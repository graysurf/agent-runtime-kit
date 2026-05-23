---
name: deliver-github-pr
description:
  Deliver GitHub pull requests end to end through the released nils-cli `forge-cli pr deliver` macro.
---

# Deliver GitHub PR

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH`.
- `gh` is available on `PATH` (used by `forge-cli` and by the Step 10
  chained closeout to fetch issue comments — `forge-cli issue view --format
  json` under forge-cli 0.17.6 returns body fields only).
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The working tree contains only the intended delivery changes.
- Local validation and review findings have been resolved before merge.

Inputs:

- Delivery kind: `feature` or `bug`.
- PR title and body file.
- Optional head branch, base branch, merge method, reviewers, and timeout.
- Optional `--no-merge` when the workflow should stop after checks.
- Optional `--no-closeout` to stop the workflow after delivery readiness checks
  and before any chained issue closeout. Use when closeout is owned by a
  separate downstream skill invocation or by a human reviewer. Does not
  bypass the merge step; PR delivery still completes.
- Mandatory pre-merge specialist review using the shared delivery specialist
  review gate; this is an orchestration gate, not a `forge-cli pr deliver`
  flag.
- Issue-backed state links when the PR participates in a tracking issue.
- If the PR body references a linked tracking or dispatch issue, the PR body
  must use non-closing references such as `Refs #<issue>` rather than
  `Closes #<issue>`; auto-close via the PR body is refused, and the new
  post-merge chained closeout in Step 10 replaces it under the closeout-gate
  contract.

Outputs:

- A draft or ready GitHub PR opened from the current branch.
- Required checks waited through `forge-cli pr wait-checks`.
- A `code-review-specialists` pass completed before merge with at least
  `testing` and `maintainability` forced, even for small diffs.
- A delivery review outcome comment posted to the PR before merge.
- A ready-for-review transition when needed.
- A merged PR through `forge-cli pr merge`, unless `--no-merge` is supplied.
- Delivery evidence recorded in the PR or linked tracking issue.
- When the PR body references a linked tracking or dispatch issue via
  `Refs #<issue>` and chained closeout runs (default, unless `--no-closeout`
  or `--no-merge` was supplied or any closeout gate rejects): a closed
  provider issue, a rendered closeout comment in the issue's profile family
  (`tracking-issue-closeout:v1` for tracking,
  `dispatch-plan-closeout:v1` for dispatch), and the issue dashboard
  repaired to link the closeout comment URL.

Failure modes:

- Provider auth fails, the branch has no pushed upstream, or the base branch is
  not the intended target.
- Required checks fail, time out, remain pending, or are missing without an
  explicit no-checks decision.
- Mandatory specialist review reports concrete findings that have not been
  repaired or explicitly accepted under the delivery policy.
- Delivery review outcome comment posting fails.
- Review findings or issue-backed completion gates are unresolved.
- A PR body uses `Closes #<issue>` or any equivalent provider auto-close
  keyword against a linked plan-tracking or dispatch issue; auto-close is
  refused. The post-merge chained closeout in Step 10 is the permitted
  issue-close mechanism, and it runs only after
  `plan-issue record closeout-gate` clears.
- The installed `forge-cli` is older than the manifest floor. Upgrade nils-cli
  before relying on GitHub delivery macro checks, ready, or merge operations.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli pr deliver \
  --provider github \
  --kind feature \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY" \
  --base main \
  --method squash \
  --no-merge
```

Run the shared review gate before merge:

```bash
review-specialists scope --base "$BASE_REF" --testing --maintainability --format json
forge-cli --provider github pr comment "$PR_NUMBER" --body-file "$DELIVERY_REVIEW_OUTCOME"
forge-cli --provider github pr merge "$PR_NUMBER" --method squash
```

Run the post-merge chained closeout when the PR body references a linked
tracking or dispatch issue via `Refs #<issue>` (default, unless
`--no-closeout` or `--no-merge`). Fetch the body + comments through `gh`
because `forge-cli issue view --format json` omits comments under
forge-cli 0.17.6:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_COMMENTS_JSON"
jq -r .body "$ISSUE_COMMENTS_JSON" >"$ISSUE_BODY"

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

plan-issue record render-comment \
  --profile tracking \
  --kind closeout \
  --content-file "$CLOSEOUT_MD" \
  --out "$CLOSEOUT_COMMENT"

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$CLOSEOUT_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$FINAL_DASHBOARD" --format json
forge-cli issue close "$ISSUE" --repo "$OWNER_REPO" --format json
```

For dispatch profile issues, swap `--profile tracking` for `--profile
dispatch` and add `--require-review` to the closeout-gate invocation. The
v2 marker family `plan-issue-record:v2` covers both tracking and dispatch
through the `--profile` flag; the retired `--marker-family compat` /
`shared` flags are not accepted by `plan-issue >=0.17.7`. The audit step
in this block determines the profile.

## Workflow

1. Confirm the branch, base, dirty-tree scope, validation evidence, and review
   outcome.
2. Inspect linked issues and closing references. For issue-backed plan work,
   prefer `Refs #<issue>` until the appropriate closeout gate has passed.
3. Prepare a PR body with `## Summary` and `## Test plan`.
4. Run `forge-cli pr deliver` with the GitHub provider, selected base, and
   `--no-merge` so checks complete before the mandatory review gate. If the
   macro stops for a concrete blocker before checks are green, fix the blocker
   on the same branch and rerun the macro.
5. Follow the shared delivery specialist review gate:
   `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`.
   Resolve the PR base branch, run `review-specialists scope --base "$BASE_REF"
   --testing --maintainability --format json`, add risk lenses when warranted,
   and do not skip only because the diff is small.
6. Keep `code-review-specialists` read-only. Repair concrete findings in this
   delivery workflow, then rerun validation, required checks, and affected
   specialist lenses.
7. Post the delivery review outcome comment before merge using:
   `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`.
8. For lightweight tracking issues, verify the latest issue-hosted state is
   complete and closeout-ready before allowing auto-close. For dispatch issues,
   verify `plan-issue` sprint/plan gates or use `dispatch-plan-closeout`.
9. Merge with `forge-cli --provider github pr merge "$PR_NUMBER"` unless
   `--no-merge` is the requested final stop.
10. After merge, if the PR body referenced a linked tracking or dispatch
   issue via `Refs #<issue>` and `--no-closeout` was not supplied, run the
   chained closeout inline. Re-fetch the issue body and comments through
   `gh issue view "$ISSUE" --json body,comments` (forge-cli 0.17.6's
   `issue view --format json` returns the body fields only; the comments
   array is required for `plan-issue record audit|closeout-gate
   --comments-json`). Run `plan-issue record audit` to identify the
   profile (`tracking` or `dispatch`), then run `plan-issue record
   closeout-gate` with the matching profile and the merged PR ref. On
   gate pass, render the closeout comment through `plan-issue record
   render-comment --kind closeout`, post it through `forge-cli issue
   comment`, repair the dashboard through `forge-cli issue edit`, and
   close the issue through `forge-cli issue close` (no `--reason`;
   forge-cli 0.17.6 rejects it). On gate fail, stop the chain, leave
   the issue open with the unblock action surfaced by the failing step,
   and recommend rerunning `plan-tracking-issue-closeout` (tracking) or
   `dispatch-plan-closeout` (dispatch) directly to diagnose or complete.
   This step never runs when `--no-merge` was used.
11. Record the PR URL, check evidence, review outcome, merge commit, chained
   closeout result (closed/skipped/blocked), and any fallback used in the
   linked issue or delivery notes.

## Boundary

`forge-cli` owns provider create, checks wait, ready, and merge calls. The
workflow owner owns scope judgment, code changes, local validation, specialist
review decisions, specialist repair loops, delivery outcome comments,
issue-backed completion gates, and any temporary provider fallback decision.

The chained closeout in Step 10 reuses the same `plan-issue record
closeout-gate`, `plan-issue record render-comment --kind closeout`, and
`forge-cli issue close` calls that `plan-tracking-issue-closeout` and
`dispatch-plan-closeout` wrap; those skills remain the canonical reference
for the sequence and the recovery surface when the chain fails or when
`--no-closeout` is supplied. The boundary does not move: `plan-issue
record` still owns gate evaluation and marker rendering, and `forge-cli`
still owns the provider close call. PR-body `Closes #<issue>` auto-close
remains banned even when chained closeout is enabled.
