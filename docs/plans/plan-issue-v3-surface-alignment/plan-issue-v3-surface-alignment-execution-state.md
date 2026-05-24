# plan-issue V3 Surface Alignment Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: planning
- Target scope: runtime-kit skill surface alignment and nils-cli retired helper removal
- Execution window: Sprint 1-3
- Current task: create source and plan bundle
- Next task: validate bundle, open tracking issue, and begin Sprint 1 edits
- Last updated: 2026-05-24
- Branch/commit/PR: feat/plan-issue-v3-surface / pending / pending
- Source document: docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending
- Delivery PR: pending
- Session snapshot: pending
- Validation snapshot: pending
- Review snapshot: pending
- Heuristic inbox entry: core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift/ENTRY.md
- Cross-repo implementation target: /Users/terry/Project/sympoies/nils-cli

## Affected Runtime-Kit Skills

| Skill | Status | Notes |
| --- | --- | --- |
| `dispatch/create-plan-tracking-issue` | pending | Replace initial manual render/comment/provider flow with `record open`. |
| `dispatch/execute-plan-tracking-issue` | pending | Replace lifecycle comment rendering with `record post`; dashboard repair with `repair-dashboard`. |
| `dispatch/deliver-plan-tracking-issue` | pending | Replace validation/closeout helper sequence with v3 post/close flow. |
| `dispatch/plan-tracking-issue-closeout` | pending | Replace `closeout-gate` and closeout render helper with `record close` path. |
| `dispatch/deliver-dispatch-plan` | pending | Replace dashboard/comment/ledger helper assumptions with v3 creation and state flow. |
| `dispatch/dispatch-plan-closeout` | pending | Replace closeout helper sequence with v3 close flow. |
| `dispatch/execute-dispatch-lane` | pending | Replace session/state comment helper with `record post`. |
| `dispatch/review-dispatch-lane-pr` | pending | Replace review/session comment helper with `record post`. |
| `pr/create-dispatch-lane-pr` | pending | Replace session comment helper with `record post`. |
| `pr/deliver-github-pr` | pending | Replace chained closeout helper sequence with v3 close flow. |
| `pr/deliver-gitlab-mr` | pending | Replace chained closeout helper sequence with v3 close flow. |

## Validation Plan

- `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json`
- `plan-tooling validate --file docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `agent-runtime audit-drift`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
- `bash scripts/ci/all.sh`
- nils-cli focused `plan-issue` tests
- nils-cli repository check command from its `DEVELOPMENT.md`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Update lightweight tracking skill family | pending | Four dispatch/tracking skills. |
| 1.2 | pending | Update dispatch and PR delivery skill family | pending | Seven source skills plus references. |
| 2.1 | pending | Update docs, manifests, and rendered outputs | pending | Docs/source, manifests, targets, goldens. |
| 2.2 | pending | Update runtime-smoke and drift checks | pending | Deterministic smoke should use v3 only. |
| 3.1 | pending | Remove helper subcommands and active docs/tests in nils-cli | pending | Cross-repo implementation. |
| 3.2 | pending | Verify downstream alignment and update tracking | pending | Heuristic entry and execution state. |

## Session Log

- 2026-05-24: Created heuristic inbox entry
  `plan-issue-v3-surface-drift` and verified it with
  `heuristic-inbox verify --strict`.
- 2026-05-24: Created discussion source, plan, and execution-state bundle for
  issue-backed delivery.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json` | passed | New inbox entry strict validation passed. | local output |
| `plan-tooling validate --file docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain` | passed | Plan bundle structural validation passed. | local output |
