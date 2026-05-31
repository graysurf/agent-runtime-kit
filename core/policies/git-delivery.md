# Git, Commits, And Delivery

## Purpose

This policy holds the detailed mechanics behind agent-owned Git work and how it
reaches a provider: the commit body gate, managed worktree paths, branch
naming, label selection, and PR/MR body format.

It is declared as a `project-dev` document in `AGENT_DOCS.toml` (global scope),
so the harness surfaces it through the hook preflight when implementation work
starts. `AGENT_HOME.md` carries the always-on hard gates — use `semantic-commit`,
use `git-cli worktree`, use `forge-cli` for provider records, keep signing on,
and never force-push `main`. Those gates are also enforced mechanically by hooks,
but hooks do not replace policy: this file is the intent and the procedural
detail behind the one-line gates.

## Commits

- The `semantic-commit` body gate enforces 1-2 bullets on non-trivial commits;
  trivial commits may omit the body.
- Draft an accurate 1-2 sentence summary grounded in the actual diff before
  committing or opening a record; never derive a title or body from
  `git log -1`.

## Worktrees

- `git-cli worktree` is the managed lifecycle surface; direct mutating
  `git worktree` is blocked by hook so paths, branch names, JSON contracts, and
  cleanup behavior stay consistent across sessions.
- Managed agent worktrees live under the runtime-kit state worktree tree
  (`${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/worktrees/<repo-key>/<branch-slug>`);
  the sibling `.../agent-runtime-kit/out/` tree stays owned by `agent-out` for
  workflow artifacts.
- `git-cli worktree remove` reclaims the working tree but intentionally leaves
  the branch ref in place; delete a merged throwaway branch explicitly, or use
  `meta:worktree-triage` to batch-clean stale worktrees and branches.

## Branches

- Branch names use `feat/<slug>` or `fix/<slug>` (lowercase, hyphenated, three
  to six words). A ticket id `ABC-123` becomes `feat/abc-123-<slug>`.
- `git-cli worktree add <slug>` derives the branch as `feat/<slug>` from the
  base ref automatically, so manual branch creation in a shared checkout is
  rarely needed.

## Issues, PRs, And MRs

- For agent-owned provider issues, PRs, and MRs, use the active workflow or
  `forge-cli` surface instead of raw provider commands. Direct `gh pr create`
  or `glab mr create` are blocked by hook; PR/MR delivery goes through the
  active delivery skill.
- PR/MR bodies come from the active delivery skill / `agent-runtime pr-body
  render` (the canonical formatter; minimum `## Summary` + `## Test plan`). Do
  not hand-write body scaffolding or copy the formatter's section table into
  policy files.

## Labels

- Labels describe the record's type, area, state or size, and workflow for
  triage and automation.
- When the active project provides `manifests/forge-labels.yaml`, select labels
  from that catalog and follow `core/policies/forge-label-taxonomy.md`; current
  CLI / skill surfaces handle ensure, validation, and application details.
