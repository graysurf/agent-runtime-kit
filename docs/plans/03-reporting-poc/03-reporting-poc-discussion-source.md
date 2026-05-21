# Plan 03 — Reporting Domain POC (Source)

- Status: open, ready for implementation planning
- Date: 2026-05-20
- Source: `docs/source/inventory-target-architecture.md` — Phase 2 bullet
  list (lines 1689–1694), `## Proof Of Concept Scope` /
  `### Simulated Reporting POC` (lines 1471–1643), `## Manifest Layer`
  (lines 493–580), `## Portable Skill References` (lines 674–717),
  `## Runtime Root Model` (lines 583–672), `## Testing And Validation`
  test layers 1–5 (lines 1411–1450), and Resolved Decision #10
  (`### Codex Activation Surface (Reality Check)`, lines 442–498).
- Scope: end-to-end Phase 2 POC for one low-risk domain (`reporting`):
  portable canonical source bodies for `daily-brief`, `project-retro`,
  `topic-radar`; product adapter metadata for Codex and Claude; the
  three manifest slices plus root map; render-golden snapshots; drift
  audit fixtures; deterministic dry-run install snapshots. **No live
  runtime home is mutated by this plan.**

## Execution

- Recommended plan:
  docs/plans/03-reporting-poc/03-reporting-poc-plan.md
- Recommended execution state:
  docs/plans/03-reporting-poc/03-reporting-poc-execution-state.md

## Purpose

Phase 2 of the multi-repo agent runtime kit migration. This plan
migrates the first domain end-to-end through every layer that Plan 01
froze (manifests, schemas, drift allowlist, CLI stub) and Plan 02
implemented (`agent-runtime render` + minimal `audit-drift`). It is
deliberately scoped to one small domain (three skills, one plugin) so
the migration tooling is exercised against real content before the
remaining seven domains land in Plan 05.

Three rules constrain the work:

1. **Source must be portable.** Skill bodies under `core/skills/reporting/`
   must use the Tera helpers `{{ skill_ref(...) }}`, `{{ script(...) }}`,
   and `{{ state_out(...) }}`. No `$AGENT_HOME` reference may survive
   the migration. The rendered Codex / Claude snippets in the source
   doc (lines 1577–1603) are the acceptance contract.
2. **Codex adapter metadata is local-only.** Per Resolved Decision #10,
   `targets/codex/plugins/reporting/.codex-plugin/plugin.json` exists
   for source-organisation and local schema validation only. Codex
   never reads it. PR review must not flag this file as a "missing
   marketplace entry".
3. **No live-home mutation.** Sprints 3 and 4 stop at golden snapshots,
   drift fixtures, and dry-run install plans. The apply path lands in
   Plan 04.

## Current Judgment

- The current Claude plugin (`$HOME/.config/claude/plugins/reporting/`)
  already ships `daily-brief` and `project-retro` with usable bodies.
  `topic-radar` lives under `$HOME/.config/agent-kit/skills/tools/
  market-research/topic-radar/` in agent-kit. Sprint 1 reads from those
  paths and rewrites the bodies into the portable canonical form;
  Sprint 2 wires the cross-product domain shift through `path_override`
  (see open question below).
- `topic-radar/scripts/topic-radar.sh` is migrated as-is into the new
  canonical layout. The "rewrite to a nils-cli binary" path is deferred
  to the extraction backlog (see open question below).
- `min_version` / `recommended_version` baselines for
  `manifests/runtime-roots.yaml` are pinned from the development host
  on the planning date: `codex --version` reports `codex-cli 0.130.0`,
  `claude --version` reports `2.1.145 (Claude Code)`. The
  `min_version_effective_from` date is set to `2026-06-03` (14 days
  after the Phase 2 PR merge target on `2026-05-20`) so existing hosts
  have a runway before the floor starts blocking.
- `required_clis` floors are pinned to the `0.1.0` nils-cli release
  cut by Phase 1.5 (the release that ships the real `agent-runtime
  render` body and the four Tera helpers); no `<TBD>` placeholders are
  permitted in Plan 03 manifests.
- Sprint 3 commits the golden snapshots produced by `agent-runtime
  render --update-golden`. The diff is reviewed before commit per the
  Test Layer 2 contract in the source doc.
- Sprint 3 covers four drift classes: `source-manifest`,
  `rendered-target` diff, `$AGENT_HOME` leak, `docs-home`. The full
  five-class set (`missing` / `stale` / `extra` /
  `intentional-difference` / `unsafe`) lands with the full
  `audit-drift` body in Plan 05.
- Sprint 4 pins `agent-runtime install --dry-run` output for both
  products. The expected shape is the "Dry-run install output" example
  in the source doc (lines 1610–1628).

## Source References

- `docs/source/inventory-target-architecture.md`
  - `## Proof Of Concept Scope` + `### Simulated Reporting POC`
    (lines 1471–1643) — POC deliverables, portable source example,
    rendered Codex / Claude examples, dry-run install example, drift
    audit example.
  - `## Manifest Layer` (lines 493–580) — schema_version rule, skill
    naming convention, cross-product domain mapping via
    `path_override`, skill naming collision policy.
  - `## Portable Skill References` (lines 674–717) — Tera helper
    contract for `{{ script(...) }}` / `{{ skill_ref(...) }}` /
    `{{ state_out(...) }}`.
  - `## Runtime Root Model` (lines 583–672) — `live_home`,
    `docs_home`, `state_home`, `plugin_root` per product; XDG fallback;
    `CLAUDE_KIT_STATE_HOME` back-compat.
  - `## Testing And Validation` test layers 1–5 (lines 1411–1450) —
    manifest schema validation, render golden, hook adapter contract
    tests (out of scope for this domain), install dry-run snapshots,
    drift audit fixtures.
  - `### Codex Activation Surface (Reality Check)` (lines 442–498) +
    Resolved Decision #10 — `.codex-plugin/plugin.json` is local-only.
  - Root-map example block (lines 1221–1244) — verbatim shape for
    `manifests/runtime-roots.yaml`.

## Findings

| Priority | ID | Issue | Evidence | Fix Location | Acceptance |
| --- | --- | --- | --- | --- | --- |
| high | R1 | No portable canonical reporting bodies exist; current sources still bake `$AGENT_HOME` references and product-specific paths. | `$HOME/.config/agent-kit/skills/workflows/reporting/daily-brief/SKILL.md`; `$HOME/.config/agent-kit/skills/workflows/reporting/project-retro/SKILL.md`; `$HOME/.config/agent-kit/skills/tools/market-research/topic-radar/SKILL.md`; `$HOME/.config/claude/plugins/reporting/skills/daily-brief/SKILL.md`; `$HOME/.config/claude/plugins/reporting/skills/project-retro/SKILL.md`. | `core/skills/reporting/daily-brief/SKILL.md`, `core/skills/reporting/project-retro/SKILL.md`, `core/skills/reporting/topic-radar/SKILL.md`, `core/skills/reporting/topic-radar/scripts/topic-radar.sh`. | Rendered Codex/Claude outputs match the snippets in the source doc lines 1577–1603 byte-exact. |
| high | R2 | No Codex or Claude adapter metadata for reporting; render cannot fan source out into product-specific surfaces. | `docs/source/inventory-target-architecture.md` lines 1518–1524. | `targets/codex/plugins/reporting/.codex-plugin/plugin.json`, `targets/claude/plugins/reporting/.claude-plugin/plugin.json`. | Codex metadata validates against the local schema only (Resolved Decision #10); Claude metadata matches upstream Claude plugin schema. |
| high | R3 | `manifests/skills.yaml`, `plugins.yaml`, `product-capabilities.yaml`, `runtime-roots.yaml` carry no domain entries yet; render and drift cannot run. | Plan 01 deliverables; example slice in source doc lines 1520–1554. | `manifests/skills.yaml`, `manifests/plugins.yaml`, `manifests/product-capabilities.yaml`, `manifests/runtime-roots.yaml`. | All four manifests carry the reporting entries with concrete `required_clis: ">=0.1.0"` floors (no `<TBD>`); `runtime-roots.yaml` pins the development host's product versions; `schema_version: 1` everywhere. |
| high | R4 | No render-golden snapshots exist for the reporting domain; render determinism is not enforced. | `docs/source/inventory-target-architecture.md` test layer 2 (lines 1423–1428). | `tests/golden/codex/reporting/*/expected/`, `tests/golden/claude/reporting/*/expected/`. | `agent-runtime render` produces zero diff against committed snapshots on a clean tree. |
| medium | R5 | No drift fixtures exercise the four POC drift classes against the reporting tree. | `docs/source/inventory-target-architecture.md` test layer 5 (lines 1436–1439). | `tests/drift/<scenario>/` for source-manifest / rendered-target diff / `$AGENT_HOME` leak / docs-home. | Each fixture pins both report text and exit code; `audit-drift` exits 0 on the clean POC. |
| medium | R6 | No dry-run install snapshot pins the deterministic plan shape; install scope expansion would slip through review. | `docs/source/inventory-target-architecture.md` test layer 4 (lines 1432–1435) and dry-run example (lines 1610–1628). | `tests/install/codex/expected.txt`, `tests/install/claude/expected.txt`. | Dry-run plans touch only `AGENTS.md` (Codex), the managed `config.toml` block, `settings.json` (Claude), and link-map files; never auth / history / sessions / cache. |

## Ownership Boundary

- Runtime: `agent-runtime render` and `agent-runtime audit-drift`
  bodies live in `sympoies/nils-cli` and ship via the tap (Plan 02).
  Plan 03 only consumes those subcommands.
- Source: `core/skills/reporting/`, `targets/codex/plugins/reporting/`,
  `targets/claude/plugins/reporting/` — all in this repo.
- Manifests: `manifests/skills.yaml`, `manifests/plugins.yaml`,
  `manifests/product-capabilities.yaml`,
  `manifests/runtime-roots.yaml` — Phase 1 seeded the files; Phase 2
  fills in the reporting entries.
- Tests: `tests/golden/`, `tests/drift/`, `tests/install/` — all
  pinned in-tree; CI gates added in Plan 02 enforce them.

## Backlog / Next Fixes

1. Plan 04 — Apply mode lands the `agent-runtime install --apply`
   path on top of the dry-run snapshots pinned here.
2. Plan 05 — Migrate the remaining seven domains using the same
   four-sprint shape established here.
3. Migrate `topic-radar.sh` to a nils-cli binary (extraction backlog;
   see open question below).
4. Add the remaining drift classes (`missing` / `stale` / `extra` /
   `intentional-difference` / `unsafe`) once Plan 05 lands the full
   `audit-drift` body.

## Retention Intent

- This source doc is execution coordination — delete after plan
  completes.
- The canonical bodies under `core/skills/reporting/`, the manifests,
  the render-golden snapshots, the drift fixtures, and the dry-run
  install snapshots stay as durable contract.

## Validation Gate

- `plan-tooling validate --file docs/plans/03-reporting-poc/03-reporting-poc-plan.md --format text --explain`
- `agent-runtime render --check`
- `agent-runtime render --update-golden && git diff --exit-code tests/golden/`
- `agent-runtime audit-drift --format text`
- `agent-runtime install --product codex --dry-run` (diff against `tests/install/codex/expected.txt`)
- `agent-runtime install --product claude --dry-run` (diff against `tests/install/claude/expected.txt`)

## Do Not Do

- Do not mutate any live runtime home. No write under `$HOME/.codex/`,
  `$HOME/.claude/`, `$CODEX_HOME`, or any `CLAUDE_KIT_STATE_HOME`
  target lands in this plan. Apply mode is Plan 04.
- Do not emit `$AGENT_HOME` in any rendered output. Drift audit treats
  every leak as an error.
- Do not invent a Codex marketplace step. Resolved Decision #10 is
  binding — `.codex-plugin/plugin.json` is local-only.
- Do not leave any `required_clis` value as `<TBD>`. Phase 2 pins
  concrete `>=0.1.0` floors (or higher) against the Phase 1.5 nils-cli
  release.
- Do not rewrite `topic-radar.sh` into a nils-cli binary in this plan;
  carry it as-is and defer the extraction to the backlog.

## Open Questions

- ~~Domain-mapping decision for `topic-radar`~~ — **Resolved
  2026-05-21 (reviewer: terry, Option A)**: adopt
  `docs/source/inventory-target-architecture.md` L555–566 verbatim,
  declaring both
  `products.codex.path_override: skills/tools/market-research/topic-radar`
  and
  `products.claude.path_override: plugins/reporting/skills/topic-radar`
  on `reporting.topic-radar`. Rationale: matches the canonical source
  doc example byte-for-byte, preserves current invocation paths on
  both products, pins the override explicitly on both sides so drift
  audit does not depend on Claude's natural-derivation rule.
  Cross-product domain unification is deferred to Plan 05 (Domain
  Migration Sweep) where it has review budget and migration PR
  templates.
- ~~Whether to capture the rendered `topic-radar.sh` script as-is or
  migrate it to a nils-cli binary~~ — **Resolved 2026-05-21
  (reviewer: terry)**: ship `topic-radar.sh` as-is in Plan 03; do not
  extract to a nils-cli binary yet. Rationale: `topic-radar` is still
  actively gaining features and its usage shape is not yet stable;
  extracting now would lock in an interface that has to be re-cut
  shortly. The extraction backlog entry stays open for revisit after
  the skill stabilises.
