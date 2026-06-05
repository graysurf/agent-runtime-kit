# Files, Hooks, And Validation

## Purpose

This policy holds the detailed mechanics for where agent output artifacts go,
where hook source and managed config live, and how to run project validation
commands.

It is declared as a `project-dev` document in `AGENT_DOCS.toml` (home scope),
so the harness surfaces it through the hook preflight when implementation work
starts. `AGENT_HOME.md` carries the always-on directives — follow the active
project's conventions, keep debug artifacts out of `/tmp`, do not create durable
discussion artifacts unless asked, hooks do not replace policy, and prefer
project-defined validation. This file is the procedural detail behind them.

## Output Artifacts

- For temporary/debug artifacts without a project-defined output path, create a
  project run directory with `agent-out project --topic <topic> --mkdir`.
- Debug/test artifacts without a project-defined path belong under the
  runtime-kit state out tree
  (`${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/`),
  not `/tmp`; reference that path in the reply.
- Do not override established tool/workflow artifact contracts; use
  `agent-out audit` before cleaning or enforcing the runtime-kit state out tree
  (`${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/out/`).

## Hooks

- Hooks may enforce mechanical guardrails, but hooks do not replace policy.
- Hook source and managed config live under the active hook source checkout plus
  the managed block in the tool's runtime config (Codex `config.toml`, Claude
  `settings.json`).
- Use the installed hook sync command to update the local runtime config; do not
  track or symlink the whole runtime config file.

## Validation

- Prefer project-defined validation commands. If none exist, run the smallest
  meaningful checks and report what was or was not run.
- When running project build, test, validation, or repository-owned script
  commands, prefer `agent-run exec --cwd <repo> -- <command> ...` when available
  so `.envrc` / `.env` handling is explicit in non-interactive agent sessions.
  Do not run `direnv allow` automatically.
