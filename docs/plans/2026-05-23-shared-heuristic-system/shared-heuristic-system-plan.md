# Plan: Shared Heuristic System

## Overview

Move the Heuristic System policy, curated inbox records, and rendered workflow
guidance into `agent-runtime-kit` so Codex and Claude use the same retained
improvement root and the same public `heuristic-inbox` skill name.

This plan is intentionally scoped to the released nils-cli `0.17.4` surface.
The `heuristic-inbox` CLI already accepts explicit inbox and case paths, so the
runtime-kit delivery can use a shared `core/policies/heuristic-system/` root
without adding unreleased nils-cli behavior. Any future `--system-root` or
environment fallback should be handled as a nils-cli follow-up only if the
explicit path contract proves too cumbersome.

## Read First

- Primary source: docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Whether nils-cli needs a new `--system-root` flag. Default: no, document
    the released equivalent with `--inbox-dir <root>/error-inbox` and absolute
    case paths.
  - Whether legacy Claude retained records exist. Default: migrate the
    reusable agent-kit retained records and document an empty Claude retained
    record source when only placeholder folders are present.
  - Whether live runtime-home install should be applied during closeout.
    Default: use render, dry-run install, doctor, deterministic smoke, and full
    CI in this PR; live home mutation remains explicit user-approved follow-up.

## Scope

- In scope:
  - Add `core/policies/heuristic-system/` as the canonical shared policy and
    retained-record root.
  - Migrate reusable retained records from legacy agent-kit into the shared
    root, preserving redacted evidence summaries and strict verification.
  - Update architecture and rendered skill bodies so `heuristic-inbox` is the
    public workflow name and the shared root is product-independent.
  - Update the skill-usage reminder and relevant reporting guidance so raw
    skill-usage evidence stays separate from curated heuristic cases.
  - Add or update deterministic smoke coverage proving the shared root can be
    listed and verified from both product perspectives.
  - Refresh render outputs and golden snapshots.
- Out of scope:
  - Writing raw runtime evidence into the shared root automatically.
  - Reintroducing the legacy public `heuristic-error-inbox` skill name.
  - Removing legacy agent-kit or Claude files before runtime-kit surfaces are
    installed and accepted.
  - Replacing the released `heuristic-inbox` CLI with unreleased nils-cli
    behavior inside this repo.
  - Mutating real `$HOME/.codex` or `$HOME/.claude` runtime homes without an
    explicit closeout request.

## Assumptions

1. `heuristic-inbox 0.17.4` can list, verify, update, ingest evidence, and
   archive cases using explicit absolute paths.
2. The shared root can be a tracked runtime-kit policy tree:
   `core/policies/heuristic-system/`.
3. Product runtime homes may keep transient evidence in product state, but
   curated retained improvement records belong in the shared root.
4. Existing archived retained records are already redacted enough to migrate,
   but each migrated case must pass `heuristic-inbox verify --strict`.

## Sprint 1: Shared Policy And Runtime Guidance

**Goal**: Land the shared root, migrate retained records, update rendered
guidance, and prove the released CLI can operate against the same root from
both product surfaces.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add shared Heuristic System root and migrate retained records

- **Location**:
  - `core/policies/heuristic-system/HEURISTIC_SYSTEM.md`
  - `core/policies/heuristic-system/README.md`
  - `core/policies/heuristic-system/error-inbox/README.md`
  - `core/policies/heuristic-system/operation-records/README.md`
  - `core/policies/heuristic-system/error-inbox/archive/2026/deliver-gitlab-mr-skipped-pipeline-and-cleanup/ENTRY.md`
  - `core/policies/heuristic-system/operation-records/github-pr-required-check-gating/RECORD.md`
  - `docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-execution-state.md`
- **Description**: Create the product-independent policy root, active inbox
  README, operation-records README, and migrated retained case folders. Migrate
  the reusable agent-kit archived inbox case and operation record into the new
  shared root.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` exists and describes
    runtime evidence, curated inbox cases, and operation records as separate
    layers.
  - The shared root contains `error-inbox/` and `operation-records/`.
  - Migrated retained records pass strict `heuristic-inbox verify`.
  - Legacy Claude source inspection is recorded in the execution state.
- **Validation**:
  - `heuristic-inbox verify core/policies/heuristic-system/error-inbox/archive/2026/deliver-gitlab-mr-skipped-pipeline-and-cleanup --strict --format json`
  - `heuristic-inbox verify core/policies/heuristic-system/operation-records/github-pr-required-check-gating --strict --format json`

### Task 1.2: Update architecture and rendered workflow surfaces

- **Location**:
  - `docs/source/inventory-target-architecture.md`
  - `core/skills/meta/heuristic-inbox/SKILL.md.tera`
  - `core/skills/evidence/skill-usage/SKILL.md.tera`
  - `core/skills/reporting/project-retro/SKILL.md.tera`
  - `core/hooks/shared/skill-usage-reminder.py`
  - Related generated and golden output under `build/` and `tests/golden/`
- **Description**: Replace the stale per-product state placement and legacy
  `heuristic-error-inbox` naming with the shared root contract. Keep raw
  `skill-usage` records as evidence and route only curated follow-ups to the
  shared Heuristic System root.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Architecture documents one shared root for policy, active inbox, archive,
    and operation records.
  - Rendered Codex and Claude `heuristic-inbox` skills use the same canonical
    root and released CLI examples.
  - Rendered `skill-usage` guidance explains when a verified record should
    become a curated `heuristic-inbox` case.
  - Hook reminder text remains advisory and does not auto-create cases.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `git diff --exit-code -- tests/golden/`

### Task 1.3: Add deterministic shared-root validation

- **Location**:
  - `tests/runtime-smoke/cases/meta/run.sh`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-execution-state.md`
- **Description**: Extend deterministic meta smoke so the `heuristic-inbox`
  probe lists the shared root through explicit absolute inbox paths and verifies
  the migrated retained records. Record both Codex and Claude as product
  perspectives over the same root, not as separate inbox locations.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Deterministic meta smoke proves the shared root list command works without
    relying on caller cwd.
  - The smoke validates migrated retained records in strict mode.
  - Full CI remains clean after generated output and golden snapshots refresh.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/all.sh`

## Issue Closeout Gate

The tracking issue is complete when all Task 1 rows are done, the branch is
merged, issue-visible validation and review evidence are posted, and the issue
dashboard links to current state and validation comments.

Closeout does not require live mutation of real Codex or Claude runtime homes.
If live install is desired after merge, it should be a separate explicit
follow-up with dry-run-first evidence.
