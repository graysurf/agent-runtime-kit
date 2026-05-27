# Retire claude-kit Scripts Discussion Source

- Status: ready for plan execution
- Date: 2026-05-23
- Source: user discussion on whether `~/.claude/scripts/` can be removed,
  followed by the constraint that claude-kit is being deprecated and no new
  reference to claude-kit should be added.
- Intended next step: execute this plan inside agent-runtime-kit so the live
  `~/.claude/scripts/` install surface stops resolving through claude-kit and
  is owned by `agent-runtime-kit` exclusively.

## Execution

- Recommended plan: docs/plans/2026-05-23-retire-claude-kit-scripts/retire-claude-kit-scripts-plan.md
- Recommended execution state: docs/plans/2026-05-23-retire-claude-kit-scripts/retire-claude-kit-scripts-execution-state.md

## Purpose

`~/.claude/scripts/` currently resolves to `~/.config/claude/scripts/` in the
claude-kit repo. Claude Code home-scope policy, hooks, meta skills, and most
plugin surfaces have already moved into `agent-runtime-kit`; the remaining
scripts directory is the last live install surface still owned by claude-kit.
claude-kit is now scheduled for retirement, so this surface needs to land in
`agent-runtime-kit` before the claude-kit checkout can be removed. Anything
that does not deserve to survive that move should be dropped here.

The plan also resolves the parallel question for slash commands under
`~/.claude/commands/`. The commands directory is symlinked into claude-kit
today, so the same migration moment must take ownership of any commands that
back the migrated scripts.

## Confirmed Facts

- [U1] claude-kit is being deprecated; no new references to claude-kit should
  be added from now on.
- [U2] Anything that has to keep working must live in `agent-runtime-kit`;
  unmanaged plain files inside `~/.claude/` are not acceptable.
- [U3] The cleanup must let the next session pick the work up directly without
  re-litigating the decision matrix.
- [F1] `~/.claude/scripts/` is a symlink to `~/.config/claude/scripts/`
  (claude-kit repo working tree).
- [F2] claude-kit `scripts/` contains: six slash-command dispatchers
  (`bench.sh`, `bootstrap.sh`, `demo.sh`, `deploy.sh`, `release.sh`,
  `pre-pr.sh`), three Claude-only operator helpers (`doctor.sh`,
  `memory-snapshot.sh`, `upstream-drift.sh`), one runtime-agnostic scaffolder
  (`new-project-skill.sh`), one runtime-agnostic adapter binary
  (`plan-issue-adapter`), claude-kit's own CI gate library
  (`scripts/ci/*.sh`), and claude-kit install wiring (`_plugins.env`,
  `_symlinks.env`).
- [F3] The six dispatchers each `exec` the active repo's
  `.agents/scripts/<name>.sh`. The runtime-agnostic equivalent already exists
  as `plugin:meta:<name>` skills under `targets/<runtime>/plugins/meta/`,
  installed for both Codex and Claude through link maps.
- [F4] `doctor.sh`, `memory-snapshot.sh`, and `upstream-drift.sh` operate on
  Claude Code's directory layout (`~/.claude/projects/*/memory/`, Claude
  Code's bundled plugin/MCP defaults, `~/.claude/` symlink contract). They
  have no Codex equivalent and cannot be made runtime-agnostic without
  rewriting their behavior.
- [F5] `new-project-skill.sh` scaffolds `.agents/scripts/<bench|pre-pr|...>.sh`
  starters inside a target repo; the behavior is runtime-agnostic and useful
  to both Codex and Claude consumers.
- [F6] `plan-issue-adapter` already accepts
  `--runtime claude|codex|opencode` and is invoked from
  `plugins/dispatch/references/` as `<state-dir>/scripts/plan-issue-adapter`.
- [F7] `scripts/ci/*.sh` is consumed by claude-kit's own
  `.githooks/pre-commit` and `.github/workflows/ci.yml`; the claude-kit repo
  is the only consumer.
- [F8] `~/.claude/commands/` is symlinked into claude-kit too, so the same
  retirement move needs to relocate any command files that back the surviving
  scripts.
- [F9] `agent-runtime-kit/targets/claude/` currently manages plugin manifests
  and skill trees through `link-map.yaml`, but does not yet manage `scripts/`
  or `commands/` surfaces.

## Decisions

1. Drop the six slash-command dispatchers and their matching `commands/*.md`
   entries (`/bench`, `/bootstrap`, `/demo`, `/deploy`, `/release`,
   `/pre-pr`). The `plugin:meta:*` skill family provides the same behavior
   through `.agents/scripts/<name>.sh` exec and is already shipped on both
   Codex and Claude.
2. Move Claude-only maintenance scripts (`doctor.sh`, `memory-snapshot.sh`,
   `upstream-drift.sh`) and their drift baseline JSON into
   `agent-runtime-kit/targets/claude/scripts/`. Wire installation through
   `targets/claude/link-map.yaml` so `~/.claude/scripts/<name>` resolves into
   the runtime-kit checkout.
3. Move `new-project-skill.sh` and the `plan-issue-adapter` binary into a new
   runtime-agnostic `agent-runtime-kit/scripts/` location. Link them through
   `targets/claude/link-map.yaml` for now; Codex linking is deferred until a
   Codex consumer surfaces an explicit need.
4. Introduce a Claude-managed `commands/` surface in arkit
   (`targets/claude/commands/`) and migrate the slash commands that back the
   surviving scripts (`doctor`, `new-project-skill`, plus `memory-clean`
   which is currently a thin skill wrapper and worth preserving).
5. Drop `scripts/ci/*.sh`, `_plugins.env`, `_symlinks.env`, and any
   claude-kit-only wiring (`install.sh`, `uninstall.sh`,
   `.githooks/pre-commit`) once arkit owns the surface and live install is
   verified.
6. Defer deletion of the claude-kit checkout itself to a follow-up step,
   after the live `~/.claude/scripts/` and `~/.claude/commands/` surfaces are
   confirmed to resolve through `agent-runtime-kit`.

## Scope

- In scope:
  - New `targets/claude/scripts/` source directory in arkit.
  - New `targets/claude/commands/` source directory in arkit.
  - New runtime-agnostic `scripts/` entries in arkit for the two portable
    helpers.
  - Link-map entries for every newly added file.
  - Drop list and removal procedure for retired claude-kit assets.
  - Live install verification on the local Claude home.
- Out of scope:
  - Repointing Codex to the new runtime-agnostic helpers.
  - Removing the claude-kit Git checkout or repository.
  - Rewriting any of the migrated scripts' behavior.
  - Replacing the `plugin:meta:*` skills with a different abstraction.

## Open Questions

- Whether `memory-snapshot.sh` retains relevance once Claude Code memory
  consolidation lands a built-in surface; default is to keep it for now.
- Whether `upstream-drift.sh` and `drift-baseline.json` should be promoted to
  an `agent-runtime` subcommand instead of a freestanding script; default is
  to migrate as-is and revisit during the next nils-cli release boundary.
