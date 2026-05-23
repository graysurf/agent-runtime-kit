# plan-issue v0.17.7 leaks plan-issue-record-payload JSON fence into every rendered comment and collapses state-comment markdown content

## Status

- Status: open
- First observed: 2026-05-24
- Area: plan-issue record contract; `dispatch:create-plan-tracking-issue` and any skill that consumes `plan-issue record open` output
- Severity: medium
- Source upstream PRs: sympoies/nils-cli#453 (v2 marker collapse + audit/dashboard rewrite), #454 (live record open/post/close + strict v2 gate); upstream check pending — payload-fence rendering may have shipped in either
- Source upstream release: sympoies/nils-cli v0.17.7
- Source local context: `docs/source/nils-cli-surface.md` is pinned at `v0.17.7`; host `agent-runtime --version` is aligned at `0.17.7`. The previous v2 marker migration (inbox case `plan-issue-v2-marker-collapse-drift`, now archived) covered the flag/schema breaks but did not catch this rendering regression because the affected comments were no longer being produced under the v1 path that existing tests still exercised.

## Signal

`plan-issue record open --profile tracking` under v0.17.7 renders every
comment (source, plan, state) with two visible artifacts that older
runs did not carry:

1. **Trailing `plan-issue-record-payload` JSON code-fence.** Every
   comment ends with a markdown fenced block:

   ```text
   ```plan-issue-record-payload
   {
     "schema": "plan-issue-record.payload.v2",
     "role": "source" | "plan" | "state",
     ...
   }
   ```
   ```

   The block is rendered verbatim in the GitHub issue UI as a literal
   JSON snippet sitting under the `<details>` block, polluting every
   comment with ~10–30 lines of machine payload. Pre-v0.17.7 renders
   embedded the same data inside the `<!-- plan-issue-record:v2 -->`
   HTML comment marker, invisible in the rendered view.

2. **State comment markdown body collapse.** The state comment used to
   inline the bundle's `*-execution-state.md` content beneath the
   marker (see graysurf/agent-runtime-kit#79 comment-4526114549 for
   the prior shape — full Execution State / Validation Plan / Task
   Ledger / Session Log / Validation / Notes sections inlined). Under
   v0.17.7 the state comment body is reduced to:

   ```text
   <!-- plan-issue-record:v2 role=state profile=tracking -->

   ## Execution State

   - Profile: tracking

   Initial execution state seeded by `plan-issue record open`.

   ```plan-issue-record-payload
   { ... full JSON tasks array ... }
   ```
   ```

   The execution-state markdown content is no longer inlined; readers
   of the issue only see the payload JSON unless they go read the
   bundle file separately.

The audit envelope itself parses correctly from the visible JSON block
(`plan-issue record audit --profile tracking` returns
`missing_required:[]`, `recognized_count:3`), so the regression is
purely cosmetic in terms of contract — but a tracking issue is a
human-facing surface and the new rendering visibly diverges from every
prior tracking issue in this repo (#43, #50, #53, #55, #58, #64, #67,
#69, #73, #79; all v2 markers, none carry the visible JSON fence).

## Impact

- Every new plan-tracking or dispatch-plan issue created on v0.17.7
  ships with a visually broken render: three comments each carrying a
  redundant JSON tail; the state comment loses its markdown narrative
  surface.
- The user explicitly flagged the regression on
  graysurf/agent-runtime-kit#83
  (`"為什麼 留言那些會帶到 json 的輸出？ 你可以參考別的 tracking issue
  應該都沒有這些格式錯誤的問題"`). Manual patching of #83's three
  comments via `gh api -X PATCH issues/comments/<id>` was required to
  restore the prior render shape.
- `dispatch:create-plan-tracking-issue` and any sibling skill that
  surfaces a freshly opened tracker (including
  `dispatch:deliver-plan-tracking-issue` and
  `dispatch:deliver-dispatch-plan`) ship the same defect end-to-end;
  no skill body has noticed because the runtime-smoke fixtures
  exercise marker round-trip via audit but do not assert on the
  comment body shape.
- `tests/golden/` snapshots for the tracking and dispatch profiles
  cover rendered SKILL bodies but not live comment output, so the
  defect surfaces only in real provider mutation.

## Evidence

- Raw record: no `skill-usage` record exists; observation was made
  directly during user-driven `dispatch:create-plan-tracking-issue`
  invocation against graysurf/agent-runtime-kit#82 (now closed) which
  created graysurf/agent-runtime-kit#83.
- Cross-issue comparison: `for N in 83 79 73 69 67 64; do COUNT=$(gh
  issue view "$N" --repo graysurf/agent-runtime-kit --json comments
  --jq '[.comments[] | select(.body | contains("plan-issue-record-payload"))] | length'); echo "issue #$N: $COUNT"; done`
  produced `83: 3`, all others `0`.
- Manual fix audit: after `gh api -X PATCH
  repos/graysurf/agent-runtime-kit/issues/comments/<id>` against the
  three #83 comments to strip the JSON fence and re-inline the
  execution-state markdown into the state comment, `plan-issue record
  audit --profile tracking --comments-json <fresh-dump>` returned
  `missing_required:[]`, `unsupported_markers:[]`, `recognized_count:3`.
  The HTML comment marker alone is sufficient for audit; the visible
  JSON fence is not required for the contract.
- Host version: `nils-plan-issue-cli 0.17.7`; surface pin
  `docs/source/nils-cli-surface.md:8` is `v0.17.7`.
- Comparison comment URLs (prior shape):
  https://github.com/graysurf/agent-runtime-kit/issues/79#issuecomment-4526114549
  (state comment with full inlined markdown, no JSON fence).
- Current defect comment URLs (pre-patch):
  https://github.com/graysurf/agent-runtime-kit/issues/83#issuecomment-4526209675,
  https://github.com/graysurf/agent-runtime-kit/issues/83#issuecomment-4526209700,
  https://github.com/graysurf/agent-runtime-kit/issues/83#issuecomment-4526209725.
- Post-patch comment shape recorded in the same comment URLs after
  the API edit at `2026-05-23T18:37:48–49Z`.

## Current Workaround

After every `plan-issue record open --profile tracking|dispatch`
invocation under v0.17.7:

1. `gh api repos/<owner>/<repo>/issues/<n>/comments --jq '.[] | .id'`
   to list the three new comment IDs.
2. For each, fetch `.body`, strip the trailing
   `\n```plan-issue-record-payload\n.*\n```\s*$` block, and
   `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -f
   body=@<stripped>` it back.
3. For the state comment, additionally rewrite the body to inline
   the bundle's `*-execution-state.md` content beneath the
   `<!-- plan-issue-record:v2 role=state -->` marker (matching the
   shape of pre-v0.17.7 issues such as #79's state comment).
4. Re-audit with `plan-issue record audit --profile tracking
   --comments-json <fresh-dump>` to confirm `missing_required:[]`,
   `recognized_count:3`.

This workaround is in-band — no skill modification required — but
every operator who opens a tracker on v0.17.7 has to apply it.

## Promotion Criteria

Close this entry (promote to a fix and archive) when **either** of the
following is true:

- Upstream `sympoies/nils-cli` ships a release that removes the
  visible `plan-issue-record-payload` code-fence from rendered
  comments (folding the payload back into the HTML marker or behind a
  `--include-payload-fence` opt-in flag) and restores the state
  comment's inlined markdown body, and `docs/source/nils-cli-surface.md`
  is rolled forward to that release.
- An in-repo wrapper around `plan-issue record open` (e.g. in the
  `dispatch:create-plan-tracking-issue` skill body) post-processes
  the rendered comments to strip the JSON fence and rebuild the
  state comment from the bundle file, and a runtime-smoke probe
  asserts the rendered comment shape matches the pre-v0.17.7 shape.

## Prevention Rule

**When bumping `docs/source/nils-cli-surface.md` past a nils-cli
release that touches `plan-issue record open|post`, dry-run the
opener against a throwaway repo / draft issue and visually inspect
the rendered source / plan / state comments end-to-end.** If the
rendered shape diverges from the prior tracker pattern (compare
against the most-recent `Plan tracker:` issue in this repo), block
the bump on a same-PR migration of the affected skills.

This is the same prevention rule the previous v2 marker collapse
case landed (`plan-issue-v2-marker-collapse-drift`), expanded from
"check flag / schema rejection" to "check rendered output shape."

## Next Action

- File an upstream issue against `sympoies/nils-cli` describing the
  visible payload fence and the state-comment content collapse;
  link this inbox entry, comparison URLs, and the manual patch
  workaround. Cross-link the resulting upstream issue back here.
- Until upstream resolution, document the workaround above in the
  `dispatch:create-plan-tracking-issue` skill body so future agents
  apply it without re-discovering the regression.
