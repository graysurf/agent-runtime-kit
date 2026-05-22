---
name: tracking-issue-closeout
description:
  Close a plan-tracked issue only after plan-issue gates, approval, merged PR evidence, and final dashboard synchronization pass.
---

# Tracking Issue Closeout

## Contract

Prereqs:

- `plan-issue` is installed from the released nils-cli package and available on
  `PATH`.
- The issue follows the `plan-issue` Task Decomposition contract, or an offline
  body file is supplied for a dry-run gate check.
- User approval or project-policy approval is captured as a concrete comment
  URL before close.
- Linked PRs are merged unless the close policy explicitly allows a documented
  exception.

Inputs:

- Issue number or offline body file.
- Approved review comment URL.
- Optional close reason, close comment, repository override, and state dir.

Outputs:

- A `plan-issue close-plan` JSON result.
- A final close comment and closed provider issue in live mode.
- A rendered dry-run close plan when using `--body-file` or `--dry-run`.

Failure modes:

- Any task row is not done, lacks a concrete PR reference, or points at an
  unmerged PR.
- The approval URL is missing or invalid.
- Live provider issue close fails.
- The issue body no longer parses as a `plan-issue` task table.

## Entrypoint

Run the close gate without mutating the provider first:

```bash
plan-issue close-plan \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --approved-comment-url "$APPROVAL_URL" \
  --dry-run \
  --format json
```

Close live only after the dry-run gate passes:

```bash
plan-issue close-plan \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --approved-comment-url "$APPROVAL_URL" \
  --reason completed \
  --format json
```

For local fixture checks, replace `--issue` with `--body-file <path>` and keep
`--dry-run`.

## Workflow

1. Run `plan-issue status-plan` and confirm all task rows are done or explicitly
   accepted by policy.
2. Resolve the approval comment URL and record it in validation evidence.
3. Run `plan-issue close-plan --dry-run` and inspect any gate failure.
4. Repair missing PR links, incomplete rows, stale approval references, or
   unmerged PRs before live close.
5. Run live `plan-issue close-plan` only after the dry-run gate passes.
6. Record the close result, issue URL, close comment, and any accepted caveat in
   the final session note.

## Boundary

`plan-issue close-plan` owns close gates, task-row validation, approval URL
checking, final comments, and provider issue closure. The skill body owns
approval interpretation, policy exceptions, and whether to stop for user review.
