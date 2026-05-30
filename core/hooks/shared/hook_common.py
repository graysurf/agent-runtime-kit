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
import subprocess
import sys
from collections.abc import Iterable, Mapping
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


def command_matches_validation(actual: str, declared: str) -> bool:
    """True when a Bash command invokes a declared validation command.

    Matches the declared command's distinctive path-like tokens (so wrappers and
    trailing flags still match, e.g. `agent-run exec -- bash scripts/ci/all.sh`),
    falling back to a substring of the whole declared command.
    """
    if not actual or not declared:
        return False
    declared = declared.strip()
    distinctive = [
        token
        for token in declared.split()
        if "/" in token or token.endswith((".sh", ".py", ".rs"))
    ]
    if distinctive:
        return any(token in actual for token in distinctive)
    return declared in actual


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
