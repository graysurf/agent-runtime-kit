# Plan: Skill Usage Evidence Durability And Query

## Overview

Make skill-usage evidence useful at the moments that matter. Today the
`skill-usage` reminder hook fires for 35 high-impact skills and the
`skill-usage` CLI produces a verified `skill-usage.record.v1` envelope, but the
consumption side is thin: the only programmatic consumer is
`heuristic-inbox new --from-skill-usage`, the records live as ephemeral runtime
evidence under the `agent-out` tree, the heuristic-system gatekeeper rejects raw
records from commit, and there is no list / search / aggregate surface. Records
are easy to write and hard to read back.

This plan builds the missing consumption path in three coordinated streams and
then re-reviews how `skill-usage` and the heuristic-system define and cooperate:

1. Closeout signal surfacing so a session never loses a record worth promoting.
2. A producer nils-cli version stamp plus evidence query primitives so records
   are unambiguous and searchable across versions.
3. A durable evidence archive store and a scrubbed migrate path, mirroring the
   proven `agent-plan-archive` + `plan-archive` pattern.

This is an L2 plan because the work spans three repositories
(`agent-runtime-kit`, `nils-cli`, and a durable archive store), is expected to
land through multiple focused PRs, carries unresolved design decisions that must
be frozen before building, and needs a state ledger to prevent scope drift. It
is serial: each stream depends on a design decision or an upstream primitive
from the previous one.

## Read First

- Primary source:
  `docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Prior pattern reference: the `agent-plan-archive` repo and the released
  `plan-archive` CLI (`catalog` / `query` / `search` / `refresh` / `migrate` /
  `discover` / `validate-*`) are the storage-plus-query template to mirror, not
  reinvent.
- Current producer / consumer surfaces:
  - `core/skills/evidence/skill-usage/SKILL.md.tera`
  - `core/hooks/shared/skill-usage-reminder.py` and
    `core/hooks/shared/skill-usage-reminder.skills.json`
  - `core/policies/heuristic-system/HEURISTIC_SYSTEM.md`
  - `core/skills/meta/heuristic-session-closeout/SKILL.md.tera`
- Open questions carried into execution:
  - Durable grain: archive raw envelopes wholesale, roll up to one index record
    per session / skill-run, or archive only curated-promoted records.
  - Storage target: DECIDED before execution. A new sibling archive repo
    mirroring `agent-plan-archive`; clone path resolves `--archive` flag >
    `$AGENT_EVIDENCE_ARCHIVE_HOME` env > machine-local config `archive_clone_path`
    (config under `$XDG_CONFIG_HOME/agent-evidence-archive/`) > documented default
    `${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive`. See the source
    doc Key Decisions for rejected alternatives.
  - The exact `producer` schema field shape and which nils-cli surface owns it.
  - The query shapes operators actually need (by skill, outcome, repo, time).
  - The redaction / scrub policy reused from `plan-archive refresh` and
    `heuristic-inbox ingest-evidence`.

## Scope

In scope:

- A frozen design decision document for grain, storage target, producer-version
  schema, query shapes, redaction policy, and cross-repo coordination.
- `heuristic-session-closeout` surfacing of the active session's skill-usage
  records and outcomes.
- A nils-cli `producer` version stamp on the `skill-usage.record.v1` envelope,
  with a matching kit version-pin bump.
- nils-cli evidence query primitives (list / search / aggregate) with declared
  readable schema versions.
- A durable evidence archive store with config, schema, and validation, plus a
  scrubbed migrate path from the `agent-out` tree.
- A re-review and reconciliation of the `skill-usage` and heuristic-system
  definitions and their interaction across the new lifecycle.

Out of scope:

- Widening or narrowing the reminder catalog beyond what the re-review proves is
  warranted in Sprint 5.
- Changing unrelated nils-cli command contracts.
- Backfilling historical pre-stamp records into the archive.
- Runtime-home installation changes beyond the version-pin bump.
- Private machine-local skills.

## Assumptions

1. The `agent-plan-archive` + `plan-archive` model is a sufficient template for a
   durable, version-aware, queryable evidence store; the design risk is low.
2. The nils-cli changes (producer version field, query primitives) land as their
   own upstream nils-cli PRs and are referenced from this tracker; the kit
   coordinates them through the version-pin and consumes them after release.
3. GitHub is the provider for the tracking issue, so both `workflow::plan` and
   `workflow::tracking` labels apply.
4. Raw records contain command transcripts and local paths, so any committed
   archive entry must be scrubbed; no raw `skill-usage.record.json` is committed.
5. The closeout surfacing in Sprint 2 delivers most of the "never lose a record
   worth promoting" value on its own and validates demand before the archive is
   built.

## Sprint 1: Design Freeze And Tracker Baseline

**Goal**: Open the tracker and freeze the design decisions that gate every later
sprint, so building does not start on a guessed schema.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Create the plan bundle and open the tracker

- **Location**:
  - `docs/plans/2026-06-14-skill-usage-evidence-archive/`
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
  - `plan-tooling validate --file docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md --format text --explain`
  - `plan-issue record audit --profile tracking --expect-visible`

### Task 1.2: Freeze the evidence-record design decisions

- **Location**:
  - `docs/plans/2026-06-14-skill-usage-evidence-archive/`
- **Description**: Write a design decision document that resolves every open
  question in Read First: durable grain, storage target, the `producer` schema
  field shape, the query shapes operators need, the redaction / scrub policy, and
  the cross-repo coordination model. Record the chosen option and the rejected
  alternatives for each decision.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Each open question has a decision with stated rejected alternatives.
  - The durable grain and storage target are chosen before any store is built.
  - The query shapes are concrete enough to drive a catalog schema.
  - The scrub policy names the reused nils-cli redaction surface.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md --format text --explain`
  - `git diff --check`

## Sprint 2: Closeout Signal Surfacing

**Goal**: Make the active session's skill-usage records visible at closeout so no
record worth promoting is silently lost. Kit-side only; no new repo.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 2.1: Surface session skill-usage records in closeout

- **Location**:
  - `core/skills/meta/heuristic-session-closeout/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `tests/golden/`
- **Description**: Teach `heuristic-session-closeout` to enumerate the active
  session's `*-skill-usage` records under the `agent-out` tree with their skill,
  outcome status, and linked evidence, so fail / blocked / worked-around runs are
  reviewed for promotion before the session ends. Use existing data only.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Closeout lists the session's skill-usage records with outcome status.
  - Records with non-pass outcomes are flagged for promotion review.
  - The closeout boundary (no auto-commit of raw records) is preserved.
  - Rendered Codex / Claude goldens match the source change.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`

## Sprint 3: Producer Version And Query Primitives

**Goal**: Land the upstream nils-cli primitives that make records unambiguous
across versions and searchable, then consume them in the kit through the
version-pin.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Stamp the producer nils-cli version on the record

- **Location**:
  - `nils-cli` (upstream, referenced PR)
  - `manifests/` version-pin surface in this repo
- **Description**: Add a `producer` block (tool name and nils-cli version) to the
  `skill-usage.record.v1` envelope so archived records carry the producing
  version. Land it upstream in nils-cli, release it, and bump the kit version-pin
  via the `nils-cli-bump` flow.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - New records carry the producer tool and nils-cli version.
  - The schema version is incremented only if the addition is not backward
    compatible; otherwise the field is additive.
  - The kit version-pin is bumped and aligned after the nils-cli release.
- **Validation**:
  - nils-cli upstream test / clippy gates (referenced).
  - `agent-runtime doctor --class version-alignment`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence`

### Task 3.2: Add evidence query primitives

- **Location**:
  - `nils-cli` (upstream, referenced PR)
  - `docs/source/nils-cli-surface.md`
- **Description**: Add list / search / aggregate query primitives over archived
  records, mirroring `plan-archive` `query` / `catalog` / `search`. Queries run
  against a normalized derived view and declare the schema versions they can
  read, so mixed-version archives stay queryable.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Query primitives filter by skill, outcome, repo, and time.
  - The query surface declares its readable schema-version range.
  - The nils-cli surface doc records the new commands.
- **Validation**:
  - nils-cli upstream test / clippy gates (referenced).
  - `bash scripts/ci/all.sh`

## Sprint 4: Evidence Archive Store And Migrate Path

**Goal**: Stand up the durable, scrubbed evidence store chosen in Sprint 1 and the
path that moves rolled-up records into it.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Stand up the evidence archive store

- **Location**:
  - new sibling archive repo `agent-evidence-archive`
  - `docs/source/`
- **Description**: Create the durable evidence archive mirroring the
  `agent-plan-archive` layout: config, an index / catalog schema, and
  `validate-*` style integrity checks. Resolve the clone path as `--archive`
  flag > `$AGENT_EVIDENCE_ARCHIVE_HOME` env > machine-local config
  `archive_clone_path` (config under `$XDG_CONFIG_HOME/agent-evidence-archive/`) >
  documented default `${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive`.
  Do not store raw envelopes if the chosen grain is rollup.
- **Dependencies**:
  - Task 1.2
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - The store has config, an index schema, and integrity validation.
  - The layout follows the archive precedent so the query CLI can read it.
  - No raw `skill-usage.record.json` is committed.
- **Validation**:
  - Archive integrity validation (the chosen `validate-*` surface).
  - `git diff --check`

### Task 4.2: Build the scrubbed migrate path

- **Location**:
  - `core/skills/` (migrate skill or extension)
  - `core/policies/`
  - `manifests/skills.yaml`
  - `tests/golden/`
- **Description**: Provide the dry-run-first path that rolls up and scrubs
  records from the `agent-out` tree into the archive, reusing the
  `plan-archive refresh` scrub-log review and `heuristic-inbox ingest-evidence`
  redaction discipline. A scrub log must be reviewed before commit.
- **Dependencies**:
  - Task 3.2
  - Task 4.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Migration is dry-run-first and scrubs before writing.
  - A reviewable scrub log is produced; raw records are never committed.
  - The migrate surface is discoverable and documented.
  - Rendered Codex / Claude goldens match source changes.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`

## Sprint 5: Lifecycle Re-Review, Delivery, And Closeout

**Goal**: Re-review how skill-usage and the heuristic-system define and cooperate
across the new lifecycle, then deliver and close only after issue-visible
evidence is complete.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 5.1: Re-review the skill-usage and heuristic-system contract

- **Location**:
  - `core/policies/heuristic-system/HEURISTIC_SYSTEM.md`
  - `core/skills/evidence/skill-usage/SKILL.md.tera`
  - `core/hooks/shared/skill-usage-reminder.skills.json`
  - `core/skills/meta/heuristic-session-closeout/SKILL.md.tera`
- **Description**: Reconcile the definitions and interaction of skill-usage, the
  reminder catalog, closeout surfacing, the archive, and heuristic-inbox
  promotion into one coherent record-produce-curate-archive-query lifecycle.
  Adjust the reminder catalog scope only where the new consumption path justifies
  it.
- **Dependencies**:
  - Task 2.1
  - Task 3.2
  - Task 4.2
- **Complexity**: 4
- **Acceptance criteria**:
  - The end-to-end lifecycle is documented in one place without contradicting
    the per-skill bodies.
  - The reminder catalog scope is justified against the consumption path.
  - No safety gate or retention boundary is lost in the reconciliation.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 5.2: Deliver close-ready evidence and close the tracker

- **Location**:
  - `docs/plans/2026-06-14-skill-usage-evidence-archive/`
- **Description**: Run the full runtime-kit gate stack, record final state,
  session, validation, review, and linked PR evidence on the tracker, and run
  close-ready and closeout only when every task row has evidence.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Full `scripts/ci/all.sh` passes on a clean tree.
  - `tests/hooks/run.sh` passes.
  - Tracker contains current state, session, validation, review, and closeout
    evidence.
  - `tracking close-ready --profile tracking --expect-visible` returns
    `ready: true`.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`
  - `plan-issue tracking close-ready --profile tracking --expect-visible`
