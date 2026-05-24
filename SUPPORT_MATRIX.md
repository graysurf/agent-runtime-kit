# SUPPORT_MATRIX

Unified human-readable view of which Codex and Claude harness primitives
`agent-runtime-kit` ships into today, by what mechanism, and at what
version floor. Manifests (`manifests/*.yaml`, `docs/source/nils-cli-surface.md`,
`DEVELOPMENT.md`) remain the source of truth — this file is a derived
view kept in sync with them, not a parsed gate.

For per-product narrative detail with file:line citations, see:

- `docs/source/harness-shape-codex.md`
- `docs/source/harness-shape-claude.md`
- `docs/source/inventory-target-architecture.md`

For Codex-only asymmetries (no plugin loader at runtime, no marketplace,
no `settings.json`-equivalent), see Resolved Decision #10 in
`docs/source/inventory-target-architecture.md:2049-2073`.

## How this matrix is maintained

- Rows are hand-authored in this PR from the two harness-shape docs;
  the plan in `docs/plans/support-matrix/support-matrix-plan.md`
  records the agreed long-format normalized schema and the open
  question on whether to promote to render-from-manifests later.
- When a new primitive lands in either shape doc, add a `surface` ×
  `product` row pair here in the same PR. `runtime-roots.yaml` bumps of
  `min_version` / `min_version_effective_from` and nils-cli surface
  snapshot bumps both require refreshing the matrix; the reopen
  triggers in the plan closeout describe this.
- This matrix is not parsed by `doctor`, `audit-drift`, or any CI
  gate. If a future plan adds a `support-matrix` drift class, that
  class should read the manifests behind the matrix, not parse this
  markdown.

## Schema

Each row is one `(surface, product)` pair.

| column | semantics |
|---|---|
| `surface` | Harness primitive identifier; uses the surface name from `harness-shape-{codex,claude}.md`. Surfaces 1-17 enumerate the unified set across both products. |
| `product` | `codex` or `claude`. |
| `state` | One of the five values listed in the state legend below. |
| `mechanism` | One-line summary of how `agent-runtime-kit` ships into the surface (or `—` when `state` is `not-applicable` or `not-shipped`). |
| `source_artifact` | Repo-relative path of the checked-in source, or `—` when nothing is shipped. Multi-path entries are newline-separated inside the cell. |
| `min_product` | Product `min_version` from `manifests/runtime-roots.yaml` when the row is gated by the product harness; `n/a` when the row is `not-applicable` to that product or when no product floor is enforced (repo-local prompts, etc.). |
| `min_nils_cli` | nils-cli surface pin (current snapshot at `docs/source/nils-cli-surface.md`; minimum version a row needs to operate, which may be older than the current snapshot) when arkit relies on `agent-runtime` or a capability binary to ship the row; `n/a` when no nils-cli call is on the path. |
| `ci_acceptance` | CI gate position(s) from `scripts/ci/all.sh` (see `DEVELOPMENT.md:157-178`) that exercise the row, or `—` when no gate covers it. |
| `live_acceptance` | Live-session acceptance protocol (e.g. `codex debug prompt-input`, fresh Claude session) separate from CI; `—` when no live protocol is wired in. |
| `source_manifest` | Pointer to the manifest entry or design doc paragraph the row is derived from. |

### State legend

- `shipped` — concrete source artifact + install path + acceptance lane.
- `partial` — some sub-surfaces present, others reserved but empty.
- `planned-not-shipped` — contract defined in inventory / manifests but
  no source artifact yet.
- `not-shipped` — harness primitive that arkit does not target; not on
  the current roadmap unless added explicitly.
- `not-applicable` — primitive does not exist on this product's harness
  (e.g. `marketplace` on Codex per Resolved Decision #10), or local
  metadata that the product never loads at runtime
  (e.g. `.codex-plugin/plugin.json`). `not-applicable` is distinct
  from `not-shipped`: `not-applicable` means "the product would not
  read this even if arkit shipped it"; `not-shipped` means "arkit
  could ship this but chose not to".

### Product version pins

- Codex: `min_version` **0.130.0**, `recommended_version` 0.130.0,
  `min_version_effective_from` 2026-06-03, probe `codex --version`
  (`manifests/runtime-roots.yaml:17-27`).
- Claude: `min_version` **2.1.145**, `recommended_version` 2.1.145,
  `min_version_effective_from` 2026-06-03, probe `claude --version`
  (`manifests/runtime-roots.yaml:29-38`).
- nils-cli surface: snapshot **v0.20.0**
  (`docs/source/nils-cli-surface.md:1-15`).
- Per-skill nils-cli floors: `manifests/skills.yaml` `required_clis`;
  tighter than the surface-level pin where a specific binary is
  declared (heuristic-inbox, agent-out, etc.).

## Matrix

| surface | product | state | mechanism | source_artifact | min_product | min_nils_cli | ci_acceptance | live_acceptance | source_manifest |
|---|---|---|---|---|---|---|---|---|---|
| 1. home prompt (`AGENTS.md` / `CLAUDE.md`) | codex | shipped | symlink `$CODEX_HOME/AGENTS.md → AGENT_HOME.md` | `AGENT_HOME.md` | 0.130.0 | n/a | — (home-policy cutover only) | live Codex Desktop session | `docs/source/inventory-target-architecture.md:540-544` |
| 1. home prompt (`AGENTS.md` / `CLAUDE.md`) | claude | shipped | symlink `$HOME/.claude/CLAUDE.md → AGENT_HOME.md` | `AGENT_HOME.md` | 2.1.145 | n/a | — (home-policy cutover only) | live Claude session | `docs/source/inventory-target-architecture.md:222-235` |
| 2. project prompt (`./AGENTS.md` / `./CLAUDE.md`) | codex | shipped | repo working tree; `./AGENTS.md` tracked | `AGENTS.md` | 0.130.0 | n/a | — | live Codex session in repo | `AGENTS.md:1-10` |
| 2. project prompt (`./AGENTS.md` / `./CLAUDE.md`) | claude | shipped | repo working tree; `./CLAUDE.md` symlinks to `./AGENTS.md` | `CLAUDE.md` → `AGENTS.md` | 2.1.145 | n/a | — | live Claude session in repo | `AGENTS.md:1-10` |
| 3. plugin manifest (`.codex-plugin` / `.claude-plugin` `plugin.json`) | codex | not-applicable | metadata copy for audit only; Codex has no plugin loader at runtime | `targets/codex/plugins/<plugin>/.codex-plugin/plugin.json` (10 plugins) | n/a | v0.17.5 | gate 5 (audit-drift schema check, local only) | — | `manifests/product-capabilities.yaml:23-30`; `docs/source/inventory-target-architecture.md:562-571` |
| 3. plugin manifest (`.codex-plugin` / `.claude-plugin` `plugin.json`) | claude | shipped | `plugin-manifest-copy` per plugin into `~/.claude/plugins/<p>/.claude-plugin/plugin.json` | `targets/claude/plugins/<plugin>/.claude-plugin/plugin.json` (10 plugins) | 2.1.145 | v0.17.5 | gate 5 (audit-drift), gate 7 (sandbox install rehearsal) | — | `manifests/product-capabilities.yaml:47-54`; `targets/claude/link-map.yaml:15-18` |
| 4. plugin marketplace (`.claude-plugin/marketplace.json`) | codex | not-applicable | Codex has no marketplace API | — | n/a | n/a | — | — | `manifests/product-capabilities.yaml:43`; `docs/source/inventory-target-architecture.md:566-567` |
| 4. plugin marketplace (`.claude-plugin/marketplace.json`) | claude | shipped | `plugin-manifest-copy` of root marketplace.json | `targets/claude/.claude-plugin/marketplace.json` | 2.1.145 | v0.17.5 | gate 5 (audit-drift), gate 7 | — | `manifests/product-capabilities.yaml:59-63`; `targets/claude/link-map.yaml:130-133` |
| 5. plugin-scoped skill discovery (`plugins/<p>/skills/<s>/`) | codex | not-applicable | Codex local skills live under `$CODEX_HOME/skills`, not plugin roots; row 15 is the active root | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:545-554, 569-584` |
| 5. plugin-scoped skill discovery (`plugins/<p>/skills/<s>/`) | claude | shipped | rendered to `build/claude/plugins/<p>/skills/<s>/`, then `symlinked-file` `recursive: true` per plugin | `core/skills/<domain>/<skill>/` → `build/claude/plugins/<p>/skills/<s>/` (10 plugins) | 2.1.145 | v0.20.0 | gate 3 (render), gate 4 (golden), gate 5 (drift), gate 7 (sandbox), gate 8 (runtime-smoke) | — | `manifests/product-capabilities.yaml:62`; `targets/claude/link-map.yaml:20-24` |
| 6. slash command files (`commands/<n>.md`) | codex | not-applicable | Codex has no `commands/` loader in the runtime-kit activation surface | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:540-560` |
| 6. slash command files (`commands/<n>.md`) | claude | shipped | `symlinked-file` of `targets/claude/commands` directory into `~/.claude/commands` (one link, individual command files served from the linked dir) | `targets/claude/commands/new-project-skill.md`, `targets/claude/commands/memory-clean.md` | 2.1.145 | v0.17.5 | gate 7 (sandbox install) | — | `docs/source/inventory-target-architecture.md:228-230`; `targets/claude/link-map.yaml:140-143` |
| 7. subagent definitions (`agents/<n>.md`) | codex | not-applicable | Codex has no file-backed subagent loader; `AGENT_HOME.md` carries delegation modes as policy text (surface 17) | — | n/a | n/a | — | — | `AGENT_HOME.md:37-49`; `docs/source/inventory-target-architecture.md:226-228` |
| 7. subagent definitions (`agents/<n>.md`) | claude | not-shipped | arkit does not ship any `agents/<n>.md` source today | — | n/a | n/a | — | — | `docs/source/harness-shape-claude.md` row 7 |
| 8. hook scripts (`hooks/<n>.*`) | codex | shipped | `core/hooks/shared/` symlinked into `$CODEX_HOME/hooks` | `core/hooks/shared/` | 0.130.0 | v0.17.5 | gate 10 (`tests/hooks/run.sh`) | — | `targets/codex/link-map.yaml:391-394` |
| 8. hook scripts (`hooks/<n>.*`) | claude | partial | `core/hooks/shared/` symlinked into `~/.claude/hooks`; `targets/claude/hooks/` adapter slot reserved but empty | `core/hooks/shared/` | 2.1.145 | v0.17.5 | gate 10 (`tests/hooks/run.sh`) | — | `targets/claude/link-map.yaml:125-128`; Resolved Decision #4 (`docs/source/inventory-target-architecture.md:1978-1981`) |
| 9. hook registration via `settings.json` block | codex | not-applicable | Codex hook activation is TOML-only (surface 16); no `settings.json` equivalent | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:555-558` |
| 9. hook registration via `settings.json` block | claude | planned-not-shipped | managed-block contract defined; no `settings.json.template` artifact in `targets/claude/` yet | — | 2.1.145 | v0.17.5 (for future install) | gate 5 (would cover marker pair when shipped) | — | `manifests/runtime-roots.yaml:34`; `docs/source/inventory-target-architecture.md:460` (target tree), `:1264-1278` (managed-block contract) |
| 10. output styles (`output-styles/<n>.md`) | codex | not-applicable | Codex has no output-styles loader | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:232` |
| 10. output styles (`output-styles/<n>.md`) | claude | not-shipped | arkit does not ship any `output-styles/<n>.md` source today | — | n/a | n/a | — | — | `docs/source/harness-shape-claude.md` row 10 |
| 11. status line (`statusLine` in `settings.json`) | codex | not-applicable | Codex has no `settings.json` / statusLine loader | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:233` |
| 11. status line (`statusLine` in `settings.json`) | claude | not-shipped | arkit does not template `statusLine`; same gap as the `settings.json` slot itself | — | n/a | n/a | — | — | `docs/source/harness-shape-claude.md` row 11 |
| 12. MCP servers (per-user MCP config) | codex | not-shipped | runtime-kit does not template MCP servers; per-user MCP credentials are classified as sensitive | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:1456-1464` |
| 12. MCP servers (per-user MCP config) | claude | not-shipped | same as codex; out-of-scope by design (secret boundary) | — | n/a | n/a | — | — | `docs/source/inventory-target-architecture.md:1456-1464` |
| 13. heuristic system (curated retained records) | codex | shipped | shared policy root; consumed by `heuristic-inbox` binary with explicit `--inbox-dir` | `core/policies/heuristic-system/` | 0.130.0 | v0.17.5 (`heuristic-inbox`) | gate 8 (runtime-smoke deterministic, meta domain) | — | `docs/source/inventory-target-architecture.md:950-956` |
| 13. heuristic system (curated retained records) | claude | shipped | same shared policy root | `core/policies/heuristic-system/` | 2.1.145 | v0.17.5 (`heuristic-inbox`) | gate 8 (runtime-smoke deterministic, meta domain) | — | `docs/source/inventory-target-architecture.md:950-956` |
| 14. runtime state (`state_home`) | codex | shipped | `CODEX_AGENT_STATE_HOME` env var + `agent-out` runtime allocator | `manifests/runtime-roots.yaml` codex block | 0.130.0 | v0.17.5 (`agent-out >=0.13.0` floor) | gate 5 (drift), gate 7 (doctor `block=0`) | — | `manifests/runtime-roots.yaml:17-23`; `manifests/product-capabilities.yaml:40-42` |
| 14. runtime state (`state_home`) | claude | shipped | `CLAUDE_KIT_STATE_HOME` env var + `agent-out` runtime allocator | `manifests/runtime-roots.yaml` claude block | 2.1.145 | v0.17.5 (`agent-out >=0.13.0` floor) | gate 5 (drift), gate 7 (doctor `block=0`) | — | `manifests/runtime-roots.yaml:29-35`; `manifests/product-capabilities.yaml:64-66` |
| 15. Codex local skill root (`$CODEX_HOME/skills/<d>/<s>/`) | codex | shipped | one directory symlink per active skill folder under `$CODEX_HOME/skills/<d>/<s>/` | `core/skills/<domain>/<skill>/` → `build/codex/plugins/<d>/skills/<s>/` (53 entries) | 0.130.0 | v0.20.0 | gate 3 (render), gate 5 (golden), gate 6 (drift), gate 7 (`doctor --class skill-surface --product codex`), gate 8 (sandbox), gate 9 (runtime-smoke) | `codex debug prompt-input` fresh session | `targets/codex/link-map.yaml:7-12, 28-44, 57-127, 343-389`; `manifests/skills.yaml` |
| 15. Codex local skill root (`$CODEX_HOME/skills/<d>/<s>/`) | claude | not-applicable | Claude uses plugin-scoped skill discovery (surface 5) instead | — | n/a | n/a | — | — | `manifests/product-capabilities.yaml:45-62` |
| 16. Codex hook registration (`config.toml` managed block) | codex | shipped | `managed-block` sync into `$CODEX_HOME/config.toml`, surface `hooks`, hash-comment markers | `targets/codex/hooks/config.block.toml` | 0.130.0 | v0.17.5 | gate 5 (drift, managed-block presence + marker pair), gate 10 (`tests/hooks/run.sh`) | — | `targets/codex/link-map.yaml:396-401`; `docs/source/inventory-target-architecture.md:1256-1270` |
| 16. Codex hook registration (`config.toml` managed block) | claude | not-applicable | Claude uses `settings.json` block (surface 9) instead; the two are different upstream primitives | — | n/a | n/a | — | — | `manifests/runtime-roots.yaml:17-38` (`hook_config_strategy` differs per product) |
| 17. prompt-mode delegation policy (`AGENT_HOME.md`) | codex | shipped | policy text loaded as part of the home prompt (surface 1) | `AGENT_HOME.md` | 0.130.0 | n/a | — | live Codex session | `AGENT_HOME.md:37-49` |
| 17. prompt-mode delegation policy (`AGENT_HOME.md`) | claude | shipped | same shared home prompt, same policy text | `AGENT_HOME.md` | 2.1.145 | n/a | — | live Claude session | `AGENT_HOME.md:37-49` |

## Open asymmetries

- **Codex-side skill-surface doctor exists; Claude side does not.**
  `agent-runtime doctor --class skill-surface --product codex` runs in
  the default CI gate stack (position 7). There is no
  `--product claude` counterpart today; this asymmetry is recorded
  here as a schema-relevant gap rather than a bug, and will need a
  Claude-side analogue if the Claude skill surface starts drifting
  silently. See `DEVELOPMENT.md:164, 170-178`.
- **No live Claude acceptance protocol is wired in tree.** Codex has
  `codex debug prompt-input` in a fresh Codex Desktop session
  (`docs/plans/codex-skill-surface-acceptance-cutover/`). The Claude
  equivalent ("fresh Claude session that lists installed skills") has
  no documented protocol or CI gate today. Closest analogue is the
  quarantined `bash tests/runtime-smoke/run.sh --mode product
  --product claude --probe-only` (`DEVELOPMENT.md:235-242`).
- **Codex `.codex-plugin/plugin.json` is shipped as audit metadata but
  never loaded at runtime.** This is the `not-applicable` row whose
  `source_artifact` column is non-empty; Resolved Decision #10 is the
  authoritative reason (`docs/source/inventory-target-architecture.md:2049-2073`).
- **Claude hook adapter slot (`targets/claude/hooks/`) is empty.** The
  shared scripts ship today, but the Claude-specific adapter wrapper
  contract from Resolved Decision #4 has no concrete source yet —
  hence the `partial` state on row 8 claude.
  See Resolved Decision #4 in `docs/source/inventory-target-architecture.md:1978-1981`.
- **`settings.json` managed block contract is defined but no template
  artifact exists.** Row 9 claude is `planned-not-shipped`. The
  managed-block paired-marker contract is described in
  `docs/source/inventory-target-architecture.md:1264-1278`; no
  `targets/claude/settings.json.template` or matching link-map entry
  ships today.

## When this matrix needs an update

This section is the contributor-facing checklist. Cross-reference the
`Reopen triggers` block in
`docs/plans/support-matrix/support-matrix-execution-state.md` if you
need the plan's view of the same drift vectors.

- A new harness primitive lands in `harness-shape-codex.md` or
  `harness-shape-claude.md` → add the missing rows here in the same
  PR.
- `manifests/runtime-roots.yaml` bumps `min_version` /
  `recommended_version` / `min_version_effective_from` for either
  product → refresh the affected `min_product` cells in this file in
  the same PR.
- `docs/source/nils-cli-surface.md` rolls past `v0.20.0` →
  refresh `min_nils_cli` cells and the surface-pin paragraph. The
  Position 2 surface-pin alignment gate in `scripts/ci/all.sh` fails
  closed whenever this refresh lags the host `agent-runtime --version`,
  so an unsynced bump is loud rather than silent.
- A new CI gate position is added or removed in
  `scripts/ci/all.sh` (`DEVELOPMENT.md:157-178`) → refresh
  `ci_acceptance` cells that reference it.
- A `support_state` flips for a row (e.g. `partial` → `shipped` when
  the Claude hook adapter slot fills, or `planned-not-shipped` →
  `shipped` when `settings.json.template` lands) → flip the state and
  the related cells in the same PR that lands the change.
- Manifest counts referenced inline change — e.g. `manifests/plugins.yaml`
  grows past 10 plugin entries, or `manifests/skills.yaml` past 53
  Codex skill entries → refresh the parenthetical counts in the
  `source_artifact` cells of rows 3, 4, 5, 15. Until a drift-audit
  `support-matrix` class lands, these counts are not enforced
  automatically.
