# Review Outcome Posting Contract

Use this contract when a review workflow needs provider-visible PR/MR review
activity for either a single-lens specialist report or a combined delivery-owner
outcome. `forge-cli pr review` is the only provider primitive for this path. On
GitHub, pass `--submit-review` so each post is a native pull request review event
(the `#pullrequestreview-` object) authored by the chosen reviewer bot, with
`--decision` mapped to the review event: specialist reports post as `COMMENT`
reviews and the combined delivery-owner outcome posts as an `APPROVE` /
`REQUEST_CHANGES` review. GitLab has no equivalent single review event, so it
omits `--submit-review` and posts an outcome note (provider parity is preserved
by the `SUBMIT_REVIEW` guard in the snippets below).

Reviewer subagents remain read-only. The owning parent, dispatch, or delivery
workflow writes every provider-visible comment. Specialist review comments are
pre-disposition `comments-only` reports posted after one lens returns. Combined
delivery-owner outcomes are post-disposition comments posted after the owner has
synthesized findings, decided repairs or tradeoffs, and chosen the final review
decision.

## Posting order is non-negotiable

A review finding is both work-progress and evidence: it is the cause a fix
commit responds to. Post it the moment the lens that produced it returns —
before repairing, committing, or moving to the next lens. The fix is the reply
to the comment, so the comment must already exist when the fix lands.

Never invert this. Do not repair and commit first and post the comment after. A
comment posted after its fix reads as caused by nothing, inverts the PR/MR
timeline, and is lost entirely if the run stops between the fix and the post.
Posting is not a closing summary of work already done; it is the record that the
finding existed before anyone acted on it.

Only the final combined delivery-owner outcome — the disposition (`approve` or
`request-changes`) — is posted after repairs, because a disposition can only be
decided once the findings it resolves exist. Findings post first as they return;
the disposition posts last.

For delivery review gates, the required posting order is:

1. After each reviewer lens returns, the parent posts a compact single-lens
   specialist review comment with that lens's bot profile.
2. If the lens blocks delivery, the parent repairs in the delivery branch,
   commits, reruns validation, and reruns the affected lens.
3. The parent posts the follow-up specialist review comment with the same lens
   bot profile.
4. After all selected lenses pass or are explicitly dispositioned, the parent
   posts one combined delivery-owner outcome with `FORGE_BOT_PROFILE=dobi`.

The subagent never calls the provider. This keeps provider credentials in the
parent workflow while still making review progress visible in PR/MR and optional
issue activity. Specialist comments report findings and evidence only; the
combined delivery-owner outcome records final dispositions.

## Inputs

- `PROVIDER`: `github` or `gitlab`. The snippets below expect this variable to
  be non-empty. To rely on remote auto-detection, remove the whole
  `--provider "$PROVIDER"` pair instead of passing an empty value.
- `OWNER_REPO`: provider repository slug such as `owner/name`.
- `PR_NUMBER`: numeric PR/MR id.
- `REVIEW_DECISION`: `comments-only`, `approve`, or `request-changes`.
  Specialist review comments use `comments-only`; combined owner outcomes map
  the final delivery decision to `approve` or `request-changes`.
- `REVIEW_COMMENT_FILE`: compact comment body. Use
  `SPECIALIST_REVIEW_COMMENT.md` for specialist reports and
  `DELIVERY_REVIEW_OUTCOME_COMMENT.md` for combined owner outcomes.
- `REVIEW_LENS`: the single specialist lens for a specialist review comment.
  For combined owner outcomes, pass repeated `--lens` flags from the selected
  lens list.
- `REVIEW_BOT_PROFILE`: shell variable resolved from the table below when
  posting exactly one mapped specialist lens. Use `dobi` for combined owner
  outcomes.
- Optional `ISSUE`: tracking or dispatch issue that should receive a compact
  activity mirror.

## Identity

Set `FORGE_BOT_PROFILE` on every `forge-cli pr review` post. Use `dobi` for
combined owner outcomes or unknown-lens owner summaries, and use the mapped
reviewer profile only when the comment represents exactly one mapped specialist
lens:

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
  *) REVIEW_BOT_PROFILE=dobi ;;
esac
```

Unmapped specialist lenses such as `api-contract`, `security`, or
`data-migration` still use the specialist report body and `comments-only`; they
are authored by `dobi-bot` as owner summaries because no dedicated reviewer bot
profile exists for those lenses.

Do not wrap `forge-cli` with `env`, `command`, or `exec`; those forms bypass the
local forge-cli shell wrapper that mints the GitHub App token. Pass identity
selection as an inline assignment immediately before `forge-cli` instead.

Do not let a reviewer subagent post directly. If an explicit reviewer profile
cannot mint a token or cannot write the provider comment, stop and surface the
provider error instead of retrying as the user.

## Command

Native review events are GitHub-only, so guard `--submit-review` on the provider
once and reuse it in both snippets (on GitLab the array is empty and the post
falls back to an outcome note):

```bash
SUBMIT_REVIEW=()
[ "$PROVIDER" = github ] && SUBMIT_REVIEW=(--submit-review)
```

Single known specialist lens report:

```bash
case "$REVIEW_LENS" in
  red-team) REVIEW_BOT_PROFILE=review-red-team ;;
  testing) REVIEW_BOT_PROFILE=review-testing-bot ;;
  maintainability) REVIEW_BOT_PROFILE=review-maintainability ;;
  performance) REVIEW_BOT_PROFILE=review-performance ;;
  *) REVIEW_BOT_PROFILE=dobi ;;
esac

FORGE_BOT_PROFILE="$REVIEW_BOT_PROFILE" \
  forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
    --repo "$OWNER_REPO" \
    --decision comments-only \
    "${SUBMIT_REVIEW[@]}" \
    --comment-file "$REVIEW_COMMENT_FILE" \
    --lens "$REVIEW_LENS" \
    --format json
```

Combined owner outcome after all specialist reports are resolved:

```bash
FORGE_BOT_PROFILE=dobi \
  forge-cli --provider "$PROVIDER" pr review "$PR_NUMBER" \
    --repo "$OWNER_REPO" \
    --decision "$REVIEW_DECISION" \
    "${SUBMIT_REVIEW[@]}" \
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

The issue mirror records the PR/MR review URL and metadata. It does not
duplicate the full review body.

Always set `FORGE_BOT_PROFILE=dobi` for combined or default-owner posts. Only
the single-lens branch should set a reviewer profile for one command.

## Read-Back

For live bot-profile smoke tests, read the created comment back from the
provider and confirm its author before declaring the identity path verified.
