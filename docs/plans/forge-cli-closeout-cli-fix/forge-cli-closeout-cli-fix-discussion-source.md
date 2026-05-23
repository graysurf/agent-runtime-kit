# Closeout CLI Documentation Fix Discussion Source

- Status: ready for plan execution
- Date: 2026-05-23
- Source: post-merge follow-up from PR #71
  (`feat(skills): chain matching closeout into deliver-* skills`) where
  the Sprint 3.2 specialist review surfaced two `api-contract` info
  findings against the `forge-cli` invocations referenced in both the
  existing canonical closeout skills and the new chained-closeout
  blocks. The findings were tagged `no-action / pre-existing` in the
  PR #71 delivery review outcome and deferred to a follow-up.
  Subsequent dry-run verification against `forge-cli 0.17.6` confirmed
  both are real CLI rejections, not docs drift.
- Intended next step: ship a small follow-up PR that removes the
  `--reason completed` flag from every `forge-cli issue close`
  invocation in `core/skills/` and switches the `--comments-json`
  source from `forge-cli issue view --format json` to a `gh|glab
  issue view --json body,comments` substitute, so the documented
  closeout sequence matches what `forge-cli 0.17.6` actually accepts.
  Re-exercise the chained closeout against this follow-up's own
  tracking issue to confirm the fix is end-to-end correct.

## Execution

- Recommended plan: docs/plans/forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-plan.md
- Recommended execution state: docs/plans/forge-cli-closeout-cli-fix/forge-cli-closeout-cli-fix-execution-state.md

## Purpose

The deliver-* chained closeout merged in PR #71 (squash `de44f80`)
documents a closeout sequence whose `forge-cli` invocations were
inherited from the pre-existing canonical closeout skills. Two of
those invocations are wrong under the current `forge-cli 0.17.6`
surface, and the same pattern is now mirrored across both the
canonical closeout skills and the four deliver-* skill bodies.

The chained closeout that actually closed issue #67 succeeded only
because I deviated from the documented commands at run time — I used
`gh issue view --json body,comments` instead of `forge-cli issue
view --format json`, and I dropped the `--reason completed` flag
from `forge-cli issue close`. A second operator following the
documented sequence verbatim would hit two `unknown-subcommand` exits
back-to-back.

This follow-up brings the documented commands in line with the actual
CLI surface so future invocations work without deviation.

## Confirmed Facts

- [F1] `forge-cli issue close --reason completed --dry-run` (forge-cli
  0.17.6) returns
  `ok=false, code=unknown-subcommand, message="unexpected argument '--reason' found"`,
  exit code 64. The same call without `--reason` succeeds with
  backend plan `gh issue close <id>`.
- [F2] `forge-cli issue view <id> --format json --dry-run` shows the
  backend plan
  `["gh","issue","view","<id>","--json","number,url,state,title,labels,assignees,body"]`.
  The JSON envelope's `.data` object has 8 keys
  (`assignees, body, labels, number, provider, state, title, url`)
  and **no** `comments` field. Feeding the file to
  `plan-issue record audit|closeout-gate --comments-json` therefore
  resolves to "no comments present".
- [F3] `gh issue view <id> --repo <owner/repo> --json body,comments`
  returns an object with `body` (string) and `comments[]` (array of
  comment objects). `plan-issue record ... --comments-json`'s
  documented input shape (`comments` field OR raw array) accepts
  this payload directly.
- [F4] The same `--reason completed` literal occurs **18 times**
  across `core/skills/` source `.tera` files and the rendered
  `tests/golden/{codex,claude}/` expected/SKILL.md snapshots. The six
  source files are:
  `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`,
  `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`,
  `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`,
  `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`,
  `core/skills/pr/deliver-github-pr/SKILL.md.tera`,
  `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`.
- [F5] The four `deliver-*` SKILL bodies added in PR #71 explicitly
  conflate the `forge-cli issue view --format json` output with
  `--comments-json`; the two canonical closeout skills use distinct
  variables (`$ISSUE_JSON` for the view file, `$ISSUE_COMMENTS_JSON`
  passed to audit) but leave the derivation unspecified. Both shapes
  fail when an operator follows the documented commands verbatim.
- [F6] The Sprint 3.5 chained closeout against issue #67 used the
  working alternative (`gh issue view ... --json body,comments` and
  `forge-cli issue close ... --format json` without `--reason`) and
  succeeded; issue #67 closed at 2026-05-23T14:28:04Z with the
  `tracking-issue-closeout:v1` comment present.
- [F7] `forge-cli` 0.17.6 has no `--include-comments` (or equivalent)
  on `forge-cli issue view`. There is no comments-aware view
  subcommand exposed in `forge-cli issue --help`.
- [F8] `glab issue view --comments` exists on the GitLab side per the
  glab CLI surface, so the GitLab substitute is provider-symmetric
  with the GitHub substitute via `gh issue view --json body,comments`.

## Decisions

1. Drop `--reason completed` from every `forge-cli issue close`
   invocation in `core/skills/`. The implicit backend (`gh issue
   close <id>` / `glab issue close <id>`) is what already runs in
   practice; no behavior change at the provider level.
2. Switch the `--comments-json` source in every closeout sequence
   block from `forge-cli issue view --format json` to a `gh issue
   view --json body,comments` substitute on the GitHub side and a
   `glab issue view --comments` substitute on the GitLab side. Keep
   `forge-cli issue view --format json` available for body-only
   needs in the same block.
3. Tighten the variable derivation in all six skill bodies so that
   `$ISSUE_BODY` and `$ISSUE_COMMENTS_JSON` (or equivalent names)
   are explicitly produced by the commands above the audit /
   closeout-gate calls. No more underspecified handoffs.
4. Do not touch the `forge-cli` CLI itself in this PR. The longer-term
   fix is to add `forge-cli issue view --include-comments` in nils-cli;
   that lives in `sympoies/nils-cli`, not in `agent-runtime-kit`, and
   is tracked as out-of-scope here.
5. Refresh the eight `tests/golden/{codex,claude}/plugins/{dispatch,pr}/`
   expected/SKILL.md snapshots after the source edits so
   `scripts/ci/all.sh` position 4 (`git diff --exit-code tests/golden/`)
   stays clean on the pre-push hook.
6. Re-exercise the chained closeout end-to-end against this PR's own
   tracking issue. The fix is correct when the new follow-up issue
   closes through the (corrected) `deliver-github-pr` Step 10 path
   without any manual command substitution.

## Open Questions

- Should the GitLab substitute use `glab issue view --comments` or
  build the equivalent JSON from `glab issue view --output json`?
  Lean toward `--comments` for symmetry with the GitHub line; will
  finalize during the Sprint 1 edits.
- Should the canonical closeout skills (`plan-tracking-issue-closeout`,
  `dispatch-plan-closeout`) carry a more prescriptive Entrypoint block
  now that we're touching them, or keep the variables underspecified
  and only tighten the deliver-* blocks? Lean toward tightening both
  while we have the file open.

## Out Of Scope

- Adding a comments-aware view to `forge-cli` itself (tracked
  separately under nils-cli).
- Reworking the closeout marker contract or the `plan-issue record`
  command shapes.
- Touching `close-github-pr` / `close-gitlab-mr` (those skills do not
  drive issue closeout and are not affected by the two findings).
- Any change to the merge or audit logic; only the documented CLI
  invocations move.
