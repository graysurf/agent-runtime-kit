# Phase 4 Domain Migration Sweep Execution State

## Current State

- Status: ready-for-sprint-8
- Target scope: Sprint 1 through Sprint 7 complete; Sprint 8 not started
- Execution window: Sprint 7 dispatch domain migration closeout / pre-Sprint 8 checkpoint
- Staged execution confirmation: not applicable
- Current task: Pre-Sprint 8 checkpoint complete
- Next task: Stop before Sprint 8 overlay gates until the owner starts it
- Last updated: 2026-05-22 22:07 CST
- Branch/commit/PR: main; merge commit 47ab356327a70e3d1ef1ef1aab4e223c3fa1631f; PR #39 merged
- Source document: docs/plans/05-domain-migration/05-domain-migration-plan.md
- Direct source-doc execution waiver: not applicable

## Plan 06 Acceptance Dependency

Plan 05 Sprint 5+ must not resume until the Plan 06 runtime skill acceptance
harness is in place and deterministic acceptance is green for every Sprint 1-4
migrated skill, or the affected case has an explicit `skip-host-capability`
classification. The required continuation checks are:

- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic`
- `bash scripts/ci/all.sh`

Product-in-the-loop smoke is a quarantined/manual evidence lane, not a required
Sprint 5 blocker. Product prompt execution remains skipped by default unless an
operator supplies isolated provider/auth state; any `blocked-design` product
result must be recorded before migration proceeds past the affected surface.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | done | Re-verify Plan 03 reporting POC | `bash scripts/ci/all.sh` pass | Baseline reporting POC/full gate passed before meta edits |
| Task 1.2 | done | Migrate policy and state meta skills | `core/skills/meta/{agent-docs,agent-out,agent-scope-lock}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 1.3 | done | Migrate workflow meta skills | `core/skills/meta/{heuristic-inbox,repo-retro,semantic-commit}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 1.4 | done | Wire meta manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/` | Shared meta integration rendered for Codex and Claude |
| Task 2.1 | done | Migrate media skill sources | `core/skills/media/{image-processing,screen-record}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 2.2 | done | Migrate browser skill sources | `core/skills/browser/{browser-session,canary-check}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 2.3 | done | Wire media/browser manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/` | Media and browser plugins render/install dry-run cleanly |
| Task 3.1 | done | Migrate web and test-first evidence sources | `core/skills/evidence/{web-evidence,test-first-evidence}/SKILL.md.tera` | Evidence capture lane A invokes released nils-cli primitives only |
| Task 3.2 | done | Migrate review and skill-usage evidence sources | `core/skills/evidence/{review-evidence,skill-usage}/SKILL.md.tera` | Evidence capture lane B invokes released nils-cli primitives only |
| Task 3.3 | done | Wire evidence capture manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/` | Evidence capture plugin integration rendered for both products |
| Task 4.1 | done | Migrate docs-impact source | `core/skills/evidence/docs-impact/SKILL.md.tera` | Body invokes `docs-impact` and separates CLI classification from judgment |
| Task 4.2 | done | Migrate model-cross-check source | `core/skills/evidence/model-cross-check/SKILL.md.tera` | Body records provider-boundary notes and invokes `model-cross-check` |
| Task 4.3 | done | Finalize evidence domain integration | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/`, `docs/source/extraction-backlog.md` | Complete evidence domain gate passed; no extraction blocker found |
| Task 5.1 | done | Migrate PR/MR create skills | `core/skills/pr/{create-github-pr,create-gitlab-mr,create-dispatch-lane-pr}/SKILL.md.tera` | Create bodies invoke released `forge-cli pr create` surfaces only. |
| Task 5.2 | done | Migrate PR/MR close skills and wire create/close integration | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/`, runtime-smoke `pr` probes | Create/close PR plugin integration rendered for both products; `forge-cli` dry-run smoke passed. |
| Task 6.1 | done | Migrate delivery skill sources | `core/skills/pr/{deliver-github-pr,deliver-gitlab-mr}/SKILL.md.tera` | Delivery bodies invoke released `forge-cli pr deliver` surfaces only. |
| Task 6.2 | done | Add delivery lifecycle smoke harness | `tests/smoke/deliver-lifecycle.sh` | Harness dry-run, target guards, repeatable scratch branch setup, and live scratch PR delivery passed. |
| Task 6.3 | done | Wire delivery manifests, golden snapshots, and PR domain gate | manifests, plugin manifests, sandbox pins, `tests/golden/`, runtime-smoke `pr` probes | Integration and deterministic dry-run pass; `P5-S5-G1` closed by nils-cli `v0.17.1`, and live Sprint 6 smoke passed against `graysurf/agent-runtime-kit-smoke`. |
| Task 7.1 | done | Migrate issue lifecycle dispatch sources | `core/skills/dispatch/{plan-tracking-issue,issue-lifecycle,tracking-issue-closeout}/SKILL.md.tera` | Bodies invoke released `plan-tooling`, `plan-issue`, and `plan-issue-local` surfaces only. |
| Task 7.2 | done | Migrate execution and dispatch orchestration sources | `core/skills/dispatch/{execute-from-tracking-issue,deliver-tracking-issue,dispatch-pr-review,dispatch-subagent-pr}/SKILL.md.tera` | Bodies invoke released `forge-cli`, `plan-issue`, and `review-evidence` surfaces only. |
| Task 7.3 | done | Wire dispatch manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/`, runtime-smoke `dispatch` probes | Dispatch plugin integration rendered for both products; deterministic dispatch smoke passed. |
| Task 8.1 | pending | Audit private overlay effective config | n/a | `.private` values remain untracked |
| Task 8.2 | pending | Verify project-local overlay smoke gate | n/a | Adds stable fixture only |
| Task 9.1 | pending | Prepare legacy repository archive markers | n/a | Root `MOVED.md` in legacy repos |
| Task 9.2 | pending | Archive legacy repositories on GitHub | n/a | Archive, do not delete |
| Task 9.3 | pending | Remove local legacy pointers and migrate Claude state | n/a | Recommended cutover 2026-06-30 |

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --format text --explain` | pass | Plan bundle validation passed through `bash scripts/ci/all.sh` | n/a |
| `for n in 1 2 3 4 5 6 7 8 9; do plan-tooling batches --file docs/plans/05-domain-migration/05-domain-migration-plan.md --sprint "$n" --format json; done` | pass | Sprint DAG/sizing check passed for every sprint | `agent-out` run dir `issue-26-sprint-4` |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 1 --strategy deterministic --pr-grouping group --pr-group 'Task 1.1=s1-reporting-guard' --pr-group 'Task 1.2=s1-meta-policy-state' --pr-group 'Task 1.3=s1-meta-workflow' --pr-group 'Task 1.4=s1-meta-integration' --format json` | pass | Sprint 1 dependency-layer PR split returned expected records | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 2 --strategy deterministic --pr-grouping group --pr-group 'Task 2.1=s2-media-source' --pr-group 'Task 2.2=s2-browser-source' --pr-group 'Task 2.3=s2-media-browser-integration' --format json` | pass | Sprint 2 dependency-layer PR split returned expected records | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 3 --strategy deterministic --pr-grouping group --pr-group 'Task 3.1=s3-web-test-evidence' --pr-group 'Task 3.2=s3-review-usage-evidence' --pr-group 'Task 3.3=s3-evidence-capture-integration' --format json` | pass | Sprint 3 dependency-layer PR split returned expected records | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 7 --strategy deterministic --pr-grouping group --pr-group 'Task 7.1=s7-issue-lifecycle' --pr-group 'Task 7.2=s7-execution-orchestration' --pr-group 'Task 7.3=s7-dispatch-integration' --format json` | pass | Sprint 7 dependency-layer PR split returned Task 7.1, 7.2, and 7.3 grouped records. | n/a |
| `for n in 4 5 6 8 9; do plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint "$n" --strategy deterministic --pr-grouping per-sprint --format json; done` | partial | Sprint 4 per-sprint split passed for selected scope; Sprints 5, 6, 8, and 9 remain future scope | n/a |
| `agent-runtime render --product codex` | pass | Rendered 26 Codex skills | n/a |
| `agent-runtime render --product claude` | pass | Rendered 26 Claude skills | n/a |
| `agent-runtime render --product codex --update-golden` | pass | Refreshed Codex golden snapshots including PR domain files | `tests/golden/codex/` |
| `agent-runtime render --product claude --update-golden` | pass | Refreshed Claude golden snapshots including PR domain files | `tests/golden/claude/` |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | Dry-run install skill-list diff passed for Claude and Codex | n/a |
| `agent-runtime audit-drift` | pass | Root audit clean; only documented product manifest info differences | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 24 unique skill ids plus quarantined product prompt cases. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Deterministic runtime smoke passed for all 24 migrated skill ids before Sprint 6 edits. | temp run root cleaned |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed before Sprint 6 edits, including 24-skill deterministic runtime smoke. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | pass | Sprint 5 PR domain probes passed for GitHub/GitLab create and close dry-run surfaces. | temp run root cleaned |
| `forge-cli pr wait-checks 37 --provider github --repo graysurf/agent-runtime-kit --format json` | fail | `forge-cli 0.16.0` requested unsupported `gh 2.92.0` JSON field `conclusion`; recorded extraction backlog item `P5-S5-G1`. | n/a |
| `gh pr checks 37 --watch --interval 10 --fail-fast` | pass | Provider-native fallback verified PR #37 remote CI passed. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Runtime skill smoke now covers 24 skills including the Sprint 5 PR domain. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 24 skills each before Sprint 6 edits with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --format json` | pass | Product temp-home install summary updated to 24 skills before Sprint 6 edits; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary.json` |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 26 unique skill ids plus quarantined product prompt cases after Sprint 6 edits. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | pass | PR deterministic smoke now covers create, close, dispatch-lane create, and delivery macro dry-runs. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 26 skills each with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install --format json > /tmp/runtime-smoke-install-summary-s6.json && diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary-s6.json` | pass | Install JSON expected output updated to 26 skills. | `/tmp/runtime-smoke-install-summary-s6.json` |
| `bash tests/runtime-smoke/run.sh --mode product --format json > /tmp/runtime-smoke-product-summary-s6.json && diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary-s6.json` | pass | Product expected output updated to 26 installed skills; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary-s6.json` |
| `if bash tests/smoke/deliver-lifecycle.sh; then exit 1; else test $? -ne 0; fi` | pass | Delivery smoke refuses to run without scratch fork and branch. | n/a |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke` | pass | Safe default delivery smoke produced `forge-cli pr deliver --dry-run` evidence against scratch target metadata. | temp artifact path printed by command |
| `forge-cli --version` | pass | Local released binary reports `forge-cli 0.17.1`. | n/a |
| `gh release view v0.17.1 --repo sympoies/nils-cli --json tagName,url,publishedAt` | pass | Upstream nils-cli `v0.17.1` release is published and fixes the GitHub pending-check stdout path discovered during live smoke. | https://github.com/sympoies/nils-cli/releases/tag/v0.17.1 |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke --execute-live` | pass | Live delivery smoke created and merged scratch PR #4 using released `forge-cli 0.17.1`; scratch CI passed and merge commit is `45c6cb44b40a65fb1ee05145713921afcbf5ba4a`. | `/var/folders/3d/s2d3jvyn0g758lsd_2t79h1w0000gn/T//agent-runtime-kit-deliver-lifecycle.6KUs4y` |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed after Sprint 6 unblock, including deterministic runtime smoke `total=26 pass=26`. | n/a |
| `bash -n tests/runtime-smoke/run.sh tests/runtime-smoke/cases/dispatch/run.sh` | pass | Runtime-smoke dispatcher and dispatch case syntax passed. | n/a |
| `shellcheck tests/runtime-smoke/run.sh tests/runtime-smoke/cases/dispatch/run.sh` | pass | Shell lint passed for Sprint 7 runtime-smoke changes. | n/a |
| `shfmt -i 2 -ci -d tests/runtime-smoke/run.sh tests/runtime-smoke/cases/dispatch/run.sh` | pass | Shell formatting diff check passed. | n/a |
| `jq empty targets/codex/plugins/dispatch/.codex-plugin/plugin.json targets/claude/plugins/dispatch/.claude-plugin/plugin.json tests/runtime-smoke/expected/install-summary.json tests/runtime-smoke/product/expected/product-summary.json` | pass | Dispatch plugin manifests and expected JSON summaries parse cleanly. | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 33 unique skill ids across 43 cases after Sprint 7 dispatch additions. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` | pass | Dispatch deterministic smoke passed for all seven dispatch skill ids. | temp run root cleaned |
| `agent-runtime render --product codex --update-golden` | pass | Refreshed Codex golden snapshots including dispatch domain files; rendered 33 skills. | `tests/golden/codex/` |
| `agent-runtime render --product claude --update-golden` | pass | Refreshed Claude golden snapshots including dispatch domain files; rendered 33 skills. | `tests/golden/claude/` |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 33 skills each with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install --format json > /tmp/runtime-smoke-install-summary-s7.json && diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary-s7.json` | pass | Install expected output updated to 33 skills. | `/tmp/runtime-smoke-install-summary-s7.json` |
| `bash tests/runtime-smoke/run.sh --mode product --format json > /tmp/runtime-smoke-product-summary-s7.json && diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary-s7.json` | pass | Product expected output updated to 33 installed skills; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary-s7.json` |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Runtime skill smoke now covers 33 migrated skill ids including the Sprint 7 dispatch domain. | temp run root cleaned |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | Dry-run install skill-list diff passed for Claude and Codex with dispatch pins. | n/a |
| `agent-runtime audit-drift` | pass | Root audit clean; only documented product manifest info differences including dispatch plugin metadata. | n/a |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed after Sprint 7 edits, including deterministic runtime smoke `total=33 pass=33`. | n/a |
| `gh pr checks 39 --watch --interval 10 --fail-fast` | pass | PR #39 remote `scripts/ci/all.sh` check passed. | https://github.com/graysurf/agent-runtime-kit/actions/runs/26292428029/job/77395930874 |
| `/Users/terry/.config/agent-kit/skills/workflows/code-review/code-review-specialists/scripts/review_specialists.py scope --base origin/main --testing --maintainability` | pass | Specialist review scope selected testing and maintainability; red-team review applied due broad diff; no displayed findings remained. | n/a |
| `gh pr comment 39 --body-file <delivery-review-outcome>` | pass | Posted delivery review outcome comment with merge decision and no blocking findings. | https://github.com/graysurf/agent-runtime-kit/pull/39#issuecomment-4519412557 |
| `/Users/terry/.config/agent-kit/skills/workflows/pr/github/close-github-pr/scripts/close-github-pr.sh --kind feature --pr 39` | pass | PR #39 marked ready, merged, remote branch deleted, local branch cleaned up, and `main` fast-forwarded to merge commit `47ab356327a70e3d1ef1ef1aab4e223c3fa1631f`. | https://github.com/graysurf/agent-runtime-kit/pull/39 |
| `agent-runtime install --product claude --dry-run` | pending | Sprint 8 effective config check | n/a |
| `agent-runtime install --product codex --dry-run` | pending | Sprint 8 effective config check | n/a |
| `bash tests/projects/project-local-smoke/run.sh` | pending | Sprint 8 project-local overlay smoke | n/a |
| `agent-runtime doctor --check-project tests/projects/project-local-smoke` | pending | Sprint 8 project-local doctor check | n/a |
| `gh repo view graysurf/agent-kit --json isArchived,name` | pending | Sprint 9 archive verification | n/a |
| `gh repo view graysurf/claude-kit --json isArchived,name` | pending | Sprint 9 archive verification | n/a |
| `test ! -L "$HOME/.agents"` | pending | Sprint 9 symlink removal check | n/a |
| `state_root="${XDG_STATE_HOME:-$HOME/.local/state}"; if [ -d "$state_root/agent-runtime-kit/claude" ]; then test ! -d "$state_root/claude-kit"; else rg -q 'claude-kit state migration no-op' docs/plans/05-domain-migration/05-domain-migration-execution-state.md; fi` | pending | Sprint 9 conditional state-home check | n/a |

## Blockers

- Any missing nils-cli binary or required flag blocks the affected skill body
  and must be logged in `docs/source/extraction-backlog.md`.
- Plan 06 deterministic acceptance is satisfied through Sprint 7 by the current
  `matrix`, `deterministic`, and `scripts/ci/all.sh` validation; rerun the
  same gate before future sprint merges.
- Sprint 6 delivery smoke requires a scratch fork/branch and must not target
  `graysurf/agent-runtime-kit` `main`.
- Sprint 7 dispatch migration is merged in PR #39 at
  `47ab356327a70e3d1ef1ef1aab4e223c3fa1631f`.
- Sprint 8 overlay gates have not been started.
- Sprint 9 requires GitHub admin permission on `graysurf/agent-kit` and
  `graysurf/claude-kit`.
- Local cutover should use the recommended 2026-06-30 date unless the execution
  owner records a different decision.

## Session Log

- 2026-05-22: Bootstrapped issue-backed execution state for GitHub issue #26 because the issue had source/plan snapshots but no `execute-from-tracking-issue:state:v1` comment.
- 2026-05-22: Completed Sprint 1 through Sprint 4 in branch `feat/issue-26-sprint-4`: added meta, media, browser, and evidence portable skill source bodies; wired manifests, product plugin metadata, link maps, sandbox expected skill pins, and golden snapshots; added `docs/source/extraction-backlog.md` with no selected-scope extraction blockers.
- 2026-05-22: Validation passed: `bash scripts/ci/all.sh`, selected `plan-tooling split-prs` checks, full `plan-tooling batches` sweep, `agent-runtime audit-drift`, and `bash scripts/ci/sandbox-install-rehearsal.sh`.
- 2026-05-22: Recorded Plan 06 acceptance dependency before Sprint 5+ resumes: deterministic runtime smoke is the required gate; product smoke remains manual/quarantined until isolated provider/auth execution is supplied.
- 2026-05-22: Completed Sprint 5 PR create/close migration in branch `feat/plan-05-pr-domain`: added `forge-cli`-backed PR/MR create and close skill sources, PR plugin manifests/link maps, golden snapshots, sandbox pins, and deterministic PR runtime-smoke probes; opened PR #37.
- 2026-05-22: Recorded extraction backlog item `P5-S5-G1` after live `forge-cli pr checks` / `wait-checks` failed against `gh 2.92.0`; used `gh pr checks` as the provider-native fallback for PR #37 CI evidence.
- 2026-05-22: Implemented Sprint 6 delivery macro sources, PR manifest wiring, deterministic delivery dry-run probes, and `tests/smoke/deliver-lifecycle.sh`; live scratch delivery smoke is blocked because `graysurf/agent-runtime-kit-smoke` is unavailable and GitHub live checks still depend on `P5-S5-G1`.
- 2026-05-22: Created and configured scratch repository `graysurf/agent-runtime-kit-smoke`, delivered `sympoies/nils-cli` issue #439, released and installed `nils-cli v0.17.1`, bumped PR-domain `forge-cli` floors to `>=0.17.1`, and passed live Sprint 6 delivery smoke by creating and merging scratch PR #4.
- 2026-05-22: Merged Plan 05 Sprint 6 PR #38 at `b21e22d7594ea817532dbd0ce1530066f6f02a88`; issue #26 dashboard, state, validation, and session comments now mark Sprint 6 complete and Sprint 7 intentionally not started.
- 2026-05-22: Started Sprint 7 dispatch domain migration on `feat/plan-05-dispatch-domain`; Sprint 7 split-prs readiness passed and Task 7.1 is in progress.
- 2026-05-22: Completed Sprint 7 dispatch source migration, manifests, product plugin metadata, link maps, golden snapshots, sandbox pins, and deterministic dispatch runtime smoke; local CI passed with `total=33 pass=33`.
- 2026-05-22: Fixed a small Sprint 7 usage bug before commit: removed unsupported `forge-cli pr create --draft` guidance from `dispatch-subagent-pr` because draft PRs are the default in released `forge-cli 0.17.1`.
- 2026-05-22: Merged Plan 05 Sprint 7 PR #39 at `47ab356327a70e3d1ef1ef1aab4e223c3fa1631f`; issue #26 dashboard, state, validation, and session comments should now mark Sprint 7 complete and Sprint 8 intentionally not started.
