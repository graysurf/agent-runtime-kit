# Plan: Sync Runtime Skill Prune

## Overview

Close the add-only gap in `sync-runtime-skills` by adding a released
`agent-runtime` stale-surface prune primitive first, then consuming it from the
runtime-kit sync wrapper. The desired end state is that adding, updating, and
removing managed skills all reconcile live Codex and Claude runtime homes
without shell-level deletion logic.

The important boundary is repo ownership: nils-cli owns the deterministic
runtime-home reconciliation primitive; agent-runtime-kit owns manifests, source
docs, rendered skill surfaces, and the thin daily sync wrapper.

## Read First

- Primary source: docs/plans/sync-runtime-skill-prune/sync-runtime-skill-prune-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: none.

## Scope

- In scope:
  - Add `agent-runtime prune-stale` to nils-cli with `--dry-run` and
    `--apply`.
  - Reuse or factor `audit-drift extra` scan-root and expected-path logic so
    detection and repair stay aligned.
  - Only remove provably runtime-kit-owned stale symlinks and empty
    directories under owned roots.
  - Skip and report foreign symlinks, regular files, non-empty directories,
    and anything outside install-map-owned roots.
  - Release and locally install the nils-cli version containing the primitive.
  - Update `scripts/sync-runtime-skills.sh` to run prune after install and
    before final verification when `--apply` is active.
  - Add `--no-prune` to the wrapper with visible warning/audit behavior.
  - Update `meta.sync-runtime-skills` skill docs, rendered outputs, goldens,
    manifest floor, and runtime-kit validation fixtures.
- Out of scope:
  - Deleting arbitrary runtime-home state such as auth, history, sessions,
    logs, caches, projects, or plugin install artifacts.
  - Making `remove-skill` mutate live runtime homes.
  - Repurposing `agent-runtime uninstall` as normal refresh pruning.
  - First-time host bootstrap, Homebrew setup, or unrelated nils-cli changes.
  - Historical `docs/plans/**` cleanup.

## Assumptions

1. The current `audit-drift extra` class is the best starting point for stale
   live-surface detection, but it must become reusable by a repair primitive.
2. Broken managed symlinks may point at removed build paths, so ownership checks
   need lexical target classification in addition to canonical path checks.
3. Runtime-kit cannot safely consume `prune-stale` until the nils-cli release is
   installed and the required `agent-runtime` floor is updated.
4. The first implementation should be conservative: skipped stale candidates
   are acceptable when ownership is ambiguous, but accidental deletion of
   user-owned content is not.

## Sprint 1: Add The nils-cli Prune Primitive

**Goal**: Ship a released `agent-runtime prune-stale` command that can detect
and remove stale managed runtime surfaces safely in sandbox and live homes.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Add prune-stale planner and executor

- **Location**:
  - `docs/plans/sync-runtime-skill-prune/`
- **Description**: Add a new planner and executor for stale runtime surfaces.
  The implementation target is the nils-cli `agent-runtime-cli` crate. The
  planner should load the product link map with overlay handling, build the
  current expected live-path set, scan only install-map-owned roots, and
  classify extra live paths. The executor should remove only owned stale
  symlinks and empty directories in apply mode. Dry-run must classify without
  mutation.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Extra live surfaces under owned roots are classified deterministically.
  - Regular files, non-empty directories, and foreign symlinks are skipped.
  - Broken managed symlinks can still be classified safely.
  - Second apply is an exit-0 no-op.
- **Validation**:
  - `cargo test -p agent-runtime-cli --test integration prune_stale`

### Task 1.2: Expose agent-runtime prune-stale CLI

- **Location**:
  - `docs/plans/sync-runtime-skill-prune/`
- **Description**: Add the CLI command with `--source-root`, `--product`,
  `--live-home`, `--dry-run`, `--apply`, `--no-overlay`, and `--overlay-path`
  in the nils-cli `agent-runtime-cli` command surface. Text output should
  summarize removals and skips; JSON output should expose a stable envelope for
  later runtime-kit tests and automation.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Help text documents the safety boundary and supported flags.
  - Dry-run performs no filesystem writes.
  - Apply removes only removable stale candidates.
  - JSON output distinguishes removed, skipped, and no-op candidates.
- **Validation**:
  - `cargo test -p agent-runtime-cli --test integration prune_stale`
  - `cargo test -p agent-runtime-cli --test integration audit_drift_extra_intentional`

### Task 1.3: Regression-check install, uninstall, and audit behavior

- **Location**:
  - `docs/plans/sync-runtime-skill-prune/`
- **Description**: Prove the new primitive does not weaken existing install,
  uninstall, backup, overlay, or audit contracts in nils-cli. Keep uninstall as
  the all-current-link-map removal path; keep prune as the stale-only refresh
  path.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Existing install and uninstall tests still pass.
  - Audit extra behavior is either unchanged or intentionally refactored with
    equivalent findings.
  - No tests imply regular files or foreign symlinks can be deleted.
- **Validation**:
  - `cargo test -p agent-runtime-cli --test integration install_pipeline`
  - `cargo test -p agent-runtime-cli --test integration uninstall`
  - `cargo test -p agent-runtime-cli --test integration audit_drift_extra_intentional`

### Task 1.4: Release and install the nils-cli primitive

- **Location**:
  - `docs/plans/sync-runtime-skill-prune/`
- **Description**: Deliver the nils-cli PR, release the version containing
  `agent-runtime prune-stale`, and verify the local `agent-runtime` on `PATH`
  exposes the new command before runtime-kit consumes it.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 4
- **Acceptance criteria**:
  - The nils-cli PR is merged.
  - A released/installable nils-cli version contains `agent-runtime prune-stale`.
  - Local `agent-runtime --version` and `agent-runtime prune-stale --help`
    prove runtime-kit can consume the command.
- **Validation**:
  - nils-cli repository release gate per current `DEVELOPMENT.md`
  - `agent-runtime --version`
  - `agent-runtime prune-stale --help`

## Sprint 2: Consume Prune From agent-runtime-kit Sync

**Goal**: Update runtime-kit sync surfaces so live runtime refreshes prune stale
managed skills by default after nils-cli ships the primitive.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 2.1: Update sync-runtime-skills.sh

- **Location**:
  - `scripts/sync-runtime-skills.sh`
- **Description**: Add `--no-prune`, print planned prune commands in dry-run
  mode, and run `agent-runtime prune-stale --apply` after install when
  `--apply` is active. Preserve the existing order of pull, source-count check,
  render, install, doctor, and Codex prompt-input, with prune inserted after
  install and before final verification.
- **Dependencies**:
  - Task 1.4
- **Complexity**: 4
- **Acceptance criteria**:
  - Default dry-run prints prune commands without mutating runtime homes.
  - `--apply` runs prune for each selected product unless `--no-prune` is set.
  - `--no-prune` logs that live stale surfaces are not fully reconciled.
  - Existing `--product`, `--no-pull`, and `--no-verify` behavior remains.
- **Validation**:
  - `bash scripts/sync-runtime-skills.sh`
  - `bash scripts/sync-runtime-skills.sh --apply --no-pull --no-prune`

### Task 2.2: Update skill docs, manifest floor, and rendered outputs

- **Location**:
  - `manifests/skills.yaml`
  - `core/skills/meta/sync-runtime-skills/SKILL.md.tera`
  - `tests/golden/`
- **Description**: Raise the required `agent-runtime` floor for
  `meta.sync-runtime-skills`, update the skill contract for prune behavior and
  `--no-prune`, then rerender Codex and Claude outputs/goldens.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - The skill body documents prune sequencing and safety boundaries.
  - Rendered Codex and Claude skill outputs match the source template.
  - Manifest floors reflect the released nils-cli version.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`

### Task 2.3: Add removed-skill sync fixture coverage

- **Location**:
  - `tests/`
  - `scripts/ci/`
- **Description**: Add focused runtime-kit coverage that simulates a managed
  skill removed from the current link map while stale live runtime symlinks
  remain. Prove sync/prune removes owned stale surfaces and skips user-owned
  content.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Codex active skill stale symlink fixture is pruned.
  - Claude plugin-tree stale skill file fixture is pruned.
  - Foreign symlink and regular-file fixtures survive unchanged.
  - The fixture can run without mutating real live homes.
- **Validation**:
  - focused removed-skill sync fixture command
  - `bash scripts/ci/sandbox-install-rehearsal.sh`

### Task 2.4: Full validation and live sync proof

- **Location**:
  - repository root
- **Description**: Run the full runtime-kit gate and perform a live sync smoke
  from the durable primary checkout after the feature lands. Verify audit-drift
  remains clean.
- **Dependencies**:
  - Task 2.3
- **Complexity**: 3
- **Acceptance criteria**:
  - Full local CI passes.
  - Live sync reports install, prune, doctor, and Codex prompt-input status.
  - Final audit-drift is clean except documented intentional differences.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - `bash scripts/sync-runtime-skills.sh --apply --no-pull`
  - `agent-runtime audit-drift --source-root /Users/terry/Project/graysurf/agent-runtime-kit`

## Issue Closeout Gate

The tracking issue is complete when:

- Sprint 1 nils-cli PR is merged and the released local `agent-runtime`
  exposes `prune-stale`.
- Sprint 2 runtime-kit PR is merged and runtime-kit consumes the released
  primitive.
- Runtime-kit full CI passes after render/golden and fixture updates.
- Live sync from the durable primary checkout completes with prune enabled.
- `agent-runtime audit-drift` reports clean or only documented intentional
  differences.
- The issue dashboard links to current source, plan, state, validation, and
  PR/release evidence.

## Future Work

- Promote the durable prune contract into `docs/source/` after implementation
  if it becomes important architecture guidance.
- Consider making `audit-drift` and `prune-stale` share a public JSON schema if
  downstream automation starts consuming both.
