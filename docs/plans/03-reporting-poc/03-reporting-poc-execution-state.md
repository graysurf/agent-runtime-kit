# Reporting POC Execution State

## Current State

- Status: paused on Plan 02 gaps (blocked on sympoies/nils-cli v0.14.0)
- Target scope: whole plan (2-sprint revision)
- Execution window: undecided — resumes after v0.14.0
- Staged execution confirmation: not applicable
- Current task: Task 1.1 (deliverables drafted, parked on `feat/plan-03-sprint-1-reporting-bodies-and-manifests`)
- Next task: Task 1.1 (re-validate against v0.14.0 render surface)
- Last updated: 2026-05-21
- Branch/commit: `feat/plan-03-sprint-1-reporting-bodies-and-manifests` @ `d890b11` (WIP, not merged)
- Source document: docs/plans/03-reporting-poc/03-reporting-poc-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID       | Status                                  | Task                                                                              | Evidence                                       | Notes                                                                                                  |
| -------- | --------------------------------------- | --------------------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Task 1.1 | drafted, blocked on nils-cli#409/#410   | Write portable `daily-brief/SKILL.md`                                             | `d890b11`                                      | body present; rendered output is host-specific (script() leak) and missing siblings (multi-file render)|
| Task 1.2 | drafted, blocked on nils-cli#409/#410   | Write portable `project-retro/SKILL.md`                                           | `d890b11`                                      | body present; same render shape concerns                                                               |
| Task 1.3 | drafted, blocked on nils-cli#409/#410   | Write portable `topic-radar/SKILL.md` and migrate `topic-radar.sh`                | `d890b11`                                      | SKILL.md + bin/ + scripts/ + references/ present in source; build/ omits sibling files                 |
| Task 1.4 | drafted                                 | Write Codex adapter metadata                                                      | `d890b11`                                      | `targets/codex/plugins/reporting/.codex-plugin/plugin.json`, valid JSON                                |
| Task 1.5 | drafted                                 | Write Claude adapter metadata                                                     | `d890b11`                                      | `targets/claude/plugins/reporting/.claude-plugin/plugin.json`, valid JSON                              |
| Task 1.6 | drafted                                 | Fill `manifests/skills.yaml` with reporting entries                               | `d890b11`                                      | 3 entries; `required_clis: ">=0.13.0"` concrete; `state_out_mode: runtime`; topic-radar path_override  |
| Task 1.7 | drafted                                 | Fill `manifests/plugins.yaml` with the reporting plugin entry                     | `d890b11`                                      | one `reporting` plugin; contained_skills enumerates the three                                          |
| Task 1.8 | drafted                                 | Fill `manifests/product-capabilities.yaml`                                        | `d890b11`                                      | `plugin_manifest_diff` block refined against the concrete adapter `plugin.json` files                  |
| Task 1.9 | done                                    | Verify `manifests/runtime-roots.yaml` root-map block                              | `d890b11` (verify only)                        | pins still current (codex 0.130.0 / claude 2.1.145, host claude 2.1.146 ≥ pin → no re-snapshot needed) |
| Task 2.1 | blocked on Sprint 1                     | Generate and commit render-golden snapshots                                       | n/a                                            | cannot pin until script() emits host-portable paths                                                    |
| Task 2.2 | blocked on Sprint 1                     | Add drift fixtures for the four POC drift classes                                 | n/a                                            | depends on Task 2.1                                                                                    |
| Task 2.3 | blocked on Sprint 1                     | Confirm clean POC audit-drift exits 0                                             | partial (clean tree exits 0 with current body) | already verified on `d890b11`; will re-verify after re-render under v0.14.0                            |

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

- **sympoies/nils-cli#409** — `agent-runtime render` only copies the
  rendered `SKILL.md` leaf into `build/<product>/...`. Sibling files
  (`bin/`, `scripts/`, `references/`) are not copied, so the
  `topic-radar` skill ships an SKILL body that references a script
  path absent from the rendered tree. Sprint 1 acceptance ("script
  exists and is executable in the rendered output") cannot be met.
- **sympoies/nils-cli#410** — `{{ script(path=...) }}` helper emits
  an absolute host filesystem path (`/Users/<user>/...`) instead of
  the source-doc canonical `$CODEX_HOME/...` /
  `${CLAUDE_PLUGIN_ROOT}/...` shape. `audit-drift` v0.13.0 only flags
  `$AGENT_HOME` literal and does not catch this leak. Sprint 2
  goldens cannot be pinned host-portable until this lands.
- **sympoies/nils-cli#411** — `render_to` values containing
  `build/<product>/` get doubled (output lands at
  `build/codex/build/codex/...`). The render-cache JSON records the
  intended single-prefix path. Either source-doc canonical needs to
  drop the `build/<product>/` prefix from example `render_to` values,
  or the binary needs to stop prepending. Low-effort fix once a
  direction is picked; Sprint 1 manifests need re-touching.
- Plan 01 cleanup PR (merged 2026-05-21) pinned `runtime-roots.yaml`
  versions and removed the residual `$AGENT_HOME` literal; baseline
  `audit-drift` exits 0 on the parked Sprint 1 WIP.
- nils-cli v0.13.0 is on PATH and ships the actual `render` /
  `audit-drift` bodies; the gaps above are scope-completeness issues,
  not regressions.

## Resume Condition

- sympoies/nils-cli v0.14.0 (or whichever release closes #409, #410,
  #411) ships through `sympoies/homebrew-tap`.
- `brew upgrade nils-cli` on the dev host pulls v0.14.0.
- Re-pull the parked branch
  `feat/plan-03-sprint-1-reporting-bodies-and-manifests`, re-run
  `agent-runtime render --product codex && --product claude`, confirm
  build tree mirrors source layout (full subtree per skill,
  host-portable script paths, single `build/<product>/` prefix).
- Re-verify Sprint 1 gates (grep clean, render exit 0, audit-drift
  exit 0). Open PR for Sprint 1.

## Session Log

- 2026-05-21 — Sprint 1 implementation attempted, paused mid-validation.
  Drafted all 9 Sprint 1 artifacts (`d890b11` on
  `feat/plan-03-sprint-1-reporting-bodies-and-manifests`). Stated
  Sprint 1 gates passed locally (`render --product {codex,claude}`
  exit 0, `audit-drift` exit 0, no `$AGENT_HOME` literals in
  `core/skills/reporting/`). Discovery revealed three Plan 02
  scope-completeness gaps in v0.13.0: filed
  sympoies/nils-cli#409 (multi-file render),
  sympoies/nils-cli#410 (script() helper emits absolute host path),
  sympoies/nils-cli#411 (render_to doubling). Plan 03 paused until
  v0.14.0 closes these. Branch preserved on remote; no PR opened.
- 2026-05-21 — Plan rev (pre-implementation). Sprint count reduced
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
