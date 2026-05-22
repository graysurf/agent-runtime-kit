# Shared Hooks Runtime Discussion Source

- Status: implemented in this branch
- Date: 2026-05-22
- Source: user request to move agent-kit and claude-kit hooks into
  `agent-runtime-kit`, keep product harness differences where required, and
  create a new worktree for the work.
- Scope: migrate hook source, define a shared hook layout, preserve product
  activation surfaces, and add local hook contract validation.

## Execution

- Recommended plan: docs/plans/07-shared-hooks-runtime/07-shared-hooks-runtime-plan.md
- Recommended execution state: docs/plans/07-shared-hooks-runtime/07-shared-hooks-runtime-execution-state.md

## Purpose

`agent-kit` and `claude-kit` both carried near-duplicate hook scripts for
commit hygiene, PR/MR creation, Python execution, project memory writes, MCP
secret scans, portable path scans, agent-docs reminders, skill-usage reminders,
session health, PR readiness, and scope-lock validation. The runtime-kit target
architecture already says hooks should be owned by `agent-runtime-kit`; this
work turns that design into a concrete source layout.

## Confirmed Facts

- [U1] The requested outcome is a complete hook migration from agent-kit and
  claude-kit into this repo.
- [U2] Shared behavior should have one shared implementation; product-specific
  harness differences can remain separate.
- [U3] The work must happen in a new worktree.
- [F1] agent-kit stores Codex hooks under `$HOME/.config/agent-kit/hooks/codex/`.
- [F2] claude-kit stores Claude hooks under `$HOME/.config/claude/hooks/`.
- [F3] `docs/source/inventory-target-architecture.md` defines
  `core/hooks/` as portable hook logic and `targets/<product>/hooks/` as
  product activation.
- [F4] `targets/<product>/link-map.yaml` drives runtime install surfaces.

## Decisions

1. Use `core/hooks/shared/` as the canonical shared hook source for scripts
   whose behavior is the same across products.
2. Keep Codex managed-block activation under `targets/codex/hooks/`; keep the
   Claude settings fragment next to hook source until nils-cli has a structural
   settings merge surface.
3. Use product environment variables such as `AGENT_RUNTIME_PRODUCT` to tune
   labels, cache keys, and docs-home hints without forking whole scripts.
4. Keep legacy bypass and suppress env vars accepted where the old hooks used
   them, but add neutral `AGENT_RUNTIME_*` env names for the runtime-kit
   surface.
5. Link shared hook scripts through product link maps. Codex also gets a
   managed `config.toml` hook block. Claude gets a checked-in
   `core/hooks/claude/settings.hooks.jsonc` fragment, but not a whole
   `settings.json` replacement.

## Scope

- In scope:
  - Shared hook scripts and catalog under `core/hooks/shared/`.
  - Codex hook config source under `targets/codex/hooks/`.
  - Claude hook settings fragment under `core/hooks/claude/`.
  - Link-map entries that install shared hook scripts for both products.
  - Codex managed-block activation through `targets/codex/link-map.yaml`.
  - Contract tests under `tests/hooks/`.
  - CI wiring for the hook contract smoke.
- Out of scope:
  - Replacing a user's full `$HOME/.claude/settings.json`.
  - Mutating live `$HOME/.codex` or `$HOME/.claude`.
  - Adding new nils-cli structural JSON merge behavior in this repo.
  - Rewriting hook semantics beyond the compatibility needed to share source.

## Acceptance Criteria

1. The migrated hook source includes all tracked agent-kit Codex hook scripts
   and the skill-usage reminder catalog.
2. Common hook behavior runs from one shared script directory.
3. Codex and Claude target surfaces reference the same installed script names.
4. Direct git commit, non-trivial semantic-commit without body, bare Python in
   managed repos, direct PR creation, project memory writes, MCP secrets,
   portable local paths, and skill-usage prompts have hook coverage.
5. `agent-runtime install --dry-run` includes shared hook script installation
   for both products and Codex config managed-block activation.
6. The repo CI gate runs the hook contract smoke.

## Risks And Guardrails

- Claude settings activation is intentionally a fragment in this branch. The
  current install managed-block helper appends blocks; using it to inject a
  top-level `hooks` object into an existing JSON settings file would risk
  corrupting user-owned settings.
- Legacy product env vars remain accepted so old skill wrappers do not break
  during the migration window.
- Runtime state, auth, history, sessions, caches, and full product config files
  remain out of tracked source.

## Read First References

- `docs/source/inventory-target-architecture.md`
- `targets/codex/link-map.yaml`
- `targets/claude/link-map.yaml`
- `core/hooks/shared/`
- `targets/codex/hooks/config.block.toml`
- `core/hooks/claude/settings.hooks.jsonc`
