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

- `agent-docs` is no longer a manual per-task step. Required-doc and validation
  policy is data each repository declares in its `AGENT_DOCS.toml` catalog
  (`[[document]]` + `[[validation]]`); the harness delivers it:
  - Always-on home policy is auto-loaded (this file).
  - Per-intent docs (for example `project-dev`, `task-tools`) are injected by
    the UserPromptSubmit hook via `agent-docs preflight --intent <intent>`;
    read them before writing.
  - Repo health — install-symlink wiring, declared-doc presence and validity,
    and catalog validity — is checked by `agent-docs audit` in CI and the daily
    SessionStart healthcheck.
- Before declaring a code-editing task done, run the validation the active
  intent declares (surfaced in the injected preflight). The finish-line gate
  blocks a stop when code was edited but the declared validation did not run;
  state an explicit waiver to release it.
- Inspect a repo's requirements on demand with `agent-docs preflight --intent
  <intent>` or `agent-docs explain --intent <intent>`; manage a project-local
  catalog with `agent-docs init` / `list` / `remove`.
- docs-home is derived from the install symlink (`~/.claude/CLAUDE.md` /
  `~/.codex/AGENTS.md`); pass `--docs-home` only to override it. Do not use
  `$HOME/.agents` or `$AGENT_HOME` as docs-home (`$AGENT_HOME` is for
  `agent-out` runtime artifacts; `$HOME/.agents` is retired).
- The `resolve` / `baseline` / `scaffold-*` / `add` / `contexts` commands and
  the `startup` per-task context were retired in the engine redesign.

## Work Mode

- Natural-language collaboration is the default interface.
- Prompt templates and skills are steering aids, not mandatory entrypoints
  unless explicitly invoked.
- For explicit implementation, maintenance, validation, or delivery requests:
  honor the Required Preflight policy, then execute instead of prolonging
  planning.
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

## Work Tier Levels

- Classify every substantive work request into the lowest applicable tier and
  use that tier's method; never run light work through a heavy tier. Tiers:
  L0 direct / PR-only, L1 follow-up issue, L2 plan tracking issue, L3 dispatch
  plan. PR delivery is the shared floor under every tier; an
  implementation-readiness doc is an optional spec attached to any tier, not a
  tier itself.
- At the start of such work, state the tier and the recommended next step. When
  the tier is L1+ (a durable provider artifact or heavier path) or the
  classification is ambiguous, surface the level and next step as a decision and
  wait; for an unambiguous L0, say so and proceed. Re-triage if the work
  escalates mid-flight.
- Full ladder, escalation judge, per-tier methods, and the proactive-triage
  contract: `core/policies/work-tier-levels.md` (injected for `project-dev`).

## Evidence, Memory, And External Facts

- Use traceable citations when source material materially affects a
  requirement, feasibility, work, or external-fact claim.
- Source tags: `[U#]` user input (record in English, paraphrasing
  non-English input), `[F#]` local files/code/docs, `[W#]` web
  source, `[A#]` app/API/CLI/tool result, `[I#]` inference from cited facts.
- Do not present unsupported assumptions as facts.
- For external, unstable, or time-sensitive claims, run `task-tools` preflight,
  prefer authoritative sources, and cite the evidence used.
- External-fact workflow and source tags: `core/policies/external-facts.md`
  (required for `task-tools`). The CLI tool catalog remains available on demand
  as optional `task-tools` context in `core/policies/cli-tools.md`.
- Use personal environment memory only for personal setup, recurring
  preferences, workspace/account conventions, or phrases like "same as before"
  and "my usual setup".
- Do not use memory for secrets, temporary task state, or project state.

## Files, Hooks, And Validation

- Follow the active project's conventions for deliverables and generated
  files.
- Keep temporary/debug artifacts out of `/tmp`: put them under the runtime-kit
  state out tree (via `agent-out`) and reference that path in the reply.
- Do not create durable discussion or decision artifacts unless asked,
  required by project rules, or clearly reusable.
- Hooks may enforce mechanical guardrails, but hooks do not replace policy.
- Prefer project-defined validation commands. If none exist, run the smallest
  meaningful checks and report what was or was not run.
- Artifact paths, `agent-out` usage, hook source / sync, and `agent-run exec`
  mechanics: `core/policies/files-hooks-validation.md` (injected for
  `project-dev`).

## Git, Commits, Issues, PRs, And MRs

- Always use the `semantic-commit` skill; direct `git commit` is blocked by
  hook.
- Use `git-cli worktree` for agent worktree lifecycle; direct mutating
  `git worktree` commands are blocked by hook.
- Do not enable `extensions.worktreeConfig`, set per-worktree identity/signing
  config, or use `--no-gpg-sign` for tracked work. If signing fails, stop and
  report the blocker.
- For agent-owned provider issues, PRs, and MRs, use the active workflow or
  `forge-cli` surface; direct `gh pr create` or `glab mr create` are blocked by
  hook.
- Pre-commit: follow `DEVELOPMENT.md` to run the relevant tests/checks before
  committing.
- Never force-push `main`.
- Commit body gate, managed worktree paths, branch naming, label selection, and
  PR/MR body format: `core/policies/git-delivery.md` (injected for
  `project-dev`).

## Plan Archive

- The agent-plan-archive stores past plans, issues, PRs, and MRs for recurring
  implementation context.
- Consult it only before opening a new plan, or when diagnosing a suspected
  recurring or previously resolved problem — not as a per-task or background
  step.
- Discover with `plan-archive catalog` (`--grep` keyword, `--area`, or
  `--refs-to <url>` for ref→plan reverse lookup) when the exact ref is
  unknown. Plain `--grep` matches catalog metadata only; add `--deep` to
  also match issue/PR/MR body and comment text, or `plan-archive search
  <term>` for hit-level full-text results with snippets. Fetch a known
  candidate with `plan-archive query --ref`, `--plan`, or `--repo`.
- Check each result's `fetched_at` before relying on it; refresh on demand.

## Session Closeout

`core/policies/heuristic-system/HEURISTIC_SYSTEM.md` is the full routing policy
for turning workflow failures and repeated lessons into durable knowledge.

- Same-turn transient fixes need no retained record; mention them in the reply.
- Important unresolved workflow gaps or suspected nils-cli / primitive bugs go
  through `heuristic-inbox`, with version, minimal repro, upstream issue link
  when found, and the current workaround.
- Reproducible product bugs get a focused test or script fix. Repeated
  cross-skill lessons belong in operation records; stable policy belongs in
  `AGENT_HOME.md`, project policy files, or the relevant skill `SKILL.md`.
- Active inbox entries live under
  `core/policies/heuristic-system/error-inbox/`; archive promoted or `wontfix`
  entries via `heuristic-inbox`, never by deleting them in place.
- After the session goal is achieved, run `$heuristic-session-closeout` to
  review available evidence and preserve warranted retained records on `main`.
