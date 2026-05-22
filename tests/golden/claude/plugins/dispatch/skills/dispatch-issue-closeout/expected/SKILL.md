---
name: dispatch-issue-closeout
description:
  Close out an existing plan-issue dispatch runtime after subagent implementation, main-agent review, approval, and merged PR gates pass.
---

# Dispatch Issue Closeout

## Contract

Prereqs:

- `plan-issue`, `plan-issue-local`, `forge-cli`, `review-evidence`, and
  `review-specialists` are installed from released nils-cli packages and
  available on `PATH`.
- The target issue was created or maintained by `deliver-dispatch-plan` and has
  a `Task Decomposition` table.
- The main agent is acting as orchestrator/reviewer only; implementation
  remains on subagent-owned task lanes.
- The final approval comment URL is known before live close.

Inputs:

- Plan issue number, repository slug, approval comment URL, and optional review
  summary.
- PR linkage inputs for row sync: task ID or sprint/pr-group, canonical PR
  reference, and current row status.
- Dispatch bundle evidence when the issue originated from `start-sprint`:
  `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`, and plan
  task context.
- Review evidence and provider check results for all task-lane PRs and the
  final integration PR, when present.

Outputs:

- Current `status-plan` checkpoint and issue dashboard state.
- Review decisions executed through `dispatch-pr-review` with retained evidence
  and issue row synchronization.
- Final `ready-plan` checkpoint when the issue is ready for close approval.
- `plan-issue close-plan` result, provider issue closed in live mode, and one
  `deliver-dispatch-plan:closeout:v1` checkpoint.

Failure modes:

- The issue is not a dispatch/plan-issue runtime, or task rows are missing.
- Any implementation task is owned by `main-agent` instead of a subagent lane.
- PR references are missing, unmerged, wrong-base, or not synchronized to rows.
- Follow-up is routed to a replacement lane without explicit reassignment.
- Review evidence, approval URL, final integration, issue mention, or close
  gates fail.

## Entrypoint

Inspect current state:

```bash
plan-issue status-plan --issue "$ISSUE" --repo "$OWNER_REPO" --format json
```

Synchronize PR rows before review or close gates:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

Run final ready and close gates:

```bash
plan-issue ready-plan --issue "$ISSUE" --repo "$OWNER_REPO" --summary-file "$SUMMARY" --format json
plan-issue close-plan --issue "$ISSUE" --repo "$OWNER_REPO" --approved-comment-url "$APPROVAL_URL" --format json
```

Use `references/LOCAL_REHEARSAL.md` only when the user explicitly requests
offline rehearsal.

## Workflow

1. Confirm repository, issue number, runtime mode, provider auth, and approval
   basis.
2. Run `status-plan` and verify `Task Decomposition` is the runtime source of
   truth.
3. Confirm task owners remain subagent identities; main-agent implementation
   ownership is invalid for dispatch issues.
4. For each active lane, verify branch, worktree, execution mode, PR reference,
   dispatch bundle, and validation evidence.
5. Keep task-lane continuity: clarification, CI repair, and review follow-up go
   back to the current lane unless main-agent explicitly reassigns it.
6. Use `dispatch-pr-review` for request-followup, merge, or close-pr decisions.
   Record specialist review as used or skipped with rationale.
7. After each review decision, synchronize issue rows with `plan-issue link-pr`
   or the applicable sprint command before continuing.
8. Run `ready-plan` only when all implementation and review gates are ready for
   final approval.
9. Run `close-plan` only after approval, merged PRs, final integration mention,
   and cleanup gates pass.
10. Post or verify one `deliver-dispatch-plan:closeout:v1` marker and ensure the
    dashboard links latest dispatch state/session/validation evidence.

## Boundary

`plan-issue` owns runtime rows, ready/close gates, provider issue updates, and
close operation. `forge-cli` owns provider PR lifecycle. `dispatch-pr-review`
owns review-decision execution. This skill owns closeout orchestration, lane
continuity enforcement, approval interpretation, and final issue evidence
quality.

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
