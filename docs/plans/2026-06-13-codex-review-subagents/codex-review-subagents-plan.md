# Plan: Codex Review Subagents

## Overview

Make runtime-kit's managed `code-review` workflows run through reviewer
subagents in both Codex and Claude Code. The work adds a cross-product managed
agent/subagent surface, starts with one quick-reviewer vertical slice, then
extends the same source model to specialist review lenses.

This is an L2 plan because the work is multi-step, surface-level, and needs a
state ledger across docs, manifests, render/install behavior, generated
artifacts, and review skill routing. It remains below L3 unless implementation
must split into independent parallel PR lanes.

## Read First

- Primary source:
  `docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Runtime-kit anchors:
  - `manifests/surfaces.yaml`
  - `docs/source/harness-shape-codex.md`
  - `docs/source/harness-shape-claude.md`
  - `targets/codex/link-map.yaml`
  - `targets/claude/link-map.yaml`
  - `core/skills/code-review/`
  - `core/skills/code-review/code-review-specialists/references/`
  - `tests/golden/`
  - `tests/runtime-smoke/`
- External product references:
  - Codex Subagents: <https://developers.openai.com/codex/subagents>
  - Claude Code Subagents:
    <https://docs.anthropic.com/en/docs/claude-code/sub-agents>
- Open questions carried into execution: none

## Scope

In scope:

- Open this L2 plan-tracking issue from a committed bundle.
- Baseline current Codex and Claude subagent discovery expectations.
- Design and implement a managed cross-product reviewer-agent source surface.
- Render/install Codex custom-agent TOML and Claude Markdown/YAML subagents.
- Update support matrix and harness-shape docs to match the actual surface.
- Update `code-review-quick-pass` to use a quick-reviewer subagent by default.
- Update `code-review-specialists` to dispatch selected specialist reviewer
  subagents and merge JSONL findings through existing CLI gates.
- Add CI/smoke coverage that fails on missing or stale reviewer-agent artifacts.
- Deliver implementation PRs and close the tracker through the normal L2 flow.

Out of scope:

- OpenAI hosted GitHub code review product behavior.
- Upstream product changes in Codex or Claude Code.
- Automatic code fixes from reviewer subagents.
- Provider review comments from code-review skills.
- Replacing `review-specialists` JSONL validation, merge, or report rendering.
- Dispatch-plan fan-out unless a later checkpoint escalates to L3.

## Assumptions

1. GitHub is the provider for this tracker, so `workflow::plan` and
   `workflow::tracking` labels are both valid.
2. The first implementation should prefer a runtime-kit-only render/install
   path, but a nils-cli change is acceptable if the released renderer cannot
   represent managed agent/subagent artifacts.
3. Product-specific authoring formats differ, but the reviewer behavior and
   review contract should stay source-equivalent across Codex and Claude.
4. The review workflows should continue to choose quick-pass versus specialist
   review by risk/scope rather than always running every specialist.

## Sprint 1: Tracker And Surface Baseline

**Goal**: Open the tracker and confirm the exact current surface gap before
editing runtime artifacts.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

Note: Task 1.1 creates only the tracker; Task 1.2 may produce a docs/baseline PR
only if it changes source files.

### Task 1.1: Create the plan bundle and open the tracker

- **Location**:
  - `docs/plans/2026-06-13-codex-review-subagents/`
- **Description**: Commit this source, plan, and execution-state bundle; validate
  it; dry-run `plan-issue record open`; open the provider tracker when the
  preview matches; initialize run state; and audit visible lifecycle evidence.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - Bundle has source, plan, and execution-state files.
  - `plan-tooling validate` passes for the plan.
  - Provider issue contains visible source, plan, and initial state lifecycle
    records.
  - Local run state is initialized for downstream execution.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md --format text --explain`
  - `plan-issue record audit --profile tracking --expect-visible`

### Task 1.2: Baseline reviewer-agent surface requirements

- **Location**:
  - `manifests/surfaces.yaml`
  - `docs/source/harness-shape-codex.md`
  - `docs/source/harness-shape-claude.md`
  - `targets/codex/link-map.yaml`
  - `targets/claude/link-map.yaml`
  - `core/skills/code-review/`
- **Description**: Compare official Codex and Claude subagent discovery formats
  with runtime-kit's current shipped surface registry and link maps. Decide
  whether the first implementation needs only runtime-kit templates/link maps or
  also an upstream nils-cli renderer/install primitive.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Current Codex and Claude subagent discovery paths are recorded with official
    source links.
  - Runtime-kit's stale or missing surface rows are identified.
  - A concrete implementation path is selected for Sprint 2.
  - Any nils-cli dependency is recorded as a blocker before runtime-kit edits
    depend on it.
- **Validation**:
  - `agent-runtime render --target support-matrix`
  - `bash scripts/ci/validate-surfaces-manifest.sh`

## Sprint 2: Quick-Reviewer Vertical Slice

**Goal**: Ship the smallest cross-product reviewer-agent surface that can
support `code-review-quick-pass`.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

Note: if a nils-cli primitive is required, split that upstream work before the
runtime-kit implementation PR.

### Task 2.1: Add managed reviewer-agent source and render/install scaffolding

- **Location**:
  - New managed reviewer-agent source path selected in Task 1.2.
  - `manifests/`
  - `targets/codex/`
  - `targets/claude/`
  - generated `build/` outputs and `tests/golden/`
- **Description**: Add a canonical quick-reviewer source and render it into
  Codex and Claude product-native agent formats. Install artifacts into the
  product discovery locations through the managed link maps.
- **Dependencies**:
  - Task 1.2
- **Complexity**: 4
- **Acceptance criteria**:
  - One quick-reviewer source produces Codex TOML and Claude Markdown/YAML
    render outputs.
  - Sandbox install rehearsal exposes the quick-reviewer artifact in both
    product homes.
  - Support matrix and harness docs describe the new shipped/partial state.
  - Rendered goldens are refreshed from source changes only.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime render --target support-matrix --update-golden`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`

### Task 2.2: Route quick-pass review through the quick reviewer

- **Location**:
  - `core/skills/code-review/code-review-quick-pass/SKILL.md.tera`
  - `core/skills/code-review/README.md`
  - generated Codex/Claude skill outputs and goldens
- **Description**: Update quick-pass review so the parent agent dispatches one
  read-only reviewer subagent by default, then synthesizes the result. If
  reviewer subagent dispatch is unavailable, the workflow must report an
  explicit waiver or blocker.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Quick-pass workflow names the reviewer-agent path and parent-agent
    synthesis responsibilities.
  - Fallback behavior is explicit and auditable.
  - Quick-pass remains lightweight and does not invoke the full specialist
    bundle for tiny or ordinary diffs.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`

## Sprint 3: Specialist Reviewer Fan-Out

**Goal**: Extend the quick-reviewer surface to every selected
`code-review-specialists` lens.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

Note: split only if Task 3.1 exposes a large render/install boundary.

### Task 3.1: Add specialist reviewer agent definitions

- **Location**:
  - Managed reviewer-agent source path
  - `core/skills/code-review/code-review-specialists/references/specialists/`
  - generated Codex/Claude agent outputs and goldens
- **Description**: Add specialist reviewer agents for testing,
  maintainability, security, performance, api-contract, data-migration, and
  red-team, reusing the existing specialist prompts and review contract.
- **Dependencies**:
  - Task 2.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Each specialist agent is read-only and outputs JSONL-compatible findings or
    an explicit no-findings summary.
  - Agent definitions reuse existing specialist focus areas and avoid new
    confidence/severity rules.
  - Render/install checks cover the full specialist set.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`

### Task 3.2: Route specialist review through selected reviewer subagents

- **Location**:
  - `core/skills/code-review/code-review-specialists/SKILL.md.tera`
  - `core/skills/code-review/README.md`
  - generated Codex/Claude skill outputs and goldens
- **Description**: Update specialist review so scope detection selects lenses,
  the parent dispatches matching read-only specialist reviewer subagents, and
  returned findings are validated and merged by `review-specialists`.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - Parent agent owns base-ref selection, scope detection, dispatch, validation,
    merge, and final synthesis.
  - Specialist subagents own only their assigned read-only lens.
  - Malformed or missing specialist output is handled as a workflow failure or
    residual risk, not a verified finding.
  - Existing `review-specialists validate/merge/render` gates remain in use.
- **Validation**:
  - `review-specialists scope --base origin/main --format json` on a
    representative diff when available.
  - `review-specialists validate --input docs/plans/2026-06-13-codex-review-subagents/specialist-findings.jsonl --validate-paths --format json`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`

## Sprint 4: Product Probes And Delivery Integration

**Goal**: Prove the installed reviewer agents are discoverable where practical
and integrate the new review path into delivery gates.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Add product-safe reviewer-agent discovery probes

- **Location**:
  - `tests/runtime-smoke/`
  - `scripts/ci/`
  - product target fixtures
- **Description**: Add deterministic or probe-only checks that confirm installed
  Codex and Claude runtime homes include the reviewer agent definitions. Use
  live product probes only when they can run without mutating real home state.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - CI or smoke catches missing Codex reviewer agent artifacts.
  - CI or smoke catches missing Claude reviewer subagent artifacts.
  - Any manual-only live product acceptance is documented with a clear command
    and expected result.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - `bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only`

### Task 4.2: Reconcile delivery review callers

- **Location**:
  - `core/skills/code-review/code-review-pre-merge-gate/SKILL.md.tera`
  - `core/skills/pr/`
  - `core/skills/dispatch/`
  - generated Codex/Claude outputs and goldens
- **Description**: Update callers and routing docs so delivery review gates use
  the new subagent-backed quick/specialist review paths without moving provider
  mutation into code-review skills.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 3
- **Acceptance criteria**:
  - Delivery callers route to subagent-backed code-review workflows.
  - Provider comments, PR/MR decisions, merges, and issue closeout remain owned
    by delivery skills.
  - Dispatch lane review can still record specialists as used/skipped.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`

## Sprint 5: Full Validation, Delivery, And Closeout

**Goal**: Finish the tracked feature with full validation, PR delivery, and
plan closeout.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

Note: use this sprint for the final integration PR or PR delivery for the last
open implementation branch.

### Task 5.1: Run full project validation

- **Location**:
  - repository root
- **Description**: Run the declared project validation and targeted probes after
  all planned changes are integrated.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 2
- **Acceptance criteria**:
  - Full CI gate passes.
  - Hook tests pass.
  - Relevant product/smoke probes pass or have explicit tracked blockers.
- **Validation**:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

### Task 5.2: Deliver PRs and close the tracker

- **Location**:
  - provider PRs/MRs
  - tracking issue
- **Description**: Deliver remaining implementation PRs through the normal PR
  floor, record final validation/review evidence, run close-ready, then use the
  closeout skill to close and archive the tracker.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 2
- **Acceptance criteria**:
  - All implementation PRs are merged or explicitly superseded.
  - Tracking issue has final state, session, validation, and review evidence.
  - Close-ready passes.
  - Bundle is archived or otherwise retired by the closeout workflow.
- **Validation**:
  - `plan-issue tracking close-ready --expect-visible`
  - `plan-issue record close --profile tracking`
  - `plan-archive migrate`
