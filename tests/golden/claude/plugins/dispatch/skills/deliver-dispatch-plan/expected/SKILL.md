---
name: deliver-dispatch-plan
description:
  Deliver a dispatch-ready plan by creating one shared issue-backed plan record, dispatching task lanes, reviewing PRs, and closing through lifecycle gates.
---

# Deliver Dispatch Plan

## Purpose

Create or resume one shared dispatch plan issue, dispatch task lanes,
coordinate lane PRs and reviews, and hand off to dispatch closeout. The
skill keeps main-agent orchestration separate from lane implementation
and never closes the dispatch issue itself.

## When to use

- A validated plan bundle is ready for parallel lane execution and the
  user wants one shared dispatch tracker plus per-lane PRs.
- An existing dispatch issue needs to be resumed after a session break.

## Inputs

- `OWNER_REPO`, `PLAN_BUNDLE`, `PLAN`, optional `ISSUE` when resuming.
- Lane assignments (task / sprint / PR-group) — derived from the plan or
  passed explicitly.
- Dispatch labels from the shared taxonomy:
  `type::chore`, primary `area::*`, `state::needs-triage`,
  `workflow::plan`, `workflow::dispatch`.

## Preflight

- `plan-issue >=0.22.3`, `plan-tooling`, and `forge-cli` are on `PATH`.
- `plan-tooling validate --file "$PLAN"` is green.
- Bundle files exist at canonical paths and are committed.
- Lane assignments do not violate runtime layout invariants (one lane per
  PR group; per-sprint lanes share a sprint root).

## Allowed lifecycle roles

- `source`, `plan`, and initial `state` snapshots through `record open
  --profile dispatch` or `record attach --profile dispatch`.
- Dispatch-profile `state`, `session`, `validation`, and `review`
  checkpoints through `tracking checkpoint --profile dispatch`.
- Dashboard repair through `tracking checkpoint --repair-dashboard` or
  the lower-level `record repair-dashboard`.

## Forbidden actions

- No closeout. `dispatch-plan-closeout` owns `record close --profile
  dispatch`.
- No implementing lane tasks. Each lane belongs to
  `execute-dispatch-lane`.
- No reviewing lane PRs. `review-dispatch-lane-pr` owns review evidence.
- No PR merge. `forge-cli pr deliver` (called by the lane skills) owns
  PR lifecycle.
- No lightweight tracking closeout rules.
- No multiple shared plan issues for the same dispatch plan unless the
  user explicitly splits scope.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for lifecycle evidence.

## CLI flow

```bash
plan-tooling validate --file "$PLAN" --format text --explain

plan-issue --repo "$OWNER_REPO" --format json record open \
  --profile dispatch \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore --label area::docs \
  --label state::needs-triage --label workflow::plan --label workflow::dispatch

plan-issue --format json tracking run init \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --bundle "$PLAN_BUNDLE"

# For each lane: dispatch `execute-dispatch-lane` with the lane scope.
# After lane PR delivery and review evidence land, post the dispatch-level
# state/session checkpoint:
plan-issue --format json tracking checkpoint \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --post state,session --repair-dashboard

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" \
  --linked-pr "$LANE_PR_1" --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" --expect-visible
```

## Evidence requirements

- The dispatch dashboard names every assigned lane PR with its merge
  status.
- `tracking status --profile dispatch` reports `RECORD_OPEN_ACTIVE` or
  later before lane skills are dispatched.
- `tracking close-ready --profile dispatch` returns `ready: true` only
  after every lane PR has merged with required-check pass and review
  evidence is recorded.

## Stop conditions

- Lane PRs report unmerged or required-check failures.
- A lane's review evidence reports unresolved blocker findings.
- `tracking close-ready` blockers — surface, do not bypass.
- A lane skill returns a `forge-cli` failure that cannot be retried by
  the user.

## Validation

- `plan-tooling validate` green.
- `plan-issue record open --profile dispatch --dry-run` returns a stable
  preview.
- `tracking close-ready --profile dispatch` returns `ready: true` before
  handing off to `dispatch-plan-closeout`.

## Boundary

The main agent owns orchestration, integration, and the close-ready
decision. Subagents own lane implementation, review, and PR delivery.
`forge-cli` owns PR mechanics. `plan-issue tracking` owns reconciliation,
checkpoint rendering, and dashboard repair.
