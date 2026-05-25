---
name: deliver-gitlab-mr
description:
  Deliver GitLab merge requests end to end through the released nils-cli `forge-cli pr deliver` macro.
---

# Deliver GitLab MR

## Contract

Prereqs:

- `agent-runtime`, `forge-cli`, `plan-issue >=0.20.0`, and
  `review-specialists` are installed from the released nils-cli package and
  available on `PATH`. The `code-review-pre-merge-gate` workflow uses
  `review-specialists`.
- `glab auth status` succeeds for the target GitLab host when running live mode.
- The working tree contains only the intended delivery changes.
- Local validation and review findings have been resolved before merge.

Inputs:

- Delivery kind: `feature` or `bug`.
- MR title and body section files for `agent-runtime pr-body render`.
- Optional head branch, base branch, merge method, reviewers, and timeout.
- Required labels selected from the shared taxonomy: one `type::`, one primary
  `area::`, and one `size::`. Add `risk::` or `provider::gitlab` when the
  scope warrants it.
- Optional `--no-merge` when the workflow should stop after checks.
- Optional `--no-closeout` to stop after delivery readiness checks and before
  linked issue closeout.
- Mandatory pre-merge review through `code-review-pre-merge-gate`.
- If the MR description references a linked tracking or dispatch issue, use
  non-closing references such as `Refs #<issue>`; GitLab close keywords are
  refused.
- If the MR description references a linked tracking or dispatch issue,
  lifecycle readiness is also a pre-merge gate: source, plan, complete state,
  latest `role=session`, validation, and review evidence must be present before
  merge.

Outputs:

- A draft or ready GitLab MR opened from the current branch.
- Pipeline or check state waited through `forge-cli pr wait-checks`.
- A `code-review-pre-merge-gate` result completed before merge with at least
  `testing` and `maintainability`.
- A delivery review outcome comment posted to the MR before merge.
- A merged MR through `forge-cli pr merge`, unless `--no-merge` is supplied.
- When a linked issue closeout runs, `plan-issue record close` posts closeout
  evidence, repairs the dashboard, verifies linked merge requests, and closes
  the issue.

Failure modes:

- Provider auth fails, the branch has no pushed upstream, or the base branch is
  not the intended target.
- Pipeline checks fail, time out, remain pending, or are missing without an
  explicit no-checks decision.
- Selected labels fail catalog validation or the provider rejects label
  application.
- Mandatory pre-merge review gate findings are unresolved or undispositioned.
- Delivery review outcome comment posting fails.
- An MR description uses a GitLab auto-close keyword against a linked
  plan-tracking or dispatch issue.
- A linked tracking or dispatch issue is missing lifecycle readiness before
  merge. Route to `deliver-plan-tracking-issue` or `deliver-dispatch-plan`
  instead of merging and backfilling after the fact.
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
  --out "$MR_BODY"
```

Use the released provider CLI directly:

```bash
forge-cli pr deliver \
  --provider gitlab \
  --kind feature \
  --title "$MR_TITLE" \
  --body-file "$MR_BODY" \
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
review-specialists scope \
  --base "$BASE_REF" \
  --testing \
  --maintainability \
  --format json
forge-cli --provider gitlab pr comment "$MR_NUMBER" \
  --body-file "$DELIVERY_REVIEW_OUTCOME"
forge-cli --provider gitlab pr merge "$MR_NUMBER" --method squash
```

For linked tracking or dispatch issues, run a pre-merge lifecycle audit before
the merge. This is not closeout yet, because `record close` verifies the merged
MR after merge:

```bash
forge-cli --provider gitlab --repo "$OWNER_REPO" --format json \
  issue view "$ISSUE" --with-comments >"$ISSUE_VIEW_JSON"
jq '{body:.data.body, comments:(.data.comments // [])}' \
  "$ISSUE_VIEW_JSON" >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile "$PROFILE" \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON"
```

Stop if the audit lacks `session` evidence, if the latest state is not
`complete`, or if the dashboard still shows `Latest session: pending`.

Run linked issue closeout after merge when the MR description references a
tracking or dispatch issue via `Refs #<issue>` and `--no-closeout` was not
supplied:

```bash
plan-issue --repo "$OWNER_REPO" --format json record close \
  --issue "$ISSUE" \
  --profile "$PROFILE" \
  --linked-pr "$OWNER_REPO!$MR_NUMBER" \
  --approval "$APPROVAL" \
  --bundle "$PLAN_BUNDLE" \
  --add-label state::closed \
  --remove-label state::needs-triage
```

Use `profile=tracking` for lightweight plan-tracking issues and
`profile=dispatch` for dispatch plan records.

## Workflow

1. Confirm the branch, base, dirty-tree scope, validation evidence, and review
   outcome.
2. Inspect linked issues and closing references. For issue-backed plan work,
   use `Refs #<issue>` until `record close` has passed.
3. Render the MR body with `agent-runtime pr-body render`.
4. Select labels before provider mutation. Every delivered MR needs `type::`,
   one primary `area::`, and `size::`; add `risk::` for high-risk changes and
   `provider::gitlab` for GitLab-specific work. Use `state::do-not-merge`
   instead of prose-only blockers when an MR must not merge.
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
10. Before merge, if the MR references a linked tracking or dispatch issue,
    audit it and confirm lifecycle readiness: source/plan snapshots, complete
    state, latest `role=session`, validation, review, and dashboard links are
    present. If not, stop and route to the matching plan delivery workflow.
11. Merge with `forge-cli --provider gitlab pr merge "$MR_NUMBER"` unless
    `--no-merge` is the requested final stop.
12. After merge, if the MR description referenced a linked tracking or dispatch
    issue and `--no-closeout` was not supplied, run `plan-issue record close`
    with the correct profile. On gate fail, leave the issue open with the
    blocked code surfaced by `plan-issue` and route to the matching closeout
    skill.
13. Record the MR URL, labels, pipeline/check evidence, review outcome, merge
    commit, chained closeout result, and any fallback used in delivery notes.

## Boundary

`forge-cli` owns provider create, checks wait, ready, and merge calls.
`plan-issue record` owns linked issue lifecycle closeout. The workflow owner
owns scope judgment, code changes, local validation, pre-merge gate decisions,
repair loops, delivery outcome comments, and any temporary provider fallback
decision. MR-description auto-close remains banned for issue-backed
plan records.
