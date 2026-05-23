# plan-issue v2 marker collapse silently broke runtime-smoke probes and create-plan-tracking-issue skill on host bump to nils-cli v0.17.7

## Status

- Status: open
- First observed: 2026-05-24
- Area: plan-issue record contract; dispatch + pr runtime-smoke probes; dispatch domain skill specs
- Severity: medium
- Source upstream PRs: sympoies/nils-cli#453, #454, #455, #456
- Source upstream release: sympoies/nils-cli v0.17.7
- Source local context: this repo pins the nils-cli surface in `docs/source/nils-cli-surface.md` at v0.17.6 while `brew install sympoies/tap/nils-cli` has already advanced the host to v0.17.7; the discussion source under `docs/plans/nils-cli-version-alignment/` was authored to close exactly this silent-drift class.

## Signal

`sympoies/nils-cli v0.17.7` (released 2026-05-23, four hours after the
`v0.17.6` snapshot was pinned into this repo) shipped a breaking
contract change in the `plan-issue record` subsystem under the upstream
header "v2 marker collapse + audit/dashboard rewrite". Three concrete
breaks:

1. **`--marker-family` flag removed.**
   `plan-issue record render-comment` and `render-dashboard` reject
   `--marker-family compat` (and `--marker-family shared`) with
   `error: unexpected argument '--marker-family' found`. Exit 2.
2. **Record envelope schema bumped v1 → v2.**
   `render-comment` returns `plan-issue-cli.record.render.comment.v2`;
   `render-dashboard` returns the matching v2 envelope. Probes that
   `grep -q 'plan-issue-cli.record.render.comment.v1'` no longer match
   (the v1 string is absent from the output).
3. Marker token format collapsed. The old `compat` family v1 tokens
   (such as `plan-tracking-issue:snapshot:v1` with `kind=source`, and
   `execute-from-tracking-issue:state:v1` / `:session:v1` /
   `:validation:v1`, plus `code-review-specialists:review:v1`) were
   replaced by a single `plan-issue-record:v2` token differentiated by
   `role=<source|plan|state|...>` and `profile=tracking|dispatch`.
   `plan-issue record audit --profile tracking` reads the old markers
   as `unsupported_markers` and reports the required source / plan /
   state markers as missing.

## Impact

- `tests/runtime-smoke/cases/dispatch/run.sh` writes hardcoded v1 markers
  in `write_tracking_comments_json` and `write_dispatch_comments_json`,
  passes the retired `--marker-family compat` / `--marker-family shared`
  flags to `render-comment` and `render-dashboard`, and `grep -q
  '"missing_required":\\[\\]'` (over-escaped, would never match anyway).
  Six probes fail under v0.17.7: `dispatch.create-plan-tracking-issue`,
  `dispatch.dispatch-plan-closeout`,
  `dispatch.deliver-plan-tracking-issue`,
  `dispatch.review-dispatch-lane-pr`,
  `dispatch.execute-dispatch-lane`, plus
  `pr.create-dispatch-lane-pr` from `tests/runtime-smoke/cases/pr/run.sh`.
- The `dispatch:create-plan-tracking-issue` SKILL body
  (`core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`)
  instructs callers to pass `--marker-family compat`; under v0.17.7 the
  skill cannot complete its render-comment step. Sibling skills under
  `core/skills/dispatch/` and the matching golden output need parallel
  checks.
- `scripts/ci/all.sh` Position 8 `runtime-smoke` fails non-zero, which
  makes the `pre-push` hook fail on every push from a host running
  v0.17.7, regardless of what the PR changes.
- No CI gate in this repo compared `agent-runtime --version`
  (`v0.17.7`) against the snapshot pin (`v0.17.6`), so the breaking
  bump landed silently between PR #66 (snapshot to v0.17.6, merged
  2026-05-23) and host brew upgrade.

## Evidence

- Raw record: this entry was authored from in-session reproduction (no `skill-usage` record exists yet — the v0.17.7 break surfaced while running `create-plan-tracking-issue` skill against a freshly upgraded host, before any skill-usage envelope could be written).
- Host vs pinned version mismatch reproduced:
  - `agent-runtime --version` → `agent-runtime 0.17.7`.
  - `head -8 docs/source/nils-cli-surface.md | tail -1` → ``- Active git describe --tags output: `v0.17.6` ``.
- Retired flag rejection reproduced: `plan-issue record render-comment --profile tracking --marker-family compat --kind state --content-file <tmp> --out <tmp> --format json` → `error: unexpected argument '--marker-family' found` (exit 2).
- v2 round-trip succeeds: render-comment (without `--marker-family`) + render-dashboard + audit `--profile tracking` returns `missing_required:[]`, `unsupported_markers:[]`, `recognized_count:3`.
- Probe failure mode captured in
  `<state_home>/.../artifacts/dispatch/create-plan-tracking-state-comment.json`
  during `bash tests/runtime-smoke/run.sh --mode deterministic --domain
  dispatch --keep-artifacts`: file contains the upstream error string
  `error: unexpected argument '--marker-family' found`, not the
  expected v2 envelope.
- Upstream release notes for sympoies/nils-cli v0.17.7 list "consumer migration notes" under What's Changed (PR sympoies/nils-cli#456); upstream signalled the break.

## Current Workaround

- For PRs that do not touch the broken code paths, push with
  `--no-verify` after explicit user authorization. The pre-push hook
  failure is unrelated to the change being shipped. Note this **only**
  while this case is open; reinstate the hook as soon as the v2
  migration lands.
- For invoking the `dispatch:create-plan-tracking-issue` skill end to
  end, no workaround: the skill's render-comment step cannot complete
  on v0.17.7 without removing `--marker-family compat` from the body.
  Either downgrade nils-cli to v0.17.6, or land the v2 migration
  first.

## Promotion Criteria

Close this entry (promote workaround into the v2 migration PR, then
archive) when all four of the following are true:

- `tests/runtime-smoke/cases/dispatch/run.sh` and
  `tests/runtime-smoke/cases/pr/run.sh` are updated to use v2 markers
  end to end (no `--marker-family` flag, no `v1` envelope greps, no
  hardcoded `plan-tracking-issue:*` / `execute-from-tracking-issue:*`
  markers in the JSON fixtures), and all eight previously-failing
  probes return `pass / skill_count=1` on a host running v0.17.7.
- `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
  (and any sibling dispatch / pr skill body that references the
  retired flag set or the v1 marker tokens) is rewritten against the
  v2 contract; `agent-runtime render` regenerates clean output; the
  matching `tests/golden/` snapshots are refreshed.
- `docs/source/nils-cli-surface.md` is rolled forward from `v0.17.6`
  to the version that resolves the v2 migration (likely `v0.17.7` or
  later); `README.md:19` and `SUPPORT_MATRIX.md` `min_nils_cli`
  cells are refreshed in the same PR per the existing checklist.
- The Step 1 CI gate from
  `docs/plans/nils-cli-version-alignment/` lands so the next time a
  host advances past the pinned surface, the gate fires before
  downstream tests assume the host binary matches.

## Prevention Rule

**Before merging a nils-cli surface-pin bump in
`docs/source/nils-cli-surface.md`, dry-run the affected `plan-issue`,
`forge-cli`, and `agent-runtime` subcommands referenced in every
SKILL body and runtime-smoke probe against the new binary.** If any
flag or schema is rejected, list the migration delta in the bump PR
description and either:

- Land the migration in the same PR (skill bodies, runtime-smoke
  fixtures, golden snapshots), or
- Block the bump on the migration PR landing first.

This rule applies to every plan-issue / forge-cli minor across the
0.x series until the version-alignment doctor class
(`docs/plans/nils-cli-version-alignment/` Step 2) lands and enforces
it mechanically.

## Next Action

Open a separate v2-migration PR that touches:

1. `tests/runtime-smoke/cases/dispatch/run.sh`
2. `tests/runtime-smoke/cases/pr/run.sh`
3. `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
   plus sibling dispatch skill bodies that still reference v1
   markers.
4. `tests/golden/` snapshots regenerated after the skill rewrites.
5. `docs/source/nils-cli-surface.md` rolled to the active host
   version, `README.md` Version baseline row, `SUPPORT_MATRIX.md`
   cells refreshed.

Reference this entry from that PR's description so future PRs touching
the same surface can find the migration ledger without re-deriving it.
