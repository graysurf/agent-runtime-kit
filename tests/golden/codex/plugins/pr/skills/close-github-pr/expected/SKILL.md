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
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The target PR number is known.
- Required validation, review findings, and issue-backed completion gates have
  been resolved before merge.

Inputs:

- PR number.
- Merge method when the repo requires a method other than the `forge-cli`
  default.
- Optional `--keep-branch` when source branch deletion is not desired.
- A decision to merge, mark ready, wait for checks, or abandon-close the PR.

Outputs:

- Check-state evidence from `forge-cli pr checks` or
  `forge-cli pr wait-checks`.
- Ready-for-review transition when needed.
- A merged PR through `forge-cli pr merge`, or a closed unmerged PR through
  `forge-cli pr close` when explicitly abandoning.

Failure modes:

- Required checks fail, time out, or remain pending.
- The PR is not mergeable, targets a non-default base without explicit
  allowance, or provider auth fails.
- Issue-backed completion state is incomplete for a PR that would close or
  finalize a tracking issue.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli --provider github pr checks "$PR_NUMBER" --required-only true
forge-cli --provider github pr wait-checks "$PR_NUMBER"
forge-cli --provider github pr ready "$PR_NUMBER"
forge-cli --provider github pr merge "$PR_NUMBER" --method merge
```

Only abandon a PR when that is the requested outcome:

```bash
forge-cli --provider github pr close "$PR_NUMBER"
```

## Workflow

1. Inspect the PR metadata and linked issue state before changing it.
2. Resolve review findings and run required local validation.
3. Run `forge-cli --provider github pr wait-checks "$PR_NUMBER"` to gate on
   required provider checks.
4. Run `forge-cli --provider github pr ready "$PR_NUMBER"` if the PR is still
   draft and is ready to merge.
5. Run `forge-cli --provider github pr merge "$PR_NUMBER"` with the repository's
   merge method and branch-retention choice.
6. Record the merge commit, check evidence, linked issue updates, and any
   residual risk in the durable timeline.

## Boundary

`forge-cli` owns provider check, ready, merge, and close calls. The workflow
owner owns review judgment, local validation, issue-backed close gates, and the
decision to merge versus abandon-close.
