---
name: semantic-commit
description:
  Commit staged changes with Semantic Commit format through the nils-cli `semantic-commit` command.
---

# Semantic Commit

## Contract

Prereqs:

- `semantic-commit` is installed from the released nils-cli package and available on `PATH`.
- The intended change set is deliberately staged.
- The repository status has been inspected so unrelated user changes are not included.

Inputs:

- Staged git changes.
- Semantic commit subject and optional body.
- Optional staged-context request before message generation.

Outputs:

- Staged-change context or a git commit created by the CLI.
- Validation failure details when the message format or staged state is invalid.

Failure modes:

- No staged changes are present.
- The message does not satisfy Semantic Commit format.
- Staged files include unrelated or out-of-scope changes.

## Entrypoint

Use the released CLI directly:

```bash
semantic-commit staged-context
semantic-commit commit --message "feat: migrate evidence skill wrappers"
semantic-commit commit --message-file /tmp/commit-message.txt
```

## Workflow

1. Inspect `git status --short` before staging.
2. Stage only the intended files.
3. Use `semantic-commit staged-context` when the commit message needs a grounded summary.
4. Use `semantic-commit commit` to create the commit; do not run `git commit` directly in workflows that require semantic commits.

## Boundary

`semantic-commit` owns message validation and commit creation. The workflow owner owns selecting the staged files and ensuring the commit boundary is coherent.
