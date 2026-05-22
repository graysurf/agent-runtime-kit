# Delivery Review Outcome Comment

Use this shared comment contract after the delivery specialist review gate has
enough information to decide whether delivery can merge, must stop, or can
continue with an accepted residual risk. The owning delivery workflow posts the
comment; `code-review-specialists` stays read-only.

Disposition vocabulary and reason/evidence rules are canonical in
`references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`.

## Ownership

- `deliver-github-pr` posts the outcome on the PR before merging.
- `deliver-gitlab-mr` posts the outcome on the MR before merging.
- `deliver-tracking-issue` records the PR/MR outcome comment URL in
  issue-hosted session or validation evidence instead of duplicating the full
  report.
- `code-review-specialists` supplies review evidence only. It must not post or
  update live PR/MR comments.

## Timing

- Post one final outcome comment after the review and repair pass, before final
  merge/close.
- If review blocks delivery, post a blocked outcome comment before stopping when
  provider auth and permissions allow it.
- Do not post every intermediate specialist finding or repair iteration unless
  the user explicitly asks for verbose audit comments.
- If comment posting fails, stop before merge and report the provider command,
  exit status, and retry action. A delivery that requires this contract is not
  complete without the outcome comment.

## Provider Commands

GitHub:

```bash
forge-cli --provider github pr comment "$PR_NUMBER" --body-file comment.md
```

GitLab:

```bash
forge-cli --provider gitlab pr comment "$MR_NUMBER" --body-file comment.md
```

Use provider repository flags when local remotes are ambiguous. Prefer creating
an append-only outcome comment; edit or replace an existing comment only when
the workflow has explicitly identified the previous
`agent-kit:delivery-review-outcome:v1` comment from the same delivery attempt.

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
- Lenses used, including forced minimum lenses.
- Validation and provider check or pipeline status.
- Findings table. Use a single `none` row when there were no findings or
  residual risks to report.

## Dispositions

Use the shared disposition schema:
`references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`.

Keep the comment compact. Link to detailed specialist reports, validation logs,
issue evidence, or follow-up records instead of pasting long raw review output.
