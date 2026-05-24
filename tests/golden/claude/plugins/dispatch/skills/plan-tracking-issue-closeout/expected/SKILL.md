---
name: plan-tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue after lifecycle audit, validation, approval, PR evidence, and dashboard repair pass.
---

# Plan Tracking Issue Closeout

## Contract

Prereqs:

- `plan-issue >=0.20.0` is available on `PATH`; `gh` is useful for explicit
  preflight audit read-back.
- The issue was created by `create-plan-tracking-issue` or carries equivalent
  lightweight source/plan/state/session/validation comments.
- User approval, project-policy approval, or issue-visible approval evidence is
  available before live close.
- Linked PRs are merged unless the close policy records a documented exception.

Inputs:

- Issue number or URL, repository override, approval basis, linked PR refs,
  optional review evidence URL, and optional repair-only mode.
- Provider issue body and comments JSON when running a manual audit before
  close.

Outputs:

- A closeout comment, final dashboard repair, and provider issue close performed
  by `plan-issue record close`.
- In repair mode, dashboard repair through `record repair-dashboard` only.

Failure modes:

- Source snapshot, plan snapshot, complete state, validation, approval, linked
  PR evidence, or required review evidence is missing.
- The latest state payload has unresolved rows other than explicit `deferred`.
- The issue is a dispatch runtime; route to `dispatch-plan-closeout`.
- Provider audit, PR verification, dashboard repair, closeout comment, or close
  mutation fails inside `plan-issue record close`.

## Entrypoint

Optional read-back audit:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON"
```

Live closeout:

```bash
plan-issue --repo "$OWNER_REPO" --format json record close \
  --issue "$ISSUE" \
  --profile tracking \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --bundle "$PLAN_BUNDLE"
```

Repair-only dashboard refresh:

```bash
plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"
```

## Marker Contract

Required lightweight comments use `plan-issue-record:v2` with
`profile=tracking` for source, plan, state, validation, and any required review
evidence. `record close` owns the closeout comment and final dashboard repair.

The issue body is a mutable dashboard only. The latest valid state payload must
show completion with all task rows `done` or explicitly `deferred` before close.

## Workflow

1. Read issue body, labels, state, linked PRs, and comments.
2. Run `record audit --profile tracking`; reject dispatch issues and route to
   `dispatch-plan-closeout`.
3. Confirm approval evidence and linked PR refs are exact and issue-visible.
4. Run `record close --profile tracking` with approval, linked PRs, and bundle.
5. If close fails, leave the issue open and report the exact blocked code from
   the JSON result.
6. In repair-only mode, require the issue to already be closed or explicitly
   approved for repair, then run `record repair-dashboard` only.

## Boundary

`plan-issue record` owns marker audit, strict closeout evaluation, closeout
commenting, dashboard repair, linked PR provider verification, and provider
issue close. The skill body owns approval interpretation, repair-vs-live
judgment, dispatch-vs-tracking routing, and final evidence quality.
