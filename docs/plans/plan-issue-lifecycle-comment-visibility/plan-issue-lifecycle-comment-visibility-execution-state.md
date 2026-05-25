# Execution State: Plan Issue Lifecycle Comment Visibility

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: tracking issue opened
- Target scope: make `plan-issue` lifecycle comments visibly include detailed
  state, validation, review, session, and closeout evidence; collapse non-final
  Task Ledgers by default; and expand final Task Ledgers by default.
- Current task: implement Sprint 1 in `sympoies/nils-cli`.
- Next task: add lifecycle visible rendering support to `plan-issue record post`
  and `record close`.
- Last updated: 2026-05-25
- Branch: feat/plan-issue-state-visibility
- Source document:
  docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-plan.md
- Plan document:
  docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-plan.md
- Review source:
  docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-review-source.md
- Live tracking issue:
  <https://github.com/graysurf/agent-runtime-kit/issues/115>
  - Source comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535055484>
  - Plan comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535055642>
  - Initial state comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535055774>

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add state execution-state file CLI input and visible gates | n/a | Add `record post --kind state --execution-state-file` and forbid Profile-only lifecycle comments. |
| 1.2 | pending | Add Task Ledger display modes and evidence renderers | n/a | Add `auto`, `collapsed`, `expanded`, and role-specific visible evidence renderers. |
| 1.3 | pending | Validate local nils-cli binary for runtime-kit consumption | n/a | Use local debug binary with scoped PATH before release. |
| 2.1 | pending | Update tracking issue skill contracts | n/a | Lifecycle posts must include detailed visible evidence, not only hidden payload. |
| 2.2 | pending | Update dispatch runtime-smoke lifecycle coverage | n/a | Assert visible evidence for state, validation, review, session, and closeout comments. |
| 2.3 | pending | Render and update nils-cli surface floor | n/a | Update floor only after released nils-cli is available. |
| 3.1 | pending | Release nils-cli z+1 | n/a | Verify Homebrew/released binary exposes new flags. |
| 3.2 | pending | Run full runtime-kit delivery validation | n/a | Use released nils-cli floor for final validation. |
| 3.3 | pending | Deliver PR and close tracking issue | n/a | Final state must show expanded Task Ledger before close. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | Required startup docs present. |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | Project development docs and docs placement policy present. |
| `agent-docs resolve --context task-tools --strict --format checklist` | pass | CLI tooling docs present for provider and release work. |
| `agent-docs resolve --context skill-dev --strict --format checklist` | pass | Skill development docs present. |
| `rumdl check docs/plans/plan-issue-lifecycle-comment-visibility/*.md` | pass | Plan bundle markdown passes. |
| `plan-tooling validate --file docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-plan.md --format json` | pass | Plan bundle validates. |
| `bash scripts/ci/all.sh` | pass | Pre-push gate positions 1-13 passed for initial plan bundle commit. |
| `plan-issue record open --repo graysurf/agent-runtime-kit --profile tracking --bundle docs/plans/plan-issue-lifecycle-comment-visibility` | pass | Opened issue #115 with source, plan, and initial state comments. |

## Closeout Gate

- Close condition: nils-cli release is available and consumed by runtime-kit,
  runtime-kit tracking skills require detailed visible lifecycle evidence,
  runtime-smoke proves visible state/validation/review/session/closeout behavior,
  full validation passes, PR review gates pass, and the tracking issue's final
  state comment has an expanded Task Ledger plus hidden payload marker.
- Reopen triggers:
  - `record post --kind state` can still post a short summary without the full
    execution-state markdown.
  - Hidden payload recognition passes while visible `## Task Ledger` is absent.
  - Validation, review, session, or closeout comments render only heading plus
    `Profile: tracking`.
  - Non-final state comments expand long ledgers by default.
  - Final state comments collapse the ledger by default.
  - runtime-kit final validation depends on an unreleased local nils-cli debug
    binary.
