#!/usr/bin/env python3
"""PreToolUse hook: block Claude `Co-Authored-By` trailers in commit messages.

The Claude Code harness instructs the agent to append a
`Co-Authored-By: Claude ...` trailer to commit messages. This gate removes that
default behavior by blocking any mutating `semantic-commit commit` whose message
carries such a trailer, regardless of the Claude model named after the colon.
Genuine non-Claude co-authors are left untouched.
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
    read_payload,
)

# A commit trailer line whose author is any Claude model, e.g.
# `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.
CLAUDE_COAUTHOR_RE = re.compile(r"^\s*co-authored-by:\s*claude\b", re.IGNORECASE | re.MULTILINE)

BLOCK_REASON = (
    "commit message contains a Claude Co-Authored-By trailer\n"
    "  matched: Co-Authored-By: Claude ...\n"
    "  rule: do not attribute commits to any Claude model\n"
    "  fix: remove the `Co-Authored-By: Claude ...` line from the --message body"
)


def has_claude_coauthor(message: str) -> bool:
    return CLAUDE_COAUTHOR_RE.search(message) is not None


def main() -> int:
    command = command_from(read_payload())
    if not command or not is_semantic_commit_commit(command):
        return ALLOW

    message = extract_message(command)
    if message is None:
        return ALLOW

    if has_claude_coauthor(message):
        emit_block(BLOCK_REASON)
    return ALLOW


if __name__ == "__main__":
    sys.exit(main())
