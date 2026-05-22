# Phase 4 Domain Migration Sweep Execution State

## Current State

- Status: in-progress
- Target scope: Sprint 1 through Sprint 5 complete; Sprint 6+ pending
- Execution window: Sprint 5 PR create/close domain migration
- Staged execution confirmation: not applicable
- Current task: Task 5.2 complete pending PR merge
- Next task: Task 6.1 after Sprint 5 PR merge
- Last updated: 2026-05-22 17:06 CST
- Branch/commit/PR: feat/plan-05-pr-domain; pending
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
| Task 6.1 | pending | Migrate delivery skill sources | n/a | `forge-cli` delivery macros |
| Task 6.2 | pending | Add delivery lifecycle smoke harness | n/a | Scratch fork/branch only |
| Task 6.3 | pending | Wire delivery manifests, golden snapshots, and PR domain gate | n/a | Full PR-domain integration |
| Task 7.1 | pending | Migrate issue lifecycle dispatch sources | n/a | `plan-issue`, `plan-issue-local`, `plan-tooling` |
| Task 7.2 | pending | Migrate execution and dispatch orchestration sources | n/a | Execution/review handoff lane |
| Task 7.3 | pending | Wire dispatch manifests, adapters, and golden snapshots | n/a | Full dispatch-domain integration |
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
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 7 --strategy deterministic --pr-grouping group --pr-group 'Task 7.1=s7-issue-lifecycle' --pr-group 'Task 7.2=s7-execution-orchestration' --pr-group 'Task 7.3=s7-dispatch-integration' --format json` | pending | Sprint 7 dependency-layer PR split | n/a |
| `for n in 4 5 6 8 9; do plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint "$n" --strategy deterministic --pr-grouping per-sprint --format json; done` | partial | Sprint 4 per-sprint split passed for selected scope; Sprints 5, 6, 8, and 9 remain future scope | n/a |
| `agent-runtime render --product codex` | pass | Rendered 19 Codex skills | n/a |
| `agent-runtime render --product claude` | pass | Rendered 19 Claude skills | n/a |
| `agent-runtime render --product codex --update-golden` | pass | Refreshed Codex golden snapshots | `tests/golden/codex/` |
| `agent-runtime render --product claude --update-golden` | pass | Refreshed Claude golden snapshots | `tests/golden/claude/` |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | Dry-run install skill-list diff passed for Claude and Codex | n/a |
| `agent-runtime audit-drift` | pass | Root audit clean; only documented product manifest info differences | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 24 unique skill ids plus quarantined product prompt cases. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Deterministic runtime smoke passed for all 24 migrated skill ids. | temp run root cleaned |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed, including 24-skill deterministic runtime smoke. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | pass | Sprint 5 PR domain probes passed for GitHub/GitLab create and close dry-run surfaces. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Runtime skill smoke now covers 24 skills including the Sprint 5 PR domain. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 24 skills each with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --format json` | pass | Product temp-home install summary updated to 24 skills; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary.json` |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke` | pending | Sprint 6 scratch delivery smoke | n/a |
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
- Sprint 5+ must not continue unless Plan 06 deterministic acceptance is green
  for Sprint 1-4 migrated skills, or an affected case has an explicit
  `skip-host-capability` classification.
- Sprint 6 delivery smoke requires a scratch fork/branch and must not target
  `graysurf/agent-runtime-kit` `main`.
- Sprint 9 requires GitHub admin permission on `graysurf/agent-kit` and
  `graysurf/claude-kit`.
- Local cutover should use the recommended 2026-06-30 date unless the execution
  owner records a different decision.

## Session Log

- 2026-05-22: Bootstrapped issue-backed execution state for GitHub issue #26 because the issue had source/plan snapshots but no `execute-from-tracking-issue:state:v1` comment.
- 2026-05-22: Completed Sprint 1 through Sprint 4 in branch `feat/issue-26-sprint-4`: added meta, media, browser, and evidence portable skill source bodies; wired manifests, product plugin metadata, link maps, sandbox expected skill pins, and golden snapshots; added `docs/source/extraction-backlog.md` with no selected-scope extraction blockers.
- 2026-05-22: Validation passed: `bash scripts/ci/all.sh`, selected `plan-tooling split-prs` checks, full `plan-tooling batches` sweep, `agent-runtime audit-drift`, and `bash scripts/ci/sandbox-install-rehearsal.sh`.
- 2026-05-22: Recorded Plan 06 acceptance dependency before Sprint 5+ resumes: deterministic runtime smoke is the required gate; product smoke remains manual/quarantined until isolated provider/auth execution is supplied.
- 2026-05-22: Completed Sprint 5 PR create/close migration in branch `feat/plan-05-pr-domain`: added `forge-cli`-backed PR/MR create and close skill sources, PR plugin manifests/link maps, golden snapshots, sandbox pins, and deterministic PR runtime-smoke probes.
