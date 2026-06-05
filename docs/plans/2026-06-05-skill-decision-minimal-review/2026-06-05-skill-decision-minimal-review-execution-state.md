# Skill Decision-Minimal Review Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress - L2 bundle is being created and the tracking issue is
  not opened yet.
- Target scope: repo-wide decision-minimal review of managed
  agent-runtime-kit skills, preserving safety gates while reducing redundant
  prose.
- Execution window: Sprint 1 tracking and audit baseline -> Sprint 2 shared
  rubric and patterns -> Sprint 3 high-risk workflow skills -> Sprint 4 support
  and prompt-style skills -> Sprint 5 integration and closeout.
- Current task: Task 1.1.
- Next task: Task 1.2.
- Last updated: 2026-06-05T17:48:36Z
- Branch/commit/PR: docs/skill-decision-minimal-review (bundle branch; no PR
  yet).
- Source document: docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-plan.md
- Plan document: docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending

## Validation Plan

- Bundle:
  - `plan-tooling validate --file docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-plan.md --format text --explain`
- Tracker open:
  - `plan-issue --repo graysurf/agent-runtime-kit --format json --dry-run record open --profile tracking --bundle docs/plans/2026-06-05-skill-decision-minimal-review --title "skill decision-minimal review" ...`
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- Runtime-kit batches:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `bash scripts/ci/skill-governance-audit.sh`
  - domain-specific deterministic smoke commands named in the plan.
- Final validation:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | in-progress | Create the plan bundle and open the tracker | pending | Bundle files are being authored in this branch. |
| 1.2 | pending | Produce the skill inventory and triage matrix | pending | Starts after tracker open. |
| 2.1 | pending | Place the reusable skill-editing rubric | pending | Starts after inventory. |
| 2.2 | pending | Identify shared-spec candidates per domain | pending | Starts after rubric placement. |
| 3.1 | pending | Review PR and issue lifecycle skills | pending | Starts after shared-spec decisions. |
| 3.2 | pending | Review meta and repository-mutation skills | pending | Starts after PR/issue lifecycle skills. |
| 4.1 | pending | Review code-review and evidence skills | pending | Starts after meta skills. |
| 4.2 | pending | Review conversation, browser, media, and reporting skills | pending | Starts after code-review and evidence skills. |
| 5.1 | pending | Run full render, governance, drift, and smoke validation | pending | Starts after all edit batches. |
| 5.2 | pending | Deliver close-ready evidence and close the tracker | pending | Starts only when all ledger rows have evidence. |

## Session Log

- 2026-06-05: User selected L2 for a full repo-wide skill cleanup using the
  decision-minimal pattern from PR #286. Bundle authoring started on
  `docs/skill-decision-minimal-review`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| pending | pending | Plan bundle validation has not run yet. | n/a |
