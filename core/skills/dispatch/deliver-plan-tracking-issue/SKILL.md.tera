---
name: deliver-plan-tracking-issue
description:
  Deliver a lightweight issue-backed plan scope through implementation, review, PR delivery, lifecycle comments, and close readiness gates.
---

# Deliver Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, `forge-cli`, `review-evidence`, and
  `review-specialists` are available on `PATH`. Lifecycle record commands
  require `plan-issue >=0.17.4`; before release, prepend the scoped nils-cli
  debug binary directory to `PATH`.
- The target issue has recoverable plan/task state and linked source context.
- The target issue is a lightweight plan-tracking issue. If the issue contains
  dispatch profile comments, subagent lane records, or dispatch ledger state,
  route to `deliver-dispatch-plan` or `dispatch-plan-closeout`.
- The delivery branch contains only the intended issue scope.
- Invoking this workflow is authorization to carry the selected issue scope
  through PR review, merge, issue synchronization, and close readiness unless
  the user supplies a narrower stop condition.

Inputs:

- Issue number or URL, optional plan path, task/sprint selector, repository
  override, close policy, and validation commands.
- Review evidence, specialist review outcome, and explicit
  fixed/residual/follow-up/deferred/no-action disposition for every meaningful
  finding.

Outputs:

- A pushed branch and PR for the selected issue scope.
- Required checks and review evidence completed before merge.
- For every PR, a `code-review-specialists` pass with at least `testing` and
  `maintainability` forced by the shared delivery specialist review gate, even
  for small diffs.
- For every PR, a provider-side delivery review outcome comment URL recorded in
  issue-hosted session or validation evidence.
- Lightweight state/session/validation comments rendered through
  `plan-issue record` after execution, PR review, PR merge, and final
  completion.
- Closeout readiness evidence when the selected scope completes the issue.

Failure modes:

- Issue state is incomplete, stale, or ambiguous.
- The issue is actually a dispatch runtime; use the dispatch workflow family.
- Local or remote validation fails.
- Specialist review or review-evidence findings remain unresolved or lack an
  issue-visible disposition.
- `forge-cli` PR checks, ready, merge, comment, or close operations fail.
- `plan-issue record closeout-gate` rejects the current lifecycle evidence.

## Entrypoint

Start with issue audit and plan gates:

```bash
plan-issue record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --format json
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
  --no-merge
```

Record review evidence before merge:

```bash
review-specialists scope --base "$BASE_REF" --testing --maintainability --format json
review-evidence init --out "$REVIEW_OUT" --subject "PR #$PR_NUMBER"
review-evidence record-validation --out "$REVIEW_OUT" --command "$COMMAND" --status pass
review-evidence verify --out "$REVIEW_OUT" --format json
```

Render issue-visible state after delivery events:

```bash
plan-issue record render-comment --profile tracking --marker-family compat --kind validation \
  --content-file "$VALIDATION_MD" --out "$VALIDATION_COMMENT"
forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$VALIDATION_COMMENT" --format json
```

## Workflow

1. Resolve issue state, plan path, selected task/sprint, and close policy.
2. Run `plan-issue record audit --profile tracking` and `plan-tooling
   validate`. Stop on missing lifecycle comments, stale state, or plan errors.
3. Implement and validate the selected scope.
4. Create or deliver the PR with `forge-cli`, using `--no-merge` until checks
   and specialist review have both passed.
5. Run mandatory specialist review for every PR using:
   `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`.
   Always force `testing` and `maintainability`, add risk lenses when the PR
   scope warrants them, and do not skip only because the diff is small.
6. Classify and repair review findings. Concrete findings block merge until
   fixed in the selected issue scope or explicitly dispositioned. After repairs,
   rerun focused validation, provider checks, and affected specialist lenses.
7. Post the delivery review outcome comment before merge using:
   `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`.
8. Merge only after checks, specialist review, review evidence, lifecycle audit,
   and issue-backed completion gates pass.
9. Append state/session/validation comments with PR number, validation, review
   lenses, finding disposition, and task ledger status. Use `Refs #<issue>` in
   PR bodies so closeout owns issue closure.
10. Before merge or final success, verify the latest lightweight state is
    closeout-ready: status `complete`, all task rows `done` or `deferred`,
    validation/PR evidence present, and dashboard links current.
11. Close through `plan-tracking-issue-closeout` after completion approval. If
    the issue is a dispatch runtime, use `dispatch-plan-closeout` instead.
12. Leave the issue open with an exact unblock action if any gate fails.

## Boundary

`plan-issue record` owns lifecycle rendering, audit, and closeout-gate
evidence. `forge-cli` owns PR provider lifecycle. `review-evidence` owns
retained review records. `code-review-specialists` supplies read-only
specialist review. This workflow owns lightweight issue execution, review
judgment, repair decisions, issue-visible finding dispositions, delivery
outcome comment URLs, and final status reporting.
