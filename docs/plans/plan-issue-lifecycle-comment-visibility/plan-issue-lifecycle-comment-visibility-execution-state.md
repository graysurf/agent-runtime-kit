# Execution State: Plan Issue Lifecycle Comment Visibility

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: in progress
- Target scope: make `plan-issue` lifecycle comments visibly include detailed
  state, validation, review, session, and closeout evidence; collapse non-final
  Task Ledgers by default; and expand final Task Ledgers by default.
- Current task: nils-cli PR #526 includes the renderer normalization fix and
  has been pushed at commit `b1de607`; issue #115 lifecycle comments have
  been refreshed with the approved visible format.
- Next task: release nils-cli z+1, then validate runtime-kit against the
  released floor.
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
| 1.1 | done | Add state execution-state file CLI input and visible gates | `sympoies/nils-cli` branch `feat/plan-issue-lifecycle-comments`; `cargo test -p nils-plan-issue-cli` pass | Added `record post --kind state --execution-state-file` and usage errors for non-state or missing Task Ledger. |
| 1.2 | done | Add Task Ledger display modes and evidence renderers | `sympoies/nils-cli` commit `b1de607`; local-fast pass | Added `auto`, `collapsed`, `expanded`, role-specific visible evidence renderers, and execution-state normalization so v2 comments keep the legacy visible fields without duplicate headings/profile lines. |
| 1.3 | done | Validate local nils-cli binary for runtime-kit consumption | local `plan-issue` help/version probe; local install helper pass | Installed local `plan-issue` / `plan-issue-local`; runtime-kit smoke used the local install ahead of Homebrew 0.22.2. |
| 2.1 | done | Update tracking issue skill contracts | `core/skills/dispatch/{create,execute,deliver,plan-tracking-issue-closeout}/SKILL.md.tera` | Lifecycle posts now require detailed visible evidence, not only hidden payload. |
| 2.2 | done | Update dispatch runtime-smoke lifecycle coverage | `tests/runtime-smoke/cases/dispatch/run.sh`; dispatch smoke pass | Asserts visible state Task Ledger, validation, review, and closeout evidence. |
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
| `cargo test -p nils-plan-issue-cli` | pass | nils-cli package tests passed, including lifecycle visible render coverage. |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | pass | nils-cli local-fast package gate passed for `nils-plan-issue-cli`. |
| `./scripts/install-local-release-binaries.sh --bin plan-issue --bin plan-issue-local` | pass | Installed local release binaries into `/Users/terry/.local/nils-cli`. |
| `plan-issue record post --help` with local install first on `PATH` | pass | Local binary exposes `--execution-state-file` and `--task-ledger-display`. |
| `cargo test -p nils-plan-issue-cli --test integration record_post_state_execution_state_file -- --nocapture` | pass | Focused regression coverage confirms one visible `## Execution State`, one visible `Profile`, preserved legacy fields, and correct Task Ledger display. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` with local install first on `PATH` | pass | 8/8 dispatch runtime-smoke probes passed with visible lifecycle evidence assertions, including duplicate heading/profile guards. |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | pass | Package local-fast passed after the renderer normalization fix. |
| `git push origin feat/plan-issue-lifecycle-comments` | pass | Pushed nils-cli commit `b1de607` to PR #526. |

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
