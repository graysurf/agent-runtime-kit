# deliver-pr merges past unresolved asynchronous bot review threads

## Status

- Status: open
- First observed: 2026-06-11
- Area: pr-delivery
- Severity: medium

## Signal

The `deliver-pr` merge sequence (`forge-cli pr deliver --no-merge` ->
`pr wait-checks` -> `code-review-pre-merge-gate` -> outcome comment ->
`pr merge`) never reads provider-side review state. `pr wait-checks`
watches CI checks only; the pre-merge gate reviews the local diff
read-only; nothing fetches reviews or review threads from the provider.
Human review surfaces in-session through discussion, so the systematic
blind spot is asynchronous bot reviewers (code-quality bots and
similar), which post review threads minutes after PR creation.

Live repro (sympoies/symphony-board#169): PR created 04:48:29Z,
`github-code-quality[bot]` posted two inline review threads at
04:49:36Z and 04:57:25Z, merge ran 05:01:29Z. The threads were
provider-visible 4-12 minutes before merge and were only found
afterwards, when the user asked why nobody had looked.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-11); the timeline
  above was read back from the GitHub API after merge
  (`pulls/169/comments` + `reviewThreads` GraphQL on
  sympoies/symphony-board).
- `forge-cli pr comments` (v1.0.15) lists the issue-style comment
  stream only; review threads have no forge-cli read surface, so even a
  compliant agent had no released-surface way to sweep them.

## Impact

Every `deliver-pr` merge can silently bypass unresolved bot review
findings. Severity stays medium because human findings still surface
in-session and the missed findings are typically static-analysis-grade,
but the class is systematic: it recurs on every delivery in every repo
with an asynchronous bot reviewer, and silence reads as "no findings".

## Current Workaround

Skill prose (graysurf/agent-runtime-kit PR linked below): `deliver-pr`
now requires a provider review-thread sweep immediately before the
merge call — `gh api graphql` `reviewThreads` on GitHub, `glab api`
discussions on GitLab — with every unresolved thread dispositioned
(repair / reply-and-resolve as accepted / convert to follow-up) before
merge. `code-review-pre-merge-gate` accepts the swept threads as
optional evidence input. Prose depends on agent compliance; the durable
fix is the mechanical fail-closed gate in `forge-cli pr merge`
(sympoies/nils-cli#808).

## Promotion Criteria

Promote after the durable fix or accepted-risk decision is implemented,
validated, and linked from this entry.

## Next Action

Track sympoies/nils-cli#808 (forge-cli mechanical merge gate); archive when it ships and the skill prose switches to the released surface
