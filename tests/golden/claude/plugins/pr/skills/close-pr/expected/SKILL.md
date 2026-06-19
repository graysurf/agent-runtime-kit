---
name: close-pr
description:
  Close or merge GitHub pull requests or GitLab merge requests through the released nils-cli `forge-cli pr` lifecycle surfaces.
---

# Close PR / MR

## Contract

Prereqs:

- `forge-cli >=1.11.2` is installed from the released nils-cli package and
  available on `PATH`; its `pr merge` enforces the review-thread
  (`unresolved_review_threads`) and task-list (`unchecked_task_items`)
  fail-closed gates.
- Shared provider and issue-backed merge rules in
  `core/skills/pr/pr-lifecycle/README.md` are satisfied.
- The target PR/MR number is known.
- Required validation, review findings, and issue-backed completion gates have
  been resolved before merge.

Inputs:

- Provider: `github` or `gitlab` (let `forge-cli` detect it from the remote, or
  pass `--provider` explicitly).
- PR/MR number.
- Merge method when the repo/project requires a method other than the
  `forge-cli` default.
- Optional `--keep-branch` when source branch deletion is not desired.
- Optional user-requested pre-close review through the matching `code-review-*`
  skill.
- A decision to merge, mark ready, wait for checks, or abandon-close the PR/MR.
- Issue-backed close gate evidence when the PR/MR would complete or auto-close a
  lightweight tracking issue or dispatch plan issue.

Outputs:

- Check / pipeline state evidence from `forge-cli pr checks` or
  `forge-cli pr wait-checks`.
- User-requested pre-close review completed before merge, when
  requested, with no concrete findings waiting on user decision.
- Ready-for-review transition when needed.
- A merged PR/MR through `forge-cli pr merge`, or a closed unmerged PR/MR
  through `forge-cli pr close` when explicitly abandoning.

Failure modes:

- Required checks / pipeline checks fail, time out, or remain pending.
- Unresolved review threads or unchecked `- [ ]` task-list items remain on
  the PR/MR at merge time; `forge-cli pr merge` fails closed with
  `unresolved_review_threads` / `unchecked_task_items` until each is
  dispositioned (or explicitly bypassed with a recorded reason).
- The PR/MR is not mergeable, targets a non-default base without explicit
  allowance, or provider auth fails.
- Issue-backed completion state is incomplete for a PR/MR that would close or
  finalize a tracking issue.
- User-requested pre-close review reports concrete findings that
  need a user decision before merge.
- The installed `forge-cli` is older than the manifest floor. Upgrade nils-cli
  before relying on GitHub checks / GitLab pipelines, ready, or merge
  operations.

## Entrypoint

Use the released CLI directly. `forge-cli` detects the provider from the remote;
pass `--provider "$PROVIDER"` to pin it (`github` or `gitlab`):

```bash
forge-cli --provider "$PROVIDER" pr checks "$PR_NUMBER" --required-only true
forge-cli --provider "$PROVIDER" pr wait-checks "$PR_NUMBER"
forge-cli --provider "$PROVIDER" pr ready "$PR_NUMBER"
forge-cli --provider "$PROVIDER" pr merge "$PR_NUMBER" --method merge
```

Before the merge call, sweep both merge gates and disposition what they
surface:

```bash
forge-cli --provider "$PROVIDER" --format json pr review-threads list "$PR_NUMBER"
forge-cli --provider "$PROVIDER" --format json pr tasks "$PR_NUMBER"
```

`data.unresolved == 0` and `data.unchecked == 0` are the gates `pr merge`
enforces mechanically. Resolve threads by repair, reply-and-resolve, or a
follow-up issue; resolve unchecked `- [ ]` description items by checking
them off or rewriting them as deferred with a follow-up ref. Do not pass
`--allow-unresolved-threads` or `--allow-unchecked-tasks` (the latter
requires `--allow-unchecked-tasks-reason`) without recording why in the
close decision.

When the user requests review, run the matching read-only `code-review-*`
workflow before continuing; do not inline review orchestration into this close
workflow.

Only abandon a PR/MR when that is the requested outcome:

```bash
forge-cli --provider "$PROVIDER" pr close "$PR_NUMBER"
```

## Workflow

1. Inspect the PR/MR metadata, closing references, linked issues, and
   base/target branch before changing it.
2. Resolve review findings and run required local validation.
3. If the user explicitly requested review, specialist review, or review before
   close, choose the lightest matching read-only review workflow before final
   merge: `code-review-quick-pass` for routine diffs,
   `code-review-focused-lens` for explicit lenses,
   `code-review-pre-merge-gate` for final delivery gates, and
   `code-review-specialists` only for broad or risky full-bundle review. Resolve
   the base/target branch and stop before merge if concrete findings need a
   decision.
4. Run `forge-cli --provider "$PROVIDER" pr wait-checks "$PR_NUMBER"` to gate on
   required provider checks or pipelines.
5. Sweep `forge-cli pr review-threads` and `forge-cli pr tasks` (see
   Entrypoint) and disposition every unresolved thread and unchecked `- [ ]`
   description item before merging; `pr merge` refuses both fail-closed.
6. For plan-tracking issues, require complete issue-backed state and closeout
   readiness before merging a PR/MR that closes or finalizes the issue. For
   dispatch issues, require `plan-issue` / `dispatch-plan-closeout` gates.
7. Run `forge-cli --provider "$PROVIDER" pr ready "$PR_NUMBER"` if the PR/MR is
   still draft and is ready to merge.
8. Run `forge-cli --provider "$PROVIDER" pr merge "$PR_NUMBER"` with the
   repo/project merge method and branch-retention choice.
9. Record the merge commit, check/pipeline evidence, linked issue updates, and
   any residual risk in the durable timeline.

## Boundary

`forge-cli` owns provider check, ready, merge, and close calls. The workflow
owner owns review judgment, local validation, issue-backed close gates, and the
decision to merge versus abandon-close. Direct close requests do not run the
mandatory delivery gate unless the user asked for review; end-to-end
`deliver-pr` owns that mandatory gate and calls this close surface only after
review has passed or been dispositioned.

Shared rules: `core/skills/pr/pr-lifecycle/README.md`.
