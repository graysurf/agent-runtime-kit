# sync-runtime-surfaces prune-stale misses retired recursive skill directories

## Status

- Status: open
- First observed: 2026-05-31
- Area: sync-runtime-surfaces; agent-runtime prune-stale; rendered skill directory cleanup
- Severity: medium

## Signal

During the `sync-runtime-skills` -> `sync-runtime-surfaces` rename delivery,
`scripts/sync-runtime-surfaces.sh --apply` reported `prune=ok`, but the retired
recursive plugin-skill directories still existed in the live Codex / Claude
homes and generated build tree. They had to be removed manually before the
follow-up cleanup PR could be considered complete.

Root cause, two layers:

1. `agent-runtime prune-stale` only removes provably owned symlinks and empty
   directories. A retired *recursive-file* managed skill directory holds real
   files (a non-empty dir), so prune-stale detects it as a candidate but
   conservatively SKIPS it — it cannot prove ownership of real files versus
   genuine user content. Confirmed on `agent-runtime v1.0.3`: a stale
   `plugins/meta/skills/<retired>/` with real files yields
   `candidates=N changes=0 skipped=N`, records `skipped-non-empty-directory` /
   `skipped-regular-file`, and `ok: true`. This removal policy is a nils-cli
   decision and the remaining open half of this case.
2. `scripts/sync-runtime-surfaces.sh` discarded the prune-stale result and
   hard-coded `prune=ok` on every `--apply`, so the operator never saw the
   skipped candidates. This was the misleading finish signal and is fixed
   in-repo (below).

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260531-215228-drop-sync-runtime-skills-pr/skill-usage.record.json`
- PR #220 renamed the surface and ran the live sync; PR #224 removed the old
  compatibility wrapper and stale aliases after the manual cleanup.
- Observed stale paths were the retired `sync-runtime-skills` managed plugin
  skill directories under `$HOME/.codex/plugins/meta/skills/`,
  `$HOME/.claude/plugins/meta/skills/`, and the repo `build/{codex,claude}/`
  generated trees.
- Summary: linked `skill-usage.record.v1` envelope; raw runtime details remain
  in the evidence location.
- In-repo mitigation landed (this case's PR): `scripts/sync-runtime-surfaces.sh`
  now reads the `agent-runtime prune-stale --format json` result, reports
  `prune=review-needed` (not `prune=ok`) when `skipped > 0`, and lists the
  leftover paths so the operator removes the retired directories by hand.
  Regression probes in `tests/runtime-smoke/cases/meta/run.sh` cover both the
  upstream skip behavior (`prune-stale skips retired recursive-file managed
  skill directory`) and the honest reporting (`reports prune=review-needed`).
- Minimal repro against the pinned binary:
  `mkdir -p home/plugins/meta/skills/retired/scripts && printf x > home/plugins/meta/skills/retired/SKILL.md`
  then
  `agent-runtime prune-stale --source-root <repo> --product claude --live-home home --apply`
  reports `skipped` and leaves the directory.

## Impact

Future managed skill renames or removals can still leave stale
runtime-discoverable plugin skill directories that `agent-runtime prune-stale`
will not auto-remove. The operator-facing half is now mitigated: the sync
finish signal is honest (`prune=review-needed` plus the exact paths) instead of
a misleading `prune=ok`, so retired directories are no longer silently left
behind under a green summary. The directories still require a manual `rm` until
prune-stale itself removes provably owned recursive managed directories.

## Current Workaround

`scripts/sync-runtime-surfaces.sh --apply` now surfaces every stale candidate
prune-stale could not auto-remove and reports `prune=review-needed`. When that
status appears, remove only the exact retired managed skill directories listed
in the output.

## Promotion Criteria

The in-repo regression fixtures and honest finish signal have landed. Promote
this case after `agent-runtime prune-stale` (nils-cli) learns to remove a
provably owned recursive-file managed skill directory tree — for example via an
install/ownership ledger that distinguishes managed content from genuine user
content — so the live sync path removes stale managed plugin-skill directories
without manual `rm`, and the
`prune-stale skips retired recursive-file managed skill directory` probe is
re-pointed to assert removal.

## Next Action

Upstream the remaining half in `sympoies/nils-cli`: give `agent-runtime
prune-stale` an ownership-aware removal path for retired recursive-file managed
skill directories, then re-point the characterization probe and promote this
case.
