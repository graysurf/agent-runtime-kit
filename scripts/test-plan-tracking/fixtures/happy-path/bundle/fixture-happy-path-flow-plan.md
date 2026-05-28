# Plan: Plan-Tracking Happy Path Flow Fixture

## Overview

A minimal, fully-frozen plan bundle used by the
`scripts/test-plan-tracking/` driver to exercise the plan-tracking
issue skill series (`create-plan-tracking-issue` →
`execute-plan-tracking-issue` → `plan-tracking-issue-closeout`)
against the `graysurf/plan-tracking-testbed` repo. Two trivial
append-only tasks against `notes.md` keep the diff real but tiny so
the test focuses on the lifecycle comments, not the underlying work.

## Read First

- Primary source: `docs/plans/fixture-happy-path-flow/fixture-happy-path-flow-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: none

## Scope

- In scope: append two dated lines to `notes.md`, commit each line as
  one task, post the corresponding lifecycle comments on the tracking
  issue, and close cleanly via `plan-tracking-issue-closeout`.
- Out of scope: code generation, multi-file refactors, CLI surface
  changes, lane fan-out, anything touching tooling outside this
  repo.

## Assumptions

1. The testbed repo has no other open plan-tracking issues; reset
   ran before the flow started.
2. `plan-issue` and `plan-tooling` on PATH are at or above the floors
   declared by the source skills (currently `>=0.22.3`).
3. The driver supplies `OWNER_REPO=graysurf/plan-tracking-testbed`
   and a clean branch named `test/happy-path-flow`.

## Sprint 1: Append two notes

**Goal**: produce two appended lines in `notes.md` with full
lifecycle evidence on the tracking issue.

**Demo/Validation**:

- Command(s): `git log --oneline -3`, `gh issue view <N> --comments`.
- Verify: both task commits are present, the issue carries
  `source`, `plan`, `state` (initial), per-task `state` updates, and
  the closing `closeout` comment in order.

### Task 1.1: Append line A to notes.md

- **Location**:
  - `notes.md`
- **Description**: append one dated line `- <ISO date>: task 1.1
  ran.` under the `## Log` section.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - `notes.md` grows by exactly one line.
  - Commit subject begins with `chore:`.
- **Validation**:
  - `git diff HEAD~1 -- notes.md` shows a single `+` line.

### Task 1.2: Append line B to notes.md

- **Location**:
  - `notes.md`
- **Description**: append one dated line `- <ISO date>: task 1.2
  ran.` under the `## Log` section.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - `notes.md` grows by exactly one line.
  - Commit subject begins with `chore:`.
- **Validation**:
  - `git diff HEAD~1 -- notes.md` shows a single `+` line.

## Testing Strategy

- Unit: none — this fixture exists to drive the skill series, not to
  exercise production code.
- Integration: the driver's `assert-shape.sh` reads the resulting
  tracking issue via `gh api` and checks lifecycle comment shape and
  label order.
- E2E/manual: the agent runs `create-plan-tracking-issue` →
  `execute-plan-tracking-issue` → `plan-tracking-issue-closeout`
  interactively, pausing at each checkpoint for the driver to
  snapshot state.

## Risks & gotchas

- The fixture is reused across runs; the driver must wipe the
  testbed (close issues, delete branches, drop the bundle directory)
  before each run, or the create skill will refuse with
  `tracker-already-exists`.
- `notes.md` accumulates lines across runs; the reset script
  truncates it back to the bootstrap state.

## Rollback plan

- Close the tracking issue, delete the test branch, restore
  `notes.md` from the initial commit. The driver's `reset.sh`
  performs all three.
