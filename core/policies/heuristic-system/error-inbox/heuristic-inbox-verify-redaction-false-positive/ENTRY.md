# heuristic-inbox verify sk- secret pattern false-positives on hyphenated identifiers

## Status

- Status: open
- First observed: 2026-06-01
- Area: heuristic-inbox verify (redacted-secret scan)
- Severity: low

## Signal

The redacted-secret scan used by `heuristic-inbox verify --strict` matches the
OpenAI-style key pattern `sk-[A-Za-z0-9_-]{16,}` as a raw substring with no
leading boundary. It therefore fires inside ordinary hyphenated identifiers that
merely contain that substring mid-word, reporting a spurious
`body_token_pattern` violation.

> Note: the exact triggering string is deliberately NOT reproduced verbatim in
> this entry, because writing it would trip the very pattern this finding is
> about and make this entry itself fail `verify --strict`. The full literal lives
> in the upstream issue (outside the scan).

## Evidence

- Raw record: not captured (live diagnosis 2026-06-01 during the PR #234
  closeout sweep, while strict-verifying `workspace-partial-bump-floor-probe-drift`).
- Upstream issue (full literal repro): `sympoies/nils-cli#740`.
- Shape of the repro: an ENTRY body references a real dated plan-folder slug
  whose tail forms the literal `sk-` followed by 16+ word characters (a
  `task-ledger` / `durability` style name). `verify --strict` then returns a
  `{"kind":"body_token_pattern", "message":"body matches redacted-secret pattern
  'sk-[A-Za-z0-9_-]{16,}'"}` violation, because `sk-` is matched mid-word with no
  leading boundary.
- Versions: heuristic-inbox 1.0.0 (v1.0.0).

## Impact

Legitimate content (plan names, branch names, any token whose tail forms
`sk-` + 16+ word chars) fails strict verify and would block archive / CI
strict-verify of that case, masking real findings behind a spurious
secret-pattern hit.

## Current Workaround

No clean workaround for real paths that contain the substring. In practice it is
contained because the pattern is enforced only by `verify --strict`; the
`archive` readiness gate does not flag it (so `workspace-partial-bump-floor-probe-drift`
archived cleanly despite the false positive). See sibling finding
`heuristic-inbox-archive-cwd-destination`.

## Promotion Criteria

Promote when `sympoies/nils-cli#740` adds a leading boundary
(`(?<![A-Za-z0-9_-])sk-...` or equivalent) so the pattern only matches a real key
token, the same boundary fix is applied to sibling short-prefix secret patterns,
and it is validated against the plan-folder case captured in `#740`.

## Next Action

Track `sympoies/nils-cli#740`; promote and archive this entry once the upstream
boundary fix ships and is verified.
