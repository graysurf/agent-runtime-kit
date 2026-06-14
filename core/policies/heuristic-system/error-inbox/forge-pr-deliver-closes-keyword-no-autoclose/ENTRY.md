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

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-14)
- PR: `graysurf/agent-runtime-kit#343` (merged `1db8fa8`, squash).
- Issue: `graysurf/agent-runtime-kit#341` — body keyword `Closes #341` present,
  not auto-closed on merge; closed manually post-merge.
- Cause **unconfirmed**: either (a) `forge-cli pr create/deliver` does not
  establish the GitHub "linked issue" (Development) relationship that body
  closing-keywords drive, or (b) GitHub squash-merge auto-close timing/edge —
  i.e. it might have been latency that the manual close pre-empted. A second
  occurrence is needed to distinguish.

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

Promote once the cause is confirmed on a second occurrence: if it is a forge-cli
linkage gap, file an upstream `sympoies/nils-cli` issue and link it here, then
either fix forge-cli to register the linked-issue relationship or document the
post-merge close-verification step in `deliver-pr`. If it proves to be GitHub
latency only, mark `wontfix` with the timing note.

## Next Action

Watch for recurrence on the next regular issue-backed forge-cli delivery. On the
next occurrence, before any manual close, capture: the PR body as stored on
GitHub, the issue timeline (to see whether a `connected`/`closed` event fired
late), and the merge event timing. Route a confirmed forge-cli gap to an upstream
nils-cli issue.
