---
name: review-dispatch-lane-pr
description:
  Review one dispatch lane PR with retained evidence, post provider review comments, and update the shared dispatch issue with the review decision.
---

# Review Dispatch Lane PR

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=0.22.3`, `forge-cli`, `review-evidence`.
- Issue precondition: the shared dispatch issue exists and the lane PR
  has been created by `execute-dispatch-lane` /
  `create-dispatch-lane-pr`.
- PR precondition: the PR exists, targets the correct base, and
  reports passing required checks (or the reviewer has explicit
  override authority).
- Run state precondition: `tracking status --profile dispatch
  --expect-visible` is clean before recording review status.
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO`, `ISSUE` (shared dispatch issue), `RUN_STATE`.
- `LANE_PR` reference and `PR_NUMBER`.
- Reviewer decision (`approve` / `request-changes` /
  `comments-only`), lenses, finding dispositions, and the
  retained-evidence path produced by `review-evidence`.

Outputs:

- `tracking checkpoint --profile dispatch --post review` for the lane
  scope (with `--repair-dashboard` when the dashboard is stale).
- Dispatch lane `state` / `session` update through `tracking
  checkpoint --post state,session` when the review outcome flips the
  lane back to implementation.
- `forge-cli pr review` posts the provider review comment.
- `review-evidence` produces a retained findings artifact path or
  URL.

Failure modes:

- Forbidden lifecycle roles for this skill: `record open`,
  `record close`, lane implementation posts beyond review-driven
  state flips. Direct posts abort with `forbidden-role-for-skill`.
- Controller refusal codes propagated: `run-state-stale`,
  `RECORD_BLOCKED`,
  `tracking-checkpoint-live-not-implemented`,
  `visible-completeness-failed`.
- Visible-completeness lint codes relevant here:
  `review-missing-decision`, `review-missing-disposition`,
  `state-missing-task-ledger`.
- Scope-leak: implementing fixes inside this skill; merging the PR;
  posting raw `gh pr review` / `glab mr approve` for recorded review
  evidence; skipping retained `review-evidence` when findings exist.

## Entrypoint

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

## Workflow

1. **Preflight** — `tracking status --profile dispatch --expect-visible`;
   refuse to record review state on `run-state-stale` or
   `RECORD_BLOCKED`.
2. **Review judgement** — apply review lenses; produce
   `$REVIEW_EVIDENCE` through `review-evidence`. Findings get
   dispositions before approval.
3. **Run state update** — `tracking run update --review-decision`.
4. **Review checkpoint** — `tracking checkpoint --post review
   --repair-dashboard`. If findings flip the lane back to
   implementation, also post `state,session` for the lane scope.
5. **Provider review comment** — `forge-cli pr review` records the
   decision on the provider.
6. **Read-back** — confirm the dispatch dashboard reflects the lane
   review status and the lane PR carries the review comment.
7. **Stop** on any Failure mode code; do not implement fixes unless
   the user explicitly switches the lane from review to
   implementation.

## Boundary

Owns:

- The review judgement (decision, lenses, finding dispositions).
- The decision to flip the lane back to implementation when findings
  block approval.

Does not own:

- Implementing fixes — that is `execute-dispatch-lane` after the
  redirection.
- Closing the dispatch issue — that is `dispatch-plan-closeout`.
- Merging the PR — `forge-cli` and the active PR delivery skills.
- Retained findings format — that is `review-evidence`.

Cross-references:

- Upstream: `execute-dispatch-lane` produces the lane PR.
- Downstream: back to `execute-dispatch-lane` on
  `request-changes`; otherwise on to `dispatch-plan-closeout` once
  all lanes are clean.
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
