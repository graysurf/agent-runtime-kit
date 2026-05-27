# Plan: Plan Archive Discover

## Overview

Ship a read-only archive-candidate discovery path for `plan-archive`: a
testable CLI command in `nils-cli` plus a thin runtime-kit skill that presents
candidate folders and then delegates selected folders to the existing
single-plan `plan-archive-migrate` workflow.

This preserves the destructive boundary: discovery can inspect and classify
many folders, but migration remains per-folder, dry-run-first, and gated by
explicit user confirmation.

## Read First

- Primary source:
  docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-discussion-source.md
- Source type: discussion-to-implementation-doc
- Related skill:
  core/skills/meta/plan-archive-migrate/SKILL.md.tera
- Related runtime surfaces:
  core/skills/meta/plan-archive-query/SKILL.md.tera
  manifests/skills.yaml
  manifests/plugins.yaml
- Open questions carried into execution:
  - Exact closeout markers for `eligible` versus `unknown`.
  - Suggested migrate command shape when multiple provider refs are inferred.

## Scope

- In scope:
  - `plan-archive discover` read-only CLI command in `sympoies/nils-cli`.
  - Candidate classification into `eligible`, `blocked`, and `unknown`.
  - JSON output that includes folder path, reasons, inferred provider refs,
    archive target preview when resolvable, and suggested migrate command.
  - Fixture/unit tests for inference, target collision, missing refs, dirty plan
    folders, and closeout/unknown classification.
  - `plan-archive-discover` skill source in `agent-runtime-kit`.
  - Skill manifest/plugin registration and rendered Codex/Claude surfaces.
- Out of scope:
  - Bulk apply.
  - Automatic deletion or archive commits.
  - Provider refresh during discovery.
  - SQLite/catalog/full-text archive search.
  - Changing the existing `plan-archive-migrate` apply contract.

## Assumptions

1. `plan-archive migrate` already exposes reusable code or can be refactored to
   share source identity, host classification, and archive target derivation.
2. Existing plan folders contain enough local evidence to infer provider refs
   or classify the folder as `blocked` / `unknown` without live provider calls.
3. `agent-runtime-kit` remains the right home for the user-facing skill wrapper
   and coordination plan, while the CLI implementation lands in `nils-cli`.

## Sprint 1: CLI Discovery Contract And Classification

**Goal**: Land the read-only CLI command and stable JSON contract.
**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Define candidate model and shared discovery inputs

- **Location**:
  - `crates/plan-archive/src/discover/mod.rs`
  - `crates/plan-archive/src/migrate/mod.rs`
- **Description**: Add a discovery module with `DiscoverCandidate`,
  `DiscoverStatus`, `DiscoverReason`, and provider-ref source metadata. Reuse or
  extract migrate's source identity, host classification, and archive target
  derivation so discover and migrate cannot drift.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - Candidate model serializes deterministically.
  - Discovery can enumerate folders under `docs/plans/` or an explicit
    `--plans-root`.
  - Discovery never mutates source or archive repos.
  - Shared target derivation is covered by tests used by both discover and
    migrate paths.
- **Validation**:
  - `cargo test -p nils-plan-archive discover`
  - `cargo test -p nils-plan-archive migrate`

### Task 1.2: Add `plan-archive discover`

- **Location**:
  - `crates/plan-archive/src/cli.rs`
  - shell completion generation surfaces
- **Description**: Add a `discover` subcommand with `--source-repo`,
  `--plans-root`, `--archive`, `--hosts`, `--include-unknown`, and
  `--format json|text`. The command scans plan folders, infers provider refs
  from local plan/source/state files, previews archive targets when possible,
  checks target collisions and dirty plan-folder state, and emits suggested
  `plan-archive migrate ... --format json` commands for eligible folders.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `eligible` candidates include at least one provider ref and a resolvable
    archive target that does not already exist.
  - `blocked` candidates include actionable reasons such as missing provider
    refs, existing archive target, or dirty source plan folder.
  - `unknown` candidates preserve ambiguous cases without inventing closeout
    evidence.
  - JSON output is stable and suitable for the skill wrapper.
  - Text output is concise enough for humans to scan.
  - Completion coverage includes the new subcommand and flags.
- **Validation**:
  - `cargo test -p nils-plan-archive discover`
  - `plan-archive discover --source-repo <fixture> --archive <fixture>
    --format json`
  - completion coverage / docs hygiene gates used by `nils-cli`

### Task 1.3: Document CLI behavior and examples

- **Location**:
  - `crates/plan-archive/README.md`
  - `crates/plan-archive/docs/README.md`
- **Description**: Document read-only discovery, status classes, example JSON,
  and the handoff to `plan-archive migrate`. Make it explicit that discover
  never applies migrations and that users still review migrate dry-run output
  before apply.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 2
- **Acceptance criteria**:
  - README examples include an eligible and a blocked candidate.
  - Docs do not imply bulk apply or provider refresh.
  - Existing migrate docs link to discover only as a preselection helper.
- **Validation**:
  - `rumdl check crates/plan-archive/README.md crates/plan-archive/docs/README.md`

## Sprint 2: Runtime Skill Wrapper

**Goal**: Add a thin `plan-archive-discover` skill in runtime-kit.
**PR grouping intent**: group
**Execution Profile**: serial after Sprint 1 command shape is stable

### Task 2.1: Add skill source and manifest entries

- **Location**:
  - `core/skills/meta/plan-archive-discover/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
- **Description**: Add a skill that runs `plan-archive discover --format json`,
  presents eligible/blocked/unknown candidates, and stops for user selection.
  The skill must hand selected folders to `plan-archive-migrate`; it must not
  apply migrations itself.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Skill contract states read-only discovery and no automatic apply.
  - Skill failure modes include missing CLI, archive config, missing refs, and
    ambiguous closeout evidence.
  - Manifest registration renders Codex and Claude targets.
  - Plugin metadata includes the skill in the meta plugin.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `bash scripts/ci/skill-governance-audit.sh`

### Task 2.2: Update runtime floor and generated surfaces

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `build/` or target render output as required by the repo gate
  - `tests/golden/` if render output changes
- **Description**: Update the documented nils-cli surface floor only after the
  released CLI contains `plan-archive discover`. Regenerate rendered skill
  surfaces and committed goldens according to the runtime-kit validation stack.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Runtime-kit does not claim `plan-archive discover` before the CLI floor
    provides it.
  - Rendered Codex/Claude skill surfaces match source templates.
  - Golden output is clean after regeneration.
- **Validation**:
  - `bash scripts/ci/all.sh` or a justified targeted subset if the change is
    docs/skill-only

## Validation Summary

- `plan-tooling validate --file
  docs/plans/2026-05-27-plan-archive-discover/plan-archive-discover-plan.md
  --format text --explain`
- `cargo test -p nils-plan-archive discover`
- `cargo test -p nils-plan-archive migrate`
- `rumdl check` on changed Markdown in both repos
- runtime-kit render and skill governance checks
- full repo gates before final PR delivery when practical

## Handoff Notes

- Start implementation in a dedicated worktree/branch, not the existing
  plan-archive search-layer checkout.
- Treat `discover` as a candidate selector. It may suggest migration commands,
  but `plan-archive-migrate` remains the only path to apply.
- If closeout evidence cannot be inferred confidently from local files, return
  `unknown` with reasons instead of promoting the folder to `eligible`.
