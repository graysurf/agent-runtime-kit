# plan-issue V3 Surface Alignment Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress
- Target scope: runtime-kit skill surface alignment and nils-cli retired helper removal
- Execution window: Sprint 1-3
- Current task: begin Sprint 1 runtime-kit skill surface edits
- Next task: update lightweight tracking skill family
- Last updated: 2026-05-24
- Branch/commit/PR: feat/plan-issue-v3-surface / 2c6a97d / pending
- Source document: docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/93
- Source snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528889172
- Plan snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528889245
- Initial state snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528889341
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
- 2026-05-24: Pushed branch `feat/plan-issue-v3-surface`, opened tracking
  issue #93 with `plan-issue record open`, and read-back audited source, plan,
  and initial state comments.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json` | passed | New inbox entry strict validation passed. | local output |
| `plan-tooling validate --file docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain` | passed | Plan bundle structural validation passed. | local output |
| `plan-issue record open --dry-run --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/plan-issue-v3-surface-alignment` | passed | Preview produced hidden payload carriers and no visible `plan-issue-record` code fence. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-213350-plan-issue-v3-tracker/record-open-dry-run.json` |
| `plan-issue record open --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/plan-issue-v3-surface-alignment` | passed | Created tracking issue #93 with source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-213350-plan-issue-v3-tracker/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file .../issue-93-body.md --comments-json .../issue-93.json --format json` | passed | GitHub read-back audit returned `missing_required:[]`, `unsupported_markers:[]`, `recognized_count:3`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-213350-plan-issue-v3-tracker/issue-93-audit.json` |
