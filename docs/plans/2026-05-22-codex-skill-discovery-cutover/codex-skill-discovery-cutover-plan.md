# Plan: Codex Skill Discovery Cutover

## Overview

Move Codex skill usage off the temporary `$HOME/.agents` compatibility alias and
onto the `agent-runtime-kit` Codex runtime surface under `$HOME/.codex`. The
plan starts by proving what Codex Desktop actually uses for local skill
discovery, then closes any required-skill migration gaps, updates the Codex
install surface, and finishes with a reversible live-session cutover gate.

This plan only covers Codex skill discovery and skill usage. It does not
implement hook migration, Claude migration, Plan 05 cleanup, or general product
prompt smoke except where those surfaces directly affect whether Codex can see
the required skills.

## Read First

- Primary source: docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - What exact runtime path, cache, config, or app-provided registry does Codex
    Desktop use for local skill discovery?
  - Which `$HOME/.codex` surface should carry runtime-kit skills:
    `$HOME/.codex/plugins/<domain>/skills`, `$HOME/.codex/skills`, generated
    `AGENTS.md` references, or another verified Codex-supported surface?
  - Should `discussion-to-implementation-doc` and `handoff-session-prompt` be
    migrated before alias removal, or should the acceptance set be narrowed?
- Secondary references:
  - `CODEX_AGENTS.md`
  - `docs/source/inventory-target-architecture.md`
  - `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`
  - `manifests/product-capabilities.yaml`
  - `manifests/runtime-roots.yaml`
  - `targets/codex/link-map.yaml`
  - `tests/sandbox/codex/expected-skills.txt`

## Scope

- In scope:
  - Prove and document the Codex Desktop local skill discovery mechanism.
  - Choose the Codex runtime skill surface under `$HOME/.codex`.
  - Ensure the required acceptance skills are available from
    `agent-runtime-kit`, not through `$HOME/.agents`.
  - Update Codex manifests, link maps, rendered/golden output, and smoke pins as
    needed for the chosen surface.
  - Add a reversible live-session validation gate for a fresh Codex Desktop
    session without `$HOME/.agents`.
  - Retire the compatibility alias only after the live gate passes.
- Out of scope:
  - Implementing hook migration or changing hook behavior except where a
    verified skill-discovery mechanism explicitly depends on a hook-loaded file.
  - Claude migration, Claude runtime roots, or Claude plugin behavior.
  - Plan 05 cleanup unrelated to Codex skill discovery.
  - Product prompt smoke beyond the minimal live-session skill availability
    proof.
  - Mutating auth, sessions, history, logs, caches, or secrets.

## Assumptions

1. `agent-runtime-kit` remains the source of truth for shared skill bodies,
   manifests, and Codex target metadata.
2. `$HOME/.codex/AGENTS.md` already links directly to
   `agent-runtime-kit/CODEX_AGENTS.md`.
3. Current temp-home install smoke proves file installation and doctor behavior,
   but not fresh Codex Desktop skill discovery.
4. `$HOME/.agents -> $HOME/.config/agent-kit` remains a temporary compatibility
   alias until the live Codex Desktop gate passes.
5. Live-home changes must be dry-run-first, reversible, and recorded with exact
   rollback commands before permanent alias removal.

## Sprint 1: Discovery Contract

**Goal**: Establish what Codex Desktop actually uses to discover local skills
and turn that into an executable acceptance contract before changing runtime
state.

**Demo/Validation**:

- Commands:
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist`
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist`
  - `agent-runtime install --product codex --dry-run`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
- Verify: the sprint produces a documented discovery mechanism, a required
  skill acceptance set, and a reversible live-session test protocol without
  mutating real `$HOME/.codex` or removing `$HOME/.agents`.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 1.1: Identify Codex Desktop discovery mechanism

- **Location**:
  - `docs/source/inventory-target-architecture.md`
  - `manifests/product-capabilities.yaml`
  - `targets/codex/`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
- **Description**: Inspect local Codex runtime inputs and available CLI/app
  evidence to determine whether Codex Desktop discovers skills from
  `$CODEX_HOME/plugins`, `$CODEX_HOME/skills`, loaded prompt references, an
  app-managed registry/cache, launch environment variables, or another surface.
  Record uncertainty as a blocker instead of guessing.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - The execution-state ledger records the inspected surfaces and evidence.
  - The selected candidate discovery mechanism is tied to a concrete loaded
    file, directory, CLI output, app behavior, or documented runtime source.
  - If Codex Desktop discovery cannot be inspected directly, the task records
    the smallest live experiment needed before Sprint 2.
  - No real `$HOME/.codex` skill files, auth, sessions, history, logs, or caches
    are modified.
- **Validation**:
  - `agent-runtime install --product codex --dry-run`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`

### Task 1.2: Audit required skill availability

- **Location**:
  - `manifests/skills.yaml`
  - `core/skills/`
  - `tests/sandbox/codex/expected-skills.txt`
  - `docs/source/extraction-backlog.md`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
- **Description**: Map the minimum required acceptance set
  (`semantic-commit`, `execute-plan-tracking-issue`, `deliver-plan-tracking-issue`,
  `discussion-to-implementation-doc`, `handoff-session-prompt`) to current
  runtime-kit source, manifest IDs, rendered Codex paths, required CLIs, and
  missing migration work.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Every required skill has one of: available in `agent-runtime-kit`, missing
    and scheduled for migration, or explicitly removed from the acceptance set
    with a recorded owner decision.
  - Missing required skills are not treated as satisfied through legacy
    `agent-kit` or `$HOME/.agents`.
  - Any missing nils-cli primitive needed by a required skill is recorded as a
    release-boundary blocker.
- **Validation**:
  - `rg -n 'semantic-commit|execute-plan-tracking-issue|deliver-plan-tracking-issue|discussion-to-implementation-doc|handoff-session-prompt' manifests/skills.yaml tests/sandbox/codex/expected-skills.txt core/skills`

### Task 1.3: Define reversible live-session acceptance protocol

- **Location**:
  - `tests/runtime-smoke/`
  - `docs/source/inventory-target-architecture.md`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
- **Description**: Define the exact live-session proof for fresh Codex Desktop
  skill discovery without `$HOME/.agents`, including setup, alias-disable
  window, expected skill visibility, pass/fail evidence, and rollback steps.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 4
- **Acceptance criteria**:
  - The protocol disables or renames `$HOME/.agents` only inside a reversible
    window and restores it on failure.
  - The protocol names the required skills to verify and the observable signal
    that proves Codex can see them.
  - The protocol distinguishes temp-home install smoke from real Desktop
    discovery.
  - The protocol avoids auth, session, history, log, and cache mutation.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - Manual review of rollback commands before live mutation.

## Sprint 2: Runtime-Kit Codex Surface

**Goal**: Implement the chosen `$HOME/.codex` skill surface and close required
skill gaps while keeping `$HOME/.agents` available as fallback until Sprint 3.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
  - `bash scripts/ci/all.sh`
- Verify: Codex install output includes the chosen discovery surface and every
  required acceptance skill is present from runtime-kit source.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 2.1: Document and wire the Codex skill surface

- **Location**:
  - `manifests/product-capabilities.yaml`
  - `manifests/runtime-roots.yaml`
  - `targets/codex/link-map.yaml`
  - `targets/codex/`
  - `docs/source/inventory-target-architecture.md`
- **Description**: Update the Codex product capability and install metadata to
  match the discovery mechanism proven in Sprint 1. Keep `.codex-plugin`
  metadata as local audit data only unless Sprint 1 proves Codex actually loads
  it.
- **Dependencies**:
  - Task 1.1
  - Task 1.3
- **Complexity**: 5
- **Acceptance criteria**:
  - The chosen skill surface is under `$HOME/.codex`.
  - Rendered Codex output does not depend on `$HOME/.agents` or ambient
    `AGENT_HOME`.
  - Product capability docs no longer imply unproven plugin discovery.
  - The install dry-run shows the expected Codex files or references.
- **Validation**:
  - `agent-runtime install --product codex --dry-run`
  - `agent-runtime audit-drift`

### Task 2.2: Migrate missing required skills

- **Location**:
  - `core/skills/`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/codex/`
- **Description**: Add runtime-kit source, manifest entries, Codex rendering,
  and acceptance pins for any required skill from Task 1.2 that is missing.
  Expected candidates are `discussion-to-implementation-doc` and
  `handoff-session-prompt` unless Task 1.2 narrows the acceptance set.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 6
- **Acceptance criteria**:
  - Required skills no longer rely on legacy `agent-kit` source at runtime.
  - Each migrated skill has a concrete domain, source path, Codex render path,
    and required CLI floor when applicable.
  - Missing nils-cli behavior is logged as a blocker instead of recreated in
    inline shell or Python.
  - Sandbox expected skill pins include the required set.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
  - `rg -n 'discussion-to-implementation-doc|handoff-session-prompt' manifests/skills.yaml tests/sandbox/codex/expected-skills.txt core/skills`

### Task 2.3: Add discovery-focused Codex smoke coverage

- **Location**:
  - `tests/runtime-smoke/`
  - `tests/sandbox/codex/expected-skills.txt`
  - `DEVELOPMENT.md`
- **Description**: Extend the existing install/product smoke harness so it can
  assert the chosen discovery surface and required skill set without mutating
  real `$HOME/.codex`. Keep Desktop prompt execution quarantined/manual.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Temp-home install mode verifies the same skill surface that Sprint 1
    selected for Desktop discovery.
  - The expected Codex skill set includes every required acceptance skill.
  - Product prompt execution remains opt-in and does not become a default CI
    dependency.
  - `DEVELOPMENT.md` lists the targeted discovery smoke commands.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`

### Task 2.4: Integrate render, golden, and drift gates

- **Location**:
  - `tests/golden/codex/`
  - `scripts/ci/all.sh`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
- **Description**: Refresh generated Codex output and golden snapshots, then
  decide whether the new discovery smoke belongs in the default CI gate or a
  manual/quarantined lane.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
  - Task 2.3
- **Complexity**: 4
- **Acceptance criteria**:
  - `agent-runtime render --product codex` and golden checks are stable.
  - `agent-runtime audit-drift` reports no unplanned source/target mismatch.
  - Any CI gate addition is deterministic and does not require Desktop app
    state.
  - Execution-state notes separate deterministic coverage from live Desktop
    coverage.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/all.sh`

## Sprint 3: Reversible Alias Retirement

**Goal**: Prove a fresh Codex Desktop session can discover the required skills
from `$HOME/.codex` without `$HOME/.agents`, then retire the compatibility
alias with a verified rollback path.

**Demo/Validation**:

- Commands:
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - `agent-docs --docs-home "$HOME/.codex" resolve --context startup --strict --format checklist`
  - `if [ -L "$HOME/.agents" ]; then readlink "$HOME/.agents"; else test ! -e "$HOME/.agents"; fi`
- Verify: new Codex Desktop sessions can see the required skills without the
  alias, docs preflight no longer depends on `.agents`, and rollback is tested
  before permanent removal.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Run pre-live dry-run and backup checks

- **Location**:
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
  - `$HOME/.codex`
  - `$HOME/.agents`
- **Description**: Before any live mutation, record current symlink state,
  launch environment relevant to skill discovery, Codex install dry-run output,
  and exact rollback commands. Do not touch auth, sessions, logs, history, or
  caches.
- **Dependencies**:
  - Task 2.4
- **Complexity**: 3
- **Acceptance criteria**:
  - Current `$HOME/.agents` state is recorded.
  - Current `$HOME/.codex` skill surface state is recorded without dumping
    secrets or private runtime data.
  - Rollback commands are reviewed before disabling the alias.
  - Install dry-run and temp-home smoke pass.
- **Validation**:
  - `agent-runtime install --product codex --dry-run`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`

### Task 3.2: Verify fresh Codex Desktop without `.agents`

- **Location**:
  - `$HOME/.codex`
  - `$HOME/.agents`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
- **Description**: In a reversible test window, disable the compatibility alias,
  start a fresh Codex Desktop session, and verify the required skills are
  visible and usable from the runtime-kit-owned `$HOME/.codex` surface. Restore
  the alias immediately if the gate fails.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 5
- **Acceptance criteria**:
  - `$HOME/.agents` is absent or disabled during the test window.
  - A fresh Codex Desktop session can see each required acceptance skill.
  - Evidence records the exact session result without exposing secrets or raw
    private logs.
  - Failure restores `$HOME/.agents -> $HOME/.config/agent-kit` and records the
    blocker for follow-up.
- **Validation**:
  - Manual fresh Codex Desktop session check from the Sprint 1 protocol.
  - `agent-docs --docs-home "$HOME/.codex" resolve --context startup --strict --format checklist`

### Task 3.3: Retire compatibility alias after live pass

- **Location**:
  - `CODEX_AGENTS.md`
  - `docs/source/inventory-target-architecture.md`
  - `manifests/runtime-roots.yaml`
  - `$HOME/.agents`
  - macOS launch environment only if Task 1.1 proves it affects skill discovery
- **Description**: Remove or disable the `$HOME/.agents` compatibility alias
  after live discovery passes. Update only the docs and local environment
  references that are directly part of Codex skill discovery; do not fold in
  hook or Claude cleanup.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 4
- **Acceptance criteria**:
  - `$HOME/.agents` is no longer required for Codex skill discovery.
  - Any remaining `.agents` mention in tracked docs is explicitly historical,
    rollback-only, or project-local overlay behavior.
  - New shell or launch environment no longer points Codex skill discovery at
    the legacy `agent-kit` checkout unless it is retained as a documented
    rollback fallback.
  - Rollback instructions remain available after alias retirement.
- **Validation**:
  - `! rg -n '/Users/[^/]+/\\.agents|\\$HOME/\\.agents' "$HOME/.zshenv" "$HOME/.config/zsh/scripts/_internal/paths.exports.zsh" "$HOME/.codex/config.toml"`
  - `if [ -L "$HOME/.agents" ]; then false; else test ! -e "$HOME/.agents"; fi`
  - `agent-docs --docs-home "$HOME/.codex" resolve --context startup --strict --format checklist`

### Task 3.4: Prove rollback and close the cutover

- **Location**:
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
  - `docs/source/inventory-target-architecture.md`
  - `DEVELOPMENT.md`
- **Description**: Exercise or dry-run the rollback path, record final
  validation, and promote durable discovery rules out of the plan bundle into
  the appropriate source docs.
- **Dependencies**:
  - Task 3.3
- **Complexity**: 3
- **Acceptance criteria**:
  - Rollback is either executed in a safe drill or dry-run with all commands
    verified.
  - Final validation distinguishes Desktop live evidence from deterministic
    temp-home evidence.
  - Durable discovery contract is promoted to maintained source docs.
  - The plan bundle is ready for issue-backed closeout.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - Manual rollback drill or dry-run evidence recorded in execution state.

## Testing Strategy

- Static/docs:
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist`
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist`
  - `plan-tooling validate --file docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md --format text --explain`
- Render/install:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
- Product/live:
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - Manual fresh Codex Desktop session check with `$HOME/.agents` disabled in a
    reversible test window.
- Full gate:
  - `bash scripts/ci/all.sh` before closing implementation.

## Risks & gotchas

- Codex Desktop skill discovery may not match Codex CLI or temp-home install
  behavior. Do not treat install smoke as live Desktop proof.
- The existing architecture says `.codex-plugin/plugin.json` is local audit
  metadata, not a runtime loader. Do not build the cutover around it unless new
  evidence proves Codex now loads it.
- The required acceptance set currently includes skills that may not be in
  `agent-runtime-kit`. Removing `.agents` before closing that gap can regress
  daily workflows.
- Ambient `AGENT_HOME`, `AGENT_DOCS_HOME`, or launchctl values can hide a
  `.agents` dependency. Validation must prove the selected non-`.agents`
  surface is actually in use.
- Live Desktop checks can touch local app state if run carelessly. The live
  protocol must avoid auth, sessions, history, logs, and caches.
- Same-sprint lanes can conflict in `manifests/skills.yaml`,
  `targets/codex/link-map.yaml`, and `tests/sandbox/codex/expected-skills.txt`.
  Shared integration belongs in the final task of Sprint 2.

## Rollback plan

- Before live mutation, record current `$HOME/.agents` target and Codex
  discovery-related launch environment.
- If live discovery fails, restore:
  - `ln -sfn "$HOME/.config/agent-kit" "$HOME/.agents"`
  - any discovery-relevant launch environment values identified by Sprint 1
  - the previous `$HOME/.codex` skill surface if Sprint 2 changed it
- Re-run:
  - `agent-docs --docs-home "$HOME/.agents" resolve --context startup --strict --format checklist`
  - fresh Codex Desktop session check for the legacy fallback path
- Revert repository changes from the failed sprint together with their
  manifest, render, golden, sandbox, and docs updates.
