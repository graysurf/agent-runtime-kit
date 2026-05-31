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

## Impact

Future managed skill renames or removals can leave stale runtime-discoverable
plugin skill directories even though the sync script reports a successful
prune. That makes the finish signal misleading and can keep retired skill names
available in local runtimes.

## Current Workaround

After any managed skill rename/removal sync, explicitly check the old live and
generated plugin-skill paths. Remove only the exact retired managed directories
when `agent-runtime prune-stale` reports success but leaves them behind.

## Promotion Criteria

Promote after `agent-runtime prune-stale` has a regression fixture for a renamed
or removed recursive-file skill directory and the live sync path removes stale
managed plugin-skill directories without manual `rm`.

## Next Action

Add a regression fixture for renaming/removing a recursive-file skill directory and update prune-stale so stale managed plugin-skill directories are removed without manual rm.
