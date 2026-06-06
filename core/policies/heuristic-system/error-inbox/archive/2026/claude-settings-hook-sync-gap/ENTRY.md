# Claude settings hook source is not applied by sync-runtime-skills

## Status

- Status: promoted
- First observed: 2026-05-31
- Area: Claude settings hooks; sync-runtime-skills; runtime hook rollout
- Severity: medium

## Signal

During issue #712 closeout, `agent-runtime-kit` merged a new shared hook
(`block-direct-git-worktree.py`) and updated
`core/hooks/claude/settings.hooks.jsonc`, then
`bash scripts/sync-runtime-skills.sh --apply` was run from the durable primary
checkout. The sync installed the Claude hook script under `$HOME/.claude/hooks`
and `agent-runtime doctor --class skill-surface --product claude` passed, but
the live `$HOME/.claude/settings.json` `PreToolUse` hook list did not gain the
new `block-direct-git-worktree.py` entry.

This is consistent with the documented product surface:
`docs/source/harness-shape-claude.md` marks Claude `settings.json` managed-block
hook registration as `planned-not-shipped`. The operational risk is that a
future hook rollout can appear fully synced while Claude still lacks the live
settings hook entry.

## Evidence

- Raw record: manual closeout diagnosis for sympoies/nils-cli#712 on
  2026-05-31; no raw transcript retained.
- `sync-runtime-skills --apply` summary: `codex+claude`, prune OK, doctor OK,
  Codex prompt-input verified.
- Codex live config was updated:
  `$HOME/.codex/config.toml` contains the `block-direct-git-worktree.py`
  managed hook command.
- Claude live hook script was installed:
  `$HOME/.claude/hooks/block-direct-git-worktree.py` exists and blocks
  `git worktree add ...` when invoked with a Claude-style hook payload.
- Claude live settings initially lacked the matching command in
  `$HOME/.claude/settings.json`; the session applied a narrow manual insertion
  into the existing `PreToolUse` / `Bash` hook list and revalidated JSON.

## Impact

Claude sessions can continue to allow raw mutating `git worktree` commands even
after source hook fragments and hook scripts are merged, synced, and reported
healthy. Agents may incorrectly treat source `settings.hooks.jsonc` plus a
successful `sync-runtime-skills --apply` as live enforcement.

## Current Workaround

None. Resolved by `scripts/sync-runtime-surfaces.sh --apply --product claude`
merging `core/hooks/claude/settings.hooks.jsonc` into live
`$HOME/.claude/settings.json` while preserving custom hooks and replacing only
runtime-kit managed hook commands.

## Promotion Criteria

Promote when either:

- `sync-runtime-skills --apply --product claude` owns a managed
  `settings.json` hook block or equivalent merge path and tests prove a source
  `settings.hooks.jsonc` change reaches live Claude settings; or
- the sync workflow explicitly reports Claude settings hook fragments as
  planned-not-shipped / manual-only so delivery agents cannot mistake a passing
  skill-surface doctor for live hook activation.

## Next Action

None. Fixed in
`https://github.com/graysurf/agent-runtime-kit/commit/4d55260d9a9bfbe138a1b18dfb8479732ac39583`.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/commit/4d55260d9a9bfbe138a1b18dfb8479732ac39583`

## Archive

- Archived: 2026-06-06
- Reason: Completed entry archived out of the active error inbox.
