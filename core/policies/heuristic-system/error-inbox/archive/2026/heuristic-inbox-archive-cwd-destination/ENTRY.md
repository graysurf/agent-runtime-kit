# heuristic-inbox archive resolves destination from cwd, not the case path

## Status

- Status: promoted
- First observed: 2026-06-01
- Area: heuristic-inbox CLI (archive destination resolution)
- Severity: medium

## Signal

`heuristic-inbox archive <ABS_PATH>` computes the archive destination from the
current working directory via the relative default `--inbox-dir`
(`heuristic-system/error-inbox`), not from the explicit case-folder PATH passed
on the command line. When the case folder lives in one checkout/worktree but the
command runs from a different cwd, the case is moved into a brand-new stray
`heuristic-system/error-inbox/archive/<YEAR>/...` tree created under the cwd, and
deleted from its real location. `ok=true` and `data.destination` is reported as
a relative path, so the misplacement is silent.

## Evidence

- Raw record: not captured (live diagnosis 2026-06-01 during the
  agent-runtime-kit heuristic-inbox closeout sweep delivered in PR #234).
- Upstream issue: `sympoies/nils-cli#739`.
- Repro: with cwd = checkout A, run `heuristic-inbox archive
  /abs/checkoutB/core/policies/heuristic-system/error-inbox/<slug> -y --date
  2026-06-01 --format json` (no `--inbox-dir`); the folder is moved out of
  checkout B into `A/heuristic-system/error-inbox/archive/2026/<slug>` (a new
  tree at A's root, not under `core/policies/`).
- Versions: heuristic-inbox 1.0.0 (v1.0.0).

## Impact

Silent cross-checkout data move: the case is removed from its real inbox and
lands as untracked files in an unrelated working tree. Easy to hit when
archiving a worktree's case while the shell cwd is the main checkout. Recovered
in the PR #234 session by moving the folders back to the worktree and deleting
the stray tree.

## Current Workaround

Always pass `--inbox-dir <abs>/error-inbox` (and `--archive-root` if customized)
matching the case PATH's repo; never rely on the cwd-relative default. The same
caution applies to any subcommand whose default `--inbox-dir` is relative. See
sibling finding `heuristic-inbox-verify-redaction-false-positive`.

## Promotion Criteria

Promote when `sympoies/nils-cli#739` lands a fix that either derives the
inbox-dir / archive-root from the case folder's own parent (when not explicitly
given) or fails with a `case-path-outside-inbox` error instead of silently
relocating, and the new behavior is validated.

## Next Action

None. Fixed by sympoies/nils-cli#742 and released in v1.0.10; verified with
heuristic-inbox 1.0.10 that archive dry-run derives the destination from the
case path rather than the shell cwd.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/742`

## Archive

- Archived: 2026-06-06
- Reason: Fixed by nils-cli #742 and released in v1.0.10; archive destination
  behavior verified locally.
- Durable link: `https://github.com/sympoies/nils-cli/pull/742`
