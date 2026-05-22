---
name: close-github-pr
description:
  Close or merge GitHub pull requests through the released nils-cli `forge-cli pr` lifecycle surfaces.
---

# Close GitHub PR

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH` when the user requests pre-close specialist review.
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The target PR number is known.
- Required validation, review findings, and issue-backed completion gates have
  been resolved before merge.

Inputs:

- PR number.
- Merge method when the repo requires a method other than the `forge-cli`
  default.
- Optional `--keep-branch` when source branch deletion is not desired.
- Optional user-requested pre-close specialist review through
  `code-review-specialists`.
- A decision to merge, mark ready, wait for checks, or abandon-close the PR.
- Issue-backed close gate evidence when the PR would complete or auto-close a
  lightweight tracking issue or dispatch plan issue.

Outputs:

- Check-state evidence from `forge-cli pr checks` or
  `forge-cli pr wait-checks`.
- User-requested pre-close specialist review completed before merge, when
  requested, with no concrete findings waiting on user decision.
- Ready-for-review transition when needed.
- A merged PR through `forge-cli pr merge`, or a closed unmerged PR through
  `forge-cli pr close` when explicitly abandoning.

Failure modes:

- Required checks fail, time out, or remain pending.
- The PR is not mergeable, targets a non-default base without explicit
  allowance, or provider auth fails.
- Issue-backed completion state is incomplete for a PR that would close or
  finalize a tracking issue.
- User-requested pre-close specialist review reports concrete findings that
  need a user decision before merge.
- The installed `forge-cli` is older than the manifest floor. Upgrade nils-cli
  before relying on GitHub checks, ready, or merge operations.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli --provider github pr checks "$PR_NUMBER" --required-only true
forge-cli --provider github pr wait-checks "$PR_NUMBER"
forge-cli --provider github pr ready "$PR_NUMBER"
forge-cli --provider github pr merge "$PR_NUMBER" --method merge
```

Optional user-requested review gate:

```bash
review-specialists scope --base "$BASE_REF" --format json
```

Only abandon a PR when that is the requested outcome:

```bash
forge-cli --provider github pr close "$PR_NUMBER"
```

## Workflow

1. Inspect the PR metadata, closing references, linked issues, and base branch
   before changing it.
2. Resolve review findings and run required local validation.
3. If the user explicitly requested review, specialist review, or review before
   close, run the optional `code-review-specialists` gate before final merge.
   Resolve the PR base branch, keep the specialist workflow read-only, honor its
   scope and skip rules unless the user forced a lens, and stop before merge if
   concrete findings need a decision.
4. Run `forge-cli --provider github pr wait-checks "$PR_NUMBER"` to gate on
   required provider checks.
5. For plan-tracking issues, require complete issue-backed state and closeout
   readiness before merging a PR that closes or finalizes the issue. For
   dispatch issues, require `plan-issue` / `dispatch-plan-closeout` gates.
6. Run `forge-cli --provider github pr ready "$PR_NUMBER"` if the PR is still
   draft and is ready to merge.
7. Run `forge-cli --provider github pr merge "$PR_NUMBER"` with the repository's
   merge method and branch-retention choice.
8. Record the merge commit, check evidence, linked issue updates, and any
   residual risk in the durable timeline.

## Boundary

`forge-cli` owns provider check, ready, merge, and close calls. The workflow
owner owns review judgment, local validation, issue-backed close gates, and the
decision to merge versus abandon-close. Direct close requests do not run the
mandatory delivery gate unless the user asked for review; end-to-end
`deliver-github-pr` owns that mandatory gate and calls this close surface only
after review has passed or been dispositioned.
