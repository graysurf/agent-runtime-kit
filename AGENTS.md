# AGENTS.md

## Scope

- Repo-local agent policy for `agent-runtime-kit`. Global / home-scope
  defaults live in `AGENT_HOME.md`, loaded by Codex via
  `$HOME/.codex/AGENTS.md` and by Claude via `$HOME/.claude/CLAUDE.md`
  (both symlinks point at this repo's `AGENT_HOME.md`).
- `./CLAUDE.md` in this repo is a one-line file containing `@AGENTS.md`,
  using Claude Code's import syntax so Claude reads the same repo-local
  rules without maintaining a second copy.

## Project Purpose

- Build a new single-source repository for the local agent runtime layer that is
  currently split between `agent-kit` and `claude-kit`.
- The goal is one canonical source for shared skills, workflows, hooks, docs,
  plugin metadata, install/link management, and drift auditing.
- Codex and Claude should become product targets/adapters, not separate source
  repos that require manual porting.

## Local Source Repositories

- Single source of truth: this repo (`agent-runtime-kit`). Codex and Claude
  read it through symlinks (`$HOME/.codex/AGENTS.md`, `$HOME/.claude/CLAUDE.md`
  → `AGENT_HOME.md`) and through rendered targets in `targets/`.
- Live Codex home:
  `$HOME/.codex`
- Live Claude home:
  `$HOME/.claude`
- Retired locations (do not reintroduce):
  - `$HOME/.config/agent-kit` — legacy Codex-oriented source. Removed. Both
    the docs catalog and `out/` artifact tree now live elsewhere
    (`agent-runtime-kit` checkout for docs; `$AGENT_HOME/out/` under
    `${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit` for artifacts).
  - `$HOME/.config/claude` — legacy Claude-oriented source. Replaced by
    rendered output under `targets/claude/` in this repo.
  - `$HOME/.agents` — compatibility alias from earlier Codex sessions. Not
    required for skill discovery; Codex loads runtime-kit skills through
    `$HOME/.codex/skills` directly. Rollback (recreate alias) is preserved
    in the `codex-skill-surface-acceptance-cutover` plan rollback artifacts
    only.

## Important Boundaries

- Do not symlink or version the whole `~/.codex/config.toml`; the existing
  Codex model syncs a managed hook block instead.
- Do not track runtime state: auth, history, sessions, logs, caches, plugin
  install artifacts, local generated state, or secrets.
- Use dry-run-first workflows for install/link/render/drift-audit changes.
- Required env to operate the runtime:
  - `AGENT_HOME` — `agent-out` artifact root, e.g.
    `${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit`. Must not be
    `$HOME/.config/agent-kit`.
  - `AGENT_DOCS_HOME` — `agent-docs` catalog root, e.g. this checkout
    (`$HOME/Project/<org>/agent-runtime-kit`).

## First Source Document

- Start with:
  `docs/source/inventory-target-architecture.md`

## Next Intended Work

1. Review the target architecture.
2. Build a source inventory and manifest schema.
3. Use one low-risk domain, probably `reporting`, as the first proof of concept.
4. Render or link Codex and Claude target surfaces from the shared source.
5. Add drift audit before mutating live runtime homes.
