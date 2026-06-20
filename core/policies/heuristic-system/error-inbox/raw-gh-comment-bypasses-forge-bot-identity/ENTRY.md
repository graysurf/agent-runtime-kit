# Free-form lifecycle/review comments via raw gh bypass the forge-bot wrapper and post as graysurf instead of the bot

## Status

- Status: open
- First observed: 2026-06-20
- Area: forge-bot identity routing; gh issue/pr comment posting
- Severity: low

## Signal

A free-form "Post-merge specialist review" comment was posted to a tracking
issue as the `graysurf` USER, while every structured `plan-issue-record:v2`
lifecycle comment on the same issue (source / plan / state / session /
validation / review / closeout) was posted as the `dobi-bot[bot]` BOT.

Root cause: the forge-bot wrapper that routes provider identity
(`_lib/shared/env/30-forge-bot.zsh` + `_lib/shared/bin/_forge-identity.zsh` in
graysurf/local-scripts) only intercepts the `forge-cli` command — a zsh
function plus the `FORGE_CLI_BIN` subprocess router. Its default verb table
routes `issue comment` / `pr comment` to the BOT. But a free-form review
summary posted via raw `gh issue comment` / `gh api .../comments` never reaches
the wrapper: raw `gh` uses the ambient `gh auth` token (graysurf's PAT), so it
posts as graysurf. The structured records went through `forge-cli` → bot; the
prose summary went through raw `gh` → graysurf. Same review, two identities,
split purely by which tool posted it.

This contradicts the wrapper's stated intent ("intermediate lifecycle
comments/edits = bot"). It is also a guardrail hole: the AGENT_HOME hook blocks
`gh pr create` / `glab mr create`, but does NOT block `gh issue comment` /
`gh pr comment` / `gh api .../comments`, so comment-posting silently bypasses
bot routing with no warning.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-20)
- Public refs: `sympoies/symphony-board#305` — comment `4757616059` (graysurf,
  prose `## Post-merge specialist review`, no `plan-issue-record` marker,
  11:45:11Z) vs comment `4757616879` (dobi-bot[bot], structured
  `plan-issue-record:v2 role=review`, 11:45:25Z, +14s).
- The bot's `role=review` record minted successfully 14s later, so bot token
  minting was healthy at that moment — this rules out a `forge-cli`
  bot-mint-failure fallback (which would also warn to stderr) and confirms the
  prose comment went through a non-`forge-cli` path.

## Impact

Attribution / cosmetic only — no security or data impact, and the comment
content is correct. But it is systemic: it recurs in any session where an agent
posts a free-form review/status/lifecycle comment via raw `gh` instead of
`forge-cli`, across every repo that uses the bot wrapper. Result: inconsistent
author identity in issue/PR timelines (some lifecycle comments bot, some user),
which muddies "who/what acted" history and can read as the human having posted
machine-generated review prose.

## Current Workaround

Post free-form lifecycle/review comments through a bot-governed path instead of
raw `gh`:

- `forge-cli issue comment …` / `forge-cli pr comment …` — default-routes to
  the bot via the wrapper; or
- `GH_TOKEN="$(forge-bot-token)" gh issue comment …` — the explicit raw-gh
  pattern documented in `30-forge-bot.zsh` (mints an installation token for the
  repo owner).

To deliberately keep a comment as graysurf, make it explicit: `FORGE_AS=user
forge-cli issue comment …` — an intentional choice, not an accident of tool
selection.

## Promotion Criteria

Promote when the bot-routing guardrail is extended to cover comment-posting:
either the AGENT_HOME hook that blocks `gh pr create` / `glab mr create` also
intercepts/redirects `gh issue comment` / `gh pr comment` /
`gh api .../comments`, or a skill-policy note explicitly directs free-form
lifecycle/review comments through `forge-cli` (or `forge-bot-token` + gh). Link
the hook/policy change from this entry.

## Next Action

None now — deferred by the user (observed but not fixing this turn). Revisit
when next touching the forge-bot hook/guardrail or the comment-posting
convention; decide between a hook extension and a skill-policy note. Leave
`Cluster` unset until a sibling identity-routing gap appears.
