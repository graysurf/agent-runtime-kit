---
name: deliver-gitlab-mr
description:
  Deliver GitLab merge requests end to end through the released nils-cli `forge-cli pr deliver` macro.
---

# Deliver GitLab MR

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `glab auth status` succeeds for the target GitLab host when running live mode.
- The working tree contains only the intended delivery changes.
- Local validation and review findings have been resolved before merge.

Inputs:

- Delivery kind: `feature` or `bug`.
- MR title and body file.
- Optional head branch, base branch, merge method, reviewers, and timeout.
- Optional `--no-merge` when the workflow should stop after checks.
- Issue-backed state links when the MR participates in a tracking issue.

Outputs:

- A draft or ready GitLab MR opened from the current branch.
- Pipeline or check state waited through `forge-cli pr wait-checks`.
- A ready-for-review transition when needed.
- A merged MR through `forge-cli pr merge`, unless `--no-merge` is supplied.
- Delivery evidence recorded in the MR or linked tracking issue.

Failure modes:

- Provider auth fails, the branch has no pushed upstream, or the base branch is
  not the intended target.
- Pipeline checks fail, time out, remain pending, or are missing without an
  explicit no-checks decision.
- Review findings or issue-backed completion gates are unresolved.
- Merge strategy, source-branch cleanup, or non-default base requirements are
  ambiguous.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli pr deliver \
  --provider gitlab \
  --kind feature \
  --title "$MR_TITLE" \
  --body-file "$MR_BODY" \
  --base main \
  --method squash
```

To stop after checks without merging:

```bash
forge-cli pr deliver \
  --provider gitlab \
  --kind feature \
  --title "$MR_TITLE" \
  --body-file "$MR_BODY" \
  --base main \
  --no-merge
```

## Workflow

1. Confirm the branch, base, dirty-tree scope, validation evidence, and review
   outcome.
2. Prepare an MR body with `## Summary` and `## Test plan`.
3. Run `forge-cli pr deliver` with the GitLab provider and the selected base.
4. If the macro stops before merge, fix the concrete blocker on the same branch
   and rerun the macro.
5. Record the MR URL, pipeline or check evidence, review outcome, merge commit,
   and any fallback used in the linked issue or delivery notes.

## Boundary

`forge-cli` owns provider create, checks wait, ready, and merge calls. The
workflow owner owns scope judgment, code changes, local validation, specialist
review decisions, issue-backed completion gates, and any temporary provider
fallback decision.
