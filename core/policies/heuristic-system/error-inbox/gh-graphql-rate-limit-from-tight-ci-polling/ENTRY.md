# Tight gh CI polling loops exhaust the shared GraphQL rate limit

## Status

- Status: open
- First observed: 2026-06-14
- Area: ci
- Severity: low

## Signal

During a release, a 25s `gh run list` poll loop waited ~10 min for
`release.yml`, then a resume step ran `gh release view --json assets,url`. That
view call failed with `GraphQL: API rate limit already exceeded for user ID
...`. The 5,000/hr GraphQL budget was exhausted by the polling loop (and shared
across all tools/agents on the box), while the REST `core` budget still had
~4,800 remaining.

## Evidence

- Raw record: not captured; manual diagnosis of gh GraphQL rate-limit exhaustion, 2026-06-14
- Evidence: `evidence/rate-limit-and-rest-fallback.md`
- `project-bump-version-tag-release.sh --from-tap` aborted at
  `assert_release_assets_available` (which uses `gh release view --json`,
  GraphQL) with "GitHub Release ... is not available" — a false negative; the
  release was fully published.
- `gh api rate_limit --jq .resources` showed `graphql.remaining = 0` (reset
  ~134s out) while `core.remaining = 4821`.
- Cross-checking the release via REST (`gh api repos/<repo>/releases/tags/<tag>`)
  succeeded immediately — confirmed the release + 8 assets were present.

## Impact

A long tight `gh` poll loop can silently drain the shared GraphQL budget and
make a subsequent GraphQL-backed call (`gh release view`, `gh pr view`,
`gh search`) fail with a misleading "not available" / not-found error rather
than an explicit rate-limit message — risking a wrong conclusion (e.g. "the
release did not publish").

## Current Workaround

- Prefer the harness's background run-completion notifications over tight `gh`
  poll loops where possible.
- When polling is required, widen the interval and gate on the **free**
  `gh api rate_limit` endpoint (it does not consume quota); sleep until
  `graphql.remaining` recovers before the next GraphQL call.
- Cross-check release/asset existence with REST (`gh api
  repos/<repo>/releases/tags/<tag>`, `core` budget) when GraphQL is exhausted.

## Promotion Criteria

Promote when the release/CI-wait helpers either back off on the `rate_limit`
endpoint or route existence checks through REST, so a drained GraphQL budget no
longer surfaces as a false "not available".

## Next Action

Prefer harness run-completion notifications over tight gh poll loops; when
polling is required, gate on the free rate_limit endpoint and fall back to REST.
