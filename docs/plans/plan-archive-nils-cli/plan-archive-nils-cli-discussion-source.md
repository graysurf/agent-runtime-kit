# Plan Archive — nils-cli Capabilities Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-27
- Source: derived sub-plan slice of the master design at
  `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`.
- Intended next step: feed this document, together with the master
  discussion source, into `create-plan-tracking-issue`. The tracker
  issue is opened in `sympoies/nils-cli`.

## Execution

- Recommended plan: docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-plan.md
- Recommended execution state: docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-execution-state.md

## Purpose

Carve out the deterministic CLI surface that the plan-archive skills in
`agent-runtime-kit` will call. The master discussion source captures
the full system design; this sub-plan slice exists so plan-tooling can
attach a sibling source document to the `agent-runtime-kit`-owned
plan-tooling structure while the actual implementation work lands in
`sympoies/nils-cli`.

## Read First

- Master design: `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`
  (Configuration layering, Index / cache, Migration skill, Query skill,
  Retention of employer-sourced material, Risks And Guardrails).
- Sibling sub-plan: `docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-discussion-source.md`
  (consumes the CLI capabilities authored under this plan).
- One-shot prereq: archive repository bootstrap, recorded in the master
  discussion source.

## Decisions Lifted From The Master Source

- The CLI binary owns three subcommands plus three schema validators
  and a secret-scrub library. Subcommand contract follows the master
  design's `Migration skill`, `Index / cache`, and `Query skill`
  sections.
- The CLI never owns provider authentication; all forge calls delegate
  to the existing `forge-cli` surface.
- The CLI never owns commit creation; `plan-archive migrate --apply`
  invokes the released `semantic-commit` binary.
- Snapshot writes are append-only ISO8601 files with optional
  `<ISO8601>.scrub.log` siblings, never overwriting and never deleting
  earlier snapshots.
- Output of every subcommand is JSON shaped per the existing
  `cli.<command>.<sub>.v1` convention.

## Scope

- See `Scope` and `Out of scope` in the sibling plan.

## Acceptance Criteria

- See `Issue Closeout Gate` in the sibling plan.

## Retention Intent

- This document is plan-source material. It is cleanup-eligible after
  the sibling plan executes, unless the workflow is promoted to a
  maintained runbook elsewhere in the repo.
