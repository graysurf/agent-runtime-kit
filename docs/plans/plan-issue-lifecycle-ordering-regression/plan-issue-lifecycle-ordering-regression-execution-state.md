# Plan Issue Lifecycle Ordering Regression Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: ready for issue-backed planning
- Target scope: restore issue-visible plan lifecycle ordering and required
  session evidence for v2 plan issue records.
- Execution window: Sprint 1-3
- Current task: create issue-backed tracking record.
- Next task: Task 1.1 - add missing-session closeout regression fixture.
- Last updated: 2026-05-26
- Branch/commit/PR: pending commit
- Source document:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Discussion source:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-discussion-source.md
- Plan document:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Execution state:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-execution-state.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add missing-session closeout regression fixture | n/a | Model #117's closed issue with no `role=session` and `Latest session: pending`. |
| 1.2 | pending | Add #28-like complete lifecycle success fixture | n/a | Prove v2 state/session/validation/review/closeout timeline succeeds. |
| 1.3 | pending | Define nils-cli readiness and closeout enforcement boundary | n/a | Decide release/consume boundary for readiness and missing-session enforcement. |
| 2.1 | pending | Make session posting explicit in plan delivery skills | n/a | Add canonical `record post --kind session` command shape. |
| 2.2 | pending | Add pre-merge lifecycle readiness to PR and MR delivery | n/a | Keep closeout post-merge but block linked plan merges before readiness. |
| 2.3 | pending | Align closeout skills with required session evidence | n/a | Closeout should reject missing required session evidence. |
| 3.1 | pending | Consume released nils-cli readiness support when required | n/a | Refresh semver floors and surface docs only after release. |
| 3.2 | pending | Run full render, smoke, and governance gates | n/a | Full runtime-kit validation after skill and fixture changes. |
| 3.3 | pending | Perform live GitHub lifecycle rehearsal and closeout | n/a | Use this tracker to prove session is present before closeout. |

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `agent-docs resolve --context task-tools --strict --format checklist`
- `plan-tooling validate --file <plan> --format text --explain`
- `rumdl check docs/plans/plan-issue-lifecycle-ordering-regression/*.md`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `bash scripts/ci/all.sh`

## Session Log

- 2026-05-26: Created discussion source from live comparison of issue #28 and
  issue #117 plus local skill and `plan-issue` CLI inspection.
- 2026-05-26: Created initial plan and execution-state bundle for issue-backed
  tracking.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Project development docs present. | n/a |
| `agent-docs resolve --context task-tools --strict --format checklist` | passed | Task tooling docs present for provider and external checks. | n/a |

## Residual Risk

- Missing-session enforcement may require a nils-cli release before runtime-kit
  can replace skill-level guidance with a hard CLI gate.
- Existing open v2 plan records without session comments may need an explicit
  waiver or migration path if closeout becomes strict by default.
