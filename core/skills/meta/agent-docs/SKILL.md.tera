---
name: agent-docs
description:
  Resolve, scaffold, and validate required agent documentation for home and project scopes through the nils-cli `agent-docs` command.
---

# Agent Docs

## Contract

Prereqs:

- `agent-docs` is installed from the released nils-cli package and available on `PATH`.
- The caller knows the documentation home to use and passes it explicitly with `--docs-home`.
- Project work happens from the target repository root unless `--project-path` is supplied.

Inputs:

- Required context name such as `startup`, `project-dev`, `task-tools`, or `skill-dev`.
- Optional baseline, scaffold, or completion request.
- Optional project path and worktree fallback mode.

Outputs:

- Checklist, text, or machine-readable evidence from `agent-docs`.
- Clear missing-doc or degraded-mode detail when strict resolution fails.

Failure modes:

- Required docs are missing under the selected docs home.
- The current directory is not the intended project path.
- Strict baseline checks fail and write/delivery work must stop until repaired or explicitly degraded.

## Entrypoint

Use the released CLI directly. Prepend the required `--docs-home` flag with the current product's native docs home value; Codex renders that value as `$CODEX_HOME`, and Claude renders it as `$HOME/.claude`.

```bash
agent-docs resolve --context startup --strict --format checklist
agent-docs resolve --context project-dev --strict --format checklist
agent-docs baseline --check --target all --strict --format text
```

## Workflow

1. Resolve `startup` at the start of a new task or session.
2. Resolve `project-dev` before repository edits, tests, commits, or delivery.
3. Resolve `task-tools` before technical research or external verification.
4. Resolve `skill-dev` before skill lifecycle work.
5. If a strict hard gate fails, stop write actions and run the baseline check. Report the missing docs or degraded mode explicitly.

## Boundary

`agent-docs` owns deterministic doc discovery, context resolution, baseline checks, and completion output. The skill body owns when to call it and how to interpret the result for the current workflow.
