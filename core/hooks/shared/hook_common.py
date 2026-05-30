"""Shared helpers for product hook scripts.

Hooks should be conservative: if the input payload is missing or has an
unknown shape, allow the tool call and let the normal tool/runtime validation
handle it. Mechanical guardrails should block only when the relevant command
or path is explicit in the payload.

The helpers intentionally fan out across the union of Codex and Claude payload
keys so the hook implementations can stay shared while product activation
stays in `targets/<product>/`.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
from collections.abc import Iterable, Mapping
from pathlib import PurePosixPath
from typing import Any

ALLOW = 0


def read_payload() -> dict[str, Any]:
    try:
        loaded = json.load(sys.stdin)
    except Exception:
        return {}
    return loaded if isinstance(loaded, dict) else {}


def emit_block(reason: str) -> None:
    sys.stdout.write(json.dumps({"decision": "block", "reason": reason}))
    sys.stdout.write("\n")


def tool_input_dict(payload: Mapping[str, Any]) -> dict[str, Any]:
    tool_input = payload.get("tool_input", {})
    return dict(tool_input) if isinstance(tool_input, dict) else {}


def command_from(payload: Mapping[str, Any]) -> str:
    tool_input = payload.get("tool_input", {})
    if isinstance(tool_input, dict):
        command = tool_input.get("command", "")
        return command if isinstance(command, str) else str(command)
    return ""


def iter_text_values(value: Any) -> Iterable[str]:
    if isinstance(value, str):
        yield value
        return
    if isinstance(value, Mapping):
        for nested in value.values():
            yield from iter_text_values(nested)
        return
    if isinstance(value, list | tuple):
        for nested in value:
            yield from iter_text_values(nested)


def patch_text_candidates(payload: Mapping[str, Any]) -> list[str]:
    tool_input = payload.get("tool_input", {})
    if isinstance(tool_input, str):
        return [tool_input]
    if not isinstance(tool_input, dict):
        return []

    candidates: list[str] = []
    for key in ("patch", "input", "content", "diff", "text", "command"):
        value = tool_input.get(key)
        if isinstance(value, str):
            candidates.append(value)

    # Some runtimes wrap the raw patch in nested input structures. Keep this
    # as a fallback after known keys so direct values are tested first.
    for value in iter_text_values(tool_input):
        if value not in candidates:
            candidates.append(value)
    return candidates


def apply_patch_paths(patch_text: str) -> list[str]:
    paths: list[str] = []
    prefixes = (
        "*** Add File: ",
        "*** Update File: ",
        "*** Delete File: ",
        "*** Move to: ",
    )
    for line in patch_text.splitlines():
        for prefix in prefixes:
            if line.startswith(prefix):
                path = line[len(prefix) :].strip()
                if path:
                    paths.append(path)
                break
    return paths


def file_paths_from_payload(payload: Mapping[str, Any]) -> list[str]:
    tool_input = payload.get("tool_input", {})
    paths: list[str] = []
    if isinstance(tool_input, dict):
        for key in ("file_path", "path", "filename"):
            value = tool_input.get(key)
            if isinstance(value, str) and value:
                paths.append(value)
    for candidate in patch_text_candidates(payload):
        paths.extend(apply_patch_paths(candidate))
    return paths


def is_semantic_commit_commit(command: str) -> bool:
    """True when the command is a mutating `semantic-commit commit` invocation.

    Dry-run / validate-only / help / non-commit subcommands are excluded so
    message-content gates only fire on commands that actually write a commit.
    """
    if not re.search(r"\bsemantic-commit\s+commit\b", command):
        return False
    if re.search(r"(--validate-only|--dry-run|-h\b|--help\b)", command):
        return False
    return not re.search(
        r"\bsemantic-commit\s+(staged-context|config|help|--help)\b",
        command,
    )


def extract_message(command: str) -> str | None:
    """Best-effort recovery of the commit message from a semantic-commit command.

    Handles `--message`/`-m` passed as a `$(cat <<TAG ...)` HEREDOC, a
    double-quoted string (with common escapes), or a single-quoted string.
    Returns None when no message argument can be parsed.
    """
    heredoc_re = re.compile(
        r"""(?:--message|-m)
            \s+
            ["']?
            \$\(
            \s*cat\s*<<(?P<dash>-)?
            \s*
            (?P<q>['"])?
            (?P<tag>\w+)
            (?P=q)?
            \s*\n
            (?P<body>.*?)
            \n
            (?P<leading>[ \t]*)
            (?P=tag)
            \s*
            \n?
            \s*\)
            ["']?""",
        re.DOTALL | re.VERBOSE,
    )
    match = heredoc_re.search(command)
    if match:
        return match.group("body")

    double_quoted_re = re.compile(r'(?:--message|-m)\s+"((?:\\.|[^"\\])*)"', re.DOTALL)
    match = double_quoted_re.search(command)
    if match:
        return _unescape_double_quoted(match.group(1))

    single_quoted_re = re.compile(r"(?:--message|-m)\s+'([^']*)'", re.DOTALL)
    match = single_quoted_re.search(command)
    if match:
        return match.group(1)

    return None


def _unescape_double_quoted(raw: str) -> str:
    """Undo the common backslash escapes inside a double-quoted shell string."""
    return (
        raw.replace("\\\\", "\x00")
        .replace('\\"', '"')
        .replace("\\n", "\n")
        .replace("\\t", "\t")
        .replace("\x00", "\\")
    )


def iter_flag_values(command: str, *flags: str) -> list[str]:
    """Recover every value passed to any of `flags` in a shell command.

    Recognizes `--flag value` and `--flag=value`, where the value is a
    single-quoted string, a double-quoted string (with common escapes), or a
    bare unquoted token. Best-effort guardrail parsing, not a real shell, so
    flag names are matched only when followed by `=` or whitespace.
    """
    values: list[str] = []
    for flag in flags:
        pattern = re.compile(
            re.escape(flag)
            + r"""(?:=|\s+)(?:'(?P<sq>[^']*)'|"(?P<dq>(?:\\.|[^"\\])*)"|(?P<bare>[^\s'"]\S*))"""
        )
        for match in pattern.finditer(command):
            if match.group("sq") is not None:
                values.append(match.group("sq"))
            elif match.group("dq") is not None:
                values.append(_unescape_double_quoted(match.group("dq")))
            elif match.group("bare") is not None:
                values.append(match.group("bare"))
    return values


def read_message_file(command: str, *, max_bytes: int = 65536) -> str | None:
    """Best-effort read of a `--message-file` argument's contents.

    Returns the file text (capped at `max_bytes`) for the first readable
    `--message-file` path, or None when no path parses or can be read.
    """
    for path in iter_flag_values(command, "--message-file"):
        try:
            with open(path, encoding="utf-8", errors="replace") as handle:
                return handle.read(max_bytes)
        except OSError:
            continue
    return None


# --- agent-docs finish-line validation gate helpers ---------------------------
#
# Shared by the PreToolUse recorder (finish-line-record.py) and the Stop gate
# (stop-finish-line-gate.py). The recorder writes evidence markers under a
# repo's project-dev validation marker directory; the gate reads them to decide
# whether the declared validation has run since code was last edited.


def git_toplevel(cwd: str | None = None) -> str | None:
    """Return the git work-tree root for `cwd` (or the process cwd), else None."""
    try:
        completed = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            cwd=cwd,
            check=False,
        )
    except (OSError, ValueError):
        return None
    if completed.returncode != 0:
        return None
    top = completed.stdout.strip()
    return top or None


def _runtime_cache_dir() -> str:
    return os.path.join(os.path.expanduser("~"), ".cache", "agent-runtime-kit")


def _resolve_project_dev_contract(repo_root: str) -> dict[str, Any] | None:
    """Resolve a repo's project-dev validation contract via `agent-docs`."""
    docs_home = os.environ.get("AGENT_RUNTIME_DOCS_HOME") or os.environ.get("AGENT_DOCS_HOME")
    args = ["agent-docs"]
    if docs_home:
        args += ["--docs-home", docs_home]
    args += ["--project-path", repo_root, "explain", "--intent", "project-dev", "--format", "json"]
    try:
        completed = subprocess.run(
            args, capture_output=True, text=True, check=False, timeout=15
        )
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    if completed.returncode != 0 or not completed.stdout.strip():
        return None
    try:
        data = json.loads(completed.stdout)
    except Exception:
        return None
    validation = data.get("validation") if isinstance(data, dict) else None
    if not isinstance(validation, dict) or not validation.get("declared"):
        return None
    commands = [
        command
        for command in (validation.get("commands") or [])
        if isinstance(command, str) and command.strip()
    ]
    if not commands:
        return None
    marker = validation.get("marker")
    if not isinstance(marker, str) or not marker.strip():
        marker = ".cache/agent-validation/project-dev.ok"
    return {"commands": commands, "marker": marker.strip()}


def project_dev_validation_contract(repo_root: str) -> dict[str, Any] | None:
    """The repo's project-dev validation contract, or None when none applies.

    Returns ``{"commands": [...], "marker": "..."}`` when the repo declares an
    ``AGENT_DOCS.toml`` whose project-dev intent has a validation contract with
    at least one command. The agent-docs result is cached per repo, keyed on the
    catalog's mtime, so the recorder can run on every tool call cheaply.
    """
    catalog = os.path.join(repo_root, "AGENT_DOCS.toml")
    if not os.path.isfile(catalog):
        return None
    try:
        catalog_mtime = os.path.getmtime(catalog)
    except OSError:
        catalog_mtime = 0.0

    digest = hashlib.sha1(repo_root.encode("utf-8")).hexdigest()[:16]
    cache_path = os.path.join(_runtime_cache_dir(), f"contract-{digest}.json")
    try:
        with open(cache_path, encoding="utf-8") as handle:
            cached = json.load(handle)
        if isinstance(cached, dict) and cached.get("catalog_mtime") == catalog_mtime:
            return cached.get("contract")
    except (OSError, ValueError):
        pass

    contract = _resolve_project_dev_contract(repo_root)
    try:
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        with open(cache_path, "w", encoding="utf-8") as handle:
            json.dump({"catalog_mtime": catalog_mtime, "contract": contract}, handle)
    except OSError:
        pass
    return contract


def validation_marker_set(repo_root: str, marker: str) -> dict[str, str]:
    """Derive the marker file paths for a repo from the contract `marker`."""
    rel = marker.strip().lstrip("/")
    rel_dir = os.path.dirname(rel) or "."
    stem = os.path.splitext(os.path.basename(rel))[0] or "project-dev"
    abs_dir = os.path.join(repo_root, rel_dir)
    return {
        "dir": abs_dir,
        "ok": os.path.join(repo_root, rel),
        "dirty": os.path.join(abs_dir, f"{stem}.dirty"),
        "stem": stem,
    }


def command_ran_marker(marker_set: Mapping[str, str], index: int) -> str:
    return os.path.join(marker_set["dir"], f"{marker_set['stem']}.cmd{index}.ran")


SHELL_SEPARATOR_TOKENS = {";", "&&", "||", "|", "(", ")"}


def shell_tokens(command: str) -> list[str]:
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
        lexer.whitespace_split = True
        lexer.commenters = ""
        return list(lexer)
    except ValueError:
        return []


def is_shell_separator(token: str) -> bool:
    return token in SHELL_SEPARATOR_TOKENS or bool(token) and all(
        char in ";&|()" for char in token
    )


def simple_commands(command: str) -> list[list[str]]:
    commands: list[list[str]] = []
    current: list[str] = []
    for token in shell_tokens(command):
        if is_shell_separator(token):
            if current:
                commands.append(current)
            current = []
            continue
        current.append(token)
    if current:
        commands.append(current)
    return commands


ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*")


def is_assignment(token: str) -> bool:
    return bool(ASSIGNMENT_RE.match(token))


def skip_env_prefix(tokens: list[str], index: int) -> int:
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            return index + 1
        if is_assignment(token):
            index += 1
            continue
        if token in {"-i", "--ignore-environment", "-0", "--null"}:
            index += 1
            continue
        if token in {"-u", "--unset"}:
            index += 2
            continue
        if token.startswith("--unset="):
            index += 1
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return index
    return index


def invocation_tokens(simple_command: list[str]) -> list[str]:
    index = 0
    while index < len(simple_command) and is_assignment(simple_command[index]):
        index += 1
    if index >= len(simple_command):
        return []

    command = PurePosixPath(simple_command[index]).name
    if command == "env":
        index = skip_env_prefix(simple_command, index + 1)
    elif command == "time":
        index += 1
        while index < len(simple_command) and simple_command[index].startswith("-"):
            index += 1
    elif command in {"command", "exec"}:
        if index + 1 < len(simple_command) and simple_command[index + 1] in {"-v", "-V"}:
            return []
        index += 1

    if index >= len(simple_command):
        return []

    command = PurePosixPath(simple_command[index]).name
    if command == "agent-run" and index + 1 < len(simple_command):
        if simple_command[index + 1] == "exec":
            for next_index in range(index + 2, len(simple_command)):
                if simple_command[next_index] == "--":
                    return simple_command[next_index + 1 :]
            return simple_command[index + 2 :]

    return simple_command[index:]


def normalize_pathish(token: str) -> str:
    normalized = token
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def token_matches_declared(actual: str, declared: str, *, command_position: bool) -> bool:
    if actual == declared:
        return True
    if command_position and PurePosixPath(actual).name == declared:
        return True
    if "/" in declared:
        expected = normalize_pathish(declared)
        observed = normalize_pathish(actual)
        return observed == expected or observed.endswith(f"/{expected}")
    return False


def invocation_matches_declared(actual_tokens: list[str], declared_tokens: list[str]) -> bool:
    if len(actual_tokens) < len(declared_tokens):
        return False
    for index, declared in enumerate(declared_tokens):
        if not token_matches_declared(
            actual_tokens[index], declared, command_position=(index == 0)
        ):
            return False
    return True


def command_matches_validation(actual: str, declared: str) -> bool:
    """True when a Bash command invokes a declared validation command.

    The check is intentionally shell-segment based, not substring based. A
    command that merely prints or mentions `bash scripts/ci/all.sh` must not
    satisfy the finish-line gate. Known wrappers such as
    `agent-run exec -- bash scripts/ci/all.sh` are unwrapped before matching.
    """
    if not actual or not declared:
        return False
    declared_invocations = [
        invocation_tokens(command) for command in simple_commands(declared.strip())
    ]
    if not declared_invocations or any(not command for command in declared_invocations):
        return False
    actual_invocations = [
        invocation_tokens(command) for command in simple_commands(actual) if command
    ]
    return all(
        any(
            invocation_matches_declared(actual_tokens, declared_tokens)
            for actual_tokens in actual_invocations
        )
        for declared_tokens in declared_invocations
    )


def touch_marker(path: str) -> bool:
    """Create/refresh an empty marker file; return False on failure."""
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "a", encoding="utf-8"):
            pass
        os.utime(path, None)
        return True
    except OSError:
        return False
