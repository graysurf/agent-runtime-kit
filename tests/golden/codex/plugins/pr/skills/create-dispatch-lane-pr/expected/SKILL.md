---
name: create-dispatch-lane-pr
description:
  Create a GitHub dispatch-lane pull request with `forge-cli pr create` after a plan issue assigns the lane.
---

# Create Dispatch Lane PR

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- A plan issue or dispatch record identifies the lane, source branch, base
  plan branch, task scope, and required validation.
- Dispatch-plan lanes must target `PLAN_BRANCH`, not the repository default
  branch.
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The lane branch has been pushed and has an upstream tracking branch.

Inputs:

- Dispatch lane id, task id, source branch, base plan branch, title, and body
  file.
- Validation evidence or an explicit not-run reason for the lane.
- Required body sections: `## Summary`, `## Scope`, `## Testing`, and
  `## Issue`.
- Optional labels and reviewers.

Outputs:

- A draft GitHub pull request for the dispatch lane.
- Provider command evidence in `--dry-run` mode.
- PR URL recorded back to the owning plan issue or dispatch record.

Failure modes:

- The dispatch record is missing branch, base, task, or validation data.
- The PR body is missing required `forge-cli` sections such as `## Summary` and
  `## Scope`, `## Testing`, and `## Issue`, or still contains placeholders.
- The PR base is not the dispatched `PLAN_BRANCH`.
- GitHub auth, branch upstream checks, labels, or reviewers fail.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli --provider github pr create \
  --kind feature \
  --base "$PLAN_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE" \
  --label dispatch
```

For an audited preview:

```bash
forge-cli --provider github --dry-run --format json pr create \
  --kind feature \
  --base "$PLAN_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE" \
  --label dispatch
```

## Workflow

1. Read the owning dispatch record and confirm the lane scope, source branch,
   base plan branch, and validation expectations.
2. Inspect `git status --short --branch`, then push the lane branch and confirm
   upstream tracking.
3. Render a PR body with `## Summary`, `## Scope`, `## Testing`, and
   `## Issue`; include the lane id, task ids, validation, issue link, and
   handoff notes.
4. Run the `forge-cli --dry-run` form when the lane needs command-shape
   evidence before mutation.
5. Confirm the requested base equals the assigned `PLAN_BRANCH`.
6. Run `forge-cli --provider github pr create ...` to create the draft lane PR.
7. Write the PR URL back to the owning issue timeline or dispatch record through
   `plan-issue link-pr` when the issue uses `Task Decomposition`.

## Boundary

`forge-cli` owns the GitHub PR creation call. The dispatch workflow owns lane
selection, issue timeline updates, validation interpretation, and reviewer or
subagent handoff policy.
