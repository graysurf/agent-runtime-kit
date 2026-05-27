# Plan Issue Lifecycle Ordering Regression Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: pre-merge lifecycle evidence ready; runtime-kit PR checks and review
  passed
- Target scope: restore issue-visible plan lifecycle ordering and required
  session evidence for v2 plan issue records.
- Execution window: Sprint 1-3
- Current task: Task 3.3 - perform live GitHub lifecycle rehearsal and closeout.
- Next task: merge runtime-kit PR #121, post final lifecycle evidence, close
  issue #120, and sync runtime skills.
- Last updated: 2026-05-26
- Branch/commit/PR: runtime-kit branch `fix/plan-issue-session-lifecycle`, PR
  <https://github.com/graysurf/agent-runtime-kit/pull/121>; nils-cli PR
  <https://github.com/sympoies/nils-cli/pull/537> merged as `2f5d0073`.
- Source document:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Discussion source:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-discussion-source.md
- Plan document:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Execution state:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-execution-state.md
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
| 1.1 | done | Add missing-session closeout regression fixture | nils-cli PR #537; runtime-smoke local-binary dispatch probe | Missing `role=session` now blocks with `session-missing`; the runtime-kit smoke case distinguishes body `## Session Log` from real session evidence. |
| 1.2 | done | Add #28-like complete lifecycle success fixture | existing dispatch/tracking closeout smoke plus updated session-bearing fixtures | Passing tracking and dispatch closeout fixtures include source, plan, complete state, session, validation, review, approval, and merged PR evidence. |
| 1.3 | done | Define nils-cli readiness and closeout enforcement boundary | `docs/source/extraction-backlog.md`; nils-cli PR #537 | Runtime-kit keeps skill guidance explicit now and does not raise `plan-issue` semver floors until the session gate is released. |
| 2.1 | done | Make session posting explicit in plan delivery skills | rendered Codex/Claude skills and goldens | `deliver-plan-tracking-issue` now includes canonical `record post --kind session`. |
| 2.2 | done | Add pre-merge lifecycle readiness to PR and MR delivery | rendered PR/MR skills and PR runtime-smoke source assertions | GitHub and GitLab delivery skills require linked issue lifecycle readiness before merge. |
| 2.3 | done | Align closeout skills with required session evidence | closeout skill source and rendered goldens | Tracking and dispatch closeout guidance rejects missing session evidence or `Latest session: pending`. |
| 3.1 | deferred | Consume released nils-cli readiness support when required | nils-cli PR #537 merged; no manifest floor bump | Release consumption stays deferred until the nils-cli session gate ships in a versioned release; local debug binary validates the intended behavior. |
| 3.2 | done | Run full render, smoke, and governance gates | focused local-binary dispatch/pr smoke and full CI passed | Full runtime-kit validation passed with local nils-cli debug binary on PATH. |
| 3.3 | in-progress | Perform live GitHub lifecycle rehearsal and closeout | issue #120 has a real `role=session` start comment; runtime-kit PR #121 checks and review passed | Use this tracker to prove session is present before closeout. |

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `agent-docs resolve --context task-tools --strict --format checklist`
- `plan-tooling validate --file <plan> --format text --explain`
- `rumdl check docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/*.md`
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
- 2026-05-26: Posted a real v2 `role=session` start comment to issue #120
  before implementation, then patched nils-cli `record close` to block missing
  session evidence with `session-missing`.
- 2026-05-26: Updated runtime-kit plan/dispatch/PR/MR delivery skills so
  session evidence is explicit and linked issue lifecycle readiness is checked
  before merge.
- 2026-05-26: Ran full runtime-kit CI with the local nils-cli debug binary on
  `PATH`; the missing-session closeout smoke passed by blocking with
  `session-missing`.
- 2026-05-26: Opened runtime-kit PR #121, posted the pre-merge review outcome,
  fixed a clean-checkout plan location issue, and confirmed the remote
  `scripts/ci/all.sh` job passed.
- 2026-05-26: Merged nils-cli PR #537 after required `coverage`, `test`, and
  `test_macos` checks passed; the hard session gate is now on nils-cli `main`
  but not yet consumed through a released runtime-kit floor.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Project development docs present. | n/a |
| `agent-docs resolve --context task-tools --strict --format checklist` | passed | Task tooling docs present for provider and external checks. | n/a |
| `plan-tooling validate --file docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md --format json` | passed | Plan bundle validates with no errors. | local output |
| `rumdl check docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/*.md` | passed | Markdown passed for source, plan, and execution-state files. | local output |
| `forge-cli label ensure --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --format json` | passed | Label catalog already matched provider state. | local output |
| `plan-issue record open --dry-run --profile tracking --bundle docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression --format json` | passed | Preview generated dashboard plus source, plan, and state lifecycle comments. | local output |
| `plan-issue record open --profile tracking --bundle docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression --format json` | passed | Opened issue #120 and posted source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-023453-plan-issue-lifecycle-ordering-regression/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file issue-120-body.md --comments-json issue-120.json --format json` | passed | Read-back audit recognized source, plan, and state lifecycle comments with no missing required markers. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-023453-plan-issue-lifecycle-ordering-regression/issue-120-audit.json` |
| `rg` state-comment shape check | passed | Initial state comment contains visible execution state, folded task ledger, and hidden payload carrier. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-023453-plan-issue-lifecycle-ordering-regression/issue-120-state-comment.md` |
| `bash scripts/ci/all.sh` | passed | Pre-push hook ran positions 1-13 successfully before pushing `bedfffc`. | local pre-push output |
| `cargo fmt --all --check` in `$NILS_CLI` | passed | nils-cli formatting passed after adding the session closeout gate. | local output |
| `cargo test -p nils-plan-issue-cli lifecycle_record -- --nocapture` | passed | Strict closeout gate unit coverage passed with session evidence required. | local output |
| `cargo test -p nils-plan-issue-cli live_record_ops::record_close -- --nocapture` | passed | `record close` integration coverage passed, including the new `session-missing` regression fixture. | local output |
| `cargo build -p nils-plan-issue-cli --bins` | passed | Local `plan-issue` debug binary built for runtime-kit validation. | local output |
| `PATH=$NILS_CLI/target/debug:$PATH bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch --format json` | passed | Local debug `plan-issue` blocked the missing-session fixture with `session-missing`; dispatch delivery session-post probes passed. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/runtime-smoke-dispatch-local.json` |
| `PATH=$NILS_CLI/target/debug:$PATH bash tests/runtime-smoke/run.sh --mode deterministic --domain pr --format json` | passed | GitHub and GitLab PR/MR delivery smoke passed and asserted pre-merge lifecycle readiness guidance. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/runtime-smoke-pr-local.json` |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch --format json` | passed | Released `plan-issue` path remains CI-safe by marking the unreleased session gate as `skip-host-capability`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/runtime-smoke-dispatch-release.json` |
| `PATH=$NILS_CLI/target/debug:$PATH agent-run exec --cwd $PWD -- bash scripts/ci/all.sh` | passed | Full runtime-kit CI positions 1-13 passed with the local nils-cli debug binary; deterministic smoke reported `dispatch.plan-issue-session-closeout-gate` as pass. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/ci-all-local-debug-2.log` |
| `review-specialists scope --repo $PWD --base main --testing --maintainability --red-team --format json` | passed | Runtime-kit PR #121 review gate selected testing, maintainability, and red-team; no blocking findings. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/review-specialists-pr121-red-team.json` |
| `review-evidence verify --out <review-evidence-pr121> --format json` | passed | Review evidence for PR #121 is complete with the unreleased nils-cli floor as an accepted residual risk. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/review-evidence-verify.json` |
| `forge-cli pr checks 121 --repo graysurf/agent-runtime-kit --format json` | passed | Remote GitHub Actions `scripts/ci/all.sh` passed after removing the untracked `build/` plan location. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/pr121-checks-latest.json` |
| `forge-cli pr checks 537 --repo sympoies/nils-cli --format json` | passed | nils-cli PR #537 required `coverage`, `test`, and `test_macos` checks passed after syncing with `main`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/nils-cli-pr/checks-537-poll-6.json` |
| `forge-cli pr merge 537 --repo sympoies/nils-cli --method squash --format json` | passed | nils-cli session closeout gate merged to `main` as `2f5d0073`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-024144-plan-issue-lifecycle-ordering-delivery/nils-cli-pr/pr537-merge-final.json` |

## Residual Risk

- Runtime-kit does not yet raise the consumed `plan-issue` floor because the
  hard `session-missing` gate is merged to nils-cli `main` but not yet available
  in a released nils-cli version.
- Existing open v2 plan records without session comments will need a session
  backfill before strict closeout once the nils-cli gate is released.
