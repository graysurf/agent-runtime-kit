# Reporting POC Execution State

## Current State

- Status: not started
- Target scope: whole plan
- Execution window: undecided
- Staged execution confirmation: not applicable
- Current task: Task 1.1
- Next task: Task 1.1
- Last updated: 2026-05-20
- Branch/commit: not started
- Source document: docs/plans/03-reporting-poc/03-reporting-poc-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID       | Status  | Task                                                                              | Evidence | Notes                                                                |
| -------- | ------- | --------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------- |
| Task 1.1 | pending | Write portable `daily-brief/SKILL.md`                                             | n/a      | reads $HOME/.config/claude + agent-kit legacy bodies                 |
| Task 1.2 | pending | Write portable `project-retro/SKILL.md`                                           | n/a      | reads $HOME/.config/claude + agent-kit legacy bodies                 |
| Task 1.3 | pending | Write portable `topic-radar/SKILL.md` and migrate `topic-radar.sh`                | n/a      | script migrated as-is; nils-cli extraction deferred to backlog       |
| Task 2.1 | pending | Write Codex adapter metadata                                                      | n/a      | local-only per Resolved Decision #10                                 |
| Task 2.2 | pending | Write Claude adapter metadata                                                     | n/a      | upstream Claude plugin schema                                        |
| Task 2.3 | pending | Fill `manifests/skills.yaml` with reporting entries                               | n/a      | concrete `required_clis: ">=0.1.0"` floors; no `<TBD>` allowed       |
| Task 2.4 | pending | Fill `manifests/plugins.yaml` with the reporting plugin entry                     | n/a      | enumerates three contained skills                                    |
| Task 2.5 | pending | Fill `manifests/product-capabilities.yaml`                                        | n/a      | Codex vs Claude shape + `plugin_manifest_diff` block                 |
| Task 2.6 | pending | Fill `manifests/runtime-roots.yaml` with the root-map block                       | n/a      | versions pinned from host on 2026-05-20; effective_from 2026-06-03   |
| Task 3.1 | pending | Generate and commit render-golden snapshots                                       | n/a      | six (skill, product) expected/ directories                           |
| Task 3.2 | pending | Add drift fixtures for the four POC drift classes                                 | n/a      | source-manifest / rendered-target diff / agent-home leak / docs-home |
| Task 3.3 | pending | Confirm clean POC audit-drift exits 0                                             | n/a      | matches source-doc drift-audit example lines 1632–1642               |
| Task 4.1 | pending | Pin Codex dry-run install snapshot                                                | n/a      | tests/install/codex/expected.txt                                     |
| Task 4.2 | pending | Pin Claude dry-run install snapshot                                               | n/a      | tests/install/claude/expected.txt                                    |

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/03-reporting-poc/03-reporting-poc-plan.md --strict --format text` | pending | run before first commit | n/a |
| `agent-runtime render --check` | pending | end of Sprint 2 | n/a |
| `agent-runtime render --update-golden --domain reporting` | pending | Sprint 3 Task 3.1 | tests/golden/ |
| `git diff --exit-code tests/golden/` | pending | Sprint 3 Task 3.1 | n/a |
| `agent-runtime audit-drift --format text` | pending | Sprint 3 Task 3.3 | n/a |
| `diff -u tests/install/codex/expected.txt <(agent-runtime install --product codex --dry-run)` | pending | Sprint 4 Task 4.1 | tests/install/codex/expected.txt |
| `diff -u tests/install/claude/expected.txt <(agent-runtime install --product claude --dry-run)` | pending | Sprint 4 Task 4.2 | tests/install/claude/expected.txt |

## Blockers

- Plan 02 (`02-nils-cli-render-and-drift-audit`) must ship the
  `0.1.0` nils-cli release through `sympoies/homebrew-tap` before
  Sprint 1 can run. `agent-runtime render` and the minimal
  `audit-drift` body are hard prerequisites.
- Reviewer must confirm the `path_override` default for
  `reporting.topic-radar` before Sprint 2 commits. Default
  recommended in the source doc: declare
  `products.codex.path_override: skills/tools/market-research/topic-radar`.

## Session Log

(none yet)
