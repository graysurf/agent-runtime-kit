# Plan: Plan Issue Lifecycle Comment Visibility

## Overview

Make plan-tracking issue lifecycle comments complete and readable. The durable
fix is split across `nils-cli` and `agent-runtime-kit`: `nils-cli` owns the
stable `plan-issue record post` / `record close` contract and renderer, while
runtime-kit skills own workflow discipline, smoke coverage, rendered skill
surfaces, and the consumed released CLI floor.

## Read First

- Primary source: docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-review-source.md
- Source type: discussion-to-implementation-doc
- Recommended plan: docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-plan.md
- Recommended execution state: docs/plans/plan-issue-lifecycle-comment-visibility/plan-issue-lifecycle-comment-visibility-execution-state.md
- Open questions carried into execution: none; the source document records the
  resolved decisions.

## Scope

- In scope:
  - Add a first-class `plan-issue record post --kind state
    --execution-state-file <path>` surface in `sympoies/nils-cli`.
  - Add `--task-ledger-display auto|collapsed|expanded` for state comments.
  - Collapse non-final Task Ledgers and expand final Task Ledgers by default.
  - Render validation, review, session, and closeout payload details into
    visible lifecycle comments so hidden payloads are not the only detailed
    evidence.
  - Update runtime-kit tracking skills to post canonical execution-state
    markdown for state lifecycle comments and detailed visible evidence for
    validation, review, session, and closeout comments.
  - Update runtime-smoke coverage so visible state, validation, review, session,
    and closeout comment bodies are tested.
  - Release or consume nils-cli `z+1`, then update runtime-kit's documented
    nils-cli floor and rendered skill surfaces.
- Out of scope:
  - Bulk repairing historical issues other than the already repaired issue #112.
  - Changing the hidden `plan-issue-record-payload:hex` carrier format.
  - Removing `--summary-file` from session, validation, review, or closeout
    lifecycle comments.
  - Making mutable issue dashboards the durable task ledger.

## Sprint 1: nils-cli Lifecycle Comment Contract

**Goal**: Teach `plan-issue record post` and `record close` to render useful
visible lifecycle comments for every tracked kind, while preserving hidden
payloads for machine audit.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add state execution-state file CLI input and visible gates

- **Location**:
  - `sympoies/nils-cli/crates/plan-issue-cli/src/commands/record.rs`
  - `sympoies/nils-cli/crates/plan-issue-cli/src/execute.rs`
- **Description**: Add `--execution-state-file <path>` to `record post`.
  Accept it only for `--kind state`, make it mutually exclusive with
  `--summary-file`, read and validate the markdown file, and add a renderer
  guard that rejects Profile-only lifecycle comments for every postable kind.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `record post --kind state --execution-state-file <path>` renders the full
    execution-state markdown in dry-run and fixture comment bodies.
  - Non-state `--execution-state-file` usage fails clearly.
  - Missing, empty, or Task-Ledger-less files fail clearly.
  - State, session, validation, review, and closeout render paths cannot emit a
    heading plus profile-only visible body.
  - Existing non-state `--summary-file` usage still works.
- **Validation**:
  - `cargo test -p plan-issue-cli record_post_state_execution_state_file`
  - `cargo test -p plan-issue-cli cli_contract`

### Task 1.2: Add Task Ledger display modes and evidence renderers

- **Location**:
  - `sympoies/nils-cli/crates/plan-issue-cli/src/commands/record.rs`
  - `sympoies/nils-cli/crates/plan-issue-cli/src/lifecycle_record.rs`
  - `sympoies/nils-cli/crates/plan-issue-cli/src/execute.rs`
- **Description**: Add `--task-ledger-display auto|collapsed|expanded`.
  Default to `auto` for state comments. In `auto`, expand final state comments
  when payload status is complete and all task rows are terminal; collapse
  non-final state comments by wrapping only the Task Ledger section in a
  GitHub-supported `<details>` block. Add deterministic visible renderers for
  validation, review, session, and closeout payloads, and make `record close`
  use the closeout renderer.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Non-final state comments keep `## Task Ledger` visible and place ledger
    rows inside `<details><summary>Show task ledger</summary>`.
  - Final state comments show the Task Ledger expanded with no `<details>`
    wrapper around the ledger rows.
  - `record open` and `record attach` initial states collapse non-final
    ledgers by default.
  - Hidden payload carriers remain outside the collapsed details block.
  - Validation comments visibly show overall status and command rows.
  - Review comments visibly show decision, lenses, findings, and retained review
    evidence links when present.
  - Closeout comments visibly show approval, linked PR, merge SHA, check status,
    override, and note details.
- **Validation**:
  - `cargo test -p plan-issue-cli state_task_ledger_display`
  - `cargo test -p plan-issue-cli lifecycle_visible_evidence`
  - `cargo test -p plan-issue-cli live_record_ops`

### Task 1.3: Validate local nils-cli binary for runtime-kit consumption

- **Location**:
  - `sympoies/nils-cli`
  - `agent-runtime-kit`
- **Description**: Run focused nils-cli tests, build the local debug binary, and
  use command-scoped `PATH` or direct binary invocation to validate runtime-kit
  changes before the nils-cli release is cut.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Local `plan-issue` debug binary exposes `--execution-state-file` and
    `--task-ledger-display`.
  - runtime-kit focused smoke can run against the local binary without
    replacing the Homebrew released binary permanently.
- **Validation**:
  - `cargo test -p plan-issue-cli`
  - `cargo build -p plan-issue-cli`
  - `PATH=$NILS_CLI_DEBUG_PATH:$PATH plan-issue record post --help`

## Sprint 2: runtime-kit Skill And Smoke Consumption

**Goal**: Make tracking issue skills require the new state markdown surface and
prove visible lifecycle comment completeness in runtime-smoke.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Update tracking issue skill contracts

- **Location**:
  - `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- **Description**: Require canonical `<slug>-execution-state.md` for state
  lifecycle posts, document collapsed non-final and expanded final ledger
  behavior, require detailed visible validation/review/session/closeout
  evidence, and add closeout checks for visible lifecycle completeness before
  `record close`.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 4
- **Acceptance criteria**:
  - State post examples use `--execution-state-file` instead of short
    `--summary-file` summaries.
  - Non-final examples use collapsed or default auto display.
  - Final/closeout examples require expanded Task Ledger visibility.
  - Validation, review, session, and closeout examples require role-specific
    visible evidence rather than Profile-only comments.
  - Skill text says hidden payload recognition alone is insufficient.
- **Validation**:
  - `rg -n -- '--execution-state-file|--task-ledger-display' core/skills/dispatch`
  - `rg -n -- '--kind state' core/skills/dispatch`

### Task 2.2: Update dispatch runtime-smoke lifecycle coverage

- **Location**:
  - `tests/runtime-smoke/cases/dispatch/run.sh`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
- **Description**: Replace short state summaries with execution-state markdown
  fixtures and add visible evidence assertions for all lifecycle kinds. Assert
  dry-run state comment bodies contain visible `## Task Ledger`, hide non-final
  ledger rows inside `<details>`, expand final ledger rows, and preserve hidden
  payload markers. Assert validation, review, session, and closeout comments
  contain role-specific visible evidence and are not Profile-only.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Runtime-smoke fails if a state post contains only hidden payload without a
    visible Task Ledger.
  - Runtime-smoke fails if non-final Task Ledger rows are expanded by default.
  - Runtime-smoke fails if final Task Ledger rows are collapsed by default.
  - Runtime-smoke fails if validation, review, session, or closeout bodies only
    contain the lifecycle heading plus profile line.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`

### Task 2.3: Render and update nils-cli surface floor

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `build/`
  - `tests/golden/`
- **Description**: After the nils-cli release is available, update the consumed
  surface snapshot and any required CLI floors, then render Codex and Claude
  products and refresh goldens.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Surface docs name the released nils-cli `z+1` version and new
    `plan-issue` flags plus lifecycle visible-rendering behavior.
  - Required CLI floors match the released version.
  - Codex and Claude rendered skills contain the updated tracking issue
    contract.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime audit-drift`

## Sprint 3: Release, Delivery, And Closeout

**Goal**: Land the nils-cli release, deliver the runtime-kit consumption PR,
and close the tracking issue with complete visible lifecycle comments.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Release nils-cli z+1

- **Location**:
  - `sympoies/nils-cli`
  - `sympoies/homebrew-tap`
- **Description**: Cut the next nils-cli release after focused tests pass,
  update the Homebrew tap, and verify the released `plan-issue` binary exposes
  the new flags.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 4
- **Acceptance criteria**:
  - A new nils-cli release exists for the accepted `z+1` version.
  - Homebrew install/upgrade path exposes the new `plan-issue record post`
    flags.
  - runtime-kit no longer depends on an unreleased local debug binary for final
    validation.
- **Validation**:
  - `plan-issue --version`
  - `plan-issue record post --help`

### Task 3.2: Run full runtime-kit delivery validation

- **Location**:
  - `agent-runtime-kit`
- **Description**: Run focused checks and the full repository gate using the
  released nils-cli floor, record validation evidence, and prepare PR delivery.
- **Dependencies**:
  - Task 2.3
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Focused dispatch runtime-smoke passes with released nils-cli.
  - Render, drift, golden, and surface manifest gates pass.
  - Full `bash scripts/ci/all.sh` passes or any unrelated failure has an exact
    unblock action.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/all.sh`

### Task 3.3: Deliver PR and close tracking issue

- **Location**:
  - `agent-runtime-kit`
- **Description**: Open or update the runtime-kit PR, run the pre-merge review
  gate, merge after checks pass, post final expanded Execution State, and close
  the plan-tracking issue through `plan-issue record close`.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - PR is merged after required validation and review evidence.
  - Latest issue state comment has a visible expanded Task Ledger plus hidden
    payload marker.
  - `plan-issue record audit` recognizes complete lifecycle evidence.
  - `plan-issue record close` closes the provider issue and repairs the final
    dashboard.
- **Validation**:
  - `plan-issue record audit --profile tracking`
  - `plan-issue record close --profile tracking`
