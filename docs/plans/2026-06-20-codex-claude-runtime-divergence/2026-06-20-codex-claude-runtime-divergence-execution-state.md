# Execution State: Codex / Claude runtime divergence

## Execution State

- Source document: docs/plans/2026-06-20-codex-claude-runtime-divergence/2026-06-20-codex-claude-runtime-divergence-plan.md
- Tracking issue: not yet opened — run `create-plan-tracking-issue` at the start of execution
- Current sprint: Sprint 1 (not started)
- Status: planned; awaiting execution
- Branch: not yet created — use `feat/codex-claude-runtime-divergence`
- Last updated: 2026-06-20

## Task Ledger

| ID | Title | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | R1 — per-product home-prompt render target | todo | — | upstream nils-cli; render view must put `product` in scope |
| 1.2 | C1 — `product` field on catalog parser/model | todo | — | upstream; enum-validate names so a typo hard-errors |
| 1.3 | C1 — `preflight --product` + resolver filter + preflight.v2 | todo | — | upstream; filter docs + validations in one place; unset = include-all |
| 1.4 | Upstream acceptance (goldens/schema/tests) | todo | — | local debug binary; capture test-first evidence |
| 2.1 | Land + release nils-cli + tap + brew upgrade | todo | — | release flow; upgrade Mac + g14 |
| 2.2 | Pin bump + required_clis floors | todo | — | via `meta:nils-cli-bump`; version-alignment must report block=0 |
| 3.1 | Render per-product `AGENT_HOME` + retarget `setup.sh` | todo | — | cutover from raw symlink; update surfaces rows 1 + 17 |
| 3.2 | Remove Codex-only prose from shared body + Claude render | todo | — | neutral fallback stays valid safe-fallback |
| 3.3 | SUPPORT_MATRIX golden + audit-drift + harness-shape | todo | — | preserve anchor headings + source_manifest lockstep |
| 4.1 | Hook `--product` forwarding + validation parity | todo | — | cache key includes product; capability-probe `preflight --help` |
| 4.2 | `product=codex` catalog doc (parity backstop) | todo | — | demonstrates C1; audit-unset still validates it |
| 4.3 | Broad-sentinel leakage lint (post-#436 scope) | todo | — | include gated Codex plugin/marketplace artifacts; negative self-test |
| 4.4 | Full acceptance + runtime-smoke home probe | todo | — | `scripts/ci/all.sh` + `tests/hooks/run.sh` green |

## Validation Log

- 2026-06-20: bundle authored from the `docs/discussions` evaluation capture and graduated to this L2 bundle. #436 drift folded in. No execution yet.

## Session Notes

- 2026-06-20: graduated from `docs/discussions/2026-06-20-codex-claude-runtime-divergence.md` to this bundle after the four decisions (D1 per-product render home, D2 broad-sentinel lint, D3 preflight v2, D4 build C1 now) were resolved.
- 2026-06-20: #436 (`f10e12b`, Codex plugin/marketplace adoption) analyzed for drift. Key facts for the executor: the home prompt is still a raw symlink wired by `scripts/setup.sh` (R1 owns the cutover, surfaces rows 1 + 17); agent-docs / `AGENT_DOCS.toml` / the hooks are untouched by #436 (C1 is greenfield there); the leakage lint must enumerate the post-#436 gated Codex plugin/marketplace artifacts because `config_activation` is stale; and #436 forced no pin bump, so this plan's bump is owned here.
- 2026-06-20: gate-first sequencing — ship R1 + C1 in `sympoies/nils-cli`, release and pin-bump, then consume in this repo (home cutover, then hook wiring + lint + acceptance). Reuse #436's `--product` + feature-gate and capability-flag conventions.
