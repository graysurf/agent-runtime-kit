# skill-usage record-* concurrent writes can drop or duplicate validation entries

## Status

- Status: promoted
- First observed: 2026-06-06
- Area: skill-usage CLI; retained evidence record mutation concurrency
- Severity: medium

## Signal

- During a `deliver-pr` closeout for `sympoies/nils-cli#782`, two
  `skill-usage record-validation` commands were launched in one parallel tool
  call against the same `--out` directory.
- Both commands returned success, but an immediate `skill-usage show` did not
  contain both new validation entries. The final record had to be repaired by
  re-running the writes serially and ended with a duplicated smoke validation.
- This suggests the `record-*` mutation path is read/modify/write without a
  per-record lock or compare-and-swap guard.

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/sympoies__nils-cli/20260606-123919-skill-usage/skill-usage.record.json`
- Summary: linked `skill-usage.record.v1` envelope; raw runtime details remain in the evidence location.
- Upstream finding filed: graysurf/plan-tracking-testbed#66 (2026-06-12).

## Impact

Evidence records can silently lose, duplicate, or reorder entries when agents
parallelize writes to the same `skill-usage` record. This is easy to trigger
because the runtime encourages parallel tool calls for independent work, while
record mutation needs per-output serialization.

## Current Workaround

Serialize all `skill-usage record-*` mutations for a given `--out` directory.
Use parallel calls only for read-only evidence commands or for writes to
independent record directories.

## Promotion Criteria

Promote after `skill-usage` either uses file locking / atomic update semantics
for record mutations, or the skill/policy layer includes an explicit guard
against same-record parallel writes. Validation should cover two concurrent
`record-validation` calls and prove both entries are retained or one call fails
cleanly.

## Next Action

None; fixed by sympoies/nils-cli#828 (merge
d2dfbdc2d8a4f44f2cc2e0cd4903e1d1ee39541a), and tracker finding
graysurf/plan-tracking-testbed#66 is closed. Validation added
skill_usage_serializes_concurrent_record_mutations; local-fast and PR CI
passed.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/828`

## Archive

- Archived: 2026-06-13
- Reason: Fixed in nils-cli v1.1.0 and consumed by agent-runtime-kit v2026.06.13
- Durable link: `https://github.com/sympoies/nils-cli/pull/828`
