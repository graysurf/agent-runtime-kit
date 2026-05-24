---
name: dispatch-plan-closeout
description:
  Close out a shared dispatch plan record after lane PRs, review, validation, approval, and lifecycle gates pass.
---

# Dispatch Plan Closeout

## Contract

Prereqs:

- `plan-issue >=0.20.0`, `review-evidence`, and `review-specialists` are
  available on `PATH`.
- The target issue was created or maintained by `deliver-dispatch-plan` and has
  dispatch-profile lifecycle comments plus dispatch state payloads.
- The main agent is acting as orchestrator/reviewer only; implementation remains
  on subagent-owned task lanes.
- Final approval evidence is known before live close.

Inputs:

- Dispatch issue number, repository slug, approval evidence, linked lane PRs,
  final integration PR, and optional review summary.
- Provider issue body and comments JSON for optional pre-close audit.
- Dispatch validation, review, and cleanup evidence.

Outputs:

- Current dispatch audit result.
- Review decisions executed through `review-dispatch-lane-pr` with retained
  evidence.
- Closeout comment, final dashboard repair, linked PR verification, and issue
  close performed by `plan-issue record close`.

Failure modes:

- The issue is not a dispatch-profile record, or dispatch state comments are
  missing.
- PR references are missing, unmerged, wrong-base, or not reflected in current
  dispatch state.
- Follow-up is routed to a replacement lane without explicit reassignment.
- Review evidence, approval, final integration, issue mention, or closeout gate
  evidence fails.

## Entrypoint

Optional read-back audit:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile dispatch \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON"
```

Live closeout:

```bash
plan-issue --repo "$OWNER_REPO" --format json record close \
  --issue "$ISSUE" \
  --profile dispatch \
  --linked-pr "$OWNER_REPO#$FINAL_PR" \
  --approval "$APPROVAL" \
  --bundle "$PLAN_BUNDLE"
```

## Workflow

1. Confirm repository, issue number, runtime mode, provider auth, and approval
   basis.
2. Run `record audit --profile dispatch`; reject lightweight tracking issues
   and route them to `plan-tracking-issue-closeout`.
3. Confirm task owners remain subagent identities; main-agent implementation
   ownership is invalid for dispatch issues.
4. For each lane, verify branch, worktree, execution mode, PR reference,
   dispatch bundle, validation evidence, and review evidence.
5. Keep task-lane continuity: clarification, CI repair, and review follow-up go
   back to the current lane unless main-agent explicitly reassigns it.
6. Use `review-dispatch-lane-pr` for request-followup, merge, or close-pr
   decisions. Record specialist review as used or skipped with rationale.
7. Append dispatch state/session/validation/review comments through
   `record post` after review decisions; dashboards are repaired through
   `record repair-dashboard`.
8. Run `record close --profile dispatch` only when all implementation and review
   gates are ready for final approval.
9. If `record close` fails, leave the issue open and surface the exact blocked
   code and required next action.

## Boundary

`plan-issue record` owns dispatch audit, strict closeout, linked PR provider
verification, closeout commenting, dashboard repair, and issue close.
`review-dispatch-lane-pr` owns review-decision execution. This skill owns
closeout orchestration, lane continuity enforcement, approval interpretation,
and final issue evidence quality.

## References

- Local rehearsal: `references/LOCAL_REHEARSAL.md`
- Task lane continuity:
  `skills/dispatch/deliver-dispatch-plan/references/TASK_LANE_CONTINUITY.md`
- Main-agent review rubric:
  `skills/dispatch/deliver-dispatch-plan/references/MAIN_AGENT_REVIEW_RUBRIC.md`
- Post-review outcomes:
  `skills/dispatch/deliver-dispatch-plan/references/POST_REVIEW_OUTCOMES.md`
- Dispatch issue record contract:
  `skills/dispatch/deliver-dispatch-plan/references/DISPATCH_ISSUE_RECORD_CONTRACT.md`
