# Discussion Source: Codex plugin/marketplace adoption

## Status
- Date: 2026-06-20
- Type: discussion-to-implementation-doc (source snapshot for the plan tracking issue)
- Predecessor: PR #434 (merged) — corrected the stale "Codex has no plugin loader / marketplace" docs but deliberately left the capability model on its pre-2026 baseline.

## Execution

- Recommended plan: docs/plans/2026-06-20-codex-plugin-marketplace-adoption/2026-06-20-codex-plugin-marketplace-adoption-plan.md
- Recommended execution state: docs/plans/2026-06-20-codex-plugin-marketplace-adoption/2026-06-20-codex-plugin-marketplace-adoption-execution-state.md

## Context

`agent-runtime-kit` renders one skill source (`core/skills/<domain>/<skill>/SKILL.md.tera`)
into both Codex and Claude. The Claude side is fully adopted as a plugin +
marketplace (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`,
activated by `sync-runtime-surfaces.sh` via `claude plugin marketplace add`).
The Codex side renders a parallel `.codex-plugin/plugin.json` tree but treats it
as **audit-only**: Codex skills are actually discovered through the flat
`$CODEX_HOME/skills/<domain>/<skill>/` root (surface 15), and there is no Codex
marketplace.

That asymmetry was correct when the harness-shape docs were written
(2026-05-31), because Codex had no plugin loader then. It is no longer correct:
Codex shipped a real plugin loader + marketplace in 2026. PR #434 fixed the
false statements but explicitly deferred the capability-model change and the
adoption work to this plan.

## Problem

runtime-kit does not use Codex's now-available plugin/marketplace surface, and
the Codex `.codex-plugin/plugin.json` it emits does not match Codex's current
loader schema. This plan adopts the Codex surface so both products activate
skills the same way.

## Spike findings (2026-06-20)

- **[A] Local `codex-cli 0.141.0`** ships `codex plugin {add,list,marketplace,remove}`.
  `codex plugin marketplace add <SOURCE>` accepts a local path, `owner/repo[@ref]`,
  HTTPS Git URL, or SSH Git URL (with `--ref`, `--sparse`, `--json`) — a near-exact
  mirror of `claude plugin marketplace add`, so the activation step is a direct
  analogue of the existing Claude block in `sync-runtime-surfaces.sh`.
- **[W] Codex `plugin.json` schema** (developers.openai.com/codex/plugins/build):
  `name` / `version` / `description` / `skills: "./skills/"` / `mcpServers` /
  `apps` / `hooks` / `interface{}`. The repo currently emits `skills: [{id, source}]`
  (an audit array) — a real drift that must be reconciled before Codex can load it.
- **[W] Codex marketplace** canonical path is `.agents/plugins/marketplace.json`;
  Codex also reads `.claude-plugin/marketplace.json` as a **legacy** source —
  a cheap interop option worth evaluating against rendering a native Codex marketplace.
- **[F] `manifests/product-capabilities.yaml`** encodes the pre-2026 baseline
  (`marketplace_concept: false`, `loaded_at_runtime: false`) and its own top
  comment anticipated this exact trigger: "the capability matrix changes only
  when a product itself changes (e.g. Codex publishes a real plugin loader)."

## Decisions to confirm in execution

1. **Reverse Resolved Decision #10** ("Codex `.codex-plugin/plugin.json` is
   audit-only; Codex does not load it") — required before flipping the
   capability flags. This is the Task 1.1 gate.
2. **Marketplace path**: render a native `.agents/plugins/marketplace.json`, or
   reuse the legacy `.claude-plugin/marketplace.json` interop path (Task 2.1).

## Scope summary

In scope: Codex `plugin.json` schema alignment, `codex-plugin.schema.json`,
Codex marketplace render + `sync-runtime-surfaces.sh` activation, capability-model
flip + matrix/harness-shape promotion, acceptance lanes. Out of scope: the Claude
side, the shared `SKILL.md` format, and removing the flat skills root before the
plugin path is proven live.

## References
- PR #434: https://github.com/graysurf/agent-runtime-kit/pull/434
- Codex plugin authoring: https://developers.openai.com/codex/plugins/build
- Codex changelog: https://developers.openai.com/codex/changelog
- `docs/source/harness-shape-codex.md` surfaces 3-5; `manifests/surfaces.yaml`; `manifests/product-capabilities.yaml`
