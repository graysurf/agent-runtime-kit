# Review run drifted to fix-then-post; post-before-fix order was buried, not a stated invariant

## Status

- Status: promoted
- First observed: 2026-06-22
- Area: pr-delivery; code-review posting contract
- Severity: low
- Resolved-by: graysurf/agent-runtime-kit PR #463 (docs(code-review): make review posting-order an explicit invariant)

## Signal

On the `deliver-pr` delivery-gate path an agent received specialist review
findings, repaired and committed the fix, and only afterward posted the review
comment to the PR. The skill text already prescribed the opposite order — post
each lens's finding the moment it returns, before repair — but the agent drifted
to fix-then-post under repair momentum. Root cause: the order lived only as a
buried procedural step, framed as the optional-sounding "default
provider-visible progress model", with no rationale and no prohibition of the
inverse — so it read as guidance, not an invariant.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-22)
- User-reported during a live session (2026-06-22): the agent fixes the issue
  and commits, then goes back to post the review-agent comment.
- Pre-fix text: `core/skills/code-review/code-review-specialists/references/REVIEW_OUTCOME_POSTING_CONTRACT.md`
  framed the four-step order as "the default provider-visible progress model";
  `deliver-pr` step 8 and `code-review-pre-merge-gate` step 5 said "before repair
  work starts" only as a numbered step, with no stated reason and no inverse-ban.

## Impact

A review comment posted after its fix inverts the PR/MR timeline (the comment
reads as caused by nothing), weakens the audit trail, and is lost entirely if
the run stops between the fix commit and the post. A review finding is both
work-progress and evidence; deferring it defeats provider-visible progress.
Transferable: the same failure shape applies to any "do X before Y" ordering
(test-first-evidence, commit-before-push) when it is stated only as a step.

## Current Workaround

Resolved — no workaround needed. PR #463 promotes the order to a named,
rationale-bearing invariant: a `## Posting order is non-negotiable` section in
`REVIEW_OUTCOME_POSTING_CONTRACT.md` (post the moment a lens returns, before any
repair/commit; never invert; only the final disposition posts after fixes), the
list header reworded from "the default ... progress model" to "the required
posting order", a lead callout in `code-review-pre-merge-gate`, an explicit
before-step-9 note in `deliver-pr` step 8, and one-line pointers in the
read-only lens skills (`code-review-quick-pass`, `code-review-focused-lens`,
`code-review-follow-up`) and `guided-feature-build` Phase 6.

## Promotion Criteria

Met. The invariant shipped in PR #463 and renders into both products' goldens;
the full 15-position `scripts/ci/all.sh` gate plus `tests/hooks/run.sh` passed.
The durable lesson: when a correct ordering still drifts, state it as a named
invariant with rationale and an explicit inverse-prohibition, not as another
procedural step.

## Related

- `operation-records/async-bot-review-fix-loop/` — sibling review-posting class
  (deliver-time sweep timing + fix-loop recursion); distinct root cause.
- `error-inbox/archive/2026/deliver-pr-merge-misses-bot-review-threads/` —
  sibling deliver-pr review-thread timing case.
- `error-inbox/archive/2026/raw-gh-comment-bypasses-forge-bot-identity/` —
  sibling review-comment posting/identity case.

## Next Action

None — resolved by PR #463 and ready to archive.

## Archive

- Archived: 2026-06-22
- Reason: Resolved by PR #463 — post-before-fix order made a named invariant
- Durable link: `https://github.com/graysurf/agent-runtime-kit/pull/463`
