#!/usr/bin/env python3
"""PreToolUse hook: guard forge-cli invocations and labelable record creation.

This hook owns the forge-cli Bash hot path. It blocks invocation forms that
bypass the local `forge-cli` shell function identity wrapper, then reminds when
an agent runs a `forge-cli` command that creates or delivers a labelable
provider record (`pr create`, `pr deliver`, `issue create`) without any
`--label` flag, surface a soft reminder to consider labelling the record for
triage and automation.

This is advisory, not mandatory: labels stay optional. An intentional
no-label record can proceed by prefixing the command with `FORGE_NO_LABELS=1`
(or `AGENT_RUNTIME_FORGE_NO_LABELS=1`), or by exporting either name. The hook
emits a block decision only as the delivery mechanism for the reminder — the
agent re-runs either with labels or with the bypass marker.

`forge-cli` is provider-neutral, so `pr create` already covers both GitHub PRs
and GitLab MRs; there is no separate `mr` subcommand to match.
"""

from __future__ import annotations

import os
import sys
from pathlib import PurePosixPath

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import (
    ALLOW,
    _heredoc_delimiters_on_line,
    _line_has_unquoted_continuation,
    command_from,
    emit_block,
    is_assignment,
    invocation_tokens,
    read_payload,
    simple_commands,
    shell_tokens,
    strip_heredoc_bodies,
)

REMINDER = (
    "forge-cli is about to create a record without any --label. Consider adding "
    "one or more --label flags so the record carries type / area / state / size "
    "/ workflow for triage and automation (follow forge-label-taxonomy; when the "
    "repo ships manifests/forge-labels.yaml, pick from that catalog). This is a "
    "reminder, not a hard requirement: if this record intentionally needs no "
    "label, re-run with FORGE_NO_LABELS=1 prefixed."
)

BYPASS_BLOCK = (
    "Do not run forge-cli through env/command/exec, a path-qualified binary, "
    "or a nested shell; those forms bypass the local forge-cli wrapper and can "
    "post provider records as the user instead of the configured GitHub App "
    "bot. Invoke `forge-cli ...` directly, and pass identity overrides as "
    "inline assignments, for example "
    "`FORGE_BOT_PROFILE=dobi forge-cli pr review ...`."
)

# forge-cli (sub)commands that create or deliver a labelable provider record.
LABELABLE_SUBCOMMANDS = frozenset(
    {("pr", "create"), ("pr", "deliver"), ("issue", "create")}
)

LABEL_FLAG = "--label"
LABEL_FLAG_PREFIX = "--label="
HELP_FLAGS = frozenset({"--help", "-h"})

OVERRIDE_ENV_NAMES = ("FORGE_NO_LABELS", "AGENT_RUNTIME_FORGE_NO_LABELS")
TRUTHY_VALUES = {"1", "true", "yes"}

# forge-cli global options that consume the following token as their value, so
# the subcommand scan does not mistake a value for the `pr` / `issue` command.
FORGE_GLOBAL_OPTIONS_WITH_VALUE = {
    "--format",
    "--remote",
    "--provider",
    "--repo",
    "--store-root",
}

ENV_OPTIONS_WITH_VALUE = {
    "-C",
    "--chdir",
    "-P",
    "--path",
}

ENV_OPTION_VALUE_PREFIXES = (
    "--chdir=",
    "--path=",
)

ENV_SPLIT_OPTIONS = {
    "-S",
    "--split-string",
}

ENV_SPLIT_PREFIXES = (
    "--split-string=",
)

TIME_OPTIONS_WITH_VALUE = {
    "-f",
    "--format",
    "-o",
    "--output",
}

TIME_OPTION_VALUE_PREFIXES = (
    "--format=",
    "--output=",
)

SHELL_COMMANDS = {"bash", "dash", "ksh", "sh", "zsh"}


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


def simple_command_bypass(tokens: list[str]) -> bool:
    """True when an inline `FORGE_NO_LABELS=1` assignment prefixes the command."""
    index = 0
    while index < len(tokens) and is_assignment(tokens[index]):
        if assignment_override_enabled(tokens[index]):
            return True
        index += 1

    if index >= len(tokens) or PurePosixPath(tokens[index]).name != "env":
        return False

    index += 1
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
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return False
    return False


def basename(token: str) -> str:
    return PurePosixPath(token).name


def skip_assignments(tokens: list[str], index: int = 0) -> int:
    while index < len(tokens) and is_assignment(tokens[index]):
        index += 1
    return index


def expand_env_split_tokens(tokens: list[str], index: int) -> list[str]:
    expanded: list[str] = []
    while index < len(tokens):
        token = tokens[index]
        if token in ENV_SPLIT_OPTIONS:
            if index + 1 < len(tokens):
                expanded.extend(shell_tokens(tokens[index + 1]))
            index += 2
            continue
        matched_prefix = next(
            (prefix for prefix in ENV_SPLIT_PREFIXES if token.startswith(prefix)),
            None,
        )
        if matched_prefix is not None:
            expanded.extend(shell_tokens(token[len(matched_prefix) :]))
            index += 1
            continue
        if token.startswith("-") and not token.startswith("--"):
            split_index = token.find("S")
            if split_index > 0:
                prefix_flags = token[1:split_index]
                payload = token[split_index + 1 :]
                expanded.extend(f"-{flag}" for flag in prefix_flags)
                if payload:
                    expanded.extend(shell_tokens(payload))
                    index += 1
                    continue
                if index + 1 < len(tokens):
                    expanded.extend(shell_tokens(tokens[index + 1]))
                index += 2
                continue
        expanded.append(token)
        index += 1
    return expanded


def env_target_tokens(tokens: list[str], index: int) -> list[str]:
    tokens = expand_env_split_tokens(tokens, index)
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            return tokens[index + 1 :]
        if is_assignment(token):
            index += 1
            continue
        if token in {"-i", "--ignore-environment", "-0", "--null"}:
            index += 1
            continue
        if token in {"-u", "--unset"}:
            index += 2
            continue
        if token in ENV_OPTIONS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("--unset=") or any(
            token.startswith(prefix) for prefix in ENV_OPTION_VALUE_PREFIXES
        ):
            index += 1
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        return tokens[index:]
    return []


def time_target_tokens(tokens: list[str], index: int) -> list[str]:
    index += 1
    while index < len(tokens) and tokens[index].startswith("-"):
        token = tokens[index]
        if token in TIME_OPTIONS_WITH_VALUE:
            index += 2
            continue
        if any(token.startswith(prefix) for prefix in TIME_OPTION_VALUE_PREFIXES):
            index += 1
            continue
        index += 1
    return tokens[index:]


def command_target_tokens(tokens: list[str], index: int) -> list[str] | None:
    index += 1
    if index < len(tokens) and tokens[index] in {"-v", "-V"}:
        return None
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            return tokens[index + 1 :]
        if token == "-p":
            index += 1
            continue
        if token.startswith("-") and token != "-":
            return None
        return tokens[index:]
    return None


def exec_target_tokens(tokens: list[str], index: int) -> list[str] | None:
    index += 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            return tokens[index + 1 :]
        if token in {"-c", "-l"}:
            index += 1
            continue
        if token == "-a":
            index += 2
            continue
        if token.startswith("-") and token != "-":
            return None
        return tokens[index:]
    return None


def unwrap_agent_run(tokens: list[str], index: int) -> tuple[list[str], int] | None:
    if basename(tokens[index]) != "agent-run" or index + 1 >= len(tokens):
        return None
    if tokens[index + 1] != "exec":
        return None
    for next_index in range(index + 2, len(tokens)):
        if tokens[next_index] == "--":
            return tokens[next_index + 1 :], 0
    return tokens[index + 2 :], 0


def shell_c_payload(tokens: list[str], index: int) -> str | None:
    index += 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            index += 1
            continue
        if token == "-c" or (
            token.startswith("-") and not token.startswith("--") and "c" in token[1:]
        ):
            if index + 1 < len(tokens):
                return tokens[index + 1]
            return None
        index += 1
    return None


def shell_script_bypasses_forge_cli_wrapper(command: str) -> bool:
    stripped = strip_heredoc_bodies(command)
    return any(
        command_bypasses_forge_cli_wrapper(tokens, bare_forge_is_bypass=True)
        for tokens in simple_commands(stripped)
        if tokens
    )


def shell_heredoc_bypasses_forge_cli_wrapper(command: str) -> bool:
    if "<<" not in command:
        return False
    lines = command.split("\n")
    pending: list[tuple[str, bool, bool, list[str]]] = []
    logical_scan_parts: list[str] = []
    for raw in lines:
        line = raw.rstrip("\r")
        if pending:
            delimiter, strip_tabs, preserve_body, body = pending[0]
            candidate = line.lstrip("\t") if strip_tabs else line
            if candidate == delimiter:
                if preserve_body and body:
                    if shell_script_bypasses_forge_cli_wrapper("\n".join(body)):
                        return True
                pending.pop(0)
            elif preserve_body:
                body.append(raw)
            continue

        if _line_has_unquoted_continuation(line):
            logical_scan_parts.append(line[:-1])
            continue

        logical_scan_parts.append(line)
        logical_line = "".join(logical_scan_parts)
        for delimiter, strip_tabs, preserve_body in _heredoc_delimiters_on_line(
            logical_line
        ):
            pending.append((delimiter, strip_tabs, preserve_body, []))
        logical_scan_parts = []
    for _delimiter, _strip_tabs, preserve_body, body in pending:
        if preserve_body and body:
            if shell_script_bypasses_forge_cli_wrapper("\n".join(body)):
                return True
    return False


def command_bypasses_forge_cli_wrapper(
    tokens: list[str], *, bare_forge_is_bypass: bool = False
) -> bool:
    index = skip_assignments(tokens)
    if index >= len(tokens):
        return False

    command_token = tokens[index]
    command = basename(command_token)
    if command == "time":
        target = time_target_tokens(tokens, index)
        return bool(target) and command_bypasses_forge_cli_wrapper(
            target, bare_forge_is_bypass=bare_forge_is_bypass
        )
    unwrapped = unwrap_agent_run(tokens, index)
    if unwrapped is not None:
        target, target_index = unwrapped
        return command_bypasses_forge_cli_wrapper(
            target[target_index:], bare_forge_is_bypass=bare_forge_is_bypass
        )
    if command == "forge-cli":
        return bare_forge_is_bypass or command_token != "forge-cli"
    if command == "env":
        target = env_target_tokens(tokens, index + 1)
        return bool(target) and command_bypasses_forge_cli_wrapper(
            target, bare_forge_is_bypass=True
        )
    if command == "command":
        target = command_target_tokens(tokens, index)
        return target is not None and command_bypasses_forge_cli_wrapper(
            target, bare_forge_is_bypass=True
        )
    if command == "exec":
        target = exec_target_tokens(tokens, index)
        return target is not None and command_bypasses_forge_cli_wrapper(
            target, bare_forge_is_bypass=True
        )
    if command in SHELL_COMMANDS:
        payload = shell_c_payload(tokens, index)
        if payload is None:
            return False
        return any(
            command_bypasses_forge_cli_wrapper(
                nested_tokens, bare_forge_is_bypass=True
            )
            for nested_tokens in simple_commands(payload)
        )
    return False


def leading_subcommand(rest: list[str]) -> tuple[str, str] | None:
    """Return the (command, action) pair after `forge-cli`, skipping globals."""
    positionals: list[str] = []
    index = 0
    while index < len(rest) and len(positionals) < 2:
        token = rest[index]
        if token == "--":
            index += 1
            while index < len(rest) and len(positionals) < 2:
                positionals.append(rest[index])
                index += 1
            break
        if token in FORGE_GLOBAL_OPTIONS_WITH_VALUE:
            index += 2
            continue
        if token.startswith("-") and token != "-":
            index += 1
            continue
        positionals.append(token)
        index += 1
    if len(positionals) >= 2:
        return positionals[0], positionals[1]
    return None


def has_label_flag(rest: list[str]) -> bool:
    return any(
        token == LABEL_FLAG or token.startswith(LABEL_FLAG_PREFIX) for token in rest
    )


def is_help_request(rest: list[str]) -> bool:
    return any(token in HELP_FLAGS for token in rest)


def needs_label_reminder(tokens: list[str]) -> bool:
    invocation = invocation_tokens(tokens)
    if not invocation or PurePosixPath(invocation[0]).name != "forge-cli":
        return False
    rest = invocation[1:]
    if leading_subcommand(rest) not in LABELABLE_SUBCOMMANDS:
        return False
    if is_help_request(rest):
        return False
    return not has_label_flag(rest)


def main() -> int:
    command = command_from(read_payload())
    if not command:
        return ALLOW
    if shell_heredoc_bypasses_forge_cli_wrapper(command):
        emit_block(BYPASS_BLOCK)
        return ALLOW
    for tokens in simple_commands(command):
        if not tokens:
            continue
        if command_bypasses_forge_cli_wrapper(tokens):
            emit_block(BYPASS_BLOCK)
            return ALLOW
        if env_override_enabled() or simple_command_bypass(tokens):
            continue
        if needs_label_reminder(tokens):
            emit_block(REMINDER)
            return ALLOW
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
