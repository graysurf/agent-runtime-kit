# AGENT_HOME.md

## Purpose & Scope

- This file defines home-scope/global defaults for the local agent runtime
  layer, shared by both Codex and Claude Code.
- It is git-managed in `agent-runtime-kit` and live-loaded through:
  - `$CODEX_HOME/AGENTS.md` (normally `$HOME/.codex/AGENTS.md`)
  - `$HOME/.claude/CLAUDE.md`
  Both symlinks should point directly at this `AGENT_HOME.md` file in the
  checked-out source repo.
- It intentionally uses the `AGENT_HOME.md` name, not `AGENTS.md` or
  `CLAUDE.md`, so neither Codex nor Claude reads the same policy twice when
  this source repository is the active project and a project-local
  `AGENTS.md` / `CLAUDE.md` is also present.
- It must be safe as fallback policy for unrelated workspaces, not only this
  repo.
- A closer project or directory `AGENTS.md` / `CLAUDE.md` can override or
  extend these defaults.
- Keep this file concise. Detailed workflows belong in docs resolved by
  `agent-docs`.

## Default Work Mode

- Natural-language collaboration is the default interface.
- Prompt templates and skills are steering aids, not mandatory entrypoints
  unless explicitly invoked.
- For explicit implementation, maintenance, validation, or delivery requests,
  execute after required preflight instead of prolonging planning.
- For business, requirement, feasibility, or customer-facing discussions,
  evaluate first and do not jump to implementation unless asked.
- Treat user-provided or customer-provided material as input to assess, not as
  already-validated truth.
- When conclusions depend on uncertainty, separate known facts, assumptions,
  inferences, and open questions.

## Delegation Modes

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

## Operating Defaults

- Ask only the minimum clarification needed when objective, done criteria,
  scope, constraints, environment, or safety/reversibility are materially
  unclear.
- When assumptions are acceptable, state them briefly and proceed.
- Before editing code, scripts, docs, or config, inspect the target plus
  relevant definitions, call sites, loading paths, or project rules — not just
  the lines being changed.
- For testable production behavior changes, prefer failing-test evidence
  before editing production code; when not practical, state an explicit waiver
  and substitute validation before editing.
- For external, unstable, or time-sensitive claims, prefer authoritative
  sources and cite the evidence used.
- Keep answers concise, high-signal, and easy to verify.
- Default user-facing language is Traditional Chinese unless requested
  otherwise.
- Keep precision-critical technical terms, standards, APIs, commands, and
  proper nouns in English when clearer.
- Debug/test artifacts: write to
  `${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/`
  instead of `/tmp`, and reference that path in the reply.

## Evidence & Traceability

- Use traceable citations when source material materially affects a
  requirement, feasibility, work, or external-fact claim.
- Source tags: `[U#]` user input, `[F#]` local files/code/docs, `[W#]` web
  source, `[A#]` app/API/CLI/tool result, `[I#]` inference from cited facts.
- Do not present unsupported assumptions as facts.
- If external lookup is needed, run the `task-tools` preflight first.

## Memory Usage

- Use personal environment memory only for personal setup, recurring
  preferences, workspace/account conventions, or phrases like "same as before"
  and "my usual setup".
- Follow the checked-out agent-docs runbook for detailed rules.
- Do not use memory for secrets, temporary task state, or project state.

## `agent-docs` Preflight Policy

- `agent-docs` is the mandatory home-scope dispatch contract before
  implementation, external lookup, or skill lifecycle work.
- `agent-docs` resolves its catalog from `$AGENT_DOCS_HOME` (or the
  `--docs-home` flag). Export `AGENT_DOCS_HOME` to point at the active
  `agent-runtime-kit` checkout (the home-scope docs catalog now lives in
  this repo, not in the retired `$HOME/.config/agent-kit`).
- Do not use `$HOME/.agents` or `$AGENT_HOME` as the docs-home indirection.
  `$AGENT_HOME` is reserved for `agent-out` artifacts (runtime-kit state
  tree). The `$HOME/.agents` alias is retired; live Codex skill discovery
  works from `$HOME/.codex/skills` directly against the runtime-kit build
  output.
- Required context sequence:
  - new session or task: `startup`
  - repository edits, tests, commits, or delivery:
    `startup` → `project-dev`
  - technical research or external verification: `startup` → `task-tools`
  - skill lifecycle work: `startup` → `skill-dev`
- Resolve each required context in strict checklist mode (with
  `AGENT_DOCS_HOME` exported, `--docs-home` may be omitted):
  `agent-docs resolve --context <context> --strict --format checklist`
- Concrete preflight sequence before edits/tests/commits:
  1. Determine runtime intent (`startup`, `project implementation`,
     `technical research`, `skill authoring`).
  2. `agent-docs resolve --context startup --strict --format checklist`
  3. Run the strict gate for the active intent:
     - Project implementation:
       `agent-docs resolve --context project-dev --strict --format checklist`
     - Technical research:
       `agent-docs resolve --context task-tools --strict --format checklist`
     - Skill authoring:
       `agent-docs resolve --context skill-dev --strict --format checklist`
  4. If any required doc is missing or strict resolve fails, stop write
     actions and run
     `agent-docs baseline --check --target all --strict --format text`.
  5. Proceed with edits/tests/commits only when required preflight docs are
     `status=present`.
- New repository bootstrap (missing baseline docs): run `agent-doc-init` and
  then verify with the baseline check above.

## Commit Rules

- Always use the `semantic-commit` (or `semantic-commit-autostage`) skill —
  direct `git commit` is blocked by hook, and the body gate enforces 1–2
  bullets on non-trivial commits.
- Pre-commit: follow `DEVELOPMENT.md` to run the relevant tests/checks before
  committing.

## PR / MR Rules

- Direct `gh pr create` / `glab mr create` are blocked by hook. Use the
  active tool's PR/MR delivery skill (e.g. `forge-cli pr deliver` or the
  matching `pr:deliver-*` skill) which runs preflight → create → wait CI →
  close.
- Branch: `feat/<slug>` or `fix/<slug>` (lowercase, hyphenated, 3–6 words;
  ticket id `ABC-123` → `feat/abc-123-<slug>`).
- Draft an accurate 1–2 sentence summary grounded in the actual diff before
  opening — never derive title / body from `git log -1`.
- Never force-push `main`.

## Files, Hooks, And Validation

- Follow the active project's conventions for deliverables and generated
  files.
- For temporary/debug artifacts without a project-defined output path, create
  a project run directory with `agent-out project --topic <topic> --mkdir`.
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

## Heuristic System

`HEURISTIC_SYSTEM.md` (under `core/policies/heuristic-system/` in the
`agent-runtime-kit` checkout) defines how skill workflow failures get
compressed into durable knowledge. When a skill or nils-cli primitive
misbehaves, gets worked around, or produces a useful lesson, route the
signal by the table below:

| Signal | Route |
| --- | --- |
| Transient failure fixed in the same turn | No durable artifact; mention in reply only |
| Unresolved, important workflow gap | `heuristic-inbox new --from-skill-usage <record>` |
| Reproducible bug | Focused test or script fix |
| Suspected nils-cli / primitive bug | `heuristic-inbox new` with nils-cli version, minimal repro, upstream issue link if found, and skill-side workaround |
| Repeated, cross-skill failure | `heuristic-system/operation-records/<slug>.md` |
| Stable project policy | `AGENT_HOME.md` / project `AGENTS.md` / `CLAUDE.md` / the skill's `SKILL.md` |

For suspected nils-cli / primitive bugs, skim
<https://github.com/sympoies/nils-cli> issues and recent releases before
filing — link the matching upstream issue from the inbox entry instead of
duplicating it. If web access is unavailable, open the inbox entry anyway
and note that the upstream check is pending.

Active inbox lives at `core/policies/heuristic-system/error-inbox/` in the
`agent-runtime-kit` checkout. After an entry is `promoted` or `wontfix`
with no remaining next action, archive it under
`core/policies/heuristic-system/error-inbox/archive/YYYY/` via the
`heuristic-inbox` skill — never delete in place.
