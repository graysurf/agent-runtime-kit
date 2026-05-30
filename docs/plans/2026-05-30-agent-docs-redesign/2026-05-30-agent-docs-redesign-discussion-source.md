# agent-docs Redesign — Implementation Handoff

- Status: decisions settled; ready for plan generation.
- Date: 2026-05-30
- Source: user-driven full review and no-backward-compatibility redesign
  of the `agent-docs` nils-cli capability (`sympoies/nils-cli`
  `crates/agent-docs`) and its agent-runtime-kit catalog (`AGENT_DOCS.toml`)
  plus hook integration. The user stated the tool's original goal: force
  the agent to notice `DEVELOPMENT.md` and have a high chance of following
  its test/validation process, because agents were repeatedly finishing
  work without running the required validation. The session reframed the
  tool around what the Claude/Codex harness already does (auto-loaded
  policy, lifecycle hooks) and around where enforcement actually has to
  happen (the finish line, not the start).
- Intended next step: generate the plan bundle under
  `docs/plans/2026-05-30-agent-docs-redesign/`. This is a source artifact,
  not an implementation plan.

## Execution

This feeds one cross-repo plan: engine changes land in `sympoies/nils-cli`
(`crates/agent-docs`); catalog, hooks, and home-policy changes land in
`graysurf/agent-runtime-kit`. Sequencing belongs in the plan.

- Recommended plan: docs/plans/2026-05-30-agent-docs-redesign/2026-05-30-agent-docs-redesign-plan.md
- Recommended execution state: docs/plans/2026-05-30-agent-docs-redesign/2026-05-30-agent-docs-redesign-execution-state.md
- Status: decisions settled; plan generation is the next step.
- Next-task source: this document

## Purpose

Re-found `agent-docs` on two truths uncovered in the review:

1. The harness already delivers always-on policy. `AGENT_HOME.md` is
   symlink-auto-loaded into every repo on every session
   (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`). So "force the agent to
   read the global policy" is already solved by the harness, not by
   `agent-docs`.
2. The real pain is end-of-task adherence, not start-of-task presence.
   Agents finish without running the validation in `DEVELOPMENT.md`.
   `agent-docs` only ever checked presence at the start, which
   structurally cannot stop a skipped step at the end. Enforcement must
   move to the finish line.

The redesign principle, in one line:

> Anything the agent must see goes onto a path the harness loads
> (session auto-load, or hook-injected content). Anything the agent must
> *do* is enforced at the finish line (a Stop-hook gate plus the existing
> pre-commit / pre-PR gate), not by a start-time presence check. Policy is
> declared as data by the repo; the binary is a generic resolver and
> auditor, no longer an agent per-task preflight.

### What agent-docs becomes

`agent-docs` stops being an agent-run per-task preflight. It becomes:

- `audit` — repo health, wiring, content validity, and "is the validation
  contract declared," for CI and the daily SessionStart healthcheck.
- `preflight --intent X` — resolve what THIS repo requires for an intent
  (the doc set and the validation contract), emitted in a shape hooks
  consume. Hooks, not the agent, run this.
- catalog management — `init` / `explain` / `list` / `remove`.

Per-task content delivery moves to the harness (auto-load for short
always-on cues; hook-injected awareness cues for intent docs). Enforcement
teeth move to a Stop-hook gate plus the existing pre-PR / commit gate.

## Delivery-Mechanism Classification

The spine of the design: route every required doc to the mechanism that
actually reaches the agent at the right time.

| Doc class | Example | Delivery mechanism | agent-docs role |
| --- | --- | --- | --- |
| Always-on global policy | `AGENT_HOME.md` | harness auto-load (symlink) | audit the wiring only |
| Always-on global short cue | plan-archive, heuristic pointers | inline into `AGENT_HOME.md` (auto-load) | none after migration |
| Project self-policy | repo `AGENTS.md` / `CLAUDE.md` | harness auto-load (cwd) | none |
| Intent-scoped doc | `cli-tools.md`, `DEVELOPMENT.md` | resolved by `agent-docs`; short awareness cue injected at intent; not always-on | resolve + validate |
| Validation contract | `DEVELOPMENT.md` test/validation steps, `pre-pr.sh` | resolved by `agent-docs`; enforced at finish line by Stop-hook + pre-PR/commit gate | resolve the contract |
| Repo health / wiring | symlink intact, docs present/non-empty, catalog valid | `audit` (CI + daily) | the job itself |

## Confirmed Facts (current behaviour)

- [F1] `AGENT_DOCS.toml` declares three extension docs: two
  `context = "startup"`, `scope = "global"` pointers
  (`plan-archive-query-pointer-v1.md`, `heuristic-system-pointer-v1.md`)
  and one `context = "project-dev"`, `scope = "project"` entry
  (`docs-placement-retention-policy-v1.md`). Every entry uses
  `when = "always"`.
- [F2] Contexts, scopes, and the context-to-required-doc mapping are
  hardcoded Rust (`model.rs`, `resolver.rs`). Builtins: `startup` ->
  `AGENTS.md` (for BOTH `home` and `project` scope, preferring
  `AGENTS.override.md`); `skill-dev` -> `DEVELOPMENT.md` (home);
  `task-tools` -> `core/policies/cli-tools.md` (home); `project-dev` ->
  `DEVELOPMENT.md` (project). Changing a builtin needs a nils-cli release.
- [F3] `DocumentWhen` (`model.rs`) has a single value `Always`. The `when`
  field is parsed and validated (`config.rs`) but is functionally inert.
- [F4] The only way to drop a builtin is a project-side `required = false`
  opt-out keyed to the builtin's exact context/scope/path; `startup` can
  never be opted out. Shipped in nils-cli PR #658 / v0.28.6 (the "pure-docs
  repo does not need DEVELOPMENT.md" change).
- [F5] `resolve` and `baseline` only check existence
  (`DocumentStatus::Present|Missing`). Neither reads or returns content,
  validates non-emptiness, or checks freshness. The output is a presence
  report, not content delivery, and nothing checks whether any process ran.
- [F6] `scaffold-baseline` generates template `AGENTS.md` /
  `DEVELOPMENT.md` / `core/policies/cli-tools.md`; command autodetection
  only recognizes Cargo projects. A scaffolded placeholder satisfies the
  presence check.
- [F7] Enforcement is soft and start-only: a UserPromptSubmit hook
  (`user-prompt-agent-docs.sh`) injects a reminder only on hardcoded
  English keywords and self-suppresses when the prompt contains the literal
  string `agent-docs`; a SessionStart healthcheck surfaces baseline gaps
  once per day. Nothing acts at task end, and nothing verifies reading or
  validation.
- [F8] The target-architecture source
  (`docs/source/inventory-target-architecture.md`) states `AGENT_DOCS_HOME`
  is rejected as a target-level default (shell leakage selects the wrong
  policy) and that explicit `--docs-home` is preferred; current practice
  relies on the ambient env var anyway. It also fixes the CLI boundary:
  deterministic logic lives in nils-cli, content/wiring in the kit.
- [A1] Empirical: `resolve --context startup` with `--docs-home` at this
  repo and `--project-path` at an unrelated repo (`sympoies/nils-cli`)
  lists both `scope = "global"` startup pointers as `source=extension-home
  status=present required`, resolved from `docs_home`. The global pointers
  DO propagate to any project-level invocation.
- [A2] Empirical: `dirname(readlink ~/.claude/CLAUDE.md)` equals the kit
  checkout (and `AGENT_DOCS_HOME`) exactly; `~/.codex/AGENTS.md` resolves to
  the same `AGENT_HOME.md`. The kit location is derivable from the install
  symlink without the env var.
- [A3] The harness auto-loads `AGENT_HOME.md` on every session in every
  repo via the home symlinks. It does NOT auto-load the `scope=global`
  pointer files, `cli-tools.md`, or `DEVELOPMENT.md`.

## Problem Statement

`agent-docs` predates the Claude Code harness's auto-loaded prompt file and
lifecycle hooks. Four structural gaps follow:

1. Wrong time. The pain is agents finishing without running validation
   (end-of-task), but `agent-docs` only checks presence at the start
   [F5][F7]. Start-time presence cannot prevent an end-time skip; this is
   why the tool never fixed the pain.
2. Presence, not comprehension or action. It reports a file exists; it
   never delivers content or checks that a process ran. The `scope=global`
   cues are the clearest case: reported `present`, content never delivered,
   so the cross-repo cue is frequently never read [F5][A1][A3].
3. Policy baked into the binary. Contexts and required docs are Rust
   constants [F2]; the `required=false` opt-out [F4] patches defaults that
   are wrong for many repos.
4. Redundant with the harness. The primary global policy is already
   auto-loaded [A3]; making the agent run `resolve` to confirm it exists
   adds nothing.

## Decisions

1. Reframe `agent-docs` from an agent per-task preflight ("check present +
   trust") into non-agent-facing jobs: `audit` (repo health, wiring,
   content validity, contract-declared), `preflight --intent X` (resolve
   what this repo requires, emitted for hooks to consume), and catalog
   management (`init`/`explain`/`list`/`remove`). The agent no longer runs a
   per-task `resolve`.
2. Route every required doc by the delivery-mechanism classification table
   above; build to that table.
3. Make contexts and required docs fully data-driven. Remove hardcoded Rust
   builtins; ship a default catalog in the kit that any repo inherits or
   overrides. Policy changes no longer need a nils-cli release.
4. Replace the `required=false` opt-out with real `when` predicates:
   `path-exists:<glob>` composed with `||` and `&&` (deliberately not a full
   expression language). A pure-docs repo with no `Cargo.toml` /
   `package.json` / `src/**` auto-skips code docs with no manual opt-out.
5. Validate content, not just existence: non-empty, a required marker, and
   an optional `last-reviewed` freshness check. A scaffolded placeholder
   must NOT satisfy the gate.
6. Split enforcement by timing:
   - Start of task: a short, language-agnostic awareness cue injected by
     hook on `project-dev` / `task-tools` intent (the validation commands
     plus "run before declaring done"), not the full doc. No up-front
     PreToolUse edit-block — rejected: wrong moment, high friction, and it
     does not stop end-of-task skipping.
   - Finish of task: a Stop / SubagentStop-hook gate plus the existing
     pre-commit / pre-PR gate. If the repo declares a validation contract
     and the session edited code (non-doc files) but there is no evidence
     the validation ran, block turn-end (or delivery) with the resolved
     commands, allowing an explicit waiver with reason. Proving the
     validation ran (not its correctness) is sufficient for this pain.
7. Retire the `AGENT_DOCS_HOME` env var as a policy-delivery channel. The
   harness symlink delivers the primary policy and the inlined cues. Where
   the kit must still be located (audit, `global` resolution), derive it
   from the install symlink (`dirname(readlink ~/.claude/CLAUDE.md)`); keep
   explicit `--docs-home` for CI and overrides.
8. Retire `startup` as an agent-run per-task preflight. The home-scope
   `AGENTS.md` is auto-loaded, so checking its existence adds nothing. The
   residual "is the symlink intact?" becomes a wiring check in `audit` and
   the daily healthcheck.
9. Migrate the two `scope=global` startup cues inline into `AGENT_HOME.md`
   (heuristic routing summary into `## Session Closeout`; a new
   `## Plan Archive` block for the plan-archive cue), verify auto-load, then
   remove the two `AGENT_DOCS.toml` startup entries. Retire the thin
   `*-v1.md` pointer files; keep `HEURISTIC_SYSTEM.md` as the full policy.
   Order is fixed: inline and verify first, then delete.
10. Collapse the command surface to `audit`, `preflight`, `init`,
    `explain`, `list`, `remove`; dedupe resolved docs by resolved path
    (fixes `AGENTS.md` listed twice when `docs_home == project_path`);
    `audit` reports problems and prints a suggested fix command (it does not
    auto-repair).
11. `init` emits an annotated, human-editable project-local override stub
    (`--print` to stdout; `--dry-run` / `--force` to write). It lists the
    defaults the project inherits as comments, ships commented
    ready-to-uncomment override examples, and embeds the schema and `when`
    syntax inline. It must NOT dump a full copy of the inherited defaults
    (that forks and drifts); a project that needs no override declares no
    required entries. Optionally it detects `Cargo.toml` / `package.json`
    and pre-fills matching `when` examples in comments.
12. Codex finish-line enforcement is a committed deliverable, not a
    Claude-only feature with an optional Codex fallback. It may land in a
    later phase and may use a Codex-native mechanism, but the no-skip
    invariant is non-negotiable: on Codex, a session that edited non-doc
    code cannot reach "done" or delivery without running the declared
    validation or recording an explicit waiver.

## Scope

- `agent-docs` engine redesign in `sympoies/nils-cli`: command surface,
  data-driven catalog schema, `when` evaluator, content validation,
  symlink-derived kit location, resolution of the per-repo validation
  contract for hook consumption.
- agent-runtime-kit integration: a default catalog; inlining the two global
  cues into `AGENT_HOME.md`; a language-agnostic start-of-task awareness
  injection hook; a finish-line validation gate (Claude Stop-hook first;
  Codex enforcement committed, see Decision 12) wired to the resolved
  contract and the existing pre-PR / commit gate; reworking the daily
  healthcheck around `audit`.
- Removals: hardcoded builtins, the `required=false` opt-out,
  `AGENT_DOCS_HOME` as a required env var, the English keyword reminder
  hook, the `startup` per-task preflight step in prose (`AGENT_HOME.md`,
  `DEVELOPMENT.md`, skills, hooks), and the thin pointer files.

## Non-Scope

- An up-front PreToolUse edit/commit block (rejected in Decision 6).
- Verifying that validation passed or was meaningful — only that it ran.
- A general-purpose `when` expression language beyond `path-exists`, glob,
  and boolean composition.
- `agentmemory` or any cross-agent memory work (separate plan).
- Rewriting unrelated nils-cli capabilities or the render / install / drift
  orchestration.
- A historical cleanup pass of existing plan bundles or docs.

## Implementation Boundaries

- nils-cli owns deterministic engine logic: catalog schema parsing, the
  `when` evaluator, content validation, resolution, symlink-derived
  location, and JSON / exit-code contracts. agent-runtime-kit owns catalog
  content, hook source, the inlined `AGENT_HOME.md` cues, and prose. This
  follows the CLI boundary in [F8].
- `agent-docs` RESOLVES the validation contract; it does NOT enforce it.
  Enforcement (start-of-task awareness injection, finish-line Stop gate)
  lives in agent-runtime-kit hooks and the existing pre-PR / commit gate.
- Engine changes ship via a nils-cli release and a tap / `required_clis`
  bump before the kit depends on them. The plan sequences engine-first,
  then kit content, then prose / hook removal.
- Global-cue migration order is fixed: inline into `AGENT_HOME.md` and
  verify auto-load, THEN remove the `AGENT_DOCS.toml` startup entries.
- Claude is the first implementation target for the hooks; Codex
  finish-line enforcement is a committed later-phase deliverable
  (Decision 12), implemented via whatever non-bypassable choke point Codex
  provides. Codex content-injection fidelity is verified in the plan.

## Requirements

1. A data-driven catalog schema replaces hardcoded builtins; contexts and
   required docs are declared, not compiled in.
2. `when` supports `path-exists:<glob>` with `||` / `&&`, evaluated against
   the resolved project root.
3. Content validation (non-empty + marker; optional freshness) is part of
   `audit` and `preflight`; placeholders fail.
4. `preflight --intent X` returns the non-auto-loaded doc set and the
   per-repo validation contract for that intent, in a shape hooks consume.
5. The kit location is derived from the install symlink when `--docs-home`
   is absent; the `AGENT_DOCS_HOME` env var is no longer required.
6. A language-agnostic hook injects a short awareness cue (the validation
   commands + "run before declaring done") on `project-dev` / `task-tools`
   intent; the English keyword reminder hook is removed.
7. A finish-line Stop / SubagentStop-hook gate blocks turn-end when the repo
   declares a validation contract, the session edited non-doc code, and
   there is no evidence the validation ran; it surfaces the resolved
   commands and accepts an explicit waiver with reason. It integrates with
   the existing pre-PR / commit gate.
8. The two `scope=global` startup cues are delivered via `AGENT_HOME.md`
   auto-load, and the corresponding `AGENT_DOCS.toml` entries are removed.
9. `audit` reports wiring (symlink intact and pointing at the kit), declared
   docs present and content-valid, and catalog validity, with a suggested
   fix command.
10. Resolved docs are de-duplicated by resolved path.
11. `init` emits an annotated override stub (stdout via `--print`; write via
    `--dry-run` / `--force`) that shows inherited defaults as comments,
    provides ready-to-uncomment override examples plus inline schema and
    `when` syntax, and never writes a full copy of the inherited defaults.
12. The finish-line validation gate (Requirement 7) is delivered for Codex
    as well as Claude. It may ship in a later phase and use a Codex-native
    choke point (a Stop-equivalent lifecycle event if one exists, otherwise
    the commit / delivery path Codex already routes through). The plan must
    identify the Codex mechanism and must not leave a Codex path where the
    gate is silently skippable.

## Acceptance Criteria

- A pure-docs repo (no `Cargo.toml` / `package.json` / `src/**`) requires no
  manual opt-out: code docs are auto-skipped via `when`.
- A zero-byte or placeholder required doc fails `audit` and `preflight`.
- With `AGENT_DOCS_HOME` unset and `--docs-home` omitted, `audit` locates
  the kit via the symlink and reports correctly; an intact setup is green.
- In a Claude session the plan-archive and heuristic cues are present in
  context with no agent-run `resolve` step (auto-loaded), and the
  `AGENT_DOCS.toml` startup entries are gone.
- On `project-dev` intent, the short validation awareness cue is injected.
- A session that edits non-doc code and tries to stop without running the
  declared validation is blocked with the resolved commands; running them
  (or giving an explicit waiver) lets it stop.
- The same finish-line gate holds on Codex: a session that edited non-doc
  code cannot reach done or delivery without running the declared validation
  or recording an explicit waiver. The mechanism may differ from Claude, but
  it must not be silently skippable.
- `agent-docs <command> --help` shows only `audit`, `preflight`, `init`,
  `explain`, `list`, `remove`; `resolve` / `baseline` / `scaffold-*` and the
  `startup` per-task step are gone.
- `agent-docs init --print` outputs a valid, rumdl-clean annotated
  `AGENT_DOCS.toml` stub that lists inherited defaults as comments and
  declares no required entries by default; a fresh project that runs it and
  makes no edits adds zero new requirements.
- nils-cli integration tests are updated to the new surface; the kit CI gate
  stack (`scripts/ci/all.sh`) and hook tests (`tests/hooks/run.sh`) pass.

## Findings Table (review basis)

| Priority | Issue | Evidence | Fix location | Acceptance |
| --- | --- | --- | --- | --- |
| P1 | Enforcement at wrong time: start-presence cannot stop end-of-task skipping | [F5][F7] | kit Stop-hook + pre-PR gate | Finish-line gate blocks stop when validation unrun |
| P1 | Checks existence, not comprehension; content never delivered | [F5][A1][A3] | kit hooks + nils-cli | Cues auto-loaded; intent cues injected |
| P1 | Policy baked into the binary; release needed to change | [F2] | nils-cli engine | Data-driven catalog |
| P1 | `AGENT_DOCS_HOME` ambient env footgun; contradicts own policy | [F8][A2] | nils-cli + kit | Symlink-derived location; env optional |
| P2 | `required=false` opt-out coarse and backwards | [F4] | nils-cli engine | `when` predicates auto-skip |
| P2 | `when` field inert (only `Always`) | [F3] | nils-cli engine | `when` predicates implemented |
| P2 | Reminder hook English-keyword-fragile and ignorable | [F7] | kit hook | Language-agnostic cue injection |
| P3 | No content/freshness validation; stubs pass | [F5][F6] | nils-cli engine | Non-empty + marker fails stubs |
| P3 | `resolve`/`baseline` overlap; `startup` lists `AGENTS.md` twice | [F2] | nils-cli engine | Collapsed commands; dedupe by path |
| P3 | `add` without `list`/`remove`; `scaffold-*` naming overlap | [F2][F6] | nils-cli engine | `init` + `list`/`remove` symmetry |

## Risks And Guardrails

- Stop-hook false positives could block legitimate stops. Guardrail: only
  trigger when non-doc code was edited AND a contract is declared; always
  accept an explicit waiver with reason; default to warn-then-block, not
  silent lock-out.
- "Evidence the validation ran" is heuristic. Guardrail: prefer a marker
  written by `pre-pr.sh` / the validation command over scraping history;
  the plan defines the marker contract.
- Codex may lack a Claude-style Stop event. This affects the mechanism, not
  whether Codex enforces the gate (committed in Decision 12). Guardrail: if
  no Stop-equivalent exists, enforce at the commit / delivery choke point
  Codex already routes through; the plan must confirm a non-bypassable path
  and must not ship a skippable Codex fallback. Claude lands first.
- Inlining cues grows the always-loaded prompt. Guardrail: only short cues
  move inline; large docs (`cli-tools.md`) stay intent-scoped; keep inlined
  cues terse.
- Symlink-derived location couples to the install convention. Guardrail:
  `--docs-home` remains the explicit override; `audit` flags a broken or
  missing symlink rather than failing silently.
- Removing `startup` from prose touches `AGENT_HOME.md`, `DEVELOPMENT.md`,
  skills, and hooks. Guardrail: sequence after the cue migration and after
  the engine ships, so prose never points at removed behaviour.

## Validation Plan

- nils-cli: unit/integration tests for catalog schema parsing, `when`
  evaluation, content validation, symlink-derived location, validation-
  contract resolution, and the collapsed command surface; `--help` snapshot
  updated.
- agent-runtime-kit: `bash scripts/ci/all.sh` (gate stack),
  `bash tests/hooks/run.sh` (awareness injection + Stop-gate behaviour), and
  `rumdl check` on changed Markdown.
- Manual: a Claude session in an unrelated repo confirms cues are present
  via auto-load with no `resolve` step; editing code and attempting to stop
  without validation is blocked, and a waiver or a real validation run
  releases it.
- Expected review gate at PR time: `code-review-pre-merge-gate` for the
  nils-cli engine change (contract + exit codes); quick-pass for the kit
  content and hook changes.

## Retention Intent

Coordination; cleanup-eligible after the plan executes. Promote the
delivery-mechanism classification and the start-vs-finish enforcement model
into `docs/source/` only if they prove useful as standing architecture
guidance beyond this change.

## Read-First References

- `docs/source/inventory-target-architecture.md` — CLI boundary, runtime
  root model, `AGENT_DOCS_HOME` rejection rationale.
- `docs/source/docs-placement-retention-policy-v1.md` — docs placement.
- `AGENT_HOME.md` — home policy, the `agent-docs` preflight mandate to
  rework, and the `## Session Closeout` block that receives the heuristic
  cue.
- `docs/source/global-pointers/plan-archive-query-pointer-v1.md`,
  `docs/source/global-pointers/heuristic-system-pointer-v1.md` — cue source
  text to inline.
- `sympoies/nils-cli` `crates/agent-docs/` — engine to redesign.
- `AGENT_DOCS.toml`, `core/hooks/shared/user-prompt-agent-docs.sh`,
  `core/hooks/shared/session-start-healthcheck.sh` — kit integration to
  rework.

## Recommended Next Artifact

Generate the plan bundle
`docs/plans/2026-05-30-agent-docs-redesign/2026-05-30-agent-docs-redesign-plan.md`
and open the tracking issue via `create-plan-tracking-issue` against
`graysurf/agent-runtime-kit`.
