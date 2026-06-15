# forge-cli pr deliver reports valid test-first evidence as unreadable

## Status

- Status: wontfix
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

Update (2026-06-16): reproduced and resolved as operator misuse, not a
`forge-cli` defect. `forge-cli pr deliver --test-first-evidence` takes a DIR
(clap `value_name = "DIR"`, `crates/forge-cli/src/cli.rs`); the test-first gate
calls `verify_dir(<dir>)`, which reads `<dir>/test-first-evidence.json`. The
recorded repro passed the JSON *file* (`--test-first-evidence
<test-first-evidence.json>`) while `verify` was run against the *directory*
(`--out <evidence-dir>`), so the gate read `<file>/test-first-evidence.json` and
returned exactly the observed `test_first_evidence_unreadable` ("Not a
directory"). Verified locally: passing the verify-clean directory succeeds;
passing the JSON file fails with that error. The correct invocation is
`--test-first-evidence "$EVIDENCE_DIR"`. Resolved `wontfix`; no `forge-cli`
change is warranted.

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

None — resolved as operator misuse (reproduced 2026-06-16): forge-cli --test-first-evidence takes the verify-clean DIR, not the JSON file; no forge-cli change needed.

## Archive

- Archived: 2026-06-16
- Reason: operator misuse; reproduced 2026-06-16 (forge-cli --test-first-evidence takes a DIR)
- Durable link: `https://github.com/graysurf/agent-runtime-kit/issues/394`
