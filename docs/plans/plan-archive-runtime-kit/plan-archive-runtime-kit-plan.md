# Plan: Plan Archive — agent-runtime-kit Skill Bodies

## Overview

Wire the deterministic `plan-archive` CLI capabilities (Plan 1) into
two user-facing skills in `agent-runtime-kit`, update the placement /
naming policy, and land the manifest plus validation coverage.

This plan is one of two cross-repo deliveries that fall out of the
master design at
`docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`.
Plan 1 (`plan-archive-nils-cli`) lands the deterministic CLI surface
that this plan calls. The archive repository itself is bootstrapped as
a one-shot prerequisite (Plan 2 note in the master discussion source)
and is not tracked here.

The tracker issue for this plan is opened in `agent-runtime-kit`.

## Read First

- Primary source: docs/plans/plan-archive-system/plan-archive-system-discussion-source.md
- Source type: discussion-to-implementation-doc
- Sibling plan: docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-plan.md
- One-shot prereq: archive repository bootstrap (see master discussion
  source, "Archive repository" decision section).
- Open questions carried into execution:
  - [Q1] Skill domain. Default in this plan: place both new skills in
    the existing `meta` domain unless plan execution finds a clean
    reason for a separate `plan-archive` domain.
  - [Q2] Skill names. Default in this plan: `meta:plan-archive-migrate`
    and `meta:plan-archive-query`. Confirm naming against
    `create-skill` standards during execution.
  - [Q3] Whether the date-prefix rule applies to plan folders created
    on branches that started before this work lands. Default in this
    plan: applies to plan folders whose first commit lands after the
    naming policy change.

## Scope

- In scope:
  - Update `docs/source/docs-placement-retention-policy-v1.md` to add
    the `<YYYY-MM-DD>-<slug>/` naming rule for new plan folders.
  - Author the migration skill body that wraps
    `plan-archive migrate --dry-run` / `--apply`.
  - Author the query skill body that wraps `plan-archive query` and
    `plan-archive refresh`.
  - Register both skills in `manifests/skills.yaml` and their plugin
    containment in `manifests/plugins.yaml`.
  - Add `required_clis` floor entries that pin the `plan-archive`
    binary version released by Plan 1.
  - Update product render paths under `targets/<product>/` and refresh
    the render-goldens.
  - Add skill-usage reminder metadata for the new skills.
  - Add runtime-smoke and sandbox install rehearsal coverage.
  - Add a small set of focused docs notes under skill local READMEs
    where the workflow needs more than the `SKILL.md` body can carry.
- Out of scope:
  - The deterministic CLI (Plan 1 owns that).
  - Bootstrapping the archive repository (Plan 2 prereq).
  - Backfilling `<YYYY-MM-DD>-` prefixes onto existing plan folders.
  - Forge-cli changes.
  - Reopen-detection or background sync.
  - Promoting any docs/plans bundle to a domain-local runbook (a
    separate, optional pass after execution).

## Assumptions

1. Plan 1 has produced a released `nils-cli` tag that ships the
   `plan-archive` binary with the subcommands listed in the Plan 1
   plan file.
2. The archive repository exists and contains a maintainer-approved
   `README.md` (or `LEGAL.md`) plus a seeded `config/hosts.yaml`
   (Plan 2 prereq).
3. The existing skill-governance audit, render-golden, runtime-smoke,
   sandbox install rehearsal, and project-overlay smoke gates remain
   the acceptance stack for new skill surfaces.
4. The canonical skill source path is
   `core/skills/<domain>/<skill>/SKILL.md.tera`.
5. `manifests/skills.yaml` continues to declare canonical
   `<domain>.<skill>` IDs, source paths, supported products, render
   paths, and `required_clis`.

## Sprint 1: Naming And Policy Touch-up

**Goal**: Make the new `<YYYY-MM-DD>-<slug>/` rule discoverable through
the placement / retention policy and the project preflight, before any
skill body lands.

**PR grouping intent**: group

**Execution Profile**: serial

### Task 1.1: Add date-prefix naming rule to placement policy

- **Location**:
  - `docs/source/docs-placement-retention-policy-v1.md`
- **Description**: Add a short Naming sub-section (or extend the
  existing one) that pins
  `docs/plans/<YYYY-MM-DD>-<slug>/` as the canonical shape for new
  plan folders, with a note that pre-v1 slug-only folders remain valid
  and are not retroactively renamed.
- **Dependencies**: none
- **Complexity**: 1
- **Acceptance criteria**:
  - The policy document names the new rule and the exemption for
    pre-v1 folders.
  - `agent-docs resolve --context project-dev --strict` continues to
    pass.
- **Validation**:
  - `rumdl check docs/source/docs-placement-retention-policy-v1.md`
  - `agent-docs resolve --context project-dev --strict --format checklist`

### Task 1.2: Update repo policy hooks if needed

- **Location**:
  - `AGENT_HOME.md` and `AGENTS.md` (only if a placement reference
    needs updating)
- **Description**: Confirm whether either policy file references
  `docs/plans/` paths in a way that needs the new naming rule. If so,
  add a one-line pointer to the placement policy update from Task 1.1.
  Most likely a no-op; if so, record the no-op in the execution state
  and skip.
- **Dependencies**: Task 1.1
- **Complexity**: 1
- **Acceptance criteria**:
  - Either the touch lands, or the execution state records that no
    change was required.
- **Validation**:
  - `rumdl check` if either file is touched.

## Sprint 2: Migration Skill

**Goal**: Add `meta:plan-archive-migrate` (default name; [Q2]) as a
user-invoked skill body that calls `plan-archive migrate`.

**PR grouping intent**: group

**Execution Profile**: serial

### Task 2.1: Author the migration skill body

- **Location**:
  - `core/skills/meta/plan-archive-migrate/SKILL.md.tera`
  - `core/skills/meta/plan-archive-migrate/references/`
- **Description**: Author the skill body following the
  `create-skill` standard. The skill always runs `plan-archive migrate
  --dry-run` first, presents the JSON output to the user, requires
  explicit user confirmation before invoking `--apply`, and surfaces
  failure modes clearly.
- **Dependencies**: Plan 1 released
- **Complexity**: 4
- **Acceptance criteria**:
  - Skill body passes the skill-governance H2 body-shape audit.
  - Skill body does not duplicate CLI logic.
  - Skill body references the archive repo location through the
    machine-local config, not a hardcoded path.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`

### Task 2.2: Manifest and plugin registration for migration skill

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `core/hooks/shared/skill-usage-reminder.skills.json`
- **Description**: Register the skill ID, source path, supported
  products, render paths, plugin containment, and skill-usage
  reminder metadata. Add a `required_clis` floor pinning the
  `plan-archive` binary version.
- **Dependencies**: Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Manifest schema validation passes.
  - The skill appears in exactly one plugin containment list.
  - The `required_clis` floor is not a placeholder.
- **Validation**:
  - `bash scripts/ci/validate-surfaces-manifest.sh`
  - `bash scripts/ci/all.sh`

### Task 2.3: Render goldens and fixtures for migration skill

- **Location**:
  - `targets/<product>/...`
  - `tests/golden/`
  - `tests/runtime-smoke/fixtures/`
- **Description**: Refresh the render-goldens for the new skill body
  across supported products, and add runtime-smoke fixtures for both
  the dry-run and apply paths against a synthetic working / archive
  pair.
- **Dependencies**: Tasks 2.1, 2.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Render-goldens reflect the new skill bodies under each product.
  - Runtime-smoke fixtures cover dry-run, apply success, and apply
    abort on push failure.
- **Validation**:
  - `bash scripts/ci/all.sh`

## Sprint 3: Query Skill

**Goal**: Add `meta:plan-archive-query` (default name; [Q2]) as the
read / refresh surface that wraps `plan-archive query` and
`plan-archive refresh`.

**PR grouping intent**: group

**Execution Profile**: serial

### Task 3.1: Author the query skill body

- **Location**:
  - `core/skills/meta/plan-archive-query/SKILL.md.tera`
  - `core/skills/meta/plan-archive-query/references/`
- **Description**: Author the skill body. The skill reads cache by
  default, surfaces `fetched_at` on every record, and provides
  explicit refresh by ref, by repo, or by date window. The skill
  enforces the user-review step before any refresh commit that
  triggered a `.scrub.log`.
- **Dependencies**: Plan 1 released
- **Complexity**: 4
- **Acceptance criteria**:
  - Skill body passes the skill-governance H2 body-shape audit.
  - Skill body never instructs the user to call `forge-cli` directly
    for the same payload.
  - `fetched_at` is surfaced by default.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`

### Task 3.2: Manifest and plugin registration for query skill

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `core/hooks/shared/skill-usage-reminder.skills.json`
- **Description**: Same shape as Task 2.2 but for the query skill.
- **Dependencies**: Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Manifest validation passes.
  - Plugin containment is unique.
  - `required_clis` floor matches Task 2.2.
- **Validation**:
  - `bash scripts/ci/validate-surfaces-manifest.sh`
  - `bash scripts/ci/all.sh`

### Task 3.3: Render goldens and fixtures for query skill

- **Location**:
  - `targets/<product>/...`
  - `tests/golden/`
  - `tests/runtime-smoke/fixtures/`
- **Description**: Refresh render-goldens and add runtime-smoke
  fixtures covering single-ref read, cross-repo aggregate, refresh
  with redaction triggering scrub-log review, and archive plan link
  traversal.
- **Dependencies**: Tasks 3.1, 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Render-goldens reflect the new skill bodies under each product.
  - Runtime-smoke fixtures cover each query mode and the
    scrub-review gate.
- **Validation**:
  - `bash scripts/ci/all.sh`

## Sprint 4: Validation Closeout

**Goal**: Make the new surfaces first-class citizens of the
governance and acceptance stack.

**PR grouping intent**: group

**Execution Profile**: serial

### Task 4.1: Skill-governance audit coverage

- **Location**:
  - `scripts/ci/skill-governance-audit.sh`
  - `tests/runtime-smoke/fixtures/skill-lifecycle/`
- **Description**: Confirm both new skills appear in the governance
  audit's expected list and that their fixtures pass the create-skill
  completeness checks.
- **Dependencies**: Tasks 2.x and 3.x
- **Complexity**: 2
- **Acceptance criteria**:
  - Both new skills are present in the audit's expected list.
  - Audit run is clean on a fresh checkout.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`

### Task 4.2: Sandbox install rehearsal and overlay smoke

- **Location**:
  - `tests/runtime-smoke/`
  - `tests/projects/project-local-smoke/`
- **Description**: Add the new skills to the sandbox install rehearsal
  expected list and to the project-overlay smoke fixture (if the
  overlay smoke runs on `meta` skills).
- **Dependencies**: Task 4.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Sandbox install rehearsal succeeds with both new skills present.
  - Project-overlay smoke (if applicable) succeeds.
- **Validation**:
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - Project-overlay smoke command per current convention.

## Issue Closeout Gate

- All Sprint 1–4 PRs are merged.
- Sandbox install rehearsal, runtime-smoke, governance audit, manifest
  validation, and render-golden checks pass in CI.
- The archive repository contains at least one migrated plan that the
  query skill can locate by ref.
- The master discussion source is reviewed for any follow-up actions
  worth promoting to retained docs.

## Future Work (Out Of Scope For This Tracker)

- Bulk migration of pre-v1 `docs/plans/<slug>/` folders.
- Reopen-detection automation.
- Compaction of historical `_index/` snapshots.
- Promoting the workflow into a maintained runbook under
  `docs/source/`.
- Web UI for browsing the archive.
