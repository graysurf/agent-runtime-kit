---
name: execute-plan-tracking-issue
description:
  Resume lightweight issue-backed plan execution from lifecycle comments and keep the dashboard current.
---

# Execute Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, and `forge-cli` are available on `PATH`.
  The lifecycle record commands require
  `plan-issue >=0.17.4`; before release, prepend the scoped nils-cli debug
  binary directory to `PATH`.
- The issue has source/plan snapshots and lifecycle comments, or enough
  issue-visible state to reconstruct them before edits.
- Repository preflight and dirty-tree triage have passed.

Inputs:

- Issue number or URL, repository override, plan path, selected task/sprint,
  branch name, validation scope, and PR policy.
- Selected PR labels: one `type::`, one primary `area::`, one `size::`, and
  `workflow::tracking` for tracking-issue implementation work.
- Latest state/session/validation comments, plus dashboard body and comments
  fetched from the provider.
- Issue contract classification: lightweight tracking issue or dispatch issue.

Outputs:

- A scoped implementation branch and PR for the selected issue-backed task.
- Updated append-only state/session/validation comments rendered through
  `plan-issue record`.
- A refreshed dashboard that links the latest durable comments, validation,
  and PR evidence.

Failure modes:

- The issue lacks recoverable source, plan, state, or task ledger evidence.
- The issue is actually a dispatch runtime; route to `deliver-dispatch-plan`,
  `execute-dispatch-lane`, or `dispatch-plan-closeout`.
- The selected task is ambiguous, validation fails, provider PR operations fail,
  or dashboard audit cannot recognize the lifecycle markers.

## Entrypoint

Fetch and audit issue state before edits:

```bash
forge-cli issue view "$ISSUE" --repo "$OWNER_REPO" --format json >"$ISSUE_JSON"

plan-issue record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --format json
```

Validate the plan and create the PR through provider tooling:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
forge-cli pr create \
  --provider github \
  --repo "$OWNER_REPO" \
  --kind feature \
  --base "$BASE_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY" \
  --label type::feature \
  --label area::runtime \
  --label size::m \
  --label workflow::tracking \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels \
  --format json
```

Render the execution comments and dashboard:

```bash
plan-issue record render-comment --profile tracking --kind state \
  --content-file "$STATE_MD" --out "$STATE_COMMENT"
plan-issue record render-comment --profile tracking --kind session \
  --content-file "$SESSION_MD" --out "$SESSION_COMMENT"
plan-issue record render-comment --profile tracking --kind validation \
  --content-file "$VALIDATION_MD" --out "$VALIDATION_COMMENT"
plan-issue record render-dashboard --profile tracking \
  --state-url "$STATE_URL" \
  --session-url "$SESSION_URL" \
  --validation-url "$VALIDATION_URL" \
  --linked-pr "#$PR_NUMBER" \
  --out "$UPDATED_DASHBOARD"
```

## Issue Contract Selection

- Lightweight tracking issues use the compatibility marker family:
  - `<!-- plan-issue-record:v2 role=source profile=tracking -->`
  - `<!-- plan-issue-record:v2 role=plan profile=tracking -->`
  - `<!-- plan-issue-record:v2 role=state profile=tracking -->`
  - `<!-- plan-issue-record:v2 role=session profile=tracking -->`
  - `<!-- plan-issue-record:v2 role=validation profile=tracking -->`
- The mutable issue body is only a dashboard. The latest valid state comment is
  the durable task ledger and should keep the canonical columns
  `ID | Status | Task | Evidence | Notes`.
- Dispatch issues use the dispatch profile and a dispatch ledger/state
  comments. Do not rewrite a tracking issue into dispatch in place.

## Workflow

1. Read issue body, comments, labels, linked PRs, and latest local plan state.
2. Run `plan-issue record audit --profile tracking`; stop if required markers
   are missing or the issue is classified as dispatch.
3. Validate the plan with `plan-tooling`.
4. Update the issue-backed state markdown before code edits so the selected
   task, current status, and next action are visible.
5. Implement only the selected task scope and run validation.
6. Select labels before PR mutation. Every tracking implementation PR needs
   `type::`, one primary `area::`, `size::`, and `workflow::tracking`; use
   `state::do-not-merge` when the PR must not merge.
7. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json`
   before the first live PR in that repo. Use `label audit` when mutation is
   not allowed.
8. Create or update the PR through `forge-cli`.
9. Post state, session, and validation comments rendered by
   `plan-issue record render-comment`.
10. Re-render and edit the dashboard with latest comment URLs, validation
   summary, PR references, blockers, and next action.
11. Before merge, closeout, or final success reporting, run
   `plan-issue record audit` again and verify the latest state is complete or
   explicitly leaves follow-up/deferred rows.

## Boundary

`plan-tooling` owns plan parsing and validation. `plan-issue record` owns
dashboard/comment rendering, marker audit, and local closeout gate evidence.
`forge-cli` owns provider issue and PR mutation. The skill body owns scope
selection, implementation judgment, validation interpretation, and whether a
gate is strong enough to continue.
