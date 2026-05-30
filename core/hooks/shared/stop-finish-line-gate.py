#!/usr/bin/env python3
"""Stop hook: block finishing when code was edited but the declared project-dev
validation has not run since.

Reads the repo's project-dev validation contract (commands + marker) via
agent-docs. When the `<stem>.dirty` marker (written by finish-line-record.py on
a code edit) is newer than a per-command `<stem>.cmd<i>.ran` marker, the
declared validation has not run since the last edit, so the stop is blocked with
the outstanding commands. A waiver or suppress env releases it.

This is the finish-line enforcement point (plan [D12]): mechanism-flexible but
never silently skippable. The same shared script is wired into the Stop event
for both Claude and Codex.
"""

from __future__ import annotations

import os
import sys
from collections.abc import Iterable

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import (
    ALLOW,
    command_ran_marker,
    emit_block,
    git_toplevel,
    project_dev_validation_contract,
    read_payload,
    touch_marker,
    validation_marker_set,
)

SUPPRESS_ENVS = (
    "AGENT_RUNTIME_SUPPRESS_FINISH_GATE",
    "AGENT_KIT_SUPPRESS_FINISH_GATE",
    "CLAUDE_KIT_SUPPRESS_FINISH_GATE",
)
WAIVER_ENVS = (
    "AGENT_RUNTIME_VALIDATION_WAIVER",
    "AGENT_KIT_VALIDATION_WAIVER",
    "CLAUDE_KIT_VALIDATION_WAIVER",
)


def env_enabled(names: Iterable[str]) -> bool:
    for name in names:
        value = os.environ.get(name, "")
        if value and value != "0":
            return True
    return False


def reason(repo_root: str, contract: dict, outstanding: list[str]) -> str:
    name = os.path.basename(os.path.abspath(repo_root))
    full = " && ".join(contract["commands"])
    missing = " && ".join(outstanding)
    return (
        f"Code was edited in {name} but its declared project-dev validation has "
        f"not run since the last edit. Run it before finishing:\n  {full}\n"
        f"Outstanding: {missing}\n"
        f"(Running it records {contract['marker']}, which releases this gate. To "
        f"finish without validating, set AGENT_RUNTIME_VALIDATION_WAIVER=1 and "
        f"state the waiver reason.)"
    )


def main() -> int:
    read_payload()  # consume the Stop payload (unused)
    if env_enabled(SUPPRESS_ENVS):
        return ALLOW

    repo_root = git_toplevel()
    if not repo_root:
        return ALLOW
    contract = project_dev_validation_contract(repo_root)
    if not contract:
        return ALLOW

    markers = validation_marker_set(repo_root, contract["marker"])
    dirty = markers["dirty"]
    if not os.path.exists(dirty):
        return ALLOW
    try:
        dirty_mtime = os.path.getmtime(dirty)
    except OSError:
        return ALLOW

    outstanding: list[str] = []
    for index, declared in enumerate(contract["commands"]):
        ran = command_ran_marker(markers, index)
        try:
            if os.path.getmtime(ran) >= dirty_mtime:
                continue
        except OSError:
            pass
        outstanding.append(declared)

    if not outstanding:
        touch_marker(markers["ok"])
        return ALLOW

    if env_enabled(WAIVER_ENVS):
        return ALLOW

    emit_block(reason(repo_root, contract, outstanding))
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
