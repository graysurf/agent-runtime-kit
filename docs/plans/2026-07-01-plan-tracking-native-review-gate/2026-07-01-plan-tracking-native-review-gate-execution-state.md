# Execution State: Align deliver-plan-tracking-issue to deliver-pr's native bot code review

## Execution State

- Source document: docs/plans/2026-07-01-plan-tracking-native-review-gate/2026-07-01-plan-tracking-native-review-gate-plan.md
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/491>
- Current sprint: Sprint 1 (not started)
- Status: ready-to-start
- Branch: feat/plan-tracking-native-review-gate
- Last updated: 2026-07-01

## Task Ledger

| ID | Title | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | Update the Contract (floor, prereqs, references, policy) | pending |  | forge-cli 1.11.2->1.17.0; add review-specialists; reference gate + posting contract; drop single-author exception |
| 1.2 | Rewrite the Entrypoint + Workflow PR/Review steps to Shape 1 | pending |  | adapt review-dispatch-lane-pr block to --profile tracking; issue-side review checkpoint before merge |
| 1.3 | Render three products + refresh goldens | pending |  | source has no product conditionals; golden diff must be clean |
| 2.1 | Bump the deliver-dispatch-plan forge-cli floor | pending |  | 1.11.2->1.17.0; behavior unchanged; re-render + goldens |
| 2.2 | Full declared validation | pending |  | bring host on-pin first; scripts/ci/all.sh + tests/hooks/run.sh |
| 2.3 | Testbed live review-event round trip | pending |  | native APPROVE URL -> tracking review checkpoint -> close-ready; record the record-audit ordering observation |

## Validation Log

- 2026-07-01: bundle authored from the deliver-plan-tracking-issue vs deliver-pr feasibility discussion (trigger: sympoies/nils-cli#1000 had no native review event). Decisions locked: Shape 1, single-author always runs the full gate, dispatch-family consistency in scope.

## Session Notes

- 2026-07-01: Confirmed no CLI capability gap — pin `v1.20.1` / `forge-cli 1.17.0` already exposes every surface `deliver-pr` uses; `review-dispatch-lane-pr` is the proven native-review template. Shape 1 chosen because it sidesteps `deliver-pr`'s pre-merge linked-issue audit ordering tension (`forge-cli pr merge` only fails closed on unresolved threads / unchecked tasks, not on the lifecycle audit).
- 2026-07-01: Host toolchain observed off-pin at authoring time (`plan-tooling 1.20.3` vs pin `v1.20.1`); must be brought on-pin before the position-2 version-alignment gate in `scripts/ci/all.sh`.
