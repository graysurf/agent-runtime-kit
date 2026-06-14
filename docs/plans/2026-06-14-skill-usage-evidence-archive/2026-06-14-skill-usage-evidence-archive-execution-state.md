# Skill Usage Evidence Durability And Query Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in progress; plan bundle authored, tracker not yet opened.
- Target scope: make skill-usage evidence durable and queryable through closeout
  surfacing, a producer nils-cli version stamp, evidence query primitives, and a
  scrubbed evidence archive store, then re-review the skill-usage and
  heuristic-system contract.
- Execution window: Sprint 1 design freeze and tracker baseline -> Sprint 2
  closeout surfacing -> Sprint 3 producer version and query primitives ->
  Sprint 4 archive store and migrate path -> Sprint 5 re-review, delivery, and
  closeout.
- Current task: Task 1.1.
- Next task: Task 1.2.
- Last updated: 2026-06-14
- Branch/commit/PR: docs/skill-usage-evidence-archive (bundle branch)
- Source document: docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md
- Plan document: docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending; opened by create-plan-tracking-issue

## Validation Plan

- Bundle:
  - Run `plan-tooling validate --file <plan-file> --format text --explain`.
- Tracker open:
  - Dry-run `plan-issue record open` against the tracker bundle.
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- Runtime-kit batches:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `bash scripts/ci/skill-governance-audit.sh`
  - domain-specific deterministic smoke commands named in the plan.
- Upstream nils-cli:
  - nils-cli test / clippy gates (referenced) and
    `agent-runtime doctor --class version-alignment` after the version-pin bump.
- Final validation:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | in-progress | Create the plan bundle and open the tracker | Bundle authored on docs/skill-usage-evidence-archive; plan-tooling validate pending; tracker open pending. | This task. |
| 1.2 | pending | Freeze the evidence-record design decisions | none | Resolves grain, storage, producer schema, query shapes, redaction. |
| 2.1 | pending | Surface session skill-usage records in closeout | none | Kit-only; uses existing agent-out data. |
| 3.1 | pending | Stamp the producer nils-cli version on the record | none | Upstream nils-cli PR + kit version-pin bump. |
| 3.2 | pending | Add evidence query primitives | none | Mirror plan-archive query/catalog/search. |
| 4.1 | pending | Stand up the evidence archive store | none | Per Sprint 1 storage decision. |
| 4.2 | pending | Build the scrubbed migrate path | none | Dry-run-first; scrub-log review; no raw commit. |
| 5.1 | pending | Re-review the skill-usage and heuristic-system contract | none | One coherent lifecycle. |
| 5.2 | pending | Deliver close-ready evidence and close the tracker | none | Full CI + close-ready gate. |

## Session Log

- 2026-06-14: User reviewed `/skill-usage`, identified that records are
  write-easy but read-poor, confirmed all three improvements (closeout
  surfacing, producer version + query, durable archive), chose L2, and invoked
  `create-plan-tracking-issue`. Bundle authoring started on
  `docs/skill-usage-evidence-archive`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md --format text --explain` | pending | Plan bundle validation. | local |
