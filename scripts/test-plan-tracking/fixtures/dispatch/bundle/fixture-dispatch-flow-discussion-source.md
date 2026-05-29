# Plan-Tracking Dispatch Flow Fixture Source

- Status: ready for plan generation
- Date: 2026-05-29
- Source: synthetic — authored as a frozen fixture for the
  `agent-runtime-kit/scripts/test-plan-tracking/` driver, not from a
  real user discussion.
- Intended next step: copy this bundle into
  `graysurf/plan-tracking-testbed` at `docs/plans/fixture-dispatch-flow/`,
  then open the shared dispatch issue via `deliver-dispatch-plan`
  (`record open --profile dispatch`).

## Execution

This document feeds **one** plan executed under the **dispatch** profile
as a single sprint fanned out into two independent task lanes, each
landing its own lane PR against the shared plan branch.

- Recommended plan: `docs/plans/fixture-dispatch-flow/fixture-dispatch-flow-plan.md`
- Recommended execution state: `docs/plans/fixture-dispatch-flow/fixture-dispatch-flow-execution-state.md`
- Status: ready to implement immediately
- Next-task source: this document

## Purpose

Exercise the **dispatch** profile of the plan-issue skill family end to
end against a real GitHub repo:

- One shared dispatch issue opened with `record open --profile dispatch`.
- Two independent lanes, each driven by `execute-dispatch-lane`, each
  producing its own lane PR against the shared plan branch and its own
  lane-scoped `state` / `session` / `validation` checkpoint.
- One lane review per lane via `review-dispatch-lane-pr`.
- Dispatch-level rollup + non-mutating close-ready handoff via
  `deliver-dispatch-plan`, then closure via `dispatch-plan-closeout`.

The tracking profile is already covered by the `happy-path` and
`deliver` fixtures. Dispatch was previously only spot-verified through a
single `tracking checkpoint --profile dispatch` call
(graysurf/plan-tracking-testbed#28). This fixture makes the multi-lane
orchestration path a first-class, repeatable e2e.

## Decisions

- **Single bundle, two lanes**: keeps the task ledger small while still
  proving the per-lane `state` / `session` / `validation` checkpoint
  path runs at least twice, each marked `profile=dispatch`.
- **`notes.md` append-only**: each lane appends one dated line; lanes run
  sequentially so their appends never conflict on merge into the shared
  plan branch.
- **Frozen fixture, mutable testbed**: the bundle source lives in
  `agent-runtime-kit/scripts/test-plan-tracking/fixtures/dispatch/` and
  is copied (not symlinked) into the testbed at run start so the
  testbed's working copy is fully expendable.

## Out of Scope

- More than two lanes, cross-lane dependencies, or true concurrent
  execution (the driver runs lanes sequentially).
- Edge cases such as blocked / waived lanes, retry checkpoints, or
  ledger drift.
- Adversarial inputs (malformed plan, missing source, etc.).

## References

- `agent-runtime-kit/core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `agent-runtime-kit/core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- `agent-runtime-kit/core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `agent-runtime-kit/core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
