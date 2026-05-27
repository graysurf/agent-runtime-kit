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

import json
import re
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
