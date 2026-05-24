---
name: deliver-plan-tracking-issue
description:
  Deliver a lightweight issue-backed plan scope through implementation, review, PR delivery, lifecycle comments, and close readiness gates.
---

# Deliver Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue >=0.20.0`, `forge-cli`,
  `review-evidence`, and `review-specialists` are available on `PATH`.
- The target issue has recoverable plan/task state and linked source context.
- The target issue is a lightweight plan-tracking issue. If it contains
  dispatch-profile comments or dispatch lane records, route to the dispatch
  workflow family.
- The delivery branch contains only the intended issue scope.
- Invoking this workflow authorizes carrying the selected issue scope through
  PR review, merge, issue synchronization, and close readiness unless the user
  supplies a narrower stop condition.

Inputs:

- Issue number or URL, optional plan bundle/path, task selector, repository
  override, close policy, validation commands, and linked PR refs.
- Selected PR labels: one `type::`, one primary `area::`, one `size::`, and
  `workflow::tracking` for tracking-issue delivery.
- State/session/validation/review payload JSON and visible summaries.
- Review evidence, specialist review outcome, and explicit disposition for
  every meaningful finding.

Outputs:

- A pushed branch and PR for the selected issue scope.
- Required checks and review evidence completed before merge.
- At least `testing` and `maintainability` specialist lenses for every PR.
- Issue-visible state, session, validation, and review comments posted through
  `plan-issue record post`.
- When closeout runs, `plan-issue record close` posts closeout evidence,
  repairs the dashboard, verifies linked PRs, and closes the provider issue.

Failure modes:

- Issue state is incomplete, stale, or ambiguous.
- The issue is actually a dispatch runtime.
- Local or remote validation fails.
- Specialist review or review-evidence findings remain unresolved or lack an
  issue-visible disposition.
- `forge-cli` PR checks, ready, merge, or comment operations fail.
- `plan-issue record close` rejects the current lifecycle evidence.

## Entrypoint

Start with issue audit and plan gates:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON"
plan-tooling validate --file "$PLAN" --format text --explain
```

Open or deliver the PR through `forge-cli`:

```bash
forge-cli pr deliver \
  --provider github \
  --repo "$OWNER_REPO" \
  --kind feature \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY" \
  --base main \
  --method squash \
  --label type::feature \
  --label area::runtime \
  --label size::m \
  --label workflow::tracking \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels \
  --no-merge
```

Record review evidence before merge:

```bash
review-specialists scope --base "$BASE_REF" --testing --maintainability --format json
review-evidence init --out "$REVIEW_OUT" --subject "PR #$PR_NUMBER"
review-evidence record-validation --out "$REVIEW_OUT" --command "$COMMAND" --status pass
review-evidence verify --out "$REVIEW_OUT" --format json
```

Post issue-visible lifecycle updates:

```bash
plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile tracking \
  --kind validation \
  --payload-file "$VALIDATION_PAYLOAD" \
  --summary-file "$VALIDATION_MD"

plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"
```

Run chained closeout inline unless `--no-closeout` was supplied:

```bash
plan-issue --repo "$OWNER_REPO" --format json record close \
  --issue "$ISSUE" \
  --profile tracking \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --bundle "$PLAN_BUNDLE"
```

## Workflow

1. Resolve issue state, plan bundle/path, selected task, and close policy.
2. Run `record audit --profile tracking` and `plan-tooling validate`; stop on
   missing lifecycle comments, stale state, or plan errors.
3. Implement and validate the selected scope.
4. Select labels before provider mutation. Every tracking delivery PR needs
   `type::`, one primary `area::`, `size::`, and `workflow::tracking`; use
   `state::do-not-merge` when the PR must not merge.
5. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json`
   before the first live PR in that repo. Use `label audit` when mutation is
   not allowed.
6. Create or deliver the PR with `forge-cli`, using `--no-merge` until checks
   and specialist review have passed.
7. Run mandatory specialist review for every PR using:
   `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`.
8. Classify and repair review findings. Concrete findings block merge until
   fixed or explicitly dispositioned in issue-visible evidence.
9. Post the delivery review outcome comment before merge using:
   `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`.
10. Merge only after checks, specialist review, review evidence, lifecycle audit,
   and issue-backed completion gates pass.
11. Append state, session, validation, and review comments through
   `record post`; include PR labels in the visible summary and repair the
   dashboard after each meaningful lifecycle event.
12. Before merge or final success, verify the latest tracking state is
    closeout-ready: status `complete`, all task rows `done` or `deferred`,
    validation/review/PR evidence present, and dashboard links current.
13. After completion approval, run `record close` unless `--no-closeout` was
    supplied. Stop on any blocked code and leave the issue open with the exact
    unblock action surfaced by `plan-issue`.
14. Leave the issue open with an exact unblock action if any gate fails or if
    `--no-closeout` was supplied.

## Boundary

`plan-issue record` owns lifecycle comments, dashboard repair, audit, strict
closeout, linked PR provider verification, and issue close. `forge-cli` owns PR
provider lifecycle. `review-evidence` owns retained review records.
`code-review-specialists` supplies read-only specialist review. This workflow
owns lightweight issue execution, review judgment, repair decisions,
issue-visible finding dispositions, delivery outcome comment URLs, and final
status reporting.
