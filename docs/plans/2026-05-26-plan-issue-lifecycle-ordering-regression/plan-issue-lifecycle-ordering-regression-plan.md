# Plan: Plan Issue Lifecycle Ordering Regression

## Overview

Restore the old plan issue timeline quality shown by issue #28 while keeping
the current v2 `plan-issue-record` lifecycle format. The implementation should
make session evidence a first-class required lifecycle record, add a pre-merge
readiness gate for issue-backed PR/MR delivery, and consume or plan nils-cli
support when closeout/readiness enforcement belongs in the CLI instead of skill
prose.

## Read First

- Primary source:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-discussion-source.md
- Source type: discussion-to-implementation-doc
- Recommended plan:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Recommended execution state:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-execution-state.md
- Open questions carried into execution: none; nils-cli work is represented as
  an explicit release/consume boundary inside this plan.

## Scope

- In scope:
  - Add regression fixtures for #117-like missing-session closeout.
  - Preserve #28-like state/session/validation timeline quality under v2
    markers.
  - Update plan-tracking and dispatch delivery skills so session posting is
    explicit and issue-visible.
  - Update GitHub and GitLab PR/MR delivery skills so linked plan records cannot
    merge before lifecycle readiness.
  - Add or consume released nils-cli readiness/session enforcement where CLI
    gates are needed.
  - Refresh rendered skills, goldens, smoke coverage, and lifecycle docs.
- Out of scope:
  - Reverting to v1 issue marker names.
  - Reopening or repairing #117 as the target record.
  - Making PR delivery skills own plan execution details.
  - Requiring lifecycle session comments for arbitrary non-plan issues.

## Sprint 1: Regression Fixtures And CLI Boundary

**Goal**: Capture the lifecycle-ordering regression with deterministic tests and
define the nils-cli surface needed to enforce it reliably.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add missing-session closeout regression fixture

- **Location**:
  - `tests/runtime-smoke/cases/dispatch/`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
- **Description**: Add a deterministic fixture that models the #117 failure:
  source, plan, complete state, validation, review, and closeout-ready PR data
  are present, but no latest `role=session` lifecycle comment exists and the
  dashboard still reports `Latest session: pending`.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - The fixture fails under current behavior before the enforcement fix.
  - The failure reports a stable missing-session or stale-session-dashboard
    blocked code.
  - The fixture distinguishes a visible `## Session Log` inside a state comment
    from a real `role=session` lifecycle record.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`

### Task 1.2: Add #28-like complete lifecycle success fixture

- **Location**:
  - `tests/runtime-smoke/cases/dispatch/`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
- **Description**: Add or extend deterministic fixtures so a v2 record with
  source, plan, state, session, validation, review, linked merged PR evidence,
  and closeout passes readiness and closeout.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - A #28-like v2 lifecycle sequence passes readiness and closeout.
  - The fixture verifies the latest session link is visible in the repaired or
    final dashboard.
  - The fixture keeps visible evidence assertions, not hidden-payload-only
    checks.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`

### Task 1.3: Define nils-cli readiness and closeout enforcement boundary

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `docs/source/extraction-backlog.md`
  - `manifests/skills.yaml`
- **Description**: Decide whether the current released `plan-issue` can enforce
  missing-session and pre-merge readiness. If not, record the nils-cli surface
  requirement and expected consume path before runtime-kit depends on it.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - The plan records whether runtime-kit can implement enforcement immediately
    or must wait for a nils-cli release.
  - Any new nils-cli requirement names a concrete command shape, JSON blocked
    codes, and the runtime-kit skill surfaces that will consume it.
  - `manifests/skills.yaml` floors are updated only after the required release
    is available.
- **Validation**:
  - `plan-issue record audit --help`
  - `plan-issue record close --help`
  - `bash scripts/ci/skill-governance-audit.sh`

## Sprint 2: Runtime-Kit Skill Contract Repairs

**Goal**: Make runtime-kit skills follow the desired lifecycle sequence even
before lower-level gates reject omissions.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Make session posting explicit in plan delivery skills

- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `tests/golden/`
- **Description**: Add a canonical `plan-issue record post --kind session`
  entrypoint wherever plan-tracking delivery asks for state, session,
  validation, and review comments. Keep the session visible and role-specific;
  do not bury it only inside a state markdown section.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Rendered Codex and Claude skills show `--kind session` in the lifecycle
    command sequence.
  - The workflow text says session evidence is required before merge and before
    final success.
  - Goldens reflect only the intended skill contract changes.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `rumdl check core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`

### Task 2.2: Add pre-merge lifecycle readiness to PR and MR delivery

- **Location**:
  - `core/skills/pr/deliver-github-pr/SKILL.md.tera`
  - `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
  - `tests/runtime-smoke/cases/pr/`
  - `tests/golden/`
- **Description**: Update PR/MR delivery so a linked tracking or dispatch issue
  referenced with `Refs #<issue>` must pass lifecycle readiness before merge.
  Closeout remains post-merge because it verifies the merged PR/MR.
- **Dependencies**:
  - Task 1.3
  - Task 2.1
- **Complexity**: 5
- **Acceptance criteria**:
  - GitHub and GitLab delivery skills distinguish pre-merge readiness from
    post-merge closeout.
  - The skills route to plan/dispatch delivery when readiness evidence is
    missing instead of merging and backfilling later.
  - Smoke coverage or focused fixture checks the command shape.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`

### Task 2.3: Align closeout skills with required session evidence

- **Location**:
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  - `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  - `tests/golden/`
- **Description**: Update closeout guidance so required session evidence is
  part of the closeout gate and any missing-session waiver is explicit,
  visible, and audited.
- **Dependencies**:
  - Task 1.3
  - Task 2.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Closeout skills reject dashboards that leave required session links pending.
  - Dispatch and tracking profiles use the same session evidence rule unless a
    profile-specific waiver is documented.
  - Rendered skills mention the nils-cli blocked code or readiness command when
    available.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`

## Sprint 3: Integration, Release Consumption, And Live Rehearsal

**Goal**: Validate the repaired lifecycle end to end and avoid another
issue-visible regression.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Consume released nils-cli readiness support when required

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `manifests/skills.yaml`
  - `docs/source/harness-shape-codex.md`
  - `docs/source/harness-shape-claude.md`
- **Description**: After nils-cli ships any required readiness or session
  enforcement support, refresh runtime-kit's consumed surface snapshot and
  semver floors. If no nils-cli change was needed, record that decision and the
  local runtime-kit enforcement boundary instead.
- **Dependencies**:
  - Task 1.3
  - Task 2.2
  - Task 2.3
- **Complexity**: 5
- **Acceptance criteria**:
  - `docs/source/nils-cli-surface.md` reflects the consumed release or records
    that the current release already satisfies the plan.
  - Skill `required_clis` floors match the first released version that provides
    the consumed command behavior.
  - The repository does not depend on unreleased local nils-cli binaries.
- **Validation**:
  - `agent-runtime --version`
  - `plan-issue --version`
  - `bash scripts/ci/skill-governance-audit.sh --check-counts`

### Task 3.2: Run full render, smoke, and governance gates

- **Location**:
  - `tests/runtime-smoke/`
  - `tests/golden/`
  - `tests/sandbox/`
- **Description**: Refresh all generated surfaces and run the focused and full
  validation stack after the lifecycle contract changes.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
  - Task 2.3
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Rendered Codex and Claude surfaces match source.
  - Dispatch and PR smoke cover missing-session failure and complete lifecycle
    success.
  - Full CI passes.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
  - `bash scripts/ci/all.sh`

### Task 3.3: Perform live GitHub lifecycle rehearsal and closeout

- **Location**:
  - `docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/`
  - `docs/source/nils-cli-surface.md`
- **Description**: Use this tracker as the live rehearsal. Before merging the
  implementation PR, post issue-visible state, session, validation, and review
  evidence; verify pre-merge readiness; then merge, post final state if needed,
  and close only after the dashboard links the latest session.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 4
- **Acceptance criteria**:
  - The issue timeline contains a v2 `role=session` comment before closeout.
  - The final dashboard does not show `Latest session: pending`.
  - Closeout passes with linked PR merge SHA/check evidence.
  - The final execution state records the live rehearsal evidence.
- **Validation**:
  - `plan-issue record audit --profile tracking`
  - `plan-issue record close --dry-run --profile tracking`
  - live issue read-back with `gh issue view`

## Validation And Delivery Gate

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `agent-docs resolve --context task-tools --strict --format checklist`
- `plan-tooling validate --file <plan> --format text --explain`
- `rumdl check docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/*.md`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `bash scripts/ci/all.sh`

## Rollback Notes

- If session-required closeout breaks existing active records, keep the new
  fixture and add an explicit waiver path rather than silently accepting
  missing session evidence.
- If nils-cli release work blocks runtime-kit progress, land the skill contract
  and fixture updates first, then keep release consumption as a tracked follow-up
  without weakening the desired lifecycle contract.
- If PR-level delivery becomes too broad, route issue-backed PRs to
  `deliver-plan-tracking-issue` or `deliver-dispatch-plan` instead of allowing
  direct merge.
