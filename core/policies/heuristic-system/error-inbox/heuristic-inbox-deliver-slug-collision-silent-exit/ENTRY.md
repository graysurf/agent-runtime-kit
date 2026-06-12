# heuristic-inbox deliver exits 1 silently when the day's default records branch already exists

## Status

- Status: open
- First observed: 2026-06-12
- Area: heuristic-inbox deliver (records branch + managed worktree lifecycle)
- Severity: medium

## Signal

`heuristic-inbox deliver` (nils-cli v1.0.17) derives its default records
branch slug from the UTC date (`heuristic-records-<date>`). The second
delivery on the same day collides with the first one's leftover branch +
managed worktree at the `git worktree add -b docs/heuristic-records-<date>`
step and exits 1 with no output at all: no JSON error envelope despite
`--format json`, nothing on stderr, and the invocation log records only
`exit_code: 1` with no error detail. Two gaps compound:

1. The failure path emits no diagnostics on any surface, so the operator
   sees a bare exit 1 (or, piped through `jq`, nothing).
2. `deliver` never cleans up its merged records worktrees/branches, so the
   day's first successful delivery guarantees the collision for the second
   (six `heuristic-records-*` worktrees, 2026-06-03 through 2026-06-12, had
   piled up when this was diagnosed).

## Evidence

- Raw record: `evidence/deliver-slug-collision-evidence.md`
- Summary: redacted evidence ingested at creation time; raw logs and secrets were stripped before commit.
- Live occurrence: first same-day delivery merged as
  graysurf/agent-runtime-kit#309 (branch `docs/heuristic-records-2026-06-12`
  left behind); the second delivery failed silently until re-run with
  `--slug heuristic-records-2026-06-12-finding-links`, which landed as
  graysurf/agent-runtime-kit#311.
- Upstream issue filed: sympoies/nils-cli#820 (2026-06-12).
- Counter-datapoint (2026-06-12, later session, same v1.0.17): the same
  same-day collision (third/fourth deliveries of the day, against the
  leftover `docs/heuristic-records-2026-06-12` branch from the merged #314)
  did NOT exit silently — both runs emitted a structured
  `worktree-add-failed` JSON envelope naming the colliding branch and
  `worktree_path`, with git's `fatal: a branch named ... already exists` in
  `details.stderr`. The silent-exit gap may be conditional (or the original
  observation may have been output-swallowing in the consuming pipe); the
  envelope code is `worktree-add-failed`, not a dedicated
  `records-branch-exists`, so promotion criterion (a) is at most partially
  met. Re-run with `--slug heuristic-records-2026-06-12-record-post-compose`
  landed as graysurf/agent-runtime-kit#315.

## Impact

Every second same-day records delivery fails with zero diagnostics —
closeout flows are exactly the same-day-repeat-prone path. The operator
burns diagnosis time on an invisible failure, and the only recorded trace
(`invocation.json`) carries no failure reason either.

## Current Workaround

- Pass a unique `--slug` (e.g. `heuristic-records-<date>-<topic>`) for any
  delivery after the day's first.
- Periodically remove merged records worktrees and branches
  (`git-cli worktree remove <slug>` + `git branch -D docs/<slug>`; the
  branch needs `-D` because records PRs are squash-merged), or run
  `worktree-triage` when the pile grows.

## Promotion Criteria

Promote when `heuristic-inbox deliver` (a) emits a structured error envelope
(e.g. `records-branch-exists`) naming the colliding branch and worktree on
this failure path, and ideally (b) auto-uniquifies the default slug or
cleans up its merged records worktrees; validated by a same-day
double-delivery test (second run either succeeds with a uniquified slug or
fails with the precise error).

## Next Action

Track sympoies/nils-cli#820 (filed 2026-06-12) for the upstream fix
(structured error envelope on the collision path, default-slug
uniquification, and/or merged-worktree cleanup). Until it lands, keep the
unique-`--slug` workaround. Promote per the promotion criteria once the
fix ships with a same-day double-delivery test.
