# Plan: Plan Issue vNext Implementation

## Overview

Implement the plan issue vNext workflow as a CLI-first redesign. The work
starts in `sympoies/nils-cli` by building a clean vNext core inside the existing
`crates/plan-issue-cli` compatibility shell, then rewrites the runtime-kit plan
issue skill family from the design documents, refreshes generated outputs, and
lands the released CLI floor.

This plan is the execution driver. Do not use the existing plan issue skill
family to guide or post progress for this implementation unless the user later
explicitly chooses to open an issue-backed tracker for this plan.

## Read First

- Primary source: docs/plans/2026-05-26-plan-issue-vnext-implementation/plan-issue-vnext-implementation-discussion-source.md
- Source type: discussion-to-implementation-doc
- Design documents:
  - docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md
  - docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md
  - docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md
  - docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md
  - docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md
- Open questions carried into execution:
  - none

## Scope

- In scope:
  - `nils-cli` vNext lifecycle core, tracking controller, checkpoint, and
    close-ready implementation.
  - Compatibility-preserving migration of existing `plan-issue record`
    rendering internals.
  - Runtime-kit plan issue skill source deletion/rewrite from the redesign
    docs.
  - Runtime-kit rendered targets, goldens, smoke coverage, docs, and CLI floor
    updates.
- Out of scope:
  - Historical issue comment rewrite.
  - Direct provider CLI mutation for plan issue lifecycle comments.
  - Replacing `plan-tooling` validation or `forge-cli` PR lifecycle ownership.
  - Dynamic graph orchestration inside `nils-cli` core.

## Execution Rules

- Execute from this plan bundle and the five design documents.
- Do not invoke `create-plan-tracking-issue`,
  `execute-plan-tracking-issue`, `deliver-plan-tracking-issue`,
  `plan-tracking-issue-closeout`, `deliver-dispatch-plan`,
  `execute-dispatch-lane`, `review-dispatch-lane-pr`,
  `dispatch-plan-closeout`, or `create-dispatch-lane-pr` as implementation
  drivers for this plan.
- Run required `agent-docs` preflight in each repository before edits or
  validation.
- Use repo-relative paths in public docs. Do not write personal checkout paths
  into committed documentation.
- For nils-cli tasks, record exact repo-relative paths, commits, command
  output summaries, and local binary path policy in the execution-state ledger.
- Use a scoped local binary path while developing runtime-kit skills; do not
  globally replace the installed CLI.

## Cross-Repo Location Note

`Location` entries are validated relative to `agent-runtime-kit`. Tasks that
modify `sympoies/nils-cli` therefore point to this bundle and the relevant
redesign docs. Their descriptions name nils-cli repo-relative target paths that
must be edited in the nils-cli checkout during execution.

## Sprint 1: nils-cli vNext Boundary

**Goal**: Create the clean vNext implementation boundary inside the existing
`crates/plan-issue-cli` crate while preserving the public CLI shell.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add vNext module skeletons

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, add the vNext module boundary under
  `crates/plan-issue-cli/src/`. Target modules are
  `lifecycle_vnext/{registry,templates,visible_lint,payloads,render}` and
  `tracking/{run_state,events,fsm,reconcile,checkpoint,close_ready}` or
  equivalent names with the same boundaries. Preserve `plan-issue` and
  `plan-issue-local` binaries, global output envelope, exit-code conventions,
  provider abstraction, runtime layout, fixture assets, and released command
  compatibility.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - The crate compiles with the new vNext modules present.
  - Existing `plan-issue record` commands continue to compile and pass current
    compatibility tests.
  - New modules are not hidden inside a catch-all executor file.
  - Execution state records the nils-cli repo-relative paths created.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli --no-fail-fast`
  - `cargo check -p nils-plan-issue-cli`

### Task 1.2: Freeze compatibility baseline

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, identify the existing fixture and
  integration tests that prove current `record open`, `record post`,
  `record repair-dashboard`, `record close`, `record audit`, provider routing,
  output envelopes, and runtime layout behavior. Add focused compatibility
  assertions where gaps would let the vNext work accidentally break released
  behavior before runtime-kit migrates.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Compatibility tests cover released record command entrypoints.
  - Tests assert JSON envelope shape and stable error behavior for at least one
    representative success and one representative failure.
  - Runtime layout resolution remains shared infrastructure, not duplicated in
    vNext modules.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli record --no-fail-fast`
  - `cargo test -p nils-plan-issue-cli runtime_layout --no-fail-fast`

## Sprint 2: Lifecycle Templates And Visible Lint

**Goal**: Make every lifecycle role registry-driven and visibly complete.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Implement lifecycle role registry

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, implement a registry entry for each
  lifecycle role: `source`, `plan`, `state`, `session`, `validation`,
  `review`, and `closeout`. Each entry defines marker role, heading, required
  visible sections, payload schema type, direct-post allowance, dashboard
  repair expectation, and closeout ownership. Mark `source` and `plan` as
  open/attach-only and `closeout` as `record close` owned.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Registry iteration proves every role has a visible template and payload
    schema.
  - Role ownership metadata prevents direct progress posts for `source`,
    `plan`, and `closeout`.
  - Registry tests compare headings and required sections to the taxonomy doc.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli lifecycle_vnext_registry --no-fail-fast`

### Task 2.2: Implement visible completeness lint

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, add reusable visible-completeness
  lint for rendered lifecycle comments. It must reject Profile-only comments,
  require visible state Task Ledger content, require validation overall status
  plus commands or waiver, require review decision and finding disposition when
  findings exist, require session summary, and require closeout approval plus
  linked PR evidence or explicit no-PR note.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Each lifecycle role has passing and failing visible-lint fixtures.
  - Failure codes are stable and role-specific.
  - Hidden payload success alone cannot satisfy visible completeness.
  - Non-final state may collapse Task Ledger rows while keeping the
    `## Task Ledger` heading visible.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli visible_lint --no-fail-fast`

### Task 2.3: Extend audit with visible expectation

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, extend `plan-issue record audit`
  with an `--expect-visible` path or equivalent option that runs the new
  visible-completeness lint in addition to hidden payload audit. Preserve the
  existing audit behavior when visible checks are not requested.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Existing audit fixtures pass without `--expect-visible`.
  - `--expect-visible` reports missing visible sections with stable codes.
  - Runtime-kit closeout can use the audit result before claiming final
    success.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli record_audit --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- record audit --help`

## Sprint 3: Template Preview And Renderer Fixtures

**Goal**: Expose deterministic templates and prove renderer output for every
role before adding controller-driven mutation.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Add `record template`

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
- **Description**: In `sympoies/nils-cli`, add a non-mutating
  `plan-issue record template` command backed by the vNext registry. It should
  preview visible Markdown skeletons and JSON payload skeletons for each role
  without emitting a real hidden payload carrier.
- **Dependencies**:
  - Task 2.3
- **Complexity**: 4
- **Acceptance criteria**:
  - `--format markdown` prints the visible skeleton for every role.
  - `--format json` prints the payload data skeleton for every role.
  - The command rejects unsupported role/profile combinations.
  - Template output is generated from the same registry as renderers.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli record_template --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- record template --profile tracking --kind validation --format markdown`

### Task 3.2: Add renderer fixture coverage for all roles

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, add deterministic renderer fixtures
  for `source`, `plan`, `state`, `session`, `validation`, `review`, and
  `closeout`. Fixtures must prove first-line marker shape, hidden payload
  carrier shape, visible headings, visible completeness, and Task Ledger display
  mode behavior.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Every role has at least one golden or snapshot fixture.
  - State fixtures cover collapsed non-final and expanded final Task Ledger
    rendering.
  - Fixtures reject legacy visible payload code fences.
  - Fixture output is usable by runtime-kit smoke without live provider
    mutation.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli lifecycle_vnext_render --no-fail-fast`

## Sprint 4: Run-State Schema, Events, FSM, And Reconciliation

**Goal**: Add typed local run state and deterministic reconciliation against
provider issue evidence.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 4.1: Implement run-state schema and event journal

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
- **Description**: In `sympoies/nils-cli`, implement
  `plan-issue.execution-run.v1` and `plan-issue.execution-event.v1` structs,
  JSON parsing/writing, schema validation, append-only `events.jsonl`, and the
  issue-scoped runtime root under the existing state-dir resolution contract.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 6
- **Acceptance criteria**:
  - `run-state.json` round-trips required and recommended fields.
  - `events.jsonl` appends run start, task update, validation, reconciliation,
    checkpoint, and failure events without rewriting old events.
  - Runtime layout is issue-scoped and reuses existing state-dir precedence.
  - Large artifacts are stored as paths or redacted previews, not inline blobs.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_run_state --no-fail-fast`
  - `cargo test -p nils-plan-issue-cli tracking_events --no-fail-fast`

### Task 4.2: Implement FSM and provider reconciliation

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
- **Description**: In `sympoies/nils-cli`, implement FSM state derivation for
  `RECORD_UNOPENED`, `RECORD_OPEN_INITIAL`, `RECORD_OPEN_ACTIVE`,
  `RECORD_BLOCKED`, `RECORD_VALIDATING`, `RECORD_REVIEWED`,
  `RECORD_READY_FOR_CLOSE`, and `RECORD_CLOSED`. Reconcile provider comments,
  dashboard state, plan bundle files, run state, and event journal before
  recommending transitions.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 7
- **Acceptance criteria**:
  - Provider issue evidence wins over stale local run state.
  - The controller reports stale run state and refuses live mutation when issue
    evidence is newer.
  - Missing lifecycle roles produce precise recommended next actions.
  - Blocked state maps to latest state evidence with blocked status.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_fsm --no-fail-fast`
  - `cargo test -p nils-plan-issue-cli tracking_reconcile --no-fail-fast`

### Task 4.3: Add `tracking status`

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
- **Description**: In `sympoies/nils-cli`, add non-mutating
  `plan-issue tracking status`. It reads issue evidence through live provider,
  fixture files, or explicit body/comment inputs; reads the plan bundle and
  run state; runs audit plus optional visible lint; and emits a stable JSON
  envelope with current FSM state, lifecycle evidence, run-state summary,
  reconciliation warnings, safe transitions, and recommended next action.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 6
- **Acceptance criteria**:
  - Status can run without provider mutation.
  - Fixture mode covers complete, blocked, stale, validating, reviewed, and
    close-ready records.
  - JSON envelope is deterministic and documented by tests.
  - `--expect-visible` flows through to visible completeness checks.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_status --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- tracking status --help`

## Sprint 5: Run Updates And Checkpoint Dry-Run

**Goal**: Let agents update typed local state and render safe checkpoint
payloads without provider mutation.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 5.1: Add run init and run update

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
- **Description**: In `sympoies/nils-cli`, add
  `plan-issue tracking run init` and `plan-issue tracking run update`. They
  should initialize issue-scoped run state after open/attach, select task or
  sprint scope, record branch/worktree/PR fields, record validation and review
  evidence, and append typed events.
- **Dependencies**:
  - Task 4.3
- **Complexity**: 6
- **Acceptance criteria**:
  - Run init creates `run-state.json`, `events.jsonl`, and issue-scoped
    directories.
  - Run update can change phase, selected task, PR, validation, review,
    artifact, blocker, and note fields without losing existing data.
  - Updates append events and preserve schema version.
  - Invalid phase or malformed evidence fails with stable errors.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_run_update --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- tracking run init --help`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- tracking run update --help`

### Task 5.2: Add checkpoint dry-run rendering

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
- **Description**: In `sympoies/nils-cli`, add dry-run support for
  `plan-issue tracking checkpoint`. It should read run state and plan bundle
  files, reconcile provider issue evidence, render requested roles
  (`state`, `session`, `validation`, `review` where available), run visible
  lint, and write reproducible rendered outputs under the issue-scoped run
  directory without provider mutation.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 7
- **Acceptance criteria**:
  - Dry-run outputs list every planned lifecycle write and dashboard repair.
  - Empty session, validation, or review payloads are not rendered as comments.
  - Rendered comment bodies pass visible completeness before being reported as
    postable.
  - Stale provider issue evidence blocks dry-run-to-live readiness.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_checkpoint_dry_run --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- tracking checkpoint --help`

### Task 5.3: Add stale-state and completeness refusal tests

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
- **Description**: In `sympoies/nils-cli`, add negative tests proving
  checkpoint refuses stale run state, missing visible sections, missing
  execution-state Task Ledger, unsupported direct source/plan/closeout posts,
  and provider evidence that has advanced beyond local state.
- **Dependencies**:
  - Task 5.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Every refusal emits a stable blocked code and suggested unblock action.
  - Refusal tests cover both fixture input and local run-state input.
  - Refused checkpoints do not write provider comments or dashboard repairs.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_checkpoint_refusals --no-fail-fast`

## Sprint 6: Live Checkpoint, Close-Ready, And Record Migration

**Goal**: Add provider-safe live checkpoint behavior, non-mutating close
readiness, and migrate record rendering internals onto the vNext core.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 6.1: Implement live tracking checkpoint

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
- **Description**: In `sympoies/nils-cli`, implement live
  `plan-issue tracking checkpoint` as an adapter over existing lifecycle
  primitives. It must post allowed roles, repair the dashboard when requested,
  persist rendered bodies, append provider mutation events with comment URLs,
  and return a stable JSON envelope. It must never call `record close`.
- **Dependencies**:
  - Task 5.3
- **Complexity**: 7
- **Acceptance criteria**:
  - Live checkpoint posts only roles allowed by role metadata.
  - Dashboard repair is explicit and reported.
  - Provider mutation is skipped in fixture/dry-run mode.
  - Failed provider mutation appends a failure event without corrupting
    run state.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_checkpoint_live --no-fail-fast`
  - Provider-safe local fixture smoke for live checkpoint adapters.

### Task 6.2: Implement `tracking close-ready`

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md`
- **Description**: In `sympoies/nils-cli`, add non-mutating
  `plan-issue tracking close-ready`. It should run the same strict gates as
  `record close`, verify visible completeness when requested, reconcile linked
  PR evidence from issue comments, run state, and explicit flags, and return
  exact blocked codes plus suggested unblock actions.
- **Dependencies**:
  - Task 6.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Close-ready does not post closeout, repair dashboards, or close issues.
  - Passing close-ready and `record close --dry-run` agree on closeout gates.
  - Missing approval, linked PR, validation, review, final expanded state, or
    visible sections produce precise blocked codes.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli tracking_close_ready --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- tracking close-ready --help`

### Task 6.3: Migrate record rendering internals to vNext

- **Location**:
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md`
- **Description**: In `sympoies/nils-cli`, migrate existing `record open`,
  `record post`, `record repair-dashboard`, `record close`, and `record audit`
  rendering/audit internals to the vNext registry and visible-lint helpers
  where appropriate. Keep released command syntax and compatibility behavior
  unless the runtime-kit migration and release boundary explicitly allow a
  breaking change.
- **Dependencies**:
  - Task 6.2
- **Complexity**: 7
- **Acceptance criteria**:
  - Existing record command tests still pass.
  - New vNext registry tests and old command compatibility tests use the same
    role metadata.
  - Runtime-kit-facing command examples are generated from or validated
    against the vNext behavior.
  - There is no second lifecycle rendering engine for the same role.
- **Validation**:
  - `cargo test -p nils-plan-issue-cli --no-fail-fast`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- record --help`

## Sprint 7: nils-cli Validation, Docs, And Release Boundary

**Goal**: Prove the local binary against the design docs, update nils-cli docs,
and prepare the release consumed by runtime-kit.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 7.1: Validate local binary against design fixtures

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/`
  - `docs/source/plan-issue-redesign/`
- **Description**: Build a local `plan-issue` binary from the nils-cli branch
  and run fixture-driven smoke checks for template preview, visible audit,
  tracking status, run init/update, checkpoint dry-run, checkpoint live adapter
  in provider-safe mode, close-ready, and compatibility record commands.
  Record the binary path policy and command summaries in execution state
  without writing personal checkout paths into public docs.
- **Dependencies**:
  - Task 6.3
- **Complexity**: 5
- **Acceptance criteria**:
  - Local binary exposes the expected `record template` and `tracking`
    subcommands in help output.
  - Fixture checks compare output to the five redesign documents.
  - Compatibility record commands remain usable for runtime-kit migration.
  - Execution state records nils-cli branch, commit, and validation summary.
- **Validation**:
  - `cargo build -p nils-plan-issue-cli`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- record template --help`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- tracking --help`

### Task 7.2: Update nils-cli docs and release prep

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/`
  - `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md`
- **Description**: In `sympoies/nils-cli`, update active CLI docs,
  completions, changelog or release notes, and version/release preparation for
  the new plan issue surfaces. The release must happen before runtime-kit final
  floor validation can claim released-binary success.
- **Dependencies**:
  - Task 7.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Active nils-cli docs describe vNext surfaces and preserve the compatibility
    policy.
  - Help output and docs agree for `record template`, `tracking status`,
    `tracking run init`, `tracking run update`, `tracking checkpoint`, and
    `tracking close-ready`.
  - Nils-cli repository checks pass.
  - Release version or pending release blocker is recorded in execution state.
- **Validation**:
  - nils-cli repository check command required by its `DEVELOPMENT.md`
  - `cargo run -q -p nils-plan-issue-cli --bin plan-issue -- --help`

## Sprint 8: Runtime-Kit Skill Rewrite

**Goal**: Replace the plan issue skill source bodies with concise contracts
based on the redesign docs and local nils-cli binary behavior.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 8.1: Rewrite lightweight tracking skills

- **Location**:
  - `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  - `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
- **Description**: Delete or replace the current bodies for the four
  lightweight tracking skills. Rewrite them in the new section order:
  Purpose, When to use, Inputs, Preflight, Allowed lifecycle roles, Forbidden
  actions, CLI flow, Evidence requirements, Stop conditions, and Validation.
  They must call the new controller surfaces rather than hand-compose
  lifecycle comments.
- **Dependencies**:
  - Task 7.2
- **Complexity**: 6
- **Acceptance criteria**:
  - `create-plan-tracking-issue` opens or previews source, plan, and initial
    state, and may initialize run state after open.
  - `execute-plan-tracking-issue` reconciles status, updates run state, and
    checkpoints only issue-visible progress.
  - `deliver-plan-tracking-issue` uses checkpoint and close-ready probes but
    does not hand-write closeout.
  - `plan-tracking-issue-closeout` uses close-ready and `record close`; it does
    not implement tasks or post progress checkpoints.
  - Old prompt wording and manual comment assembly instructions are gone.
- **Validation**:
  - `rg -n "render-comment|render-dashboard|hand-compose|raw provider|gh issue comment|glab issue note" core/skills/dispatch/create-plan-tracking-issue core/skills/dispatch/execute-plan-tracking-issue core/skills/dispatch/deliver-plan-tracking-issue core/skills/dispatch/plan-tracking-issue-closeout`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 8.2: Rewrite dispatch issue and lane skills

- **Location**:
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  - `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
  - `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
  - `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
  - `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera`
  - `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
- **Description**: Delete or replace the current bodies for dispatch plan,
  dispatch lane, review, closeout, and lane PR helper skills. Rewrite them
  around profile ownership, lane boundaries, allowed lifecycle roles,
  forbidden actions, controller checkpoints, review evidence, and `forge-cli`
  PR ownership.
- **Dependencies**:
  - Task 8.1
- **Complexity**: 7
- **Acceptance criteria**:
  - `deliver-dispatch-plan` owns plan-level orchestration and does not become
    a lane implementer by default.
  - `execute-dispatch-lane` can only update the assigned lane scope.
  - `review-dispatch-lane-pr` records review evidence and does not implement
    fixes unless redirected.
  - `dispatch-plan-closeout` requires lane, review, validation, approval, and
    integration evidence before close.
  - `create-dispatch-lane-pr` creates PR/MR evidence but does not directly post
    plan issue lifecycle comments.
- **Validation**:
  - `rg -n "hand-compose|raw provider|gh issue comment|glab issue note|Profile-only" core/skills/dispatch core/skills/pr/create-dispatch-lane-pr`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 8.3: Audit and rewrite related references

- **Location**:
  - `core/skills/dispatch/deliver-dispatch-plan/references/`
  - `core/skills/dispatch/dispatch-plan-closeout/references/`
  - `docs/source/nils-cli-surface.md`
  - `docs/source/plan-issue-redesign/`
- **Description**: Audit current plan issue reference files and docs for old
  lifecycle mechanics, manual comment assembly, direct provider comments,
  obsolete command names, and stale CLI floors. Delete, rewrite, or retain
  references only when the rewritten source skills explicitly depend on them.
- **Dependencies**:
  - Task 8.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Retained references align with the vNext controller and role taxonomy.
  - Obsolete references are removed or rewritten.
  - `docs/source/nils-cli-surface.md` names the intended released CLI floor or
    explicitly marks the floor as pending release.
  - No active docs tell agents to post plan lifecycle comments through raw
    provider commands.
- **Validation**:
  - `rg -n "render-comment|render-dashboard|closeout-gate|build-dispatch-ledger|gh issue comment|glab issue note" core/skills docs/source tests/runtime-smoke`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

## Sprint 9: Runtime-Kit Rendering, Smoke, And CLI Floor

**Goal**: Regenerate product outputs, prove runtime behavior with the local
binary, then switch final validation to the released nils-cli floor.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 9.1: Refresh rendered outputs and goldens

- **Location**:
  - `targets/`
  - `tests/golden/`
  - `manifests/skills.yaml`
  - `docs/source/nils-cli-surface.md`
- **Description**: Render Codex and Claude targets from the rewritten skill
  sources, refresh golden snapshots, and update manifests and docs that
  describe required `plan-issue` surfaces.
- **Dependencies**:
  - Task 8.3
- **Complexity**: 5
- **Acceptance criteria**:
  - Rendered Codex and Claude outputs match source templates.
  - Goldens are refreshed from renderer output, not hand-edited as source.
  - Manifest CLI floors remain pending/local until the nils-cli release exists,
    then move to the released version.
  - Drift audit has no unexplained generated-output differences.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime audit-drift`

### Task 9.2: Add runtime smoke for visible lifecycle behavior

- **Location**:
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `tests/runtime-smoke/cases/dispatch/run.sh`
  - `tests/runtime-smoke/cases/pr/run.sh`
  - `tests/runtime-smoke/`
- **Description**: Update runtime smoke so it verifies visible comment bodies,
  hidden payload audit, checkpoint dry-run output, stale run-state refusal,
  and close-ready blocked/pass cases using fixture or provider-safe paths.
  Smoke must prove that no lifecycle comment is Profile-only.
- **Dependencies**:
  - Task 9.1
- **Complexity**: 7
- **Acceptance criteria**:
  - Smoke asserts `## Execution State`, `## Task Ledger`,
    `## Execution Session`, `## Validation Evidence`, `## Review Evidence`,
    and `## Tracking Issue Closeout` where applicable.
  - Smoke covers collapsed non-final and expanded final state Task Ledger
    behavior.
  - Smoke covers stale run state refusing live checkpoint.
  - Smoke runs with the scoped local nils-cli binary before release.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch --format text`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr --format text`

### Task 9.3: Final released-floor validation

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `manifests/skills.yaml`
  - `tests/runtime-smoke/`
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/`
- **Description**: After nils-cli releases the vNext `plan-issue` surface,
  update runtime-kit required CLI floors and rerun final validation against the
  released binary rather than the local debug binary. Record the version and
  validation summary in execution state.
- **Dependencies**:
  - Task 9.2
- **Complexity**: 5
- **Acceptance criteria**:
  - `docs/source/nils-cli-surface.md` and `manifests/skills.yaml` agree on the
    released `plan-issue` floor.
  - Runtime smoke passes without a scoped local debug binary.
  - Final validation names the exact released version used.
  - Any release blocker is recorded as a blocked task, not hidden as success.
- **Validation**:
  - `plan-issue --version`
  - `plan-issue record template --help`
  - `plan-issue tracking --help`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch --format text`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr --format text`

## Sprint 10: Final Gate And Handoff

**Goal**: Finish the implementation with clean docs, validation, and execution
state that future maintainers can audit without rereading the whole thread.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 10.1: Run full repo validation

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/`
  - `docs/source/plan-issue-redesign/`
  - `scripts/ci/`
- **Description**: Run the full validation required by runtime-kit
  `DEVELOPMENT.md` after nils-cli released-floor validation passes. Include
  plan bundle validation, render checks, drift audit, runtime smoke, and any
  additional CI gate required by the repo at execution time.
- **Dependencies**:
  - Task 9.3
- **Complexity**: 5
- **Acceptance criteria**:
  - Full runtime-kit validation passes or has a documented unrelated blocker
    with evidence and owner.
  - Plan bundle validation passes.
  - Execution state validation ledger is updated with command summaries.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-26-plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md --format text --explain`
  - `bash scripts/ci/all.sh`

### Task 10.2: Final documentation and execution-state cleanup

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-vnext-implementation/plan-issue-vnext-implementation-execution-state.md`
  - `docs/source/nils-cli-surface.md`
  - `docs/source/plan-issue-redesign/`
- **Description**: Update execution state with final nils-cli and runtime-kit
  commits, released version, validation evidence, remaining follow-ups, and
  retention notes. Promote only stable behavior into maintained docs and leave
  this plan bundle as coordination history.
- **Dependencies**:
  - Task 10.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Execution state marks all tasks done, blocked, or explicitly deferred with
    evidence.
  - Stable CLI behavior is reflected in maintained runtime-kit docs.
  - Coordination-only notes are not copied into canonical docs.
  - Final handoff states whether any follow-up remains.
- **Validation**:
  - `git diff --check`
  - `plan-tooling validate --file docs/plans/2026-05-26-plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md --format text --explain`

## Final Acceptance

- nils-cli vNext controller surfaces are implemented and released.
- runtime-kit skills are rewritten from the design docs and generated outputs
  are refreshed.
- Runtime smoke and visible completeness checks prove issue comments no longer
  drift into Profile-only or inconsistent formats.
- The final implementation can be understood from this bundle, the five design
  docs, and execution-state evidence without invoking the old plan issue
  skills.
