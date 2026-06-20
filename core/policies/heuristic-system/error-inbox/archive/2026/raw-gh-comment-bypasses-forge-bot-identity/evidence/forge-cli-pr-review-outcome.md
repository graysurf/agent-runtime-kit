# raw-gh-comment-bypasses-forge-bot-identity promotion evidence

Promotion criteria was met by adding a provider-visible review outcome primitive
that routes through forge-cli instead of raw GitHub comments.

- nils-cli release: https://github.com/sympoies/nils-cli/releases/tag/v1.13.0
- runtime-kit PR: https://github.com/graysurf/agent-runtime-kit/pull/445
- runtime-kit release: https://github.com/graysurf/agent-runtime-kit/releases/tag/v2026.06.21
- review outcome comment posted through `forge-cli pr review`:
  https://github.com/graysurf/agent-runtime-kit/pull/445#issuecomment-4759170014

Runtime-kit skill policy now directs delivery review outcomes through
`forge-cli pr review`, including optional issue mirroring, so agents no longer
need raw `gh` comments for this review-outcome path.

Changed policy surfaces:

- `core/skills/pr/deliver-pr/SKILL.md.tera`
- `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`
- `core/skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`
- `core/skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`

The primitive intentionally posts a durable outcome comment and optional issue
mirror; it does not mutate native provider approval/request-changes state.
