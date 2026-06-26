# Delivery Review Outcome Comment

Use this shared outcome contract after the delivery specialist review gate has
enough information to decide whether delivery can merge, must stop, or can
continue with an accepted residual risk. The owning delivery workflow posts the
outcome through `forge-cli pr review`; `code-review-specialists` stays
read-only.

Disposition vocabulary and reason/evidence rules are canonical in
`references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`.
Provider posting ownership, bot identity, and optional issue mirroring are
canonical in `references/REVIEW_OUTCOME_POSTING_CONTRACT.md`.
Single-lens reviewer bot progress comments use
`references/SPECIALIST_REVIEW_COMMENT.md` instead.
Resolvable GitHub review threads for actionable findings are attached to the
specialist progress comments that first surface those findings, not to the final
combined approval summary.

## Ownership

- `deliver-pr` posts the outcome on the PR/MR before merging through
  `forge-cli pr review`.
- `deliver-plan-tracking-issue` records the PR/MR outcome comment URL in
  issue-hosted session or validation evidence instead of duplicating the full
  report.
- `code-review-specialists` supplies review evidence only. It must not post or
  update live PR/MR comments.

## Timing

- Post one final combined outcome comment after the review and repair pass,
  before final merge/close. Use `FORGE_BOT_PROFILE=dobi` for the combined owner
  outcome.
- If review blocks delivery, post a blocked outcome comment before stopping when
  provider auth and permissions allow it.
- Do not use this format for individual reviewer bot reports. Those comments
  report findings only; the parent/main agent owns the dispositions recorded
  here.
- If outcome posting fails, stop before merge and report the provider command,
  exit status, and retry action. A delivery that requires this contract is not
  complete without the outcome.

## Provider Command

Use the provider-aware primitive for GitHub and GitLab. Follow
`references/REVIEW_OUTCOME_POSTING_CONTRACT.md` for the parent-owned posting
flow, the lens-to-`FORGE_BOT_PROFILE` table, and optional issue mirroring:

```bash
# Native review events are GitHub-only; GitLab posts an outcome note instead.
SUBMIT_REVIEW=()
[ "$PROVIDER" = github ] && SUBMIT_REVIEW=(--submit-review)

FORGE_BOT_PROFILE=dobi forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
  --decision "$REVIEW_DECISION" \
  "${SUBMIT_REVIEW[@]}" \
  --comment-file comment.md \
  --lens testing \
  --lens maintainability
```

Set `REVIEW_DECISION=approve` for `proceed-to-merge` or
`proceed-with-accepted-residual`, and `request-changes` for `blocked`. Use
provider repository flags when local remotes are ambiguous. With `--submit-review`
on GitHub the decision maps to a native pull request review event
(`approve`→`APPROVE`, `request-changes`→`REQUEST_CHANGES`,
`comments-only`→`COMMENT`) authored by the `dobi` reviewer bot; on GitLab the
decision is recorded as outcome-note metadata only (no native approval state).
Use `SPECIALIST_REVIEW_COMMENT.md` with `--decision comments-only` for
non-decisional specialist notes, adding `--thread-file` only when that note
surfaces actionable findings that need owner changes.

## Required Comment Shape

```markdown
<!-- agent-kit:delivery-review-outcome:v1 -->
## Delivery Review Outcome

- Reviewable: PR #123
- Decision: proceed-to-merge | blocked | proceed-with-accepted-residual
- Lenses: testing, maintainability, api-contract
- Validation: scripts/check.sh --all pass
- Provider checks: required checks pass

| Item | Disposition | Reason | Evidence |
| --- | --- | --- | --- |
| Missing edge-case test | fixed-now | Required for behavior coverage. | commit + validation |
| Minor wording note | no-action | N/A | reviewed docs diff |
| Cleanup opportunity | follow-up-linked | Outside this delivery scope. | issue URL |
```

Required fields:

- Marker: `<!-- agent-kit:delivery-review-outcome:v1 -->`
- Reviewable identifier: PR number/URL or MR number/URL.
- Decision: `proceed-to-merge`, `blocked`, or
  `proceed-with-accepted-residual`.
- Lenses used, including the full selected lens set and forced minimum lenses.
- Validation and provider check or pipeline status.
- Findings table. Use a single `none` row when there were no findings or
  residual risks to report.

## Dispositions

Use the shared disposition schema:
`references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`.

Keep the comment compact. Link to detailed specialist reports, validation logs,
issue evidence, or follow-up records instead of pasting long raw review output.
