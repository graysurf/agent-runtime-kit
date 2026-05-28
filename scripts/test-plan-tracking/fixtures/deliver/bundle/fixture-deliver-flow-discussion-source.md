# Plan-Tracking Deliver Flow Fixture Source

- Status: ready for plan generation
- Date: 2026-05-29
- Source: synthetic — authored as a frozen fixture for the
  `agent-runtime-kit/scripts/test-plan-tracking/` driver, not from a
  real user discussion.
- Intended next step: copy this bundle into
  `graysurf/plan-tracking-testbed` at
  `docs/plans/fixture-deliver-flow/`, then open the tracking issue
  via `create-plan-tracking-issue`.

## Execution

This document feeds **one** plan executed as a single sprint with
two serial append-only tasks against `notes.md` in the testbed, then
delivered through a single merged PR.

- Recommended plan: `docs/plans/fixture-deliver-flow/fixture-deliver-flow-plan.md`
- Recommended execution state: `docs/plans/fixture-deliver-flow/fixture-deliver-flow-execution-state.md`
- Status: ready to implement immediately
- Next-task source: this document

## Purpose

Exercise the plan-tracking deliver flow end to end against a real
GitHub repo without the noise of a production-grade plan. The
fixture is intentionally small enough that any drift in lifecycle
comment shape, the review-role checkpoint, the PR delivery handoff,
or the close-ready audit gates shows up clearly in the driver's
`assert.sh` output rather than being swamped by legitimate variance
from a complex plan.

## Decisions

- **Single bundle, two tasks, one PR**: keeps the task ledger small
  enough that field presence checks are easy to read while still
  proving the per-task `state` update path runs at least twice and
  the final delivery flow renders a single review-role checkpoint.
- **`notes.md` append-only**: avoids merge conflicts across reruns
  and keeps the diff trivially auditable when the PR is opened.
- **Frozen fixture, mutable testbed**: the bundle source lives in
  `agent-runtime-kit/scripts/test-plan-tracking/fixtures/deliver/`
  and is copied (not symlinked) into the testbed at run start so the
  testbed's working copy is fully expendable.
- **`feat/` branch prefix**: `forge-cli pr create` enforces the
  `^(feat|fix|chore|docs|ci|refactor)/...` rule, and `forge-cli pr
  deliver` calls that internally; using `feat/deliver-flow` keeps
  the fixture aligned with the rule without requiring a waiver.

## Out of Scope

- Lane fan-out across multiple sprints (will live under a future
  `fixtures/lane-fanout/` set).
- Edge cases such as empty validation blocks, retry checkpoints, or
  ledger drift (covered by later named fixtures once the deliver
  path is stable).
- Adversarial inputs (malformed plan, missing source, etc.) — those
  will live under `fixtures/error-cases/` if/when failure-mode
  testing is added.

## References

- `agent-runtime-kit/core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
- `agent-runtime-kit/core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- `agent-runtime-kit/core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- `agent-runtime-kit/core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
