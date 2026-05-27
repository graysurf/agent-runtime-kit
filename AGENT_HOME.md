# AGENT_HOME.md

## Purpose & Scope

- This file defines shared home-scope defaults for the local agent runtime
  layer used by Codex and Claude Code.
- It is git-managed in `agent-runtime-kit` and loaded through:
  - `$CODEX_HOME/AGENTS.md` (normally `$HOME/.codex/AGENTS.md`)
  - `$HOME/.claude/CLAUDE.md`
  Both should symlink directly to this `AGENT_HOME.md` file in the
  checked-out source repo.
- The filename is intentionally not `AGENTS.md` or `CLAUDE.md`, so this source
  repo can also keep project-local policy without double-loading the same
  defaults.
- This must be safe fallback policy for unrelated workspaces. A closer project
  or directory `AGENTS.md` / `CLAUDE.md` can override or extend it.
- Keep this file concise. Detailed workflows belong in docs resolved by
  `agent-docs`.

## Required Preflight

- `agent-docs` is mandatory before implementation, external lookup, skill
  lifecycle work, edits, tests, commits, or delivery.
- Resolve docs from the active `agent-runtime-kit` checkout. Export
  `AGENT_DOCS_HOME=/path/to/agent-runtime-kit` (or pass `--docs-home`) before
  preflight; the catalog lives here, not in retired `$HOME/.config/agent-kit`.
- Do not use `$HOME/.agents` or `$AGENT_HOME` as docs-home. `$AGENT_HOME` is
  for `agent-out` runtime artifacts, and `$HOME/.agents` is retired.
- Always run `startup`, then add one strict context for the active intent:
  - repo edits, tests, commits, or delivery: `project-dev`
  - technical research or external verification: `task-tools`
  - skill lifecycle work: `skill-dev`
- Resolve every required context in strict checklist mode:
  `agent-docs resolve --context <context> --strict --format checklist`
- If any required doc is missing or strict resolve fails, stop write actions
  and run `agent-docs baseline --check --target all --strict --format text`.
- Proceed with edits/tests/commits only when required docs are
  `status=present`.
- New repository bootstrap: run `agent-doc-init`, then rerun the baseline
  check.

## Work Mode

- Natural-language collaboration is the default interface.
- Prompt templates and skills are steering aids, not mandatory entrypoints
  unless explicitly invoked.
- For explicit implementation, maintenance, validation, or delivery requests:
  run required preflight, then execute instead of prolonging planning.
- For business, requirement, feasibility, or customer-facing discussions,
  evaluate first and do not jump to implementation unless asked.
- Treat user-provided or customer-provided material as input to assess, not as
  already-validated truth.
- Ask only the minimum clarification needed when objective, done criteria,
  scope, constraints, environment, or safety/reversibility are materially
  unclear.
- When assumptions are acceptable, state them briefly and proceed.
- When conclusions depend on uncertainty, separate known facts, assumptions,
  inferences, and open questions.
- Before editing code, scripts, docs, or config, inspect the target plus
  relevant definitions, call sites, loading paths, or project rules.
- For testable production behavior changes, prefer failing-test evidence before
  editing production code; when not practical, state an explicit waiver and
  substitute validation before editing.
- Keep answers concise, high-signal, and easy to verify.
- Keep precision-critical technical terms, standards, APIs, commands, and
  proper nouns in English when clearer.

## Delegation

- Subagent delegation is opt-in. Use explicit user instruction or prompt modes
  such as `parallel-first` or `orchestrator-first` before spawning subagents.
- `parallel-first` optimizes for safely parallelizable sidecar work.
- `orchestrator-first` makes the main agent own intent, scope, dispatch,
  integration, validation, and final answer while subagents own implementation
  lanes.
- Outside an explicit delegation mode, follow the runtime harness rules and do
  not treat this file alone as permission to spawn subagents.
- Do not use delegation modes for small changes, unclear requirements, tightly
  coupled refactors, destructive operations, or work whose next step blocks on
  a subagent result.

## Evidence, Memory, And External Facts

- Use traceable citations when source material materially affects a
  requirement, feasibility, work, or external-fact claim.
- Source tags: `[U#]` user input, `[F#]` local files/code/docs, `[W#]` web
  source, `[A#]` app/API/CLI/tool result, `[I#]` inference from cited facts.
- Do not present unsupported assumptions as facts.
- For external, unstable, or time-sensitive claims, run `task-tools` preflight,
  prefer authoritative sources, and cite the evidence used.
- Use personal environment memory only for personal setup, recurring
  preferences, workspace/account conventions, or phrases like "same as before"
  and "my usual setup".
- Do not use memory for secrets, temporary task state, or project state.

## Files, Hooks, And Validation

- Follow the active project's conventions for deliverables and generated
  files.
- For temporary/debug artifacts without a project-defined output path, create
  a project run directory with `agent-out project --topic <topic> --mkdir`.
- Debug/test artifacts without a project-defined path belong under
  `${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/`,
  not `/tmp`; reference that path in the reply.
- Do not override established tool/workflow artifact contracts; use
  `agent-out audit` before cleaning or enforcing the runtime-kit state
  tree (`$AGENT_HOME/out/`, normally
  `${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/out/`).
- Do not create durable discussion or decision artifacts unless asked,
  required by project rules, or clearly reusable.
- Hooks may enforce mechanical guardrails, but hooks do not replace policy.
- Hook source and managed config live under the active hook source checkout
  plus the managed block in the tool's runtime config (Codex `config.toml`,
  Claude `settings.json`).
- Use the installed hook sync command to update the local runtime config;
  do not track or symlink the whole runtime config file.
- Prefer project-defined validation commands. If none exist, run the smallest
  meaningful checks and report what was or was not run.
- When running project build, test, validation, or repository-owned script
  commands, prefer `agent-run exec --cwd <repo> -- <command> ...` when
  available so `.envrc` / `.env` handling is explicit in non-interactive agent
  sessions. Do not run `direnv allow` automatically.

## Git, Commits, Issues, PRs, And MRs

- Always use the `semantic-commit` (or `semantic-commit-autostage`) skill;
  direct `git commit` is blocked by hook, and the body gate enforces 1-2
  bullets on non-trivial commits.
- Pre-commit: follow `DEVELOPMENT.md` to run the relevant tests/checks before
  committing.
- For agent-owned provider issues, PRs, and MRs, use the active workflow or
  `forge-cli` surface instead of raw provider commands. Direct `gh pr create`
  or `glab mr create` are blocked by hook; PR/MR delivery should go through
  the active delivery skill.
- Labels describe the record's type, area, state or size, and workflow for
  triage and automation. When the active project provides
  `manifests/forge-labels.yaml`, select labels from that catalog and follow
  `core/policies/forge-label-taxonomy.md`; current CLI / skill surfaces handle
  ensure, validation, and application details.
- Branch: `feat/<slug>` or `fix/<slug>` (lowercase, hyphenated, 3-6 words;
  ticket id `ABC-123` becomes `feat/abc-123-<slug>`).
- Draft an accurate 1-2 sentence summary grounded in the actual diff before
  opening; never derive title or body from `git log -1`.
- Never force-push `main`.

## Session Closeout

`core/policies/heuristic-system/HEURISTIC_SYSTEM.md` is the detailed routing
policy for turning workflow failures and repeated lessons into durable
knowledge; the startup preflight surfaces its routing summary via the
`agent-docs` global pointer. After the session goal is achieved, run
`$heuristic-session-closeout` to review available evidence and preserve
warranted retained records on `main`.
