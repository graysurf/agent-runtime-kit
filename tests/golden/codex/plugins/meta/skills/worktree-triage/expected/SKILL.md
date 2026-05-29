---
name: worktree-triage
description:
  Read-only scan of a repo's git worktrees that classifies each branch against a base ref (default `origin/main`) as safe-to-prune (fully merged or patch-equivalent), a rescue-candidate carrying unique commits, dirty, or locked; then, only on explicit confirmation, prunes the safe worktrees and opens draft PRs for genuinely unmerged work. Use it when agent-spawned worktrees pile up and you need to (1) clean stale worktrees and (2) find commits that never made it back to the base branch.
---

# Worktree Triage

## Contract

Prereqs:

- Run from inside the target git repository (or pass `--repo <path>`).
- `git` is on `PATH`; Python 3.11+ is available (the bundled
  `worktree_triage.py` helper is stdlib-only).
- `forge-cli` is installed from the released nils-cli package for the
  draft-PR rescue path. The scan itself needs no provider access.
- The base ref the work should have landed on is fetched and current.
  The helper is **read-only and never fetches** — run `git fetch origin`
  yourself first so `origin/main` is not stale, or the ahead/behind and
  supersession verdicts will be wrong.

Inputs:

- The repo to scan (`--repo`, defaults to the current repo).
- The base ref each branch is classified against (`--base`, defaults to
  `origin/main`).

Outputs:

- A `worktree-triage.scan.v1` JSON envelope (or text) with a `summary`
  (per-disposition counts) and a `worktrees` array. Each record carries
  `path`, `branch`, `is_primary`, `disposition`, `suggested_action`, and
  — for branches with unique commits — `ahead`/`behind`, a
  `unique_commit_count`, and an `evidence` block with the two-dot
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
  `git fetch`, or a non-`main` default branch — pass `--base`).
- A worktree is reported `dirty` or `locked`: that is a verdict to act on,
  not a tool error. Never remove either without resolving it first.
- A `rescue-candidate` whose `evidence` looks subtractive is a *signal* to
  review, not a license to delete — confirm with the human before closing
  or discarding.

## Entrypoint

Fetch first so the base ref is current, then scan:

```bash
git fetch origin
$CODEX_HOME/plugins/meta/skills/worktree-triage/scripts/worktree-triage.sh --repo . --base origin/main
```

Machine-readable envelope for selection logic:

```bash
$CODEX_HOME/plugins/meta/skills/worktree-triage/scripts/worktree-triage.sh --repo . --base origin/main --format json
```

## Workflow

1. **Fetch + scan.** Run `git fetch origin` (state it; the helper never
   fetches), then run the helper. Treat its output as read-only evidence.
2. **Present the triage table.** Show the user each worktree's
   `disposition`, branch, ahead/behind, and `suggested_action`, grouped
   into: safe-to-prune (`safe-merged` + `safe-superseded`),
   rescue-candidates, and blocked (`dirty` / `locked` / `primary`).
3. **Prune the safe set — only on explicit confirmation.** For each
   `safe-merged` / `safe-superseded` worktree the user approves:

   ```bash
   git worktree remove <path>
   git branch -D <branch>
   ```

   Delete the remote branch only when it has no open PR, or its PR is
   itself superseded/closed. Never prune a `primary`, `dirty`, or `locked`
   worktree, and never prune a `rescue-candidate`.
4. **Judge each rescue-candidate.** Read its `evidence`:
   - `likely_superseded: true` (net diff empty or subtractive) means the
     branch's content has probably already landed on the base via another
     commit even though `git cherry` still lists the commits — confirm with
     `git diff <base>..<branch> --stat`. If confirmed, close any associated
     PR and discard the branch (this is the stale-duplicate pattern). Do
     not merge it.
   - `likely_superseded: false` (real additions) means genuine unmerged
     work. On confirmation, open a **draft** PR for human review via the
     `create-github-pr` / `deliver-github-pr` workflow (forge-cli). Never
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

- `create-github-pr` / `deliver-github-pr` — open the draft PR a genuine
  `rescue-candidate` is handed off to. Triage never merges.
- `close-github-pr` — close the PR of a `rescue-candidate` confirmed to be
  already-on-base (superseded).
- `sync-runtime-skills` — its apply path refuses linked-worktree source
  roots; this skill is the companion that cleans those worktrees up.
