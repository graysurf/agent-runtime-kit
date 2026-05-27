# Plan: Forge Label Taxonomy

## Overview

Create one provider-neutral label taxonomy for GitHub issues / PRs and GitLab
issues / MRs, then wire it into the agent workflows that create provider
records. `agent-runtime-kit` owns the label catalog, policy, and skill usage
rules. `nils-cli` owns the `forge-cli` provider implementation for label audit,
ensure, validation, and automatic label application.

## Read First

- Primary source: docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Final machine-readable catalog path: lean toward
    `manifests/forge-labels.yaml`.
  - Whether `forge-cli label ensure` updates existing color/description drift
    by default: lean toward explicit `--update-existing`.
  - Whether strict label validation is default or opt-in: lean toward
    first-rollout opt-in `--strict-labels`.

## Scope

- In scope:
  - A human-readable label policy in `agent-runtime-kit`.
  - A machine-readable default label catalog in `agent-runtime-kit`.
  - A linked `sympoies/nils-cli` follow-up issue for `forge-cli label`
    audit/ensure and PR/MR deliver label propagation.
  - Agent skill updates so issue, PR, MR, and plan-tracking workflows choose
    and apply labels.
  - Runtime smoke/golden coverage for the updated skill guidance.
  - Rollout verification against representative GitHub and GitLab repos.
- Out of scope:
  - Deleting or renaming existing provider labels automatically.
  - Replacing GitHub/GitLab native state, milestone, assignee, review, or CI
    concepts with labels.
  - Adding a separate `urgency::` group in the first taxonomy.
  - Implementing Alfred UI behavior; consumers can use `forge-cli` JSON later.

## Sprint 1: Catalog And Policy

**Goal**: Define the shared label taxonomy in a durable source format that both
agents and `forge-cli` can consume.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Add the machine-readable label catalog

- **Location**:
  - `manifests/`
  - `core/policies/`
- **Description**: Add the default provider-neutral label catalog with groups,
  names, descriptions, colors, applicability (`issue`, `pr`, `mr`), required
  conditions, mutual exclusivity, and repo-extension slots for `area::` labels.
  Include the core groups `type::`, `area::`, `priority::`, `severity::`,
  `size::`, and `state::`, plus optional `risk::`, `provider::`, and
  `workflow::`.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Catalog includes every label from the discussion source taxonomy.
  - Catalog encodes mutually exclusive scoped groups where only one value
    should be active.
  - Catalog allows repo-local `area::` extensions without editing shared core
    labels.
  - Catalog distinguishes issue-only, PR/MR-only, and shared labels.
- **Validation**:
  - YAML or JSON parser check for the catalog file.
  - `git diff --check`.

### Task 1.2: Add human policy and root pointers

- **Location**:
  - `core/policies/`
  - `AGENT_HOME.md`
  - `AGENTS.md`
- **Description**: Add concise policy describing label group semantics, when
  agents must select labels, when to run provider label ensure, and how to treat
  legacy `plan` / `issue` labels during rollout. Keep root files short and
  point to the canonical policy instead of copying the full catalog.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - Policy says `priority::` owns scheduling order and `severity::` owns impact.
  - Policy says first rollout does not use `urgency::`.
  - Root guidance stays concise and links to the canonical policy.
  - Legacy `plan` / `issue` compatibility is documented.
- **Validation**:
  - `bash scripts/ci/all.sh`.

## Sprint 2: Provider CLI Follow-Up

**Goal**: Track and consume the `nils-cli` work required for labels to be
auditable, creatable, and automatically applied through `forge-cli`.

**PR grouping intent**: `per-sprint`
**Execution Profile**: `serial`

### Task 2.1: Open linked nils-cli implementation issue

- **Location**:
  - `docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-execution-state.md`
  - `docs/source/nils-cli-surface.md`
- **Description**: Open a `sympoies/nils-cli` issue linked back to this
  tracking issue. The issue must request `forge-cli label list/audit/ensure`,
  `pr deliver --label`, catalog-based validation, provider fixtures, and
  release notes. Record the URL in this plan's issue timeline.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Linked `nils-cli` issue exists and references this tracking issue.
  - Issue separates CLI implementation from `agent-runtime-kit` policy work.
  - Issue includes first-version non-goals: no delete/rename by default, no
    strict enforcement until opt-in validation exists.
- **Validation**:
  - `forge-cli issue view <issue> --provider github --repo sympoies/nils-cli --format json`.

### Task 2.2: Consume released forge-cli label support

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `manifests/`
  - `core/skills/pr/`
  - `core/skills/issue/`
- **Description**: After the linked `nils-cli` work is released, bump required
  `forge-cli` floors and document the supported label surfaces. The consumed
  release must support provider-neutral label audit/ensure and repeatable
  labels on both `pr create` and `pr deliver`.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - `docs/source/nils-cli-surface.md` names the released `forge-cli` version and
    label surfaces.
  - Manifest floors require a release with label ensure/audit and deliver label
    propagation.
  - Skill sources no longer describe label arguments as optional free-form
    provider passthrough only.
- **Validation**:
  - `forge-cli label audit --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --dry-run --format json`.
  - `forge-cli pr deliver --help` shows repeatable `--label`.

## Sprint 3: Agent Workflow Integration

**Goal**: Make agents select, ensure, and apply labels in the workflows that
create issues, PRs, and MRs.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 3.1: Update issue and PR/MR skills

- **Location**:
  - `core/skills/issue/issue-follow-up/SKILL.md.tera`
  - `core/skills/pr/create-github-pr/SKILL.md.tera`
  - `core/skills/pr/create-gitlab-mr/SKILL.md.tera`
  - `core/skills/pr/deliver-github-pr/SKILL.md.tera`
  - `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
- **Description**: Update issue and PR/MR skills so agents choose labels before
  provider mutation, run label ensure or audit when the repo may not have the
  catalog, and pass the selected labels into `forge-cli`. PR/MR workflows must
  include `type::`, `area::`, and `size::`; issue workflows must include
  `type::`, `area::`, and `state::needs-triage` unless a more specific state is
  known.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - Create/deliver skills show label selection before live provider mutation.
  - GitHub and GitLab wording uses the same taxonomy.
  - Bug issue guidance requires severity selection when impact is known.
  - `state::do-not-merge` is used for blocked PR/MR safety, not prose only.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`.
  - `agent-runtime render --product claude --update-golden`.

### Task 3.2: Update plan and dispatch label usage

- **Location**:
  - `core/skills/dispatch/`
  - `tests/runtime-smoke/`
  - `tests/golden/`
- **Description**: Update plan-tracking and dispatch workflows to use
  `workflow::plan`, `workflow::tracking`, and `workflow::dispatch` once the
  labels exist, while preserving the current `plan` label during rollout.
  Ensure tracking issues and dispatch lane PRs apply workflow labels in
  addition to normal type/area/size labels where appropriate.
- **Dependencies**:
  - Task 3.1
- **Acceptance criteria**:
  - Plan tracking issue creation applies workflow labels when available.
  - Dispatch lane PR creation applies a workflow label and a size label.
  - Existing issue-backed lifecycle audit markers are unchanged.
  - Legacy `plan` label compatibility remains documented until migration is
    complete.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`.
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`.

### Task 3.3: Refresh rendered outputs and smoke coverage

- **Location**:
  - `tests/golden/`
  - `tests/runtime-smoke/`
  - `tests/smoke/`
  - `manifests/`
- **Description**: Refresh rendered Codex/Claude skill outputs, update runtime
  smoke expectations, and add deterministic coverage that proves label
  arguments reach `forge-cli` dry-run plans for issue, PR, MR, and deliver
  flows.
- **Dependencies**:
  - Task 3.2
- **Acceptance criteria**:
  - Golden outputs match source skill changes.
  - Runtime smoke covers issue create, PR create, MR create, and PR/MR deliver
    label arguments.
  - Dry-run evidence shows selected labels in provider command plans.
- **Validation**:
  - `bash scripts/ci/all.sh`.

## Sprint 4: Rollout And Verification

**Goal**: Verify that the taxonomy works against real provider repositories and
that agents can create correctly labeled provider records.

**PR grouping intent**: `per-sprint`
**Execution Profile**: `serial`

### Task 4.1: Ensure labels on representative repositories

- **Location**:
  - `docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-execution-state.md`
  - `core/policies/`
- **Description**: Run label audit/ensure against at least
  `graysurf/agent-runtime-kit` and `sympoies/nils-cli`. If a GitLab target is
  available, run the same dry-run and live ensure flow there. Record missing
  labels, created labels, and any drift intentionally left unchanged.
- **Dependencies**:
  - Task 3.3
- **Acceptance criteria**:
  - GitHub audit passes for `graysurf/agent-runtime-kit`.
  - GitHub audit passes for `sympoies/nils-cli`.
  - GitLab audit is either passed or explicitly recorded as blocked by access /
    target selection.
  - No labels are deleted or renamed during rollout.
- **Validation**:
  - `forge-cli label audit --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --format json`.
  - `forge-cli label audit --catalog manifests/forge-labels.yaml --repo sympoies/nils-cli --format json`.

### Task 4.2: Exercise end-to-end labeled creation

- **Location**:
  - `tests/smoke/`
  - `tests/runtime-smoke/`
  - `docs/plans/2026-05-24-forge-label-taxonomy/forge-label-taxonomy-execution-state.md`
- **Description**: Run a safe live or scratch-provider exercise proving an
  agent can create an issue and PR/MR with taxonomy labels. Keep provider
  records draft/open unless the normal delivery workflow explicitly merges or
  closes them.
- **Dependencies**:
  - Task 4.1
- **Acceptance criteria**:
  - A created issue has `type::`, `area::`, and `state::` labels.
  - A created PR/MR has `type::`, `area::`, and `size::` labels.
  - `pr deliver` preserves labels through the macro path.
  - The tracking issue records provider URLs and validation results.
- **Validation**:
  - `forge-cli issue view <issue> --format json`.
  - `forge-cli pr view <pr-or-mr> --format json`.

## Closeout Gate

- The tracking issue can close only after the `nils-cli` follow-up is released,
  `agent-runtime-kit` consumes the release, agent skills apply the taxonomy,
  representative provider labels are ensured, and live or scratch creation
  evidence proves labels are applied to both issue and PR/MR records.
- Reopen triggers: `forge-cli pr deliver` drops labels, GitLab scoped label
  behavior diverges from the catalog, agents create provider records without
  required labels, or legacy `plan` / `issue` labels remain the only workflow
  labels after migration.
