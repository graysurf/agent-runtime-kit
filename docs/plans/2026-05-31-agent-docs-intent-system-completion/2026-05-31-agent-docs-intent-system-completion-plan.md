# Plan: agent-docs Intent System Completion

## Overview

Complete the residual agent-docs intent-system gaps tracked in
`graysurf/agent-runtime-kit#217` using the user-selected Option C. This is a
cross-repo plan: nils-cli owns the `agent-docs` primitive for fail-closed
declared-intent checks, and runtime-kit owns the hook/catalog consumers,
validation, pin bump, and issue closeout.

The plan intentionally keeps the two repos in sequence. The runtime-kit
finish-line and cue fixes can be developed locally, but the runtime-kit pin
cannot move until nils-cli ships a release containing the new primitive.

## Read First

- Primary source:
  `docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-discussion-source.md`
- Source type: existing issue/spec
- Source issue: `graysurf/agent-runtime-kit#217`
- Runtime-kit anchors:
  - `AGENT_DOCS.toml`
  - `core/hooks/shared/hook_common.py`
  - `core/hooks/shared/finish-line-record.py`
  - `core/hooks/shared/stop-finish-line-gate.py`
  - `core/hooks/shared/user-prompt-agent-docs.sh`
  - `tests/hooks/test_shared_hooks.py`
  - `docs/source/nils-cli-pin.yaml`
  - `docs/source/nils-cli-surface.md`
  - `docs/source/nils-cli-version-workflows.md`
- nils-cli anchors:
  - `crates/agent-docs/src/model.rs`
  - `crates/agent-docs/src/resolver.rs`
  - `crates/agent-docs/src/cli.rs`
  - `crates/agent-docs/tests/integration/preflight.rs`
  - `crates/agent-docs/tests/integration/explain_list_remove.rs`
- Open questions carried into execution:
  - Exact nils-cli flag name and failure semantics for the declared-intent
    guard.
  - Whether guarded `preflight` should treat an intent declared only by
    optional docs as declared.

## Scope

In scope:

- Open an L2 plan-tracking issue from this bundle.
- Design and implement a nils-cli `agent-docs` primitive that lets callers
  fail closed for mistyped or unresolved requested intents.
- Release nils-cli and update the Homebrew tap.
- Update runtime-kit finish-line enforcement so every declared validation
  contract is enforced, not only `project-dev`.
- Update runtime-kit cue composition so truncated required-doc lists are
  visibly marked.
- Reclassify `core/policies/cli-tools.md` as optional for the `task-tools`
  intent while keeping `core/policies/external-facts.md` required.
- Integrate the new nils-cli primitive where runtime-kit benefits from
  fail-closed declared-intent checks.
- Bump the runtime-kit nils-cli pin through the standard bump flow and close
  the tracker.

Out of scope:

- Keyword-gated or language-specific task detection.
- Hardcoded nils-cli builtins for known intent names.
- Moving the runtime-kit nils-cli pin before the nils-cli release exists.
- Changing the broader plan-issue lifecycle model.

## Assumptions

1. `sympoies/nils-cli` remains available locally at
   `/Users/terry/Project/sympoies/nils-cli`.
2. Runtime-kit continues to pin exactly one released nils-cli surface through
   `docs/source/nils-cli-pin.yaml`.
3. Runtime-kit content gates may be run against an unreleased nils-cli binary
   with `scripts/dev/with-nils-version.sh`, but full `scripts/ci/all.sh` only
   passes once the host binary matches the pin.
4. GitHub is the provider for the runtime-kit tracking issue, so both
   `workflow::plan` and `workflow::tracking` labels can be applied.

## Sprint 1: Step 1 - L2 Tracking Record

**Goal**: Create a provider-backed plan-tracking issue for this cross-repo
effort.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Create the plan bundle and open the tracker

- **Location**:
  - `docs/plans/2026-05-31-agent-docs-intent-system-completion/`
- **Description**: Freeze #217, the user-selected Option C, the six-step
  sequence, and the initial task ledger into this plan bundle. Validate it,
  dry-run `plan-issue record open`, then open the provider tracker if the
  preview matches the intended issue.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - Bundle has source, plan, and execution-state files.
  - `plan-tooling validate --file <plan> --format text --explain` passes.
  - Provider issue contains source, plan, and initial state lifecycle
    evidence.
  - Local run state is initialized for the provider issue.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md --format text --explain`
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.

## Sprint 2: Step 2 - nils-cli Design Spike

**Goal**: Decide the minimal fail-closed `agent-docs` primitive for explicitly
requested intents.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 2.1: Specify the declared-intent guard contract

- **Location**:
  - `sympoies/nils-cli` `crates/agent-docs`
- **Description**: Choose the exact CLI contract for failing closed when a
  requested intent is not declared. The preferred design is an opt-in flag on
  `preflight`, preserving the current permissive default for compatibility.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Design states what counts as declared: document entry, validation entry,
    or both.
  - Design states behavior for an intent declared only by optional docs.
  - Design states exit code and JSON/text output shape on failure.
  - Design does not hardcode known intent names.
- **Validation**:
  - A short nils-cli design note or PR description section covers the above.

## Sprint 3: Step 3 - nils-cli Implementation PR

**Goal**: Implement, test, and merge the selected nils-cli primitive.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Implement the declared-intent guard

- **Location**:
  - `sympoies/nils-cli` `crates/agent-docs`
- **Description**: Implement the selected CLI contract and tests. Preserve
  current default behavior unless the design spike explicitly decides a
  breaking change is acceptable.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - A mistyped intent such as `project_dev` fails when the guard is enabled.
  - A declared intent such as `project-dev` succeeds when the guard is
    enabled.
  - Existing unguarded `preflight --intent no-such-intent` compatibility is
    either preserved or intentionally changed with updated tests.
  - nils-cli PR is merged.
- **Validation**:
  - `cargo test -p agent-docs`
  - Any broader nils-cli checks required by that repo before PR delivery.

## Sprint 4: Step 4 - nils-cli Release

**Goal**: Ship the nils-cli primitive in a released binary surface.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Release nils-cli and update the Homebrew tap

- **Location**:
  - `sympoies/nils-cli`
  - `sympoies/homebrew-tap`
- **Description**: Cut the nils-cli release containing Task 3.1, update the
  tap, and upgrade the local host installation.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Release tag exists.
  - Homebrew tap points at the release.
  - Local `agent-docs --version` reports the released version.
- **Validation**:
  - `brew upgrade sympoies/tap/nils-cli`
  - `agent-runtime --version`
  - `agent-docs --version`

## Sprint 5: Step 5 - Runtime-kit Consumer Changes

**Goal**: Fix gaps 1-3 in runtime-kit and consume the new nils-cli primitive
for gap 4.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 5.1: Make finish-line validation intent-aware

- **Location**:
  - `core/hooks/shared/hook_common.py`
  - `core/hooks/shared/finish-line-record.py`
  - `core/hooks/shared/stop-finish-line-gate.py`
  - `tests/hooks/test_shared_hooks.py`
- **Description**: Replace the single `project-dev` validation contract lookup
  with enforcement for every declared validation contract that applies to the
  repo.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 3
- **Acceptance criteria**:
  - A fixture with both `project-dev` and another validation-bearing intent
    requires both contracts after a code edit.
  - Existing waiver, suppression, docs-only, and no-contract cases still pass.
- **Validation**:
  - `bash tests/hooks/run.sh`

### Task 5.2: Make required-doc cue truncation explicit

- **Location**:
  - `core/hooks/shared/user-prompt-agent-docs.sh`
  - `tests/hooks/test_shared_hooks.py`
- **Description**: Keep the cue concise but append an overflow marker when an
  intent has more required docs than the rendered list includes.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 1
- **Acceptance criteria**:
  - A fixture with seven required docs renders the first six plus an explicit
    `+1 more` or equivalent marker.
  - Existing multi-intent cue behavior still passes.
- **Validation**:
  - `bash tests/hooks/run.sh`

### Task 5.3: Reclassify `cli-tools.md` as optional for `task-tools`

- **Location**:
  - `AGENT_DOCS.toml`
  - any generated targets or goldens affected by rendered skill/docs output
- **Description**: Keep `external-facts.md` required for `task-tools`, but
  make `cli-tools.md` optional and auditable.
- **Dependencies**:
  - Task 5.2
- **Complexity**: 1
- **Acceptance criteria**:
  - `agent-docs preflight --intent task-tools --format json` reports only
    `external-facts.md` as required.
  - `cli-tools.md` remains present in `agent-docs list` as optional.
- **Validation**:
  - `agent-docs preflight --intent task-tools --format json`
  - `agent-docs list --format json`

### Task 5.4: Integrate the new nils-cli primitive

- **Location**:
  - runtime-kit hook or CI surface selected during Task 2.1
- **Description**: Use the released nils-cli fail-closed declared-intent
  primitive where runtime-kit explicitly requests known intent names, so a
  mistyped hook call cannot silently resolve an empty preflight.
- **Dependencies**:
  - Task 4.1
  - Task 5.1
- **Complexity**: 2
- **Acceptance criteria**:
  - A targeted test proves the hook or CI path fails closed for a mistyped
    requested intent when the new primitive is enabled.
  - The normal `project-dev` and `task-tools` paths continue to work.
- **Validation**:
  - `bash tests/hooks/run.sh`
  - targeted `agent-docs` command demonstrating the new primitive.

## Sprint 6: Step 6 - Pin Bump And Closeout

**Goal**: Align runtime-kit with the released nils-cli surface and close the
tracking record.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 6.1: Bump runtime-kit nils-cli pin and deliver

- **Location**:
  - `docs/source/nils-cli-pin.yaml`
  - `docs/source/nils-cli-surface.md`
  - manifests and generated/golden output touched by the bump flow
- **Description**: Use the standard nils-cli bump workflow after the host
  binary is upgraded. Run full runtime-kit validation, deliver the PR, and
  record closeout evidence on the tracking issue.
- **Dependencies**:
  - Task 5.4
- **Complexity**: 3
- **Acceptance criteria**:
  - Host nils-cli version matches `docs/source/nils-cli-pin.yaml`.
  - Runtime-kit PR is merged.
  - `graysurf/agent-runtime-kit#217` is linked to the tracking record and has
    a final resolution path.
  - Plan-tracking issue closeout passes.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`
  - plan-tracking close-ready and closeout checks.
