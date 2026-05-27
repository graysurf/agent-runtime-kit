# Plan Archive Discover Discussion Source

## Source

- [U1] User asked whether `plan-archive-migrate` could be used without a
  specific folder so an agent can inspect all archive-eligible plans first.
- [U2] Advisor response: keep `plan-archive-migrate` single-plan and
  dry-run-first; add a read-only discovery wrapper before migration.
- [U3] User asked whether the discovery wrapper should be only a skill or a CLI
  capability; advisor recommended Option B: a read-only CLI subcommand with a
  thin skill wrapper.
- [U4] User selected Option B and required the work to happen in a separate
  worktree to avoid conflicting with other agents.
- [F1] `plan-archive-migrate` skill contract requires a single plan folder and
  at least one provider reference, and gates apply on explicit confirmation.
- [F2] `docs/source/docs-placement-retention-policy-v1.md` says new plan
  bundles use `docs/plans/<YYYY-MM-DD>-<slug>/`.

## Problem

`plan-archive-migrate` is deliberately scoped to one plan folder. That is the
right destructive boundary because apply creates archive and source-repo
deletion commits. However, users also need a safe way to ask, "Which plan
folders in this repo look ready to archive?" without manually inspecting every
folder and without letting an agent invent inconsistent eligibility rules.

Putting that discovery logic only in a skill would make the behavior hard to
test and easy to drift from the CLI's source identity, host classification,
archive target, and migration preflight rules.

## Decision

Implement Option B:

- Add a read-only `plan-archive discover` CLI command in `nils-cli`.
- Reuse the same source-repo, archive, host, and target-path logic that
  `plan-archive migrate` uses.
- Return structured JSON that classifies plan folders as `eligible`, `blocked`,
  or `unknown`.
- Add a new `plan-archive-discover` skill in `agent-runtime-kit` that only
  presents the CLI output and hands selected folders to `plan-archive-migrate`
  for per-folder dry-run and explicit confirmation.

## Target Outcome

An agent or human can run one read-only command to enumerate archive candidates
for a working repo. The command must not copy, delete, commit, push, refresh
provider state, or call destructive migration paths. The skill must not apply a
migration directly; it only narrows candidate selection and then delegates each
chosen folder to the existing migrate workflow.

## Execution

- Recommended plan:
  docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-plan.md
- Recommended execution state:
  docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-execution-state.md

## Non-Goals

- Bulk apply or automatic migration.
- Folding discovery into `plan-archive migrate` without `--plan`.
- Replacing `plan-archive-query` or the archive catalog/search work.
- Provider refresh during discovery; local evidence is enough for candidate
  classification, and uncertain cases should be reported as `unknown`.

## Key Constraints

- Discovery is read-only by default and must be safe in dirty working repos.
- The implementation should be testable in `nils-cli` fixtures, not embedded in
  agent-specific heuristics.
- The skill should remain a thin orchestration layer, matching the existing
  CLI-owned boundary of `plan-archive-migrate`.
- The work must proceed on its own branch/worktree so it does not conflict with
  concurrent plan-archive work.

## Open Questions

- Exact closeout markers that should make a folder `eligible` versus `unknown`
  should be finalized from existing execution-state and migrated-plan fixtures.
- Whether `plan-archive discover` should suggest one combined migration command
  or one command per provider ref should be decided after reviewing the current
  migrate argument parser and metadata payload shape.
