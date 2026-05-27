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
        raw = match.group(1)
        return (
            raw.replace("\\\\", "\x00")
            .replace('\\"', '"')
            .replace("\\n", "\n")
            .replace("\\t", "\t")
            .replace("\x00", "\\")
        )

    single_quoted_re = re.compile(r"(?:--message|-m)\s+'([^']*)'", re.DOTALL)
    match = single_quoted_re.search(command)
    if match:
        return match.group(1)

    return None
