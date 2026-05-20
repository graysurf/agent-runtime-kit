# Agent Runtime Kit Inventory And Target Architecture

Date: 2026-05-20
Status: source document for the first implementation discussion

## Purpose

Create one maintained source of truth for the local agent runtime layer that is
currently split between:

- `$HOME/.config/agent-kit`
- `$HOME/.config/claude`

The new repository should own shared skills, workflows, hooks, policy docs,
plugin metadata, install/link management, and drift detection. Codex and Claude
should become product targets rather than separate source repositories.

## Current State Inventory

### `agent-kit`

Path: `$HOME/.config/agent-kit`

Observed role:

- Current Codex-oriented source of truth.
- `$HOME/.agents` is a symlink to this repo.
- `$HOME/.codex/AGENTS.md` links to `$HOME/.agents/CODEX_AGENTS.md`.
- Codex hook source lives under `hooks/codex/`.
- Codex hook activation is managed by syncing a managed block into
  `$HOME/.codex/config.toml`, not by symlinking the full config file.
- Public skills use a multi-level layout under `skills/`, for example:
  `skills/workflows/...`, `skills/tools/...`, `skills/automation/...`.

Observed skill count:

- `77` unique `SKILL.md` directories under `$HOME/.config/agent-kit/skills`.

Important existing contract:

- Do not track or symlink the whole Codex `config.toml`.
- Preserve product-local runtime state such as auth, logs, history, cache,
  sessions, and generated runtime files outside the canonical source tree.

### `claude-kit`

Path: `$HOME/.config/claude`

Observed role:

- Current Claude Code extension repo.
- `install.sh` links tracked surfaces into `$HOME/.claude`.
- `scripts/_symlinks.env` is the canonical symlink list for Claude surfaces.
- User-global root skills still exist under `skills/<name>/SKILL.md`.
- Most recently organized skills live under plugin roots:
  `plugins/<domain>/skills/<skill>/SKILL.md`.
- Claude plugin manifests use `.claude-plugin/plugin.json`.
- Claude local marketplace lives at `.claude-plugin/marketplace.json`.

Observed skill count:

- `84` unique `SKILL.md` directories across `$HOME/.config/claude/plugins`
  and `$HOME/.config/claude/skills`.

Important existing contract:

- Claude has flatter runtime skill discovery than Codex.
- The Hybrid C plugin reorganization moved many skills from user-level
  `skills/` into plugin roots, but path references can still drift if scripts,
  tests, or docs assume legacy top-level skill locations.
- Current `claude-kit` working tree has unrelated local changes; migration work
  must inspect and preserve them rather than treating the tree as clean.

### GitHub Repositories

- `graysurf/agent-kit`: public, default branch `main`.
- `graysurf/claude-kit`: private, default branch `main`.
- `graysurf/agent-runtime-kit`: private, default branch will be established by
  the initial commit.

## Target Architecture

The repository should be structured around one canonical source and explicit
product adapters:

```text
agent-runtime-kit/
  core/
    policies/
    skills/
      <domain>/<skill>/
    hooks/
    docs/
    scripts/
  targets/
    codex/
      AGENTS.md.template
      config.block.toml
      plugins/<domain>/.codex-plugin/plugin.json
      link-map.yaml
    claude/
      CLAUDE.md.template
      AGENTS.md.template
      settings.json.template
      plugins/<domain>/.claude-plugin/plugin.json
      link-map.yaml
  manifests/
    skills.yaml
    plugins.yaml
    product-capabilities.yaml
  scripts/
    install
    uninstall
    doctor
    render-target
    audit-drift
```

### Core Layer

`core/` owns portable intent and implementation:

- shared skill bodies and assets
- shared scripts
- shared workflow contracts
- shared policy docs
- shared hook source when behavior is product-independent
- canonical domain grouping

The core layer should not contain runtime-home paths such as `~/.codex` or
`~/.claude` except in examples or adapter documentation.

### Product Adapter Layer

`targets/codex/` owns Codex-specific activation:

- `CODEX_AGENTS.md` / `AGENTS.md` rendering
- `.codex-plugin/plugin.json` generation or storage
- Codex plugin marketplace entries
- managed hook block for `~/.codex/config.toml`
- Codex-specific skill root or plugin path rules

`targets/claude/` owns Claude-specific activation:

- `CLAUDE.md` / `AGENTS.md` rendering
- `.claude-plugin/plugin.json` generation or storage
- Claude marketplace entries
- `settings.json` hook registration
- flat skill adapters or plugin-root skill layout

Product adapters may contain wrappers or compatibility shims, but durable
workflow instructions should remain in `core/` whenever possible.

### Manifest Layer

`manifests/` should make the source of truth machine-checkable:

- `skills.yaml`: skill id, domain, source path, supported products, aliases,
  product-specific names, required tools, and portability notes.
- `plugins.yaml`: domain plugin metadata, contained skills, product manifests,
  dependencies, and install policy.
- `product-capabilities.yaml`: product differences such as nested skill support,
  plugin manifest schema, hooks model, config activation, and runtime state
  boundaries.

The manifest layer is the right place to record intentional Codex/Claude
differences so they do not become undocumented drift.

## Install And Link Strategy

The installer should manage links and rendered files explicitly. It should never
blindly replace an entire runtime home.

Recommended behavior:

1. Render product target files into a build or generated target directory.
2. Link only approved files/directories into `~/.codex` and `~/.claude`.
3. Sync mutable config via managed blocks where the product stores local state in
   the same file.
4. Back up existing non-symlink files before replacing them.
5. Preserve runtime state directories and secrets.

Product-specific examples:

- Codex: link `~/.codex/AGENTS.md`, sync managed hooks into
  `~/.codex/config.toml`, register/install local plugins when supported, and
  leave auth/history/logs/cache untouched.
- Claude: link approved files from the canonical link map into `~/.claude`,
  register the local plugin marketplace, install configured plugins, and leave
  projects/history/session/cache/plugin install artifacts untouched.

## Drift Detection

The project needs first-class drift audit because Codex and Claude will continue
to evolve independently.

`scripts/audit-drift` should check:

- source manifest versus rendered target files
- rendered target files versus live symlink destinations
- product plugin manifests versus marketplace entries
- live runtime config managed blocks versus source blocks
- skill inventory differences across products
- local runtime paths that should never be tracked
- known intentional product differences from `product-capabilities.yaml`

The audit should classify findings:

- `missing`: source says a surface should exist but it does not
- `stale`: live/rendered content differs from source
- `extra`: live surface exists but is unmanaged
- `intentional-difference`: documented divergence
- `unsafe`: secret/runtime/cache/history material appears in a tracked surface

## Proof Of Concept Scope

Recommended first domain: `reporting`.

Why:

- Small enough for a pilot.
- Contains useful cross-product workflow behavior.
- Exercises plugin packaging and skill references without touching high-risk PR,
  CI, or dispatch delivery paths.
- Current Claude plugin already has `daily-brief` and `project-retro`; current
  agent-kit also has `topic-radar` under market research, so the pilot will
  expose real domain-boundary decisions.

POC deliverables:

1. Create `core/skills/reporting/` with canonical source for the chosen skills.
2. Create Codex adapter metadata for a `reporting` plugin.
3. Create Claude adapter metadata for a `reporting` plugin.
4. Add a manifest entry for each skill and plugin.
5. Add a render or link script for this one domain.
6. Add a drift audit that compares source, rendered files, and live target paths.
7. Verify that `AGENTS.md` / runtime-home files remain outside version control
   unless explicitly intended.

## Migration Phases

### Phase 1: Inventory And Schema

- Freeze current inventory from `agent-kit` and `claude-kit`.
- Define `skills.yaml`, `plugins.yaml`, and `product-capabilities.yaml`.
- Decide naming for product-specific aliases.
- Decide whether product adapters are generated, hand-maintained, or hybrid.

### Phase 2: Reporting POC

- Migrate one low-risk domain.
- Render Codex and Claude targets.
- Validate local activation without disturbing current production homes.
- Add drift audit for the pilot.

### Phase 3: Installer

- Add dry-run-first install.
- Add uninstall and doctor.
- Preserve the existing Claude `_symlinks.env` model as a design input.
- Preserve the existing Codex managed-block model for `config.toml`.

### Phase 4: Domain Migration

Suggested order:

1. `reporting`
2. `media`
3. `browser`
4. `evidence`
5. `meta`
6. `pr`
7. `dispatch`
8. project/company/private overlays

High-risk domains such as `pr` and `dispatch` should migrate only after the
installer and drift audit are reliable.

## Open Questions

- Should `agent-runtime-kit` eventually replace both repos, or should
  `agent-kit` remain the public portable framework while this repo manages the
  private cross-product runtime?
- Which domains should stay private because they include company or local
  workspace assumptions?
- Should Codex use plugin-first packaging for all domains, or keep multi-level
  skill roots for some local-only workflows?
- Should Claude flat root skills become generated adapters from plugin/core
  source?
- What is the minimum compatibility target for Codex and Claude versions?

## Next Session Checklist

1. Confirm this target architecture.
2. Decide whether the first POC domain is `reporting`.
3. Build the manifest schema.
4. Import the current reporting-domain source files.
5. Add render and drift-audit scripts for the pilot only.
6. Validate without mutating live `~/.codex` or `~/.claude` until the dry-run
   output is reviewed.

