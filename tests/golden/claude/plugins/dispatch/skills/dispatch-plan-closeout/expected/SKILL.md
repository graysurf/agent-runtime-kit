---
name: dispatch-plan-closeout
description:
  Close out a shared dispatch plan record after lane PRs, review, validation, approval, and lifecycle gates pass.
---

# Dispatch Plan Closeout

## Contract

Prereqs:

- `plan-issue`, `forge-cli`, `review-evidence`, `review-specialists`, and
  `gh` are available on `PATH`. The lifecycle record commands require
  `plan-issue >=0.17.4`; before release, prepend the scoped nils-cli debug
  binary directory to `PATH`. `gh` is required because `forge-cli issue
  view --format json` (forge-cli 0.17.6) does not include comments —
  `plan-issue record audit|closeout-gate --comments-json` needs a payload
  with the `comments` array, which `gh issue view --json body,comments`
  returns directly.
- The target issue was created or maintained by `deliver-dispatch-plan` and has
  dispatch profile lifecycle comments plus a dispatch ledger.
- The main agent is acting as orchestrator/reviewer only; implementation
  remains on subagent-owned task lanes.
- Final approval evidence is known before live close.

Inputs:

- Dispatch issue number, repository slug, approval evidence, linked lane PRs,
  final integration PR, and optional review summary.
- Provider issue body and comments JSON for audit and closeout-gate checks.
- Dispatch validation, review, and cleanup evidence.

Outputs:

- Current dispatch audit and closeout-gate result.
- Review decisions executed through `review-dispatch-lane-pr` with retained
  evidence.
- One dispatch closeout comment rendered by `plan-issue record`.
- Final dashboard with latest dispatch state/session/validation/review/closeout
  links, then provider issue close through `forge-cli`.

Failure modes:

- The issue is not a dispatch profile record, or dispatch ledger/state comments
  are missing.
- PR references are missing, unmerged, wrong-base, or not reflected in current
  dispatch state.
- Follow-up is routed to a replacement lane without explicit reassignment.
- Review evidence, approval, final integration, issue mention, or closeout gate
  evidence fails.

## Entrypoint

Audit and gate dispatch state. Fetch the body + comments through `gh`
(or `glab` on the GitLab side); `forge-cli issue view --format json`
only returns the body fields and would resolve `--comments-json` to an
empty comment set:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_COMMENTS_JSON"
jq -r .body "$ISSUE_COMMENTS_JSON" >"$ISSUE_BODY"

plan-issue record audit \
  --profile dispatch \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --format json

plan-issue record closeout-gate \
  --profile dispatch \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --require-complete \
  --require-session \
  --require-validation \
  --require-review \
  --approval "$APPROVAL" \
  --linked-pr "#$FINAL_PR" \
  --format json
```

Render and apply closeout. `forge-cli issue close` (forge-cli 0.17.6)
does not accept `--reason`; the backend `gh issue close <id>` runs
without a reason argument:

```bash
plan-issue record render-comment \
  --profile dispatch \
  --marker-family shared \
  --kind closeout \
  --content-file "$CLOSEOUT_MD" \
  --out "$CLOSEOUT_COMMENT"

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$CLOSEOUT_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$FINAL_DASHBOARD" --format json
forge-cli issue close "$ISSUE" --repo "$OWNER_REPO" --format json
```

## Workflow

1. Confirm repository, issue number, runtime mode, provider auth, and approval
   basis.
2. Run `plan-issue record audit --profile dispatch`; reject lightweight
   tracking issues and route them to `plan-tracking-issue-closeout`.
3. Confirm task owners remain subagent identities; main-agent implementation
   ownership is invalid for dispatch issues.
4. For each lane, verify branch, worktree, execution mode, PR reference,
   dispatch bundle, validation evidence, and review evidence.
5. Keep task-lane continuity: clarification, CI repair, and review follow-up go
   back to the current lane unless main-agent explicitly reassigns it.
6. Use `review-dispatch-lane-pr` for request-followup, merge, or close-pr
   decisions. Record specialist review as used or skipped with rationale.
7. Append dispatch state/session/validation/review comments after review
   decisions; the dashboard should link latest evidence rather than carry the
   durable ledger itself.
8. Run `closeout-gate` only when all implementation and review gates are ready
   for final approval.
9. Post one closeout comment, repair the dashboard, and close the issue through
   `forge-cli` only after approval, merged PRs, final integration mention, and
   cleanup gates pass.

## Boundary

`plan-issue record` owns dispatch audit, closeout-gate evidence, and
dashboard/comment rendering. `forge-cli` owns provider issue and PR lifecycle.
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
