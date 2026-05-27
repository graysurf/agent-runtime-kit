# Reporting POC Execution State

## Current State

- Status: in-progress (Sprint 2 landing under nils-cli v0.14.0)
- Target scope: whole plan (2-sprint revision)
- Execution window: Sprint 2 active (final sprint)
- Staged execution confirmation: not applicable
- Current task: Sprint 2 wrap-up (open PR)
- Next task: none — plan complete after Sprint 2 PR merges
- Last updated: 2026-05-21
- Branch/commit: `feat/plan-03-sprint-2-render-goldens-drift-fixtures` (active; built on Sprint 1 merge `dd31390`)
- Source document: docs/plans/2026-05-20-03-reporting-poc/03-reporting-poc-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID       | Status                                  | Task                                                                              | Evidence                                       | Notes                                                                                                  |
| -------- | --------------------------------------- | --------------------------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Task 1.1 | done                                    | Write portable `daily-brief/SKILL.md`                                             | `d890b11` + skills.yaml render_to bump          | body present; rendered output portable (`$CODEX_HOME` / `$HOME/.claude`) under v0.14.0                |
| Task 1.2 | done                                    | Write portable `project-retro/SKILL.md`                                           | `d890b11` + skills.yaml render_to bump          | body present; same render shape; portable under v0.14.0                                                |
| Task 1.3 | done                                    | Write portable `topic-radar/SKILL.md` and migrate `topic-radar.sh`                | `d890b11` + skills.yaml render_to bump          | SKILL.md.tera + bin/ + scripts/ + references/ all copy verbatim into build/<product>/ under v0.14.0    |
| Task 1.4 | done                                    | Write Codex adapter metadata                                                      | `d890b11`                                      | `targets/codex/plugins/reporting/.codex-plugin/plugin.json`, valid JSON                                |
| Task 1.5 | done                                    | Write Claude adapter metadata                                                     | `d890b11`                                      | `targets/claude/plugins/reporting/.claude-plugin/plugin.json`, valid JSON                              |
| Task 1.6 | done                                    | Fill `manifests/skills.yaml` with reporting entries                               | `d890b11` + render_to bump                      | 3 entries; `required_clis: ">=0.13.0"` concrete; `state_out_mode: runtime`; topic-radar path_override; render_to canonical `plugins/<plugin>/skills/<skill>/SKILL.md` shape under v0.14.0 |
| Task 1.7 | done                                    | Fill `manifests/plugins.yaml` with the reporting plugin entry                     | `d890b11`                                      | one `reporting` plugin; contained_skills enumerates the three                                          |
| Task 1.8 | done                                    | Fill `manifests/product-capabilities.yaml`                                        | `d890b11`                                      | `plugin_manifest_diff` block refined against the concrete adapter `plugin.json` files                  |
| Task 1.9 | done                                    | Verify `manifests/runtime-roots.yaml` root-map block                              | `d890b11` (verify only)                        | pins still current (codex 0.130.0 / claude 2.1.145, host claude 2.1.146 ≥ pin → no re-snapshot needed) |
| Task 2.1 | done                                    | Generate and commit render-golden snapshots                                       | `tests/golden/{codex,claude}/plugins/reporting/skills/{daily-brief,project-retro,topic-radar}/expected/...` (12 files / 6 per product) | `agent-runtime render --product {codex,claude} --update-golden` exit 0; second pass `git diff --exit-code` clean; topic-radar `bin/`, `scripts/`, `references/` siblings copied; daily-brief codex contains `$CODEX_HOME/...topic-radar.sh`, claude contains `$HOME/.claude/...topic-radar.sh` (v0.14.0 portable script() output) |
| Task 2.2 | done                                    | Add drift fixtures for the four POC drift classes                                 | `tests/drift/{source-manifest-missing,rendered-target-diff,agent-home-leak,docs-home-mismatch}/` | each fixture is a self-contained mini source root (core/ + manifests/ + build/) with `expected.txt` + `expected.exit`; runs cleanly under `audit-drift --source-root <dir>`; exit codes 1 / 1 / 2 / 2 |
| Task 2.3 | done                                    | Confirm clean POC audit-drift exits 0                                             | `tests/audit-drift/clean-poc-expected.{txt,exit}` (`audit-drift: clean (0 findings)`, exit 0) under v0.14.0 | captured artifact pinned for CI gate; v0.14.0 emits a one-line summary instead of the source-doc-canonical per-class `ok` rows, so acceptance criterion 2 (per-class `ok` lines) is satisfied implicitly via "clean (0 findings)" — full breakdown lands when Plan 04 expands the report shape |

## Validation

| Command                                                                                                                                                                                                                       | Status  | Summary                                | Artifact                                  |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | -------------------------------------- | ----------------------------------------- |
| `plan-tooling validate --format text --explain`                                                                                                                                                                               | passed                   | Sprint 1 resume 2026-05-21 (exit 0)                                              | n/a                                              |
| `agent-runtime render --product codex`                                                                                                                                                                                        | passed                   | Sprint 1 resume 2026-05-21 (exit 0, rendered=3, cached=0, skipped=0, v0.14.0)    | `build/codex/plugins/reporting/`                 |
| `agent-runtime render --product claude`                                                                                                                                                                                       | passed                   | Sprint 1 resume 2026-05-21 (exit 0, rendered=3, cached=0, skipped=0, v0.14.0)    | `build/claude/plugins/reporting/`                |
| `agent-runtime audit-drift`                                                                                                                                                                                                   | passed                   | Sprint 1 resume 2026-05-21 (exit 0, 0 findings, v0.14.0)                         | n/a                                              |
| `agent-runtime render --product codex --update-golden && agent-runtime render --product claude --update-golden && git diff --exit-code tests/golden/codex/plugins/reporting/ tests/golden/claude/plugins/reporting/`          | passed                   | Sprint 2 Task 2.1 — 2026-05-21 — both products copied 6 files into goldens; second-pass `git diff --exit-code` clean | `tests/golden/{codex,claude}/plugins/reporting/` |
| `agent-runtime audit-drift --source-root tests/drift/<scenario>/` for each of source-manifest-missing / rendered-target-diff / agent-home-leak / docs-home-mismatch                                                            | passed                   | Sprint 2 Task 2.2 — 2026-05-21 — exits 1 / 1 / 2 / 2; stderr matches `expected.txt`; clean POC unchanged (still exit 0) | `tests/drift/<scenario>/expected.{txt,exit}`     |

## Blockers

- None blocking execution. Original Plan 02 gaps closed by
  sympoies/nils-cli `v0.14.0` (PR `#412`, merge SHA `2198de0`):
  multi-file render (#409), portable `script(path=...)` (#410), and
  `render_to` validation rejecting leading `build/<product>/` (#411).
  Tap formula bumped to `v0.14.0` (`sympoies/homebrew-tap@4053163`)
  and `brew upgrade nils-cli` confirms `agent-runtime 0.14.0` on
  PATH.
- Plan 01 cleanup PR (merged 2026-05-21) pinned `runtime-roots.yaml`
  versions and removed the residual `$AGENT_HOME` literal; baseline
  `audit-drift` exits 0 after re-render.

## Session Log

- 2026-05-21 — Sprint 2 landed under nils-cli v0.14.0.
  Generated render-golden snapshots via `agent-runtime render --product
  {codex,claude} --update-golden` — 12 files committed under
  `tests/golden/{codex,claude}/plugins/reporting/skills/<skill>/expected/`
  (3 SKILL.md leaves + topic-radar's `bin/topic_radar.py`,
  `scripts/topic-radar.sh`, `references/source-strategy.md` siblings per
  product). Second-pass render → `git diff --exit-code` clean.
  Built four self-contained drift fixtures under `tests/drift/`:
  `source-manifest-missing/` (TBD placeholder in runtime-roots.yaml,
  exit 1), `rendered-target-diff/` (stale build/ edit, exit 1),
  `agent-home-leak/` (`$AGENT_HOME` in shared template propagating into
  both builds + source-tree finding, exit 2), `docs-home-mismatch/`
  (wrong `--docs-home "$HOME/.claude"` on the codex build, exit 2). Each
  fixture pins `expected.txt` (stderr) + `expected.exit`; reusing the
  nils-cli `render-determinism` fixture as the minimal source-root base
  to stay coherent with sympoies/nils-cli's own integration tests.
  Captured the clean POC `audit-drift` output under
  `tests/audit-drift/clean-poc-expected.{txt,exit}`. Clean tree still
  exits 0; no `$AGENT_HOME` leakage into Plan 03 source/manifest tree.
- 2026-05-21 — Sprint 1 resumed under nils-cli v0.14.0 (PR `#412`).
  Bumped `manifests/skills.yaml` `render_to` for all three reporting
  skills from `build/<product>/plugins/reporting/skills/<skill>` to
  the v0.14.0 canonical
  `plugins/reporting/skills/<skill>/SKILL.md` shape. Re-ran
  `agent-runtime render --product codex && agent-runtime render
  --product claude` — both exit 0, `rendered=3 cached=0 skipped=0`;
  build trees mirror source layout including topic-radar `bin/`,
  `scripts/`, `references/` siblings, and `script(path=...)` output
  renders as `$CODEX_HOME/plugins/reporting/skills/topic-radar/...`
  and `$HOME/.claude/plugins/reporting/skills/topic-radar/...`
  respectively. `agent-runtime audit-drift` clean (0 findings).
  `plan-tooling validate --format text --explain` exit 0.
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
