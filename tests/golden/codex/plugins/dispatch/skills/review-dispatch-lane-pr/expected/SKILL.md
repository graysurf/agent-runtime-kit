---
name: review-dispatch-lane-pr
description:
  Review dispatch-lane PRs with retained evidence, provider comments, and issue-visible dispatch lifecycle updates.
---

# Review Dispatch Lane PR

## Purpose

Review one dispatch lane PR (or MR), record retained review evidence,
post provider review comments via the approved PR workflow, and update
the shared dispatch issue with the review status. The skill never
implements fixes unless the user explicitly redirects.

## When to use

- A dispatch lane PR is ready for review and the assigned reviewer has
  the lane scope in context.
- Review findings need to be recorded so the dispatch issue reflects
  current review status.

## Inputs

- `OWNER_REPO`, lane PR reference, `RUN_STATE`, `ISSUE` (shared dispatch
  issue).
- Reviewer judgment outputs: decision (`approve|request-changes|
  comments-only`), lenses, and finding dispositions.

## Preflight

- `plan-issue >=0.22.3`, `forge-cli`, and `review-evidence` are on
  `PATH`.
- The PR exists, targets the correct base, and reports passing required
  checks (or the reviewer has explicit override authority).
- `tracking status --profile dispatch --expect-visible` is clean before
  recording review status.

## Allowed lifecycle roles

- `review` checkpoint through `plan-issue tracking checkpoint --profile
  dispatch --post review` for the lane scope.
- Dispatch `state` / `session` update when the review outcome changes
  lane state (e.g., requested-changes flips lane back to implementing).
- Provider review comments through `forge-cli pr review` (or the
  appropriate PR helper).

## Forbidden actions

- No implementing fixes unless the user explicitly switches the lane
  from review to implementation.
- No `record close` and no closeout comment.
- No PR merge.
- No raw `gh pr review`, `glab mr approve`, or raw issue/PR comments for
  recorded review evidence.
- No skipping retained review evidence when findings exist (use
  `review-evidence` to persist findings before posting the checkpoint).

## CLI flow

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" --expect-visible

review-evidence --plan "$PLAN" --pr "$LANE_PR" --format json \
  >"$REVIEW_EVIDENCE"

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --review-decision "$DECISION"

plan-issue --format json tracking checkpoint \
  --profile dispatch --run-state "$RUN_STATE" \
  --post review --repair-dashboard

forge-cli pr review --repo "$OWNER_REPO" --pr "$PR_NUMBER" \
  --decision "$DECISION" --comment "$REVIEW_COMMENT" --format json
```

## Evidence requirements

- `review-evidence` returns a retained findings artifact path or URL.
- The `tracking checkpoint` envelope shows the `review` role posted with
  `lint_pass: true` and (when findings exist) a `disposition` row per
  finding.
- The shared dispatch dashboard reflects the latest lane review status.

## Stop conditions

- `tracking status` reports `run-state-stale` — refuse to record review
  evidence until reconciliation succeeds.
- Findings contain unresolved blocker severities — the lane must return
  to implementation (or be explicitly waived) before approval.
- `forge-cli pr review` fails (auth, missing PR, etc.) — surface and
  stop.

## Validation

- `tracking checkpoint --post review` envelope has `lint_pass: true` and
  no blockers.
- `forge-cli pr review` returns the recorded review URL.
- Read-back audit against the lane PR finds the review comment.

## Boundary

`review-evidence` owns retained findings. `forge-cli pr review` owns
provider review comments. `plan-issue tracking` owns the lifecycle
checkpoint. The skill body owns the review judgment.
