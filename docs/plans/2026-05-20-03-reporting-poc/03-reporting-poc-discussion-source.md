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
  docs/plans/2026-05-20-03-reporting-poc/03-reporting-poc-plan.md
- Recommended execution state:
  docs/plans/2026-05-20-03-reporting-poc/03-reporting-poc-execution-state.md

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
- `required_clis` floors are pinned to the `v0.13.0` nils-cli release
  cut by Phase 1.5 (the release that ships the real `agent-runtime
  render` body and the four Tera helpers); no placeholder strings are
  permitted in Plan 03 manifests.
- Sprint 2 (formerly Sprint 3 before the 2026-05-21 rev) commits the
  golden snapshots produced by `agent-runtime render --product <p>
  --update-golden` (per-product; no `--domain` filter in v0.13.0).
  The diff is reviewed before commit per the Test Layer 2 contract in
  the source doc; only the reporting subdirectories are added to the
  commit.
- Sprint 2 covers four drift classes: `source-manifest`,
  `rendered-target` diff, `$AGENT_HOME` leak, `docs-home`. The full
  five-class set (`missing` / `stale` / `extra` /
  `intentional-difference` / `unsafe`) lands with the full
  `audit-drift` body in Plan 04 Sprint 4.
- The original Sprint 4 ("Pin `agent-runtime install --dry-run` output
  for both products") was deferred to Plan 04 Sprint 5 on 2026-05-21:
  v0.13.0 ships no `install --dry-run` surface (Plan 02 listed
  `install` body as out-of-scope, "later phases"), and Plan 04
  already plans `tests/sandbox/<product>/expected-skills.txt` pins
  through the same surface. The original expected shape (source doc
  lines 1610–1628) is preserved verbatim in the Plan 04 reference.

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
| high | R3 | `manifests/skills.yaml`, `plugins.yaml`, `product-capabilities.yaml`, `runtime-roots.yaml` carry no domain entries yet; render and drift cannot run. | Plan 01 deliverables; example slice in source doc lines 1520–1554. | `manifests/skills.yaml`, `manifests/plugins.yaml`, `manifests/product-capabilities.yaml`, `manifests/runtime-roots.yaml`. | All four manifests carry the reporting entries with concrete `required_clis: ">=0.13.0"` floors (no placeholder strings); `runtime-roots.yaml` carries pinned version-floor values landed by the Plan 01 cleanup PR; `schema_version: 1` everywhere. |
| high | R4 | No render-golden snapshots exist for the reporting domain; render determinism is not enforced. | `docs/source/inventory-target-architecture.md` test layer 2 (lines 1423–1428). | `tests/golden/codex/plugins/reporting/*/expected/`, `tests/golden/claude/plugins/reporting/*/expected/`. | `agent-runtime render --product <p>` produces zero diff against committed snapshots on a clean tree. |
| medium | R5 | No drift fixtures exercise the four POC drift classes against the reporting tree. | `docs/source/inventory-target-architecture.md` test layer 5 (lines 1436–1439). | `tests/drift/<scenario>/` for source-manifest / rendered-target diff / `$AGENT_HOME` leak / docs-home. | Each fixture is a self-contained mini source root invoked through `agent-runtime audit-drift --source-root <fixture>` (v0.13.0 has no `--fixture` flag); pins both report text and exit code; `audit-drift` exits 0 on the clean POC. |
| medium | R6 | No dry-run install snapshot pins the deterministic plan shape; install scope expansion would slip through review. | `docs/source/inventory-target-architecture.md` test layer 4 (lines 1432–1435) and dry-run example (lines 1610–1628). | **Deferred to Plan 04 Sprint 5** (`tests/sandbox/<product>/expected-skills.txt`). `agent-runtime install --dry-run` does not exist in v0.13.0; Plan 02 listed install body as out-of-scope ("later phases"). Plan 04 Sprint 1 lands the install body and Plan 04 Sprint 5 pins the snapshots through the same surface. | Dry-run plans touch only `AGENTS.md` (Codex), the managed `config.toml` block, `settings.json` (Claude), and link-map files; never auth / history / sessions / cache. Acceptance now owned by Plan 04. |

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
- Tests: `tests/golden/` and `tests/drift/` are pinned in-tree by
  this plan (Sprint 2). Sandbox install skill-list pins under
  `tests/sandbox/<product>/expected-skills.txt` are deferred to Plan 04
  because v0.13.0 has no `agent-runtime install --dry-run` surface. CI gates
  added in Plan 02 enforce the in-tree artifacts.

## Backlog / Next Fixes

1. Plan 04 Sprint 1 — Lands the `agent-runtime install` body
   (render → link → managed-block sync → backup) with `--dry-run` /
   `--apply` / `--live-home` flags. Plan 03's original Sprint 4
   (dry-run install snapshots) is absorbed into Plan 04 Sprint 5
   where the snapshots become `tests/sandbox/<product>/expected-skills.txt`
   pins driven by the new install body.
2. Plan 04 Sprint 4 — Extends `audit-drift` with the composite
   `unsafe` score plus `intentional-difference` and `extra` finding
   classes and lands the `drift-audit.allow.yaml` allowlist
   mechanism for one-tier demotion of legitimate but
   audit-trigger-worthy patterns.
3. Plan 05 — Migrate the remaining seven domains using the
   two-sprint shape established here (after Plan 04 lands the full
   install / audit-drift surface).
4. Migrate `topic-radar.sh` to a nils-cli binary (extraction backlog;
   resolved on 2026-05-21 to defer until the skill stabilises — see
   open questions below).
5. nils-cli quality-of-life follow-ups discovered during Plan 03 rev
   (track separately, non-blocking for Plan 03 execution):
   - `audit-drift` false-positive on `<TBD>` literal strings inside
     YAML comments — the lexer should skip `#`-prefixed lines.
   - Consider `agent-runtime render --check` (re-render into
     `tempdir/` and diff against `build/`) as a CI-friendly gate;
     today consumers compose `render` + `git diff --exit-code build/`.
   - Consider `agent-runtime audit-drift --format json` for
     CI machine-parseable output once Plan 04 expands the class
     surface.

## Retention Intent

- This source doc is execution coordination — delete after plan
  completes.
- The canonical bodies under `core/skills/reporting/`, the manifests,
  the render-golden snapshots, and the drift fixtures stay as durable
  contract. (The dry-run install snapshots that were originally part
  of this durable surface are now owned by Plan 04 Sprint 5.)

## Validation Gate

- `plan-tooling validate --file docs/plans/2026-05-20-03-reporting-poc/03-reporting-poc-plan.md --format text --explain` (exit 0)
- `agent-runtime render --product codex` (exit 0; populates `build/codex/plugins/reporting/`)
- `agent-runtime render --product claude` (exit 0; populates `build/claude/plugins/reporting/`)
- `agent-runtime render --product codex --update-golden && agent-runtime render --product claude --update-golden && git diff --exit-code tests/golden/codex/plugins/reporting/ tests/golden/claude/plugins/reporting/` (Sprint 2 gate)
- `agent-runtime audit-drift` (exit 0; default text output — v0.13.0 has no `--format` flag)
- Each Sprint 2 drift fixture: `agent-runtime audit-drift --source-root tests/drift/<scenario>/` produces a report that diffs cleanly against `tests/drift/<scenario>/expected.txt` and exits with the value in `tests/drift/<scenario>/expected.exit`.
- (Dry-run install snapshot gate moved to Plan 04 Sprint 5: `bash scripts/ci/sandbox-install-rehearsal.sh`.)

## Do Not Do

- Do not mutate any live runtime home. No write under `$HOME/.codex/`,
  `$HOME/.claude/`, `$CODEX_HOME`, or any `CLAUDE_KIT_STATE_HOME`
  target lands in this plan. Apply mode is Plan 04.
- Do not emit `$AGENT_HOME` in any rendered output. Drift audit treats
  every leak as an error.
- Do not invent a Codex marketplace step. Resolved Decision #10 is
  binding — `.codex-plugin/plugin.json` is local-only.
- Do not leave any `required_clis` value as a placeholder string.
  Phase 2 pins concrete `>=0.13.0` floors (or higher) against the
  Phase 1.5 nils-cli release.
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
- ~~CLI surface alignment between v0.13.0 and Plan 03 validation
  gates~~ — **Resolved 2026-05-21 (reviewer: terry)**: rev Plan 03
  to the actual v0.13.0 `agent-runtime` surface (no `--check` /
  `--domain` / `--skill` / `--format` / `--fixture` flags) — Plan 03
  originally pinned validation gates against an aspirational CLI
  that neither the source doc nor Plan 02 plan ever committed to;
  Plan 02 plan explicitly listed `install` body and the surface
  refinements as out-of-scope. Specific consequences: (1) merge
  Sprint 1 + Sprint 2 into one PR because render byte-exact
  validation requires manifests to be present (no `--domain` /
  `--skill` filter exists); (2) move Sprint 4 (dry-run install
  snapshots) entirely to Plan 04 Sprint 5 alongside the install body
  that produces them; (3) drift fixtures invoke
  `audit-drift --source-root <fixture>` against self-contained mini
  source roots; (4) golden snapshots come from
  `render --product <p> --update-golden` and commit only the
  reporting subdirs. The Plan 01 cleanup PR (merged 2026-05-21)
  pinned `runtime-roots.yaml` versions and removed the residual
  `$AGENT_HOME` literal in `core/policies/cli-tools.md` so the
  baseline `audit-drift` exits 0.
