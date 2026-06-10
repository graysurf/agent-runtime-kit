---
name: create-pr
description:
  Create a GitHub pull request or GitLab merge request through the released nils-cli `forge-cli pr create` surface.
---

# Create PR / MR

## Contract

Prereqs:

- `agent-runtime` and `forge-cli >=1.0.11` are installed from the released
  nils-cli package and available on `PATH`.
- Shared provider, branch, body, and label rules in
  `core/skills/pr/pr-lifecycle/README.md` are satisfied.
- The source branch has been pushed and has an upstream tracking branch.
- The working tree contains only the intended changes, or unrelated changes are
  isolated from the PR/MR scope.

Inputs:

- Provider: `github` or `gitlab` (let `forge-cli` detect it from the remote, or
  pass `--provider` explicitly).
- PR/MR kind: `feature`, `bug`, `chore`, `docs`, `ci`, or `refactor`; it must
  match the branch prefix.
- Source branch, base branch, title, and body section files for
  `agent-runtime pr-body render`.
- Required labels selected from the shared taxonomy.
- Optional reviewers supported by the target provider.
- Draft state: draft by default; use `--no-draft` only when the caller has
  explicitly chosen ready-for-review.

Outputs:

- A GitHub pull request or GitLab merge request created by `forge-cli`.
- A standardized PR/MR body rendered by `agent-runtime pr-body render`, not
  hand-written section scaffolding.
- Text or JSON output from the CLI, depending on `--format`.
- Provider command evidence in `--dry-run` mode.

Failure modes:

- Provider auth, repo detection, or branch upstream checks fail.
- The PR/MR body section files are missing, empty, or fail the
  `agent-runtime pr-body render` contract.
- The rendered body is missing required `forge-cli` sections such as
  `## Summary` and `## Test plan`.
- `local_path_present`: rewrite useful evidence paths in provider-visible PR
  content to `$HOME/...` and omit remote-useless local artifact paths before
  retrying.
- The branch is not pushed, the base branch is invalid, selected labels fail
  catalog validation, or the provider rejects labels or reviewers.

## Body Format

Use `agent-runtime pr-body render` as the canonical formatter. The shared
PR/MR lifecycle reference owns minimum headings, label selection, and
non-closing issue references.

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

For bug PRs/MRs, use the bug-specific section files:

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

Then use the released provider CLI directly. `forge-cli` detects the provider
from the remote; pass `--provider "$PROVIDER"` to pin it (`github` or
`gitlab`):

```bash
forge-cli --provider "$PROVIDER" pr create \
  --kind feature \
  --base main \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE" \
  --label type::feature \
  --label area::runtime \
  --label size::m \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels
```

For an audited preview:

```bash
forge-cli --provider "$PROVIDER" --dry-run --format json pr create \
  --kind feature \
  --base main \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE" \
  --label type::feature \
  --label area::runtime \
  --label size::m \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels
```

## Workflow

1. Inspect `git status --short --branch` and confirm the branch contains only
   the intended change set.
2. Push the branch and ensure it has an upstream tracking branch.
3. Write the narrative content into section files, then render the body with
   `agent-runtime pr-body render --kind <kind> ... --out "$PR_BODY_FILE"`
   (all six kinds render; pass `--issues-file` to carry non-closing
   `Refs #<issue>` references as an `## Issues` section). Do not hand-write
   the section scaffolding or derive the title/body from `git log -1`.
4. Select labels before provider mutation; use
   `core/skills/pr/pr-lifecycle/README.md` for the shared taxonomy rule.
5. If `manifests/forge-labels.yaml` exists, validate labels with the
   appropriate `forge-cli label` surface before the first live PR/MR mutation.
6. Run `forge-cli --provider "$PROVIDER" --dry-run --format json pr create ...`
   before the live create to verify branch/kind/body/provider gates.
7. Run `forge-cli --provider "$PROVIDER" pr create ...` to create the draft
   PR/MR.
8. Record the PR/MR URL, branch, labels, validation, and any provider failure
   in the execution ledger or issue timeline.

## Boundary

`agent-runtime pr-body render` owns standardized feature/bug PR/MR body
scaffolding. `forge-cli` owns provider command rendering, body validation,
provider detection, and the live `gh pr create` / `glab mr create` call. The
workflow owner owns the PR/MR narrative content, validation evidence, branch
hygiene, and the decision to create a draft or ready record.
