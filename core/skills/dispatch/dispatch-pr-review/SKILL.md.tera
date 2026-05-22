---
name: dispatch-pr-review
description:
  Review dispatch-lane PRs with retained evidence, provider comments, and plan-issue row synchronization.
---

# Dispatch PR Review

## Contract

Prereqs:

- `forge-cli`, `plan-issue`, `review-evidence`, and `review-specialists` are
  installed from released nils-cli packages and available on `PATH`.
- Target PR, issue, task ID or sprint lane, and review decision are known.
- Provider auth is available for live PR comments, edits, merges, and issue row
  synchronization.

Inputs:

- PR number, issue number, task ID or sprint/PR group, review decision, review
  evidence directory, optional corrected PR body, and merge/close method.
- Optional review comment body file and issue note.
- Optional `code-review-specialists` report for broad, high-risk,
  security-sensitive, migration-heavy, or API-contract-heavy diffs.

Outputs:

- Review evidence record validated through `review-evidence`.
- Review evidence records `code-review-specialists` as `used` or `skipped`
  with reason/evidence for every decision.
- PR comment, PR body update, merge, close, or follow-up request through
  `forge-cli`.
- Issue task row synchronized through `plan-issue link-pr` or sprint commands.

Failure modes:

- Required review evidence is missing or fails verification.
- PR comment/body/merge operations fail through `forge-cli`.
- Issue row selector is ambiguous or `plan-issue link-pr` rejects the update.
- Review requests try to start a replacement lane without explicit reassignment.
- Specialist findings are treated as an automatic merge/close/follow-up decision
  instead of supplemental evidence for main-agent review judgment.

## Entrypoint

Record and verify review evidence:

```bash
review-specialists scope --base "$BASE_REF" --format json
review-evidence init --out "$REVIEW_OUT" --subject "PR #$PR_NUMBER"
review-evidence record-validation --out "$REVIEW_OUT" --command "$COMMAND" --status pass
review-evidence verify --out "$REVIEW_OUT" --format json
```

Comment on the PR:

```bash
forge-cli pr comment "$PR_NUMBER" \
  --provider github \
  --repo "$OWNER_REPO" \
  --body-file "$REVIEW_COMMENT" \
  --format json
```

Synchronize the issue row after the review decision:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

Merge or close only after review evidence and issue synchronization are ready:

```bash
forge-cli pr merge "$PR_NUMBER" --provider github --repo "$OWNER_REPO" --method squash
forge-cli pr close "$PR_NUMBER" --provider github --repo "$OWNER_REPO"
```

## Workflow

1. Read the PR, linked issue row, task scope, and current review evidence.
2. For broad, high-risk, security-sensitive, migration-heavy, or
   API-contract-heavy diffs, run `code-review-specialists` before the decision
   as supplemental read-only evidence. Keep the specialist workflow read-only;
   it never merges, closes, posts provider comments, or requests follow-up by
   itself.
3. Apply the review rubric and record findings, selected specialist findings,
   skip rationale, or validation in
   `review-evidence`.
4. Use the shared disposition vocabulary from
   `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`
   for meaningful review items.
5. Use `forge-cli pr comment` for follow-up requests or approval evidence.
6. Use `forge-cli pr edit` when PR body hygiene must be repaired before merge.
7. Use `plan-issue link-pr` or sprint commands to keep row state aligned with
   the review outcome.
8. Merge, close, or request follow-up through `forge-cli` according to the
   review decision.
9. Record exact PR comment URLs and issue-state evidence in the dispatch
   session.

## Boundary

`review-evidence` owns durable review records. `forge-cli` owns provider PR
comment/edit/merge/close operations. `plan-issue` owns issue row state. The
skill body owns review judgment, lane-continuity decisions, specialist
used/skipped rationale, and whether a finding blocks merge.
