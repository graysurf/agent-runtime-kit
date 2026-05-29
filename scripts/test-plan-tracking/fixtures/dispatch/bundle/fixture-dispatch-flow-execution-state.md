# Plan-Tracking Dispatch Flow Fixture Execution State

<!-- plan-issue-record:v2 role=state profile=dispatch -->
## Execution State

- Status: ready-to-start; dispatch issue not yet opened.
- Target scope: two independent append-only lanes against `notes.md` in
  `graysurf/plan-tracking-testbed`, one lane PR each, with full per-lane
  lifecycle evidence on the shared dispatch issue.
- Execution window: Sprint 1 (single sprint, two parallel lanes).
- Current task: none (dispatch issue not yet opened).
- Next task: Task 1.1 — dispatch lane A.
- Last updated: 2026-05-29
- Plan branch: `feat/dispatch-flow` (shared integration base created by
  the driver before the flow starts; each lane PR targets it).
- Lane branches: `feat/dispatch-flow-lane-1` (Task 1.1),
  `feat/dispatch-flow-lane-2` (Task 1.2) — created per lane.
- Source document: `docs/plans/fixture-dispatch-flow/fixture-dispatch-flow-plan.md`
- Direct source-doc execution waiver: not applicable
- Dispatch issue: tbd (opened by `deliver-dispatch-plan` via
  `record open --profile dispatch` against `graysurf/plan-tracking-testbed`)
- Source snapshot: pending — posted at issue open
- Plan snapshot: pending — posted at issue open
- Initial state snapshot: pending — posted at issue open

## Validation Plan

- Per-lane: `git diff HEAD~1 -- notes.md` shows a single added line.
- End-of-flow: `gh issue view <N> --repo graysurf/plan-tracking-testbed
  --json comments` returns `profile=dispatch` lifecycle markers in the
  expected order (source → plan → state → per-lane state/session/
  validation → review → closeout) and the dispatch dashboard names
  every lane PR.
- The driver's `scripts/test-plan-tracking/lib/assert.sh` consumes that
  JSON and verifies field presence, profile, lane PR merge, and label
  transitions.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Lane A — append line A to notes.md | — | Lane PR on `feat/dispatch-flow-lane-1`. |
| 1.2 | pending | Lane B — append line B to notes.md | — | Lane PR on `feat/dispatch-flow-lane-2`. |
