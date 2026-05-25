# Project Runtime Setup Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress
- Target scope: managed dispatcher surface cleanup plus `setup-project`
  workflow and adopted-repo `pre-pr` diagnostics.
- Execution window: Sprint 1-3
- Current task: Task 1.1 - remove managed `bench` and `demo` skill sources.
- Next task: execute Sprint 1 managed dispatcher surface cleanup.
- Last updated: 2026-05-26
- Branch/commit/PR: `f2f4040` pushed to `origin/main`; PR pending
- Source document: docs/plans/project-runtime-setup/project-runtime-setup-plan.md
- Discussion source:
  docs/plans/project-runtime-setup/project-runtime-setup-discussion-source.md
- Plan document: docs/plans/project-runtime-setup/project-runtime-setup-plan.md
- Execution state: docs/plans/project-runtime-setup/project-runtime-setup-execution-state.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/117>
- Source snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536042374>
- Plan snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536042480>
- Initial state snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536042572>

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Remove managed bench and demo skill sources | n/a | Remove active managed sources and manifest/plugin entries only. |
| 1.2 | pending | Refresh render output, goldens, and expected skill lists | n/a | Expected lists should exclude removed skills and include intentional count changes. |
| 1.3 | pending | Update dispatcher docs and smoke fixtures | n/a | Retained managed dispatcher set becomes bootstrap/deploy/pre-pr/release. |
| 2.1 | pending | Define setup-project contract and adoption model | n/a | Keep setup-project separate from bootstrap and host install. |
| 2.2 | pending | Add setup-project helper and fixtures | n/a | Dry-run-first repo adoption workflow with confirmed pre-pr gate creation. |
| 2.3 | pending | Render setup-project across products | n/a | Add Codex/Claude rendered surfaces and expected skill entries. |
| 3.1 | pending | Add or consume adopted-repo doctor diagnostics | n/a | Coupled nils-cli release boundary for doctor --check-project behavior. |
| 3.2 | pending | Update pre-pr missing-script guidance | n/a | Point missing pre-pr to setup-project without adding fallback validation. |
| 3.3 | pending | Final validation and tracker closeout prep | n/a | Record focused and full validation before closeout. |

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `plan-tooling validate` on this plan with `--format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --target support-matrix`
- `agent-runtime audit-drift`
- `bash scripts/ci/skill-governance-audit.sh`
- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash scripts/ci/all.sh`

## Session Log

- 2026-05-26: Created discussion source from user-approved direction: remove
  `bench`/`demo`, make `pre-pr` required for adopted repos, and add a
  setup-oriented project adoption workflow.
- 2026-05-26: Created initial plan and execution-state bundle for issue-backed
  tracking.
- 2026-05-26: Pushed commit `f2f4040`, opened tracking issue #117 with
  `plan-issue record open`, and read-back audited source, plan, and initial
  state comments.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Project development docs and docs placement policy present. | n/a |
| `plan-tooling validate --file docs/plans/project-runtime-setup/project-runtime-setup-plan.md --format json` | passed | Plan bundle validates with no errors. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/plan-tooling-validate.json` |
| `rumdl check docs/plans/project-runtime-setup/*.md` | passed | Plan bundle markdown passes. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/rumdl-check.txt` |
| `awk '/[[:blank:]]$/ ...' docs/plans/project-runtime-setup/*.md` | passed | No trailing whitespace found in the plan bundle. | n/a |
| `bash scripts/ci/all.sh` | passed | Pre-push hook ran positions 1-13 successfully while pushing `f2f4040`. | local pre-push output |
| `forge-cli label ensure --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --format json` | passed | Shared taxonomy labels were already present; no actions needed. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/label-ensure.json` |
| `plan-issue record open --dry-run --profile tracking --bundle docs/plans/project-runtime-setup --format json` | passed | Preview generated source, plan, and state snapshots with selected labels. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/record-open-dry-run.json` |
| `plan-issue record open --profile tracking --bundle docs/plans/project-runtime-setup --format json` | passed | Opened tracking issue #117 with source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file "$ISSUE_BODY" --comments-json "$ISSUE_JSON" --format json` | passed | Read-back audit recognized source, plan, and state comments with no missing required markers. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/issue-117-audit.json` |
| `rg -n "## Execution State\|## Task Ledger\|<details>\|plan-issue-record-payload" issue-117-state-comment.md` | passed | Initial state comment contains visible execution state, visible task ledger, folded details, and hidden payload carrier. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/issue-117-state-comment.md` |

## Residual Risk

- `setup-project` may need a released nils-cli helper if dry-run/apply behavior
  becomes a stable machine-readable contract rather than a skill-local shell
  helper.
- Adopted-repo diagnostics depend on released nils-cli behavior for
  `agent-runtime doctor --check-project`; runtime-kit should not claim that
  contract is available until the corresponding release has landed.
