---
name: execute-plan-tracking-issue
description:
  Resume lightweight issue-backed plan execution from lifecycle comments and keep the dashboard current.
---

# Execute Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue >=0.20.0`, and `forge-cli` are available on
  `PATH`.
- The issue has source, plan, and state lifecycle comments, or enough
  issue-visible state to reconstruct them before edits.
- Repository preflight and dirty-tree triage have passed.

Inputs:

- Issue number or URL, repository override, plan path, selected task/sprint,
  branch name, validation scope, and PR policy.
- Selected PR labels: one `type::`, one primary `area::`, one `size::`, and
  `workflow::tracking` for tracking-issue implementation work.
- State/session/validation payload JSON plus optional visible Markdown
  summaries.
- Issue contract classification: lightweight tracking issue or dispatch issue.

Outputs:

- A scoped implementation branch and PR for the selected issue-backed task.
- Updated append-only state, session, and validation comments posted through
  `plan-issue record post`.
- A refreshed dashboard from `plan-issue record repair-dashboard`.

Failure modes:

- The issue lacks recoverable source, plan, state, or task evidence.
- The issue is actually a dispatch runtime; route to the dispatch workflow
  family.
- The selected task is ambiguous, validation fails, provider PR operations fail,
  or dashboard repair/audit cannot recognize lifecycle evidence.

## Entrypoint

Fetch and audit issue state before edits:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON"
```

Validate the plan and create or update the PR through provider tooling:

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

Post lifecycle comments and repair the dashboard:

```bash
plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile tracking \
  --kind state \
  --payload-file "$STATE_PAYLOAD" \
  --summary-file "$STATE_MD"

plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile tracking \
  --kind session \
  --payload-file "$SESSION_PAYLOAD" \
  --summary-file "$SESSION_MD"

plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile tracking \
  --kind validation \
  --payload-file "$VALIDATION_PAYLOAD" \
  --summary-file "$VALIDATION_MD"

plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"
```

## Issue Contract Selection

- Lightweight tracking issues use `plan-issue-record:v2` markers with
  `profile=tracking`.
- The mutable issue body is only a dashboard. The latest valid state comment is
  the durable task ledger and should keep the canonical state payload complete.
- Dispatch issues use `profile=dispatch`; do not rewrite a tracking issue into
  dispatch in place.

## Workflow

1. Read issue body, comments, labels, linked PRs, and latest local plan state.
2. Run `record audit --profile tracking`; stop if required markers are missing
   or the issue is classified as dispatch.
3. Validate the plan with `plan-tooling`.
4. Update the issue-backed state payload before code edits so the selected task,
   current status, and next action are visible.
5. Implement only the selected task scope and run validation.
6. Select labels before PR mutation. Every tracking implementation PR needs
   `type::`, one primary `area::`, `size::`, and `workflow::tracking`; use
   `state::do-not-merge` when the PR must not merge.
7. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json`
   before the first live PR in that repo. Use `label audit` when mutation is
   not allowed.
8. Create or update the PR through `forge-cli`.
9. Post state, session, and validation comments through `record post`.
10. Repair the dashboard through `record repair-dashboard`.
11. Before merge, closeout, or final success reporting, run `record audit` again
   and verify the latest state is complete or explicitly leaves
   follow-up/deferred rows.

## Boundary

`plan-tooling` owns plan parsing and validation. `plan-issue record` owns
lifecycle comments, dashboard repair, marker audit, and record closeout.
`forge-cli` owns PR mutation. The skill body owns scope selection,
implementation judgment, validation interpretation, and whether a gate is strong
enough to continue.
