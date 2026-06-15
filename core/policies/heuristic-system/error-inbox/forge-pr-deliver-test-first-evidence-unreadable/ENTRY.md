# forge-cli pr deliver reports valid test-first evidence as unreadable

## Status

- Status: open
- First observed: 2026-06-15
- Area: forge-cli pr deliver
- Severity: medium

## Signal

During `graysurf/agent-runtime-kit` issue #381 delivery, a valid
`test-first-evidence` record was passed to `forge-cli pr deliver` while
adopting existing PR #388 after a rebase/force-push. The same record verified
successfully with `test-first-evidence verify`, but `forge-cli pr deliver`
exited with `test_first_evidence_unreadable` and reported that it could not read
the evidence path.

## Evidence

- Raw record: `evidence/heuristic-pr-deliver-test-first-evidence-unreadable.md`
- Summary: redacted evidence ingested at creation time; raw logs and secrets were stripped before commit.

## Impact

Agents following `deliver-pr` can get blocked after a normal rebase/force-push
even when test-first evidence is complete and readable. The PR can still be
delivered through lower-level `forge-cli pr checks`, `pr ready`, and `pr merge`,
but the delivery macro no longer provides the intended single surface for
adoption and gate execution.

## Current Workaround

Verify the record directly with `test-first-evidence verify`. If it is complete,
continue through the lower-level PR lifecycle surfaces: `forge-cli pr checks`,
`forge-cli pr review-threads`, `forge-cli pr tasks`, `forge-cli pr ready`, and
`forge-cli pr merge`.

## Promotion Criteria

Promote after reproducing the unreadable decision with a small valid
`test-first-evidence` record and either fixing the `forge-cli pr deliver`
readability check or documenting a verified limitation in the delivery skill.

## Next Action

Reproduce with a small valid test-first-evidence record passed to forge-cli pr deliver on an existing PR, then fix or clarify the evidence path/readability check.
