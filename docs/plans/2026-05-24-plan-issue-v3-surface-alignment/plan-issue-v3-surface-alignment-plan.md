# Plan: plan-issue V3 Surface Alignment

## Overview

Align `agent-runtime-kit` and `nils-cli` on the current `plan-issue record`
v3 surface. Runtime-kit skills, rendered outputs, docs, manifests, and
runtime-smoke tests should teach and validate only `record open`, `record
post`, `record repair-dashboard`, `record close`, and `record audit`.
`nils-cli` should then remove the retired transitional helper commands so the
old workflow is not preserved as a maintenance burden.

## Read First

- Primary source: docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-discussion-source.md
- Source type: discussion-to-implementation-doc
- Heuristic tracking entry: core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift/ENTRY.md
- Open questions carried into execution:
  - [Q1] Decide delivery ordering for runtime-kit alignment versus nils-cli
    helper removal after inspecting nils-cli tests and release constraints.
  - [Q2] Confirm whether `record close` subsumes closeout comment and dashboard
    repair, or whether `record post --kind closeout` plus
    `record repair-dashboard` remains the pre-close sequence.
  - [Q3] Pick the runtime-kit `plan-issue` minimum version after the nils-cli
    removal PR lands or a release boundary is known.

## Scope

- In scope:
  - Update the 11 affected active runtime-kit skill source templates listed in
    the source document.
  - Update rendered Codex and Claude skill outputs, golden snapshots, runtime
    smoke cases, acceptance matrix text, references, docs, and manifest pins.
  - Add or update checks that prevent active runtime-kit surfaces from
    reintroducing retired helper commands as current workflows.
  - Remove the retired helper subcommands and active docs/tests from
    `/Users/terry/Project/sympoies/nils-cli`.
  - Keep the heuristic inbox case strict-valid and link delivery evidence.
- Out of scope:
  - Rewriting historical plan bundles and archived heuristic records.
  - Adding compatibility aliases for removed commands.
  - Changing unrelated `forge-cli` label behavior.

## Assumptions

1. The supported issue-backed record flow is `record open`, `record post`,
   `record repair-dashboard`, `record close`, and `record audit`.
2. Active runtime-kit skill text should be stricter than currently installed
   CLI compatibility and should not document retired helpers as allowed.
3. `nils-cli` can remove retired helper support in a focused `plan-issue-cli`
   change without changing marker payload semantics.
4. Runtime-kit validation should prove both source templates and rendered
   product skill bodies are free of retired helper workflow instructions.

## Sprint 1: Track And Align Runtime-Kit Skill Surfaces

**Goal**: Update every active runtime-kit skill that teaches or calls retired
`plan-issue record` helper commands so it describes the v3 primary surface.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Update lightweight tracking skill family

- **Location**:
  - `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- **Description**: Replace retired helper workflows with `record open`,
  `record post`, `record repair-dashboard`, `record close`, and `record audit`.
  Make `create-plan-tracking-issue` use `record open` as the issue creation
  flow, execution skills use `record post` for lifecycle comments, and closeout
  skills use the v3 close flow after audit evidence is current.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - No active lightweight tracking skill presents `render-dashboard`,
    `render-comment`, or `closeout-gate` as the current workflow.
  - The four skill bodies explain the `plan-issue` / `forge-cli` boundary using
    the v3 surface.
  - `create-plan-tracking-issue` no longer teaches manual issue creation when
    `record open` owns initial issue/comment/dashboard creation.
- **Validation**:
  - `rg -n "render-dashboard|render-comment|closeout-gate|build-dispatch-ledger" core/skills/dispatch/{create-plan-tracking-issue,execute-plan-tracking-issue,deliver-plan-tracking-issue,plan-tracking-issue-closeout}`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 1.2: Update dispatch and PR delivery skill family

- **Location**:
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  - `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
  - `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
  - `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
  - `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera`
  - `core/skills/pr/deliver-github-pr/SKILL.md.tera`
  - `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
  - `core/skills/dispatch/deliver-dispatch-plan/references/`
  - `core/skills/dispatch/dispatch-plan-closeout/references/`
- **Description**: Align dispatch-plan creation, lane/session/review comments,
  PR chained closeout, and local rehearsal references to the v3 surface. Remove
  dispatch-ledger helper assumptions unless execution proves a current
  replacement is still needed.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - The seven source skill templates and two reference areas no longer present
    retired helpers as current commands.
  - Dispatch workflows use `record open` for issue creation where plan bundles
    are available and `record post` for subsequent lifecycle comments.
  - Closeout paths describe `record close` as the strict close gate and
    provider close owner.
- **Validation**:
  - `rg -n "render-dashboard|render-comment|closeout-gate|build-dispatch-ledger" core/skills/dispatch core/skills/pr`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

## Sprint 2: Update Runtime-Kit Validation And Documentation

**Goal**: Make repository checks, docs, manifests, and rendered outputs enforce
the v3 surface rather than preserving the retired helper path.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Update docs, manifests, and rendered outputs

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `manifests/skills.yaml`
  - `targets/`
  - `tests/golden/`
  - rendered product output generated by `agent-runtime render`
- **Description**: Document the v3 `plan-issue` record contract, adjust
  affected `required_clis` floors, and regenerate product outputs and golden
  snapshots.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Current source docs describe the v3 surface and do not document retired
    helpers as accepted active commands.
  - Affected manifest entries require a `plan-issue` version that matches the
    v3 contract.
  - Codex and Claude rendered skills match source templates.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime audit-drift`

### Task 2.2: Update runtime-smoke and drift checks

- **Location**:
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `tests/runtime-smoke/cases/dispatch/run.sh`
  - `tests/runtime-smoke/cases/pr/run.sh`
  - `scripts/ci/`
- **Description**: Update deterministic smoke coverage so it exercises the v3
  surface and rejects active docs or rendered skill text that still teaches
  retired helper commands.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Runtime-smoke no longer invokes retired helper commands.
  - A focused check fails if active source or rendered skills reintroduce the
    retired helper command names outside historical allowlisted paths.
  - Full local CI remains green.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
  - `bash scripts/ci/all.sh`

## Sprint 3: Remove Retired Helpers From nils-cli

**Goal**: Delete the transitional helper support from `nils-cli` so the retired
commands are no longer accepted by the CLI or documented as usable.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Remove helper subcommands and active docs/tests

- **Location**:
  - `docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-execution-state.md`
- **Description**: In the external repository
  `/Users/terry/Project/sympoies/nils-cli`, remove `plan-issue record
  render-dashboard`, `render-comment`, `closeout-gate`, and
  `build-dispatch-ledger` from the CLI command surface. Remove or rewrite
  active docs/tests that assert those commands exist. Keep historical changelog
  or release notes only when clearly historical.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 5
- **Acceptance criteria**:
  - `plan-issue record --help` no longer lists the retired helpers.
  - Invoking any removed helper returns an unrecognized-subcommand usage error.
  - nils-cli tests/docs no longer preserve the helpers as supported current
    behavior.
- **Validation**:
  - nils-cli focused `plan-issue` tests
  - nils-cli repository check command from its `DEVELOPMENT.md`
  - `plan-issue record --help`
  - `plan-issue record render-comment --help` returns usage error

### Task 3.2: Verify downstream alignment and update tracking

- **Location**:
  - `core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift/ENTRY.md`
  - `docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-execution-state.md`
  - runtime-kit and nils-cli PR or issue records
- **Description**: Record final validation, update the heuristic entry with
  links to the delivered runtime-kit and nils-cli changes, and leave explicit
  follow-up if a release boundary is still pending.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Heuristic inbox entry remains strict-valid.
  - Execution state lists affected skills and final disposition.
  - Any nils-cli release or downstream pin follow-up is explicit and linked.
- **Validation**:
  - `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json`
  - `plan-tooling validate --file docs/plans/2026-05-24-plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain`
