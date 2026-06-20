# Plan: Codex plugin/marketplace adoption

## Overview

Codex shipped a real plugin loader + plugin marketplace in 2026
(`codex plugin marketplace add`). runtime-kit already ships skills into Codex,
but through the flat `$CODEX_HOME/skills/<domain>/<skill>/` root (surface 15),
keeping `.codex-plugin/plugin.json` as audit-only metadata. This plan adopts
Codex's plugin/marketplace surface so Codex is activated the same way Claude
already is (render a loader-valid plugin tree + a Codex marketplace, then
`codex plugin marketplace add` it), and flips the capability model accordingly.
The flat skills root stays as a fallback until the plugin path is proven live.

## Read First
- Primary source: `docs/plans/2026-06-20-codex-plugin-marketplace-adoption/2026-06-20-codex-plugin-marketplace-adoption-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: whether to reverse Resolved Decision #10 (Task 1.1 decision gate); marketplace path choice `.agents/plugins/marketplace.json` vs legacy `.claude-plugin/marketplace.json` (Task 2.1)

## Scope
- In scope: Codex `plugin.json` schema alignment; `core/docs/schemas/codex-plugin.schema.json`; Codex marketplace render; `sync-runtime-surfaces.sh` Codex activation branch; capability-model flip (`marketplace_concept` / `loaded_at_runtime`) + matrix `state` enums + Resolved Decision #10 reversal; removing the PR #434 "pending" notes; acceptance lanes (golden, drift, sandbox, runtime-smoke).
- Out of scope: the Claude side (already shipped); changing the shared `SKILL.md` format; removing the flat `$CODEX_HOME/skills` root before the plugin path is proven live; any nils-cli public contract change beyond what the Codex render requires.

## Assumptions
1. Target host `codex-cli >= 0.141.0`, which ships `codex plugin marketplace add <SOURCE>` (local path / `owner/repo[@ref]` / HTTPS / SSH).
2. Rendering a Codex-loader-valid `plugin.json` may require a coupled `nils-cli` `agent-runtime` render change; if so it follows the DEVELOPMENT.md coupled-dev + pin-bump path.
3. Reversing Resolved Decision #10 is acceptable to the maintainer (confirmed at Task 1.1 before any capability flip).

## Sprint 1: Decision + Codex plugin manifest schema alignment
**Goal**: Confirm the Decision #10 reversal and make runtime-kit emit a Codex-loader-valid `plugin.json`.
**Demo/Validation**:
- Command(s): `codex plugin marketplace add <local marketplace>` against a rendered fixture; `codex plugin list`
- Verify: Codex accepts the rendered `plugin.json` and lists the runtime-kit plugins

### Task 1.1: Confirm and record the Resolved Decision #10 reversal
- **Location**:
  - `manifests/product-capabilities.yaml`
  - `core/docs/schemas/plugins.schema.json`
- **Description**: Decision gate — confirm runtime-kit will adopt Codex's plugin/marketplace surface, superseding Resolved Decision #10 ("Codex plugin.json is audit-only"). Record the reversal rationale.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Reversal decision recorded; the rest of the plan is unblocked, or the plan is closed if rejected
- **Validation**:
  - Decision text present and linked from the tracking issue

### Task 1.2: Align the Codex `plugin.json` render to the current loader schema
- **Location**:
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/meta/.codex-plugin/plugin.json` (representative; all 10 plugins)
  - `nils-cli` `agent-runtime` render (coupled, if the array-to-pointer shape is engine-side)
- **Description**: Replace the kit's `skills: [{id, source}]` audit array with Codex's current schema (`skills: "./skills/"` plus `interface` / `mcpServers` / `apps` / `hooks` as applicable).
- **Dependencies**:
  - Task 1.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Rendered `plugin.json` validates against Codex's loader (a sandbox `codex plugin marketplace add` + `codex plugin list` succeeds)
- **Validation**:
  - `agent-runtime render --product codex`; sandbox `codex plugin list`

### Task 1.3: Add `core/docs/schemas/codex-plugin.schema.json`
- **Location**:
  - `core/docs/schemas/codex-plugin.schema.json`
  - `manifests/product-capabilities.yaml` (`schema_ref`)
- **Description**: Author the currently-referenced-but-missing Codex plugin schema matching the aligned shape from 1.2; wire audit-drift to validate against it.
- **Dependencies**:
  - Task 1.2
- **Acceptance criteria**:
  - `agent-runtime audit-drift` validates Codex `plugin.json` against the new schema
- **Validation**:
  - `agent-runtime audit-drift`

## Sprint 2: Codex marketplace render + activation
**Goal**: Render a Codex marketplace and activate it via `codex plugin marketplace add`, mirroring the Claude block.
**Demo/Validation**:
- Command(s): `bash scripts/sync-runtime-surfaces.sh --product codex --apply`; `codex plugin marketplace list`
- Verify: the runtime-kit marketplace is registered and its plugins install

### Task 2.1: Render a Codex marketplace.json
- **Location**:
  - `targets/codex/.agents/plugins/marketplace.json` (candidate path; finalized in this task)
  - `manifests/surfaces.yaml` (row 4 codex)
  - `manifests/plugins.yaml`
- **Description**: Render a Codex marketplace listing the 10 plugins. Decide between canonical `.agents/plugins/marketplace.json` and reusing the legacy `.claude-plugin/marketplace.json` interop path.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Codex reads the rendered marketplace and lists runtime-kit plugins
- **Validation**:
  - `codex plugin marketplace list`

### Task 2.2: Add a Codex activation branch to `sync-runtime-surfaces.sh`
- **Location**:
  - `scripts/sync-runtime-surfaces.sh`
- **Description**: Mirror the Claude activation block (materialize a symlink-free marketplace under the Codex state home, `codex plugin marketplace add`, install each plugin). Dry-run by default; `--apply` to write.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 6
- **Acceptance criteria**:
  - `--product codex --apply` registers + installs; idempotent re-run
- **Validation**:
  - `bash scripts/sync-runtime-surfaces.sh --product codex --apply`; `codex plugin list`

### Task 2.3: Wire the Codex marketplace into the link-map / install plan
- **Location**:
  - `targets/codex/link-map.yaml`
- **Description**: Add the marketplace copy-install entry analogous to `claude-kit.marketplace`.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - `agent-runtime install --product codex` materializes the marketplace artifact
- **Validation**:
  - sandbox install rehearsal (Codex)

## Sprint 3: Capability-model flip + docs + acceptance
**Goal**: Flip the capability model, remove the PR #434 "pending" notes, and add acceptance coverage.
**Demo/Validation**:
- Command(s): `bash scripts/ci/all.sh`
- Verify: full gate green with the Codex plugin/marketplace surfaces marked shipped

### Task 3.1: Flip the Codex capability flags
- **Location**:
  - `manifests/product-capabilities.yaml`
  - `core/docs/schemas/product-capabilities.schema.json`
- **Description**: Set Codex `marketplace_concept: true` and `plugin_manifest.loaded_at_runtime: true`; remove the PR #434 "knowingly-stale" NOTE comments and the top-of-file pending NOTE.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - `agent-runtime audit-drift` accepts the flipped model
- **Validation**:
  - `agent-runtime audit-drift`

### Task 3.2: Promote matrix + harness-shape from "pending" to "shipped"
- **Location**:
  - `manifests/surfaces.yaml` (rows 3-5 codex `state` + `mechanism`)
  - `docs/source/harness-shape-codex.md`, `docs/source/harness-shape-claude.md`
  - `SUPPORT_MATRIX.md` + `tests/golden/shared/SUPPORT_MATRIX.md` (re-rendered)
- **Description**: Move rows 3-5 codex `state` to `shipped` (or `partial`) with accurate mechanism prose; remove the PR #434 dated "pending" Update note (or update it to "adopted"); re-render the matrix + golden.
- **Dependencies**:
  - Task 3.1
- **Acceptance criteria**:
  - Matrix + harness-shape describe the shipped Codex plugin/marketplace surface; render golden clean
- **Validation**:
  - `agent-runtime render --target support-matrix --update-golden`; `git diff --exit-code -- tests/golden/`

### Task 3.3: Add acceptance coverage for the Codex plugin/marketplace surface
- **Location**:
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/runtime-smoke/`
- **Description**: Extend sandbox install rehearsal + runtime-smoke to cover the Codex marketplace/plugin path; keep flat-root coverage during transition.
- **Dependencies**:
  - Task 3.2
- **Acceptance criteria**:
  - sandbox + runtime-smoke exercise the Codex plugin path
- **Validation**:
  - `bash scripts/ci/all.sh`; live `codex debug prompt-input`

## Testing Strategy
- Unit: schema validation (`codex-plugin.schema.json`) via audit-drift.
- Integration: render-golden, audit-drift, sandbox install rehearsal (Codex), `sync-runtime-surfaces.sh` Codex branch idempotency.
- E2E/manual: `codex plugin marketplace list` / `codex plugin list`; live `codex debug prompt-input` shows skills discovered via the plugin path.

## Risks & gotchas
- The Codex `plugin.json` schema change may be engine-side in `nils-cli`; if so, use the DEVELOPMENT.md coupled-dev loop (local binary) then a pin bump via `meta:nils-cli-bump` before final on-pin validation.
- Codex's plugin schema may evolve again; pin assumptions to the tested `codex-cli` version and record it.
- Do not remove the flat `$CODEX_HOME/skills` root (surface 15) until plugin discovery is proven live in a fresh Codex session.
- Marketplace path choice (`.agents/plugins/marketplace.json` vs legacy `.claude-plugin/marketplace.json`) affects portability; confirm in Task 2.1.

## Rollback plan
- Keep the flat skills root active throughout, so reverting the capability flip + marketplace render leaves Codex skill discovery working exactly as before PR #434. The `.codex-plugin/plugin.json` tree stays audit-only on rollback.
