---
name: create-github-pr
description:
  Create a GitHub pull request through the released nils-cli `forge-cli pr create` surface.
---

# Create GitHub PR

## Contract

Prereqs:

- `agent-runtime` is installed from the released nils-cli package and available
  on `PATH`.
- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The source branch has been pushed and has an upstream tracking branch.
- The working tree contains only the intended changes, or unrelated changes are
  isolated from the PR scope.

Inputs:

- PR kind: `feature` or `bug`.
- Source branch, base branch, title, and body section files for
  `agent-runtime pr-body render`.
- Optional labels and reviewers.
- Draft state: draft by default; use `--no-draft` only when the caller has
  explicitly chosen ready-for-review.

Outputs:

- A GitHub pull request created by `forge-cli`.
- A standardized PR body rendered by `agent-runtime pr-body render`, not
  hand-written section scaffolding.
- Text or JSON output from the CLI, depending on `--format`.
- Provider command evidence in `--dry-run` mode.

Failure modes:

- GitHub auth, repo detection, or branch upstream checks fail.
- The PR body section files are missing, empty, or fail the
  `agent-runtime pr-body render` contract.
- The rendered PR body is missing required `forge-cli` sections such as
  `## Summary` and `## Test plan`.
- The branch is not pushed, the base branch is invalid, or the provider rejects
  labels or reviewers.

## Entrypoint

Render the body with `agent-runtime` before calling the provider layer:

```bash
agent-runtime pr-body render \
  --kind feature \
  --summary-file "$SUMMARY_FILE" \
  --changes-file "$CHANGES_FILE" \
  --test-first-file "$TEST_FIRST_FILE" \
  --test-plan-file "$TEST_PLAN_FILE" \
  --risk-file "$RISK_FILE" \
  --out "$PR_BODY_FILE"
```

For bug PRs, use the bug-specific section files:

```bash
agent-runtime pr-body render \
  --kind bug \
  --summary-file "$SUMMARY_FILE" \
  --problem-file "$PROBLEM_FILE" \
  --reproduction-file "$REPRODUCTION_FILE" \
  --issues-file "$ISSUES_FILE" \
  --fix-approach-file "$FIX_APPROACH_FILE" \
  --test-first-file "$TEST_FIRST_FILE" \
  --test-plan-file "$TEST_PLAN_FILE" \
  --risk-file "$RISK_FILE" \
  --out "$PR_BODY_FILE"
```

Then use the released provider CLI directly:

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
3. Write the narrative content into section files, then render the PR body with
   `agent-runtime pr-body render --kind feature|bug ... --out "$PR_BODY_FILE"`.
   Do not hand-write the section scaffolding or derive the title/body from
   `git log -1`.
4. Run `forge-cli --provider github --dry-run --format json pr create ...` before
   the live create to verify branch/kind/body/provider gates.
5. Run `forge-cli --provider github pr create ...` to create the draft PR.
6. Record the PR URL, branch, validation, and any provider failure in the
   execution ledger or issue timeline.

## Boundary

`agent-runtime pr-body render` owns standardized feature/bug PR body scaffolding.
`forge-cli` owns provider command rendering, body validation, provider
detection, and the live `gh pr create` call. The workflow owner owns the PR
narrative content, validation evidence, branch hygiene, and the decision to
create a draft or ready PR.
