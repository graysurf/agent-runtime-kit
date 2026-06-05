# Plan: Plan-Tracking Deliver Flow Fixture

## Overview

A minimal, fully-frozen plan bundle used by the
`scripts/test-plan-tracking/` driver to exercise the four-skill
plan-tracking deliver flow (`create-plan-tracking-issue` →
`execute-plan-tracking-issue` → `deliver-plan-tracking-issue` →
`plan-tracking-issue-closeout`) against the
`graysurf/plan-tracking-testbed` repo. Two trivial append-only tasks
against `notes.md` keep the diff real but tiny so the test focuses
on the lifecycle comments, the review checkpoint, and the PR
delivery handoff, not the underlying work.

## Read First

- Primary source: `docs/plans/fixture-deliver-flow/fixture-deliver-flow-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: none

## Scope

- In scope: append two dated lines to `notes.md`, commit each line as
  one task on a `feat/deliver-flow` branch, post the corresponding
  lifecycle comments on the tracking issue, open and merge a PR via
  `forge-cli pr deliver`, post the review checkpoint, and close
  cleanly via `plan-tracking-issue-closeout`.
- Out of scope: code generation, multi-file refactors, CLI surface
  changes, lane fan-out across multiple sprints, anything touching
  tooling outside this repo.

## Assumptions

1. The testbed repo has no other open plan-tracking issues; reset
   ran before the flow started.
2. `plan-issue` and `plan-tooling` on PATH are at or above the floors
   declared by the source skills (currently `>=1.0.1`).
3. The testbed has no required CI checks configured, so `forge-cli
   pr deliver` will resolve `wait-checks` immediately and proceed to
   the merge step.
4. The driver supplies `OWNER_REPO=graysurf/plan-tracking-testbed`
   and a clean branch named `feat/deliver-flow`.

## Sprint 1: Append two notes, deliver via PR

**Goal**: produce two appended lines in `notes.md` with full
lifecycle evidence on the tracking issue, then ship them through one
merged PR.

**Demo/Validation**:

- Command(s): `git log --oneline -5`, `gh issue view <N> --comments`,
  `gh pr view <PR>`.
- Verify: both task commits are present, the issue carries `source`,
  `plan`, `state` (initial), per-task `state` updates, the `review`
  checkpoint with `decision=approve`, and the closing `closeout`
  comment in order; the linked PR is merged.

### Task 1.1: Append line A to notes.md

- **Location**:
  - `notes.md`
- **Description**: append one dated line `- <ISO date>: deliver task
  1.1 ran.` under the `## Log` section.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - `notes.md` grows by exactly one line.
  - Commit subject begins with `feat:` or `chore:`.
- **Validation**:
  - `git diff HEAD~1 -- notes.md` shows a single `+` line.

### Task 1.2: Append line B to notes.md

- **Location**:
  - `notes.md`
- **Description**: append one dated line `- <ISO date>: deliver task
  1.2 ran.` under the `## Log` section.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - `notes.md` grows by exactly one line.
  - Commit subject begins with `feat:` or `chore:`.
- **Validation**:
  - `git diff HEAD~1 -- notes.md` shows a single `+` line.

## Testing Strategy

- Unit: none — this fixture exists to drive the skill series, not to
  exercise production code.
- Integration: the driver's `assert.sh` reads the resulting tracking
  issue via `gh issue view` and the linked PR via `gh pr view`, and
  checks lifecycle comment shape, the review-role marker, and the
  rendered Task Ledger rows.
- E2E/manual: the agent runs `create-plan-tracking-issue` →
  `execute-plan-tracking-issue` → `deliver-plan-tracking-issue` →
  `plan-tracking-issue-closeout` interactively, pausing at each
  checkpoint for the driver to snapshot state.

## Risks & gotchas

- The fixture is reused across runs; the driver must wipe the
  testbed (close issues, delete branches, drop the bundle directory)
  before each run.
- The testbed has no required CI workflows; `forge-cli pr deliver`
  will move directly from open → wait-checks (0 required) →
  ready → merge. If a real CI workflow is added to the testbed
  later, the driver should pass `--check-strategy required-only` or
  similar to keep this fixture stable.
- `notes.md` accumulates lines across runs; the reset script
  truncates it back to the bootstrap state.

## Rollback plan

- Close the tracking issue, delete the PR (if open) or revert the
  merge commit on `main`, delete the test branch, restore `notes.md`
  from the initial commit. The driver's `teardown.sh` performs all
  of these except the merge-commit revert; the user does that
  manually if the test left a merged PR behind.
