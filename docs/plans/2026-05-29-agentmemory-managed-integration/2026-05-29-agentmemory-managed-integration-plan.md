# Plan: Agentmemory Managed Cross-Agent Memory Integration

## Overview

Adopt `agentmemory` as an **opt-in, managed cross-agent memory
mechanism** for Claude Code and Codex, owned by
`graysurf/agent-runtime-kit`. The runtime layer already owns the
hooks, install/link, drift audit, version floors, and dual-product
rendering that a cross-agent tool needs; landing agentmemory's wiring
here (rather than letting its own installer write into the homes)
dissolves the managed-hook-block conflict and keeps the integration
reproducible and drift-audited.

Three boundaries shape the work:

- **Mechanism in, data out.** agentmemory's cross-agent wiring (capture
  hooks, dual-target render, install/link, drift entry, version pin)
  is tracked here. Its **runtime state** — local SQLite store, daemon
  pid/log, the npm-installed package, captured transcripts — is never
  tracked; it points at the product `state_home` from
  `manifests/runtime-roots.yaml` and is gitignored, exactly like
  plugin install artifacts.
- **Curated semantics stay in `agent-memory`.** The hand-curated
  Markdown memory taxonomy and the auto-vs-curated role split remain
  in the separate `graysurf/agent-memory` repo, cross-referenced only.
- **Conservative rollout.** Because `manifests/plugins.yaml` is
  skill-centric and agentmemory ships no skills, it is modeled as a
  new lightweight "integration". Rollout is `install_policy` opt-in /
  disabled-by-default, dry-run-first, and validated in an isolated
  home before any promotion to the live runtime surface.

A spike comes first: Sprint 1 confirms agentmemory runs with zero
external API keys (local embeddings, optional/disabled LLM, BM25
fallback) and an acceptable hook + `:3111` daemon footprint on the
user's machine. Its findings gate the manifest model chosen in
Sprint 2. If the spike fails the adoption criteria, the plan stops at
the Sprint 1 decision gate and the fallback (Markdown-only sharing)
is recorded instead.

## Read First

- Primary source:
  `docs/plans/2026-05-29-agentmemory-managed-integration/2026-05-29-agentmemory-managed-integration-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Related repo (curated memory store, out of scope for edits here):
  `graysurf/agent-memory` (`~/.config/agent-memory/`)
- Repo anchors:
  - `core/hooks/shared/` + `core/hooks/claude/settings.hooks.jsonc` +
    `targets/codex/hooks/config.block.toml` (hook source + render)
  - `manifests/plugins.yaml` (skill-centric; agentmemory does not fit)
  - `manifests/runtime-roots.yaml` (`state_home` per product)
  - `drift-audit.allow.yaml`, `tests/drift`, `scripts/setup.sh`
  - `.gitignore` (runtime-state exclusions)
- Key decisions carried into execution (from the discussion source's
  Decisions section):
  - [D1] agentmemory mechanism/wiring lands in `agent-runtime-kit`.
  - [D2] agentmemory runtime state is never tracked; data dir points
    at `runtime-roots` `state_home` and is gitignored.
  - [D3] Curated-markdown semantics stay in `agent-memory`,
    cross-referenced only.
  - [D4] agentmemory is modeled as a new lightweight "integration",
    not a `plugins.yaml` entry; exact model decided in Sprint 2.
  - [D5] Third-party hook drift controlled via version pin + managed
    hook fragments rendered by this repo.
  - [D6] Rollout is opt-in / disabled-by-default, dry-run-first,
    isolated-validation-first.
  - [D7] Adopt only if the Sprint 1 spike passes the local /
    zero-API / footprint criteria; otherwise fall back to
    Markdown-only sharing.
- Open questions carried into execution:
  - [O1] `manifests/integrations.yaml` + schema vs. hook-fragment +
    launcher + managed-config-block only (resolved Sprint 2).
  - [O2] Daemon lifecycle owner: shell launcher vs.
    `targets/<product>/scripts/` vs. SessionStart hook (resolved
    Sprint 3).
  - [O3] Deep `nils-cli agent-memory` command integration — currently
    out of scope.

## Scope

- In scope:
  - **Sprint 1 (`agent-runtime-kit`, spike + findings doc)**
    - Install agentmemory in an isolated, throwaway home and confirm
      [A2][A3][A5]: local embeddings, no external API key, optional
      LLM disabled, `:3111` daemon binds `127.0.0.1`.
    - Enumerate the exact hook footprint it wants in each home and the
      precise data-dir layout under `~/.agentmemory/`.
    - Write a findings doc under `docs/source/` and a Sprint 1
      decision-gate verdict (adopt / fall back).
  - **Sprint 2 (`agent-runtime-kit`, source model)**
    - Resolve [O1] and add the chosen integration model: either a new
      `manifests/integrations.yaml` + `core/docs/schemas/`
      integrations schema, or a documented hook-fragment + launcher +
      managed-config-block layout — with agentmemory registered
      `install_policy: opt-in` / disabled by default.
    - Author the integration design doc under `docs/source/`.
  - **Sprint 3 (`agent-runtime-kit`, wiring)**
    - Source agentmemory's capture hook fragments as managed source
      and render them to both products (Claude settings.hooks.jsonc
      fragment + Codex managed block), pinned to a fixed version.
    - Add a launcher/config surface that starts the `:3111` daemon
      with its data dir pointed at the product `state_home`.
    - Add `.gitignore` and `drift-audit.allow.yaml` entries so no
      runtime state is tracked and the rendered surfaces pass drift.
  - **Sprint 4 (`agent-runtime-kit`, rollout + delivery)**
    - Cross-reference the `agent-memory` repo's curated store and the
      auto-vs-curated role split (pointer doc here; content owned
      there).
    - Wire the opt-in enable path through `scripts/setup.sh` (or the
      sync flow) behind a dry-run gate; document enable/disable.
    - Add the smallest meaningful tests (drift + a render/golden or
      smoke probe); update `README.md` / `DEVELOPMENT.md`; commit via
      `semantic-commit` (no `Co-Authored-By` trailer); deliver via
      the active PR delivery skill (`forge-cli pr deliver`).
- Out of scope (see
  [Future Work](#future-work-out-of-scope-for-this-tracker)):
  - Any edits to the `graysurf/agent-memory` repo's curated store.
  - Deep `nils-cli agent-memory` command integration ([O3]).
  - Cloud/managed memory backends (Mem0 / Zep / Letta) and any LLM
    provider key wiring.
  - Enabling agentmemory by default across all sessions.
  - Migrating existing curated Markdown memory into agentmemory's
    SQLite store.

## Assumptions

1. agentmemory's published behavior matches its README on 2026-05-29
   ([A1]-[A5]); the Sprint 1 spike re-validates the load-bearing
   claims (local embeddings, zero external API, `:3111` daemon) before
   any wiring is written.
2. `manifests/runtime-roots.yaml` `state_home` resolution is the
   correct, stable home for third-party runtime data on this machine.
3. agentmemory exposes a configurable data directory and a
   configurable embedding provider (`EMBEDDING_PROVIDER=local`) so its
   store can be relocated under `state_home` without code changes.
4. The repo's existing dry-run-first install/link/render and drift
   contracts can express an opt-in integration without new
   infrastructure beyond one manifest/schema addition.
5. The user accepts running one local background daemon (`:3111`) as
   the cost of auto-capture + semantic recall; the symlink-only
   fallback remains available if not.
6. `bash scripts/ci/all.sh` and the repo's render/golden + drift
   checks remain the gating validation surface.

## Sprint 1: Isolated Validation Spike (agent-runtime-kit)

**Goal**: Prove agentmemory runs fully local with zero external API
keys and an acceptable hook + `:3111` daemon footprint on the user's
machine, and record an explicit adopt-or-fall-back verdict before any
managed wiring is written.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Install and run agentmemory in an isolated home

- **Location**:
  - Isolated throwaway dir under the product `state_home` (the XDG
    state path from `manifests/runtime-roots.yaml`), not the live
    `~/.claude` or `~/.codex` homes.
- **Description**: Install `agentmemory`
  (`npm install -g @agentmemory/agentmemory` or `npx`) and start the
  daemon with `AGENTMEMORY` data/home env pointed at an isolated dir.
  Capture the actual on-disk layout, the listening socket, and the
  first-run embedding-model download. Do not touch the live runtime
  homes or their managed blocks.
- **Dependencies**:
  - none
- **Complexity**: 2
- **Acceptance criteria**:
  - agentmemory starts and binds `127.0.0.1:3111`; data lands only in
    the isolated dir.
  - The embedding model downloads once locally; recall works after.
  - No write occurs to `~/.claude/settings.json` or
    `~/.codex/config.toml` during the spike.
- **Validation**:
  - `lsof -iTCP:3111 -sTCP:LISTEN` (or equivalent) shows the local
    daemon; directory listing confirms the isolated data dir.

### Task 1.2: Verify zero external API + capture network/footprint evidence

- **Location**:
  - Spike findings notes (scratch, promoted into Task 1.3 doc).
- **Description**: Exercise capture + recall with no LLM provider
  configured and confirm BM25 + local-vector recall works ([A2][A3]).
  Observe outbound network (e.g. simple egress logging) to confirm no
  API calls beyond the one-time model fetch. Enumerate the exact hook
  set agentmemory wants in each home ([A4]: 12 Claude / 6 Codex) and
  the npm install artifact location.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Capture + recall succeed with `EMBEDDING_PROVIDER=local` and no
    LLM provider set.
  - No external API key is required at any point; no unexpected
    outbound calls observed after first-run model download.
  - The hook footprint and data/artifact paths are enumerated
    concretely.
- **Validation**:
  - Recall returns a previously captured fact; egress observation
    shows no API endpoints contacted post-bootstrap.

### Task 1.3: Findings doc + decision gate

- **Location**:
  - `docs/source/agentmemory-integration-spike.md`
- **Description**: Write the spike findings (real paths, footprint,
  daemon behavior, embedding/LLM modes) and a clear verdict against
  [D7]: adopt and proceed to Sprint 2, or fall back to Markdown-only
  sharing and stop. Record any deviations from [A1]-[A5].
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 1
- **Acceptance criteria**:
  - The doc states a binary verdict and the evidence behind it.
  - If "fall back", the plan stops here and Future Work captures the
    Markdown-only path; Sprints 2-4 are marked waived.
- **Validation**:
  - `rumdl check docs/source/agentmemory-integration-spike.md`.

## Sprint 2: Integration Source Model (agent-runtime-kit)

**Goal**: Resolve [O1] and land the source-of-truth model for
agentmemory as a disabled-by-default managed integration.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Decide and document the integration model

- **Location**:
  - `docs/source/agentmemory-integration-design.md`
- **Description**: Using Sprint 1 findings, choose between (a) a new
  `manifests/integrations.yaml` + a `core/docs/schemas/` integrations
  schema, or (b) a hook-fragment + launcher + managed-config-block
  layout with no new manifest type. Record the decision, the rejected
  option, and how the model expresses `install_policy: opt-in`,
  version pinning ([D5]), and `state_home` data placement ([D2]).
- **Dependencies**:
  - Task 1.3 (adopt verdict)
- **Complexity**: 2
- **Acceptance criteria**:
  - The design doc names the chosen model and the disabled-by-default
    contract, and references the exact repo surfaces it will touch in
    Sprint 3.
- **Validation**:
  - `rumdl check docs/source/agentmemory-integration-design.md`.

### Task 2.2: Add the integration registration (disabled)

- **Location**:
  - `manifests/integrations.yaml` (+ `core/docs/schemas/` schema) OR
    the hook-fragment/launcher source location chosen in Task 2.1.
- **Description**: Register agentmemory as a managed integration with
  `install_policy: opt-in` / disabled by default, a pinned version,
  and a `state_home`-based data dir. No live-home mutation; rendering
  remains inert until explicitly enabled.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - The new manifest/schema (or source layout) validates against the
    repo's schema/governance checks.
  - The integration is present but disabled: a dry-run install/render
    produces no change to the live homes.
- **Validation**:
  - The repo's manifest/schema validator (or governance check) passes;
    `scripts/setup.sh --dry-run` (or the render dry-run) shows no
    live-home delta.

## Sprint 3: Wiring Implementation (agent-runtime-kit)

**Goal**: Render agentmemory's capture hooks and daemon launcher to
both products from managed source, with runtime state confined to
`state_home` and the surfaces drift-clean.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Source + render the capture hook fragments

- **Location**:
  - `core/hooks/shared/` (managed hook fragments) +
    `core/hooks/claude/settings.hooks.jsonc` +
    `targets/codex/hooks/config.block.toml`
- **Description**: Bring agentmemory's capture hooks under managed
  source (vendored fragments pinned to the chosen version per [D5]),
  and render them into the Claude settings hooks block and the Codex
  managed block via the existing link-map/render flow. Hooks stay
  inert unless the integration is enabled.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 3
- **Acceptance criteria**:
  - When enabled, both products invoke the agentmemory capture hooks
    through the repo's managed render, not agentmemory's own installer.
  - When disabled (default), no agentmemory hook entries appear in the
    rendered targets.
- **Validation**:
  - Render + golden check passes; rendered targets reflect the
    enabled/disabled state correctly.

### Task 3.2: Daemon launcher + state_home data placement

- **Location**:
  - `targets/claude/scripts/` and/or `targets/codex/scripts/` (or the
    launcher location chosen for [O2])
- **Description**: Add a launcher that starts/stops the `:3111` daemon
  with `AGENTMEMORY` data/home pointed at the product `state_home`
  ([D2][F3]) and `EMBEDDING_PROVIDER=local`. Resolve [O2] (shell
  launcher vs. target script vs. SessionStart hook) and document the
  chosen lifecycle.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 3
- **Acceptance criteria**:
  - The launcher writes agentmemory data only under `state_home`;
    nothing under the repo or the tracked homes.
  - Daemon start/stop is documented and idempotent.
- **Validation**:
  - Manual launcher run confirms data lands under `state_home` and the
    daemon binds `127.0.0.1:3111`.

### Task 3.3: gitignore + drift-allow + version pin

- **Location**:
  - `.gitignore`, `drift-audit.allow.yaml`,
    and the integration manifest's version field
- **Description**: Ensure agentmemory's SQLite store, logs, pid, and
  npm artifact are excluded from tracking ([D2][F4]); add any required
  `drift-audit.allow.yaml` entries so the rendered surfaces pass drift;
  confirm the pinned version is the single source of truth ([D5]).
- **Dependencies**:
  - Task 3.1
  - Task 3.2
- **Complexity**: 2
- **Acceptance criteria**:
  - `git status` shows no agentmemory runtime artifacts as tracked or
    untracked-to-be-added.
  - The drift audit passes with the new rendered surfaces.
- **Validation**:
  - `bash tests/drift/...` (or the repo's drift entrypoint) passes;
    `git status --porcelain` is clean of runtime state.

## Sprint 4: Opt-in Rollout and Delivery (agent-runtime-kit)

**Goal**: Make the integration safely enable-able, cross-reference the
curated store, validate end to end, and deliver one feature PR.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 4.1: Cross-reference the agent-memory curated store

- **Location**:
  - `docs/source/agentmemory-integration-design.md` (cross-ref
    section) and a short pointer in `README.md`
- **Description**: Document the auto-vs-curated role split ([D3]):
  `agent-memory`'s curated Markdown remains the human/version-controlled
  truth layer; agentmemory is the auto-capture + semantic-recall layer.
  Link to the `agent-memory` repo; do not duplicate its content here.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 1
- **Acceptance criteria**:
  - The role split and the repo boundary are stated with a link to
    `agent-memory`; no curated content is copied into this repo.
- **Validation**:
  - `rumdl check` on the touched Markdown files.

### Task 4.2: Opt-in enable path + docs

- **Location**:
  - `scripts/setup.sh` (or the sync flow) + `DEVELOPMENT.md`
- **Description**: Wire the explicit enable/disable path for the
  integration behind the dry-run-first contract ([D6]); document how
  to turn it on, verify, and turn it off. Default stays disabled.
- **Dependencies**:
  - Task 3.3
- **Complexity**: 2
- **Acceptance criteria**:
  - Enabling is an explicit, dry-run-previewable action; disabling
    fully reverts the rendered surfaces.
  - `DEVELOPMENT.md` documents the enable/verify/disable flow.
- **Validation**:
  - `scripts/setup.sh --dry-run` before/after enable shows the
    expected delta and a clean revert.

### Task 4.3: CI, commit, and delivery

- **Location**:
  - `agent-runtime-kit` repo gate
- **Description**: Run `bash scripts/ci/all.sh` plus the repo's
  render/golden + drift checks. Commit via `semantic-commit` (no
  `Co-Authored-By` trailer per home-scope feedback). Deliver via the
  active PR delivery skill (`forge-cli pr deliver --kind feature`);
  the PR body links this tracking issue and the Sprint 1 findings doc.
- **Dependencies**:
  - Task 4.1
  - Task 4.2
- **Complexity**: 2
- **Acceptance criteria**:
  - `scripts/ci/all.sh` and drift/render checks pass.
  - The PR merges through `forge-cli pr deliver --kind feature`.
  - The integration is present, opt-in, and disabled by default on
    merge.
- **Validation**:
  - PR workflow green; merge SHA recorded on the tracking issue via
    `tracking run update --note` and a final state checkpoint.

## Issue Closeout Gate

The tracking issue is complete when:

- Sprint 1 produced a recorded adopt-or-fall-back verdict
  (`docs/source/agentmemory-integration-spike.md`). If the verdict is
  "fall back", Sprints 2-4 are waived and the issue closes with the
  Markdown-only fallback recorded in Future Work.
- On "adopt": Sprints 2-4 land on `main` of `agent-runtime-kit`; the
  integration is registered `install_policy: opt-in` and disabled by
  default.
- No agentmemory runtime state (SQLite store, daemon log/pid, npm
  artifact, transcripts) is tracked; `git status --porcelain` is clean
  of it and the drift audit passes.
- `bash scripts/ci/all.sh` plus the repo's render/golden + drift
  checks are green.
- The plan's own `execution-state.md` ledger has every executed row at
  `done` with a non-empty `Evidence` cell; waived rows are marked
  `waived` with a reason.
- The closeout comment is preceded by a final
  `tracking run update --note "<closing summary>"` event in
  `events.jsonl`.

## Future Work (Out Of Scope For This Tracker)

- **Markdown-only fallback path.** If Sprint 1 returns "fall back",
  track the lighter option (observational-memory / Basic Memory via
  MCP, or extending the existing `agent-memory` symlink/pointer
  sharing to Codex) as its own discussion source.
- **Deep `nils-cli agent-memory` integration ([O3]).** Teaching the
  released `agent-memory` CLI about agentmemory (e.g. a `resolve` that
  reports both layers) belongs in `sympoies/nils-cli`, not here.
- **Enabling agentmemory by default.** Promotion from opt-in to
  always-on requires its own evaluation once the opt-in path has
  soaked.
- **Migrating curated Markdown into agentmemory.** Bulk import of the
  existing curated store into the SQLite layer is a separate,
  reversibility-sensitive task.
- **LLM-backed compression / Ollama wiring.** Optional LLM features
  ([A3]) are deferred; the integration ships with LLM disabled.

## Retention Intent

Plan-source coordination document. Cleanup-eligible after the tracker
closes (adopt-and-delivered or fall-back-recorded) and the issue
archives via `plan-archive-migrate`. If adopted, the Sprint 1 findings
doc and the integration design doc under `docs/source/` are the
durable artifacts and should be promoted/retained there independently
of this bundle.
