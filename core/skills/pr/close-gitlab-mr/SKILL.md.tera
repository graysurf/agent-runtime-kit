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
- Optional user-requested pre-close review through the matching `code-review-*`
  skill.
- A decision to merge, mark ready, wait for checks, or abandon-close the MR.
- Issue-backed close gate evidence when the MR would complete or auto-close a
  lightweight tracking issue or dispatch plan issue.

Outputs:

- Check-state evidence from `forge-cli pr checks` or
  `forge-cli pr wait-checks`.
- User-requested pre-close review completed before merge, when
  requested, with no concrete findings waiting on user decision.
- Ready-for-review transition when needed.
- A merged MR through `forge-cli pr merge`, or a closed unmerged MR through
  `forge-cli pr close` when explicitly abandoning.

Failure modes:

- Required checks fail, time out, or remain pending.
- The MR is not mergeable, targets a non-default base without explicit
  allowance, or provider auth fails.
- Issue-backed completion state is incomplete for an MR that would close or
  finalize a tracking issue.
- User-requested pre-close review reports concrete findings that
  need a user decision before merge.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli --provider gitlab pr checks "$MR_NUMBER" --required-only true
forge-cli --provider gitlab pr wait-checks "$MR_NUMBER"
forge-cli --provider gitlab pr ready "$MR_NUMBER"
forge-cli --provider gitlab pr merge "$MR_NUMBER" --method merge
```

When the user requests review, run the matching read-only `code-review-*`
workflow before continuing; do not inline review orchestration into this close
workflow.

Only abandon an MR when that is the requested outcome:

```bash
forge-cli --provider gitlab pr close "$MR_NUMBER"
```

## Workflow

1. Inspect the MR metadata, closing references, linked issues, and target branch
   before changing it.
2. Resolve review findings and run required local validation.
3. If the user explicitly requested review, specialist review, or review before
   close, choose the lightest matching read-only review workflow before final
   merge: `code-review-quick-pass` for routine diffs,
   `code-review-focused-lens` for explicit lenses,
   `code-review-pre-merge-gate` for final delivery gates, and
   `code-review-specialists` only for broad or risky full-bundle review. Resolve
   the MR target branch and stop before merge if concrete findings need a
   decision.
4. Run `forge-cli --provider gitlab pr wait-checks "$MR_NUMBER"` to gate on
   required provider checks.
5. For plan-tracking issues, require complete issue-backed state and closeout
   readiness before merging an MR that closes or finalizes the issue. For
   dispatch issues, require `plan-issue` / `dispatch-plan-closeout` gates.
6. Run `forge-cli --provider gitlab pr ready "$MR_NUMBER"` if the MR is still
   draft and is ready to merge.
7. Run `forge-cli --provider gitlab pr merge "$MR_NUMBER"` with the project's
   merge method and branch-retention choice.
8. Record the merge commit, check evidence, linked issue updates, and any
   residual risk in the durable timeline.

## Boundary

`forge-cli` owns provider check, ready, merge, and close calls. The workflow
owner owns review judgment, local validation, issue-backed close gates, and the
decision to merge versus abandon-close. Direct close requests do not run the
mandatory delivery gate unless the user asked for review; end-to-end
`deliver-gitlab-mr` owns that mandatory gate and calls this close surface only
after review has passed or been dispositioned.
