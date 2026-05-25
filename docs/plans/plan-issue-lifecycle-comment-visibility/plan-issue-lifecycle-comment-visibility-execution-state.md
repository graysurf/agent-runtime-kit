# Execution State: Plan Issue Lifecycle Comment Visibility

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: complete
- Target scope: make `plan-issue` lifecycle comments visibly include detailed
  state, validation, review, session, and closeout evidence; collapse non-final
  Task Ledgers by default; and expand final Task Ledgers by default.
- Current task: issue #115 final-format lifecycle refresh and closeout are
  complete; local `plan-issue` binary validation and runtime-kit CI passed.
- Next task: downstream nils-cli release / Homebrew floor adoption after
  sympoies/nils-cli#526 leaves draft and merges.
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
  - Final state comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535482102>
  - Final session comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535456451>
  - Final validation comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535456597>
  - Final review comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535456758>
  - Closeout comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/115#issuecomment-4535477056>

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add state execution-state file CLI input and visible gates | `sympoies/nils-cli` branch `feat/plan-issue-lifecycle-comments`; `cargo test -p nils-plan-issue-cli` pass | Added `record post --kind state --execution-state-file` and usage errors for non-state or missing Task Ledger. |
| 1.2 | done | Add Task Ledger display modes and evidence renderers | `sympoies/nils-cli` commits `b1de607` and `047855d`; local-fast pass | Added `auto`, `collapsed`, `expanded`, role-specific visible evidence renderers, execution-state normalization, and explicit no-linked-PR closeout evidence. |
| 1.3 | done | Validate local nils-cli binary for runtime-kit consumption | local `plan-issue` help/version probe; local install helper pass | Installed local `plan-issue` / `plan-issue-local`; runtime-kit smoke used the local install ahead of Homebrew 0.22.2. |
| 2.1 | done | Update tracking issue skill contracts | `core/skills/dispatch/{create,execute,deliver,plan-tracking-issue-closeout}/SKILL.md.tera` | Lifecycle posts now require detailed visible evidence, not only hidden payload. |
| 2.2 | done | Update dispatch runtime-smoke lifecycle coverage | `tests/runtime-smoke/cases/dispatch/run.sh`; dispatch smoke pass | Asserts visible state Task Ledger, validation, review, and closeout evidence. |
| 2.3 | deferred | Render and update nils-cli surface floor | `manifests/skills.yaml`; rendered Codex/Claude golden files | Skill-level requirements now pin the affected `plan-issue` workflows to `>=0.22.3`; the global surface snapshot remains a downstream release-floor task because the released binary is still `0.22.2`. |
| 3.1 | deferred | Release nils-cli z+1 | `sympoies/nils-cli#526` is open draft | Release must run after the nils-cli PR merges to `main`; this implementation was accepted through local release binaries as planned. |
| 3.2 | done | Run full runtime-kit delivery validation | `bash scripts/ci/all.sh` with local install first on `PATH` | Pre-push hook positions 1-13 passed using the locally installed fixed `plan-issue`. |
| 3.3 | done | Deliver issue-visible review and close tracking issue | issue #115 closeout comment | Closed #115 after final state, session, validation, review, and closeout comments were refreshed in the completed visible format. |

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
| `cargo test -p nils-plan-issue-cli --test integration record_post_state_execution_state_file -- --nocapture` | pass | Focused regression coverage confirms a single visible state heading, one visible `Profile`, preserved legacy fields, and correct Task Ledger display. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` with local install first on `PATH` | pass | 8/8 dispatch runtime-smoke probes passed with visible lifecycle evidence assertions, including duplicate heading/profile guards. |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | pass | Package local-fast passed after the renderer normalization fix. |
| `git push origin feat/plan-issue-lifecycle-comments` | pass | Pushed nils-cli commit `b1de607` to PR #526. |
| `git push origin feat/plan-issue-state-visibility` with local install first on `PATH` | pass | Pre-push `scripts/ci/all.sh` positions 1-13 passed and pushed runtime-kit commit `d0e04db`. |
| `plan-issue record audit --profile tracking` for issue #115 | pass | Read-back audit recognized source, plan, state, session, validation, and review records with no missing required markers before final-format closeout refresh. |
| `cargo test -p nils-plan-issue-cli render_record_post_comment_synthesizes_validation_review_and_closeout -- --nocapture` | pass | Focused closeout renderer regression passed after adding explicit `Linked PRs: none` evidence. |
| `cargo test -p nils-plan-issue-cli` | pass | nils-cli package tests passed after the no-linked-PR closeout evidence fix. |
| `./scripts/install-local-release-binaries.sh --bin plan-issue --bin plan-issue-local` | pass | Reinstalled local `plan-issue` / `plan-issue-local` with the closeout renderer fix. |
| `git push origin feat/plan-issue-lifecycle-comments` | pass | Pushed nils-cli closeout evidence commit `047855d` to PR #526. |
| `plan-issue record close --issue 115 --profile tracking` | pass | Posted closeout comment and closed issue #115. |
| `plan-issue record post --kind state --task-ledger-display expanded` for issue #115 | pass | Posted corrected final state after closeout so the dashboard's current/next text reflects the closed issue state. |
| `plan-issue record repair-dashboard --issue 115` | pass | Repaired the issue #115 dashboard to point at the corrected final state and closeout comment. |
| `plan-issue record audit --profile tracking` for issue #115 after closeout | pass | Read-back audit reported `missing_required=[]`, `recognized_count=7`, latest state/comment URLs correct, and issue state `CLOSED`. |

## Closeout Gate

- Close condition: runtime-kit tracking skills require detailed visible
  lifecycle evidence, runtime-smoke proves visible
  state/validation/review/session/closeout behavior, full validation passes,
  and the tracking issue's final state comment has an expanded Task Ledger plus
  hidden payload marker. Completed for issue #115; released-floor adoption
  remains downstream after nils-cli PR #526 merges.
- Reopen triggers:
  - `record post --kind state` can still post a short summary without the full
    execution-state markdown.
  - Hidden payload recognition passes while visible `## Task Ledger` is absent.
  - Validation, review, session, or closeout comments render only heading plus
    `Profile: tracking`.
  - Non-final state comments expand long ledgers by default.
  - Final state comments collapse the ledger by default.
  - Formal release close is attempted before the released nils-cli floor exposes
    the same `plan-issue` surface validated through the local release binary.
