# Harness Shape — Codex

- Date: 2026-05-31
- Status: empirical observation; this file is the per-product
  narrative input to the root-level `SUPPORT_MATRIX.md`. For the
  unified Codex × Claude long-format table, see [`SUPPORT_MATRIX.md`](../../SUPPORT_MATRIX.md).
- Companion doc:
  `docs/source/harness-shape-claude.md`.
- Update (2026-06): Codex shipped a real plugin loader + plugin marketplace
  (`codex plugin marketplace add`;
  <https://developers.openai.com/codex/plugins/build>). Surfaces 3–5 below
  describe runtime-kit's current **non-adoption** of that surface, not a Codex
  product limitation: runtime-kit still installs Codex skills via the flat
  `$CODEX_HOME/skills` root (surface 15). Adopting Codex's plugin/marketplace
  surface — and the `manifests/product-capabilities.yaml` capability flip it
  implies — is a separate tracked change, not yet done.

## Purpose

Inventory the surfaces the Codex harness actually consumes at runtime
and, for each, record what `agent-runtime-kit` ships today, the
mechanism it ships through, the source artifact, and the version floor
that gates it. This is the Codex-side raw material for the unified
`SUPPORT_MATRIX.md`; do not invent capabilities here that the source
tree cannot back.

Scope rules:

- Only list primitives Codex itself reads, plus Claude-shape rows that
  must be marked `not-applicable` to keep this file pivotable with
  `docs/source/harness-shape-claude.md`.
- Mark a primitive `shipped` only when there is a concrete source
  artifact (`targets/codex/...`, `core/...`, manifest entry, link-map
  entry). A primitive with no source artifact yet is
  `planned-not-shipped`.
- `.codex-plugin/plugin.json` is source-organisation / audit metadata in
  this kit; runtime-kit does not install Codex skills as a plugin, so it is
  not loaded here (`manifests/product-capabilities.yaml`). Codex itself can
  load it as of 2026 — see the Update note above.
- Cite file paths (not line numbers — they rot); this doc must stay
  verifiable.

## Version Floors (Codex side)

- Codex product `min_version` / `recommended_version`: **0.139.0**;
  `min_version_effective_from`: **2026-06-28**; probe:
  `codex --version` (`manifests/runtime-roots.yaml`).
- `agent-runtime` orchestration binary (renders / installs the Codex
  surface) ships inside nils-cli; pinned snapshot **v1.12.0**
  (`docs/source/nils-cli-surface.md`, `docs/source/nils-cli-pin.yaml`).
  Released subcommands consumed today: `render`, `install`, `uninstall`,
  `doctor` (including `--class skill-surface --product codex`),
  `audit-drift`, `gc-backups`, `restore-backups`, `purge-state`, and
  `pr-body render`.
- The `agent-run` capability binary (nils-cli `>=0.20.0`) is consumed by
  project-script dispatcher skills so repository-owned `.agents/scripts/*`
  commands run through explicit `.envrc` / `.env` handling.
- Per-skill nils-cli floors come from `manifests/skills.yaml`
  `required_clis` and gate skill bodies, not Codex's core load path.
  Project-script dispatcher skills that depend on explicit project
  environment execution pin `agent-run` at `>=0.20.0`; dispatch / PR
  skills that depend on the v0.17.5 release boundary pin `forge-cli`,
  `plan-issue`, or `plan-tooling` at `>=0.17.5` (`manifests/skills.yaml`).
- Live Codex Desktop acceptance is separate from the deterministic
  version floor: `codex debug prompt-input` must show required skills
  in a fresh session
  (`docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/`).

## Surface-By-Surface Shape

Each section below answers the same questions so the table can pivot to
a uniform shape:

1. **Codex reads from** — runtime discovery path.
2. **Source** — checked-in artifact (`-` if none).
3. **Install mechanism** — link-map entry kind or render-time handling.
4. **Acceptance lane** — what gates the surface today.
5. **Support today** — current ship state.

### 1. Home-scope prompt (`AGENTS.md`)

- Codex reads from: `$CODEX_HOME/AGENTS.md` on session start.
- Source: root `AGENT_HOME.md`, shared with Claude's
  `$HOME/.claude/CLAUDE.md` (`AGENT_HOME.md`, `DEVELOPMENT.md`).
- Install mechanism: symlink `$CODEX_HOME/AGENTS.md →
  <source_root>/AGENT_HOME.md`. The source filename is deliberately
  distinct from repo-local `AGENTS.md` so Codex does not load duplicate
  home/project policy in this repo.
- Acceptance lane: covered by home-policy cutover and live Codex session
  observation; no dedicated CI gate diffs the link target.
- Support today: **shipped (linked)**.

### 2. Project-scope prompt (`./AGENTS.md`)

- Codex reads from: project-local `AGENTS.md` files while working in a
  repo; this is why home policy uses `AGENT_HOME.md` instead of a
  source-root `AGENTS.md`.
- Source: `./AGENTS.md` in this repo, which declares the repo-local
  policy and notes that `./CLAUDE.md` is a symlink to it (`AGENTS.md`).
- Install mechanism: not installed by `agent-runtime`; it ships as part
  of the repo working tree.
- Acceptance lane: covered indirectly by any Codex session opened in
  this repo; no specific gate.
- Support today: **shipped (repo-local only)**.

### 3. Plugin manifest (`.codex-plugin/plugin.json`)

- Codex reads from: not on a live load path in the runtime-kit surface.
  Codex itself added a plugin loader that reads `.codex-plugin/plugin.json`
  in 2026, but runtime-kit does not install Codex skills as a plugin, so this
  manifest is not loaded here (`manifests/product-capabilities.yaml`).
- Source: `targets/codex/plugins/<plugin>/.codex-plugin/plugin.json`
  exists for all 10 plugin domains (`manifests/plugins.yaml`); the
  reporting artifact shows the local audit schema shape
  (`targets/codex/plugins/reporting/.codex-plugin/plugin.json`). Note the
  kit's `skills: [{id, source}]` shape predates — and does not match —
  Codex's current `plugin.json` schema (`skills: "./skills/"` plus
  `interface` / `mcpServers` / `apps` / `hooks`).
- Install mechanism: `plugin-manifest-copy` into
  `$CODEX_HOME/plugins/<domain>/.codex-plugin/plugin.json`, retained for
  audit / compatibility only (`targets/codex/link-map.yaml`).
- Acceptance lane: drift audit validates local schema only; runtime-kit does
  not yet register a Codex plugin against Codex's loader.
- Support today: **not-applicable on the pre-2026 baseline** — Codex now has
  a plugin loader; runtime-kit has not adopted it (tracked separately).

### 4. Plugin marketplace (`.codex-plugin/marketplace.json`)

- Codex reads from: not shipped by runtime-kit. Codex added a plugin
  marketplace in 2026 (`codex plugin marketplace add`, sourcing
  `.agents/plugins/marketplace.json` and reading
  `.claude-plugin/marketplace.json` as a legacy source), but runtime-kit does
  not generate or register a Codex marketplace
  (`manifests/product-capabilities.yaml`).
- Source: **none** — runtime-kit ships only the Claude
  `.claude-plugin/marketplace.json` today.
- Install mechanism: not installed.
- Acceptance lane: none yet on the Codex side.
- Support today: **not-applicable on the pre-2026 baseline** — Codex now has
  a marketplace; adopting it for the Codex surface is tracked separately.

### 5. Plugin-scoped skills (`<plugin>/skills/<skill>/SKILL.md`)

- Codex reads from: the flat skill root, not plugin roots, in the
  runtime-kit surface. Active Codex skills are exposed through
  `$CODEX_HOME/skills/<domain>/<skill>/SKILL.md` (surface 15). Codex does
  support plugin-bundled `skills/<skill>/SKILL.md` discovery as of 2026;
  runtime-kit has not switched its active discovery to it.
- Source: `build/codex/plugins/<domain>/skills/<skill>/` exists as the
  rendered symlink target, but that tree is linked for audit only, not as
  the active plugin-scoped runtime root (`targets/codex/link-map.yaml`).
- Install mechanism: plugin skills trees are recursively linked under
  `$CODEX_HOME/plugins/<domain>/skills` for audit / compatibility, while
  active skill folders are installed separately under `$CODEX_HOME/skills`
  (see surface 15).
- Acceptance lane: none for plugin-scoped discovery; the active Codex
  skill-root acceptance is surface 15.
- Support today: **not-applicable on the pre-2026 baseline** — Codex now has
  plugin-scoped skill discovery; runtime-kit keeps the flat root (surface 15).

### 6. Slash command files (`commands/<name>.md` outside skills)

- Codex reads from: **nowhere** in the runtime-kit activation surface;
  the documented Codex load set is `$CODEX_HOME/AGENTS.md`, local
  skills, `config.toml`, and hook-referenced files.
- Source: **none**.
- Install mechanism: not installed.
- Acceptance lane: none.
- Support today: **not-applicable**. This is a Claude harness primitive,
  not a Codex one.

### 7. Subagent definitions (`agents/<name>.md`)

- Codex reads from: `$CODEX_HOME/agents/<name>.toml` (personal) and
  `.codex/agents/<name>.toml` (project) for file-backed subagents Codex can
  spawn, per the Codex subagents docs
  (<https://developers.openai.com/codex/subagents>).
- Source: one canonical `core/agents/<domain>/<name>/AGENT.md.tera`, rendered
  per product. The `product` Tera variable branches the Codex TOML body —
  `name`, `description`, `developer_instructions`, and (for a reviewer)
  `sandbox_mode = "read-only"` (`manifests/agents.yaml`).
- Install mechanism: rendered to `build/codex/agents/<name>.toml`, then
  `symlinked-file` `recursive: true` (`id: agents-tree`) into
  `$CODEX_HOME/agents/` (`targets/codex/link-map.yaml`).
- Acceptance lane: render / golden / audit-drift / sandbox install rehearsal
  gates (the rehearsal pins the installed reviewer agents per product against
  `tests/sandbox/codex/expected-agents.txt`); the live Codex discovery probe is
  manual-only, documented in `tests/runtime-smoke/README.md`.
- Support today: **shipped (`reviewer-quick` + seven specialist lenses)**. The
  cross-product agents render surface ships in nils-cli v1.3.0; the managed
  read-only reviewers are `reviewer-quick` (quick pass) plus seven specialist
  lenses (testing, maintainability, security, performance, api-contract,
  data-migration, red-team).

### 8. Hook scripts (`hooks/<name>.*`)

- Codex reads from: scripts referenced from the managed block inside
  `$CODEX_HOME/config.toml`; hook commands call files under
  `$CODEX_HOME/hooks/` (`manifests/product-capabilities.yaml`,
  `targets/codex/hooks/config.block.toml`).
- Source: portable logic under `core/hooks/shared/`; there is no
  `core/hooks/codex/` tree today, and product-specific activation lives
  in `targets/codex/hooks/` plus the link map (`core/hooks/README.md`).
- Install mechanism: `symlinked-file` (`targets/codex/link-map.yaml`,
  `id: hooks.shared-scripts`, source `core/hooks/shared` →
  `$CODEX_HOME/hooks`).
- Acceptance lane: shared hook contract tests
  (`bash tests/hooks/run.sh`, CI position 10, `DEVELOPMENT.md`).
- Support today: **shipped (shared scripts symlinked)**.

### 9. Hook registration (`settings.json` `hooks` block)

- Codex reads from: **nowhere**. Codex has no `settings.json`-equivalent
  hook registration; hook activation is TOML-only through
  `$CODEX_HOME/config.toml`.
- Source: **none** for `settings.json`; the Codex TOML managed block is
  recorded separately in surface 16.
- Install mechanism: not installed.
- Acceptance lane: none for `settings.json`; Codex hook acceptance uses
  the TOML managed block in surface 16.
- Support today: **not-applicable**.

### 10. Output styles (`output-styles/<name>.md`)

- Codex reads from: **nowhere** in the runtime-kit activation surface.
- Source: **none**.
- Install mechanism: not installed.
- Acceptance lane: none.
- Support today: **not-applicable**. This is a Claude-only primitive.

### 11. Status line (`statusLine` in `settings.json`)

- Codex reads from: **nowhere**. Codex hook/config activation is TOML
  managed-block based, not `settings.json` based
  (`manifests/runtime-roots.yaml`).
- Source: **none**.
- Install mechanism: not installed.
- Acceptance lane: none.
- Support today: **not-applicable**. This is a Claude-only primitive.

### 12. MCP servers (per-user MCP config)

- Codex reads from: Codex's own per-user config / connector setup, not
  an `agent-runtime-kit` surface. Runtime-kit only owns the hook managed
  block inside `$CODEX_HOME/config.toml`
  (`manifests/product-capabilities.yaml`).
- Source: **none** — runtime-kit does not template MCP servers.
- Install mechanism: not installed; per-user MCP connection strings are
  classified as sensitive.
- Acceptance lane: none.
- Support today: **not-shipped**. Out-of-scope by design (secret
  boundary).

### 13. Heuristic system (curated retained records)

- Codex reads from: not directly as a harness loader. The home prompt
  points at the heuristic system as policy / workflow guidance, and the
  `heuristic-inbox` skill consumes the retained-record tree.
- Source: shared root under `core/policies/heuristic-system/`
  (HEURISTIC_SYSTEM.md + error-inbox + operation-records).
- Install mechanism: currently a docs / skill surface; consumed via the
  `heuristic-inbox` nils-cli binary with explicit `--inbox-dir`
  arguments rather than a fixed Codex load path.
- Acceptance lane: runtime-smoke deterministic mode exercises the
  `heuristic-inbox` skill through the meta domain (`DEVELOPMENT.md`).
- Support today: **shipped (shared policy root)**.

### 14. Runtime state (`state_home`)

- Codex reads from: not directly — `state_home` is owned by skills /
  hooks via `agent-out` and `CODEX_AGENT_STATE_HOME`.
- Source: contract in `manifests/runtime-roots.yaml` and
  `manifests/product-capabilities.yaml`.
- Install mechanism: `agent-runtime install` resolves runtime roots;
  `agent-out` allocates artifact paths at runtime.
- Acceptance lane: drift audit + doctor verify resolution; backup
  retention reported by `doctor`.
- Support today: **shipped (env var + runtime allocator)**.

### 15. Codex local skill root (`skills/<domain>/<skill>/SKILL.md`)

- Codex reads from: `$CODEX_HOME/skills/<domain>/<skill>/SKILL.md`;
  live prompt input in the May 2026 cutover environment listed
  `$HOME/.codex/skills` as the runtime-kit skill root
  (`manifests/product-capabilities.yaml`).
- Source: `core/skills/<domain>/<skill>/`, rendered to
  `build/codex/plugins/<domain>/skills/<skill>/`; 65 Codex skill
  entries are declared in `manifests/skills.yaml` (count auto-maintained
  by `scripts/ci/skill-governance-audit.sh --update-counts`).
- Install mechanism: one non-recursive directory symlink per active
  skill folder under `$CODEX_HOME/skills/<domain>/<skill>/`
  (`targets/codex/link-map.yaml`).
- Acceptance lane: render output (CI position 2); render-golden
  (position 4); drift audit (position 5); **Codex-only** skill-surface
  doctor (position 6); sandbox install rehearsal diffs
  `tests/sandbox/codex/expected-skills.txt`; runtime-smoke deterministic
  mode exercises representative skills; live Codex Desktop acceptance
  requires `codex debug prompt-input` (`DEVELOPMENT.md`,
  `tests/sandbox/codex/expected-skills.txt:1-65`,
  `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/`).
- Support today: **shipped (rendered + directory symlink)**.

### 16. Codex hook registration (`config.toml` managed block)

- Codex reads from: `$CODEX_HOME/config.toml` TOML hook definitions
  (`manifests/product-capabilities.yaml`, `manifests/runtime-roots.yaml`).
- Source: `targets/codex/hooks/config.block.toml`; the source tree does
  **not** have `targets/codex/config.block.toml` at the root. The actual
  artifact is the hook-scoped file
  (`targets/codex/hooks/config.block.toml`).
- Install mechanism: `managed-block` into `config.toml`, surface `hooks`,
  with hash comment markers (`targets/codex/link-map.yaml`). The
  managed-block contract preserves everything outside the marker pair
  byte-for-byte.
- Acceptance lane: drift audit checks managed-block presence; hook tests
  verify the referenced shared scripts (`DEVELOPMENT.md`).
- Support today: **shipped (managed block)**.

### 17. Prompt-mode delegation policy (`AGENT_HOME.md`)

- Codex reads from: the loaded home prompt (`$CODEX_HOME/AGENTS.md`)
  carries opt-in delegation modes such as `parallel-first` and
  `orchestrator-first`; there is no separate Codex file loader for
  subagent definitions (`AGENT_HOME.md`).
- Source: root `AGENT_HOME.md`.
- Install mechanism: same symlink as surface 1; policy text is loaded as
  part of the home-scope prompt.
- Acceptance lane: live session prompt load only; no dedicated CI gate
  validates prompt-mode behavior.
- Support today: **shipped (policy text in home prompt)**.

## Coverage Summary

| # | Surface | runtime-kit ships | Mechanism | Min Codex | Min nils-cli |
|---|---|---|---|---|---|
| 1 | `AGENTS.md` (home) | yes | symlink to `AGENT_HOME.md` | 0.130.0 | n/a |
| 2 | `./AGENTS.md` (repo-local) | yes | repo working tree | 0.130.0 | n/a |
| 3 | `.codex-plugin/plugin.json` | not-applicable | audit-only metadata; Codex loader exists (2026) but kit hasn't adopted it | n/a | v0.17.5 |
| 4 | `.codex-plugin/marketplace.json` | not-applicable | Codex marketplace exists (2026); kit ships none | n/a | n/a |
| 5 | `plugins/<p>/skills/<s>/` discovery | not-applicable | active Codex skill root is row 15; plugin-scoped discovery exists (2026), not adopted | n/a | n/a |
| 6 | `commands/<n>.md` | not-applicable | — | n/a | n/a |
| 7 | `agents/<n>.toml` | yes | rendered + directory symlink into `$CODEX_HOME/agents` | 0.139.0 | v1.3.0 |
| 8 | `hooks/<n>.*` scripts | yes | shared scripts symlinked to `$CODEX_HOME/hooks` | 0.130.0 | v0.17.5 |
| 9 | `settings.json` hooks block | not-applicable | — | n/a | n/a |
| 10 | `output-styles/<n>.md` | not-applicable | — | n/a | n/a |
| 11 | `statusLine` / `settings.json` | not-applicable | — | n/a | n/a |
| 12 | MCP servers | no | — | n/a | n/a |
| 13 | Heuristic system | yes | shared policy root | 0.130.0 | v1.8.0 (heuristic-inbox) |
| 14 | `state_home` | yes | env var + `agent-out` allocation | 0.130.0 | v0.17.5 (`agent-out >=0.13.0` floor in skills.yaml) |
| 15 | `$CODEX_HOME/skills/<d>/<s>/` | yes | rendered + directory symlink per skill | 0.130.0 | v0.20.0 |
| 16 | `config.toml` hook managed block | yes | managed-block sync | 0.130.0 | v0.17.5 |
| 17 | prompt-mode delegation policy | yes | loaded via home prompt | 0.130.0 | n/a |

Status legend:

- **yes** — concrete source artifact + link-map entry or repo-local
  prompt artifact + acceptance lane.
- **partial** — some sub-surfaces present, others reserved but empty.
- **planned-not-shipped** — contract defined in manifests but no source
  artifact yet.
- **no** — Codex-capable or adjacent primitive that runtime-kit does not
  target; not on the current roadmap unless added explicitly.
- **not-applicable** — Claude harness primitive or local metadata row
  with no Codex runtime loader. (Rows 3–5 keep this label on the pre-2026
  baseline; Codex has since shipped a plugin loader + marketplace, so those
  rows are pending re-classification once runtime-kit adopts that surface —
  see the Update note at the top of this file.)

## Acceptance Lanes (Codex-Relevant CI Gates)

From `DEVELOPMENT.md`:

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
   when `block=0` (`DEVELOPMENT.md`).
8. **runtime-smoke deterministic mode** — exercises representative
   installed skills across current domains (`DEVELOPMENT.md`).
9. **project-local overlay smoke** — Codex-side project-local shims for
   `bootstrap`, `deploy`, `pre-pr`, and `release`, plus `setup-project`
   adoption diagnostics (`DEVELOPMENT.md`).
10. **`bash tests/hooks/run.sh`** — shared hook contract tests.

Quarantined (not in default CI):

- `bash tests/runtime-smoke/run.sh --mode product --product codex`;
  `--probe-only` validates isolated CLI invocation without full prompt
  execution.

Live Codex acceptance:

- `codex debug prompt-input` in a fresh Codex Desktop session is the
  live acceptance lane. Pass signal: each required skill appears as a
  `- <name>: ...` entry in the `<skills_instructions>` block with a
  file path under
  `agent-runtime-kit/build/codex/plugins/<domain>/skills/<skill>/SKILL.md`
  (`docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/`).

## Open Items For Schema Design

Things that may need a dedicated column as the unified
`SUPPORT_MATRIX.md` schema evolves:

- A `runtime_loaded` field separate from `metadata_shipped`, so Codex
  `.codex-plugin/plugin.json` can be represented as copied/audited but
  not loaded.
- A `runtime_skill_root` field that distinguishes Codex
  `$CODEX_HOME/skills/<domain>/<skill>/` from Claude plugin-scoped skill
  discovery.
- A `config_surface` enum that can express `config.toml` managed blocks
  and Claude `settings.json` blocks without pretending they are the same
  upstream primitive.
- A `ci_acceptance` field separate from `live_acceptance`, because Codex
  has both the deterministic skill-surface doctor and the live
  `codex debug prompt-input` protocol.
- A `hook_logic_origin` field that can say `shared` vs
  `product-specific`; Codex currently ships shared scripts plus a Codex
  TOML block and has no `core/hooks/codex/` adapter tree.
