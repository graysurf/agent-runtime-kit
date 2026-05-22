---
name: plan-tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue after lifecycle audit, validation, approval, PR evidence, and dashboard repair pass.
---

# Plan Tracking Issue Closeout

## Contract

Prereqs:

- `forge-cli` and `plan-issue` are available on `PATH`. The lifecycle record
  commands require `plan-issue >=0.17.4`; before release, prepend the scoped
  nils-cli debug binary directory to `PATH`.
- The issue was created by `create-plan-tracking-issue` or carries equivalent
  lightweight source/plan/state/session/validation comments.
- User approval, project-policy approval, or issue-visible approval evidence is
  available before live close.
- Linked PRs are merged unless the close policy records a documented exception.

Inputs:

- Issue number or URL, repository override, approval basis, linked PR refs,
  optional review evidence URL, and optional close reason/comment.
- Provider issue body and comments JSON for audit and closeout-gate checks.
- Optional repair-only mode for already closed issues.

Outputs:

- One append-only closeout comment rendered by `plan-issue record`.
- A final dashboard with latest durable-record links and closeout URL.
- Closed provider issue in live mode through `forge-cli issue close`.
- In repair mode, dashboard repair only unless a missing closeout marker is
  explicitly required.

Failure modes:

- Source snapshot, plan snapshot, complete state, session, validation, approval,
  linked PR evidence, or required review evidence is missing.
- The latest state ledger has unresolved rows other than explicit `deferred`.
- The issue is a dispatch runtime; route to `dispatch-plan-closeout`.
- Provider comment, edit, or close mutation fails.

## Entrypoint

Audit and gate the issue:

```bash
forge-cli issue view "$ISSUE" --repo "$OWNER_REPO" --format json >"$ISSUE_JSON"

plan-issue record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --format json

plan-issue record closeout-gate \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --require-complete \
  --require-session \
  --require-validation \
  --approval "$APPROVAL" \
  --linked-pr "#$PR_NUMBER" \
  --format json
```

Render closeout and close:

```bash
plan-issue record render-comment \
  --profile tracking \
  --marker-family compat \
  --kind closeout \
  --content-file "$CLOSEOUT_MD" \
  --out "$CLOSEOUT_COMMENT"

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$CLOSEOUT_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$FINAL_DASHBOARD" --format json
forge-cli issue close "$ISSUE" --repo "$OWNER_REPO" --reason completed --format json
```

## Marker Contract

Required lightweight comments:

- `<!-- plan-tracking-issue:snapshot:v1 kind=source -->`
- `<!-- plan-tracking-issue:snapshot:v1 kind=plan -->`
- `<!-- execute-from-tracking-issue:state:v1 -->`
- `<!-- execute-from-tracking-issue:session:v1 -->`
- `<!-- execute-from-tracking-issue:validation:v1 -->`

Closeout comment marker:

- `<!-- tracking-issue-closeout:v1 -->`

The issue body is a mutable dashboard only. The latest valid state comment is
the durable task ledger and must contain rows that are all `done` or
explicitly `deferred` before close.

## Workflow

1. Read issue body, labels, state, linked PRs, and comments.
2. Run `plan-issue record audit --profile tracking`; reject dispatch issues and
   route to `dispatch-plan-closeout`.
3. Run `plan-issue record closeout-gate` with explicit approval and linked PR
   refs. Add `--require-review` when the delivery path required specialist or
   review evidence.
4. Verify linked PR merge state through `forge-cli pr view` or provider checks.
5. Render one closeout comment with `plan-issue record render-comment`.
6. Re-render the final dashboard from the latest source, plan, state, session,
   validation, review, and closeout URLs.
7. In repair-only mode, require the issue to already be closed and avoid
   duplicate closeout comments.
8. In live mode, post the closeout comment, edit the dashboard, then close the
   issue through `forge-cli`.

## Boundary

`plan-issue record` owns marker audit, closeout-gate evaluation, and
dashboard/comment rendering. `forge-cli` owns provider issue view/comment/edit
and close calls. The skill body owns approval interpretation, linked PR merge
verification, repair-vs-live judgment, and final evidence quality.
