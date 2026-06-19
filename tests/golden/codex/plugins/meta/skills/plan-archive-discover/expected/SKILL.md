---
name: plan-archive-discover
description:
  Read-only scan of a working repo's plan folders for archive candidates
  through the nils-cli `plan-archive discover` command; classifies eligible /
  blocked / unknown and hands selected folders to `plan-archive-migrate`.
---

# Plan Archive Discover

## Contract

Prereqs:

- `plan-archive` is installed from the released nils-cli package and
  available on `PATH` (surface floor includes the `discover`
  subcommand).
- The archive repository is cloned locally and its path is resolvable
  from the machine-local config at
  `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml` (or passed with
  `--archive`). The skill never hardcodes the clone path.
- The working repo's `origin` remote, current branch, and `HEAD` are
  readable so source identity and target-path derivation match the
  migrate path.

Inputs:

- The working repo to scan, via `--source-repo` (defaults to the
  current git repo root).
- Optional `--plans-root`, `--archive`, and `--hosts` overrides.
- Optional `--include-unknown` to surface ambiguous candidates
  alongside the default eligible + blocked set.

Outputs:

- A discover JSON envelope (`cli.plan-archive.discover.v1`) with a
  `summary` (scanned / eligible / blocked / unknown counts) and a
  `candidates` array. Each candidate carries `plan_folder`,
  `source_path`, `status`, `reasons`, inferred `refs`, an
  `archive_target` preview, a `dirty` flag, and — for `eligible`
  folders — a single combined `suggested_migrate_command` that
  prefers self-referential issue / PR / MR refs.

Failure modes:

- The `plan-archive` binary is missing or below the surface floor that
  ships `discover`.
- The archive clone is unresolved or its `config/hosts.yaml` is
  missing.
- The source repo cannot be classified (unknown host, no `origin`).
- A folder is reported `blocked` (e.g. `no-provider-refs`,
  `archive-target-exists`, `dirty-source-folder`) or `unknown`
  (`closeout-evidence-uncertain`); these are CLI verdicts, not
  workflow errors. Never promote an `unknown` candidate to
  `eligible` by inventing closeout evidence.

## Entrypoint

Default scan (eligible + blocked):

```bash
plan-archive discover \
  --source-repo <repo-root> \
  --format json
```

Include ambiguous candidates for review:

```bash
plan-archive discover \
  --source-repo <repo-root> \
  --include-unknown \
  --format json
```

For each `eligible` candidate the user confirms, hand off to
`plan-archive-migrate` using the candidate's
`suggested_migrate_command` verbatim (dry-run first):

```bash
plan-archive migrate \
  --plan docs/plans/<YYYY-MM-DD>-<slug> \
  --issue <issue-url> \
  --format json
```

## Workflow

1. Run `plan-archive discover … --format json` against the working
   repo. Treat the output as read-only evidence — discover never
   touches source or archive repos.
2. Present the `summary` and each candidate's `status`, `reasons`,
   `refs`, and `archive_target.exists` so the user can choose which
   folders to migrate.
3. Surface `unknown` candidates only when the user asks for them
   (`--include-unknown`). Do not auto-promote them to `eligible`.
4. For each candidate the user selects, follow the
   `plan-archive-migrate` workflow: run the suggested dry-run command,
   present the report, and require explicit confirmation before
   `--apply`.
5. Discover stops at preselection. The skill never applies a
   migration, never deletes folders, and never commits.

## Boundary

`plan-archive discover` owns folder enumeration, source identity,
host classification, target-path derivation, ref inference, closeout
classification, and the suggested migrate-command shape. The skill
body owns when to run discovery, how to surface candidates for
selection, and the handoff to `plan-archive-migrate` for each
selected folder. It does not duplicate CLI logic, invent closeout
evidence, or call the migrate apply path itself.

## Related Skills

- `plan-archive-migrate` — single-folder destructive archival path
  that discover hands each selected folder off to. Discover never
  applies a migration itself.
- `plan-archive-query` — read past archived plans, issues, PRs, and
  MRs from the archive cache. Use it before opening new work or to
  cross-check an archive target that discover reports as already
  existing.
