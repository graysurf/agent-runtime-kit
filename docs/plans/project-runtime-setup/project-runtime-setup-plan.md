# Plan: Project Runtime Setup

## Overview

Trim low-value repo script dispatcher skills from the managed runtime surface,
then add a `setup-project` workflow that helps a target repository adopt the
project-local `.agents/` conventions used by the retained dispatcher skills.
The retained high-value dispatchers remain thin wrappers over repository-owned
scripts; the new setup workflow makes those scripts discoverable and auditable
instead of relying on users to remember every global skill name.

## Read First

- Primary source: docs/plans/project-runtime-setup/project-runtime-setup-discussion-source.md
- Source type: discussion-to-implementation-doc
- Recommended plan: docs/plans/project-runtime-setup/project-runtime-setup-plan.md
- Recommended execution state: docs/plans/project-runtime-setup/project-runtime-setup-execution-state.md
- Open questions carried into execution: none; the source document records the
  resolved direction and implementation boundaries.

## Scope

- In scope:
  - Remove managed `bench` and `demo` dispatcher skills from runtime-kit.
  - Keep managed `bootstrap`, `deploy`, `pre-pr`, and `release` dispatchers.
  - Add a managed `setup-project` workflow for project-local runtime adoption.
  - Make adopted-repo diagnostics fail closed when executable
    `.agents/scripts/pre-pr.sh` is missing.
  - Update manifests, plugin metadata, render output, golden snapshots, support
    docs, sandbox expected lists, runtime-smoke, and project-local smoke
    fixtures.
  - Coordinate any required `nils-cli` changes for `agent-runtime doctor
    --check-project`, release them, then consume the released floor here.
- Out of scope:
  - Removing project-owned `.agents/scripts/bench.sh` or
    `.agents/scripts/demo.sh` conventions from consuming repositories.
  - Renaming the existing `bootstrap` dispatcher.
  - Installing host/global runtime tooling from `setup-project`.
  - Adding generic fallback validation inside the `pre-pr` skill.
  - Deleting historical plan records that mention the retired dispatcher skills.

## Sprint 1: Managed Dispatcher Surface Cleanup

**Goal**: Remove `bench` and `demo` from the globally installed managed skill
surface while preserving the project-owned script convention for repositories
that still want those entrypoints locally.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Remove managed bench and demo skill sources

- **Location**:
  - `core/skills/meta/`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
- **Description**: Delete the repo-owned managed skill sources for `bench` and
  `demo`, remove their manifest entries, and remove plugin references that
  advertise them as installed managed skills. Keep no compatibility aliases.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `meta.bench` and `meta.demo` no longer appear in active managed skill
    manifests.
  - Plugin metadata no longer lists `bench` or `demo` as installed managed
    skills.
  - Project-owned `.agents/scripts/bench.sh` and `.agents/scripts/demo.sh` remain
    allowed by convention but are not globally dispatched by managed skills.
- **Validation**:
  - `rg -n "meta\\.(bench|demo)|name: (bench|demo)" manifests core/skills/meta`
  - `bash scripts/ci/skill-governance-audit.sh`

### Task 1.2: Refresh render output, goldens, and expected skill lists

- **Location**:
  - `targets/codex/link-map.yaml`
  - `targets/claude/link-map.yaml`
  - `targets/codex/plugins/meta/.codex-plugin/plugin.json`
  - `targets/claude/plugins/meta/.claude-plugin/plugin.json`
  - `tests/golden/`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/sandbox/claude/expected-skills.txt`
  - runtime-smoke expected summary fixtures when counts change
- **Description**: Render Codex and Claude after the managed surface removal,
  update golden snapshots, and update expected installed skill lists/count
  fixtures so removal is intentional rather than treated as drift.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Rendered Codex and Claude output contains no managed `bench` or `demo` skill
    bodies.
  - Expected skill lists exclude `meta.bench` and `meta.demo`.
  - Golden diffs contain only the intended managed-surface removal.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime doctor --class skill-surface --product codex`
  - `agent-runtime doctor --class skill-surface --product claude`

### Task 1.3: Update dispatcher docs and smoke fixtures

- **Location**:
  - `docs/source/inventory-target-architecture.md`
  - `docs/source/harness-shape-codex.md`
  - `docs/source/harness-shape-claude.md`
  - `DEVELOPMENT.md`
  - `tests/projects/project-local-smoke/`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `tests/runtime-smoke/cases/meta/run.sh`
- **Description**: Update active docs and smoke fixtures so the managed
  dispatcher set is `bootstrap`, `deploy`, `pre-pr`, and `release`. Remove
  `bench` and `demo` from managed-skill acceptance, while preserving text that
  consuming repositories may keep their own local helper scripts.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Active docs no longer claim that `bench` and `demo` are globally installed
    managed dispatchers.
  - Project-local smoke validates retained dispatchers only.
  - Runtime-smoke matrix and meta deterministic probes match the retained set.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode matrix`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash tests/projects/project-local-smoke/run.sh`

## Sprint 2: Setup Project Workflow

**Goal**: Add a managed setup workflow that guides unadopted or partially
adopted repositories into the project-local `.agents/` layout required by the
retained dispatcher skills.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Define setup-project contract and adoption model

- **Location**:
  - `core/skills/meta/setup-project/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `docs/source/inventory-target-architecture.md`
- **Description**: Add the managed `setup-project` skill contract. Document that
  setup is dry-run-first, repo-local, and separate from host/global bootstrap.
  Define how a repository is considered adopted, including the setup-owned
  marker or equivalent local state used by diagnostics to distinguish unadopted
  repos from adopted-but-incomplete repos.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 4
- **Acceptance criteria**:
  - The skill body clearly separates `setup-project` from `bootstrap`.
  - The skill body states that host runtime installation remains owned by
    `scripts/setup.sh` and released install docs.
  - The adopted-repo model is explicit enough for fixture tests and doctor
    diagnostics.
  - The workflow refuses destructive overwrite by default.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`
  - `plan-tooling validate` on this plan with `--format text --explain`

### Task 2.2: Add setup-project helper and fixtures

- **Location**:
  - `core/skills/meta/setup-project/scripts/setup-project.sh`
  - `tests/runtime-smoke/fixtures/skill-lifecycle`
  - `tests/runtime-smoke/cases/meta/run.sh`
- **Description**: Add a Bash 3.2-compatible helper for dry-run and apply mode.
  It should inspect `.agents/`, `.agents/scripts/`, `.agents/skills/`, and common
  project validation entrypoints; report adoption state; and create required
  directories plus an executable `pre-pr.sh` only from an explicit or confirmed
  validation command. Optional `bootstrap.sh`, `release.sh`, `deploy.sh`, and
  project-local skill wrapper creation must remain opt-in.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Dry-run reports unadopted, partial, and adopted states without mutation.
  - Apply mode can create the required project-local structure.
  - Generated `pre-pr.sh` either runs a confirmed command or fails clearly; no
    successful empty placeholder is generated.
  - Existing files are never overwritten without explicit approval.
  - Optional wrapper/project-skill behavior delegates to or stays compatible with
    `create-project-skill`.
- **Validation**:
  - `bash -n core/skills/meta/setup-project/scripts/setup-project.sh`
  - setup-project fixture dry-run/apply checks
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`

### Task 2.3: Render setup-project across products

- **Location**:
  - `tests/golden/codex/plugins/meta/skills/setup-project/expected/SKILL.md`
  - `tests/golden/claude/plugins/meta/skills/setup-project/expected/SKILL.md`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/sandbox/claude/expected-skills.txt`
  - `targets/codex/link-map.yaml`
  - `targets/claude/.claude-plugin/marketplace.json`
- **Description**: Render the new managed skill for Codex and Claude, update
  golden snapshots, and add it to expected skill lists and support surfaces.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Codex and Claude both expose `setup-project`.
  - Golden snapshots match the shared source.
  - Sandbox expected skill lists include the new skill and still exclude removed
    `bench` and `demo`.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`

## Sprint 3: Pre-PR Adoption Diagnostics

**Goal**: Make the retained `pre-pr` dispatcher and project diagnostics enforce
the adopted-repo contract without blocking arbitrary unadopted checkouts.

**PR grouping intent**: group
**Execution Profile**: serial with coupled nils-cli release boundary

### Task 3.1: Add or consume adopted-repo doctor diagnostics

- **Location**:
  - `sympoies/nils-cli` `agent-runtime doctor --check-project` implementation
  - `docs/source/nils-cli-surface.md`
  - `manifests/skills.yaml`
  - `tests/projects/project-local-smoke/`
- **Description**: Implement and release any required `nils-cli` support so
  `agent-runtime doctor --check-project <repo>` can classify unadopted,
  partially adopted, and adopted repos. Adopted repos missing executable
  `.agents/scripts/pre-pr.sh` must produce a blocking finding; unadopted repos
  should receive a setup recommendation rather than a blocker.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 7
- **Acceptance criteria**:
  - Released `agent-runtime` can distinguish adopted from unadopted repos using
    the setup adoption model.
  - Adopted repos missing executable `pre-pr.sh` fail closed.
  - Unadopted repos get actionable setup guidance without failing unrelated
    checks.
  - Runtime-kit updates its consumed nils-cli surface floor only after the
    required release is available.
- **Validation**:
  - nils-cli targeted doctor tests
  - `agent-runtime --version`
  - `agent-runtime doctor --check-project tests/projects/project-local-smoke`
  - `bash tests/projects/project-local-smoke/run.sh`

### Task 3.2: Update pre-pr missing-script guidance

- **Location**:
  - `core/skills/meta/pre-pr/SKILL.md.tera`
  - `tests/golden/codex/plugins/meta/skills/pre-pr/expected/SKILL.md`
  - `tests/golden/claude/plugins/meta/skills/pre-pr/expected/SKILL.md`
  - `core/policies/heuristic-system/error-inbox/pre-pr-cli-repo-local-fallback/ENTRY.md`
- **Description**: Update `pre-pr` so missing `.agents/scripts/pre-pr.sh`
  reports the target repo and points to `setup-project`. Close or update the
  heuristic-system inbox entry only when the implemented behavior satisfies its
  promotion criteria.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Missing-script guidance names `setup-project` as the adoption path.
  - The skill still refuses generic fallback validation.
  - The heuristic-system entry records the landed fix or remains open with the
    remaining gap.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - focused missing-script fixture or smoke case

### Task 3.3: Final validation and tracker closeout prep

- **Location**:
  - `docs/plans/project-runtime-setup/project-runtime-setup-execution-state.md`
  - `docs/plans/project-runtime-setup/`
- **Description**: Run the focused and full validation stack, record all results
  in execution state, and prepare the issue-backed tracker for implementation
  closeout after PR review and delivery.
- **Dependencies**:
  - Task 1.3
  - Task 2.3
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - `bench` and `demo` are absent from live managed skill expectations.
  - `setup-project` is present and fixture-covered.
  - Adopted repo missing `pre-pr.sh` is a blocking diagnostic.
  - Full local repository gate passes or any blocker is classified with exact
    follow-up.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`
  - `bash tests/runtime-smoke/run.sh --mode matrix`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash tests/projects/project-local-smoke/run.sh`
  - `bash scripts/ci/all.sh`

## Validation And Delivery Gate

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `plan-tooling validate` on this plan with `--format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --target support-matrix`
- `agent-runtime audit-drift`
- `bash scripts/ci/skill-governance-audit.sh`
- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash scripts/ci/all.sh`

## Rollback Notes

- If removal of `bench` or `demo` breaks active runtime acceptance, revert the
  removal as a single managed-surface change and restore the previous expected
  skill lists and smoke fixtures.
- If `setup-project` helper behavior proves too broad for a skill-owned shell
  helper, freeze the skill body and extract deterministic dry-run/apply behavior
  to `nils-cli` before continuing.
- If nils-cli doctor support is delayed, land the surface cleanup and
  `setup-project` workflow first, then keep adopted-repo blocking diagnostics as
  a tracked follow-up rather than weakening the `pre-pr` contract.
