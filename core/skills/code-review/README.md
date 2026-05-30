# Code Review Skill Routing

This directory contains the code review skill family. Prefer the lightest
workflow that can answer the review question, and escalate only when scope,
risk, or delivery policy requires it.

## Skill Selection

| Situation | Use | Notes |
| --- | --- | --- |
| Small, routine, docs-only, or ordinary diff | `code-review-quick-pass` | Lightweight read-only review. Escalates when scope or confidence requires a stronger workflow. |
| Explicit review lens requested, such as testing, security, performance, data migration, API contract, maintainability, or red-team | `code-review-focused-lens` | Runs one or more named lenses without invoking the full specialist bundle. Escalates if the selected lens exposes broader risk. |
| PR/MR is close to merge and needs the shared delivery gate | `code-review-pre-merge-gate` | Mandatory delivery gate. Forces at least `testing` and `maintainability`, produces a delivery outcome, and leaves provider comments/merge decisions to the owning delivery workflow. |
| Previous review findings were repaired and need disposition evidence | `code-review-follow-up` | Re-checks prior findings after fixes. It does not start a fresh broad review unless new concrete risk appears. |
| Broad, risky, security-sensitive, migration-heavy, API-contract-heavy, or otherwise full-bundle review | `code-review-specialists` | Full specialist review bundle. Avoid for tiny diffs, ordinary implementation work, pure formatting, docs-only changes, or CI repair loops unless explicitly requested. |

## Current Callers

| Caller skill | Review routing | Notes |
| --- | --- | --- |
| `discussion-to-implementation-doc` | Does not run review by default; records the expected review gate in the source document. | Routes later review guidance to `quick-pass`, `focused-lens`, `pre-merge-gate`, `follow-up`, or `specialists` based on scope. |
| `close-pr` | Optional user-requested review chooses the lightest matching workflow. | Uses `quick-pass` for routine diffs, `focused-lens` for explicit lenses, `pre-merge-gate` for final delivery gates, and `specialists` only for broad or risky full-bundle review. Close skills do not require `review-specialists` in their manifest because review is optional. |
| `deliver-pr` | `code-review-pre-merge-gate`. | Mandatory before merge; the delivery workflow owns comments, fixes, checks, and merge. Uses the PR base or MR target branch as the review base. |
| `deliver-plan-tracking-issue` | `code-review-pre-merge-gate` for every PR. | Mandatory before merge, even for small diffs, because the plan-tracking workflow owns delivery readiness. |
| `deliver-dispatch-plan` | `review-dispatch-lane-pr`, with supplemental `code-review-specialists` when risk warrants it. | Lane reviews stay in the dispatch lane review workflow; specialist review is read-only evidence. |
| `review-dispatch-lane-pr` | Optional `code-review-specialists` for broad or high-risk lane PRs. | Records specialists as used or skipped in review evidence. |
| `dispatch-plan-closeout` | Does not directly run code review. | Verifies lane review evidence and records specialist review as used or skipped. |
| `review-evidence` | May import `code-review-specialists` reports. | Keeps specialist output as evidence; caller owns judgment and blocking decisions. |

## Boundary

All code review skills are read-only. They can produce findings, gate results,
reports, escalation rationale, and disposition evidence, but they do not fix
code, post provider comments, merge PRs/MRs, or close issues. The workflow that
invoked review owns those actions.
