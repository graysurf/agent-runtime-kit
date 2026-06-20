# Plan: Codex / Claude runtime divergence (per-product home render + agent-docs product dimension)

## Overview

Two CLIs read one shared source, but some user-side content must differ per
runtime. The canonical case: a Codex-only code-review-delegation authorization
that today lives verbatim in the raw-symlinked `AGENT_HOME.md` and is therefore
also loaded by Claude. The evaluation (the discussion source) resolved four
decisions in favor of the durable path:

- D1 — deliver per-product home content via a new nils-cli home-prompt render
  target (R1), keeping a product-neutral fallback.
- D2 — enforce isolation with a broad-sentinel cross-product leakage lint (A4).
- D3 — bump the agent-docs preflight contract to `agent-docs.preflight.v2`.
- D4 — build the agent-docs catalog `product` dimension now (C1).

This is one coupled nils-cli effort, gate-first: ship R1 + C1 upstream in
`sympoies/nils-cli`, release and bump the pin, then consume in this repo. It must
compose with the already-landed #436 (Codex plugin/marketplace adoption, gated by
`CODEX_PLUGIN_ACTIVATION`) without drift.

## Read First

- Primary source: `docs/plans/2026-06-20-codex-claude-runtime-divergence/2026-06-20-codex-claude-runtime-divergence-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: none — the four decisions (D1 per-product render home, D2 broad-sentinel lint, D3 preflight v2, D4 build C1 now) are resolved in the source.
- Execution note (2026-06-20): #436 (`f10e12b`, Codex plugin/marketplace adoption) landed on `main`. It flipped Codex `loaded_at_runtime` / `marketplace_concept` to `true` and added a gated `sync_codex_plugin_registry`. It did NOT touch the home prompt, agent-docs, or the hooks. This plan composes with it — see Risks & gotchas for the drift items and the reuse patterns.

## Scope

- In scope: R1 (a nils-cli home-prompt render target + the `setup.sh` cutover
  from raw symlink to per-product render); C1 (an agent-docs `product` field on
  `[[document]]`/`[[validation]]`, `preflight --product`, a one-place resolver
  filter, and `agent-docs.preflight.v2`); the broad-sentinel leakage lint;
  relocating the Codex-only code-review-delegation authorization into the Codex
  home render; hook `--product` forwarding with finish-line validation parity;
  the pin bump; and the golden / drift / matrix / harness-shape / runtime-smoke
  acceptance.
- Out of scope: per-product skill bodies via `{% if product %}` (R3 — skills
  render with a null Tera view, so it needs a separate skill product view
  upstream); the Claude side, which already works; reversing or re-gating #436;
  removing the flat `$CODEX_HOME/skills` root.

## Assumptions

1. nils-cli coupled-dev follows DEVELOPMENT.md (local debug binary, then a pin
   bump via `meta:nils-cli-bump`); one release delivers both R1 and C1.
2. The host starts on pin `v1.12.0` (the value #436 left unchanged). A bump is
   required because R1 (home render) and C1 (`--product` + v2) are new
   `agent-runtime` / `agent-docs` capabilities; #436 did not pre-clear it.
3. #436 is landed: the home prompt (surfaces 1 and 17) is still a raw symlink to
   `AGENT_HOME.md` wired by `scripts/setup.sh`; this plan owns the cutover.

## Sprint 1: Upstream nils-cli — home-prompt render target (R1) + agent-docs product dimension (C1)

**Goal**: ship the two new capabilities in `sympoies/nils-cli` behind the
coupled-dev loop, validated against a local debug binary before release.
**Demo/Validation**:
- Command(s): `scripts/dev/with-nils-version.sh local -- agent-runtime render --product codex`; local-binary `agent-docs preflight --product codex` against a fixture catalog
- Verify: the per-product home prompt renders (codex / claude / neutral); `--product` filters documents and validations; the preflight schema reports v2

### Task 1.1: R1 — add a per-product home-prompt render target to agent-runtime
- **Location**:
  - `sympoies/nils-cli` `agent-runtime` render: new home-prompt RenderTarget + writer + render-golden coverage
- **Description**: Add a home-prompt render target so the home source renders per product into `build/<product>/AGENT_HOME.md`, plus a product-neutral fallback variant for unset or unknown product. The render view must put `product` in scope (as the agent render path already does) so a Codex-only block renders only into the Codex output. Extend render-golden coverage for the new artifact. Mirror #436's per-product convention rather than inventing a new one.
- **Dependencies**:
  - none
- **Complexity**: 7
- **Acceptance criteria**:
  - `agent-runtime render --product codex` and `--product claude` emit distinct home prompts; a neutral baseline renders when the product is absent; render-golden covers all three.
- **Validation**:
  - `scripts/dev/with-nils-version.sh local -- agent-runtime render --product codex`; the same for `claude`; review the render-golden diff.

### Task 1.2: C1 — add the optional `product` field to the agent-docs catalog parser and model
- **Location**:
  - `sympoies/nils-cli` `agent-docs` config parser and model (DocumentEntry / ValidationEntry + resolved JSON surface)
- **Description**: Add an optional `product` field (a string, or a `[codex, claude]` list; default = all) to `[[document]]` and `[[validation]]`. Validate names against a fixed `codex`/`claude` enum so a typo hard-errors at parse time rather than silently never-matching. Serialize the resolved product scope onto the preflight JSON so consumers can audit it.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - A catalog entry with `product = "codex"` parses; an invalid name exits with the config error; the resolved JSON carries the product scope.
- **Validation**:
  - Upstream parser/model unit tests for the string form, the list form, and the invalid-name case.

### Task 1.3: C1 — add `preflight --product`, the resolver filter, and `agent-docs.preflight.v2`
- **Location**:
  - `sympoies/nils-cli` `agent-docs` cli (`--product`), resolver (document + validation-contract filter), preflight / list / explain / audit run blocks, and the `agent-docs.preflight.v2` schema string
- **Description**: Add a `--product codex|claude` flag to preflight / list / explain / audit, and filter resolved documents AND validation contracts by the active product in ONE resolver place (so the cue and the finish-line gate cannot diverge). Unset means include-all (the safe fallback for unrelated repos and CI). Keep intent discovery product-independent and apply the product filter after the declared-intent guard. Bump the preflight contract string to `agent-docs.preflight.v2` and document it; this is the agent-docs preflight schema namespace, distinct from the `schema_version` keys in `manifests/`.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 7
- **Acceptance criteria**:
  - `preflight --product codex` includes `product=codex` docs, `--product claude` excludes them, and an unset run includes all; validation contracts filter identically; the schema version reports v2.
- **Validation**:
  - Upstream resolver tests covering include / exclude / unset for both documents and validation contracts; a preflight golden showing product-filtered output.

### Task 1.4: Upstream acceptance — goldens, schema, and tests green on the local binary
- **Location**:
  - `sympoies/nils-cli` test suites: render-golden (home target), agent-docs resolver / parser, preflight v2 golden
- **Description**: Make the upstream change set pass its own tests against the local debug binary before release, and capture failing-then-passing evidence for the test-first record.
- **Dependencies**:
  - Task 1.1
  - Task 1.3
- **Acceptance criteria**:
  - The render and agent-docs crate tests are green; render-golden and preflight goldens are updated intentionally.
- **Validation**:
  - Upstream `cargo test` for the render and agent-docs crates; `scripts/dev/with-nils-version.sh local -- agent-runtime render --product codex` from this repo.

## Sprint 2: Release nils-cli and bump the pin

**Goal**: promote the coupled change to a released, pinned surface.
**Demo/Validation**:
- Command(s): `agent-runtime --version`; `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml`
- Verify: the host is on the new pin, the required-cli floors are raised, and version-alignment reports block=0

### Task 2.1: Land, release, tap, and brew-upgrade nils-cli
- **Location**:
  - `sympoies/nils-cli` release; `sympoies/homebrew-tap` formula
- **Description**: Land the Sprint 1 change in nils-cli, cut the release through the bump-version-tag-release flow, update the tap formula, and `brew upgrade sympoies/tap/nils-cli` on every machine that runs the gate (Mac and g14).
- **Dependencies**:
  - Task 1.4
- **Acceptance criteria**:
  - `agent-runtime --version` and `agent-docs --version` report the new release on all gate hosts.
- **Validation**:
  - `agent-runtime --version`; `agent-docs --version`.

### Task 2.2: Bump the pin and required-cli floors via `meta:nils-cli-bump`
- **Location**:
  - `docs/source/nils-cli-pin.yaml`
  - `docs/source/nils-cli-surface.md`
  - `docs/source/nils-cli-version-workflows.md`
  - `manifests/runtime-roots.yaml`
- **Description**: Use `meta:nils-cli-bump` to set `pinned_tag` to the new release and raise the `agent-docs` / `agent-runtime` `required_clis` floors to the release that introduces the home render target, `--product`, and `agent-docs.preflight.v2`. Refresh the surface note and the version-baseline mirrors.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml` reports block=0; the version-baseline audit passes.
- **Validation**:
  - `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml`; `python3 scripts/ci/version-baseline-audit.py check`.

## Sprint 3: Repo consume — per-product home render adoption and delegation relocation (R1)

**Goal**: cut the home prompt over from a raw symlink to a per-product render, and
move the Codex-only delegation authorization into the Codex home block.
**Demo/Validation**:
- Command(s): `agent-runtime render --product codex`; `agent-runtime render --product claude`
- Verify: the Codex home contains the delegation authorization, the Claude home does not, and a neutral fallback exists

### Task 3.1: Render per-product `AGENT_HOME` and retarget `setup.sh`
- **Location**:
  - `AGENT_HOME.md`
  - `scripts/setup.sh`
  - `manifests/surfaces.yaml`
- **Description**: Author the home source so it carries a Codex-only code-review-delegation block, a product-neutral shared body, and a neutral fallback. Update `setup.sh` `agent_home_source()` / `product_home_prompt_path()` / `ensure_home_prompt()` to symlink each product's home target to the rendered `build/<product>/AGENT_HOME.md` instead of the raw repo `AGENT_HOME.md`, keep the neutral fallback for unset product, and preserve the existing refuse-to-clobber-non-managed-file safety check. Update `surfaces.yaml` rows 1 (home-prompt) and 17 (prompt-mode-delegation-policy) mechanism strings from "symlink ... -> AGENT_HOME.md" / "same shared home prompt" to the per-product render mechanism, keeping the `source_manifest` anchor strings in lockstep with the harness-shape headings.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 7
- **Acceptance criteria**:
  - The Codex render contains the delegation block; the Claude render does not; unset or unknown product gets the neutral fallback; `setup.sh` still refuses to overwrite a non-managed home file.
- **Validation**:
  - `agent-runtime render --product codex`; `agent-runtime render --product claude`; inspect `build/codex/AGENT_HOME.md` against `build/claude/AGENT_HOME.md`; `bash scripts/setup.sh --skip-homebrew-install --dry-run`.

### Task 3.2: Remove the Codex-only delegation prose from the shared body and the Claude render
- **Location**:
  - `AGENT_HOME.md`
- **Description**: Ensure the product-neutral fallback and the Claude render no longer contain the Codex-only "Code Review Delegation" authorization; it lives only in the Codex block. Confirm the neutral fallback remains valid safe-fallback policy for unrelated workspaces with no product set.
- **Dependencies**:
  - Task 3.1
- **Acceptance criteria**:
  - `grep -niE 'codex|claude'` on the Claude render and the neutral fallback returns no Codex-only authorization; the Codex render retains it.
- **Validation**:
  - `agent-runtime render --product codex`; `agent-runtime render --product claude`; grep the per-product outputs.

### Task 3.3: Update the support matrix, audit-drift, and harness-shape for the home-prompt cutover
- **Location**:
  - `SUPPORT_MATRIX.md`
  - `tests/golden/shared/SUPPORT_MATRIX.md`
  - `docs/source/harness-shape-codex.md`
  - `docs/source/harness-shape-claude.md`
  - `drift-audit.allow.yaml`
- **Description**: Re-render the support matrix for rows 1 and 17 (mechanism now per-product render), update the harness-shape surface-1 and surface-17 anchored sections (preserve the anchor headings; keep the `surfaces.yaml` `source_manifest` anchors in lockstep), and reconcile the `agent-home-leak` audit-drift fixture for the `$AGENT_HOME` token and the now-removed cross-product prose, allowlisting legitimately-shared content as needed.
- **Dependencies**:
  - Task 3.1
  - Task 3.2
- **Acceptance criteria**:
  - `agent-runtime render --target support-matrix` produces a clean golden; `agent-runtime audit-drift` is green including the agent-home-leak class; the harness-shape anchors are intact.
- **Validation**:
  - `agent-runtime render --target support-matrix --update-golden`; `git diff --exit-code -- tests/golden/`; `agent-runtime audit-drift`.

## Sprint 4: Repo consume — agent-docs product wiring (C1) + leakage lint (A4) + acceptance

**Goal**: wire the catalog product dimension through the hooks with validation
parity, add the broad-sentinel leakage lint scoped to the post-#436 Codex
surface, and prove the whole change.
**Demo/Validation**:
- Command(s): `bash scripts/ci/all.sh`; `bash tests/hooks/run.sh`
- Verify: per-product docs and validations resolve, the lint is green with its allowlist, and the full gate passes

### Task 4.1: Forward `AGENT_RUNTIME_PRODUCT` as `--product` from the hooks, with parity
- **Location**:
  - `core/hooks/shared/user-prompt-agent-docs.sh`
  - `core/hooks/shared/hook_common.py`
  - `tests/hooks/test_shared_hooks.py`
- **Description**: In both agent-docs hook consumers, build a `--product` argument from `AGENT_RUNTIME_PRODUCT` (only `codex` or `claude`; unset means omit, i.e. include-all), capability-probed against `preflight --help` the same way the existing `--require-declared-intent` probe works. Add the active product to the `hook_common.validation_contracts()` cache key and freshness check so a Codex run and a Claude run in the same repo do not share a cached contract. Keep the UserPromptSubmit cue and the finish-line gate in parity: the filter lives in nils-cli, and both consumers pass the same `--product`.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 6
- **Acceptance criteria**:
  - The cue and the finish-line gate resolve the same product-filtered document and validation set; an older agent-docs without `--product` still works via the omit path; a Codex-only validation never appears in a Claude run.
- **Validation**:
  - `bash tests/hooks/run.sh`; a manual `AGENT_RUNTIME_PRODUCT=codex` versus `=claude` preflight diff.

### Task 4.2: Register the Codex-only delegation as a `product=codex` catalog doc (parity backstop)
- **Location**:
  - `AGENT_DOCS.toml`
  - `core/policies/code-review-delegation-codex.md`
- **Description**: Declare the Codex-only delegation as a `product = "codex"` document so a Codex session's preflight cue surfaces it and audit can validate it; keep unset = include-all so audit and CI still see the superset. Decide `required` true or false. This both demonstrates C1 and backstops the R1 home render.
- **Dependencies**:
  - Task 4.1
- **Acceptance criteria**:
  - `agent-docs preflight --product codex` lists the doc; `--product claude` omits it; `agent-docs audit --target all --strict` (product-unset) still validates it.
- **Validation**:
  - `agent-docs preflight --intent project-dev --product codex --format json`; the same for `claude`; `agent-docs audit --target all --strict`.

### Task 4.3: Add the broad-sentinel cross-product leakage lint scoped to the post-#436 surface
- **Location**:
  - `scripts/ci/product-leak-audit.sh`
  - `scripts/ci/product-leak-allow.yaml`
  - `scripts/ci/all.sh`
  - `DEVELOPMENT.md`
- **Description**: Add a repo-local bash lint (not a nils-cli audit class) that scans each product's actually-loaded artifacts and fails on the other product's bare name (`Codex`, `Claude`, `CODEX_`) outside a documented allowlist. The "artifacts a product loads" set must include the post-#436 Codex artifacts: the rendered per-product home, the rendered Codex skills and agents, and the now-`loaded_at_runtime` plugin and marketplace artifacts (`targets/codex/.agents/plugins/marketplace.json` and the `.codex-plugin/plugin.json` trees) which are gated by `CODEX_PLUGIN_ACTIVATION` — do not rely on the stale `config_activation` list in `manifests/product-capabilities.yaml`. Allowlist the legitimately-shared docs (`SUPPORT_MATRIX.md`, `docs/source/harness-shape-*.md`, the capability prose) with reasons, and add a negative self-test. Register the lint last in `scripts/ci/all.sh` and document it in `DEVELOPMENT.md`; land the allowlist and content fix before registration so CI is green on first run.
- **Dependencies**:
  - Task 3.3
  - Task 4.1
- **Complexity**: 6
- **Acceptance criteria**:
  - The lint passes against the post-cutover tree; the negative self-test (a foreign product name in a loaded artifact) fails; the full gate is green on first run.
- **Validation**:
  - `bash scripts/ci/product-leak-audit.sh`; the negative self-test; `bash scripts/ci/all.sh`.

### Task 4.4: Full acceptance and runtime-smoke
- **Location**:
  - `tests/runtime-smoke/cases/meta/run.sh`
- **Description**: Add a home-prompt render probe alongside the existing Codex plugin-registry probes (the meta runtime-smoke case is now the home for these), run the full gate and the hook suite, and confirm the `preflight --product` behavior end to end.
- **Dependencies**:
  - Task 4.2
  - Task 4.3
- **Acceptance criteria**:
  - `bash scripts/ci/all.sh` and `bash tests/hooks/run.sh` are green; runtime-smoke covers the per-product home render.
- **Validation**:
  - `bash scripts/ci/all.sh`; `bash tests/hooks/run.sh`; `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`.

## Testing Strategy

- Unit (upstream): agent-docs parser and resolver product filter; the home-target render view.
- Integration: render-golden (home and matrix), audit-drift (agent-home-leak), the hook contract tests, `preflight --product`, version-alignment, and the version-baseline audit.
- E2E / manual: `setup.sh` dry-run home wiring; a live `preflight --product` diff; the runtime-smoke meta home-prompt probe.

## Risks & gotchas

- The home prompt is currently a raw symlink, unchanged by #436, so this plan
  owns the cutover. `setup.sh` `ensure_home_prompt()` refuses to overwrite a
  non-managed file; keep that guard when switching to the rendered target.
- R1's link-map / render additions must not disturb #436's `codex-kit.marketplace`
  link-map entry (the link-map merges per id) or the `targets/codex/.agents/plugins/`
  tree. The home prompt is a different artifact; keep them independent.
- The leakage lint must treat the post-#436 Codex plugin and marketplace
  artifacts as loaded (their capability flags are now `true`), gated by
  `CODEX_PLUGIN_ACTIVATION`. The `config_activation` list in
  `manifests/product-capabilities.yaml` is stale for these paths — enumerate the
  loaded set explicitly.
- The manifest `schema_version: 1` keys and the `agent-docs.preflight.v2` string
  are different namespaces; bumping the preflight schema does not touch the
  manifests' `schema_version`.
- No pin bump is forced by #436 (`docs/source/nils-cli-pin.yaml` still pins
  `v1.12.0`); this plan's bump is required only because R1 and C1 add new
  `agent-runtime` / `agent-docs` capability. Use the coupled-dev loop with a local
  binary until the release ships; never commit golden churn off-pin.
- Adding `{% if product %}` to a `SKILL.md.tera` silently mis-renders (null
  view); skill-level per-product divergence is out of scope and needs a separate
  upstream skill product view.
- Reuse #436's conventions: the `--product` flag plus feature-gate "ship-but-gate,
  dry-run-visible" pattern in `sync-runtime-surfaces.sh`; the capability-flag
  source-of-truth in `manifests/product-capabilities.yaml` (do not hard-code
  product names where a capability flag exists); the `setup.sh`
  activation-delegation wrapper shape; and the in-place supersession note style
  that preserves anchor headings.

## Rollback plan

- Until the home cutover is proven, keep `AGENT_HOME.md` a valid raw-symlink
  source: `setup.sh`'s prior `ln -s AGENT_HOME.md` path can be restored, and the
  per-product render is additive under `build/`. Reverting Sprint 3 restores the
  raw-symlink behavior.
- C1 is additive (unset = include-all), so reverting the catalog `product` field
  and the hook `--product` forwarding leaves include-all behavior intact.
- The leakage lint can be unregistered from `scripts/ci/all.sh` without affecting
  runtime behavior.
