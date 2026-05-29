# Agentmemory Managed Cross-Agent Memory Integration — Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-29
- Source: user-driven design session evaluating cross-agent memory
  options for a machine that runs Claude Code and Codex side by side.
  The user already operates a file-based cross-agent memory layer
  (`AGENT_HOME.md` symlinked into both homes; curated Markdown store
  in the separate `graysurf/agent-memory` repo at
  `~/.config/agent-memory/`). The question was whether and how to
  adopt `agentmemory` (the third-party persistent-memory tool) as a
  managed mechanism, and which config repo should own it.
- Intended next step: generate the single-plan bundle under
  `docs/plans/2026-05-29-agentmemory-managed-integration/`, then open
  the tracking issue via `create-plan-tracking-issue` against
  `graysurf/agent-runtime-kit`. This is a source artifact, not an
  implementation plan.

## Execution

This document feeds **one** plan executed in four sequential sprints
(isolated validation spike → integration source model → wiring
implementation → opt-in rollout), all landing in
`graysurf/agent-runtime-kit`.

- Recommended plan: docs/plans/2026-05-29-agentmemory-managed-integration/2026-05-29-agentmemory-managed-integration-plan.md
- Recommended execution state: docs/plans/2026-05-29-agentmemory-managed-integration/2026-05-29-agentmemory-managed-integration-execution-state.md
- Status: spike-first; Sprint 1 findings gate the manifest model
  chosen in Sprint 2.
- Next-task source: this document

## Purpose

Give Claude Code and Codex a shared, auto-captured, semantically
searchable memory without breaking the boundaries either config repo
already enforces. `agentmemory` is the candidate mechanism; the work
is to wire it as a **managed, opt-in integration** in the runtime
layer, not to vendor the tool or its data.

## Evidence

External facts about `agentmemory` (verified against the project's
README on 2026-05-29):

- [A1] `agentmemory` stores memory in **local SQLite + an in-memory
  vector index** ("0 external DBs"); no Postgres / external vector DB
  dependency. Data persists under `~/.agentmemory/` by default.
- [A2] The **vector / semantic search uses a local embedding model**
  (`all-MiniLM-L6-v2` / BGE-small via `@xenova/transformers`,
  `EMBEDDING_PROVIDER=local` default), on-device, **no API key**. The
  model downloads once on first run.
- [A3] An **LLM provider is optional and disabled by default** ("no
  LLM calls are made unless you configure a provider"); without one,
  BM25 synthetic compression + keyword + vector recall still work.
  Optional LLM compression can target local Ollama.
- [A4] Consumption is via **MCP server (53 tools) + REST API (125
  endpoints on :3111) + hooks (12 Claude / 6 Codex)**. There is **no
  pure library/CLI-only mode**: a local background server on `:3111`
  must run; the MCP shim degrades to a 7-tool local set with no
  server.
- [A5] Install is `npm install -g @agentmemory/agentmemory`; start
  with `agentmemory` (binds `127.0.0.1`). Fully local / offline-capable
  end to end (Node.js + iii-engine + SQLite + local embeddings).
- [W1] In the broader market, `Mem0` leads general agent-memory
  frameworks (~48-50k stars); `agentmemory` is the most-discussed
  tool specifically for cross-coding-agent (Claude Code + Codex)
  shared memory (~19.4k stars at snapshot). Star counts and the tool's
  self-reported "#1 / 95.2% R@5 LongMemEval-S" are time-sensitive,
  self-published, and must be re-validated on the user's own machine.

Repository anchors in `graysurf/agent-runtime-kit` (inspected
2026-05-29):

- [F1] `core/hooks/shared/` is the canonical source for Codex+Claude
  shared hook logic; product activation lives in
  `targets/<product>/hooks/` and link maps. Claude uses
  `core/hooks/claude/settings.hooks.jsonc` rendered into settings.json;
  Codex uses a managed block in `config.toml`
  (`hook_config_strategy: managed-block` in
  `manifests/runtime-roots.yaml`).
- [F2] `manifests/plugins.yaml` is **skill-centric** — every entry
  requires `contained_skills` + per-product `product_manifests`.
  `agentmemory` ships no skills (it is hooks + a daemon), so it does
  not fit the plugin schema.
- [F3] `manifests/runtime-roots.yaml` defines a per-product
  `state_home` under
  `${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/<product>` —
  the correct home for any agentmemory runtime data.
- [F4] `.gitignore` already excludes `build/`, secrets, `**/cache/`,
  `**/sessions/`, `**/history/`, `.env*`. The repo's stated boundary
  is "do not track runtime state: auth, history, sessions, logs,
  caches, plugin install artifacts, or secrets."
- [F5] `drift-audit.allow.yaml` + `tests/drift` gate live-home
  mutation; install/link flow through `scripts/setup.sh` and
  `scripts/sync-runtime-skills.sh` with a dry-run-first contract.

## Decisions

- [D1] The **mechanism/wiring** for agentmemory lands in
  `graysurf/agent-runtime-kit` (not `agent-memory`), because hooks,
  install/link, drift audit, version floors, and dual-product
  rendering are this repo's mandate. This also dissolves the
  managed-hook-block conflict that would arise if agentmemory's own
  installer wrote into the homes directly.
- [D2] agentmemory **runtime state** (SQLite store, daemon pid/log,
  the npm-installed package, captured transcripts) is **never
  tracked**. Its data dir points at the product `state_home` from
  `runtime-roots.yaml` and is gitignored — same treatment as plugin
  install artifacts. [F3][F4]
- [D3] The **curated-markdown memory semantics** and the auto-vs-curated
  role split stay in the separate `graysurf/agent-memory` repo; this
  integration only cross-references it. agent-runtime-kit does not
  absorb the curated store.
- [D4] agentmemory is modeled as a **new lightweight "integration"**,
  not a `plugins.yaml` entry, because the plugin schema is
  skill-centric. The exact model (a new `manifests/integrations.yaml`
  plus schema, versus a hook-fragment plus launcher plus
  managed-config-block layout) is decided after the Sprint 1 spike.
  [F2]
- [D5] **Third-party hook drift is controlled**: pin the agentmemory
  version, and treat its hook fragments as managed source rendered by
  this repo rather than letting `npm update` rewrite the homes'
  managed blocks. [F1][D1]
- [D6] **Rollout is staged and conservative**: `install_policy`
  opt-in / disabled-by-default, dry-run-first, validated in an
  isolated home before any promotion to the live runtime surface.
- [D7] agentmemory is adopted **only if** the Sprint 1 spike confirms
  it runs with zero external API keys, local embeddings, and an
  acceptable hook/daemon footprint on the user's machine; otherwise
  fall back to a lighter Markdown-only option (observational-memory /
  Basic Memory) or extend the existing symlink/pointer sharing.

## Open Questions (carried into execution)

- [O1] Manifest model: introduce `manifests/integrations.yaml` plus a
  new schema, or express agentmemory purely as hook fragments, a
  launcher, and a managed config block with no new manifest type?
  Resolved in Sprint 2 using Sprint 1 findings.
- [O2] Daemon lifecycle ownership: who starts/stops the `:3111`
  daemon — a shell launcher (parallel to
  `shell/agent-memory.zsh` in the agent-memory repo), a
  `targets/<product>/scripts/` script, or a SessionStart hook? Decided
  in Sprint 3.
- [O3] Whether deep `nils-cli agent-memory` command integration is
  warranted at all; current decision keeps it out of scope (docs +
  wiring only).

## Recommended Next Artifact

Open the tracking issue with `create-plan-tracking-issue` against
`graysurf/agent-runtime-kit` using this bundle, labels `type::chore`,
`area::*` (runtime/hooks), `state::needs-triage`, `workflow::plan`,
`workflow::tracking`.
