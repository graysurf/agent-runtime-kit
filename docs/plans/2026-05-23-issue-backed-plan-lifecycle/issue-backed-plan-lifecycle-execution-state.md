# Issue-Backed Plan Lifecycle Execution State

## Current State

- Source document: `docs/plans/2026-05-23-issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md`
- Status: complete
- Current task: Task 4.3
- Next task: PR review, nils-cli release handoff, and user acceptance
- Branch: `feat/issue-backed-plan-lifecycle`
- Runtime-kit PR: https://github.com/graysurf/agent-runtime-kit/pull/51
- Nils-cli branch: `feat/issue-backed-plan-lifecycle-cli`
- Nils-cli PR: https://github.com/sympoies/nils-cli/pull/445
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/50
- Source snapshot: https://github.com/graysurf/agent-runtime-kit/issues/50#issuecomment-4522439331
- Plan snapshot: https://github.com/graysurf/agent-runtime-kit/issues/50#issuecomment-4522439477
- Latest execution state: https://github.com/graysurf/agent-runtime-kit/issues/50#issuecomment-4522550747
- Latest execution session: https://github.com/graysurf/agent-runtime-kit/issues/50#issuecomment-4522551275
- Latest validation evidence: https://github.com/graysurf/agent-runtime-kit/issues/50#issuecomment-4522552006

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | done | Define lifecycle contract fixtures | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | Contract docs and integration fixtures added. |
| Task 1.2 | done | Preserve plan-tooling boundary | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | `plan-tooling` remains plan parsing, validation, batching, and split modeling only. |
| Task 1.3 | done | Choose CLI surface and compatibility policy | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | Added `plan-issue record` with `compat` and `shared` marker families. |
| Task 2.1 | done | Implement shared dashboard and comment renderer | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | Added deterministic `record render-dashboard` and `record render-comment`. |
| Task 2.2 | done | Implement marker audit and dashboard repair | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | Added `record audit` and `record closeout-gate`. |
| Task 2.3 | done | Implement dispatch ledger and gate support | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | Added `record build-dispatch-ledger`. |
| Task 2.4 | done | Build and expose debug binaries for integration | `/Users/terry/Project/sympoies/nils-cli-issue-backed-plan-lifecycle/target/debug/plan-issue` | Debug binary validates and exposes `plan-issue record`. |
| Task 3.1 | done | Update tracking-plan skill bodies | agent-runtime-kit branch `feat/issue-backed-plan-lifecycle` | `create-plan-tracking-issue`, `execute-plan-tracking-issue`, `deliver-plan-tracking-issue`, and `plan-tracking-issue-closeout` now use `plan-issue record` dashboard/comment/audit/closeout primitives with issue #43-compatible markers. |
| Task 3.2 | done | Update dispatch-plan skill bodies | agent-runtime-kit branch `feat/issue-backed-plan-lifecycle` | `deliver-dispatch-plan`, `execute-dispatch-lane`, `review-dispatch-lane-pr`, and `dispatch-plan-closeout` now use the same dashboard/comment model with dispatch profile markers and provider mutation through `forge-cli`. |
| Task 3.3 | done | Update smoke coverage and manifests | agent-runtime-kit branch `feat/issue-backed-plan-lifecycle` | Manifests, product link maps, rendered outputs, golden snapshots, sandbox skill lists, and PR/dispatch smoke probes now cover the shared record lifecycle. |
| Task 4.1 | done | Run cross-repo validation | nils-cli local-fast; agent-runtime-kit `scripts/ci/all.sh` | Cross-repo validation passed with the nils-cli debug binary first on `PATH`. |
| Task 4.2 | done | Run specialist review and fix findings | `/Users/terry/.config/agent-kit/out/projects/graysurf__agent-runtime-kit/20260523-050234-issue-backed-plan-lifecycle-review/specialist-review-report-final.md` | code-review-specialists found and fixed one runtime-kit CLI contract issue and one nils-cli closeout evidence issue. |
| Task 4.3 | done | Decide release/floor and close plan | runtime-kit PR #51; nils-cli PR #445 | Runtime-kit keeps the `plan-issue >=0.17.4` floor; integration used the nils-cli debug binary until release. Tracking issue closeout remains gated on PR review/user acceptance rather than automatic merge. |

## Validation Ledger

| Command | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist` | pass | current session | agent-runtime-kit preflight. |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist` | pass | current session | agent-runtime-kit preflight. |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context skill-dev --strict --format checklist` | pass | current session | skill lifecycle preflight. |
| `plan-tooling validate --file docs/plans/2026-05-23-issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --format text --explain` | pass | current session | Plan validates after replacing placeholder review commands. |
| `for n in 1 2 3 4; do plan-tooling batches --file docs/plans/2026-05-23-issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --sprint "$n" --format json; done` | pass | current session | Sprints 1-4 batch analysis passed. |
| `plan-tooling split-prs ...` for Sprints 1-4 | pass | current session | Sprints 1-3 use auto group; Sprint 4 uses per-sprint deterministic. |
| `/Users/terry/.config/agent-kit/skills/workflows/plan/plan-tracking-issue/scripts/plan-tracking-issue.sh --plan docs/plans/2026-05-23-issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --provider github --repo graysurf/agent-runtime-kit --dry-run --label plan` | pass | current session | Dry-run rendered lightweight issue body at `/tmp/issue-backed-plan-lifecycle-issue-body.md`. |
| `/Users/terry/.config/agent-kit/skills/workflows/plan/plan-tracking-issue/scripts/plan-tracking-issue.sh --plan docs/plans/2026-05-23-issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --provider github --repo graysurf/agent-runtime-kit --label plan` | pass | https://github.com/graysurf/agent-runtime-kit/issues/50 | Created the live tracking issue. |
| `gh issue comment 50 ...` source, plan, and state comments | pass | issue #50 comments | Posted source snapshot, plan snapshot, and initial execution state with compatibility markers matching issue #43. |
| `cargo test -p nils-plan-issue-cli issue_backed_lifecycle --no-fail-fast` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Focused lifecycle record integration coverage passed. |
| `cargo test -p nils-plan-issue-cli` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Full plan-issue-cli tests passed before final compat rename. |
| `cargo test -p nils-plan-tooling` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Confirmed plan-tooling boundary still passes its own tests. |
| `cargo test -p nils-forge-cli` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Confirmed provider CRUD wrapper tests remain passing. |
| `cargo build -p nils-plan-issue-cli -p nils-forge-cli -p nils-plan-tooling` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Built the affected binaries and libraries. |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Workspace gate passed: docs placement/hygiene, markdown lint, plan-bundle validation, CLI output contract, fixture lint, fmt, clippy, 3524 nextest tests, and doctests. |
| `bash -n completions/bash/plan-issue && bash -n completions/bash/plan-issue-local && zsh -n completions/zsh/_plan-issue && zsh -n completions/zsh/_plan-issue-local` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | Generated completion scripts parse successfully. |
| `git diff --check` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | No whitespace errors before commit. |
| `semantic-commit commit --automation --summary git-show ...` | pass | nils-cli commit `257742a2a2a65198626870b1e49b1d72b8944501` | CLI lane committed as `feat(plan-issue): add issue-backed record lifecycle`. |
| `plan-issue record render-comment --kind state/session/validation --marker-family compat ...` | pass | issue #50 comments | Debug binary rendered issue #43-compatible durable comments. |
| `plan-issue record render-dashboard ...` | pass | https://github.com/graysurf/agent-runtime-kit/issues/50 | Debug binary rendered the mutable issue dashboard and `gh issue edit` applied it. |
| `agent-runtime render --product codex --update-golden` | pass | current session | Regenerated Codex build output and golden snapshots after skill/manifest changes. |
| `agent-runtime render --product claude --update-golden` | pass | current session | Regenerated Claude build output and golden snapshots after skill/manifest changes. |
| `agent-runtime render --product codex` | pass | current session | Render cache confirms Codex output is current. |
| `agent-runtime render --product claude` | pass | current session | Render cache confirms Claude output is current. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | pass | current session | PR domain smoke passed 7/7, including dispatch-lane PR session comment rendering. |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` | pass | current session | Dispatch domain smoke passed 8/8 with tracking and dispatch record comments. |
| `git diff --check` | pass | current session | No whitespace errors in the agent-runtime-kit diff. |
| `agent-runtime audit-drift` | pass | current session | Drift audit is clean except documented intentional Codex/Claude plugin manifest differences. |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | current session | Acceptance matrix covers 54 expected skill IDs after renames. |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | current session | Sandbox install rehearsal passed for Claude and Codex. |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | current session | Full deterministic runtime smoke passed 44/44. |
| `review-specialists scope --base origin/main --testing --maintainability --api-contract` | pass | review artifacts | Runtime-kit diff required api-contract, maintainability, testing, and red-team review because diff lines exceeded 200. |
| `review-specialists validate --input .../findings.jsonl --repo /Users/terry/Project/graysurf/agent-runtime-kit --validate-paths` | pass | review artifacts | Runtime-kit finding normalized and path-validated. |
| `review-specialists scope --base origin/main --testing --maintainability --api-contract` | pass | review artifacts | Nils-cli diff required api-contract, maintainability, testing, and red-team review because diff lines exceeded 200. |
| `review-specialists validate --input .../nils-cli/findings.jsonl --repo /Users/terry/Project/sympoies/nils-cli-issue-backed-plan-lifecycle --validate-paths --validate-lines` | pass | review artifacts | Nils-cli finding normalized and line-validated. |
| `cargo test -p nils-plan-issue-cli issue_backed_lifecycle_closeout_gate_filters_linked_prs_by_profile -- --nocapture` | pass | nils-cli commit `cdd8f76` | Regression for cross-profile linked PR evidence filtering passed. |
| `cargo test -p nils-plan-issue-cli issue_backed_lifecycle --no-fail-fast` | pass | nils-cli commit `cdd8f76` | Focused lifecycle tests passed after review fix. |
| `cargo test -p nils-plan-issue-cli` | pass | nils-cli commit `cdd8f76` | Full plan-issue-cli suite passed after review fix. |
| `git diff --check` | pass | nils-cli worktree `feat/issue-backed-plan-lifecycle-cli` | No whitespace errors after review fix. |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | pass | nils-cli commit `cdd8f76` | Workspace gate passed after review fix: 3525 nextest tests and doctests. |
| `PATH="/Users/terry/Project/sympoies/nils-cli-issue-backed-plan-lifecycle/target/debug:$PATH" tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` | pass | current session | Dispatch smoke passed 8/8 against updated debug binary. |
| `PATH="/Users/terry/Project/sympoies/nils-cli-issue-backed-plan-lifecycle/target/debug:$PATH" bash scripts/ci/all.sh` | pass | current session | Runtime-kit CI positions 1-9 passed against updated debug binary. |
| `semantic-commit commit --automation --summary git-show ...` | pass | nils-cli commit `cdd8f76` | Review fix committed as `fix(plan-issue): filter closeout evidence by profile`. |
| `forge-cli --provider github --repo sympoies/nils-cli --format json pr create ...` | pass | https://github.com/sympoies/nils-cli/pull/445 | Opened draft nils-cli PR for the unreleased CLI side. |
| `forge-cli --provider github --repo graysurf/agent-runtime-kit --format json pr create ...` | pass | https://github.com/graysurf/agent-runtime-kit/pull/51 | Opened draft runtime-kit PR for the skill, render, smoke, and plan-state changes. |

## Notes

- This plan intentionally spans `agent-runtime-kit` and
  `/Users/terry/Project/sympoies/nils-cli`.
- `Location` entries for nils-cli implementation tasks point at this execution
  state or the discussion source because `plan-tooling` validates locations
  relative to the current `agent-runtime-kit` repository.
- Actual nils-cli code changes must be recorded here with exact paths, commits,
  commands, and debug-binary integration evidence as execution proceeds.
