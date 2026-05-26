# Plan Archive — agent-runtime-kit Skill Bodies Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-27
- Source: derived sub-plan slice of the master design at
  `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`.
- Intended next step: feed this document, together with the master
  discussion source, into `create-plan-tracking-issue`. The tracker
  issue is opened in `agent-runtime-kit`.

## Execution

- Recommended plan: docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-plan.md
- Recommended execution state: docs/plans/plan-archive-runtime-kit/plan-archive-runtime-kit-execution-state.md

## Purpose

Wire the deterministic `plan-archive` CLI surface (delivered by the
nils-cli sub-plan) into two user-facing skills in `agent-runtime-kit`,
update the placement / naming policy, and land manifest plus
validation coverage. The master discussion source carries the full
system design; this sub-plan slice exists so plan-tooling can attach a
sibling source document to the runtime-kit sub-plan structure.

## Read First

- Master design: `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`
  (Naming and layout, Configuration layering, Migration skill, Query
  skill, Retention of employer-sourced material, Risks And Guardrails).
- Sibling sub-plan: `docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-discussion-source.md`
  (must release before this sub-plan starts the skill-body work).
- One-shot prereq: archive repository bootstrap, recorded in the master
  discussion source. Must be done before runtime-smoke fixtures in
  this sub-plan exercise a real archive target.

## Decisions Lifted From The Master Source

- Both new skills live in the existing `meta` domain by default, unless
  plan execution finds a clean reason for a separate `plan-archive`
  domain.
- The migration skill always runs `plan-archive migrate --dry-run`
  first and requires explicit user confirmation before invoking
  `--apply`.
- The query skill reads cache by default, always surfaces `fetched_at`,
  and gates snapshot commits that triggered a `.scrub.log` behind
  explicit user review.
- The placement policy gains the
  `docs/plans/<YYYY-MM-DD>-<slug>/` rule for newly created plan
  folders. Pre-v1 slug-only folders are not retroactively renamed.

## Scope

- See `Scope` and `Out of scope` in the sibling plan.

## Acceptance Criteria

- See `Issue Closeout Gate` in the sibling plan.

## Retention Intent

- This document is plan-source material. It is cleanup-eligible after
  the sibling plan executes, unless the workflow is promoted to a
  maintained runbook elsewhere in the repo.
