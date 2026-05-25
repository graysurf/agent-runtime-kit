---
name: deliver-plan-tracking-issue
description:
  Deliver a lightweight issue-backed plan scope through implementation, review, PR delivery, lifecycle comments, and close readiness gates.
---

# Deliver Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue >=0.22.3`, `forge-cli`,
  `review-evidence`, and `review-specialists` are available on `PATH`. The
  `code-review-pre-merge-gate` workflow uses `review-specialists`.
  `plan-issue >=0.22.3` is required for state `--execution-state-file`,
  Task Ledger display modes, and visible validation/review/closeout evidence
  rendering.
- The target issue has recoverable plan/task state and linked source context.
- The target issue is a lightweight plan-tracking issue. If it contains
  dispatch-profile comments or dispatch lane records, route to the dispatch
  workflow family.
- The delivery branch contains only the intended issue scope.
- When a plan bundle path is supplied, all three bundle files
  (`<slug>-discussion-source.md` or `<slug>-review-source.md`,
  `<slug>-plan.md`, `<slug>-execution-state.md`) exist on disk at the
  canonical paths. `plan-tooling validate` does not require the referenced
  execution-state file to be physically present, so the skill body verifies
  file existence before lifecycle posts or `record close` runs.
- Invoking this workflow authorizes carrying the selected issue scope through
  PR review, merge, issue synchronization, and close readiness unless the user
  supplies a narrower stop condition.

Inputs:

- Issue number or URL, optional plan bundle/path, task selector, repository
  override, close policy, validation commands, and linked PR refs.
- Selected PR labels: one `type::`, one primary `area::`, one `size::`, and
  `workflow::tracking` for tracking-issue delivery.
- State/session/validation/review payload JSON and visible evidence. State
  posts use the canonical execution-state markdown through
  `--execution-state-file`; validation, review, session, and closeout comments
  must render role-specific visible evidence and must not be left as
  Profile-only comments with only hidden payload.
- Review evidence, pre-merge review gate outcome, and explicit disposition for
  every meaningful finding.

Outputs:

- A pushed branch and PR for the selected issue scope.
- Required checks and review evidence completed before merge.
- A `code-review-pre-merge-gate` result with at least `testing` and
  `maintainability` for every PR.
- Issue-visible state, session, validation, and review comments posted through
  `plan-issue record post`. Non-final state comments keep the Task Ledger
  folded; the final state comment shows the full Task Ledger expanded before
  closeout.
- A real `role=session` lifecycle comment is required before merge and final
  success. A `## Session Log` section embedded in a state comment is useful
  context, but it is not session evidence for closeout readiness.
- When closeout runs, `plan-issue record close` posts closeout evidence,
  repairs the dashboard, verifies linked PRs, and closes the provider issue.

Failure modes:

- Issue state is incomplete, stale, or ambiguous.
- The issue is actually a dispatch runtime.
- Local or remote validation fails.
- Pre-merge review gate or review-evidence findings remain unresolved or lack
  an issue-visible disposition.
- Latest session evidence is missing, or the dashboard still reports
  `Latest session: pending` when closeout readiness is being claimed.
- Any lifecycle comment read-back shows only the marker/header/Profile line
  plus hidden payload, without visible state, validation, review, or closeout
  evidence.
- `forge-cli` PR checks, ready, merge, or comment operations fail.
- `plan-issue record close` rejects the current lifecycle evidence.

## Entrypoint

When a plan bundle path is supplied, verify the three bundle files exist on
disk before running any provider call. The plan and execution-state files are
mandatory; at least one source file
(`<slug>-discussion-source.md` or `<slug>-review-source.md`) must be present.

```bash
test -f "$PLAN_BUNDLE/$SLUG-plan.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-plan.md" >&2; exit 1; }
test -f "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  || {
    echo "missing $PLAN_BUNDLE/$SLUG-execution-state.md" >&2
    echo "backfill it before record close" >&2
    exit 1
  }
test -f "$PLAN_BUNDLE/$SLUG-discussion-source.md" \
  || test -f "$PLAN_BUNDLE/$SLUG-review-source.md" \
  || {
    echo "missing discussion-source or review-source file" >&2
    exit 1
  }
```

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

Run `code-review-pre-merge-gate` and record review evidence before merge. Its
minimum underlying scope is:

```bash
review-specialists scope \
  --base "$BASE_REF" \
  --testing \
  --maintainability \
  --format json
review-evidence init --out "$REVIEW_OUT" --subject "PR #$PR_NUMBER"
review-evidence record-validation \
  --out "$REVIEW_OUT" \
  --command "$COMMAND" \
  --status pass
review-evidence verify --out "$REVIEW_OUT" --format json
```

Post issue-visible lifecycle updates:

```bash
plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile tracking \
  --kind state \
  --payload-file "$STATE_PAYLOAD" \
  --execution-state-file "$EXECUTION_STATE" \
  --task-ledger-display collapsed

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

plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile tracking \
  --kind review \
  --payload-file "$REVIEW_PAYLOAD" \
  --summary-file "$REVIEW_MD"

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
  --bundle "$PLAN_BUNDLE" \
  --add-label state::closed \
  --remove-label state::needs-triage
```

## Workflow

1. Resolve issue state, plan bundle/path, selected task, and close policy.
2. If a bundle path is supplied, confirm all three bundle files exist on
   disk at the canonical paths (`<slug>-discussion-source.md` or
   `<slug>-review-source.md`, `<slug>-plan.md`,
   `<slug>-execution-state.md`); stop and request backfill if any file is
   missing. The execution-state file is the one `plan-tooling validate`
   does not enforce existence of, and missing it produces no immediate
   error but leaves later closeout / audit reads inconsistent with the
   bundle on disk.
3. Run `record audit --profile tracking` and `plan-tooling validate`; stop on
   missing lifecycle comments, stale state, or plan errors.
4. Implement and validate the selected scope.
5. Select labels before provider mutation. Every tracking delivery PR needs
   `type::`, one primary `area::`, `size::`, and `workflow::tracking`; use
   `state::do-not-merge` when the PR must not merge.
6. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json`
   before the first live PR in that repo. Use `label audit` when mutation is
   not allowed.
7. Create or deliver the PR with `forge-cli`, using `--no-merge` until checks
   and the pre-merge review gate have passed.
8. Run `code-review-pre-merge-gate` for every PR using:
   `skills/code-review/code-review-pre-merge-gate/SKILL.md`.
9. Classify and repair review findings. Concrete findings block merge until
   fixed or explicitly dispositioned in issue-visible evidence.
10. Post the delivery review outcome body produced by
    `code-review-pre-merge-gate` before merge.
11. Merge only after checks, the pre-merge review gate, review evidence,
    lifecycle audit, a latest `role=session` comment, and issue-backed
    completion gates pass.
12. Append state, session, validation, and review comments through
    `record post`; include PR labels in the visible evidence and repair the
    dashboard after each meaningful lifecycle event. State comments must use
    `--execution-state-file "$EXECUTION_STATE"` instead of a short
    `--summary-file`; use `--task-ledger-display collapsed` for progress
    updates and `--task-ledger-display expanded` for the final pre-closeout
    state.
13. Before merge or final success, verify the latest tracking state is
    closeout-ready: status `complete`, all task rows `done` or `deferred`,
    validation/review/PR evidence present, a latest `role=session` lifecycle
    comment present, dashboard links current with no `Latest session: pending`,
    and the final state comment visibly contains an expanded `## Task Ledger`
    with no `<details>` wrapper hiding the rows.
14. After completion approval, run `record close` unless `--no-closeout` was
    supplied. Stop on any blocked code and leave the issue open with the exact
    unblock action surfaced by `plan-issue`.
15. Read back the validation, review, and closeout lifecycle comments. Treat
    any Profile-only comment as a failed delivery even if `record audit`
    recognizes the hidden payload. The closeout comment must visibly include
    final status, approval, linked PRs, merge SHA/check status, any
    non-required-check override, and notes when present.
16. Leave the issue open with an exact unblock action if any gate fails or if
    `--no-closeout` was supplied.

## Boundary

`plan-issue record` owns lifecycle comments, dashboard repair, audit, strict
closeout, linked PR provider verification, and issue close. `forge-cli` owns PR
provider lifecycle. `review-evidence` owns retained review records.
`code-review-pre-merge-gate` supplies the read-only pre-merge review gate. This
workflow owns lightweight issue execution, review judgment, repair decisions,
issue-visible finding dispositions, delivery outcome comment URLs, and final
status reporting.
