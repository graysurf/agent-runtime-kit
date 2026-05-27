---
name: plan-archive-migrate
description:
  Migrate a closed plan folder out of a working repo into the agent-plan-archive repository through the nils-cli `plan-archive migrate` command, dry-run first and apply only on explicit confirmation.
---

# Plan Archive Migrate

## Contract

Prereqs:

- `plan-archive` is installed from the released nils-cli package and
  available on `PATH`.
- `semantic-commit` is installed from the released nils-cli package and
  available on `PATH` (the apply path commits through it).
- The archive repository is cloned locally and its path is resolvable
  from the machine-local config at
  `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml` (or passed with
  `--archive`). The skill never hardcodes the clone path.
- The working repo's `origin` remote, current branch, and `HEAD` are
  readable so the source identity can be derived.

Inputs:

- The plan folder to migrate, relative to the working repo root.
- At least one provider reference (`--issue`, `--pr`, or `--mr`) so the
  archived `metadata.yaml` records provenance.
- Optional `--source-repo`, `--archive`, and `--hosts` overrides.

Outputs:

- A dry-run JSON report (archive target path, files to copy, resolved
  host classification, `metadata.yaml` payload, source files to
  delete) for the user to review.
- On confirmed apply: one archive commit, one source-repo deletion
  commit, and an apply JSON report.

Failure modes:

- The plan folder is missing, the archive clone is unresolved, or the
  source host is absent from the archive `config/hosts.yaml`.
- No provider reference is supplied.
- The archive target already exists or the working repo has
  uncommitted changes in the plan folder (apply refuses).
- A `git` or `semantic-commit` subprocess fails; the source folder is
  preserved because deletion only runs after the archive push
  succeeds.

## Entrypoint

Always run the dry-run first and show its JSON to the user:

```bash
plan-archive migrate \
  --plan docs/plans/<YYYY-MM-DD>-<slug> \
  --issue <issue-url> \
  --format json
```

Only after the user explicitly confirms the dry-run report, apply:

```bash
plan-archive migrate \
  --plan docs/plans/<YYYY-MM-DD>-<slug> \
  --issue <issue-url> \
  --apply \
  --format json
```

## Workflow

1. Confirm the plan folder is closed and eligible for archival.
2. Run `plan-archive migrate … --format json` (dry-run) and present
   the archive target, file list, classification, and `metadata.yaml`
   payload to the user.
3. Stop and require explicit user confirmation before applying. Never
   apply automatically.
4. On confirmation, run the same command with `--apply`. Report the
   archive commit and the source-repo deletion commit.
5. On any failure, surface the error code and message; do not retry a
   destructive step. The source folder is only removed after the
   archive push succeeds.

## Boundary

`plan-archive migrate` owns identity resolution, host classification,
file enumeration, the `metadata.yaml` payload, the transactional
copy/commit/push/delete sequence, and all `git` / `semantic-commit`
invocation. The skill body owns when to migrate, presenting the
dry-run for review, and gating the apply on explicit user
confirmation. It does not duplicate CLI logic or call `git` directly.
