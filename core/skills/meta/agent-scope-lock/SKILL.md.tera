---
name: agent-scope-lock
description: >
  Create, read, validate, and clear edit-scope locks through the nils-cli `agent-scope-lock` command.
---

# Agent Scope Lock

## Contract

Prereqs:

- `agent-scope-lock` is installed from the released nils-cli package and available on `PATH`.
- The intended edit scope can be expressed as repo-relative path prefixes.
- The working tree has been inspected before creating or validating a lock.

Inputs:

- Allowed repo-relative path prefixes.
- Optional owner or task identifier.
- Optional validation mode for tracked, untracked, or all changed paths.

Outputs:

- Scope-lock record, current lock display, validation result, or lock removal.

Failure modes:

- A changed path falls outside the declared prefixes.
- The lock is stale, malformed, or belongs to a different task.
- The repository root cannot be resolved.

## Entrypoint

Use the released CLI directly:

```bash
agent-scope-lock create --path core/skills/meta --path manifests/skills.yaml --owner issue-26
agent-scope-lock read
agent-scope-lock validate --changes all --format json
agent-scope-lock clear
```

## Workflow

1. Create a lock only when a workflow needs an explicit edit boundary.
2. Keep prefixes narrow enough to protect unrelated user changes.
3. Validate before committing, handing off, or widening scope.
4. Clear the lock when the scoped work is complete or abandoned.

## Boundary

`agent-scope-lock` owns lock file mechanics and changed-path validation. The workflow owner decides the allowed scope and must not treat a passing lock as a substitute for code review.
