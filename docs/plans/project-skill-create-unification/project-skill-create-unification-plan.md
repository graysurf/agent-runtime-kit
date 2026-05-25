# Plan: Project Skill Create Unification

## Overview

Unify project-local skill creation under the shared
`meta:create-project-skill` workflow. The default behavior creates the
canonical `.agents/skills/<skill>/` source and enables Claude discovery through
the project-local `.claude/skills -> ../.agents/skills` bridge. Codex-only
creation remains explicit. Claude-only creation is removed because it implies a
second source path that this repository intentionally does not support.

## Read First

- Primary source: docs/plans/project-skill-create-unification/project-skill-create-unification-discussion-source.md
- Source type: discussion-to-implementation-doc
- Recommended plan: docs/plans/project-skill-create-unification/project-skill-create-unification-plan.md
- Recommended execution state: docs/plans/project-skill-create-unification/project-skill-create-unification-execution-state.md
- Open questions carried into execution: none; the source document records the
  resolved decisions.

## Scope

- In scope:
  - Update the shared `create-project-skill` skill contract and rendered
    surfaces.
  - Add a shared project-skill creation helper under the
    `create-project-skill` source tree.
  - Remove the Claude-only `create-claude-project-skill` command and script
    surfaces.
  - Update manifests, link maps, support matrix/source docs, fixtures,
    governance checks, runtime-smoke checks, render output, and goldens as
    needed.
  - Preserve `--bridge-only` as the only Claude-specific operation for existing
    `.agents/skills` trees.
- Out of scope:
  - Changing repo-managed `create-skill` or `remove-skill`.
  - Changing `remove-project-skill` behavior except for references required by
    create-side terminology.
  - Adding a `--target claude`, `--claude-only`, or `--link-only`
    compatibility path.
  - Adding project-skill bridge checks to `agent-runtime doctor
    --check-project`.

## Sprint 1: Shared Create Contract

**Goal**: Make the shared `create-project-skill` contract own every supported
creation mode and remove Claude-only semantics from the design.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Update create-project-skill contract

- **Location**:
  - `core/skills/meta/create-project-skill/SKILL.md.tera`
- **Description**: Update the skill contract, inputs, outputs, workflow, and
  boundary text to document default `both`, `--codex-only`, `--target
  both|codex`, and `--bridge-only`. Remove `--target claude`,
  `--claude-only`, `--link-only`, and compatibility-alias language. Keep
  `.agents/skills/<skill>/` as the only canonical project-skill source.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - The skill body documents default Codex+Claude creation.
  - The skill body states that Claude-only creation is unsupported.
  - The skill body describes `--bridge-only` as bridge setup for an existing
    `.agents/skills` tree.
  - The skill body states that `.agents/scripts/pre-pr.sh` creation is
    opt-in.
- **Validation**:
  - `rg -n -- '--claude-only|--target claude|--link-only' core/skills/meta/create-project-skill/SKILL.md.tera`
    returns no active contract references.
  - `rg -n 'create-claude-project-skill' core/skills/meta/create-project-skill/SKILL.md.tera`
    returns no active contract references.

### Task 1.2: Add shared helper entrypoint

- **Location**:
  - `core/skills/meta/create-project-skill/scripts/create-project-skill.sh`
- **Description**: Add a Bash 3.2-compatible helper that implements the shared
  project-skill creation file operations: argument parsing, git root
  resolution, name validation, collision checks, skill stub creation, optional
  support folders, optional script stub, Claude bridge setup, `.gitignore`
  handling, optional wrapper creation, optional pre-pr stub creation, dry-run
  summary, and apply summary.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Default invocation creates `.agents/skills/<skill>/SKILL.md` and ensures
    `.claude/skills -> ../.agents/skills`.
  - `--codex-only` creates only canonical `.agents/skills` content and does not
    mutate `.claude/`.
  - `--bridge-only` refuses to create a new skill and only verifies or creates
    the Claude bridge for an existing `.agents/skills` tree.
  - `--target claude`, `--claude-only`, and `--link-only` exit with usage
    errors.
  - `.agents/scripts/pre-pr.sh` is created only when `--with-pre-pr-stub` is
    supplied.
- **Validation**:
  - `bash -n core/skills/meta/create-project-skill/scripts/create-project-skill.sh`
  - helper fixture invocations for default, `--codex-only`, `--bridge-only`,
    rejected Claude-only flags, and `--with-pre-pr-stub`.

### Task 1.3: Render shared products

- **Location**:
  - `build/codex/plugins/meta/skills/create-project-skill/SKILL.md`
  - `build/claude/plugins/meta/skills/create-project-skill/SKILL.md`
  - `tests/golden/codex/plugins/meta/skills/create-project-skill/expected/SKILL.md`
  - `tests/golden/claude/plugins/meta/skills/create-project-skill/expected/SKILL.md`
- **Description**: Render the updated shared skill for Codex and Claude, update
  golden snapshots, and verify both products expose the same canonical contract.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 2
- **Acceptance criteria**:
  - Codex and Claude rendered `create-project-skill` bodies match the shared
    source semantics.
  - Golden fixtures are updated intentionally.
  - No product render output mentions the removed Claude-only create surface as
    an active workflow.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime audit-drift`

## Sprint 2: Remove Claude-Only Surface

**Goal**: Delete the old Claude-only command/script and update every tracked
reference to point at the shared workflow.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Delete Claude-only command and script

- **Location**:
  - `targets/claude/commands/create-claude-project-skill.md`
  - `targets/claude/scripts/create-claude-project-skill.sh`
- **Description**: Remove the Claude-only slash command and script. Do not
  replace them with an alias. If `targets/claude/commands` or
  `targets/claude/scripts` still contains other files, keep the directory-level
  link-map entries; otherwise remove or adjust them according to the target
  install contract.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 2
- **Acceptance criteria**:
  - The two old Claude-only files are deleted.
  - No compatibility wrapper remains.
  - Target link maps still install all remaining valid Claude target surfaces.
- **Validation**:
  - `test ! -e targets/claude/commands/create-claude-project-skill.md`
  - `test ! -e targets/claude/scripts/create-claude-project-skill.sh`
  - `agent-runtime audit-drift`

### Task 2.2: Update docs, manifests, and support matrix references

- **Location**:
  - `manifests/surfaces.yaml`
  - `tests/golden/shared/SUPPORT_MATRIX.md`
  - `SUPPORT_MATRIX.md`
  - `docs/source/harness-shape-claude.md`
  - `docs/source/inventory-target-architecture.md`
  - `docs/plans/project-skill-create-unification/project-skill-create-unification-execution-state.md`
- **Description**: Replace active references to the Claude-only create command
  with the shared `create-project-skill` workflow or remove the row/reference
  when the old surface no longer exists. Retain historical plan references only
  when they are clearly historical.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Active docs no longer advertise `/create-claude-project-skill`.
  - The support matrix and source docs accurately reflect remaining Claude
    command/script surfaces.
  - Historical `docs/plans/**` references are not rewritten unless they block
    validation.
- **Validation**:
  - `rg -n 'create-claude-project-skill|--link-only' manifests targets core tests`
  - `rg -n 'create-claude-project-skill|--link-only' SUPPORT_MATRIX.md docs/source`
  - `agent-runtime render --target support-matrix --update-golden`
  - `agent-runtime audit-drift`

## Sprint 3: Acceptance Coverage

**Goal**: Prove the unified workflow with fixtures and CI gates.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Extend create-project fixture matrix

- **Location**:
  - `tests/runtime-smoke/fixtures/skill-lifecycle/create-project-skill/`
  - `scripts/ci/skill-governance-audit.sh`
- **Description**: Extend the project-local lifecycle fixture so governance can
  verify default-both creation, Codex-only creation, bridge-only setup for an
  existing skill tree, rejected Claude-only flags, and opt-in pre-pr stub
  behavior.
- **Dependencies**:
  - Task 1.2
  - Task 2.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Fixture expected paths distinguish created, verified, skipped, and refused
    paths.
  - Governance fails if `--target claude`, `--claude-only`, or `--link-only`
    appears as a supported mode.
  - Governance fails if default creation omits the Claude bridge.
  - Governance fails if `.agents/scripts/pre-pr.sh` is created by default.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh --fixture create-project`

### Task 3.2: Extend runtime-smoke coverage

- **Location**:
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `tests/runtime-smoke/cases/meta/run.sh`
- **Description**: Update the meta runtime-smoke case so it exercises the
  shared helper or fixture outputs for every supported mode and asserts the old
  Claude-only surface is absent.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Runtime-smoke covers default-both, Codex-only, bridge-only, and rejected
    removed flags.
  - Runtime-smoke asserts no independent Claude-only helper remains.
  - Acceptance matrix text names the unified behavior accurately.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`

### Task 3.3: Run full validation and record follow-up

- **Location**:
  - `docs/plans/project-skill-create-unification/project-skill-create-unification-execution-state.md`
- **Description**: Run focused validation and the full repository gate. Record
  any deferred `agent-runtime doctor --check-project` bridge probe as a
  follow-up only if implementation evidence shows it is worth productizing.
- **Dependencies**:
  - Task 1.3
  - Task 2.2
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Focused governance, runtime-smoke, render, and audit-drift checks pass.
  - `bash scripts/ci/all.sh` passes or any failure has a documented unrelated
    cause and exact unblock action.
  - Execution state records whether a doctor follow-up is needed.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh --fixture create-project`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/all.sh`
