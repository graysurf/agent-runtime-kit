---
name: close-gitlab-mr
description:
  Close or merge GitLab merge requests through the released nils-cli `forge-cli pr` lifecycle surfaces.
---

# Close GitLab MR

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `glab auth status` succeeds for the target GitLab host when running live mode.
- The target MR number is known.
- Required validation, review findings, and issue-backed completion gates have
  been resolved before merge.

Inputs:

- MR number.
- Merge method when the project requires a method other than the `forge-cli`
  default.
- Optional `--keep-branch` when source branch deletion is not desired.
- A decision to merge, mark ready, wait for checks, or abandon-close the MR.

Outputs:

- Check-state evidence from `forge-cli pr checks` or
  `forge-cli pr wait-checks`.
- Ready-for-review transition when needed.
- A merged MR through `forge-cli pr merge`, or a closed unmerged MR through
  `forge-cli pr close` when explicitly abandoning.

Failure modes:

- Required checks fail, time out, or remain pending.
- The MR is not mergeable, targets a non-default base without explicit
  allowance, or provider auth fails.
- Issue-backed completion state is incomplete for an MR that would close or
  finalize a tracking issue.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli --provider gitlab pr checks "$MR_NUMBER" --required-only true
forge-cli --provider gitlab pr wait-checks "$MR_NUMBER"
forge-cli --provider gitlab pr ready "$MR_NUMBER"
forge-cli --provider gitlab pr merge "$MR_NUMBER" --method merge
```

Only abandon an MR when that is the requested outcome:

```bash
forge-cli --provider gitlab pr close "$MR_NUMBER"
```

## Workflow

1. Inspect the MR metadata and linked issue state before changing it.
2. Resolve review findings and run required local validation.
3. Run `forge-cli --provider gitlab pr wait-checks "$MR_NUMBER"` to gate on
   required provider checks.
4. Run `forge-cli --provider gitlab pr ready "$MR_NUMBER"` if the MR is still
   draft and is ready to merge.
5. Run `forge-cli --provider gitlab pr merge "$MR_NUMBER"` with the project's
   merge method and branch-retention choice.
6. Record the merge commit, check evidence, linked issue updates, and any
   residual risk in the durable timeline.

## Boundary

`forge-cli` owns provider check, ready, merge, and close calls. The workflow
owner owns review judgment, local validation, issue-backed close gates, and the
decision to merge versus abandon-close.
