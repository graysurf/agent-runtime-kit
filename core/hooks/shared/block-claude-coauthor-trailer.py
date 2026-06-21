#!/usr/bin/env python3
"""PreToolUse hook: block Claude `Co-Authored-By` trailers in commit messages.

The Claude Code harness instructs the agent to append a
`Co-Authored-By: Claude ...` trailer to commit messages. This gate removes that
default behavior by blocking any mutating `semantic-commit commit` whose message
carries such a trailer, regardless of the Claude model named after the colon.
The trailer is detected across every source `semantic-commit` accepts:
`--message` / `-m`, `--message-file`, `--subject`, `--body-bullet`, and
`--trailer`. Genuine non-Claude co-authors are left untouched.
"""

from __future__ import annotations

import re
import sys

# Codex may execute hooks through a source symlink; keep the checkout clean.
sys.dont_write_bytecode = True

from hook_common import (
    ALLOW,
    command_from,
    emit_block,
    extract_message,
    is_semantic_commit_commit,
    iter_flag_values,
    read_message_file,
    read_payload,
)

# A commit trailer line whose author is any Claude model, e.g.
# `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.
CLAUDE_COAUTHOR_RE = re.compile(
    r"^[ \t]*co-authored-by:\s*claude\b", re.IGNORECASE | re.MULTILINE
)

BLOCK_REASON = (
    "commit carries a Claude Co-Authored-By trailer\n"
    "  matched: Co-Authored-By: Claude ...\n"
    "  rule: do not attribute commits to any Claude model\n"
    "  fix: drop the `Co-Authored-By: Claude ...` line (checked across\n"
    "       --message / -m, --message-file, --subject, --body-bullet, --trailer)"
)


def has_claude_coauthor(message: str) -> bool:
    return CLAUDE_COAUTHOR_RE.search(message) is not None


def candidate_texts(command: str) -> list[str]:
    """Every commit-message source a Claude co-author trailer could hide in."""
    texts: list[str] = []
    body = extract_message(command)
    if body:
        texts.append(body)
    file_body = read_message_file(command)
    if file_body:
        texts.append(file_body)
    texts.extend(iter_flag_values(command, "--subject", "--body-bullet", "--trailer"))
    return texts


def main() -> int:
    command = command_from(read_payload())
    if not command or not is_semantic_commit_commit(command):
        return ALLOW

    if any(has_claude_coauthor(text) for text in candidate_texts(command)):
        emit_block(BLOCK_REASON)
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
