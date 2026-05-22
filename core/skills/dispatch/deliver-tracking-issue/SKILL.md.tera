---
name: deliver-tracking-issue
description:
  Deliver an issue-backed plan scope through validation, review, PR delivery, issue synchronization, and close readiness gates.
---

# Deliver Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, `forge-cli`, `review-evidence`, and
  `review-specialists` are installed from released nils-cli packages and
  available on `PATH`.
- The target issue has recoverable plan/task state and linked source context.
- The target issue is a lightweight plan-tracking issue. If the issue contains
  `Task Decomposition` rows, subagent owners, or `deliver-dispatch-plan:*`
  markers, route to `deliver-dispatch-plan` or `dispatch-issue-closeout`.
- The delivery branch contains only the intended issue scope.
- Invoking this workflow is authorization to carry the selected issue scope
  through PR review, merge, issue synchronization, and close readiness unless the
  user supplies a narrower stop condition.

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
- Issue task rows or issue-backed state updated with PR, validation, and next
  task status.
- Closeout readiness evidence when the selected scope completes the issue.
- For lightweight issues, issue-hosted `execute-from-tracking-issue:state:v1`,
  `session:v1`, and `validation:v1` comments updated after execution, PR
  review, PR merge, and final completion.

Failure modes:

- Issue state is incomplete, stale, or ambiguous.
- The issue is actually a heavyweight dispatch runtime; use the dispatch
  workflow family instead.
- Local or remote validation fails.
- Specialist review or review-evidence findings remain unresolved or lack an
  issue-visible disposition.
- `forge-cli` PR checks, ready, merge, or close operations fail.
- `plan-issue` close or accept gates reject the current task state.

## Entrypoint

Start with the issue and plan gates:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-issue status-plan --issue "$ISSUE" --repo "$OWNER_REPO" --format json
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

Synchronize the issue row:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

## Workflow

1. Resolve issue state, plan path, selected task/sprint, and close policy.
2. Validate the plan and current issue status.
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
8. Merge only after checks, specialist review, review evidence, and issue-backed
   completion gates pass.
9. For lightweight issues, append or update the issue-hosted state/session/
   validation evidence with PR number, validation, review lenses, finding
   disposition, and task ledger status. Use `Refs #<issue>` in PR bodies so
   closeout owns the issue closure.
10. Before merge or final success, verify the latest lightweight state is
    closeout-ready: status `complete`, all task rows `done` or `deferred`,
    validation/PR evidence present, and dashboard links current.
11. Close through `tracking-issue-closeout` after completion approval. If the
    issue is a dispatch runtime, use `dispatch-issue-closeout` instead.
12. Leave the issue open with an exact unblock action if any gate fails.

## Boundary

`plan-issue` owns issue task state only when routing to dispatch gates.
`forge-cli` owns PR provider lifecycle. `review-evidence` owns retained review
records. `code-review-specialists` supplies read-only specialist review; this
workflow owns lightweight issue execution, review judgment, repair decisions,
issue-visible finding dispositions, delivery outcome comment URLs, and final
status reporting.
