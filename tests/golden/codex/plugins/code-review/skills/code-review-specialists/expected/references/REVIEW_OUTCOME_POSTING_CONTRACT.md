# Review Outcome Posting Contract

Use this contract when a review workflow has a finalized review outcome body and
needs provider-visible PR/MR activity. `forge-cli pr review` is the only provider
primitive for this path.

Reviewer subagents remain read-only. The owning parent, dispatch, or delivery
workflow writes every provider-visible outcome comment after it has received
subagent output, synthesized findings, dispositioned them, and chosen the review
decision.

For delivery review gates, the default provider-visible progress model is:

1. After each reviewer lens returns, the parent posts a compact single-lens
   outcome with that lens's bot profile.
2. If the lens blocks delivery, the parent repairs in the delivery branch,
   commits, reruns validation, and reruns the affected lens.
3. The parent posts the follow-up single-lens outcome with the same lens bot
   profile.
4. After all selected lenses pass or are explicitly dispositioned, the parent
   posts one combined owner outcome with `FORGE_BOT_PROFILE=dobi`.

The subagent never calls the provider. This keeps provider credentials in the
parent workflow while still making review progress visible in PR/MR and optional
issue activity.

## Inputs

- `PROVIDER`: `github` or `gitlab`. The snippets below expect this variable to
  be non-empty. To rely on remote auto-detection, remove the whole
  `--provider "$PROVIDER"` pair instead of passing an empty value.
- `OWNER_REPO`: provider repository slug such as `owner/name`.
- `PR_NUMBER`: numeric PR/MR id.
- `REVIEW_DECISION`: `comments-only`, `approve`, or `request-changes`.
- `REVIEW_COMMENT_FILE`: compact outcome comment body.
- `REVIEW_LENS`: the single specialist lens for a lens progress outcome. For
  combined owner outcomes, pass repeated `--lens` flags from the selected lens
  list.
- `REVIEW_BOT_PROFILE`: shell variable resolved from the table below when
  posting exactly one mapped specialist lens. Use `dobi` for combined owner
  outcomes.
- Optional `ISSUE`: tracking or dispatch issue that should receive a compact
  activity mirror.

## Identity

Set `FORGE_BOT_PROFILE` on every `forge-cli pr review` post. Use `dobi` for
combined owner outcomes or unknown-lens owner summaries, and use the mapped
reviewer profile only when the outcome represents exactly one specialist lens:

| Lens | `FORGE_BOT_PROFILE` |
| --- | --- |
| `red-team` | `review-red-team` |
| `testing` | `review-testing-bot` |
| `maintainability` | `review-maintainability` |
| `performance` | `review-performance` |

Copy this resolver into shell entrypoints that need `REVIEW_BOT_PROFILE`:

```bash
case "$REVIEW_LENS" in
  red-team) REVIEW_BOT_PROFILE=review-red-team ;;
  testing) REVIEW_BOT_PROFILE=review-testing-bot ;;
  maintainability) REVIEW_BOT_PROFILE=review-maintainability ;;
  performance) REVIEW_BOT_PROFILE=review-performance ;;
  *) unset REVIEW_BOT_PROFILE ;;
esac
```

Do not wrap `forge-cli` with `env`, `command`, or `exec`; those forms bypass the
local forge-cli shell wrapper that mints the GitHub App token. Pass identity
selection as an inline assignment immediately before `forge-cli` instead.

Do not let a reviewer subagent post directly. If an explicit reviewer profile
cannot mint a token or cannot write the provider comment, stop and surface the
provider error instead of retrying as the user.

## Command

Single known specialist lens progress outcome:

```bash
case "$REVIEW_LENS" in
  red-team) REVIEW_BOT_PROFILE=review-red-team ;;
  testing) REVIEW_BOT_PROFILE=review-testing-bot ;;
  maintainability) REVIEW_BOT_PROFILE=review-maintainability ;;
  performance) REVIEW_BOT_PROFILE=review-performance ;;
  *) unset REVIEW_BOT_PROFILE ;;
esac

FORGE_BOT_PROFILE="$REVIEW_BOT_PROFILE" \
  forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
    --repo "$OWNER_REPO" \
    --decision "$REVIEW_DECISION" \
    --comment-file "$REVIEW_COMMENT_FILE" \
    --lens "$REVIEW_LENS" \
    --format json
```

Combined owner outcome after all lens progress outcomes are resolved:

```bash
FORGE_BOT_PROFILE=dobi \
  forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
    --repo "$OWNER_REPO" \
    --decision "$REVIEW_DECISION" \
    --comment-file "$REVIEW_COMMENT_FILE" \
    --lens testing \
    --lens maintainability \
    --format json
```

Add issue mirroring only when an owning tracking or dispatch issue should show a
compact activity breadcrumb:

```bash
--issue "$ISSUE" --mirror-issue
```

The issue mirror records the PR/MR review URL and metadata. It does not duplicate
the full review body.

Always set `FORGE_BOT_PROFILE=dobi` for combined or default-owner posts. Only
the single-lens branch should set a reviewer profile for one command.

## Read-Back

For live bot-profile smoke tests, read the created comment back from the
provider and confirm its author before declaring the identity path verified.
