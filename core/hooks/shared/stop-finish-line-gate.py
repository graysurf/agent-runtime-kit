#!/usr/bin/env python3
"""Stop hook: block finishing when code was edited but declared validation has
not run since.

Reads the repo's declared validation contracts (commands + marker) via
agent-docs. When any `<stem>.dirty` marker (written by finish-line-record.py on
a code edit) is newer than a per-command `<stem>.cmd<i>.ran` marker, that
declared validation has not run since the last edit, so the stop is blocked
with the outstanding commands. A waiver or suppress env releases it.

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
    read_payload,
    touch_marker,
    validation_contracts,
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


def reason(
    repo_root: str, contracts: list[dict], outstanding: list[tuple[str, str]]
) -> str:
    name = os.path.basename(os.path.abspath(repo_root))
    full = " && ".join(
        command
        for contract in contracts
        for command in contract.get("commands", [])
        if isinstance(command, str)
    )
    missing = " && ".join(f"[{context}] {command}" for context, command in outstanding)
    markers = ", ".join(
        str(contract.get("marker", "")).strip()
        for contract in contracts
        if str(contract.get("marker", "")).strip()
    )
    return (
        f"Code was edited in {name} but its declared validation has "
        f"not run since the last edit. Run it before finishing:\n  {full}\n"
        f"Outstanding: {missing}\n"
        f"(Running it records {markers}, which releases this gate. To "
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
    contracts = validation_contracts(repo_root)
    if not contracts:
        return ALLOW

    outstanding: list[tuple[str, str]] = []
    satisfied_markers: list[dict[str, str]] = []
    for contract in contracts:
        markers = validation_marker_set(repo_root, contract["marker"])
        dirty = markers["dirty"]
        if not os.path.exists(dirty):
            continue
        try:
            dirty_mtime = os.path.getmtime(dirty)
        except OSError:
            continue

        contract_outstanding: list[str] = []
        for index, declared in enumerate(contract["commands"]):
            ran = command_ran_marker(markers, index)
            try:
                if os.path.getmtime(ran) >= dirty_mtime:
                    continue
            except OSError:
                pass
            contract_outstanding.append(declared)
        if contract_outstanding:
            context = str(contract.get("context") or "validation")
            outstanding.extend((context, command) for command in contract_outstanding)
        else:
            satisfied_markers.append(markers)

    if not outstanding:
        for markers in satisfied_markers:
            touch_marker(markers["ok"])
        return ALLOW

    if env_enabled(WAIVER_ENVS):
        return ALLOW

    emit_block(reason(repo_root, contracts, outstanding))
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
