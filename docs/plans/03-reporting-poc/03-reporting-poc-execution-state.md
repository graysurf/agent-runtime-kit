# Reporting POC Execution State

## Current State

- Status: not started
- Target scope: whole plan (2-sprint revision)
- Execution window: undecided
- Staged execution confirmation: not applicable
- Current task: Task 1.1
- Next task: Task 1.1
- Last updated: 2026-05-21
- Branch/commit: not started
- Source document: docs/plans/03-reporting-poc/03-reporting-poc-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID       | Status  | Task                                                                              | Evidence | Notes                                                                |
| -------- | ------- | --------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------- |
| Task 1.1 | pending | Write portable `daily-brief/SKILL.md`                                             | n/a      | reads $HOME/.config/claude + agent-kit legacy bodies                 |
| Task 1.2 | pending | Write portable `project-retro/SKILL.md`                                           | n/a      | reads $HOME/.config/claude + agent-kit legacy bodies                 |
| Task 1.3 | pending | Write portable `topic-radar/SKILL.md` and migrate `topic-radar.sh`                | n/a      | script migrated as-is; nils-cli extraction deferred to backlog       |
| Task 1.4 | pending | Write Codex adapter metadata                                                      | n/a      | local-only per Resolved Decision #10                                 |
| Task 1.5 | pending | Write Claude adapter metadata                                                     | n/a      | upstream Claude plugin schema                                        |
| Task 1.6 | pending | Fill `manifests/skills.yaml` with reporting entries                               | n/a      | concrete `required_clis: ">=0.13.0"` floors; no placeholder strings  |
| Task 1.7 | pending | Fill `manifests/plugins.yaml` with the reporting plugin entry                     | n/a      | enumerates three contained skills                                    |
| Task 1.8 | pending | Fill `manifests/product-capabilities.yaml`                                        | n/a      | Codex vs Claude shape + `plugin_manifest_diff` block                 |
| Task 1.9 | pending | Verify `manifests/runtime-roots.yaml` root-map block                              | n/a      | versions pinned by Plan 01 cleanup PR; verify still current          |
| Task 2.1 | pending | Generate and commit render-golden snapshots                                       | n/a      | six (skill, product) expected/ directories                           |
| Task 2.2 | pending | Add drift fixtures for the four POC drift classes                                 | n/a      | mini source roots invoked through `audit-drift --source-root`        |
| Task 2.3 | pending | Confirm clean POC audit-drift exits 0                                             | n/a      | matches source-doc drift-audit example lines 1632–1642               |

## Validation

| Command                                                                                                                                                                                                                       | Status  | Summary                                | Artifact                                  |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------------------------------------- | ----------------------------------------- |
| `plan-tooling validate --file docs/plans/03-reporting-poc/03-reporting-poc-plan.md --format text --explain`                                                                                                                   | pending | run before first commit                | n/a                                       |
| `agent-runtime render --product codex`                                                                                                                                                                                        | pending | Sprint 1 end-of-sprint gate            | `build/codex/plugins/reporting/`          |
| `agent-runtime render --product claude`                                                                                                                                                                                       | pending | Sprint 1 end-of-sprint gate            | `build/claude/plugins/reporting/`         |
| `agent-runtime audit-drift`                                                                                                                                                                                                   | pending | Sprint 1 + Sprint 2 baseline gate      | n/a                                       |
| `agent-runtime render --product codex --update-golden && agent-runtime render --product claude --update-golden && git diff --exit-code tests/golden/codex/plugins/reporting/ tests/golden/claude/plugins/reporting/`          | pending | Sprint 2 Task 2.1                      | `tests/golden/{codex,claude}/plugins/reporting/` |
| `agent-runtime audit-drift --source-root tests/drift/<scenario>/` for each of source-manifest-missing / rendered-target-diff / agent-home-leak / docs-home-mismatch                                                            | pending | Sprint 2 Task 2.2                      | `tests/drift/<scenario>/expected.{txt,exit}` |

## Blockers

- None blocking execution. The Plan 01 cleanup PR (merged 2026-05-21)
  pinned `runtime-roots.yaml` versions and removed the residual
  `$AGENT_HOME` literal, so the baseline `audit-drift` now exits 0.
- nils-cli v0.13.0 ships the actual `agent-runtime render` and
  `agent-runtime audit-drift` bodies; both are on PATH and verified.
- Original blocker entries (Plan 02 release; reviewer confirmation on
  `path_override`) are resolved and archived to the session log
  below.

## Session Log

- 2026-05-21 — Plan rev (no implementation yet). Sprint count reduced
  from 4 to 2: original Sprint 1 + Sprint 2 merged into a single PR
  because render byte-exact validation needs manifests to be present;
  original Sprint 4 (dry-run install snapshots) deferred to Plan 04
  Sprint 5 alongside the install body. All validation gates rewritten
  against the v0.13.0 `agent-runtime` surface (no `--check` /
  `--domain` / `--skill` / `--format` / `--fixture` flags).
- 2026-05-21 — Plan 01 cleanup PR landed alongside this rev: pinned
  `runtime-roots.yaml` codex `0.130.0` / claude `2.1.145` /
  `effective_from 2026-06-03`; reworded comment + cli-tools.md prose
  to drop residual `<TBD>` and `$AGENT_HOME` literals; baseline
  `audit-drift` confirmed exit 0.
- 2026-05-20 / 2026-05-21 — Open questions resolved:
  `reporting.topic-radar` `path_override` (Option A — source doc
  canonical L555–566 with both products); `topic-radar.sh` extraction
  (defer until skill stabilises); CLI surface alignment (rev Plan 03
  to v0.13.0 actual surface).
