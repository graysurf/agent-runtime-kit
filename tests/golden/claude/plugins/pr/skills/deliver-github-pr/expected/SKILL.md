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
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The working tree contains only the intended delivery changes.
- Local validation and review findings have been resolved before merge.

Inputs:

- Delivery kind: `feature` or `bug`.
- PR title and body file.
- Optional head branch, base branch, merge method, reviewers, and timeout.
- Optional `--no-merge` when the workflow should stop after checks.
- Mandatory pre-merge specialist review using the shared delivery specialist
  review gate; this is an orchestration gate, not a `forge-cli pr deliver`
  flag.
- Issue-backed state links when the PR participates in a tracking issue.

Outputs:

- A draft or ready GitHub PR opened from the current branch.
- Required checks waited through `forge-cli pr wait-checks`.
- A `code-review-specialists` pass completed before merge with at least
  `testing` and `maintainability` forced, even for small diffs.
- A delivery review outcome comment posted to the PR before merge.
- A ready-for-review transition when needed.
- A merged PR through `forge-cli pr merge`, unless `--no-merge` is supplied.
- Delivery evidence recorded in the PR or linked tracking issue.

Failure modes:

- Provider auth fails, the branch has no pushed upstream, or the base branch is
  not the intended target.
- Required checks fail, time out, remain pending, or are missing without an
  explicit no-checks decision.
- Mandatory specialist review reports concrete findings that have not been
  repaired or explicitly accepted under the delivery policy.
- Delivery review outcome comment posting fails.
- Review findings or issue-backed completion gates are unresolved.
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

## Workflow

1. Confirm the branch, base, dirty-tree scope, validation evidence, and review
   outcome.
2. Prepare a PR body with `## Summary` and `## Test plan`.
3. Run `forge-cli pr deliver` with the GitHub provider, selected base, and
   `--no-merge` so checks complete before the mandatory review gate. If the
   macro stops for a concrete blocker before checks are green, fix the blocker
   on the same branch and rerun the macro.
4. Follow the shared delivery specialist review gate:
   `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`.
   Resolve the PR base branch, run `review-specialists scope --base "$BASE_REF"
   --testing --maintainability --format json`, add risk lenses when warranted,
   and do not skip only because the diff is small.
5. Keep `code-review-specialists` read-only. Repair concrete findings in this
   delivery workflow, then rerun validation, required checks, and affected
   specialist lenses.
6. Post the delivery review outcome comment before merge using:
   `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`.
7. Merge with `forge-cli --provider github pr merge "$PR_NUMBER"` unless
   `--no-merge` is the requested final stop.
8. Record the PR URL, check evidence, review outcome, merge commit, and any
   fallback used in the linked issue or delivery notes.

## Boundary

`forge-cli` owns provider create, checks wait, ready, and merge calls. The
workflow owner owns scope judgment, code changes, local validation, specialist
review decisions, specialist repair loops, delivery outcome comments,
issue-backed completion gates, and any temporary provider fallback decision.
