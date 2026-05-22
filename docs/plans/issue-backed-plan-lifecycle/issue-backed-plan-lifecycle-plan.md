# Plan: Issue-Backed Plan Lifecycle

## Overview

Unify tracking-plan and dispatch-plan provider issue records around one shared
dashboard/comment lifecycle. The implementation starts in `nils-cli`, where
deterministic render/audit/gate behavior belongs, and then updates
`agent-runtime-kit` skills, golden outputs, and runtime smoke to consume the new
contract with local debug binaries before release.

Tracking keeps its lightweight issue-backed execution model. Dispatch becomes
the same lifecycle with subagent lanes, PR grouping, review evidence, and sprint
or close gates layered on top.

## Read First

- Primary source: docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Whether the shared lifecycle CLI should live under existing `plan-issue`
    commands, a `plan-issue record ...` subcommand group, or a separate binary.
    Default: extend `plan-issue` if the command names stay clear.
  - Whether new output should emit only shared `issue-backed-plan:*` markers or
    keep old tracking markers. Default: parse legacy markers and emit shared
    markers for new artifacts.
  - Whether dispatch closeout remains a separate skill or becomes
    `tracking-issue-closeout` with `profile=dispatch`. Default: keep separate
    public skill names but call the same lower-level CLI gates.

## Scope

- In scope:
  - Add a shared issue-backed lifecycle contract and fixtures in `nils-cli`.
  - Add or modify `nils-cli` commands for dashboard rendering, comment
    rendering, marker audit, lifecycle state validation, dispatch ledger
    generation, dashboard repair, and closeout readiness.
  - Keep `plan-tooling` focused on plan parse/validate/batches/split-prs.
  - Update `agent-runtime-kit` dispatch/tracking skill bodies to use the shared
    lifecycle contract while keeping current skill names.
  - Update render, golden snapshots, runtime smoke, acceptance matrix, and CLI
    floor/development guidance.
  - Validate `agent-runtime-kit` against `nils-cli` debug binaries before
    requiring a released `nils-cli`.
  - Run `code-review-specialists` before final delivery and fix concrete
    findings.
- Out of scope:
  - Renaming public skills back to old `agent-kit` names.
  - Removing dispatch subagent execution, PR grouping, review, sprint, or close
    gates.
  - Replacing `forge-cli` provider issue/PR CRUD atoms.
  - Hard-coding local debug binary paths into production manifests.
  - Mutating runtime homes, auth, sessions, caches, history, or secrets.

## Assumptions

1. The shared issue body is a mutable dashboard; durable records live in
   append-only issue comments.
2. `plan-tooling` already provides enough plan metadata for lifecycle commands
   to build tracking and dispatch ledgers.
3. Existing `plan-issue` `Task Decomposition` behavior may need compatibility
   preservation while new lifecycle commands are introduced.
4. `forge-cli issue view/comment/edit/close` remains the provider mutation
   layer.
5. `agent-runtime-kit` can run validation with
   `/Users/terry/Project/sympoies/nils-cli/target/debug` prepended to `PATH`.

## Sprint 1: Contract And Fixtures

**Goal**: Pin the shared issue-backed plan record contract, legacy compatibility
rules, and fixture coverage before changing CLI behavior.

**Demo/Validation**:

- Commands:
  - `cargo test -p plan-issue-cli issue_backed_lifecycle --no-fail-fast`
  - `cargo test -p plan-tooling`
  - `plan-tooling validate --file docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md --format text --explain`
- Verify: the shared dashboard/comment contract is represented by fixtures and
  `plan-tooling` remains unchanged for non-UI planning behavior.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 1.1: Define lifecycle contract fixtures

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-discussion-source.md
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
- **Description**: In `/Users/terry/Project/sympoies/nils-cli`, add fixtures
  for a tracking issue modeled after issue #43 and a dispatch issue that uses
  the same dashboard/comment shape plus a dispatch ledger. Include source
  snapshot, plan snapshot, state, session, validation, review, and closeout
  examples.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Fixtures include both tracking and dispatch profiles.
  - Fixtures represent shared `issue-backed-plan:*` markers and legacy tracking
    markers where compatibility is needed.
  - Fixture comments keep marker lines outside collapsed details blocks.
  - Quoted markers inside snapshot content are not accepted as real evidence.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli issue_backed_lifecycle --no-fail-fast`

### Task 1.2: Preserve plan-tooling boundary

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-discussion-source.md
  - docs/source/nils-cli-surface.md
- **Description**: Document and test that `plan-tooling` remains responsible
  for parse, validation, batches, and split-prs only. Any issue body, dashboard,
  comment, marker, or provider mutation logic belongs outside `plan-tooling`.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - The implementation does not add provider issue UI rendering to
    `plan-tooling`.
  - `plan-tooling` validation and split-prs behavior continue to pass.
  - Any new lifecycle command consumes plan-tooling output or internal parsing
    APIs without moving UI behavior into `plan-tooling`.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-tooling`

### Task 1.3: Choose CLI surface and compatibility policy

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - docs/source/nils-cli-surface.md
- **Description**: Inspect `plan-issue-cli` command boundaries and choose the
  command shape for shared lifecycle operations. Prefer a clear extension of
  `plan-issue` unless existing `Task Decomposition` semantics make that
  ambiguous.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Execution state records the chosen command surface and rejected
    alternatives.
  - Existing `start-plan`, `status-plan`, and `close-plan` compatibility is
    preserved or given an explicit migration path.
  - The command design supports debug-binary integration from
    `agent-runtime-kit`.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli cli_contract --no-fail-fast`

## Sprint 2: Nils-CLI Lifecycle Primitives

**Goal**: Implement deterministic lifecycle rendering, audit, state, dispatch
ledger, and closeout gates in `nils-cli`.

**Demo/Validation**:

- Commands:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli`
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p forge-cli`
- Verify: debug binaries can render and audit tracking/dispatch dashboards and
  comments without provider mutation, while `forge-cli` remains the provider
  CRUD layer.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 2.1: Implement shared dashboard and comment renderer

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - docs/source/nils-cli-surface.md
- **Description**: In `/Users/terry/Project/sympoies/nils-cli`, implement the
  selected lifecycle renderer for tracking and dispatch profiles. It should
  render a compact issue dashboard plus source, plan, state, session,
  validation, review, and closeout comment bodies.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 8
- **Acceptance criteria**:
  - Tracking dashboard does not include `## Task Decomposition`.
  - Dispatch dashboard uses the same section shape and links to a dispatch
    ledger comment.
  - New comments use the shared marker family and parse legacy tracking markers
    when required.
  - Rendered comments are GitHub-readable Markdown and collapse long snapshots.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli lifecycle_render --no-fail-fast`

### Task 2.2: Implement marker audit and dashboard repair

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - docs/source/nils-cli-surface.md
- **Description**: Port the useful legacy lifecycle helper behavior into Rust:
  standalone marker detection, latest-state selection, stale dashboard link
  detection, body repair rendering, and completion readiness checks.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 8
- **Acceptance criteria**:
  - Parser ignores quoted marker strings inside snapshots.
  - Dashboard repair is idempotent.
  - Completion gate requires complete state, done/deferred rows, validation
    evidence, and PR evidence when linked PRs exist.
  - Repair mode never duplicates closeout comments.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli lifecycle_audit --no-fail-fast`

### Task 2.3: Implement dispatch ledger and gate support

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - docs/source/nils-cli-surface.md
- **Description**: Add dispatch-profile state support for subagent lanes,
  sprint/task metadata, branch/worktree/PR group, PR links, review status,
  validation, and closeout readiness while keeping the same dashboard/comment
  structure.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
- **Complexity**: 9
- **Acceptance criteria**:
  - Dispatch ledger includes task id, sprint, owner/subagent, branch, worktree,
    execution mode, PR group, PR, status, validation, review, and notes.
  - Existing PR/link/sprint information can be represented without relying on a
    top-level `Task Decomposition` body.
  - Dispatch closeout gates require lane completion, reviews, merged PRs or
    explicit waivers, final validation, approval, and current dashboard links.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli dispatch_lifecycle --no-fail-fast`

### Task 2.4: Build and expose debug binaries for integration

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - DEVELOPMENT.md
- **Description**: Build `nils-cli` debug binaries and document the scoped
  integration command shape used by `agent-runtime-kit` validation. Do not
  hard-code debug paths into manifests.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
  - Task 2.3
- **Complexity**: 3
- **Acceptance criteria**:
  - `/Users/terry/Project/sympoies/nils-cli/target/debug` contains the updated
    binaries used by integration tests.
  - `agent-runtime-kit` validation can opt into the debug binary via scoped
    `PATH`.
  - Tracked docs explain debug-binary use as a development workflow, not a
    release requirement.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo build -p plan-issue-cli -p forge-cli -p plan-tooling`

## Sprint 3: Agent-Runtime-Kit Skill Integration

**Goal**: Update `agent-runtime-kit` tracking and dispatch skills to use the
shared lifecycle contract and debug-binary validated CLI behavior.

**Demo/Validation**:

- Commands:
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product codex --update-golden`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product claude --update-golden`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
- Verify: rendered skills and dispatch smoke use the shared issue-backed
  lifecycle output.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 3.1: Update tracking-plan skill bodies

- **Location**:
  - core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera
  - core/skills/dispatch/execute-from-tracking-issue/SKILL.md.tera
  - core/skills/dispatch/tracking-issue-closeout/SKILL.md.tera
  - tests/golden/codex/plugins/dispatch/skills/create-plan-tracking-issue/expected/SKILL.md
  - tests/golden/codex/plugins/dispatch/skills/execute-from-tracking-issue/expected/SKILL.md
  - tests/golden/codex/plugins/dispatch/skills/tracking-issue-closeout/expected/SKILL.md
- **Description**: Rewrite tracking-plan skills around the shared lifecycle CLI
  and dashboard/comment contract while preserving current names. Remove
  guidance that makes `plan-issue start-plan` / `Task Decomposition` the
  tracking issue body.
- **Dependencies**:
  - Task 2.4
- **Complexity**: 6
- **Acceptance criteria**:
  - `create-plan-tracking-issue` describes lightweight dashboard and snapshot
    comment creation.
  - `execute-from-tracking-issue` uses issue comments as durable state.
  - `tracking-issue-closeout` gates on shared lifecycle comments and approval.
  - Golden output matches rendered source.
- **Validation**:
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product codex --update-golden`

### Task 3.2: Update dispatch-plan skill bodies

- **Location**:
  - core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera
  - core/skills/dispatch/dispatch-subagent-pr/SKILL.md.tera
  - core/skills/dispatch/dispatch-pr-review/SKILL.md.tera
  - core/skills/dispatch/dispatch-issue-closeout/SKILL.md.tera
  - core/skills/dispatch/deliver-dispatch-plan/references/
  - core/skills/dispatch/dispatch-issue-closeout/references/
- **Description**: Reframe dispatch as the shared issue-backed lifecycle with
  subagent lanes. Keep lane dispatch, PR grouping, review, and close gates, but
  move durable task decomposition into dispatch ledger comments instead of a
  top-level `Task Decomposition` issue body.
- **Dependencies**:
  - Task 2.4
- **Complexity**: 7
- **Acceptance criteria**:
  - Dispatch skills share dashboard/comment vocabulary with tracking skills.
  - Subagent lane metadata remains explicit and executable.
  - Review and closeout still require specialist review, approval, validation,
    and merged PR evidence where applicable.
  - Golden output matches rendered source.
- **Validation**:
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product codex --update-golden`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product claude --update-golden`

### Task 3.3: Update smoke coverage and manifests

- **Location**:
  - tests/runtime-smoke/acceptance-matrix.yaml
  - tests/runtime-smoke/cases/dispatch/run.sh
  - tests/golden/
  - manifests/skills.yaml
  - manifests/plugins.yaml
  - docs/source/nils-cli-surface.md
- **Description**: Update runtime smoke to assert the shared tracking and
  dispatch lifecycle artifacts using debug binaries. Adjust CLI requirements
  and manifests only where the new lifecycle commands are used.
- **Dependencies**:
  - Task 3.1
  - Task 3.2
- **Complexity**: 6
- **Acceptance criteria**:
  - Smoke probes assert lightweight tracking dashboard output.
  - Smoke probes assert dispatch ledger comments with subagent lane metadata.
  - Acceptance matrix describes the shared lifecycle contract.
  - Manifests do not pin unreleased versions unless a release has been cut.
- **Validation**:
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`

## Sprint 4: Review, Release Boundary, And Closeout

**Goal**: Validate the cross-repo implementation, run specialist review, fix
findings, and close the plan with retained evidence.

**Demo/Validation**:

- Commands:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash scripts/ci/all.sh`
  - `review-specialists scope --base main --testing --maintainability --format json`
- Verify: nils-cli tests pass, agent-runtime-kit full gate passes with debug
  binaries, specialist review is resolved, and release/floor changes are
  either completed or explicitly deferred.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Run cross-repo validation

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - DEVELOPMENT.md
- **Description**: Run nils-cli targeted tests, build debug binaries, and run
  agent-runtime-kit gates with the debug binary directory on `PATH`. Record
  exact commands and results.
- **Dependencies**:
  - Task 3.3
- **Complexity**: 5
- **Acceptance criteria**:
  - `nils-cli` targeted tests pass.
  - `agent-runtime-kit` full CI passes with debug binaries.
  - Validation evidence distinguishes released binary coverage from debug
    binary coverage.
- **Validation**:
  - `cd /Users/terry/Project/sympoies/nils-cli && cargo test -p plan-issue-cli`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash scripts/ci/all.sh`

### Task 4.2: Run specialist review and fix findings

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - core/skills/dispatch/
  - tests/runtime-smoke/cases/dispatch/run.sh
  - docs/source/nils-cli-surface.md
- **Description**: Run `code-review-specialists` with at least testing and
  maintainability lenses for the combined cross-repo diff. Fix concrete
  findings and record dispositions for residual risks.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Specialist scope and findings are retained.
  - Concrete findings are fixed or explicitly dispositioned with evidence.
  - No unresolved high-confidence findings remain.
- **Validation**:
  - `review-specialists scope --base main --testing --maintainability --format json`
  - `review-specialists validate --input "$REVIEW_OUT/findings.jsonl" --validate-paths --format json`

### Task 4.3: Decide release/floor and close plan

- **Location**:
  - docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md
  - docs/source/nils-cli-surface.md
  - manifests/skills.yaml
  - tests/runtime-smoke/expected/
- **Description**: Decide whether to cut a `nils-cli` release in this plan or
  leave `agent-runtime-kit` integration documented against debug binaries until
  release. Update CLI floors only after release. Close the plan after validation
  and review evidence are complete.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Release/floor decision is explicit.
  - If release is cut, manifests and docs reference the released version.
  - If release is deferred, docs clearly state debug-binary integration status.
  - Plan execution state is complete and ready for tracking issue closeout.
- **Validation**:
  - `git status --short`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash scripts/ci/all.sh`

## Testing Strategy

- Unit: `cargo test -p plan-issue-cli`, plus targeted lifecycle renderer,
  audit, and dispatch ledger tests.
- Integration: `agent-runtime-kit` dispatch runtime smoke with nils-cli debug
  binaries on `PATH`.
- Repo gates: `agent-runtime render`, golden updates, `agent-runtime
  audit-drift`, `bash scripts/ci/all.sh`.
- Review: `code-review-specialists` with forced `testing` and
  `maintainability` lenses; add additional specialists if scope detection
  suggests them.

## Risks & gotchas

- Existing `plan-issue` command semantics are tightly coupled to
  `Task Decomposition`; changing them in place can break existing users.
- Shared markers must not create ambiguity with legacy markers or quoted
  marker examples inside snapshots.
- Dispatch must keep subagent lane continuity while adopting the shared
  dashboard/comment lifecycle.
- Cross-repo debug-binary integration can hide release/floor gaps if final
  documentation does not distinguish debug versus released binaries.
- Runtime smoke must avoid live provider mutation unless a specific live gate is
  intentionally selected.

## Rollback plan

- Keep old `plan-issue` `Task Decomposition` commands intact until replacement
  coverage passes.
- If shared lifecycle CLI is not ready, leave `agent-runtime-kit` skills on the
  current released CLI guidance and record the blocker in execution state.
- Revert `agent-runtime-kit` skill/golden/smoke changes together if the debug
  CLI contract changes substantially.
- Do not remove old marker parsing until live issues using legacy tracking
  markers can still be audited or migrated.
