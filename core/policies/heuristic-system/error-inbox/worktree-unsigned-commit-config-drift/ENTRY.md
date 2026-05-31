# Agent commits land unsigned on main, recurring under git worktree workflows

## Status

- Status: open
- First observed: 2026-05-27
- Area: git signing policy; Codex/Claude agent worktree workflows; `commit.gpgsign`
- Severity: medium

## Signal

Commits authored/committed as `graysurf` are pushed directly to `main`
**unsigned** (`git log %G?` = `N`) despite global `commit.gpgsign=true` +
`user.signingkey` in `$HOME/.config/git/config`. The user reports this happens
**frequently specifically when work is done in git worktrees** (Codex and
Claude both use worktrees), and that agents have previously also changed
`user.email` in those contexts. Observed across both `sympoies/nils-cli` and
`graysurf/agent-runtime-kit`.

## Evidence

- Raw record: not captured (live in-session diagnosis, 2026-05-27); findings
  reconstructed from `git log %G?` and GitHub commit verification at that time.
- `sympoies/nils-cli` `main`: the `feat(plan-archive)/chore(plan-archive)`
  batch (2026-05-27 ~01:11–09:38 +0800) is all `%G?=N` unsigned; committer
  timestamps cluster into batches (01:23 / 02:34 / 09:38) = rebase replays.
  Same-day single interactive commits (e.g. `docs:` at 00:15/00:44) are `G`
  signed; PR squash-merges are GitHub-signed (`verified=true`).
- `graysurf/agent-runtime-kit`: commits `c6de9d2`..`15bc2df` were unsigned
  (one carried a stale RSA key `B5690EEEBB952194` from a GitHub web merge);
  required a history re-sign + force-push to repair.
- Causes **ruled out this session (with repro)**:
  - rebase stripping signatures — refuted: local `git rebase -f` re-signs when
    `commit.gpgsign=true` (plumbing test: replayed commit went `N`→`G`).
  - `semantic-commit` not signing — refuted: this session's `semantic-commit`
    commits (`f4586cc`, `aee57c3`) are `G`.
  - global flag enabled late — refuted: earlier same-day commits are `G`.
  - repo-local / `config.worktree` override — none present at audit time.
  - cloud/UTC runner — refuted: all commits are `+0800` (local tz).
- Confirmed mechanism: signing config lives **only** in
  `$HOME/.config/git/config` (XDG). With a different/empty `HOME` or no
  `XDG_CONFIG_HOME` (`env -i HOME=/tmp/x git config commit.gpgsign` → empty),
  git defaults `gpgsign` off and produces an **unsigned commit without
  aborting**. (gpgsign=true + signing failure would instead *abort*.)
- Worktree risk factor: both repos had `extensions.worktreeConfig=true` (now
  disabled, see Workaround). Claude worktrees confirmed in use (`CLAUDE_BASE`
  marker under `.git/worktrees/<id>/`).

## Impact

- Unsigned commits reach `main`, break commit verification, and previously
  forced a history re-sign + `main` force-push to repair.
- Recurring and cross-repo; the exact agent/tool commit path that drops signing
  is **not yet identified** (finding the precise culprit was deprioritized by
  the user).

## Current Workaround

Mitigations applied this session (landing is now blocked regardless of root
cause):

- GitHub ruleset `require-signed-commits-main` (`required_signatures`, active)
  on `sympoies/nils-cli` and `graysurf/agent-runtime-kit` — server rejects
  unverifiable pushes to `main` (PR squash-merges stay verified via GitHub).
- Local lefthook `pre-push` `signed-commits` gate
  (`scripts/ci/verify-signed-commits.sh`) in both repos — fails the push when a
  local commit not yet on a remote is non-`G/U`.
- Disabled `extensions.worktreeConfig` in both repos: removes the
  per-worktree silent-override vector. Verified durable — with the extension
  off, `git config --worktree ...` hard-fails ("cannot be used with multiple
  working trees unless the config extension worktreeConfig is enabled") rather
  than silently diverging; re-arming requires a deliberate
  `git config extensions.worktreeConfig true`.

## Promotion Criteria

Promote when **any one** lands:

- (a) the precise agent path is identified and fixed so commits sign — e.g. the
  agent runner preserves `HOME`/`XDG_CONFIG_HOME`/gpg-agent into worktree
  sessions; or
- (b) a verified guarantee that no agent commit helper falls back to
  `--no-gpg-sign` on signing failure, and no programmatic commit path
  (git2/gitoxide/`commit-tree`) is used for tracked work; or
- (c) a durable policy/hook prevents per-worktree identity/signing drift (e.g.
  `AGENTS.md` rule + a worktree-config audit wired into `pre-push`).

## Next Action

Sprint 2 direct-worktree hook and AGENT_HOME policy reduce unmanaged worktree
creation and forbid per-worktree identity/signing drift, but this case stays
open until a worktree-config audit/hook or equivalent guard lands.

Lifecycle link: `https://github.com/sympoies/nils-cli/issues/712`
