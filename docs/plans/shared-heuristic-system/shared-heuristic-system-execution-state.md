# Shared Heuristic System Execution State

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: in-progress
- Target scope: Sprint 1 shared policy and runtime guidance
- Execution window: Sprint 1
- Current task: create tracking issue and begin Task 1.1
- Next task: add shared Heuristic System root and migrate retained records
- Last updated: 2026-05-23
- Branch/commit/PR: feat/shared-heuristic-system; pending
- Source document: docs/plans/shared-heuristic-system/shared-heuristic-system-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending

## Validation Plan

- `plan-tooling validate --file docs/plans/shared-heuristic-system/shared-heuristic-system-plan.md --format text --explain`
- `heuristic-inbox verify core/policies/heuristic-system/error-inbox/archive/2026/deliver-gitlab-mr-skipped-pipeline-and-cleanup --strict --format json`
- `heuristic-inbox verify core/policies/heuristic-system/operation-records/github-pr-required-check-gating --strict --format json`
- `heuristic-inbox list --inbox-dir "$PWD/core/policies/heuristic-system/error-inbox" --include-archived --format json`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `git diff --exit-code -- tests/golden/`
- `agent-runtime audit-drift`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash scripts/ci/all.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add shared Heuristic System root and migrate retained records | pending | Include legacy source inspection. |
| 1.2 | pending | Update architecture and rendered workflow surfaces | pending | Refresh render and golden output. |
| 1.3 | pending | Add deterministic shared-root validation | pending | Meta smoke should validate explicit shared-root behavior. |

## Session Log

- 2026-05-23: Created implementation plan and initial execution state from the discussion source.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| pending | pending | No implementation validation recorded yet. | n/a |

## Notes

- The released `heuristic-inbox 0.17.4` CLI exposes `--inbox-dir` for list and
  accepts explicit case paths for verify/update/archive operations. This plan
  treats that as sufficient for the runtime-kit slice and leaves a future
  nils-cli `--system-root` convenience flag as optional follow-up.
