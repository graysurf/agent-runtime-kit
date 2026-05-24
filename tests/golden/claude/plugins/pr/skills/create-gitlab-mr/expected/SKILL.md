---
name: create-gitlab-mr
description:
  Create a GitLab merge request through the released nils-cli `forge-cli pr create` surface.
---

# Create GitLab MR

## Contract

Prereqs:

- `agent-runtime` is installed from the released nils-cli package and available
  on `PATH`.
- `forge-cli` is installed from the released nils-cli package and available on
  `PATH`.
- `glab auth status` succeeds for the target GitLab host when running live mode.
- The source branch has been pushed and has an upstream tracking branch.
- The working tree contains only the intended changes, or unrelated changes are
  isolated from the MR scope.

Inputs:

- MR kind: `feature` or `bug`.
- Source branch, base branch, title, and body section files for
  `agent-runtime pr-body render`.
- Required labels selected from the shared taxonomy: one `type::`, one primary
  `area::`, and one `size::`. Add `risk::` or `provider::gitlab` when the
  scope warrants it.
- Optional reviewers supported by the target GitLab project.
- Draft state: draft by default; use `--no-draft` only when the caller has
  explicitly chosen ready-for-review.

Outputs:

- A GitLab merge request created by `forge-cli`.
- A standardized MR body rendered by `agent-runtime pr-body render`, not
  hand-written section scaffolding.
- Text or JSON output from the CLI, depending on `--format`.
- Provider command evidence in `--dry-run` mode.

Failure modes:

- GitLab auth, repo detection, or branch upstream checks fail.
- The MR body section files are missing, empty, or fail the
  `agent-runtime pr-body render` contract.
- The rendered MR body is missing required `forge-cli` sections such as
  `## Summary` and `## Test plan`.
- The branch is not pushed, the base branch is invalid, selected labels fail
  catalog validation, or the provider rejects labels or reviewers.

## Body Format

Use `agent-runtime pr-body render` as the canonical formatter. The renderer
owns feature/bug section order and the `forge-cli`-compatible minimum headings
(`## Summary` and `## Test plan`); do not duplicate that section table or
hand-write a minimum body in this skill.

For issue-backed tracking or dispatch work, put provider references in the
rendered narrative as non-closing refs such as `Refs #<issue>`; do not use
provider auto-close keywords in the PR/MR body.

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
  --out "$MR_BODY_FILE"
```

For bug MRs, use the bug-specific section files:

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
  --out "$MR_BODY_FILE"
```

Then use the released provider CLI directly:

```bash
forge-cli --provider gitlab pr create \
  --kind feature \
  --base main \
  --title "$MR_TITLE" \
  --body-file "$MR_BODY_FILE" \
  --label type::feature \
  --label area::runtime \
  --label size::m \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels
```

For an audited preview:

```bash
forge-cli --provider gitlab --dry-run --format json pr create \
  --kind feature \
  --base main \
  --title "$MR_TITLE" \
  --body-file "$MR_BODY_FILE" \
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
3. Write the narrative content into section files, then render the MR body with
   `agent-runtime pr-body render --kind feature|bug ... --out "$MR_BODY_FILE"`.
   Do not hand-write the section scaffolding or derive the title/body from
   `git log -1`.
4. Select labels before provider mutation. Every MR needs `type::`, one primary
   `area::`, and `size::`; add `risk::` for high-risk changes and
   `provider::gitlab` for GitLab-specific work. Use `state::do-not-merge`
   instead of prose-only blockers when the MR must not merge.
5. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json`
   before the first live MR in that repo. Use `label audit` when mutation is
   not allowed.
6. Run `forge-cli --provider gitlab --dry-run --format json pr create ...` before
   the live create to verify branch/kind/body/provider gates.
7. Run `forge-cli --provider gitlab pr create ...` to create the draft MR.
8. Record the MR URL, branch, labels, validation, and any provider failure in the
   execution ledger or issue timeline.

## Boundary

`agent-runtime pr-body render` owns standardized feature/bug MR body scaffolding.
`forge-cli` owns provider command rendering, body validation, provider
detection, and the live `glab mr create` call. The workflow owner owns the MR
narrative content, validation evidence, branch hygiene, and the decision to
create a draft or ready MR.
