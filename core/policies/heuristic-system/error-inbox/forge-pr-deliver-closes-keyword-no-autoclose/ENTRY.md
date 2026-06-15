# forge-cli pr deliver: Closes #N did not auto-close linked issue on squash merge

## Status

- Status: open
- First observed: 2026-06-14
- Area: forge-cli
- Severity: medium

## Signal

Delivering `graysurf/agent-runtime-kit` PR #343 via `forge-cli pr deliver
--kind bug ... --no-merge` followed by `forge-cli pr merge 343 --method squash`
did **not** auto-close the linked issue #341, even though the PR body contained a
verbatim `Closes #341` line (confirmed present on the GitHub-stored body via
`gh pr view 343 --json body`). `gh issue view 341` reported `state=OPEN` on two
checks after the merge; the issue had to be closed manually with `forge-cli issue
close 341`.

Host: nils-cli 1.3.1 (`forge-cli 1.3.1`). Merge method: squash. Base: default
branch `main`.

Second occurrence: delivering `sympoies/nils-alfredworkflow` PR #194 through
`forge-cli pr deliver --kind refactor --no-merge` and
`forge-cli pr merge 194 --method squash` left issue #190 OPEN immediately after
the merge even though the rendered PR body contained `Closes #190` and GitHub's
`closingIssuesReferences` for the PR included issue #190. The delivery closed
#190 manually with a closeout comment plus `forge-cli issue close 190`.

Third occurrence: delivering `graysurf/agent-runtime-kit` PR #388 through the
lower-level forge-cli lifecycle after `forge-cli pr deliver` adoption failed,
then `forge-cli pr merge 388 --method squash`, left issue #381 OPEN even though
the GitHub-stored PR body contained `Fixes #381`. The delivery checked issue
state immediately after merge and again about 10 seconds later; both reads
showed OPEN. The issue was then closed manually with a closeout comment plus
`forge-cli issue close 381`.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-14)
- PR: `graysurf/agent-runtime-kit#343` (merged `1db8fa8`, squash).
- Issue: `graysurf/agent-runtime-kit#341` — body keyword `Closes #341` present,
  not auto-closed on merge; closed manually post-merge.
- Evidence: `evidence/nils-alfredworkflow-pr194-no-autoclose.md`
- PR: `sympoies/nils-alfredworkflow#194` (merged `3a8b28d`, squash).
- Issue: `sympoies/nils-alfredworkflow#190` — body keyword `Closes #190`
  present and `closingIssuesReferences` included #190; issue remained open
  immediately after merge and was closed manually post-merge.
- Evidence: `evidence/pr388-no-autoclose.md`
- PR: `graysurf/agent-runtime-kit#388` (merged `ce2c6bd`, squash).
- Issue: `graysurf/agent-runtime-kit#381` — body keyword `Fixes #381` present,
  still open on immediate and delayed post-merge checks; closed manually
  post-merge.
- Cause **unconfirmed**: either (a) `forge-cli pr create/deliver` does not
  establish the GitHub "linked issue" (Development) relationship that body
  closing-keywords drive, or (b) GitHub squash-merge auto-close timing/edge —
  i.e. it might have been latency that the manual close pre-empted. The second
  occurrence showed GitHub did know the closing reference, but manual close still
  happened quickly enough that delayed auto-close processing is not fully ruled
  out.

## Impact

Agents (and skills like `deliver-pr`) that rely on `Closes #N` in a forge-cli PR
body to auto-close the linked issue on merge may instead leave the issue OPEN,
silently breaking lifecycle bookkeeping. Plan-tracking flows already avoid close
keywords (they use `Refs #N` + explicit `record close`), so the exposure is on
regular issue-backed PRs.

## Current Workaround

After a `forge-cli pr merge`, verify the linked issue state and, if still open,
close it explicitly: `forge-cli issue close <N>` (optionally with a comment
linking the merge SHA).

## Promotion Criteria

Promote once the cause is confirmed beyond quick post-merge observation: if it
is a forge-cli linkage / merge-method gap, file an upstream
`sympoies/nils-cli` issue and link it here, then either fix forge-cli or document
the post-merge close-verification step in `deliver-pr`. If it proves to be
GitHub latency only, mark `wontfix` with the timing note.

## Next Action

On the next regular issue-backed forge-cli delivery, if user timing allows, wait
several minutes after merge before manual close and capture: the PR body as
stored on GitHub, `closingIssuesReferences`, the issue state over time, the
issue timeline (to see whether a `connected`/`closed` event fired late), and the
merge event timing. Route a confirmed non-latency gap to an upstream nils-cli
issue.
