---
name: deliver-github-pr
description:
  Deliver GitHub pull requests end to end through the released nils-cli `forge-cli pr deliver` macro.
---

# Deliver GitHub PR

## Contract

Prereqs:

- `agent-runtime`, `forge-cli`, `plan-issue >=0.20.0`, and
  `review-specialists` are installed from the released nils-cli package and
  available on `PATH`. The `code-review-pre-merge-gate` workflow uses
  `review-specialists`.
- `gh auth status` succeeds for the target GitHub host when running live mode.
- The working tree contains only the intended delivery changes.
- Local validation and review findings have been resolved before merge.

Inputs:

- Delivery kind: `feature` or `bug`.
- PR title and body section files for `agent-runtime pr-body render`.
- Optional head branch, base branch, merge method, reviewers, and timeout.
- Required labels selected from the shared taxonomy: one `type::`, one primary
  `area::`, and one `size::`. Add `risk::` or `provider::github` when the
  scope warrants it.
- Optional `--no-merge` when the workflow should stop after checks.
- Optional `--no-closeout` to stop after delivery readiness checks and before
  linked issue closeout.
- Mandatory pre-merge review through `code-review-pre-merge-gate`.
- If the PR body references a linked tracking or dispatch issue, use
  non-closing references such as `Refs #<issue>`; provider auto-close keywords
  are refused.

Outputs:

- A draft or ready GitHub PR opened from the current branch.
- Required checks waited through `forge-cli pr wait-checks`.
- A `code-review-pre-merge-gate` result completed before merge with at least
  `testing` and `maintainability`.
- A delivery review outcome comment posted to the PR before merge.
- A merged PR through `forge-cli pr merge`, unless `--no-merge` is supplied.
- When a linked issue closeout runs, `plan-issue record close` posts closeout
  evidence, repairs the dashboard, verifies linked PRs, and closes the issue.

Failure modes:

- Provider auth fails, the branch has no pushed upstream, or the base branch is
  not the intended target.
- Required checks fail, time out, remain pending, or are missing without an
  explicit no-checks decision.
- Selected labels fail catalog validation or the provider rejects label
  application.
- Mandatory pre-merge review gate findings are unresolved or undispositioned.
- Delivery review outcome comment posting fails.
- A PR body uses a provider auto-close keyword against a linked plan-tracking or
  dispatch issue.
- `plan-issue record close` rejects linked issue closeout.

## Body Format

Use `agent-runtime pr-body render` as the canonical formatter. The renderer owns
feature/bug section order and the `forge-cli`-compatible minimum headings
(`## Summary` and `## Test plan`).

For issue-backed tracking or dispatch work, put provider references in the
rendered narrative as non-closing refs such as `Refs #<issue>`.

## Entrypoint

Render the body with `agent-runtime` before calling the delivery macro:

```bash
agent-runtime pr-body render \
  --kind feature \
  --summary-file "$SUMMARY_FILE" \
  --changes-file "$CHANGES_FILE" \
  --test-first-file "$TEST_FIRST_FILE" \
  --test-plan-file "$TEST_PLAN_FILE" \
  --risk-file "$RISK_FILE" \
  --out "$PR_BODY"
```

Use the released provider CLI directly:

```bash
forge-cli pr deliver \
  --provider github \
  --kind feature \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY" \
  --base main \
  --method squash \
  --label type::feature \
  --label area::runtime \
  --label size::m \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels \
  --no-merge
```

Run `code-review-pre-merge-gate` before merge. Its minimum underlying scope is:

```bash
review-specialists scope --base "$BASE_REF" --testing --maintainability --format json
forge-cli --provider github pr comment "$PR_NUMBER" --body-file "$DELIVERY_REVIEW_OUTCOME"
forge-cli --provider github pr merge "$PR_NUMBER" --method squash
```

Run linked issue closeout after merge when the PR body references a tracking or
dispatch issue via `Refs #<issue>` and `--no-closeout` was not supplied:

```bash
plan-issue --repo "$OWNER_REPO" --format json record close \
  --issue "$ISSUE" \
  --profile "$PROFILE" \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --bundle "$PLAN_BUNDLE"
```

Use `profile=tracking` for lightweight plan-tracking issues and
`profile=dispatch` for dispatch plan records.

## Workflow

1. Confirm the branch, base, dirty-tree scope, validation evidence, and review
   outcome.
2. Inspect linked issues and closing references. For issue-backed plan work,
   use `Refs #<issue>` until `record close` has passed.
3. Render the PR body with `agent-runtime pr-body render`.
4. Select labels before provider mutation. Every delivered PR needs `type::`,
   one primary `area::`, and `size::`; add `risk::` for high-risk changes and
   `provider::github` for GitHub-specific work. Use `state::do-not-merge`
   instead of prose-only blockers when a PR must not merge.
5. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json`
   before the first live delivery in that repo. Use `label audit` when mutation
   is not allowed.
6. Run `forge-cli pr deliver` with selected `--label` flags,
   `--label-catalog manifests/forge-labels.yaml` when present, and
   `--no-merge` so checks complete before the
   mandatory review gate.
7. Run `code-review-pre-merge-gate`:
   `skills/code-review/code-review-pre-merge-gate/SKILL.md`.
8. Keep `code-review-pre-merge-gate` read-only. Repair concrete findings in
   this delivery workflow, then rerun validation, checks, and affected review
   lenses.
9. Post the delivery review outcome body produced by
   `code-review-pre-merge-gate` before merge.
10. Merge with `forge-cli --provider github pr merge "$PR_NUMBER"` unless
   `--no-merge` is the requested final stop.
11. After merge, if the PR body referenced a linked tracking or dispatch issue
   and `--no-closeout` was not supplied, run `plan-issue record close` with the
   correct profile. On gate fail, leave the issue open with the blocked code
   surfaced by `plan-issue` and route to the matching closeout skill.
12. Record the PR URL, labels, check evidence, review outcome, merge commit,
    chained closeout result, and any fallback used in delivery notes.

## Boundary

`forge-cli` owns provider create, checks wait, ready, and merge calls.
`plan-issue record` owns linked issue lifecycle closeout. The workflow owner
owns scope judgment, code changes, local validation, pre-merge gate decisions,
repair loops, delivery outcome comments, and any temporary provider fallback
decision. PR-body `Closes #<issue>` auto-close remains banned for
issue-backed plan records.
