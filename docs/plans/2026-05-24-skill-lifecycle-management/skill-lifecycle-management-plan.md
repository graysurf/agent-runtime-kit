# Plan: Skill Lifecycle Management

## Overview

Deliver repo-native skill lifecycle management for `agent-runtime-kit` so
agents can add, validate, and remove managed skills without reviving the
legacy `agent-kit` path model. The v1 workflow is narrow: a repo governance
audit tool first, the `create-skill` user-facing skill second, and the
`remove-skill` user-facing skill third.

This plan keeps deterministic mutation and parsing out of skill prose. If the
implementation needs stable YAML edits, reference graph output, or dry-run
apply plans, the primitive is extracted to `nils-cli` and the repo skill calls
the released surface. `create-project-skill` and project-local overlay
behavior are explicitly deferred.

## Read First

- Primary source: docs/plans/2026-05-24-skill-lifecycle-management/skill-lifecycle-management-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - [Q1] Deterministic primitive shape: decide during implementation whether
    stable mutation belongs under an `agent-runtime skill ...` command or a
    separate lifecycle binary, after checking `nils-cli` conventions.
  - [Q2] `skill-governance` invocation mode: resolved during execution as a
    repo/CI validation tool, not a user-facing skill.
  - [Q3] `create-project-skill`: defer until project-local overlay semantics
    are designed separately.
  - [Q4] New plugin domains: require an explicit `--new-domain` flag or user
    approval before mutating product/plugin surfaces.

## Scope

- In scope:
  - Add the repo-native lifecycle surfaces `meta:create-skill` and
    `meta:remove-skill`, plus a repo governance audit tool called by those
    workflows and CI.
  - Validate canonical source shape under `core/skills/<domain>/<skill>/`,
    manifest consistency in `manifests/skills.yaml` and
    `manifests/plugins.yaml`, product render paths under `targets/<product>/`,
    skill-usage reminder metadata, golden snapshots, sandbox expectations,
    runtime-smoke coverage, and project-local smoke coverage where relevant.
  - Keep lifecycle helpers dry-run-first and Bash 3.2 compatible when repo
    scripts are sufficient.
  - Extract stable parsers, YAML mutation, reference graph output, JSON
    contracts, or apply planners to `nils-cli` when needed.
  - Add focused docs or runbook updates only where maintainers need the
    lifecycle contract outside this plan bundle.
- Out of scope:
  - Copying the legacy `$HOME/Project/graysurf/agent-kit/skills/tools/skill-management`
    tree.
  - Project-local `.agents/skills` scaffolding or any revival of
    `$HOME/.agents` as a live skill-discovery indirection.
  - Compatibility shims for removed skills unless a specific product surface
    requires an intentional alias.
  - Broad docs-index rewrites for this coordination artifact.

## Assumptions

1. The canonical skill source remains
   `core/skills/<domain>/<skill>/SKILL.md.tera`.
2. `manifests/skills.yaml` and `manifests/plugins.yaml` remain the source of
   product-independent skill and plugin metadata.
3. Product activation and render paths remain owned by `targets/<product>/`
   plus generated `build/<product>/` outputs.
4. Render/golden checks, sandbox install rehearsal, runtime-smoke, project
   overlay smoke, hook tests, and `scripts/ci/all.sh` remain the acceptance
   stack for lifecycle changes.
5. Historical references under `docs/plans/**` are durable coordination
   records and are not rewritten by removal helpers unless explicitly
   requested.

## Sprint 1: Define Governance Contract And Checks

**Goal**: Make the lifecycle contract reviewable before adding mutation
workflows. Define the exact checks that prove a skill source, manifest entry,
plugin containment, product render surface, and acceptance coverage are
consistent.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add skill lifecycle governance audit

- **Location**:
  - `scripts/ci/skill-governance-audit.sh`
  - `tests/runtime-smoke/fixtures/skill-lifecycle/`
  - `scripts/ci/all.sh`
- **Description**: Add a repo validation tool, not a user-facing skill. The
  audit validates source/manifest/plugin/reminder consistency, product render
  paths, `required_clis` floors, runtime-smoke matrix coverage, sandbox
  expected skill lists, and lifecycle create/remove fixtures. Wire it into the
  CI gate so governance runs automatically before skill lifecycle changes are
  delivered.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - Governance is implemented as `scripts/ci/skill-governance-audit.sh`, not as
    `core/skills/meta/skill-governance`.
  - The audit fails on missing source/manifest/plugin/reminder/runtime-smoke or
    sandbox coverage for active skills.
  - The audit has fixture coverage for create-skill completeness and
    remove-skill dry-run reference classes.
  - `scripts/ci/all.sh` invokes the governance audit and its fixtures.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`
  - `bash scripts/ci/skill-governance-audit.sh --fixture create`
  - `bash scripts/ci/skill-governance-audit.sh --fixture remove`
  - `bash scripts/ci/all.sh`

### Task 1.2: Add governance validation coverage

- **Location**:
  - `scripts/ci/all.sh`
  - `tests/runtime-smoke/`
  - `tests/projects/project-local-smoke/`
  - `tests/hooks/`
  - `tests/golden/`
- **Description**: Implement or wire focused checks for the lifecycle
  governance rules: every source skill has a manifest entry, every manifest
  source exists, every skill appears in exactly one plugin containment list,
  product render paths match target conventions, `required_clis` floors are not
  placeholders, reminder metadata names active skills only, and executable
  skill surfaces have matching acceptance coverage. Prefer extending existing
  repo validation positions before adding a new script.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - A broken manifest/source/plugin relationship fails a targeted local check.
  - A stale reminder entry for a removed active skill fails a targeted local
    check.
  - A lifecycle-surface change without the expected acceptance artifact fails
    or reports an explicit waiver.
  - Governance checks are included in the same command path maintainers use
    before PR delivery.
- **Validation**:
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash tests/projects/project-local-smoke/run.sh`
  - `bash tests/hooks/run.sh`
  - `bash scripts/ci/all.sh`

## Sprint 2: Add create-skill Workflow

**Goal**: Add a dry-run-first workflow for adding a managed skill in the
runtime-kit source model, including source, manifests, plugin containment,
render/golden expectations, sandbox expectations, and acceptance coverage.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Add create-skill workflow surface

- **Location**:
  - `core/skills/meta/create-skill/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `core/hooks/shared/skill-usage-reminder.skills.json`
- **Description**: Add `meta:create-skill` as an agent-facing workflow that
  accepts canonical inputs such as `--id <domain.skill>`,
  `--products codex,claude`, `--required-cli <name>=<semver-range>`, and a
  description. The workflow must scaffold the full runtime-kit shape, leave
  staging and commit to the caller, require explicit approval for new plugin
  domains, and call a released `nils-cli` primitive if structured mutation is
  needed.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 5
- **Acceptance criteria**:
  - The workflow creates or describes all required active files for a new
    managed skill: source template, skill manifest entry, plugin containment,
    product render metadata when applicable, golden/sandbox updates, and
    runtime-smoke coverage.
  - New plugin domains are blocked unless the caller provides explicit
    approval.
  - The skill body keeps judgment and sequencing in prose, and delegates stable
    mutation/parsing behavior to repo scripts or released `nils-cli`.
  - The workflow never writes legacy `skills/...` or `.agents/skills` paths.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`

### Task 2.2: Prove create-skill with a sample low-risk skill

- **Location**:
  - `core/skills/meta/`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `tests/runtime-smoke/`
  - `tests/golden/`
- **Description**: Use the new workflow against a low-risk prose-only fixture
  or sample skill so the PR proves the workflow produces a complete
  source/manifest/render/golden/sandbox delta. If committing a permanent sample
  skill is not appropriate, use a deterministic fixture under the existing test
  tree and document why the real repo source is unchanged.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - The create path produces a complete delta that the governance checks
    accept.
  - The test or fixture evidence shows the workflow reports every required
    follow-up artifact instead of silently leaving an incomplete skill.
  - Generated or rendered outputs are either committed intentionally or proven
    clean after validation.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash scripts/ci/all.sh`

## Sprint 3: Add remove-skill Workflow

**Goal**: Add a dry-run-first workflow for removing a managed skill without
leaving active references or rewriting historical plan records by default.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Add remove-skill workflow surface

- **Location**:
  - `core/skills/meta/remove-skill/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `core/hooks/shared/skill-usage-reminder.skills.json`
- **Description**: Add `meta:remove-skill` as a dry-run-first workflow. The
  workflow must identify active source, manifest, plugin, target, golden,
  sandbox, runtime-smoke, hook/reminder, and maintained-doc references for a
  target skill; require explicit apply approval before mutation; exclude
  `docs/plans/**` history by default; and fail if active references remain.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Default dry-run lists every active file that would change and exits without
    mutating files.
  - Apply mode requires explicit approval and leaves no active references
    outside documented allowlists.
  - Historical `docs/plans/**` references are retained unless the caller
    explicitly requests cleanup.
  - The workflow removes stale reminder metadata and product render references
    for the target skill.
- **Validation**:
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash tests/hooks/run.sh`
  - `bash scripts/ci/all.sh`

### Task 3.2: Prove remove-skill against a fixture

- **Location**:
  - `tests/runtime-smoke/fixtures/`
  - `tests/runtime-smoke/`
  - `tests/projects/project-local-smoke/`
  - `tests/golden/`
- **Description**: Add a deterministic removal fixture or test scenario that
  includes source, manifest, plugin, product render, sandbox, runtime-smoke,
  and reminder references. Assert that dry-run reports the full planned delta,
  apply mode removes active references, and retained historical references are
  explicitly classified.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Dry-run output names each active reference class that removal would touch.
  - Apply-mode test leaves no active references for the fixture skill.
  - `docs/plans/**` references are either ignored with an explanation or
    handled only under an explicit cleanup flag.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash tests/projects/project-local-smoke/run.sh`
  - `bash scripts/ci/all.sh`

## Sprint 4: Close Integration And Extraction Decisions

**Goal**: Make the stable lifecycle contract discoverable and decide whether
any deterministic behavior must move into `nils-cli` before closeout.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 4.1: Update stable docs for lifecycle policy

- **Location**:
  - `DEVELOPMENT.md`
  - `docs/source/inventory-target-architecture.md`
  - `docs/source/nils-cli-surface.md`
- **Description**: Promote only stable, maintainer-facing lifecycle policy out
  of the plan bundle. Document the source/manifests/targets acceptance boundary
  and the rule that stable parsing or mutation contracts belong in released
  `nils-cli`, not skill prose.
- **Dependencies**:
  - Task 2.2
  - Task 3.2
- **Complexity**: 2
- **Acceptance criteria**:
  - Maintainers can find the lifecycle boundary without reading this tracker.
  - Stable docs do not duplicate the full plan or implementation session log.
  - `nils-cli` extraction rules match the final implementation decisions.
- **Validation**:
  - `rumdl check DEVELOPMENT.md docs/source/inventory-target-architecture.md docs/source/nils-cli-surface.md`
  - `agent-runtime audit-drift`

### Task 4.2: Resolve nils-cli extraction boundary

- **Location**:
  - `docs/plans/2026-05-24-skill-lifecycle-management/skill-lifecycle-management-execution-state.md`
  - `docs/source/nils-cli-surface.md`
  - `sympoies/nils-cli` upstream issue or PR, if extraction is needed
- **Description**: Record whether lifecycle implementation required a stable
  `nils-cli` primitive. If yes, open or link the upstream issue/PR and pin the
  consumed binary in skill metadata. If no, record the no-extraction decision
  in the execution state and keep repo scripts limited to Bash glue.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 2
- **Acceptance criteria**:
  - The tracker contains a clear final decision for [Q1].
  - Any consumed `nils-cli` surface has a released version requirement in
    `manifests/skills.yaml`.
  - The repo does not introduce an unreleased local parser or mutation engine.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-24-skill-lifecycle-management/skill-lifecycle-management-plan.md --format text --explain`
  - `bash scripts/ci/all.sh`

## Issue Closeout Gate

The tracking issue is complete when:

- Sprint 1 through Sprint 4 tasks are landed on `main` or explicitly closed as
  not needed with issue-visible evidence.
- `meta:create-skill`, `meta:remove-skill`, and the governance audit tool are
  implemented and validated, or have a documented replacement boundary accepted
  by the maintainer.
- Adding one sample low-risk prose skill through the workflow produces a
  complete source/manifest/render/golden/sandbox delta and passes targeted
  validation.
- Removing one fixture skill through dry-run and apply mode reports the full
  active delta and leaves no active references.
- Full `bash scripts/ci/all.sh` is green after the lifecycle changes land.
- The issue dashboard links current validation evidence and the state comment
  records `validation=passed`, `approval=approved`, and the final `nils-cli`
  extraction decision.

## Future Work (Out Of Scope For This Tracker)

- `create-project-skill` for project-local overlays after overlay semantics
  are designed independently.
- Optional aliases or compatibility shims for removed skills when a product
  surface needs an intentional transition period.
- Broader docs index cleanup after the lifecycle policy settles.
