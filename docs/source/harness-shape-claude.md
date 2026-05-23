# Harness Shape — Claude

- Date: 2026-05-23
- Status: empirical observation; this file is the per-product
  narrative input to the root-level `SUPPORT_MATRIX.md`. For the
  unified Codex × Claude long-format table, see [`SUPPORT_MATRIX.md`](../../SUPPORT_MATRIX.md).
- Companion doc (Codex side):
  `docs/source/harness-shape-codex.md`.

## Purpose

Inventory the surfaces the Claude Code harness actually consumes at
runtime and, for each, record what `agent-runtime-kit` ships today, the
mechanism it ships through, the source artifact, and the version floor
that gates it. This is the Claude-side raw material for a unified
`SUPPORT_MATRIX.md` schema; do not invent capabilities here that the
source tree cannot back.

Scope rules:

- Only list primitives Claude itself reads. Out-of-process companions
  (host shell, brew, gh, etc.) belong in `cli-tools.yaml`.
- Mark a primitive `shipped` only when there is a concrete source
  artifact (`targets/claude/...`, `core/...`, manifest entry, link-map
  entry). "Documented in inventory doc but no source artifact yet" is
  `planned-not-shipped`.
- Cite file paths and line numbers — this doc must stay verifiable.

## Version Floors (Claude side)

- Claude product `min_version` / `recommended_version`: **2.1.145**;
  `min_version_effective_from`: **2026-06-03**; probe: `claude --version`
  (`manifests/runtime-roots.yaml:29-38`).
- `agent-runtime` orchestration binary (renders / installs the Claude
  surface) ships inside nils-cli; pinned snapshot **v0.17.5**
  (`docs/source/nils-cli-surface.md:1-15`). Released subcommands consumed
  today: `render`, `install`, `uninstall`, `doctor`, `audit-drift`,
  `gc-backups`, `restore-backups`, `purge-state`
  (`docs/source/nils-cli-surface.md:33`).
- Per-skill nils-cli floors come from `manifests/skills.yaml`
  `required_clis` (e.g. `agent-out: ">=0.13.0"`,
  `agent-docs: ">=0.16.0"`). These gate skill bodies, not the harness
  load path.

## Surface-By-Surface Shape

Each section below answers the same four questions so a future schema
can pivot to a uniform table:

1. **Claude reads from** — runtime discovery path.
2. **arkit source** — checked-in artifact (`-` if none).
3. **arkit install mechanism** — link-map entry kind or render-time
   handling.
4. **Acceptance lane** — what gates the surface today.

### 1. Home-scope prompt (`CLAUDE.md`)

- Claude reads from: `$HOME/.claude/CLAUDE.md` on every session start
  (`docs/source/inventory-target-architecture.md:222-235`).
- arkit source: root `AGENT_HOME.md` (shared with Codex
  `$CODEX_HOME/AGENTS.md`); see `DEVELOPMENT.md:36-41`.
- arkit install mechanism: symlink `$HOME/.claude/CLAUDE.md →
  <source_root>/AGENT_HOME.md`. Filename is deliberately distinct from
  project-local `CLAUDE.md` so Claude does not load duplicate policy in
  this repo.
- Acceptance lane: covered by the cross-product home-policy cutover
  plans; no dedicated CI gate diffs the link target.
- arkit support today: **shipped (linked)**.

### 2. Project-scope prompt (`./CLAUDE.md`)

- Claude reads from: `<repo>/CLAUDE.md` for repo-local policy.
- arkit source: `./CLAUDE.md` in this repo is a symlink to
  `./AGENTS.md` (the project-local Codex/Claude shared file).
- Install mechanism: not installed by `agent-runtime`; it ships as
  part of the repo working tree.
- Acceptance lane: covered indirectly by any test that opens this
  repo with Claude; no specific gate.
- arkit support today: **shipped (linked, repo-local only)**.

### 3. Plugin manifest (`.claude-plugin/plugin.json`)

- Claude reads from: `${CLAUDE_PLUGIN_ROOT}/<plugin>/.claude-plugin/plugin.json`
  at runtime (`manifests/product-capabilities.yaml:47-54`,
  `loaded_at_runtime: true`).
- arkit source: `targets/claude/plugins/<plugin>/.claude-plugin/plugin.json`
  — 10 plugins enumerated (`manifests/plugins.yaml:12-135`).
- Install mechanism: `plugin-manifest-copy` per plugin (e.g.
  `targets/claude/link-map.yaml:15-18` for reporting; same pattern for
  meta, media, browser, conversation, evidence, issue, code-review, pr,
  dispatch).
- Schema: local `core/docs/schemas/claude-plugin.schema.json`
  (`manifests/product-capabilities.yaml:54`).
- Acceptance lane: drift audit + plugin schema validation (CI gate
  position 5, `DEVELOPMENT.md:163`); sandbox install rehearsal verifies
  the loader still accepts the manifest (CI gate position 7,
  `DEVELOPMENT.md:165`).
- arkit support today: **shipped (rendered + copy-installed)**.

### 4. Plugin marketplace (`.claude-plugin/marketplace.json`)

- Claude reads from: `$HOME/.claude/.claude-plugin/marketplace.json` for
  marketplace-managed plugin discovery
  (`manifests/product-capabilities.yaml:59-63`).
- arkit source: `targets/claude/.claude-plugin/marketplace.json` (lists
  all 10 plugins; `claude-kit` namespace).
- Install mechanism: `plugin-manifest-copy`
  (`targets/claude/link-map.yaml:130-133`, `id: claude-kit.marketplace`).
- Acceptance lane: drift audit checks the file; sandbox install
  rehearsal indirectly validates load.
- arkit support today: **shipped (rendered + copy-installed)**. Codex
  has no analogue (`manifests/product-capabilities.yaml:43`).

### 5. Plugin-scoped skills (`<plugin>/skills/<skill>/SKILL.md`)

- Claude reads from: `${CLAUDE_PLUGIN_ROOT}/<plugin>/skills/<skill>/`
  for plugin-scoped skill discovery
  (`manifests/product-capabilities.yaml:62`).
- arkit source: `core/skills/<domain>/<skill>/` (10 plugin domains,
  reporting + meta + media + browser + conversation + evidence + issue +
  code-review + pr + dispatch); rendered into
  `build/claude/plugins/<plugin>/skills/<skill>/`.
- Install mechanism: `symlinked-file` with `recursive: true` per plugin
  (`targets/claude/link-map.yaml:20-24` for reporting; same for the
  other nine plugins). One symlink per rendered skill file in the
  install plan output.
- Acceptance lane: render output (CI position 3); render-golden
  (position 4); drift audit (position 5); sandbox install rehearsal
  diffs `~/.claude` skill-list output (position 7); runtime-smoke
  deterministic mode exercises representative skills (position 8,
  `DEVELOPMENT.md:166`).
- arkit support today: **shipped (rendered + recursive symlink)**.

### 6. Slash command files (`commands/<name>.md` outside skills)

- Claude reads from: `$HOME/.claude/commands/<name>.md` and
  `${CLAUDE_PLUGIN_ROOT}/<plugin>/commands/<name>.md` for slash commands
  declared independently of skills
  (`docs/source/inventory-target-architecture.md:228-230`, legacy
  claude-kit surface family).
- arkit source: **none** — no `commands/` tree under `targets/claude/`
  or `core/`. The runtime-kit model treats skill bodies as the slash
  command surface; standalone command `.md` files are not part of the
  shipped contract.
- Install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not shipped**. Claude harness allows it; this
  repo does not ship into it.

### 7. Subagent definitions (`agents/<name>.md`)

- Claude reads from: `$HOME/.claude/agents/<name>.md` and
  `${CLAUDE_PLUGIN_ROOT}/<plugin>/agents/<name>.md` for subagents
  invokable via the Agent tool
  (`docs/source/inventory-target-architecture.md:226-228`).
- arkit source: **none** — no `agents/` tree under `targets/claude/` or
  `core/`. Subagent definitions are absent from the runtime-kit source.
- Install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not shipped**. Claude-only primitive; absent
  from this repo by design today.

### 8. Hook scripts (`hooks/<name>.*`)

- Claude reads from: `$HOME/.claude/hooks/<name>.*` referenced by
  `settings.json` `hooks` block
  (`manifests/product-capabilities.yaml:55-58`).
- arkit source: portable logic under `core/hooks/shared/`; Claude
  adapter slot reserved under `core/hooks/claude/` (`core/hooks/` tree
  present in repo).
- Install mechanism: `symlinked-file`
  (`targets/claude/link-map.yaml:125-128`, `id: hooks.shared-scripts`,
  source `core/hooks/shared` → `$HOME/.claude/hooks`).
  Per-product adapters expected under `targets/claude/hooks/` per
  Resolved Decision #4
  (`docs/source/inventory-target-architecture.md:1969-1973`); no files
  shipped under that path yet.
- Acceptance lane: hooks adapter contract tests
  (`bash tests/hooks/run.sh`, CI position 10, `DEVELOPMENT.md:168`).
- arkit support today: **shipped (shared scripts symlinked)**;
  Claude-specific adapter slot is **planned-not-shipped** (manifest +
  link-map describe it; no `targets/claude/hooks/` files exist today).

### 9. Hook registration (`settings.json` `hooks` block)

- Claude reads from: `$HOME/.claude/settings.json` `hooks` block plus
  `statusLine`, etc. (`manifests/product-capabilities.yaml:55-58`,
  `hook_config_strategy: settings-json` in
  `manifests/runtime-roots.yaml:34`).
- arkit source: no `targets/claude/settings.json` or
  `settings.json.template` exists today (search results above). The
  inventory doc lists `settings.json.template` as the expected source
  (`docs/source/inventory-target-architecture.md:448-454`).
- Install mechanism: managed-block contract described
  (`docs/source/inventory-target-architecture.md:1256-1271`) — paired
  `# >>> agent-runtime-kit:<surface> >>>` / `<<<` markers. Not yet wired
  in the Claude link-map.
- Acceptance lane: drift audit covers managed-block presence
  (`docs/source/inventory-target-architecture.md:1322-1326`); no
  shipped fixture exists yet.
- arkit support today: **planned-not-shipped**. Contract defined,
  template artifact absent.

### 10. Output styles (`output-styles/<name>.md`)

- Claude reads from: `$HOME/.claude/output-styles/<name>.md`
  (`docs/source/inventory-target-architecture.md:232`).
- arkit source: **none**.
- Install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not shipped**. Claude-only primitive.

### 11. Status line (`statusLine` in `settings.json`)

- Claude reads from: `$HOME/.claude/settings.json` `statusLine` block
  (`docs/source/inventory-target-architecture.md:233`).
- arkit source: **none** (same gap as the `settings.json` template
  itself).
- Install mechanism: not installed.
- Acceptance lane: none.
- arkit support today: **not shipped**.

### 12. MCP servers (per-user MCP config)

- Claude reads from: per-user MCP config managed via Claude CLI; not
  part of `settings.json` first-class blocks.
- arkit source: **none** — runtime-kit does not template MCP servers.
- Install mechanism: not installed; per-user MCP credentials are
  classified as sensitive
  (`docs/source/inventory-target-architecture.md:1460-1465`).
- Acceptance lane: none.
- arkit support today: **not shipped**. Out-of-scope by design (secret
  boundary).

### 13. Heuristic system (curated retained records)

- Claude reads from: `$HOME/.claude/HEURISTIC_SYSTEM.md` plus
  `heuristic-system/operation-records/`,
  `heuristic-system/error-inbox/`
  (`docs/source/inventory-target-architecture.md:236-249`).
- arkit source: shared root under
  `core/policies/heuristic-system/` (HEURISTIC_SYSTEM.md +
  error-inbox + operation-records).
- Install mechanism: Currently a docs surface; consumed via the
  `heuristic-inbox` nils-cli binary with explicit `--inbox-dir`
  arguments rather than a fixed install path
  (`docs/source/inventory-target-architecture.md:951-956`).
- Acceptance lane: runtime-smoke deterministic mode exercises the
  `heuristic-inbox` skill (position 8 / meta domain).
- arkit support today: **shipped (shared policy root)**.

### 14. Runtime state (`state_home`)

- Claude reads from: not directly — `state_home` is owned by
  skills/hooks via `agent-out` and product-specific env vars
  (`CLAUDE_KIT_STATE_HOME`).
- arkit source: contract in `manifests/runtime-roots.yaml:32-33` and
  `manifests/product-capabilities.yaml:64-67`.
- Install mechanism: `agent-runtime install` sets the env var via the
  managed block; `agent-out` allocates artifact paths at runtime
  (`docs/source/inventory-target-architecture.md:1080-1109`).
- Acceptance lane: drift audit + doctor verify resolution; backup
  retention reported by `doctor`
  (`docs/source/inventory-target-architecture.md:1311-1366`).
- arkit support today: **shipped (env var + runtime allocator)**.

## arkit Coverage Summary

| # | Surface | arkit ships | Mechanism | Min Claude | Min nils-cli |
|---|---|---|---|---|---|
| 1 | `CLAUDE.md` (home) | yes | symlink to `AGENT_HOME.md` | 2.1.145 | n/a |
| 2 | `./CLAUDE.md` (repo-local) | yes | symlink to `./AGENTS.md` | 2.1.145 | n/a |
| 3 | `.claude-plugin/plugin.json` | yes | rendered + copy-install | 2.1.145 | v0.17.5 |
| 4 | `.claude-plugin/marketplace.json` | yes | rendered + copy-install | 2.1.145 | v0.17.5 |
| 5 | `plugins/<p>/skills/<s>/` | yes | rendered + recursive symlink | 2.1.145 | v0.17.5 |
| 6 | `commands/<n>.md` | no | — | n/a | n/a |
| 7 | `agents/<n>.md` | no | — | n/a | n/a |
| 8 | `hooks/<n>.*` scripts | partial | shared scripts linked; claude adapter slot empty | 2.1.145 | v0.17.5 |
| 9 | `settings.json` managed block | planned-not-shipped | — | 2.1.145 | v0.17.5 |
| 10 | `output-styles/<n>.md` | no | — | n/a | n/a |
| 11 | `statusLine` | no | — | n/a | n/a |
| 12 | MCP servers | no | — | n/a | n/a |
| 13 | Heuristic system | yes | shared policy root | 2.1.145 | v0.17.5 (heuristic-inbox) |
| 14 | `state_home` | yes | env var + `agent-out` allocation | 2.1.145 | v0.17.5 (`agent-out >=0.13.0` floor in skills.yaml) |

Status legend:

- **yes** — concrete source artifact + link-map entry + acceptance
  lane.
- **partial** — some sub-surfaces present, others reserved but empty.
- **planned-not-shipped** — contract defined in inventory / manifests
  but no source artifact yet.
- **no** — Claude harness primitive that arkit does not target; not
  on the current roadmap unless added explicitly.

## Acceptance Lanes (Claude-Relevant CI Gates)

From `DEVELOPMENT.md:157-168`:

1. `plan-tooling validate` — covers manifest schemas.
2. `agent-runtime render --product codex` — not Claude-side.
3. **`agent-runtime render --product claude`** — render gate.
4. **render-golden refresh + `git diff --exit-code`** — render
   determinism gate (Resolved Decision #9).
5. **`agent-runtime audit-drift` + fixtures** — drift audit gate
   (includes Claude plugin manifest schema diff).
6. `agent-runtime doctor --class skill-surface --product codex` —
   Codex-only today; **no Claude-side skill-surface diagnostic** in the
   default gate.
7. **sandbox install rehearsal** — installs into a temp `live_home`,
   diffs `tests/sandbox/claude/expected-skills.txt`
   (`DEVELOPMENT.md:209-214`).
8. **runtime-smoke deterministic mode** — exercises representative
   Claude-installed skills.
9. project-local overlay smoke — Codex-side; not Claude.
10. **`bash tests/hooks/run.sh`** — hook adapter contract tests.

Quarantined (not in default CI):

- `bash tests/runtime-smoke/run.sh --mode product --product claude`
  (`DEVELOPMENT.md:235-242`); `--probe-only` validates isolated CLI
  invocation. Prompt execution requires `RUNTIME_SMOKE_PRODUCT_EXECUTE=1`
  plus isolated provider/auth.

Live Claude acceptance (a fresh Claude session reading the installed
surface) has no in-tree CI gate today. The closest analogue on the
Codex side is `codex debug prompt-input` in
`docs/plans/codex-skill-surface-acceptance-cutover/`; no equivalent
Claude protocol exists yet.

## Open Items For Schema Design

Things that will need a column when the unified
`SUPPORT_MATRIX.md` schema is drafted:

- A `support_state` enum that includes
  `shipped`, `partial`, `planned-not-shipped`, `not-shipped`, and
  `not-applicable` (Codex needs `not-applicable` for primitives like
  marketplace).
- A `source_artifact` field that can hold multiple paths (skills
  surface = source + render-to + link-map all three).
- A `min_nils_cli` field that may be tighter than the surface-level
  pin when a specific `required_clis` floor dominates (skills 5, 13,
  14 above).
- A `live_acceptance` field separate from `ci_acceptance` so the
  "Codex Desktop / live Claude session" gap is visible at a glance.
- A pointer back to the source manifest so doctor / drift audit can
  read the matrix without re-deriving facts.
