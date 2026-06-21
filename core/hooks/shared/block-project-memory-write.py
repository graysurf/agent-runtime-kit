#!/usr/bin/env python3
"""PreToolUse hook: block project-state memory writes."""

from __future__ import annotations

import re
import sys
from pathlib import PurePosixPath

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import (
    ALLOW,
    bash_write_operations,
    command_from,
    emit_block,
    file_paths_from_payload,
    invocation_tokens,
    read_payload,
    simple_commands_with_nested_shells,
)

BLOCK_REASON = (
    "Blocked project-state memory write. Do not store project state in "
    "personal memory; use repository docs, git history, or agent-docs "
    "runbooks instead."
)

PROJECT_MEMORY_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(r"(?:^|/)\.claude/projects/[^/]+/memory/project_[^/]*\.md$"),
    re.compile(r"(?:^|/)\.config/agent-memory/(?:[^/]+/)*project_[^/]*\.md$"),
    re.compile(r"(?:^|/)\.codex/memories/(?:[^/]+/)*project_[^/]*\.md$"),
)


def is_project_memory_path(path: str) -> bool:
    normalized = path.replace("\\", "/")
    return any(pattern.search(normalized) for pattern in PROJECT_MEMORY_PATTERNS)


def bash_copy_style_write_targets(command: str) -> list[str]:
    targets: list[str] = []
    for simple_command in simple_commands_with_nested_shells(command, strip_heredocs=True):
        invocation = invocation_tokens(simple_command)
        if not invocation:
            continue
        name = PurePosixPath(invocation[0]).name
        if name not in {"cp", "install", "mv"}:
            continue
        positional = [token for token in invocation[1:] if not token.startswith("-")]
        if len(positional) >= 2:
            targets.append(positional[-1])
    return targets


def main() -> int:
    payload = read_payload()
    paths = file_paths_from_payload(payload)
    if str(payload.get("tool_name", "")) == "Bash":
        command = command_from(payload)
        paths.extend(path for path, _content in bash_write_operations(command))
        paths.extend(bash_copy_style_write_targets(command))
    if any(is_project_memory_path(path) for path in paths):
        emit_block(BLOCK_REASON)
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
