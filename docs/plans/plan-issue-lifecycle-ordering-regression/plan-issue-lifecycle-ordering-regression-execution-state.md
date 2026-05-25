# Plan Issue Lifecycle Ordering Regression Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: tracking issue open; ready for execution
- Target scope: restore issue-visible plan lifecycle ordering and required
  session evidence for v2 plan issue records.
- Execution window: Sprint 1-3
- Current task: Task 1.1 - add missing-session closeout regression fixture.
- Next task: execute Sprint 1 regression fixture and nils-cli boundary tasks.
- Last updated: 2026-05-26
- Branch/commit/PR: tracking bundle commit `bedfffc`
- Source document:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Discussion source:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-discussion-source.md
- Plan document:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Execution state:
  docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-execution-state.md
- Direct source-doc execution waiver: not applicable
- Tracking issue:
  <https://github.com/graysurf/agent-runtime-kit/issues/120>
- Source snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/120#issuecomment-4536392644>
- Plan snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/120#issuecomment-4536392741>
- Initial state snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/120#issuecomment-4536392828>

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
- 2026-05-26: Committed and pushed tracking bundle as `bedfffc`, opened
  tracking issue #120 with `plan-issue record open`, and read-back audited the
  source, plan, and initial state lifecycle comments.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Project development docs present. | n/a |
| `agent-docs resolve --context task-tools --strict --format checklist` | passed | Task tooling docs present for provider and external checks. | n/a |
| `plan-tooling validate --file docs/plans/plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md --format json` | passed | Plan bundle validates with no errors. | local output |
| `rumdl check docs/plans/plan-issue-lifecycle-ordering-regression/*.md` | passed | Markdown passed for source, plan, and execution-state files. | local output |
| `forge-cli label ensure --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --format json` | passed | Label catalog already matched provider state. | local output |
| `plan-issue record open --dry-run --profile tracking --bundle docs/plans/plan-issue-lifecycle-ordering-regression --format json` | passed | Preview generated dashboard plus source, plan, and state lifecycle comments. | local output |
| `plan-issue record open --profile tracking --bundle docs/plans/plan-issue-lifecycle-ordering-regression --format json` | passed | Opened issue #120 and posted source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-023453-plan-issue-lifecycle-ordering-regression/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file issue-120-body.md --comments-json issue-120.json --format json` | passed | Read-back audit recognized source, plan, and state lifecycle comments with no missing required markers. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-023453-plan-issue-lifecycle-ordering-regression/issue-120-audit.json` |
| `rg` state-comment shape check | passed | Initial state comment contains visible execution state, folded task ledger, and hidden payload carrier. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-023453-plan-issue-lifecycle-ordering-regression/issue-120-state-comment.md` |
| `bash scripts/ci/all.sh` | passed | Pre-push hook ran positions 1-13 successfully before pushing `bedfffc`. | local pre-push output |

## Residual Risk

- Missing-session enforcement may require a nils-cli release before runtime-kit
  can replace skill-level guidance with a hard CLI gate.
- Existing open v2 plan records without session comments may need an explicit
  waiver or migration path if closeout becomes strict by default.
