#!/usr/bin/env python3
"""PreToolUse hook: block direct git worktree invocations.

Agents should use git-cli worktree so worktree paths, branch names, JSON
contracts, and cleanup behavior stay consistent across sessions.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import PurePosixPath

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import (
    ALLOW,
    command_from,
    emit_block,
    env_target_tokens,
    env_split_expanded_tokens,
    invocation_tokens,
    nested_shell_payload,
    read_payload,
    simple_commands,
)

BLOCK_REASON = (
    "Do not use mutating git worktree commands directly. Use git-cli worktree "
    "instead. Emergency override: prefix with ALLOW_DIRECT_GIT_WORKTREE=1."
)

ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*")
MUTATING_WORKTREE_COMMANDS = {
    "add",
    "remove",
    "move",
    "prune",
    "repair",
    "lock",
    "unlock",
}
OVERRIDE_ENV_NAMES = (
    "ALLOW_DIRECT_GIT_WORKTREE",
    "AGENT_RUNTIME_ALLOW_DIRECT_GIT_WORKTREE",
)
TRUTHY_VALUES = {"1", "true", "yes"}
GIT_OPTIONS_WITH_VALUE = {
    "-C",
    "-c",
    "--config-env",
    "--exec-path",
    "--git-dir",
    "--namespace",
    "--work-tree",
}
GIT_OPTIONS_WITH_VALUE_PREFIXES = (
    "--config-env=",
    "--exec-path=",
    "--git-dir=",
    "--namespace=",
    "--work-tree=",
)


def basename(token: str) -> str:
    return PurePosixPath(token).name


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


def git_command_index(simple_command: list[str]) -> int | None:
    invocation = invocation_tokens(simple_command)
    if not invocation:
        return None
    return 0 if basename(invocation[0]) == "git" else None


def git_subcommand(simple_command: list[str]) -> str | None:
    found = git_subcommand_with_index(simple_command)
    return found[0] if found is not None else None


def git_subcommand_with_index(simple_command: list[str]) -> tuple[str, int] | None:
    invocation = invocation_tokens(simple_command)
    if not invocation or basename(invocation[0]) != "git":
        return None

    index = 1
    while index < len(invocation):
        token = invocation[index]
        if token == "--":
            return None
        if token in GIT_OPTIONS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("-C") and token != "-C":
            index += 1
            continue
        if token.startswith("-c") and token != "-c":
            index += 1
            continue
        if token.startswith(GIT_OPTIONS_WITH_VALUE_PREFIXES):
            index += 1
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return token, index
    return None


def git_worktree_action(simple_command: list[str]) -> str | None:
    invocation = invocation_tokens(simple_command)
    if not invocation:
        return None
    found = git_subcommand_with_index(simple_command)
    if found is None:
        return None
    subcommand, index = found
    if subcommand != "worktree":
        return None

    index += 1
    while index < len(invocation):
        token = invocation[index]
        if token == "--":
            return None
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return token
    return None


def env_override_enabled() -> bool:
    for name in OVERRIDE_ENV_NAMES:
        if os.environ.get(name, "").lower() in TRUTHY_VALUES:
            return True
    return False


def assignment_override_enabled(token: str) -> bool:
    if not is_assignment(token):
        return False
    name, value = token.split("=", 1)
    return name in OVERRIDE_ENV_NAMES and value.strip("\"'").lower() in TRUTHY_VALUES


def simple_command_override_enabled(simple_command: list[str]) -> bool:
    index = 0
    while index < len(simple_command) and is_assignment(simple_command[index]):
        if assignment_override_enabled(simple_command[index]):
            return True
        index += 1

    if index >= len(simple_command) or basename(simple_command[index]) != "env":
        return False

    return env_override_in_tokens(simple_command[index + 1 :])


def env_override_in_tokens(tokens: list[str]) -> bool:
    tokens = env_split_expanded_tokens(tokens)
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            return False
        if is_assignment(token):
            if assignment_override_enabled(token):
                return True
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
        if token in {"-C", "--chdir", "-P", "--path"}:
            index += 2
            continue
        if token.startswith(("--chdir=", "--path=")):
            index += 1
            continue
        if token in {"-S", "--split-string"} and index + 1 < len(tokens):
            return env_override_in_tokens(env_target_tokens(tokens, index))
        if token.startswith("--split-string="):
            return env_override_in_tokens(env_target_tokens(tokens, index))
        if token.startswith("-") and not token.startswith("--") and "S" in token[1:]:
            return env_override_in_tokens(env_target_tokens(tokens, index))
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return False
    return False


def invokes_git_worktree(
    command: str,
    *,
    inherited_override: bool = False,
    depth: int = 0,
    max_depth: int = 5,
) -> bool:
    if depth == 0 and env_override_enabled():
        return False
    if depth > max_depth:
        return False
    for simple_command in simple_commands(command):
        command_override = inherited_override or simple_command_override_enabled(
            simple_command
        )
        if (
            git_worktree_action(simple_command) in MUTATING_WORKTREE_COMMANDS
            and not command_override
        ):
            return True
        payload = nested_shell_payload(invocation_tokens(simple_command))
        if payload and invokes_git_worktree(
            payload,
            inherited_override=command_override,
            depth=depth + 1,
            max_depth=max_depth,
        ):
            return True
    return False


def main() -> int:
    command = command_from(read_payload())
    if command and invokes_git_worktree(command):
        emit_block(BLOCK_REASON)
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
