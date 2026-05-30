#!/usr/bin/env python3
"""PreToolUse recorder for the agent-docs finish-line validation gate.

Writes evidence markers under a repo's project-dev validation marker directory
so the Stop gate (stop-finish-line-gate.py) can tell whether the declared
validation has run since code was last edited:

- a `<stem>.dirty` marker, refreshed when a non-Markdown file under the repo is
  edited (Write/Edit/MultiEdit/NotebookEdit/apply_patch);
- a `<stem>.cmd<i>.ran` marker per declared validation command, refreshed when a
  Bash command invokes that command.

The recorder NEVER blocks; it only writes markers. It no-ops outside a git repo,
in a repo that declares no AGENT_DOCS.toml, or when the project-dev intent
declares no validation contract. It runs on PreToolUse (not PostToolUse) so the
same shared script works on both Claude and Codex.
"""

from __future__ import annotations

import os
import sys
from collections.abc import Mapping
from typing import Any

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import (
    ALLOW,
    command_from,
    command_matches_validation,
    command_ran_marker,
    file_paths_from_payload,
    git_toplevel,
    project_dev_validation_contract,
    read_payload,
    touch_marker,
    validation_marker_set,
)

EDIT_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit", "apply_patch"}


def tool_name(payload: Mapping[str, Any]) -> str:
    for key in ("tool_name", "toolName", "tool"):
        value = payload.get(key)
        if isinstance(value, str) and value:
            return value
    return ""


def under_repo(path: str, repo_root: str) -> bool:
    if not path:
        return False
    absolute = path if os.path.isabs(path) else os.path.join(repo_root, path)
    absolute = os.path.abspath(absolute)
    root = os.path.abspath(repo_root)
    try:
        return os.path.commonpath([absolute, root]) == root
    except ValueError:
        return False


def main() -> int:
    payload = read_payload()
    repo_root = git_toplevel()
    if not repo_root:
        return ALLOW
    contract = project_dev_validation_contract(repo_root)
    if not contract:
        return ALLOW

    markers = validation_marker_set(repo_root, contract["marker"])
    tool = tool_name(payload)

    if tool == "Bash":
        command = command_from(payload)
        for index, declared in enumerate(contract["commands"]):
            if command_matches_validation(command, declared):
                touch_marker(command_ran_marker(markers, index))
    elif tool in EDIT_TOOLS:
        for path in file_paths_from_payload(payload):
            if path.endswith(".md"):
                continue
            if under_repo(path, repo_root):
                touch_marker(markers["dirty"])
                break

    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
