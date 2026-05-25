---
name: dispatch-plan-closeout
description:
  Close out a shared dispatch plan record after lane PRs, review, validation, approval, and lifecycle gates pass.
---

# Dispatch Plan Closeout

## Purpose

Close one shared dispatch plan issue after every lane PR, review,
validation, integration evidence, and approval gate passes. The skill
runs `tracking close-ready --profile dispatch` for the audit, then
`record close --profile dispatch` to post the canonical dispatch
`closeout` comment and close the issue.

## When to use

- `deliver-dispatch-plan` has handed off with all lane PRs merged and
  review evidence recorded.
- The shared dispatch issue needs the final dispatch-profile closeout
  comment plus the final dashboard.

## Inputs

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`.
- Linked PR references for every dispatch lane.
- Approval evidence (comment URL or non-empty approval text).

## Preflight

- `plan-issue >=0.22.3` is on `PATH`.
- `tracking close-ready --profile dispatch` returns `ready: true` and
  `blockers: []`.
- Every lane PR is merged with required-check pass, and `tracking
  status` reflects that fact.

## Allowed lifecycle roles

- Dispatch dashboard repair through `record repair-dashboard` when the
  pre-closeout dashboard is stale.
- `record close --profile dispatch` to post the final dispatch
  `closeout` comment and close the issue.

## Forbidden actions

- No lane implementation.
- No PR creation, update, or merge.
- No `record post` for `state`, `session`, `validation`, or `review`
  during the closeout window.
- No `tracking checkpoint` for the closeout role (forbidden by the
  controller itself).
- No lightweight tracking closeout rules — dispatch closeout requires
  lane, review, validation, and integration evidence in addition to the
  lightweight gates.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for the closeout body.

## CLI flow

```bash
plan-issue --format json tracking close-ready \
  --profile dispatch \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$LANE_PR_1" --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" --expect-visible

# Optional repair when the dashboard is stale:
plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

plan-issue --repo "$OWNER_REPO" --format json record close \
  --profile dispatch \
  --issue "$ISSUE" \
  --linked-pr "$LANE_PR_1" --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL"
```

## Evidence requirements

- `tracking close-ready --profile dispatch` returns `ready: true` with
  `visible_completeness.pass: true`.
- `record close --profile dispatch` returns the dispatch closeout URL
  and a refreshed final dashboard.
- A final audit recognizes the dispatch `closeout` marker and reports
  no visible-completeness findings.

## Stop conditions

- Any lane PR is unmerged or has required-check failures.
- Any lane review reports unresolved blocker findings.
- `tracking close-ready` reports any blocker.
- `record close` strict gate fails on missing required checks, missing
  merge SHA, or unrecognized PR refs.

## Validation

- `tracking close-ready --profile dispatch --expect-visible` returns
  `ready: true`.
- `record close --profile dispatch` exits 0 with `closeout_url` and
  final dashboard.
- Final audit recognizes the `closeout` role with empty `visible.codes`.

## Boundary

`plan-issue tracking close-ready` owns the non-mutating dispatch gate.
`record close --profile dispatch` owns the closeout post and provider
issue closing. The skill body owns approval interpretation, lane
integration verification, and the final read-back integrity check.
