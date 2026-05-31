# repo-retro reports HEURISTIC_SYSTEM not_present for core/policies-nested roots

## Status

- Status: promoted
- First observed: 2026-05-31
- Area: repo-retro (heuristic-system discovery)
- Severity: low

## Signal

`repo-retro report` against this repo (agent-runtime-kit) rendered a
`## HEURISTIC_SYSTEM` section that was entirely empty on a window where the
heuristic-system tree was demonstrably active:

```
## HEURISTIC_SYSTEM
- State: not_present
- Active inbox entries: 0
- Error inbox movement: added 0, modified 0, archived 0, removed 0
- Operation records changed: 0
- Aging: no aged open retained item detected
```

User-reported: "這個 HEURISTIC_SYSTEM 是怎麼判定的 為什麼都是 0" (how is this
section derived, and why is everything 0).

## Evidence

- Raw record: not captured (manual source diagnosis, 2026-05-31).
- Host version when observed: `repo-retro 0.31.1` (report generated
  2026-05-30); root cause confirmed in source through `0.31.2`.
- Root cause (`crates/agent-workflow-primitives/src/repo_retro.rs`):
  - `summarize_heuristic_system` hard-coded `repo.join("heuristic-system")`,
    so `root.exists()` is false for this repo and the function short-circuits
    to `state: not_present` with empty counts.
  - the `git log --name-status` movement pathspecs were the same fixed
    `heuristic-system/error-inbox` / `…/operation-records` strings.
  - `active_inbox_summary` did a single non-recursive `read_dir` that only
    matched flat `error-inbox/*.md` files, never nested `<slug>/ENTRY.md`.
  - `default_path_class` hard-coded the same top-level prefixes, so nested
    cases were classified as product-docs instead of process-artifacts.
- This repo keeps the tree at `core/policies/heuristic-system/` with cases as
  `error-inbox/<slug>/ENTRY.md`, which none of the above matched.

## Impact

`repo-retro` silently under-reports heuristic-system activity (state, active
inbox, movement, aging) for any repo that nests the root under `core/policies/`
— i.e. every agent-runtime-kit retro. The data loss is invisible (it reads as
"no heuristic work this window") and can mislead a human reviewing a retro into
thinking the inbox is idle. No functional or durable-record impact.

## Current Workaround

None required for correctness of the records themselves. To get accurate retro
numbers before the fix is released, read the inbox directly
(`heuristic-inbox list --inbox-dir core/policies/heuristic-system/error-inbox`)
rather than trusting the `## HEURISTIC_SYSTEM` section.

## Promotion Criteria

Promote/archive once the upstream fix is released and this repo's nils-cli
surface pin advances to the release that carries it, then confirm a fresh
`repo-retro report` shows `State: present` with non-zero counts.

## Next Action

None — resolved upstream by sympoies/nils-cli#706
(https://github.com/sympoies/nils-cli/pull/706): repo-retro auto-discovers the
root (`heuristic-system/` then `core/policies/heuristic-system/`), adds a
`--heuristic-root` override, scans nested `<slug>/ENTRY.md` (skipping
`archive/` and evidence files), and classifies the nested root as a process
artifact. Shipped in nils-cli `v0.31.3` and adopted by this repo's surface pin
bump to `v0.31.3`; a fresh `repo-retro report` against this repo now renders
`## HEURISTIC_SYSTEM` with `State: present` and non-zero counts.

## Archive

- Archived: 2026-05-31
- Reason: Completed entry archived out of the active error inbox.
