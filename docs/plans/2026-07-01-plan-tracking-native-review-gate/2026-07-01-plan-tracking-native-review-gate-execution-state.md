# Execution State: Align deliver-plan-tracking-issue to deliver-pr's native bot code review

## Execution State

- Source document: docs/plans/2026-07-01-plan-tracking-native-review-gate/2026-07-01-plan-tracking-native-review-gate-plan.md
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/491>
- Current sprint: Sprint 1 (complete); Sprint 2 in progress
- Status: Sprint 1 + Task 2.1 implemented on branch; on-pin substitute validation green; full gate + testbed pending
- Branch: feat/plan-tracking-native-review-gate
- Last updated: 2026-07-01

## Task Ledger

| ID | Title | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | Update the Contract (floor, prereqs, references, policy) | done | commit b4adf4d4 | forge-cli 1.17.0 + review-specialists; references gate + posting contract; single-author exception removed |
| 1.2 | Rewrite the Entrypoint + Workflow PR/Review steps to Shape 1 | done | commit b4adf4d4 | pr deliver --no-merge -> gate -> pr review --submit-review -> sweeps -> review checkpoint -> pr merge; adapted from review-dispatch-lane-pr |
| 1.3 | Render three products + refresh goldens | done | commit b4adf4d4 | rendered on-pin v1.20.1; golden diff scoped to the 3 tracking goldens; git diff --exit-code clean |
| 2.1 | Bump the deliver-dispatch-plan forge-cli floor | done | commit 6e7350ba | 1.17.0; behavior unchanged; 3 dispatch goldens refreshed on-pin |
| 2.2 | Full declared validation | in-progress | on-pin substitute: governance OK, audit-drift clean, dispatch runtime-smoke pass, hooks 91 OK | full scripts/ci/all.sh blocked until host agent-runtime is on-pin (v1.20.1); host is 1.20.5 |
| 2.3 | Testbed live review-event round trip | pending |  | native APPROVE URL -> tracking review checkpoint -> close-ready; record the record-audit ordering observation |

## Validation Log

- 2026-07-01: bundle authored from the deliver-plan-tracking-issue vs deliver-pr feasibility discussion (trigger: sympoies/nils-cli#1000 had no native review event). Decisions locked: Shape 1, single-author always runs the full gate, dispatch-family consistency in scope.
- 2026-07-01: on-pin substitute validation via `scripts/dev/with-nils-version.sh release:v1.20.1` (host is 1.20.5, off-pin) — `skill-governance-audit.sh` repo OK (desc 237/240); `agent-runtime render --product {codex,claude,hermes}` succeeded; golden refresh scoped to exactly the 6 expected files; `git diff --exit-code -- tests/golden/` clean; `audit-drift` clean (20 findings, all documented); `runtime-smoke --mode deterministic --domain dispatch` all pass incl. `dispatch.deliver-plan-tracking-issue`; `tests/hooks/run.sh` 91 tests OK.
- 2026-07-01: full `scripts/ci/all.sh` NOT run — Position 2 version-alignment fails closed on the off-pin host (1.20.5 vs pin v1.20.1) by design. Deferred to Task 2.2 once the host is on-pin (or the pin is bumped to the released line via meta:nils-cli-bump — a separate decision). Test-first waiver: skill-contract (orchestration prose) change; mechanical validation is render-golden + governance (done on-pin); behavioral validation is the deferred Task 2.3 testbed live run.

## Session Notes

- 2026-07-01: Confirmed no CLI capability gap — pin `v1.20.1` / `forge-cli 1.17.0` already exposes every surface `deliver-pr` uses; `review-dispatch-lane-pr` is the proven native-review template. Shape 1 chosen because it sidesteps `deliver-pr`'s pre-merge linked-issue audit ordering tension (`forge-cli pr merge` only fails closed on unresolved threads / unchecked tasks, not on the lifecycle audit).
- 2026-07-01: Host toolchain observed off-pin at authoring time (`agent-runtime 1.20.5`, `plan-tooling 1.20.3` vs pin `v1.20.1`); must be brought on-pin before the position-2 version-alignment gate in `scripts/ci/all.sh`. All on-pin content gates were run via the `with-nils-version.sh release:v1.20.1` wrapper.
- 2026-07-01: Sprint 1 (1.1-1.3) + Task 2.1 implemented on branch `feat/plan-tracking-native-review-gate` in two commits (b4adf4d4 tracking review gate; 6e7350ba dispatch floor bump). Next: bring host on-pin for the full gate (Task 2.2), then the testbed live run (Task 2.3), then PR delivery through the newly-aligned deliver-plan-tracking-issue itself.
