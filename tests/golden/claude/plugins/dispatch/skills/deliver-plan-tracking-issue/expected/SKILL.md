---
name: deliver-plan-tracking-issue
description:
  Deliver a lightweight issue-backed plan scope through implementation, review, PR delivery, lifecycle comments, and close readiness gates.
---

# Deliver Plan Tracking Issue

## Purpose

Carry one lightweight plan-tracking issue scope from in-progress
implementation through validation, review, PR delivery, final state, and
non-mutating close-readiness handoff. The skill uses the `plan-issue
tracking` controller for every lifecycle decision and stops before
closeout so `plan-tracking-issue-closeout` can run the strict gate.

## When to use

- The tracking issue is open with at least `source`, `plan`, and `state`
  evidence and the user wants the selected scope carried all the way to
  close-ready handoff.
- Implementation, validation, review evidence, and PR delivery must all
  flow through one orchestration entry point.

## Inputs

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`, `PLAN_BUNDLE`, `BRANCH`.
- Optional `LINKED_PR` reference if the PR already exists.
- Approval evidence (URL or text) when ready for close-ready handoff.

## Preflight

- `plan-issue >=0.22.3`, `plan-tooling`, and `forge-cli` are on `PATH`.
- Run `tracking status --expect-visible` and confirm the FSM is at least
  `RECORD_OPEN_INITIAL` with no `run-state-stale` warning before posting.
- Bundle files exist at canonical paths and the execution-state Markdown
  reflects the latest task ledger.

## Allowed lifecycle roles

- `state` checkpoint through `tracking checkpoint --post state`.
- `session` checkpoint through `tracking checkpoint --post session` for
  meaningful work blocks or handoffs.
- `validation` checkpoint when validation actually ran and changed
  issue-visible status.
- `review` checkpoint after a review gate runs (specialist findings or a
  `comments-only` review evidence record).
- Dashboard repair through `tracking checkpoint --repair-dashboard`.
- Non-mutating `tracking close-ready` probe before declaring close-ready
  handoff.

## Forbidden actions

- No `record open` or `record attach`.
- No `record close` and no closeout lifecycle comment — that is owned by
  `plan-tracking-issue-closeout`.
- No skipping `tracking close-ready` before claiming close-ready handoff.
- No PR merge unless the active `forge-cli pr deliver` / `pr close`
  workflow authorizes that step for this profile.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for lifecycle evidence.
- No bypass of dispatch-only flows (this skill is `--profile tracking`).

## CLI flow

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --expect-visible

# Implementation, validation, review — each followed by run update +
# checkpoint:
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --phase validating \
  --validation-overall pass --validation-command "cargo test" \
  --validation-status pass --validation-evidence "$VALIDATION_LOG"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" --post state,session,validation \
  --repair-dashboard

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --review-decision approve

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" --post review --repair-dashboard

forge-cli pr deliver --repo "$OWNER_REPO" --pr "$PR_NUMBER" --format json

# Final state when validation/review are complete and PR is merged:
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --phase ready_for_close \
  --linked-pr "$OWNER_REPO#$PR_NUMBER"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" --post state --repair-dashboard

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --expect-visible
```

## Evidence requirements

- Every `tracking checkpoint` envelope shows `lint_pass: true` for posted
  roles and no `blocked` entries.
- `forge-cli pr deliver` returns a merged PR with required checks pass.
- `tracking close-ready` returns `ready: true` and no `blockers` before
  handoff.
- `events.jsonl` records `validation_recorded`, `review_recorded`, and
  `checkpoint_posted` events in order.

## Stop conditions

- `tracking status` reports `run-state-stale`, missing required evidence,
  or `RECORD_BLOCKED`.
- `tracking checkpoint` returns any `visible-completeness-failed` or
  `tracking-checkpoint-live-not-implemented` blocker — fix or fall back
  to `record post` for the affected role and resume.
- `forge-cli pr deliver` reports unmerged PRs or required-check failures.
- `tracking close-ready` returns `ready: false` — stop and surface the
  blockers; do not invoke `plan-tracking-issue-closeout`.

## Validation

- `tracking close-ready --expect-visible` reports `ready: true`.
- `tracking status` confirms `RECORD_READY_FOR_CLOSE` (or the appropriate
  state for the agreed handoff).
- `forge-cli pr deliver` evidence is captured in the run-state notes /
  validation evidence and in the lifecycle comments.

## Boundary

`plan-issue tracking` owns reconciliation, checkpoint rendering, and
close-readiness gate evaluation. `forge-cli` owns PR delivery. The skill
body owns scope judgment, validation strength, review interpretation,
and the decision to hand off to `plan-tracking-issue-closeout`.
