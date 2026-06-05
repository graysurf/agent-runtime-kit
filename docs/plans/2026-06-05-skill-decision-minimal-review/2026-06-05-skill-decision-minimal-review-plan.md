# Plan: Skill Decision-Minimal Review

## Overview

Review and improve the repo-managed agent-runtime-kit skills using the
decision-minimal editing pattern proven by the plan issue skill cleanup. The
work should reduce duplicated wording and long prose while preserving safety
constraints, provider differences, failure stop conditions, ownership
boundaries, and validation obligations.

This is an L2 plan because the work spans the full skill catalog, is expected
to land through multiple focused PRs, and needs a state ledger to prevent
scope drift.

## Read First

- Primary source:
  `docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Prior implementation reference:
  https://github.com/graysurf/agent-runtime-kit/pull/286
- Open questions carried into execution:
  - Whether any domain needs a new shared spec rather than only shorter
    `SKILL.md.tera` bodies.
  - Whether the lane-oriented dispatch skills should receive the same rewrite
    pass in this L2, or remain as explicit long-form exceptions.

## Scope

In scope:

- Audit all repo-managed skill bodies under `core/skills/`.
- Apply the decision-minimal rubric from the source document.
- Edit source skill templates in focused domain batches.
- Refresh rendered Codex / Claude outputs and goldens for edited skills.
- Update manifests only when the edited skill bodies expose drift.
- Deliver each implementation batch through the normal PR floor.

Out of scope:

- nils-cli primitive or CLI contract changes.
- Runtime-home installation changes.
- Private skills under local runtime homes.
- Parallel lane dispatch unless a later checkpoint explicitly escalates to L3.

## Assumptions

1. The current nils-cli release is sufficient for render, governance, and
   validation; no upstream nils-cli work is required.
2. The plan issue family cleanup in PR #286 is the baseline style, not a strict
   formatting template for every domain.
3. GitHub is the provider for the tracking issue, so both `workflow::plan` and
   `workflow::tracking` labels can be applied.
4. Small prompt-style skills may already be close to minimal and can be marked
   reviewed without edits.

## Sprint 1: Tracking And Audit Baseline

**Goal**: Open the tracker and create the repo-wide skill inventory used to
choose edit batches.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Create the plan bundle and open the tracker

- **Location**:
  - `docs/plans/2026-06-05-skill-decision-minimal-review/`
- **Description**: Create this plan bundle, validate it, commit and push the
  bundle branch, open the provider tracking issue, initialize run state, and
  verify the issue contains visible source, plan, and state evidence.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - Bundle has source, plan, and execution-state files.
  - `plan-tooling validate` passes for the plan.
  - Provider issue contains source, plan, and initial state lifecycle evidence.
  - Local run state is initialized for the provider issue.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-plan.md --format text --explain`
  - `plan-issue record audit --profile tracking --expect-visible` against the opened issue.

### Task 1.2: Produce the skill inventory and triage matrix

- **Location**:
  - `core/skills/`
  - `manifests/skills.yaml`
  - `tests/golden/`
- **Description**: Inventory all managed skills by domain, length, repeated
  sections, provider-mutation risk, shared-spec opportunity, and expected
  validation. Use the result to choose a serial batch order.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Every managed skill is classified as rewrite, light-touch, or no-change.
  - High-risk skills with provider mutation or filesystem mutation are clearly
    separated from prompt-style skills.
  - Candidate shared-spec extractions are listed before edits begin.
- **Validation**:
  - `find core/skills -name SKILL.md.tera -print0 | xargs -0 wc -l`
  - `bash scripts/ci/skill-governance-audit.sh --check-counts`

## Sprint 2: Rubric And Shared Pattern Cleanup

**Goal**: Make the decision-minimal rubric reusable without copying it into
every skill.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 2.1: Place the reusable skill-editing rubric

- **Location**:
  - `core/skills/README.md`
  - `core/skills/`
- **Description**: Add or refine the narrowest durable routing/rubric text
  needed so future skill edits can apply the decision-minimal standard without
  rereading this plan.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 2
- **Acceptance criteria**:
  - The rubric names keep/drop criteria without duplicating this whole plan.
  - The rubric clarifies that safety gates and provider differences are not
    optional prose.
  - Existing skill catalog counts and routing guidance remain accurate.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh --check-counts`
  - `git diff --check`

### Task 2.2: Identify shared-spec candidates per domain

- **Location**:
  - `core/skills/dispatch/`
  - `core/skills/pr/`
  - `core/skills/issue/`
  - `core/skills/meta/`
  - `core/skills/code-review/`
  - `core/skills/reporting/`
- **Description**: For domains with repeated safety or lifecycle rules, decide
  whether to point at an existing shared spec, add a narrow domain-local spec,
  or keep the rule inline because it is unique to one skill.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Shared rules are not duplicated in sibling skills unless local context is
    materially different.
  - Any new shared spec has a clear owning domain and is not discovered as a
    skill.
  - No skill loses a hard stop condition by moving text to a shared reference.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

## Sprint 3: High-Risk Workflow Skills

**Goal**: Rewrite the skills most likely to cause wrong provider or repository
mutations if the guidance is unclear.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Review PR and issue lifecycle skills

- **Location**:
  - `core/skills/pr/`
  - `core/skills/issue/`
  - `manifests/skills.yaml`
  - `tests/golden/`
- **Description**: Apply the rubric to PR/MR delivery, close, create, issue
  follow-up, issue triage, and plan-issue finding skills. Preserve label
  requirements, provider differences, review gates, and no-auto-close rules.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 4
- **Acceptance criteria**:
  - PR and issue skills keep irreversible-operation gates and provider
    differences explicit.
  - Repeated label and body-format prose is reduced or centralized.
  - Rendered goldens match source changes.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain issue`

### Task 3.2: Review meta and repository-mutation skills

- **Location**:
  - `core/skills/meta/`
  - `manifests/skills.yaml`
  - `tests/golden/`
- **Description**: Apply the rubric to meta skills that mutate commits,
  worktrees, runtime surfaces, retained records, archives, releases, or
  project-local scripts. Preserve dry-run-first, semantic-commit, worktree,
  install/apply, and heuristic retention boundaries.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Meta skills keep exact mutation boundaries and validation duties.
  - Long workflow prose is collapsed into decision branches where safe.
  - Rendered goldens match source changes.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `bash tests/projects/project-local-smoke/run.sh`

## Sprint 4: Support And Prompt-Style Skills

**Goal**: Clean lower-risk skill families while preserving evidence and
reporting contracts.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Review code-review and evidence skills

- **Location**:
  - `core/skills/code-review/`
  - `core/skills/evidence/`
  - `tests/golden/`
- **Description**: Reduce repeated review/evidence guidance while preserving
  read-only boundaries, finding schemas, validation evidence, and retained
  record contracts.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Review skills keep mandatory gate and read-only boundaries clear.
  - Evidence skills keep record completeness and verification requirements.
  - Generated outputs and deterministic smoke remain green.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`

### Task 4.2: Review conversation, browser, media, and reporting skills

- **Location**:
  - `core/skills/conversation/`
  - `core/skills/browser/`
  - `core/skills/media/`
  - `core/skills/reporting/`
  - `tests/golden/`
- **Description**: Apply a lighter rewrite pass to prompt-style and reporting
  skills. Keep source requirements, external-fact boundaries, artifact
  contracts, and host-capability caveats.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Prompt-style skills remain short and do not gain process overhead.
  - Reporting skills preserve source-grounding and artifact rules.
  - Browser/media skills preserve host and artifact boundaries.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain conversation`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain media`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain reporting`

## Sprint 5: Integration, Delivery, And Closeout

**Goal**: Validate the whole edited skill surface, deliver final PRs, and close
the tracker only after issue-visible evidence is complete.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 5.1: Run full render, governance, drift, and smoke validation

- **Location**:
  - `core/skills/`
  - `build/`
  - `tests/golden/`
  - `tests/runtime-smoke/`
  - `scripts/ci/`
- **Description**: Run the full runtime-kit gate stack after every batch has
  landed or before the final delivery PR. Repair generated outputs or manifest
  drift discovered by validation.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Full `scripts/ci/all.sh` passes on a clean tree.
  - `tests/hooks/run.sh` passes.
  - No stale rendered skill output or manifest drift remains.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

### Task 5.2: Deliver close-ready evidence and close the tracker

- **Location**:
  - `docs/plans/2026-06-05-skill-decision-minimal-review/`
- **Description**: Record final state, session, validation, review, and linked
  PR evidence on the tracker. Run close-ready and closeout only when every task
  row has evidence.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Tracker contains current state, session, validation, review, and closeout
    evidence.
  - `tracking close-ready --profile tracking --expect-visible` returns
    `ready: true`.
  - The plan is archived or explicitly left with a documented follow-up.
- **Validation**:
  - `plan-issue tracking close-ready --profile tracking --expect-visible`
  - `plan-issue record audit --profile tracking --expect-visible`
