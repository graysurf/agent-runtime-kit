# AGENTS.md

## Scope

- Repo-local agent policy for `agent-runtime-kit`. Global / home-scope
  defaults live in `AGENT_HOME.md`, loaded by Codex via
  `$HOME/.codex/AGENTS.md` and by Claude via `$HOME/.claude/CLAUDE.md`
  (both symlinks point at this repo's `AGENT_HOME.md`).
- `./CLAUDE.md` in this repo is a symlink to this file so Claude reads the
  same repo-local rules without maintaining a second copy.

## Project Purpose

- Build a new single-source repository for the local agent runtime layer that is
  currently split between `agent-kit` and `claude-kit`.
- The goal is one canonical source for shared skills, workflows, hooks, docs,
  plugin metadata, install/link management, and drift auditing.
- Codex and Claude should become product targets/adapters, not separate source
  repos that require manual porting.

## Local Source Repositories

- Codex-oriented source today:
  `$HOME/.config/agent-kit`
- Claude-oriented source today:
  `$HOME/.config/claude`
- Live Codex home:
  `$HOME/.codex`
- Live Claude home:
  `$HOME/.claude`
- `$HOME/.agents` is the retired compatibility alias from earlier Codex
  sessions. It is no longer required for skill discovery; if it is absent
  on a host, Codex loads runtime-kit skills through `$HOME/.codex/skills`
  directly. Rollback (recreate alias) is preserved in the
  `codex-skill-surface-acceptance-cutover` plan rollback artifacts only.

## Important Boundaries

- Do not treat either existing repo as clean. Inspect `git status` before using
  either source tree.
- The Claude tree currently has unrelated local changes. Preserve them.
- Do not symlink or version the whole `~/.codex/config.toml`; the existing
  Codex model syncs a managed hook block instead.
- Do not track runtime state: auth, history, sessions, logs, caches, plugin
  install artifacts, local generated state, or secrets.
- Use dry-run-first workflows for install/link/render/drift-audit changes.

## First Source Document

- Start with:
  `docs/source/inventory-target-architecture.md`

## Next Intended Work

1. Review the target architecture.
2. Build a source inventory and manifest schema.
3. Use one low-risk domain, probably `reporting`, as the first proof of concept.
4. Render or link Codex and Claude target surfaces from the shared source.
5. Add drift audit before mutating live runtime homes.
