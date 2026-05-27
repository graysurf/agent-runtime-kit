# plan-issue V3 Surface Alignment Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress
- Target scope: runtime-kit skill surface alignment and nils-cli retired helper removal
- Execution window: Sprint 1-3
- Current task: Draft PR review and live-home drift follow-up
- Next task: decide whether to clean up `heuristic-session-closeout` live drift before merging runtime-kit PR #94
- Last updated: 2026-05-24
- Branch/commit/PR: feat/plan-issue-v3-surface / latest pushed branch head / https://github.com/graysurf/agent-runtime-kit/pull/94
- Source document: docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/93
- Source snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528889172
- Plan snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528889245
- Initial state snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528889341
- Delivery PR: https://github.com/graysurf/agent-runtime-kit/pull/94
- Cross-repo nils-cli PR: https://github.com/sympoies/nils-cli/pull/475 (`a774607`)
- Session snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528993496
- Validation snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4529050597
- Latest state snapshot: https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4529050598
- Review snapshot: pending
- Heuristic inbox entry: core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift/ENTRY.md
- Cross-repo implementation target: /Users/terry/Project/sympoies/nils-cli

## Affected Runtime-Kit Skills

| Skill | Status | Notes |
| --- | --- | --- |
| `dispatch/create-plan-tracking-issue` | done | Uses `plan-issue record open` as the creation/read-back path. |
| `dispatch/execute-plan-tracking-issue` | done | Uses `record post` for lifecycle comments and `record repair-dashboard` for dashboard repair. |
| `dispatch/deliver-plan-tracking-issue` | done | Uses v3 post/repair/close flow and issue-record audit evidence. |
| `dispatch/plan-tracking-issue-closeout` | done | Uses `record close` instead of retired closeout helper checks. |
| `dispatch/deliver-dispatch-plan` | done | Uses shared v3 record commands for creation, lane state, review, and closeout evidence. |
| `dispatch/dispatch-plan-closeout` | done | Uses `record close` and v3 audit/repair lifecycle. |
| `dispatch/execute-dispatch-lane` | done | Uses `record post` for issue-visible lane/session state. |
| `dispatch/review-dispatch-lane-pr` | done | Uses `record post` for review/session lifecycle updates. |
| `pr/create-dispatch-lane-pr` | done | Uses `record post` dry-run probe instead of comment renderer helpers. |
| `pr/deliver-github-pr` | done | Uses plan-issue v3 closeout/audit flow for issue-backed PR delivery. |
| `pr/deliver-gitlab-mr` | done | Uses plan-issue v3 closeout/audit flow for issue-backed MR delivery. |

## Validation Plan

- `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json`
- `plan-tooling validate --file docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain`
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
| 1.1 | done | Update lightweight tracking skill family | source edits + rendered goldens | Four dispatch/tracking skills now use v3 commands. |
| 1.2 | done | Update dispatch and PR delivery skill family | source edits + rendered goldens | Seven source skills plus references now use v3 commands. |
| 2.1 | done | Update docs, manifests, and rendered outputs | render update + manifest/docs diff | Docs/source, manifests, build outputs, and goldens aligned. |
| 2.2 | done | Update runtime-smoke and drift checks | deterministic dispatch/pr smoke | Smoke fixtures now exercise v3 only. |
| 3.1 | done | Remove helper subcommands and active docs/tests in nils-cli | nils-cli local-fast passed | Cross-repo implementation verified in sibling worktree. |
| 3.2 | done | Verify downstream alignment and update tracking | issue #93 session/validation/state comments + final audit | Dashboard repaired; PR review remains outside implementation task. |

## Session Log

- 2026-05-24: Created heuristic inbox entry
  `plan-issue-v3-surface-drift` and verified it with
  `heuristic-inbox verify --strict`.
- 2026-05-24: Created discussion source, plan, and execution-state bundle for
  issue-backed delivery.
- 2026-05-24: Pushed branch `feat/plan-issue-v3-surface`, opened tracking
  issue #93 with `plan-issue record open`, and read-back audited source, plan,
  and initial state comments.
- 2026-05-24: Removed retired `plan-issue record` helper usage from 11
  runtime-kit source skills, refreshed Codex/Claude rendered goldens, and
  updated runtime-smoke dispatch/pr fixtures to use v3 commands only.
- 2026-05-24: Removed retired helper subcommands from nils-cli in a sibling
  worktree and replaced active parser coverage with explicit rejection tests.
- 2026-05-24: Re-ran nils-cli local-fast after active docs cleanup; docs-only,
  clippy, nextest, and doc tests passed. Runtime-kit source/golden/smoke gates
  passed; full `scripts/ci/all.sh` is blocked by unrelated live-home drift for
  `heuristic-session-closeout`.
- 2026-05-24: Opened draft PRs
  [agent-runtime-kit #94](https://github.com/graysurf/agent-runtime-kit/pull/94)
  and [nils-cli #475](https://github.com/sympoies/nils-cli/pull/475), then
  posted session, validation, and state lifecycle comments to issue #93 and
  repaired the dashboard.
- 2026-05-24: Added nils-cli v3 record-path coverage for `record post
  --summary-file`, `record repair-dashboard --out`, and body-file `record
  close` gating; pushed `a774607` and confirmed PR #475 `test`, `test_macos`,
  `coverage`, and CodeQL checks are green.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json` | passed | New inbox entry strict validation passed. | local output |
| `plan-tooling validate --file docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain` | passed | Plan bundle structural validation passed. | local output |
| `plan-issue record open --dry-run --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/2026-05-24-plan-issue-v3-surface-alignment` | passed | Preview produced hidden payload carriers and no visible `plan-issue-record` code fence. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-213350-plan-issue-v3-tracker/record-open-dry-run.json` |
| `plan-issue record open --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/2026-05-24-plan-issue-v3-surface-alignment` | passed | Created tracking issue #93 with source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-213350-plan-issue-v3-tracker/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file .../issue-93-body.md --comments-json .../issue-93.json --format json` | passed | GitHub read-back audit returned `missing_required:[]`, `unsupported_markers:[]`, `recognized_count:3`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-213350-plan-issue-v3-tracker/issue-93-audit.json` |
| `agent-runtime render --product codex --update-golden` | passed | Refreshed Codex rendered skill outputs and goldens after source edits. | local output |
| `agent-runtime render --product claude --update-golden` | passed | Refreshed Claude rendered skill outputs and goldens after source edits. | local output |
| `bash -n tests/runtime-smoke/cases/dispatch/run.sh` | passed | Dispatch smoke fixture syntax check passed. | local output |
| `bash -n tests/runtime-smoke/cases/pr/run.sh` | passed | PR smoke fixture syntax check passed. | local output |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch --format text` | passed | Dispatch deterministic runtime-smoke passed 8/8. | local output |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr --format text` | passed | PR deterministic runtime-smoke passed 7/7. | local output |
| `cargo fmt --all` | passed | nils-cli formatting passed in sibling worktree. | `/Users/terry/.codex/worktrees/nils-cli-plan-issue-v3` |
| `cargo test -p nils-plan-issue-cli` | passed | nils-cli plan-issue focused tests passed. | `/Users/terry/.codex/worktrees/nils-cli-plan-issue-v3` |
| `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- record --help` | passed | Help lists only `open`, `post`, `repair-dashboard`, `close`, and `audit`. | `/Users/terry/.codex/worktrees/nils-cli-plan-issue-v3` |
| `rg -n "render-dashboard\|render-comment\|closeout-gate\|build-dispatch-ledger\|issue-backed-plan-record-contract-v1" ...` | passed | Runtime-kit active skills/goldens/build/docs/smoke have no retired helper references. | local output |
| `rg -n "render-dashboard\|render-comment\|closeout-gate\|build-dispatch-ledger\|issue-backed-plan-record-contract-v1" ...` | passed | nils-cli active docs/code have no retired helper references; only parser rejection test keeps the retired names. | `/Users/terry/.codex/worktrees/nils-cli-plan-issue-v3` |
| `cargo test -p nils-plan-issue-cli --test integration live_record_ops` | passed | Added v3 live-record operation coverage passed 16/16. | `/Users/terry/.codex/worktrees/nils-cli-plan-issue-v3` |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | passed | Docs-only, fmt check, clippy, nextest 194/194, and doc tests passed after adding v3 record-path tests. | `/Users/terry/.codex/worktrees/nils-cli-plan-issue-v3` |
| `cargo llvm-cov nextest --profile ci --workspace --lcov --output-path ... --fail-under-lines 85` | blocked locally | Local coverage run hit unrelated local-sensitive forge-cli `pr_wait_checks_succeeds_when_terminal_on_third_poll`; GitHub coverage check is authoritative for PR #475 and passed after `a774607`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-222941-nils-cli-pr-475-coverage/local-coverage/` |
| GitHub PR checks for `sympoies/nils-cli#475` at `a774607` | passed | `test`, `test_macos`, `coverage`, CodeQL, and JUnit reports completed successfully; `coverage_badge` skipped as expected. | https://github.com/sympoies/nils-cli/pull/475 |
| `agent-runtime doctor --class skill-surface --product codex --format json --source-root ...` | passed | Codex skill-surface shape diagnostic passed 75/75 with no warnings or blockers. | local output |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | passed | Codex and Claude sandbox install rehearsals passed. | local output |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | passed | Full deterministic runtime smoke passed 54/54. | local output |
| `bash tests/projects/project-local-smoke/run.sh` | passed | Project-local smoke passed for bench/bootstrap/demo/deploy/pre-pr/release. | local output |
| `bash tests/hooks/run.sh` | passed | Shared hook contract tests passed 9/9. | local output |
| `bash scripts/ci/all.sh` | blocked | Source/golden gates reached position 6; `agent-runtime audit-drift` failed on unrelated live runtime extra surface `heuristic-session-closeout`. | live-home drift |
| `plan-issue record post --kind session --issue 93 --repo graysurf/agent-runtime-kit` | passed | Posted session snapshot with runtime-kit #94 and nils-cli #475 links. | https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528993496 |
| `plan-issue record post --kind validation --issue 93 --repo graysurf/agent-runtime-kit` | passed | Posted validation snapshot with partial status and live-home drift blocker. | https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528993905 |
| `plan-issue record post --kind state --issue 93 --repo graysurf/agent-runtime-kit` | passed | Posted latest state snapshot with PR links and blocker. | https://github.com/graysurf/agent-runtime-kit/issues/93#issuecomment-4528999060 |
| `plan-issue record repair-dashboard --issue 93 --repo graysurf/agent-runtime-kit --format json` | passed | Repaired issue #93 dashboard with latest session, validation, state, PR links, and blocker. | local output |
| `plan-issue record audit --profile tracking --body-file ... --comments-json ... --format json` | passed | Final read-back audit returned `missing_required:[]`, `unsupported_markers:[]`, `recognized_count:7`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-221706-plan-issue-v3-prs/issue-93-final-audit.json` |
