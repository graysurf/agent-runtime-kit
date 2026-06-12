# Evidence: heuristic-inbox deliver silent exit 1 on same-day slug collision

Date: 2026-06-12
CLI: heuristic-inbox 1.0.17 (nils-cli v1.0.17)

Sequence:

1. Earlier the same day, a records delivery (merged as
   graysurf/agent-runtime-kit#309) created branch + managed worktree
   `docs/heuristic-records-2026-06-12` (the default slug is
   `heuristic-records-<UTC date>`). Neither the branch nor the worktree is
   cleaned up after merge.
2. A second delivery the same day ran:
   `heuristic-inbox deliver --label workflow::heuristic-records
   --body-file <body.md> --format json`
3. The command exited 1 with NO output at all: no JSON error envelope
   despite `--format json`, nothing on stderr.
4. The invocation log records the failure but carries no error detail:

```json
{
  "schema_version": "cli.heuristic-inbox.invocation.v1",
  "command": "heuristic-inbox deliver",
  "exit_code": 1,
  "started_at": "2026-06-12T14:32:47Z",
  "ended_at": "2026-06-12T14:32:49Z"
}
```

(Source: `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260612-223249-heuristic-inbox/invocation.json`)

5. Re-running with a unique `--slug heuristic-records-2026-06-12-finding-links`
   succeeded immediately (PR graysurf/agent-runtime-kit#311, merged).

Aggravating factor: deliver never removes its merged records worktrees.
`git worktree list` showed six piled-up `heuristic-records-*` worktrees
(2026-06-03 through 2026-06-12), so the next same-day delivery is
guaranteed to collide with the day's first.

Dry-run plan confirms the collision point: step 2 of the plan is
`git worktree add -b docs/heuristic-records-<date> <worktrees-root>/... origin/main`,
which fails when the branch already exists.
