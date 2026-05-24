# Plan: Skill Governance Count Refresh

## Overview

Integrate active runtime-kit skill-count refresh into
`scripts/ci/skill-governance-audit.sh` so create/remove skill workflows can
update maintained count surfaces automatically, CI can fail on count drift, and
runtime sync can verify source readiness without mutating repository files.

## Read First

- Primary source: docs/plans/skill-governance-count-refresh/skill-governance-count-refresh-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - none

## Scope

- In scope:
  - Add read-only and apply count modes to `scripts/ci/skill-governance-audit.sh`.
  - Add deterministic fixture coverage for stale count detection and update.
  - Update repo-owned lifecycle skill instructions for `create-skill`,
    `remove-skill`, and `sync-runtime-skills`.
  - Update `scripts/sync-runtime-skills.sh` to run only the read-only
    governance count check before render/install.
  - Refresh rendered Codex/Claude outputs and golden snapshots.
- Out of scope:
  - Adding a separate `scripts/ci/skill-count-refresh.sh`.
  - Rewriting historical plan records under `docs/plans/**`.
  - Making `sync-runtime-skills` mutate repository source files.
  - Changing sandbox expected skill list or runtime-smoke matrix ownership.

## Assumptions

1. `manifests/skills.yaml` remains the maintained product-contract inventory
   for active repo-owned runtime-kit skills.
2. The count updater can be implemented inside the existing Python block in
   `skill-governance-audit.sh` without extracting a new released CLI surface.
3. Fixture coverage can exercise update behavior through the existing
   governance audit fixture pattern.
4. The maintained active count whitelist stays intentionally small and
   explicit.

## Sprint 1: Add Governance Count Check And Update Modes

**Goal**: Make `skill-governance-audit.sh` the single owner of active
skill-count drift detection and whitelist-only updates.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add count modes to skill governance audit

- **Location**:
  - `scripts/ci/skill-governance-audit.sh`
  - `docs/source/harness-shape-codex.md`
  - `tests/runtime-smoke/expected/install-summary.json`
  - `tests/runtime-smoke/product/expected/product-summary.json`
- **Description**: Add `--check-counts` and `--update-counts` modes to the
  existing governance audit. Reuse the parsed `manifests/skills.yaml` entries
  after existing source/manifest consistency checks to compute the active skill
  count. Check or update only the maintained active count whitelist, and fail
  closed if a target pattern is missing, ambiguous, or outside the whitelist.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Default `bash scripts/ci/skill-governance-audit.sh` fails when maintained
    active count references drift.
  - `--check-counts` performs the count check without mutating files.
  - `--update-counts` updates the active count whitelist and is idempotent.
  - `docs/plans/**` is not scanned or mutated by update mode.
  - Runtime-smoke expected JSON keeps stable formatting after update.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh --check-counts`
  - `bash scripts/ci/skill-governance-audit.sh --update-counts`
  - `git diff -- docs/source/harness-shape-codex.md tests/runtime-smoke/expected/install-summary.json tests/runtime-smoke/product/expected/product-summary.json`
  - `bash scripts/ci/skill-governance-audit.sh`

### Task 1.2: Add count-refresh fixture coverage

- **Location**:
  - `scripts/ci/skill-governance-audit.sh`
  - `tests/runtime-smoke/fixtures/skill-lifecycle/`
  - `scripts/ci/all.sh`
- **Description**: Add a deterministic fixture mode for active count refresh.
  The fixture should include deliberately stale maintained count surfaces,
  verify that check mode fails with a precise drift message, run update mode on
  the fixture copy, and verify the resulting files match expected refreshed
  content.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `bash scripts/ci/skill-governance-audit.sh --fixture count-refresh`
    exercises both stale detection and update behavior.
  - The fixture proves update mode is whitelist-only and does not rewrite
    historical plan text.
  - `scripts/ci/all.sh` includes the count-refresh fixture in the governance
    fixture stack.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh --fixture count-refresh`
  - `bash scripts/ci/all.sh`

## Sprint 2: Wire Skill Lifecycle Workflows

**Goal**: Make repo-owned skill add/remove workflows update counts, and make
runtime sync check count drift without source mutation.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Update create and remove skill workflows

- **Location**:
  - `core/skills/meta/create-skill/SKILL.md.tera`
  - `core/skills/meta/remove-skill/SKILL.md.tera`
  - `tests/golden/`
- **Description**: Update `create-skill` and `remove-skill` instructions so
  apply-mode lifecycle work runs
  `bash scripts/ci/skill-governance-audit.sh --update-counts` after source,
  manifest, sandbox, and runtime-smoke surfaces are changed, then runs the
  normal governance/render/smoke validation stack. Preserve the remove-skill
  dry-run-first boundary; count update is apply-only.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - `create-skill` rendered Codex and Claude skill bodies include the count
    update step.
  - `remove-skill` rendered Codex and Claude skill bodies include the count
    update step only after apply approval.
  - Golden snapshots reflect the updated lifecycle instructions.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `rg -n "skill-governance-audit.sh --update-counts" core/skills/meta tests/golden`

### Task 2.2: Update sync runtime skill workflow

- **Location**:
  - `scripts/sync-runtime-skills.sh`
  - `core/skills/meta/sync-runtime-skills/SKILL.md.tera`
  - `tests/runtime-smoke/cases/meta/run.sh`
  - `tests/golden/`
- **Description**: Run the read-only governance count check from
  `scripts/sync-runtime-skills.sh` after source checkout resolution and pull,
  before render/install. Update the `sync-runtime-skills` skill body to state
  that sync checks count freshness but never runs update mode. Extend the meta
  deterministic smoke probe if needed so the dry-run path shows the check.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `sync-runtime-skills` dry-run and apply paths perform the read-only count
    check before render/install.
  - `--no-verify` skips post-install verification only; it does not skip source
    count readiness checks.
  - No sync path mutates repository count files.
  - Rendered Codex and Claude skill bodies document the read-only boundary.
- **Validation**:
  - `bash scripts/sync-runtime-skills.sh --no-pull`
  - `bash scripts/sync-runtime-skills.sh --apply --no-pull --no-verify --product codex`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`

## Sprint 3: Final Validation And Tracking Closeout Prep

**Goal**: Prove the lifecycle, rendered output, fixtures, and CI gates agree
before implementation closeout.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Run full source and runtime validation

- **Location**:
  - `scripts/ci/all.sh`
  - `tests/runtime-smoke/`
  - `tests/golden/`
  - `docs/plans/skill-governance-count-refresh/skill-governance-count-refresh-execution-state.md`
- **Description**: Run the focused count refresh checks, render/golden refresh,
  sandbox rehearsal, meta deterministic smoke, and full local gate. Record
  command results and artifacts in the execution state and issue lifecycle
  comments.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Focused count refresh checks pass.
  - Sandbox install rehearsal passes.
  - Meta deterministic runtime smoke passes.
  - Full local CI passes or any blocker is clearly classified as unrelated and
    issue-visible.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh --check-counts`
  - `bash scripts/ci/skill-governance-audit.sh --fixture count-refresh`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash scripts/ci/all.sh`

### Task 3.2: Prepare issue-backed closeout evidence

- **Location**:
  - `docs/plans/skill-governance-count-refresh/skill-governance-count-refresh-execution-state.md`
  - `docs/plans/skill-governance-count-refresh/`
- **Description**: Update the execution state with final validation evidence,
  issue comments, PR links, and any residual risk before handing the tracker to
  closeout. Do not close the issue until implementation, review, and lifecycle
  evidence are complete.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Execution state names the latest session, validation, and review evidence.
  - Tracking issue dashboard can be repaired and audited without missing
    required lifecycle markers.
  - Residual risks, if any, are explicitly listed for closeout.
- **Validation**:
  - `plan-issue --repo graysurf/agent-runtime-kit --format json record audit --profile tracking --body-file "$ISSUE_BODY" --comments-json "$ISSUE_JSON"`
  - `plan-issue --repo graysurf/agent-runtime-kit --format json record repair-dashboard --profile tracking --issue "$ISSUE_NUMBER"`
