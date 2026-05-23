# Harness Shape — Codex

- Date: 2026-05-23
- Status: empirical observation; this file is the per-product
  narrative input to the root-level `SUPPORT_MATRIX.md`. For the
  unified Codex × Claude long-format table, see [`SUPPORT_MATRIX.md`](../../SUPPORT_MATRIX.md).
- Companion doc:
  `docs/source/harness-shape-claude.md`.

## Purpose

Inventory the surfaces the Codex harness actually consumes at runtime
and, for each, record what `agent-runtime-kit` ships today, the
mechanism it ships through, the source artifact, and the version floor
that gates it. This is the Codex-side raw material for a unified
`SUPPORT_MATRIX.md` schema; do not invent capabilities here that the
source tree cannot back.

Scope rules:

- Only list primitives Codex itself reads, plus Claude-shape rows that
  must be marked `not-applicable` to keep this file pivotable with
  `docs/source/harness-shape-claude.md`.
- Mark a primitive `shipped` only when there is a concrete source
  artifact (`targets/codex/...`, `core/...`, manifest entry, link-map
  entry). "Documented in inventory doc but no source artifact yet" is
  `planned-not-shipped`.
- `.codex-plugin/plugin.json` is source-organisation / audit metadata
  only. Codex does not load it at runtime
  (`docs/source/inventory-target-architecture.md:573-584`,
  `docs/source/inventory-target-architecture.md:2049-2068`).
- Cite file paths and line numbers — this doc must stay verifiable.

## Version Floors (Codex side)

- Codex product `min_version` / `recommended_version`: **0.130.0**;
  `min_version_effective_from`: **2026-06-03**; probe:
  `codex --version` (`manifests/runtime-roots.yaml:17-27`).
- `agent-runtime` orchestration binary (renders / installs the Codex
  surface) ships inside nils-cli; pinned snapshot **v0.17.5**
  (`docs/source/nils-cli-surface.md:1-15`). Released subcommands
  consumed today: `render`, `install`, `uninstall`, `doctor`
  (including `--class skill-surface --product codex`), `audit-drift`,
  `gc-backups`, `restore-backups`, and `purge-state`
  (`docs/source/nils-cli-surface.md:31-33`).
- Per-skill nils-cli floors come from `manifests/skills.yaml`
  `required_clis` and gate skill bodies, not Codex's core load path
  (`manifests/skills.yaml:7-9`). Dispatch / PR skills that depend on
  the v0.17.5 release boundary pin `forge-cli`, `plan-issue`, or
  `plan-tooling` at `>=0.17.5`
  (`manifests/skills.yaml:416-650`).
- Live Codex Desktop acceptance is separate from the deterministic
  version floor: `codex debug prompt-input` must show required skills
  in a fresh session (`docs/plans/codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md:29-40`).

## Surface-By-Surface Shape

Each section below answers the same four questions so a future schema
can pivot to a uniform table:

1. **Codex reads from** — runtime discovery path.
2. **arkit source** — checked-in artifact (`-` if none).
3. **arkit install mechanism** — link-map entry kind or render-time
   handling.
4. **Acceptance lane** — what gates the surface today.

### 1. Home-scope prompt (`AGENTS.md`)

- Codex reads from: `$CODEX_HOME/AGENTS.md` on session start
  (`docs/source/inventory-target-architecture.md:540-544`).
- arkit source: root `AGENT_HOME.md`, shared with Claude's
  `$HOME/.claude/CLAUDE.md` (`AGENT_HOME.md:5-15`,
  `DEVELOPMENT.md:37-41`).
- arkit install mechanism: symlink `$CODEX_HOME/AGENTS.md →
  <source_root>/AGENT_HOME.md`. The source filename is deliberately
  distinct from repo-local `AGENTS.md` so Codex does not load duplicate
  home/project policy in this repo
  (`docs/source/inventory-target-architecture.md:586-593`).
- Acceptance lane: covered by home-policy cutover and live Codex
  session observation; no dedicated CI gate diffs the link target.
- arkit support today: **shipped (linked)**.

### 2. Project-scope prompt (`./AGENTS.md`)

- Codex reads from: project-local `AGENTS.md` files while working in a
  repo; this is why home policy uses `AGENT_HOME.md` instead of a
  source-root `AGENTS.md`
  (`docs/source/inventory-target-architecture.md:588-593`).
- arkit source: `./AGENTS.md` in this repo, which declares the
  repo-local policy and notes that `./CLAUDE.md` is a symlink to it
  (`AGENTS.md:1-10`).
- arkit install mechanism: not installed by `agent-runtime`; it ships
  as part of the repo working tree.
- Acceptance lane: covered indirectly by any Codex session opened in
  this repo; no specific gate.
- arkit support today: **shipped (repo-local only)**.

### 3. Plugin manifest (`.codex-plugin/plugin.json`)

- Codex reads from: **nowhere**. Codex never opens
  `.codex-plugin/plugin.json` at runtime
  (`docs/source/inventory-target-architecture.md:562-571`,
  `manifests/product-capabilities.yaml:23-30`).
- arkit source: `targets/codex/plugins/<plugin>/.codex-plugin/plugin.json`
  exists for all 10 plugin domains (`manifests/plugins.yaml:12-135`);
  the reporting artifact shows the local audit schema shape
  (`targets/codex/plugins/reporting/.codex-plugin/plugin.json:1-22`).
- arkit install mechanism: `plugin-manifest-copy` into
  `$CODEX_HOME/plugins/<domain>/.codex-plugin/plugin.json`, retained for
  audit / compatibility only (`targets/codex/link-map.yaml:17-20`,
  `targets/codex/link-map.yaml:245-248`,
  `targets/codex/link-map.yaml:332-335`).
- Acceptance lane: drift audit validates local schema only; there is no
  upstream Codex registry to compare against
  (`docs/source/inventory-target-architecture.md:595-600`).
- arkit support today: **not-applicable (metadata shipped; no Codex
  runtime loader)**.

### 4. Plugin marketplace (`.codex-plugin/marketplace.json`)

- Codex reads from: **nowhere**. Codex has no plugin marketplace API
  (`docs/source/inventory-target-architecture.md:562-567`,
  `manifests/product-capabilities.yaml:43`).
- arkit source: **none**.
- arkit install mechanism: not installed.
- Acceptance lane: none; PR review must not flag a missing Codex
  marketplace entry as a defect
  (`docs/source/inventory-target-architecture.md:606-607`).
- arkit support today: **not-applicable**.

### 5. Plugin-scoped skills (`<plugin>/skills/<skill>/SKILL.md`)

- Codex reads from: **not** plugin roots. Codex local skills are exposed
  through `$CODEX_HOME/skills/<domain>/<skill>/SKILL.md`; plugin-scoped
  discovery through `$CODEX_HOME/plugins/<domain>/skills` is not the
  runtime discovery surface
  (`docs/source/inventory-target-architecture.md:545-554`,
  `docs/source/inventory-target-architecture.md:569-584`).
- arkit source: `build/codex/plugins/<domain>/skills/<skill>/` exists
  as the rendered symlink target, but that tree is not loaded as a
  plugin-scoped runtime root (`targets/codex/link-map.yaml:22-31`,
  `targets/codex/link-map.yaml:51-60`).
- arkit install mechanism: plugin skills trees are recursively linked
  under `$CODEX_HOME/plugins/<domain>/skills` for audit /
  compatibility, while active skill folders are installed separately
  under `$CODEX_HOME/skills` (see surface 15).
- Acceptance lane: none for plugin-scoped discovery; the active Codex
  skill-root acceptance is surface 15.
- arkit support today: **not-applicable (Codex has no plugin-scoped
  skill discovery)**.

### 6. Slash command files (`commands/<name>.md` outside skills)

- Codex reads from: **nowhere** in the runtime-kit activation surface;
  the documented Codex load set is `$CODEX_HOME/AGENTS.md`, local
  skills, `config.toml`, and hook-referenced files
  (`docs/source/inventory-target-architecture.md:540-560`).
- arkit source: **none**.
- arkit install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not-applicable**. This is a Claude harness
  primitive, not a Codex one
  (`docs/source/inventory-target-architecture.md:226-229`).

### 7. Subagent definitions (`agents/<name>.md`)

- Codex reads from: **nowhere** in the runtime-kit activation surface;
  `AGENT_HOME.md` describes opt-in delegation modes as policy text, not
  file-backed subagent discovery (`AGENT_HOME.md:37-49`).
- arkit source: **none**.
- arkit install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not-applicable**. Claude's `agents/<name>.md`
  file primitive has no Codex analogue in this repo
  (`docs/source/inventory-target-architecture.md:226-228`).

### 8. Hook scripts (`hooks/<name>.*`)

- Codex reads from: scripts referenced from the managed block inside
  `$CODEX_HOME/config.toml`; hook commands call files under
  `$CODEX_HOME/hooks/` (`manifests/product-capabilities.yaml:31-39`,
  `targets/codex/hooks/config.block.toml:1-8`).
- arkit source: portable logic under `core/hooks/shared/`; there is no
  `core/hooks/codex/` tree today, and product-specific activation lives
  in `targets/codex/hooks/` plus the link map
  (`core/hooks/README.md:3-16`).
- arkit install mechanism: `symlinked-file`
  (`targets/codex/link-map.yaml:391-394`, `id: hooks.shared-scripts`,
  source `core/hooks/shared` → `$CODEX_HOME/hooks`).
- Acceptance lane: shared hook contract tests
  (`bash tests/hooks/run.sh`, CI position 10,
  `DEVELOPMENT.md:157-168`).
- arkit support today: **shipped (shared scripts symlinked)**.

### 9. Hook registration (`settings.json` `hooks` block)

- Codex reads from: **nowhere**. Codex has no `settings.json`-equivalent
  hook registration; hook activation is TOML-only through
  `$CODEX_HOME/config.toml`
  (`docs/source/inventory-target-architecture.md:555-558`,
  `docs/source/inventory-target-architecture.md:568-568`).
- arkit source: **none** for `settings.json`; the Codex TOML managed
  block is recorded separately in surface 16.
- arkit install mechanism: not installed.
- Acceptance lane: none for `settings.json`; Codex hook acceptance uses
  the TOML managed block in surface 16.
- arkit support today: **not-applicable**.

### 10. Output styles (`output-styles/<name>.md`)

- Codex reads from: **nowhere** in the runtime-kit activation surface
  (`docs/source/inventory-target-architecture.md:540-560`).
- arkit source: **none**.
- arkit install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not-applicable**. This is a Claude-only
  primitive (`docs/source/inventory-target-architecture.md:232-232`).

### 11. Status line (`statusLine` in `settings.json`)

- Codex reads from: **nowhere**. Codex hook/config activation is TOML
  managed-block based, not `settings.json` based
  (`docs/source/inventory-target-architecture.md:568-568`,
  `manifests/runtime-roots.yaml:17-27`).
- arkit source: **none**.
- arkit install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not-applicable**. This is a Claude-only
  primitive (`docs/source/inventory-target-architecture.md:233-233`).

### 12. MCP servers (per-user MCP config)

- Codex reads from: Codex's own per-user config / connector setup, not
  an `agent-runtime-kit` surface. Runtime-kit only owns the hook managed
  block inside `$CODEX_HOME/config.toml`
  (`manifests/product-capabilities.yaml:31-39`).
- arkit source: **none** — runtime-kit does not template MCP servers.
- arkit install mechanism: not installed; per-user MCP connection
  strings are classified as sensitive
  (`docs/source/inventory-target-architecture.md:1456-1464`).
- Acceptance lane: none.
- arkit support today: **not-shipped**. Out-of-scope by design
  (secret boundary).

### 13. Heuristic system (curated retained records)

- Codex reads from: not directly as a harness loader. The home prompt
  points at the heuristic system as policy / workflow guidance, and the
  `heuristic-inbox` skill consumes the retained-record tree.
- arkit source: shared root under
  `core/policies/heuristic-system/` (HEURISTIC_SYSTEM.md +
  error-inbox + operation-records).
- arkit install mechanism: currently a docs / skill surface; consumed
  via the `heuristic-inbox` nils-cli binary with explicit `--inbox-dir`
  arguments rather than a fixed Codex load path
  (`docs/source/inventory-target-architecture.md:950-956`).
- Acceptance lane: runtime-smoke deterministic mode exercises the
  `heuristic-inbox` skill through the meta domain
  (`DEVELOPMENT.md:216-219`).
- arkit support today: **shipped (shared policy root)**.

### 14. Runtime state (`state_home`)

- Codex reads from: not directly — `state_home` is owned by skills /
  hooks via `agent-out` and `CODEX_AGENT_STATE_HOME`.
- arkit source: contract in `manifests/runtime-roots.yaml:17-23` and
  `manifests/product-capabilities.yaml:40-42`.
- arkit install mechanism: `agent-runtime install` resolves runtime
  roots; `agent-out` allocates artifact paths at runtime
  (`docs/source/inventory-target-architecture.md:1081-1109`).
- Acceptance lane: drift audit + doctor verify resolution; backup
  retention reported by `doctor`
  (`docs/source/inventory-target-architecture.md:1311-1368`).
- arkit support today: **shipped (env var + runtime allocator)**.

### 15. Codex local skill root (`skills/<domain>/<skill>/SKILL.md`)

- Codex reads from: `$CODEX_HOME/skills/<domain>/<skill>/SKILL.md`;
  live prompt input in the May 2026 cutover environment listed
  `$HOME/.codex/skills` as the runtime-kit skill root
  (`docs/source/inventory-target-architecture.md:545-554`,
  `manifests/product-capabilities.yaml:15-22`).
- arkit source: `core/skills/<domain>/<skill>/`, rendered to
  `build/codex/plugins/<domain>/skills/<skill>/`; 44 Codex skill
  entries are declared in `manifests/skills.yaml`
  (`manifests/skills.yaml:12-650`).
- arkit install mechanism: one non-recursive directory symlink per
  active skill folder under `$CODEX_HOME/skills/<domain>/<skill>/`
  (`targets/codex/link-map.yaml:7-12`,
  `targets/codex/link-map.yaml:28-44`,
  `targets/codex/link-map.yaml:57-127`,
  `targets/codex/link-map.yaml:343-389`).
- Acceptance lane: render output (CI position 2); render-golden
  (position 4); drift audit (position 5); **Codex-only** skill-surface
  doctor (position 6); sandbox install rehearsal diffs
  `tests/sandbox/codex/expected-skills.txt`; runtime-smoke
  deterministic mode exercises representative skills; live Codex
  Desktop acceptance requires `codex debug prompt-input`
  (`DEVELOPMENT.md:157-178`,
  `tests/sandbox/codex/expected-skills.txt:1-44`,
  `docs/plans/codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md:91-107`).
- arkit support today: **shipped (rendered + directory symlink)**.

### 16. Codex hook registration (`config.toml` managed block)

- Codex reads from: `$CODEX_HOME/config.toml` TOML hook definitions
  (`manifests/product-capabilities.yaml:31-39`,
  `manifests/runtime-roots.yaml:17-27`).
- arkit source: `targets/codex/hooks/config.block.toml`; the source
  tree does **not** have `targets/codex/config.block.toml` at the root.
  The actual artifact is the hook-scoped file
  (`targets/codex/hooks/config.block.toml:1-93`).
- arkit install mechanism: `managed-block` into `config.toml`, surface
  `hooks`, with hash comment markers
  (`targets/codex/link-map.yaml:396-401`). The managed-block contract
  preserves everything outside the marker pair byte-for-byte
  (`docs/source/inventory-target-architecture.md:1256-1270`).
- Acceptance lane: drift audit checks managed-block presence; hook
  tests verify the referenced shared scripts
  (`docs/source/inventory-target-architecture.md:1320-1325`,
  `DEVELOPMENT.md:157-168`).
- arkit support today: **shipped (managed block)**.

### 17. Prompt-mode delegation policy (`AGENT_HOME.md`)

- Codex reads from: the loaded home prompt (`$CODEX_HOME/AGENTS.md`)
  carries opt-in delegation modes such as `parallel-first` and
  `orchestrator-first`; there is no separate Codex file loader for
  subagent definitions (`AGENT_HOME.md:37-49`).
- arkit source: root `AGENT_HOME.md`.
- arkit install mechanism: same symlink as surface 1; policy text is
  loaded as part of the home-scope prompt.
- Acceptance lane: live session prompt load only; no dedicated CI gate
  validates prompt-mode behavior.
- arkit support today: **shipped (policy text in home prompt)**.

## arkit Coverage Summary

| # | Surface | arkit ships | Mechanism | Min Codex | Min nils-cli |
|---|---|---|---|---|---|
| 1 | `AGENTS.md` (home) | yes | symlink to `AGENT_HOME.md` | 0.130.0 | n/a |
| 2 | `./AGENTS.md` (repo-local) | yes | repo working tree | 0.130.0 | n/a |
| 3 | `.codex-plugin/plugin.json` | not-applicable | metadata copy for audit only; no loader | n/a | v0.17.5 |
| 4 | `.codex-plugin/marketplace.json` | not-applicable | — | n/a | n/a |
| 5 | `plugins/<p>/skills/<s>/` discovery | not-applicable | active Codex skill root is row 15 | n/a | n/a |
| 6 | `commands/<n>.md` | not-applicable | — | n/a | n/a |
| 7 | `agents/<n>.md` | not-applicable | — | n/a | n/a |
| 8 | `hooks/<n>.*` scripts | yes | shared scripts symlinked to `$CODEX_HOME/hooks` | 0.130.0 | v0.17.5 |
| 9 | `settings.json` hooks block | not-applicable | — | n/a | n/a |
| 10 | `output-styles/<n>.md` | not-applicable | — | n/a | n/a |
| 11 | `statusLine` / `settings.json` | not-applicable | — | n/a | n/a |
| 12 | MCP servers | no | — | n/a | n/a |
| 13 | Heuristic system | yes | shared policy root | 0.130.0 | v0.17.5 (heuristic-inbox) |
| 14 | `state_home` | yes | env var + `agent-out` allocation | 0.130.0 | v0.17.5 (`agent-out >=0.13.0` floor in skills.yaml) |
| 15 | `$CODEX_HOME/skills/<d>/<s>/` | yes | rendered + directory symlink per skill | 0.130.0 | v0.17.5 |
| 16 | `config.toml` hook managed block | yes | managed-block sync | 0.130.0 | v0.17.5 |
| 17 | prompt-mode delegation policy | yes | loaded via home prompt | 0.130.0 | n/a |

Status legend:

- **yes** — concrete source artifact + link-map entry or repo-local
  prompt artifact + acceptance lane.
- **partial** — some sub-surfaces present, others reserved but empty.
- **planned-not-shipped** — contract defined in inventory / manifests
  but no source artifact yet.
- **no** — Codex-capable or adjacent primitive that arkit does not
  target; not on the current roadmap unless added explicitly.
- **not-applicable** — Claude harness primitive or local metadata row
  with no Codex runtime loader.

## Acceptance Lanes (Codex-Relevant CI Gates)

From `DEVELOPMENT.md:157-178`:

1. `plan-tooling validate` — covers manifest schemas.
2. **`agent-runtime render --product codex`** — render gate.
3. `agent-runtime render --product claude` — not Codex-side, but run in
   the shared gate stack.
4. **render-golden refresh + `git diff --exit-code`** — render
   determinism gate.
5. **`agent-runtime audit-drift` + fixtures** — drift audit gate
   (includes local-only Codex `plugin.json` schema validation and
   managed-block checks).
6. **`agent-runtime doctor --class skill-surface --product codex`** —
   Codex-only skill-surface shape preflight. It validates the
   source/link-map shape that feeds `$CODEX_HOME/skills`; it is not live
   Codex Desktop acceptance.
7. **sandbox install rehearsal** — installs into temp `live_home`,
   compares installed skill surfaces with
   `tests/sandbox/codex/expected-skills.txt`, and accepts doctor only
   when `block=0` (`DEVELOPMENT.md:210-214`).
8. **runtime-smoke deterministic mode** — exercises representative
   installed skills across current domains (`DEVELOPMENT.md:216-219`).
9. **project-local overlay smoke** — Codex-side project-local shims for
   `bench`, `bootstrap`, `demo`, `deploy`, `pre-pr`, and `release`
   (`DEVELOPMENT.md:224-228`).
10. **`bash tests/hooks/run.sh`** — shared hook contract tests.

Quarantined (not in default CI):

- `bash tests/runtime-smoke/run.sh --mode product --product codex`
  (`DEVELOPMENT.md:235-242`); `--probe-only` validates isolated CLI
  invocation without full prompt execution.

Live Codex acceptance:

- `codex debug prompt-input` in a fresh Codex Desktop session is the
  live acceptance lane. Pass signal: each required skill appears as a
  `- <name>: ...` entry in the `<skills_instructions>` block with a
  file path under
  `agent-runtime-kit/build/codex/plugins/<domain>/skills/<skill>/SKILL.md`
  (`docs/plans/codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md:29-40`,
  `docs/plans/codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md:91-107`).

## Open Items For Schema Design

Things that will need a column when the unified
`SUPPORT_MATRIX.md` schema is drafted:

- A `support_state` enum that includes
  `shipped`, `partial`, `planned-not-shipped`, `not-shipped`, and
  `not-applicable`.
- A `runtime_loaded` field separate from `metadata_shipped`, so Codex
  `.codex-plugin/plugin.json` can be represented as copied/audited but
  not loaded.
- A `runtime_skill_root` field that distinguishes Codex
  `$CODEX_HOME/skills/<domain>/<skill>/` from Claude plugin-scoped skill
  discovery.
- A `config_surface` enum that can express `config.toml` managed blocks
  and Claude `settings.json` blocks without pretending they are the
  same upstream primitive.
- A `source_artifact` field that can hold multiple paths (skills
  surface = source + render-to + link-map all three).
- A `min_nils_cli` field that may be tighter than the surface-level
  pin when a specific `required_clis` floor dominates (skills 15, 13,
  and 14 above).
- A `ci_acceptance` field separate from `live_acceptance`, because
  Codex has both the deterministic skill-surface doctor and the live
  `codex debug prompt-input` protocol.
- A `product_specific_doctor` column, because the Codex skill-surface
  doctor exists in the default gate while the Claude companion doc
  records no Claude-side equivalent yet.
- A `hook_logic_origin` field that can say `shared` vs
  `product-specific`; Codex currently ships shared scripts plus a
  Codex TOML block and has no `core/hooks/codex/` adapter tree.
- A `prompt_policy_mode` field for Codex prompt-mode delegation rules
  that are loaded as home-prompt text rather than as separate harness
  files.
