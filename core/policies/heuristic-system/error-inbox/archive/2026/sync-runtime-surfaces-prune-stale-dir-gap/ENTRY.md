# sync-runtime-surfaces prune-stale misses retired recursive skill directories

## Status

- Status: promoted
- First observed: 2026-05-31
- Resolved: 2026-06-02
- Area: sync-runtime-surfaces; agent-runtime prune-stale; rendered skill directory cleanup
- Severity: medium

## Signal

During the `sync-runtime-skills` -> `sync-runtime-surfaces` rename delivery,
`scripts/sync-runtime-surfaces.sh --apply` reported `prune=ok`, but the retired
recursive plugin-skill directories still existed in the live Codex / Claude
homes and generated build tree. They had to be removed manually before the
follow-up cleanup PR could be considered complete.

Root cause (corrected after upstream code investigation — see Evidence):

1. **`agent-runtime render` is additive.** When a skill is removed from
   `manifests/skills.yaml` (renamed or retired), render leaves its
   `build/<product>/` outputs and `.render-cache.json` entry behind — the
   per-skill cleanup only fires for skills still being rendered, so a fully
   retired skill is never revisited.
2. **`prune-stale` then keeps the retired skill, silently.** prune-stale
   rebuilds its "expected" set by expanding the recursive link-map entry over
   the *current* `build/` tree (`InstallPlan::build` ->
   `expected_paths_from_plan`). A retired skill that lingers in `build/` is
   therefore still listed as expected. With the symlink-based install the
   live-home entries are symlinks (not real files), and prune-stale reports
   `candidates=0 changes=0` — a silent `prune=ok` that keeps the retired skill
   discoverable in the runtime home. Confirmed on current nils-cli `main`:
   removing the stale `build/<retired>` makes prune-stale immediately treat
   those live entries as stale and remove them.

So the root fix is in **`render`** (reconcile `build/`), not `prune-stale` —
prune-stale is correct given a clean `build/`. The earlier "prune-stale skips
real-file dirs" framing is a secondary, rarer path (real files in the live
home, which the symlink-based install does not normally produce). Note this
also means the in-repo finish-signal fix (PR #252: `prune=review-needed` when
`skipped > 0`) does **not** catch this primary case — it is
`candidates=0 / skipped=0`, a silent `prune=ok` — so the render-side reconcile
is the real closure.

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
- Upstream investigation (current nils-cli `main`, debug binary) confirmed the
  corrected diagnosis end to end:
  - `render` is additive: planting an orphan skill dir in `build/<product>/`
    and re-rendering leaves it in place (`render/writer.rs` cleanup only
    iterates skills still present in the prior cache).
  - With the stale `build/<retired>` present, `prune-stale` reports
    `candidates=0 changes=0` and keeps the live-home symlinks; deleting
    `build/<retired>` makes the same run report `candidates=N changes=N` and
    remove them.
- Upstream fix merged: `sympoies/nils-cli` PR #755 (`feat(render): reconcile
  build/ outputs for retired skills`, squash `4d7c06f`) — render removes a
  retired skill's `build/` outputs + cache entry on the next render, with a
  regression test. Merged to nils-cli `main`; **not yet released**, so the
  agent-runtime-kit pin (`v1.0.4`) does not consume it yet — a future release +
  pin bump closes the loop.
- Minimal repro of the silent leak (current nils-cli `main`): render two skills,
  remove one from `manifests/skills.yaml`, re-render, then install + prune-stale;
  the retired skill stays in the live home with `prune-stale candidates=0` until
  `build/<retired>` is gone.

## Impact

Until the render-side reconcile ships, a managed skill rename/removal can still
leave the retired skill discoverable in `$CODEX_HOME` / `$HOME/.claude`, and the
sync reports a green `prune=ok` because `prune-stale` (correctly, given the
stale `build/`) sees nothing to do. The in-repo finish-signal fix (PR #252) only
catches the secondary real-file path, not this primary `candidates=0` case, so
the leak is silent until the render fix lands.

## Current Workaround

After a managed skill rename/removal, re-run `agent-runtime render` and then
explicitly check the retired skill's `build/{codex,claude}/` and live-home
(`$CODEX_HOME` / `$HOME/.claude`) paths; remove the exact retired managed skill
directories by hand. (The `prune=review-needed` signal from
`scripts/sync-runtime-surfaces.sh` only fires for the secondary real-file case.)

## Promotion Criteria

Met. The render-side reconcile (`sympoies/nils-cli` PR #755) is merged and
shipped in `v1.0.5`, the agent-runtime-kit pin is bumped to `v1.0.5`
(`docs/source/nils-cli-pin.yaml`, PR #260), and the end-to-end path (render ->
install -> retire a skill -> render -> install -> prune-stale) leaves the
runtime home clean without a manual `rm`.

## Resolution

- Render reconcile shipped in nils-cli `v1.0.5` (#755, squash `4d7c06f`):
  render drops a retired skill's `build/<product>/` outputs + cache entry on the
  next render, so `prune-stale` no longer sees the retired skill as expected and
  removes its live-home symlinks.
- agent-runtime-kit pin bumped `v1.0.4` -> `v1.0.5` (PR #260); host upgraded via
  the tap. `sync-runtime-surfaces --apply` then reported
  `prune=ok; doctor=ok; codex prompt-input=verified` against the v1.0.5 binary —
  no leftover retired directories.
- In-repo finish-signal mitigation (PR #252: `prune=review-needed` on
  `skipped > 0`) and the runtime-smoke regression probes remain in place as a
  belt-and-suspenders guard for the secondary real-file case.

## Next Action

None. Resolved and shipped in nils-cli `v1.0.5` (see Resolution); archived.

## Archive

- Archived: 2026-06-02
- Reason: Render reconcile shipped in nils-cli v1.0.5 (#755); agent-runtime-kit pinned to v1.0.5 (#260); sync-runtime-surfaces verified clean.
- Durable link: `https://github.com/sympoies/nils-cli/releases/tag/v1.0.5`
