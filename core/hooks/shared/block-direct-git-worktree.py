#!/usr/bin/env python3
"""PreToolUse hook: block direct git worktree invocations.

Agents should use git-cli worktree so worktree paths, branch names, JSON
contracts, and cleanup behavior stay consistent across sessions.
"""

from __future__ import annotations

import os
import re
import shlex
import sys
from pathlib import PurePosixPath

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import ALLOW, command_from, emit_block, read_payload

BLOCK_REASON = (
    "Do not use mutating git worktree commands directly. Use git-cli worktree "
    "instead. Emergency override: prefix with ALLOW_DIRECT_GIT_WORKTREE=1."
)

ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.*")
SEPARATOR_TOKENS = {";", "&&", "||", "|", "(", ")"}
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


def shell_tokens(command: str) -> list[str]:
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
        lexer.whitespace_split = True
        lexer.commenters = ""
        return list(lexer)
    except ValueError:
        return []


def is_separator(token: str) -> bool:
    return token in SEPARATOR_TOKENS or bool(token) and all(char in ";&|()" for char in token)


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
    index = 0
    while index < len(simple_command) and is_assignment(simple_command[index]):
        index += 1
    if index >= len(simple_command):
        return None

    command = basename(simple_command[index])
    if command == "env":
        index = skip_env_prefix(simple_command, index + 1)
    elif command == "time":
        index += 1
        while index < len(simple_command) and simple_command[index].startswith("-"):
            index += 1
    elif command in {"command", "exec"}:
        if index + 1 < len(simple_command) and simple_command[index + 1] in {"-v", "-V"}:
            return None
        index += 1

    if index >= len(simple_command):
        return None
    return index if basename(simple_command[index]) == "git" else None


def git_subcommand(simple_command: list[str]) -> str | None:
    found = git_subcommand_with_index(simple_command)
    return found[0] if found is not None else None


def git_subcommand_with_index(simple_command: list[str]) -> tuple[str, int] | None:
    git_index = git_command_index(simple_command)
    if git_index is None:
        return None

    index = git_index + 1
    while index < len(simple_command):
        token = simple_command[index]
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
    found = git_subcommand_with_index(simple_command)
    if found is None:
        return None
    subcommand, index = found
    if subcommand != "worktree":
        return None

    index += 1
    while index < len(simple_command):
        token = simple_command[index]
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

    index += 1
    while index < len(simple_command):
        token = simple_command[index]
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
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return False
    return False


def invokes_git_worktree(command: str) -> bool:
    if env_override_enabled():
        return False
    simple_command: list[str] = []
    for token in shell_tokens(command):
        if is_separator(token):
            if (
                git_worktree_action(simple_command) in MUTATING_WORKTREE_COMMANDS
                and not simple_command_override_enabled(simple_command)
            ):
                return True
            simple_command = []
            continue
        simple_command.append(token)
    return (
        git_worktree_action(simple_command) in MUTATING_WORKTREE_COMMANDS
        and not simple_command_override_enabled(simple_command)
    )


def main() -> int:
    command = command_from(read_payload())
    if command and invokes_git_worktree(command):
        emit_block(BLOCK_REASON)
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
