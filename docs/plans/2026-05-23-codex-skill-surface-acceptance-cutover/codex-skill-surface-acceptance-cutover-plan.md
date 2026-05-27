# Plan: Codex Skill Surface Acceptance Cutover

## Overview

Consume the released `agent-runtime doctor --class skill-surface` diagnostic
from nils-cli `v0.17.5` as a preflight for Codex skill discovery, then run the
live Codex Desktop acceptance that proves required skills load without the
`$HOME/.agents` compatibility alias. This plan updates `agent-runtime-kit`
surface docs and CLI floors to match the released minimum, adds the shape
diagnostic to deterministic validation, and gates `$HOME/.agents` removal on
live Desktop evidence with a verified rollback path.

This plan supersedes the open lanes in
`docs/plans/2026-05-22-codex-skill-discovery-cutover/` for Sprint 1 preflight semantics.
It does not change nils-cli code, recreate the doctor classification in shell
or Python, or treat `.codex-plugin/plugin.json` as a Codex runtime loader.

## Read First

- Primary source: docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Should the shape check be a permanent `scripts/ci/all.sh` position or a
    targeted pre-live-acceptance command documented in `DEVELOPMENT.md`?
  - Should `required_clis` floors be bumped globally to `>=0.17.5` for all
    workflow skills, or only for surfaces whose validation depends on the new
    `agent-runtime` doctor class?
  - What exact `codex debug prompt-input` output is the stable pass/fail signal
    for skill availability in a fresh Desktop session?
  - If live acceptance passes, should `$HOME/.agents` be removed immediately or
    kept through one additional observation window?
- Secondary references:
  - `DEVELOPMENT.md`
  - `docs/source/nils-cli-surface.md`
  - `docs/source/docs-placement-retention-policy-v1.md`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md`
  - `targets/codex/link-map.yaml`
  - `manifests/skills.yaml`
  - `tests/sandbox/codex/expected-skills.txt`
  - `scripts/ci/all.sh`

## Scope

- In scope:
  - Refresh `docs/source/nils-cli-surface.md` to `v0.17.5` and document the new
    `agent-runtime doctor --class skill-surface` capability.
  - Decide and apply `required_clis` floor changes for skills or plugins that
    depend on `agent-runtime`, `plan-issue`, or `forge-cli` workflow
    primitives.
  - Add `agent-runtime doctor --class skill-surface --product codex` to the
    documented and scripted validation stack after Codex render and before
    live/install acceptance claims.
  - Capture a JSON or text summary that records item count, zero warnings,
    zero blocks, and the acceptance-boundary text.
  - Run live Codex Desktop acceptance in a reversible window and record the
    result alongside the alias-retention decision.
- Out of scope:
  - Changing nils-cli code.
  - Recreating the doctor classification in shell, Python, or
    agent-runtime-kit scripts.
  - Treating `.codex-plugin/plugin.json` as a Codex runtime loader without
    live evidence.
  - Mutating Codex auth, sessions, history, logs, caches, or secrets.
  - Permanent `$HOME/.agents` removal before live acceptance and rollback are
    documented and exercised.

## Assumptions

1. nils-cli `v0.17.5` is the released minimum for the shape diagnostic and is
   installed locally via Homebrew (`agent-runtime 0.17.5`,
   `nils-plan-issue-cli 0.17.5`, `forge-cli 0.17.5`).
2. `agent-runtime-kit` remains the source of truth for shared skill bodies,
   manifests, and Codex target metadata.
3. `$HOME/.agents -> $HOME/.config/agent-kit` remains a temporary
   compatibility alias until live Codex Desktop acceptance passes.
4. Live-home changes are dry-run-first, reversible, and recorded with exact
   rollback commands before any permanent alias removal.
5. The current shape-diagnostic output of `checks=65 ok=65 warn=0 block=0` is
   the deterministic baseline; any change to the count requires a documented
   reason in the execution state.

## Sprint 1: Surface And Floor Refresh

**Goal**: Bring repo-level CLI surface documentation and manifest CLI floors in
line with nils-cli `v0.17.5` before changing deterministic gates or live
acceptance.

**Demo/Validation**:

- Commands:
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist`
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist`
  - `agent-runtime --version`
  - `agent-runtime doctor --class skill-surface --product codex --format json --source-root .`
  - `plan-tooling validate --file docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-plan.md --format text --explain`
- Verify: the surface snapshot reflects `v0.17.5`, the doctor JSON baseline is
  captured, and `required_clis` decisions are recorded with rationale before
  Sprint 2 wires gates.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 1.1: Refresh nils-cli surface snapshot to v0.17.5

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
- **Description**: Update the active surface snapshot from `v0.17.1` to
  `v0.17.5`. Refresh the snapshot date, regenerate or hand-update the surface
  inventory to include `agent-runtime doctor --class skill-surface`, and link
  the release/tap evidence from the discussion source. Do not change nils-cli
  code or behavior.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `docs/source/nils-cli-surface.md` no longer references `v0.17.1` as the
    active snapshot and records snapshot date `2026-05-23` or later.
  - The new `agent-runtime doctor --class skill-surface` capability and its
    `--product`, `--source-root`, `--format` flags are documented.
  - Snapshot evidence cites `sympoies/nils-cli@v0.17.5` and the matching
    Homebrew tap release.
  - Execution state records the refresh and any deferred surface items as
    explicit out-of-scope.
- **Validation**:
  - `agent-runtime --version`
  - `! rg -n 'v0\\.17\\.1' docs/source/nils-cli-surface.md`

### Task 1.2: Decide and apply required_clis floor changes

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `manifests/runtime-roots.yaml`
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
- **Description**: Audit manifests for skills/plugins whose validation or
  delivery depends on `agent-runtime`, `plan-issue`, or `forge-cli`. Decide
  whether to bump floors to `>=0.17.5`, leave a narrower floor, or apply
  surgical bumps for surfaces that depend on the new doctor class. Record the
  rule and the affected ids in the execution state.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Manifest CLI floors reflect the decision and the diff matches the rule.
  - Skills/plugins that consume the new doctor class are at `>=0.17.5`.
  - Skills/plugins that explicitly stay below `0.17.5` carry a recorded reason
    in execution state.
  - No manifest entry references an unreleased nils-cli version.
- **Validation**:
  - `agent-runtime audit-drift`
  - `rg -n 'agent-runtime|plan-issue|forge-cli' manifests/skills.yaml manifests/plugins.yaml manifests/runtime-roots.yaml`

### Task 1.3: Capture deterministic shape baseline

- **Location**:
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
- **Description**: Run the released shape diagnostic against the repo with
  `--source-root` set to the working tree and store both JSON and text
  summaries under the runtime-kit state-home `out/` directory
  (`${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/`).
  Record the `checks/ok/warn/block` counts and the acceptance-boundary text
  returned by the diagnostic.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - JSON output records `checks=65 ok=65 warn=0 block=0` (or the documented
    new baseline with rationale) and exits 0.
  - The acceptance-boundary text is captured verbatim and quoted in execution
    state.
  - Artifact paths are stable under the runtime-kit state home and referenced
    by Sprint 2 wiring tasks.
  - No real `$HOME/.codex` files, auth, sessions, history, logs, or caches are
    inspected or modified.
- **Validation**:
  - `agent-runtime doctor --class skill-surface --product codex --format json --source-root .`
  - `agent-runtime doctor --class skill-surface --product codex --format text --source-root .`

## Sprint 2: Deterministic Shape Gate Integration

**Goal**: Add the shape diagnostic to the deterministic local gate so any
known-bad `SKILL.md` file-symlink shape or block-level finding fails CI before
live acceptance.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
  - `bash scripts/ci/all.sh`
- Verify: `scripts/ci/all.sh` (or the documented equivalent gate) invokes the
  shape diagnostic, fails on any `codex.active-skill.file-symlink` warning or
  doctor `block > 0`, and surfaces the acceptance-boundary message so
  maintainers do not confuse shape validation with live Desktop discovery.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 2.1: Wire shape diagnostic into scripts/ci/all.sh

- **Location**:
  - `scripts/ci/all.sh`
  - `DEVELOPMENT.md`
- **Description**: Add the shape diagnostic invocation after Codex render and
  before live/install acceptance claims. The invocation must pass
  `--product codex --source-root` set to the repo root, use the JSON format
  for machine parsing, and propagate the exit code so any block-level finding
  fails the gate.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 3
- **Acceptance criteria**:
  - `scripts/ci/all.sh` calls `agent-runtime doctor --class skill-surface --product codex`
    in a documented position.
  - The gate fails fast on doctor exit non-zero, on any
    `codex.active-skill.file-symlink` warning, and on `block > 0`.
  - The script preserves the acceptance-boundary text in its stdout so log
    readers see the shape-vs-live distinction.
  - `DEVELOPMENT.md` lists the new gate position and links the discussion
    source.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - `bash -n scripts/ci/all.sh`

### Task 2.2: Fail-loud parser for shape findings

- **Location**:
  - `scripts/ci/all.sh`
  - `scripts/ci/`
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
- **Description**: Add a small, dependency-free parser step (jq-only or
  inline) that reads the JSON output, asserts `warn=0`, `block=0`, and the
  expected baseline count or documented override, and writes the pass/fail
  summary to the runtime-kit state-home `out/` directory.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - The parser uses only repo-allowed tools (no new runtime requirements).
  - Mismatched counts produce a clear failure message that names the expected
    baseline and documented override path.
  - Pass output records the captured acceptance-boundary text in the same
    artifact.
  - The parser does not silently downgrade failures to warnings.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - Manual review of the pass/fail artifact in the runtime-kit state home.

### Task 2.3: Refresh render and drift to absorb the new gate

- **Location**:
  - `targets/codex/`
  - `tests/golden/codex/`
  - `tests/sandbox/codex/expected-skills.txt`
- **Description**: Refresh generated Codex output, golden snapshots, and
  sandbox expectations only as needed for the new gate position. Do not bundle
  unrelated link-map or manifest churn into this task.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - `agent-runtime render --product codex` is stable.
  - `agent-runtime audit-drift` reports no unplanned source/target mismatch.
  - Sandbox expectations still cover the required skills:
    `conversation.discussion-to-implementation-doc`,
    `conversation.handoff-session-prompt`,
    `dispatch.execute-plan-tracking-issue`,
    `dispatch.deliver-plan-tracking-issue`, and `meta.semantic-commit`.
  - Diff stays scoped to gate-driven changes.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime audit-drift`

### Task 2.4: Document the shape-vs-live boundary

- **Location**:
  - `DEVELOPMENT.md`
  - `docs/source/inventory-target-architecture.md`
  - `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
- **Description**: Update maintainer docs so the shape diagnostic is described
  as a preflight, not as proof of live Codex Desktop discovery. Cross-link the
  discovery-cutover execution state so the earlier plan inherits the new
  preflight.
- **Dependencies**:
  - Task 2.1
  - Task 2.3
- **Complexity**: 2
- **Acceptance criteria**:
  - `DEVELOPMENT.md` distinguishes shape validation from live acceptance and
    names the shape exit-code contract.
  - `docs/source/inventory-target-architecture.md` references the shape
    diagnostic as a deterministic preflight.
  - The discovery-cutover execution state records that Sprint 1 preflight is
    delegated to the released shape diagnostic.
  - No tracked doc claims shape validation is sufficient for Desktop
    discovery.
- **Validation**:
  - `rg -n 'skill-surface' DEVELOPMENT.md docs/source/inventory-target-architecture.md`
  - `plan-tooling validate --file docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md --format text`

## Sprint 3: Live Acceptance And Alias Decision

**Goal**: Prove that a fresh Codex Desktop session can discover the required
skills from `$HOME/.codex` without `$HOME/.agents`, then record the alias
decision with a verified rollback path.

**Demo/Validation**:

- Commands:
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - `agent-docs --docs-home "$HOME/.codex" resolve --context startup --strict --format checklist`
  - `if [ -L "$HOME/.agents" ]; then readlink "$HOME/.agents"; else test ! -e "$HOME/.agents"; fi`
- Verify: live Desktop evidence is captured, rollback is exercised or
  dry-run-verified, and the execution state records whether `$HOME/.agents`
  remains in place or is retired.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Pre-live dry-run and backup checks

- **Location**:
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
  - `$HOME/.codex`
  - `$HOME/.agents`
- **Description**: Before any live mutation, record the current `$HOME/.agents`
  state, the relevant `$HOME/.codex` skill surface state, the launch
  environment values that affect skill discovery, and the exact rollback
  commands. Do not touch auth, sessions, logs, history, or caches.
- **Dependencies**:
  - Task 2.4
- **Complexity**: 3
- **Acceptance criteria**:
  - Current `$HOME/.agents` target (or absence) is recorded.
  - Current `$HOME/.codex` skill surface state is recorded without dumping
    secrets or private runtime data.
  - Rollback commands are reviewed and stored alongside the execution state
    before disabling the alias.
  - Install dry-run and temp-home smoke pass.
- **Validation**:
  - `agent-runtime install --product codex --dry-run`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`

### Task 3.2: Fresh Codex Desktop acceptance window

- **Location**:
  - `$HOME/.codex`
  - `$HOME/.agents`
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
- **Description**: Inside a reversible test window, disable or rename
  `$HOME/.agents`, start a fresh Codex Desktop session, and capture
  `codex debug prompt-input` evidence proving the required skills are visible
  from the runtime-kit-owned `$HOME/.codex` surface. Restore the alias on any
  failure.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 5
- **Acceptance criteria**:
  - `$HOME/.agents` is absent or disabled during the test window.
  - `codex debug prompt-input` evidence lists each required acceptance skill.
  - Evidence is stored without exposing secrets or raw private logs.
  - Failure restores `$HOME/.agents -> $HOME/.config/agent-kit` and records
    the blocker for follow-up.
- **Validation**:
  - Manual fresh Codex Desktop session per the protocol.
  - `agent-docs --docs-home "$HOME/.codex" resolve --context startup --strict --format checklist`

### Task 3.3: Record alias retention decision

- **Location**:
  - `CODEX_AGENTS.md`
  - `docs/source/inventory-target-architecture.md`
  - `manifests/runtime-roots.yaml`
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
- **Description**: After live acceptance, record whether `$HOME/.agents` is
  retired immediately or held through one additional observation window. If
  retired, remove or disable the alias and update only the docs that describe
  Codex skill discovery. Hook and Claude cleanup remain out of scope.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 4
- **Acceptance criteria**:
  - The execution state records the alias decision (retire, observe, defer)
    with rationale.
  - If retired: `$HOME/.agents` is no longer required for Codex skill
    discovery, and any remaining mention in tracked docs is explicitly
    historical, rollback-only, or project-local overlay behavior.
  - If observed/deferred: the next checkpoint date and the conditions that
    trigger retirement are recorded.
  - Rollback instructions remain available regardless of the decision.
- **Validation**:
  - `if [ -L "$HOME/.agents" ]; then readlink "$HOME/.agents"; else test ! -e "$HOME/.agents"; fi`
  - `agent-docs --docs-home "$HOME/.codex" resolve --context startup --strict --format checklist`

### Task 3.4: Rollback proof and closeout

- **Location**:
  - `docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md`
  - `docs/source/inventory-target-architecture.md`
  - `DEVELOPMENT.md`
- **Description**: Exercise or dry-run the rollback path, record final
  validation, and promote durable shape-vs-live rules out of the plan bundle
  into the appropriate source docs so they survive plan closure.
- **Dependencies**:
  - Task 3.3
- **Complexity**: 3
- **Acceptance criteria**:
  - Rollback is either executed in a safe drill or dry-run with all commands
    verified.
  - Final validation separates Desktop live evidence from deterministic
    shape evidence.
  - Durable shape-vs-live contract is promoted to maintained source docs.
  - The plan bundle is ready for issue-backed closeout.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - Manual rollback drill or dry-run evidence recorded in execution state.

## Testing Strategy

- Static/docs:
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist`
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist`
  - `plan-tooling validate --file docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-plan.md --format text --explain`
- Render/install:
  - `agent-runtime render --product codex`
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
- Shape preflight:
  - `agent-runtime doctor --class skill-surface --product codex --format json --source-root .`
  - `agent-runtime doctor --class skill-surface --product codex --format text --source-root .`
- Product/live:
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - Manual fresh Codex Desktop session check with `$HOME/.agents` disabled
    inside a reversible window.
- Full gate:
  - `bash scripts/ci/all.sh` before closing implementation.

## Risks & gotchas

- The shape diagnostic is intentionally conservative and source-root based. A
  pass is necessary but not sufficient for live Desktop skill discovery.
- Current shape output covers both legacy `plugins/<domain>/skills` recursive
  file entries and the newer `skills/<domain>/<skill>` directory entries.
  Live acceptance must prove which surface Codex Desktop actually uses.
- Required skills are now present in runtime-kit, but visible skill loading
  can still fail if Codex Desktop ignores `$HOME/.codex/skills` or caches an
  older surface.
- Ambient `AGENT_HOME`, `AGENT_DOCS_HOME`, or launchctl values can hide a
  `.agents` dependency. Validation must prove the non-`.agents` surface is
  actually in use.
- Live Desktop checks can touch local app state if run carelessly. The live
  protocol must avoid auth, sessions, history, logs, and caches.
- Same-sprint lanes can conflict in `scripts/ci/all.sh`,
  `docs/source/nils-cli-surface.md`, and the Codex render/golden outputs.
  Shared integration belongs in Task 2.4 and Task 3.4.

## Rollback plan

- Before live mutation, record current `$HOME/.agents` target and Codex
  discovery-relevant launch environment.
- If live discovery fails, restore:
  - `ln -sfn "$HOME/.config/agent-kit" "$HOME/.agents"`
  - any discovery-relevant launch environment values identified in Task 3.1
  - the previous `$HOME/.codex` skill surface if it was changed inside the
    test window
- Re-run:
  - `agent-docs --docs-home "$HOME/.agents" resolve --context startup --strict --format checklist`
  - fresh Codex Desktop session check for the legacy fallback path
- Revert repository changes from the failed sprint together with their
  manifest, render, golden, sandbox, and docs updates.
