# Codex Review Subagents Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: tracker setup in progress
- Target scope: make repo-managed code review run through reviewer subagents in
  both Codex and Claude Code, while preserving main-agent ownership of review
  synthesis and delivery decisions.
- Execution window: Sprint 1 tracker and surface baseline -> Sprint 2
  quick-reviewer vertical slice -> Sprint 3 specialist reviewer fan-out ->
  Sprint 4 product probes and delivery integration -> Sprint 5 validation,
  delivery, and closeout.
- Current task: Task 1.1.
- Next task: Task 1.2.
- Last updated: 2026-06-13T17:36:03Z
- Branch/commit/PR: branch `docs/codex-review-subagents`; no PR yet.
- Source document: docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-discussion-source.md
- Plan document: docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending

## Validation Plan

- Plan bundle:
  - `plan-tooling validate --file docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md --format text --explain`
- Tracker open:
  - Dry-run `plan-issue record open --profile tracking`.
  - Live `plan-issue record open --profile tracking` after dry-run shape is
    verified.
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- Runtime-kit implementation:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --target support-matrix`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - `bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only`
- Final validation:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | in-progress | Create the plan bundle and open the tracker | pending | Bundle authoring started in managed worktree `docs/codex-review-subagents`. |
| 1.2 | pending | Baseline reviewer-agent surface requirements | pending | Compare official product docs with current runtime-kit surface registry and link maps. |
| 2.1 | pending | Add managed reviewer-agent source and render/install scaffolding | pending | Starts with quick-reviewer vertical slice. |
| 2.2 | pending | Route quick-pass review through the quick reviewer | pending | Requires explicit waiver/blocker if reviewer subagent dispatch is unavailable. |
| 3.1 | pending | Add specialist reviewer agent definitions | pending | Reuse existing specialist prompts and JSONL contract. |
| 3.2 | pending | Route specialist review through selected reviewer subagents | pending | Main agent validates and merges returned JSONL findings. |
| 4.1 | pending | Add product-safe reviewer-agent discovery probes | pending | Prefer isolated runtime homes and probe-only product checks. |
| 4.2 | pending | Reconcile delivery review callers | pending | Keep provider mutation in delivery skills. |
| 5.1 | pending | Run full project validation | pending | Full CI and hook validation after implementation. |
| 5.2 | pending | Deliver PRs and close the tracker | pending | Closeout and archive only after close-ready passes. |

## Session Log

- 2026-06-13T17:36:03Z: User requested using a managed worktree to run
  `create-plan-tracking-issue` for the Codex/Claude Code review-subagent goal.
  Worktree `docs/codex-review-subagents` was created from `origin/main`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md --format text --explain` | pending | Run before dry-run tracker open. | n/a |
| `plan-issue record open --dry-run` | pending | Preview source/plan/state lifecycle records and labels. | n/a |
| `plan-issue record audit --profile tracking --expect-visible` | pending | Run after live tracker open. | n/a |
