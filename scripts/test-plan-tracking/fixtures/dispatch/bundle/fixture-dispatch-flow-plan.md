# Plan: Plan-Tracking Dispatch Flow Fixture

## Overview

A minimal, fully-frozen plan bundle used by the
`scripts/test-plan-tracking/` driver to exercise the **dispatch** profile
of the plan-issue skill family (`deliver-dispatch-plan` →
`execute-dispatch-lane` (×2) → `review-dispatch-lane-pr` (×2) →
`dispatch-plan-closeout`) against the `graysurf/plan-tracking-testbed`
repo. Two independent, append-only lanes against `notes.md` keep each
lane's diff real but tiny so the test focuses on the multi-lane
lifecycle, not the underlying work.

## Read First

- Primary source: `docs/plans/fixture-dispatch-flow/fixture-dispatch-flow-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: none

## Scope

- In scope: open one shared dispatch issue, run two task lanes (one PR
  each against the shared plan branch) with lane-scoped lifecycle
  evidence, review each lane PR, and close cleanly via
  `dispatch-plan-closeout`.
- Out of scope: code generation, multi-file refactors, CLI surface
  changes, anything touching tooling outside this repo.

## Assumptions

1. The testbed repo has no other open plan-tracking issues; reset ran
   before the flow started.
2. `plan-issue` and `plan-tooling` on PATH are at or above the floors
   declared by the source skills (currently `>=1.0.1`).
3. The driver supplies `OWNER_REPO=graysurf/plan-tracking-testbed` and a
   clean shared plan branch named `feat/dispatch-flow`; each lane bases
   its PR on that plan branch.

## Sprint 1: Two dispatch lanes

**Goal**: produce two appended lines in `notes.md` — one per lane — each
landed by its own lane PR, with full per-lane lifecycle evidence on the
shared dispatch issue.

Dispatch fan-out: the two lanes are structurally independent (one PR
each). The driver runs them sequentially to keep `notes.md`
conflict-free on merge into the shared plan branch.

**Demo/Validation**:

- Command(s): `git log --oneline -5`, `gh issue view <N> --comments`.
- Verify: both lane commits are present, the issue carries `source`,
  `plan`, `state` (initial), two lane-scoped `state` / `session` /
  `validation` checkpoints, two `review` decisions, and the closing
  `closeout` comment in order, all marked `profile=dispatch`.

### Task 1.1: Lane A — append line A to notes.md

- **Location**:
  - `notes.md`
- **Description**: append one dated line `- <ISO date>: dispatch lane A
  (task 1.1) ran.` under the `## Log` section.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - `notes.md` grows by exactly one line.
  - The change lands via a lane PR based on `feat/dispatch-flow`.
- **Validation**:
  - `git diff HEAD~1 -- notes.md` shows a single `+` line.

### Task 1.2: Lane B — append line B to notes.md

- **Location**:
  - `notes.md`
- **Description**: append one dated line `- <ISO date>: dispatch lane B
  (task 1.2) ran.` under the `## Log` section.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - `notes.md` grows by exactly one line.
  - The change lands via a lane PR based on `feat/dispatch-flow`.
- **Validation**:
  - `git diff HEAD~1 -- notes.md` shows a single `+` line.

## Testing Strategy

- Unit: none — this fixture exists to drive the skill series, not to
  exercise production code.
- Integration: the driver's `lib/assert.sh` reads the resulting dispatch
  issue via `gh` and checks per-lane lifecycle comment shape, the
  `profile=dispatch` markers, the dispatch dashboard naming every lane
  PR, and the merged lane PRs.
- E2E/manual: the agent runs `deliver-dispatch-plan` →
  `execute-dispatch-lane` (×2) → `review-dispatch-lane-pr` (×2) →
  `dispatch-plan-closeout` interactively, pausing at each phase for the
  driver to snapshot state.

## Risks & gotchas

- The fixture is reused across runs; the driver must wipe the testbed
  (close issues, delete branches, drop the bundle directory) before each
  run, or the open step will refuse with `tracker-already-exists`.
- `notes.md` accumulates lines across runs; the reset script truncates
  it back to the bootstrap state. Lanes run sequentially so their
  appends do not conflict on merge into the shared plan branch.

## Rollback plan

- Close the dispatch issue, delete the plan branch and every lane
  branch, restore `notes.md` from the initial commit. The driver's
  `teardown.sh` performs all three.
