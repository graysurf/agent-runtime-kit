---
name: create-github-pr
description:
  Create a GitHub pull request through the released nils-cli `forge-cli pr create` surface.
---

# Create GitHub PR

## Contract

Prereqs:

- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The source branch has been pushed and has an upstream tracking branch.
- The working tree contains only the intended changes, or unrelated changes are
  isolated from the PR scope.

Inputs:

- PR kind: `feature` or `bug`.
- Source branch, base branch, title, and body file.
- Optional labels and reviewers.
- Draft state: draft by default; use `--no-draft` only when the caller has
  explicitly chosen ready-for-review.

Outputs:

- A GitHub pull request created by `forge-cli`.
- Text or JSON output from the CLI, depending on `--format`.
- Provider command evidence in `--dry-run` mode.

Failure modes:

- GitHub auth, repo detection, or branch upstream checks fail.
- The PR body is missing required `forge-cli` sections such as `## Summary` and
  `## Test plan`.
- The branch is not pushed, the base branch is invalid, or the provider rejects
  labels or reviewers.

## Entrypoint

Use the released CLI directly:

```bash
forge-cli --provider github pr create \
  --kind feature \
  --base main \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE"
```

For an audited preview:

```bash
forge-cli --provider github --dry-run --format json pr create \
  --kind feature \
  --base main \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE"
```

## Workflow

1. Inspect `git status --short --branch` and confirm the branch contains only
   the intended change set.
2. Push the branch and ensure it has an upstream tracking branch.
3. Prepare a PR body with at least `## Summary` and `## Test plan`; include
   validation commands and risk notes in prose.
4. Run `forge-cli --provider github --dry-run --format json pr create ...` when
   the command shape or provider resolution needs evidence.
5. Run `forge-cli --provider github pr create ...` to create the draft PR.
6. Record the PR URL, branch, validation, and any provider failure in the
   execution ledger or issue timeline.

## Boundary

`forge-cli` owns provider command rendering, body validation, provider
detection, and the live `gh pr create` call. The workflow owner owns the PR
narrative, validation evidence, branch hygiene, and the decision to create a
draft or ready PR.
