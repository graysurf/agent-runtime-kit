---
name: semantic-commit
description: >
  Commit, amend, or create cleanup commits through the nils-cli `semantic-commit` command while preserving agent-owned staged-change boundaries.
---

# Semantic Commit

## Contract

Prereqs:

- `semantic-commit` is installed from the released nils-cli package and
  available on `PATH`. For unreleased nils-cli surface validation, scope `PATH`
  to the local debug binary for the command being tested.
- The repository status has been inspected before staging or commit mutation.
- The intended staged set is deliberate and contains no unrelated user changes.
- Amend, message-only amend, fixup, and squash workflows have an explicit user
  or task reason; verify `HEAD` before mutating history when concurrent work is
  possible.

Inputs:

- Staged git changes, except explicit `--message-only` amend or intentional
  `--allow-empty` workflows.
- Semantic Commit message supplied by text, file, stdin, or structured fields.
- Optional trailers, signoff, clean-tree guard, expected-HEAD guard, and JSON
  output request.
- Target revision for `fixup` and `squash` cleanup commits.

Outputs:

- Staged-change context for message generation.
- A new commit, amended commit, message-only amend, `fixup!` commit, or
  `squash!` commit created by the CLI.
- Text output for humans or versioned JSON output for agents.
- Validation failure details when message, staged state, guard, target, or
  trailer checks fail.

Failure modes:

- No staged changes are present, unless `--message-only` or `--allow-empty` is
  intentionally used.
- The message does not satisfy Semantic Commit format. This includes the
  body-line rule: each body bullet must start with `- ` followed by an
  uppercase ASCII letter, a trailer, or `  ` (two spaces) continuing the
  previous bullet. A lowercase identifier, backticked token, or leading
  `--flag` as the first body token is rejected (`commit body line N must start
  with '- ' followed by uppercase letter, a trailer, or '  ' to continue the
  previous bullet`).
- Staged files include unrelated or out-of-scope changes.
- `--expect-head` does not match the current `HEAD`.
- `--require-clean` / `--no-unstaged` detects unstaged or untracked changes.
- `--no-edit`, `--message-only`, structured fields, message files, or inline
  messages are combined incompatibly.
- `fixup` / `squash` receives an invalid target revision.

## Entrypoint

Use the released CLI directly:

```bash
semantic-commit staged-context

semantic-commit commit --message "feat: migrate evidence skill wrappers"
semantic-commit commit --message-file .git/semantic-commit-message.txt

semantic-commit commit \
  --type feat \
  --scope runtime \
  --subject "refresh semantic commit skill" \
  --body-bullet "Document amend and cleanup commit workflows" \
  --body-bullet "Preserve staged-change ownership boundaries" \
  --json

semantic-commit commit --amend --no-edit --expect-head HEAD --json
semantic-commit commit --amend --message-only --message-file .git/semantic-commit-message.txt

semantic-commit fixup --target HEAD~1 --json
semantic-commit squash --target HEAD~1 --json
```

## Workflow

1. Inspect `git status --short` before staging.
2. Stage only the intended files.
3. Use `semantic-commit staged-context` when the commit message needs a grounded summary.
4. Prefer `semantic-commit commit --dry-run` or `--validate-only` before a risky
   mutation, especially when composing messages from files or structured fields.
5. Use `--expect-head <rev>` for amend and cleanup flows when another agent or
   user may have moved `HEAD`; use `--require-clean` / `--no-unstaged` when the
   workflow requires no unstaged or untracked work.
6. Use `--json` when later workflow steps need the resulting operation, subject,
   or commit SHA without parsing human output.
7. Use structured message fields (`--type`, `--scope`, `--subject`,
   repeatable `--body-bullet`) when the agent is assembling a message from known
   parts; use `--trailer` and `--signoff` instead of hand-editing standard
   trailer lines. Open every body bullet with an uppercase ASCII letter:
   `--auto-fix` capitalizes a lowercase first word, but a bullet that leads with
   a `--flag` or a backticked identifier cannot be auto-capitalized — rephrase
   to lead with a capitalized verb or noun (write `` - Keep `--now` as the
   override `` rather than `- --now stays the override`).
8. Use `semantic-commit commit --amend` for Semantic Commit amend flows:
   `--no-edit` reuses the current `HEAD` message, and `--message-only` updates
   only the message while rejecting staged content.
9. Use `semantic-commit fixup --target <rev>` or
   `semantic-commit squash --target <rev>` for review cleanup commits whose
   generated `fixup!` / `squash!` subjects intentionally are not Semantic Commit
   headers.
10. Do not run `git commit` directly for supported create, amend, message-only,
    fixup, or squash workflows. Do not use `--allow-empty` unless the task
    explicitly calls for an empty commit.

## Boundary

`semantic-commit` owns message validation, guard checks, trailer handling, and
the commit mutation. The workflow owner owns selecting staged files, deciding
whether history mutation is appropriate, keeping the commit boundary coherent,
and handling push, PR, or issue delivery separately.
