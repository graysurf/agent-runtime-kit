---
name: agent-out
description: >
  Allocate canonical project-scoped output directories, audit workflow
  artifacts, and drive reviewed cleanup plans through the nils-cli `agent-out`
  command.
---

# Agent Out

## Contract

Prereqs:

- `agent-out` is installed from the released nils-cli package and available on `PATH`.
- The caller has a concrete topic for temporary or evidence artifacts.
- Durable repo artifacts are used only when project policy or the user explicitly asks for them.
- Cleanup applies only after a reviewed `cleanup plan` and matching
  `plan_digest`; do not delete retained evidence or project artifacts by hand.

Inputs:

- Topic slug for a run directory.
- Optional repository path when allocating output for a repo other than the current directory.
- Optional audit request for existing output entries.
- Optional cleanup request for stale cache or noncanonical output entries.

Outputs:

- Canonical run directory path, JSON, or shell env output.
- Optional audit report for output hygiene.
- Optional cleanup plan and digest-gated apply report.

Failure modes:

- The topic is missing or unsafe.
- The selected repository path cannot be resolved.
- Artifact audit finds unexpected top-level or retained output entries.
- Cleanup apply rejects unreadable, stale, mismatched, or unsafe plans.
- Cleanup apply skips paths that gained retained evidence markers after the
  plan was written.

## Entrypoint

Use the released CLI directly:

```bash
agent-out project --topic browser-qa --mkdir
agent-out project --repo . --topic release-notes --format json
agent-out audit --strict
agent-out cleanup plan --format text
agent-out cleanup plan --include-projects --format json > cleanup-plan.json
agent-out cleanup apply --plan-file cleanup-plan.json --confirm-digest <plan_digest>
```

## Workflow

1. Use `agent-out project --topic <topic> --mkdir` for temporary or workflow evidence directories when the project has no defined output path.
2. Use `--format json` or `--format env` when another command needs the allocated path.
3. Run `agent-out audit` before cleanup or before enforcing output-retention policy.
4. For cleanup, run `agent-out cleanup plan` first and inspect every row:
   - `delete` rows are limited to safe top-level cache or noncanonical entries.
   - `preserve` rows include canonical roots and retained evidence markers.
   - `needs-policy` rows need an explicit retention decision, usually project
     run artifacts surfaced with `--include-projects`.
5. Migrate or prune skill-usage evidence through the evidence archive workflow
   before deleting evidence-source rows; cleanup is not a substitute for
   `evidence migrate` or `evidence prune-source`.
6. Apply cleanup only with the reviewed plan file and exact `plan_digest`.
   Re-run `cleanup plan` after apply if you need to prove the tree is clean.
7. Do not put credentials, runtime history, or persistent project state in ad hoc output directories.

## Boundary

`agent-out` owns path construction, directory creation, audit mechanics, and
digest-gated cleanup execution. The caller owns deciding whether an artifact is
temporary, durable, migrated evidence, or project-tracked.
