# heuristic-session-closeout commits records to the cwd checkout; from a worktree they strand off main

## Status

- Status: promoted
- First observed: 2026-06-01
- Area: heuristic-session-closeout skill; retained-record delivery; git worktree
- Severity: medium

## Signal

The shipped closeout Entrypoint derived its commit target from the current
working directory (`repo="$(cd "$root/../../.." && pwd -P)"`), then ran
`semantic-commit commit --repo "$repo"` followed by `git -C "$repo" push origin
main`. Run from inside a git worktree on a feature branch, this:

- commits the retained records onto the feature branch (not main), and
- runs `push origin main`, which pushes the local `main` ref — unchanged, since
  the commit landed on the feature branch — so the push is a silent no-op.

Either way the records do not reach `origin/main`. A skill-compliant agent that
honours the old "commit only from main" rule instead blocks and leaves the
records uncommitted; a literal reading of the Entrypoint commands strands them
on the feature branch (lost if that branch is abandoned, tangled into an
unrelated PR if it merges). The skill never located the primary `main` checkout,
even though `git worktree list` exposes it.

## Evidence

- Raw record: not captured — diagnosed live while auditing the closeout skill's
  worktree write-back path, 2026-06-01.
- Reproduced from inside a feature worktree: the Entrypoint derivation resolved
  `repo` to the worktree (branch `docs/...`), and `push origin main` targeted
  the local `main` ref still at its old commit while the records commit would
  sit on the feature branch.
- `git worktree list` showed the primary `main` checkout at a separate path,
  which the skill made no attempt to target.

## Impact

- Closeout from a worktree — the normal mode for agent work — does not reliably
  land retained records on `main`. They are left uncommitted, stranded on a
  feature branch, or tangled into an unrelated PR.
- The silent no-op push is the worst case: it reports success while nothing
  reached `main`.

## Current Workaround

Author and deliver retained records on a dedicated records branch in an isolated
worktree created off `origin/main`, then open a docs PR with `forge-cli pr
create`. Never commit records onto the current branch and never push `main`
directly. This is the model PR #236 bakes into the skill body.

## Promotion Criteria

Archive after PR #236 merges, once the closeout skill delivers records
exclusively via a dedicated records branch and PR, with no path that commits to
the current branch or pushes `main` directly.

## Next Action

None. Fixed by PR #236, which merged on 2026-05-31 and rewrote
heuristic-session-closeout to deliver retained records through a dedicated
branch and PR.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/pull/236`

## Archive

- Archived: 2026-06-06
- Reason: PR #236 merged; closeout skill now delivers retained records through
  a dedicated branch and PR.
- Durable link: `https://github.com/graysurf/agent-runtime-kit/pull/236`
