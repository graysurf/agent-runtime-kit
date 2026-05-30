# Plan: agent-docs Redesign — Kit-Side Adoption

## Overview

Adopt the redesigned `agent-docs` on the agent-runtime-kit side: move
always-on global cues onto the harness auto-load path, replace the
start-time "check present + trust" model with harness-native delivery, and
put the real enforcement teeth at the finish line (a validation gate that
blocks a turn from ending when code was edited but the declared validation
never ran). Policy becomes data the repo declares; `agent-docs` becomes an
auditor and resolver, not an agent per-task preflight.

This tracker is **kit-scoped**. The `agent-docs` engine redesign
(data-driven catalog, `when` predicates, content validation, collapsed
command surface, symlink-derived docs-home, `init` stub) lives in
`sympoies/nils-cli` `crates/agent-docs` and ships via its own PR, release,
and Homebrew tap. It is an upstream dependency here: Sprint 1 is
engine-independent and can land immediately; Sprints 2-4 are gated on the
nils-cli release plus a `required_clis` floor bump.

The motivating pain: agents finish work without running the validation in
`DEVELOPMENT.md`. Start-time presence checks never fixed it because the
failure is at the end of the task. The finish-line gate (Sprint 3 for
Claude, Sprint 4 for Codex) is the load-bearing change.

## Read First

- Primary source:
  `docs/plans/2026-05-30-agent-docs-redesign/2026-05-30-agent-docs-redesign-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Upstream dependency (separate repo, NOT edited by this tracker):
  `sympoies/nils-cli` `crates/agent-docs` — the engine redesign delivered
  via nils-cli PR + release + tap, then consumed here by a `required_clis`
  bump.
- Repo anchors:
  - `AGENT_HOME.md` (auto-loaded home policy; receives the inlined cues and
    the reworked preflight prose)
  - `AGENT_DOCS.toml` (the two `startup`/`global` pointer entries to remove)
  - `docs/source/global-pointers/plan-archive-query-pointer-v1.md`,
    `docs/source/global-pointers/heuristic-system-pointer-v1.md` (cue source
    to inline, then retire)
  - `core/hooks/shared/user-prompt-agent-docs.sh`,
    `core/hooks/shared/session-start-healthcheck.sh`,
    `core/hooks/claude/settings.hooks.jsonc`,
    `targets/codex/hooks/config.block.toml` (enforcement hooks)
  - `manifests/skills.yaml` (`required_clis` floor for `agent-docs`)
  - `core/skills/meta/agent-docs/SKILL.md.tera`, `DEVELOPMENT.md` (preflight
    prose), `scripts/ci/all.sh`, `tests/hooks/`
- Key decisions carried into execution (from the source Decisions section):
  - [D1] `agent-docs` reframed into `audit` + `preflight` (for hooks) +
    catalog management; no agent per-task `resolve`.
  - [D2] Route every doc by delivery mechanism (auto-load / hook-inject /
    audit).
  - [D3] Data-driven catalog; no hardcoded builtins (engine, upstream).
  - [D4] `when` predicates (`path-exists:<glob>` + `||`/`&&`) replace the
    `required=false` opt-out.
  - [D6] Enforcement split by timing: start-of-task short awareness cue
    (no up-front PreToolUse edit-block); finish-of-task Stop/delivery gate.
  - [D7] Retire `AGENT_DOCS_HOME` env var; derive docs-home from the install
    symlink; keep `--docs-home`.
  - [D8] Retire `startup` as an agent per-task preflight.
  - [D9] Inline the two global cues into `AGENT_HOME.md`, verify, then remove
    the `AGENT_DOCS.toml` entries (move first, then delete).
  - [D12] Codex finish-line enforcement is committed (may be later phase,
    Codex-native mechanism, but never silently skippable).
- Open questions carried into execution:
  - none — the source resolved all prior open items into Decisions and
    Risks (cli-tools stays on-demand, global cues inline, audit reports
    only, Codex finish-line enforcement committed in Decision 12).

## Scope

- In scope:
  - **Sprint 1 (`agent-runtime-kit`, engine-independent)**: inline the two
    global cues into `AGENT_HOME.md`, verify auto-load, remove the two
    `AGENT_DOCS.toml` `startup`/`global` entries, and retire the thin
    `*-v1.md` pointer files (keep `HEURISTIC_SYSTEM.md`).
  - **Sprint 2 (`agent-runtime-kit`, gated on nils-cli release)**: bump the
    `agent-docs` `required_clis` floor, author the kit default catalog in the
    new schema, convert `project-dev` to a `when`-conditional requirement,
    and rewrite the preflight prose to the new command surface (retiring the
    `startup` per-task step).
  - **Sprint 3 (`agent-runtime-kit`, gated on nils-cli release)**: replace
    the English-keyword reminder hook with a language-agnostic start-of-task
    awareness injection; add the Claude finish-line Stop-hook validation
    gate; rework the SessionStart healthcheck around `audit`.
  - **Sprint 4 (`agent-runtime-kit`)**: implement the Codex finish-line
    enforcement gate ([D12]); run full validation and deliver one PR.
- Out of scope (see Future Work):
  - The `agent-docs` engine implementation in `sympoies/nils-cli` (upstream
    dependency, separate PR/release).
  - A general-purpose `when` expression language beyond `path-exists`, glob,
    and boolean composition.
  - Verifying that validation passed or was meaningful — only that it ran.
  - Any cross-agent memory (`agentmemory`) work.

## Assumptions

1. The nils-cli `agent-docs` engine redesign (source decisions D1, D3, D4,
   D5, D8, D10, D11) lands, releases, and is tapped first; this kit plan
   consumes the released surface. Sprints 2-4 are gated on that release plus
   a `required_clis` bump. Sprint 1 has no engine dependency.
2. The home symlinks (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` ->
   `AGENT_HOME.md`) remain the auto-load delivery path ([A2][A3]), so inlined
   cues reach every session in every repo.
3. Claude exposes a Stop / SubagentStop hook that can block turn-end; Codex's
   non-bypassable choke point is determined in Sprint 4 ([D12]).
4. `bash scripts/ci/all.sh` and `bash tests/hooks/run.sh` remain the gating
   validation surface.

## Sprint 1: Global-Cue Migration To Auto-Load (agent-runtime-kit)

**Goal**: Move the two always-on global cues onto the harness auto-load path
and retire the catalog entries and pointer files they used, with no
dependency on the nils-cli engine.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Inline the global cues into AGENT_HOME.md

- **Location**:
  - `AGENT_HOME.md` (heuristic routing summary into `## Session Closeout`;
    a new `## Plan Archive` block for the plan-archive cue)
- **Description**: Copy the actionable cue text from
  `plan-archive-query-pointer-v1.md` and `heuristic-system-pointer-v1.md`
  into `AGENT_HOME.md`, which the harness auto-loads via the home symlinks
  ([A3]). Keep the cues terse ([D9] guardrail: only short cues inline).
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - `AGENT_HOME.md` carries both cues inline; a fresh session shows them in
    context with no `resolve` step.
  - `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` still resolve to
    `AGENT_HOME.md`.
- **Validation**:
  - `rumdl check AGENT_HOME.md`; `readlink ~/.claude/CLAUDE.md` and
    `readlink ~/.codex/AGENTS.md` both point at `AGENT_HOME.md`.

### Task 1.2: Remove the startup catalog entries and retire the pointer files

- **Location**:
  - `AGENT_DOCS.toml` (remove the two `startup`/`global` entries)
  - `docs/source/global-pointers/plan-archive-query-pointer-v1.md`,
    `docs/source/global-pointers/heuristic-system-pointer-v1.md` (retire)
- **Description**: After the cues are inlined and verified, delete the two
  `startup`/`global` `[[document]]` entries and remove the thin pointer
  files. Keep `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` (the full
  policy). Order is fixed: inline and verify first (1.1), then delete ([D9]).
- **Dependencies**:
  - Task 1.1
- **Complexity**: 1
- **Acceptance criteria**:
  - `AGENT_DOCS.toml` no longer declares the two startup pointers; the
    pointer files are removed.
  - No dangling references to the removed paths remain in the repo.
- **Validation**:
  - `rg` for the removed pointer paths returns no active references;
    `bash scripts/ci/all.sh` (or the relevant subset) passes.

## Sprint 2: Kit Catalog And Command-Surface Adoption (agent-runtime-kit)

**Goal**: Consume the released engine: data-driven default catalog,
`when`-conditional `project-dev`, and preflight prose on the new command
surface with `startup` retired as a per-task step.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 2.1: Bump required_clis and author the kit default catalog

- **Location**:
  - `manifests/skills.yaml` (`required_clis` floor for `agent-docs`)
  - the kit default catalog in the new schema (path per the released engine)
- **Description**: Gated on the nils-cli engine release (Assumptions #1).
  Pin `agent-docs` to the release that ships the redesigned engine, and
  author the kit default catalog declaring contexts and required docs as
  data ([D3]). No reliance on hardcoded builtins.
- **Dependencies**:
  - none
- **Complexity**: 2
- **Acceptance criteria**:
  - `required_clis` names the new floor; the default catalog validates.
  - `agent-docs audit` is green against the new catalog in this repo.
- **Validation**:
  - `agent-docs audit` and the repo governance/schema checks pass.

### Task 2.2: Make project-dev when-conditional and confirm pure-docs auto-skip

- **Location**:
  - the kit catalog entry for `project-dev` / `DEVELOPMENT.md`
- **Description**: Express the `DEVELOPMENT.md` requirement with a `when`
  predicate (e.g. `path-exists:Cargo.toml || path-exists:**/package.json ||
  path-exists:src/**`) so pure-docs repos auto-skip it with no opt-out
  ([D4]).
- **Dependencies**:
  - Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `DEVELOPMENT.md` is required only when a code marker is present.
  - A docs-only fixture requires no manual opt-out and reports no missing
    code doc.
- **Validation**:
  - `agent-docs preflight` / `audit` against a docs-only fixture and against
    this repo.

### Task 2.3: Rewrite preflight prose to the new surface; retire startup per-task

- **Location**:
  - `AGENT_HOME.md` (`## Required Preflight`), `DEVELOPMENT.md`,
    `core/skills/meta/agent-docs/SKILL.md.tera`, and any hook prose
- **Description**: Replace `resolve`/`baseline` and the `startup` per-task
  step with the new commands (`audit`, `preflight`) and the hook-driven
  model ([D1][D8]). Remove instructions telling the agent to run a per-task
  `startup` resolve.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - No prose instructs an agent per-task `startup` resolve; commands match
    the released surface.
- **Validation**:
  - `rg` finds no retired commands in tracked prose; render-golden for the
    `agent-docs` skill passes; `rumdl check` on touched Markdown.

## Sprint 3: Claude Enforcement Hooks (agent-runtime-kit)

**Goal**: Deliver harness-native start-of-task awareness injection and the
Claude finish-line validation gate, and rework the daily healthcheck around
`audit`.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Replace the keyword reminder with language-agnostic injection

- **Location**:
  - `core/hooks/shared/user-prompt-agent-docs.sh` +
    `core/hooks/claude/settings.hooks.jsonc` +
    `targets/codex/hooks/config.block.toml`
- **Description**: Gated on the nils-cli engine release (provides
  `preflight --intent`). Replace the English-keyword reminder ([F7]) with a
  hook that calls `agent-docs preflight --intent` and injects the resolved
  short awareness cue (validation commands + "run before declaring done")
  for `project-dev` / `task-tools` intent, with no keyword gating ([D6]
  start layer).
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - The cue is injected regardless of prompt language; no English-keyword
    dependency remains.
- **Validation**:
  - `bash tests/hooks/run.sh` including a non-English prompt case.

### Task 3.2: Claude finish-line Stop-hook validation gate

- **Location**:
  - new `core/hooks/shared/` logic + a Claude Stop / SubagentStop hook in
    `core/hooks/claude/settings.hooks.jsonc`
- **Description**: On stop, if the repo declares a validation contract and
  the session edited non-doc code but there is no evidence the validation
  ran, block turn-end with the resolved commands, accepting an explicit
  waiver with reason ([D6] finish layer). Define the "evidence ran" marker
  contract (prefer a marker written by `pre-pr.sh` / the validation command
  over scraping history). Integrate with the existing pre-commit / pre-PR
  gate.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 3
- **Acceptance criteria**:
  - A session that edits non-doc code and tries to stop without running the
    declared validation is blocked with the commands; running them or giving
    a waiver releases it.
  - No false block when only docs were edited or no contract is declared.
- **Validation**:
  - `bash tests/hooks/run.sh` Stop-gate cases (block, waiver-release,
    docs-only no-block).

### Task 3.3: Rework the SessionStart healthcheck around audit

- **Location**:
  - `core/hooks/shared/session-start-healthcheck.sh`
- **Description**: Gated on the nils-cli engine release (provides `audit`).
  Point the daily healthcheck at `agent-docs audit`, including the wiring
  check (home symlink intact and pointing at the kit) and content validity
  ([D5][D9]).
- **Dependencies**:
  - Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - The daily healthcheck surfaces a broken symlink or an empty required doc;
    an intact setup is green.
- **Validation**:
  - `bash tests/hooks/run.sh` healthcheck case with a broken-symlink fixture.

## Sprint 4: Codex Finish-Line Enforcement And Delivery (agent-runtime-kit)

**Goal**: Make the finish-line gate non-bypassable on Codex too ([D12]), run
full validation, and deliver one PR.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Codex non-bypassable finish-line gate

- **Location**:
  - `targets/codex/hooks/config.block.toml` managed block + shared
    `core/hooks/` logic
- **Description**: Determine the Codex choke point — a Stop-equivalent
  lifecycle event if one exists, otherwise the commit / delivery path Codex
  already routes through — and implement the no-skip gate so a session that
  edited non-doc code cannot reach done or delivery without running the
  declared validation or recording a waiver ([D12]). The mechanism may
  differ from Claude but must not be silently skippable.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - On Codex, editing non-doc code then reaching done/delivery without
    validation or a waiver is blocked.
  - The plan records the chosen Codex mechanism; no skippable path ships.
- **Validation**:
  - Codex hook test plus a manual Codex acceptance run
    (`codex debug prompt-input` / a fresh-session check) confirming the gate.

### Task 4.2: Full validation, commit, and delivery

- **Location**:
  - `agent-runtime-kit` repo gate
- **Description**: Run `bash scripts/ci/all.sh` plus `bash tests/hooks/run.sh`
  and `rumdl check` on touched Markdown. Commit via `semantic-commit` (no
  `Co-Authored-By` trailer per home-scope feedback). Deliver via the active
  PR delivery skill (`forge-cli pr deliver`); the PR body links this tracking
  issue and the nils-cli engine release.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `scripts/ci/all.sh` and `tests/hooks/run.sh` pass.
  - The PR merges; the tracker records the merge SHA via
    `tracking run update --note` and a final state checkpoint.
- **Validation**:
  - PR workflow green; merge SHA recorded on the tracking issue.

## Issue Closeout Gate

The tracking issue is complete when:

- Sprint 1 inlined both global cues into `AGENT_HOME.md`, verified auto-load,
  removed the two `AGENT_DOCS.toml` startup entries, and retired the pointer
  files.
- The nils-cli `agent-docs` engine release is available and the `agent-docs`
  `required_clis` floor is bumped (dependency satisfied).
- Sprints 2-4 land on `main` of `agent-runtime-kit`.
- Both the Claude and Codex finish-line gates enforce the no-skip invariant
  ([D12]): a code-editing session cannot reach done/delivery without running
  the declared validation or recording a waiver.
- `bash scripts/ci/all.sh` and `bash tests/hooks/run.sh` are green.
- The `execution-state.md` ledger has every executed row at `done` with a
  non-empty `Evidence` cell; waived rows are marked `waived` with a reason.
- The closeout comment is preceded by a final
  `tracking run update --note "<closing summary>"` event.

## Future Work (Out Of Scope For This Tracker)

- The `agent-docs` engine implementation in `sympoies/nils-cli` — tracked via
  its own PR/release; this kit tracker depends on the release.
- A general-purpose `when` expression language beyond `path-exists`, glob,
  and boolean composition.
- Promoting the delivery-mechanism classification and the start-vs-finish
  enforcement model into `docs/source/` as standing architecture guidance.
- Any cross-agent memory (`agentmemory`) integration.

## Retention Intent

Plan-source coordination document. Cleanup-eligible after the tracker closes
and archives via `plan-archive-migrate`. If the delivery-mechanism /
enforcement model is promoted, that `docs/source/` document becomes the
durable artifact independent of this bundle.
