## Current Dashboard

This issue is the durable tracking surface for an issue-backed plan execution. The full source, plan, and execution logs remain in
append-only issue comments.

- Status: in-progress
- Profile: tracking
- Target scope: make the four deliver-* skills self-contained by chaining matching closeout/close skills inline
- Current task: Sprint 1 Task 1.1 — inline closeout in deliver-plan-tracking-issue
- Next action: Sprint 1 Task 1.2 — inline closeout in deliver-dispatch-plan
- Validation: pending
- Linked PRs: none yet
- Blockers: none
- Review approval: pending

## Durable Record

- Source snapshot: pending
- Plan snapshot: pending
- Execution state: pending
- Latest session: pending
- Latest validation: pending
- Closeout comment: pending

## Guardrails

- The issue body is a mutable dashboard only.
- Append-only issue comments are the durable source of truth.
- `plan-tooling` owns plan parsing, validation, batching, and PR split modeling only.
- Provider create, comment, edit, and close operations remain owned by `forge-cli` or provider atoms.

## Original Tracker

- Title: Deliver-* skills autonomous closeout
