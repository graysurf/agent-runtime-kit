---
name: tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue only after issue-backed execution state, approval, validation, linked PRs, and dashboard repair pass.
---

# Tracking Issue Closeout

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `plan-issue` and `plan-issue-local` are available for offline gate rehearsal
  or for routing detected heavyweight dispatch issues.
- The issue was created by `create-plan-tracking-issue` or carries equivalent
  lightweight snapshot/state markers.
- User approval or project-policy approval is captured as a concrete comment
  URL, explicit approval, or issue-visible policy before close.
- Linked PRs are merged unless the close policy explicitly records a
  documented exception.

Inputs:

- Issue number or URL, repository override, approval basis, and optional close
  reason/comment.
- Optional offline issue JSON/body artifact for dry-run readiness checks.
- Optional repair mode for already closed issues whose dashboard or closeout
  marker is stale.

Outputs:

- Final dashboard derived from issue comments.
- One append-only `<!-- tracking-issue-closeout:v1 -->` closeout comment.
- Closed provider issue in live mode through `forge-cli issue close`.
- In repair mode, body-only dashboard repair and optional single missing
  closeout marker; never duplicate existing closeout markers.

Failure modes:

- Source snapshot, plan snapshot, completed execution state, completed session,
  validation evidence, approval, or merged PR evidence is missing.
- The latest state ledger has unresolved rows other than explicit `deferred`.
- The issue is a heavyweight dispatch/`plan-issue` runtime; use
  `dispatch-issue-closeout`.
- Provider issue comment, body update, or close mutation fails.

## Entrypoint

Inspect the issue and recover lightweight markers:

```bash
forge-cli issue view "$ISSUE" --repo "$OWNER_REPO" --format json
```

Post closeout evidence and close after gates pass:

```bash
forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$CLOSEOUT_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$FINAL_DASHBOARD" --format json
forge-cli issue close "$ISSUE" --repo "$OWNER_REPO" --reason completed --format json
```

For a detected `Task Decomposition` dispatch issue, stop and use
`dispatch-issue-closeout` unless the user explicitly asked for an offline
`plan-issue close-plan --body-file` rehearsal.

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
2. Reject heavyweight dispatch issues and route to `dispatch-issue-closeout`.
3. Verify source snapshot, plan snapshot, latest execution state, completed
   session, validation evidence, approval basis, and linked PR merge state.
4. Repair stale dashboard links from current comments before close.
5. Render a compact final dashboard and one closeout comment with
   `tracking-issue-closeout:v1`.
6. In repair-closed mode, require the issue to already be closed; repair only
   the dashboard, and append a missing closeout marker only when explicitly
   finalizing a closed issue.
7. In normal live mode, post the closeout comment, update the dashboard, then
   close the issue through `forge-cli`.
8. Record issue URL, closeout comment URL, linked PRs, validation summary, and
   any accepted caveat.

## Boundary

`forge-cli` owns provider issue view/comment/edit/close calls. `plan-issue`
owns heavyweight dispatch close gates when this skill routes to
`dispatch-issue-closeout`. The skill body owns lightweight marker audit,
approval interpretation, closeout rendering, dashboard repair judgment, and
whether to stop for user review.
