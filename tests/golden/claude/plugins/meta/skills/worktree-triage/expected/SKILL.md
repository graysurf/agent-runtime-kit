---
name: worktree-triage
description:
  Read-only scan of git worktrees against a base ref, classifying each branch
  as safe-to-prune, rescue-candidate, dirty, or locked; prunes safe ones and
  opens draft PRs for unmerged work only on explicit confirmation.
---

# Worktree Triage

## Contract

Prereqs:

- For one repo, run from inside the target git repository (or pass
  `--repo <path>`).
- For machine-wide cleanup, pass `--all-managed` to scan every repository
  represented under the managed worktree root
  (`${AGENT_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/worktrees`).
- `git` and `git-cli` are on `PATH`; Python 3.11+ is available (the bundled
  `worktree_triage.py` helper is stdlib-only).
- `forge-cli >=1.11.2` is installed from the released nils-cli package for the
  draft-PR rescue path. The scan itself needs no provider access.
- The base ref the work should have landed on is fetched and current in every
  scanned repo. The helper is **read-only and never fetches** — run
  `git fetch origin --prune` yourself first (in each represented repo for
  `--all-managed`) so `origin/main` is not stale, or the ahead/behind and
  supersession verdicts will be wrong.

Inputs:

- The scope to scan:
  - `--all-managed` for every repo represented under the managed worktree
    root. Use this when the user says "all worktrees", "no agents are running",
    or otherwise asks for global cleanup without naming one repo.
  - `--repo <path>` for one repo, or no scope flag to scan the current repo.
- The base ref each branch is classified against (`--base`, defaults to
  `origin/main`).

Outputs:

- A `worktree-triage.scan.v1` JSON envelope (or text) with a `scope`, optional
  `worktree_root`, a `repos` array, a `summary`
  (per-disposition counts) and a `worktrees` array. Each record carries
  `path`, `repo_root`, `branch`, `is_primary`, `disposition`,
  `suggested_action`, and — for branches with unique commits —
  `ahead`/`behind`, a `unique_commit_count`, and an `evidence` block with the
  two-dot
  `git diff <base>..<branch>` shortstat plus a `likely_superseded` flag.

Dispositions (the heart of the triage):

- `primary` — the repo's main working tree. Never a removal target.
- `dirty` — uncommitted changes present. **Blocked from removal** so
  in-progress work is never lost.
- `locked` — a git-locked worktree. Surfaced, never auto-removed.
- `safe-merged` — branch tip is an ancestor of the base (nothing ahead).
  Safe to prune.
- `safe-superseded` — branch is ahead by commit SHA, but **every** commit
  is patch-equivalent to one already in the base (`git cherry` reports
  them all as `-`). Safe to prune.
- `rescue-candidate` — branch has commits whose patch is not in the base.
  This needs human judgment: it may be genuine unmerged work, OR work that
  already reached the base via a different commit (patch-id is unreliable
  for that case — read `evidence`). **Never auto-pruned.**

Failure modes:

- Not a git repo, or `--base` does not resolve (usually a missing
  `git fetch`, or a non-`main` default branch — pass `--base`). In
  `--all-managed`, per-repo base failures are reported in `errors`; do not
  prune worktrees from a repo whose base could not be verified.
- A worktree is reported `dirty` or `locked`: that is a verdict to act on,
  not a tool error. Never remove either without resolving it first.
- A `rescue-candidate` whose `evidence` looks subtractive is a *signal* to
  review, not a license to delete — confirm with the human before closing
  or discarding.

## Entrypoint

For all managed agent worktrees, fetch each represented repo first, then scan:

```bash
$HOME/.claude/plugins/meta/skills/worktree-triage/scripts/worktree-triage.sh --all-managed --base origin/main --format json
```

For one repo, fetch first so the base ref is current, then scan:

```bash
git fetch origin
$HOME/.claude/plugins/meta/skills/worktree-triage/scripts/worktree-triage.sh --repo . --base origin/main
```

Machine-readable envelope for selection logic:

```bash
$HOME/.claude/plugins/meta/skills/worktree-triage/scripts/worktree-triage.sh --repo . --base origin/main --format json
```

## Workflow

1. **Choose scope, fetch, then scan.** If the user names one repo, use
   `--repo`; if the user asks for all worktrees or says no agents are running,
   use `--all-managed`. Run `git fetch origin --prune` for every represented
   repo in scope (state it; the helper never fetches), then run the helper.
   Treat its output as read-only evidence.
2. **Present the triage table.** Show the user each worktree's
   `disposition`, branch, ahead/behind, and `suggested_action`, grouped
   into: safe-to-prune (`safe-merged` + `safe-superseded`),
   rescue-candidates, and blocked (`dirty` / `locked` / `primary`).
3. **Prune the safe set — only on explicit confirmation.** For each
   `safe-merged` / `safe-superseded` worktree the user approves, run the
   removal against the reported `path` and delete the branch from that
   record's `repo_root` (this matters for `--all-managed`, where rows may come
   from different repos):

   ```bash
   git-cli worktree remove <path-or-slug> --format json
   git -C <repo_root> branch -D <branch>
   ```

   Delete the remote branch only when it has no open PR, or its PR is
   itself superseded/closed. Never prune a `primary`, `dirty`, or `locked`
   worktree, never prune anything from a repo listed in `errors`, and never
   prune a `rescue-candidate`.
4. **Judge each rescue-candidate.** Read its `evidence`:
   - `likely_superseded: true` (net diff empty or subtractive) means the
     branch's content has probably already landed on the base via another
     commit even though `git cherry` still lists the commits — confirm with
     `git diff <base>..<branch> --stat`. If confirmed, close any associated
     PR and discard the branch (this is the stale-duplicate pattern). Do
     not merge it.
   - `likely_superseded: false` (real additions) means genuine unmerged
     work. On confirmation, open a **draft** PR for human review via the
     `create-pr` / `deliver-pr` workflow (forge-cli). Never
     auto-merge.
5. **Stop at the human gate.** The skill never removes a worktree, deletes
   a branch, closes a PR, or opens a PR without explicit per-item
   confirmation, and never merges.

## Boundary

`worktree_triage.py` owns worktree enumeration, the ahead/behind and
ancestor checks, the patch-equivalence (`git cherry`) call, the two-dot
net-diff evidence, and the disposition verdict. The skill body owns when to
fetch and scan, how to present the triage for selection, and the confirmed
act phase (prune safe worktrees, hand rescue-candidates to PR delivery or
closure). It never re-implements the classification in prose, never
auto-removes a dirty/locked/primary worktree, never deletes a branch with
unique commits without confirmation, and never merges.

## Related Skills

- `create-pr` / `deliver-pr` — open the draft PR a genuine
  `rescue-candidate` is handed off to. Triage never merges.
- `close-pr` — close the PR of a `rescue-candidate` confirmed to be
  already-on-base (superseded).
- `sync-runtime-surfaces` — its apply path refuses linked-worktree source
  roots; this skill is the companion that cleans those worktrees up.
