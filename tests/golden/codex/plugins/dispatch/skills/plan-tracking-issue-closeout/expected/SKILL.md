---
name: plan-tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue after lifecycle audit, validation, approval, PR evidence, and dashboard repair pass.
---

# Plan Tracking Issue Closeout

## Purpose

Close one lightweight plan-tracking issue after the strict closeout gates
pass. The skill calls `plan-issue tracking close-ready` for the audit,
then `plan-issue record close` to post the canonical `closeout` comment
and close the provider issue. It never implements tasks or posts progress
checkpoints.

## When to use

- `deliver-plan-tracking-issue` reported `tracking close-ready ready:
  true` and handed off to closeout.
- A previously-stuck issue needs explicit closeout after the run-state
  and provider evidence have been reconciled.

## Inputs

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`.
- Linked PR references (`OWNER_REPO#NUMBER`) — at least one required
  unless the user explicitly provides a no-PR waiver.
- Approval evidence (comment URL or non-empty approval text).
- Optional dashboard repair flag if the latest dashboard is out of sync
  before closeout.

## Preflight

- `plan-issue >=0.22.3` is on `PATH`.
- `tracking close-ready` returns `ready: true` with no `blockers`.
- The dashboard is current — if not, run `record repair-dashboard` first
  and confirm the rendered dashboard matches the latest evidence.

## Allowed lifecycle roles

- `record repair-dashboard` for an explicit pre-closeout dashboard fix.
- `record close --profile tracking` to post the final `closeout` comment
  and close the provider issue.

## Forbidden actions

- No task implementation.
- No `record post` for `state`, `session`, `validation`, or `review`
  during the closeout window.
- No `tracking checkpoint` (the controller's checkpoint surface refuses
  closeout posts; this is a belt-and-suspenders rule).
- No `record close` when `tracking close-ready` reports any blocker.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for the closeout body.
- No bypass of approval, linked-PR, or visible-completeness evidence
  required by the strict gate.

## CLI flow

```bash
plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$LINKED_PR" \
  --approval "$APPROVAL" \
  --expect-visible

# Optional repair when the dashboard is stale:
plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

plan-issue --repo "$OWNER_REPO" --format json record close \
  --profile tracking \
  --issue "$ISSUE" \
  --linked-pr "$LINKED_PR" \
  --approval "$APPROVAL"
```

## Evidence requirements

- `tracking close-ready` returns `ready: true`, `blockers: []`, and
  `visible_completeness.pass: true`.
- `record close` returns the `closeout_url`, `final_dashboard`, and the
  closed issue state.
- A final read-back audit recognizes the `closeout` marker:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,state,comments \
  >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON" \
  --expect-visible
```

## Stop conditions

- `tracking close-ready` reports any blocker — do not call `record close`.
- `record close` fails the strict gate (missing required checks, no merge
  SHA, blocked findings) — surface the blocker and stop.
- The final audit shows `visible-completeness-failed` for the closeout
  body — open an investigation; do not retry blindly.

## Validation

- `tracking close-ready --expect-visible` returns `ready: true`.
- `record close --profile tracking` exits 0 and returns a `closeout_url`.
- Final audit recognizes the `closeout` role with `visible.codes` empty.

## Boundary

`plan-issue tracking close-ready` owns the non-mutating gate. `plan-issue
record close` owns the closeout post and provider issue closing. The
skill body owns approval interpretation, dashboard-repair decisions, and
the final read-back integrity check.
