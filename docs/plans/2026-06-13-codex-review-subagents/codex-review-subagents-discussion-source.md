# Codex Review Subagents Implementation Handoff

- **Status**: ready for L2 plan tracking
- **Date**: 2026-06-13
- **Source**: in-session design discussion about making repo-managed code review
  run through subagents in both Codex and Claude Code.
- **Intended next step**: open a lightweight plan-tracking issue, then execute
  the implementation through the tracked plan.

## Purpose

Make the repo-managed `code-review` skill family run reviews in isolated
reviewer subagent contexts for both product targets. The main agent should own
scope detection, dispatch, validation, merge/synthesis of findings, and final
review judgment; reviewer subagents should own read-only review lenses and
return structured evidence.

This work is about `agent-runtime-kit`'s managed runtime surfaces and skills. It
does not target OpenAI's hosted GitHub code review product surface unless that
scope is explicitly added later.

## Confirmed Facts

- User target: Codex review should run through subagents in both Codex and
  Claude Code. [U1]
- The work was classified as L2 because it needs a plan bundle, provider issue,
  lifecycle state, multiple validation gates, and likely multiple PRs across
  surface docs, render/install behavior, and code-review skill routing. [U2]
- Current Codex documentation says custom agents can be defined as standalone
  TOML files under `~/.codex/agents/` or project `.codex/agents/`, with required
  `name`, `description`, and `developer_instructions` fields. [W1]
- Current Claude Code documentation says custom subagents are Markdown files
  with YAML frontmatter, can live under project/user/plugin agent locations, and
  plugin subagents are discovered from plugin `agents/` directories. [W2]
- Current runtime-kit surface docs still say Codex has no file-backed subagent
  loader in the kit activation surface and Claude subagent definitions are not
  shipped by this repo today. This is now a repo-surface gap to reconcile rather
  than an acceptable end state for this feature. [F1]
- `code-review-specialists` already has deterministic scope detection,
  specialist prompt files, a JSONL finding contract, and validate/merge/render
  CLI primitives. It currently allows reviewer subagents only under explicit
  delegated modes and otherwise runs lenses sequentially in the main agent. [F2]
- The existing code-review routing keeps lightweight quick-pass separate from
  full specialist review; preserving that distinction avoids making small diffs
  pay the cost of a full specialist fan-out. [F3]

## Decisions

1. **Cross-product source, product-native render**: add one canonical source for
   reviewer agent definitions and render it into product-native formats:
   Codex TOML agents and Claude Markdown/YAML subagents.
2. **Review always isolated; specialist fan-out remains risk-based**:
   `code-review-quick-pass` should use one read-only reviewer subagent;
   `code-review-specialists` should fan out only the selected specialist lenses.
3. **Main-agent ownership stays explicit**: the parent agent owns base-ref
   selection, scope detection, subagent dispatch, JSONL validation/merge,
   synthesis, review disposition, and any provider/PR workflow handoff.
4. **Subagents stay read-only**: reviewer agents must not edit files, post live
   provider comments, merge PRs/MRs, close issues, or make final delivery
   decisions.
5. **No silent inline fallback**: if a product/runtime cannot spawn the required
   reviewer subagent, the review workflow must report a waiver or blocker
   explicitly instead of silently doing the review in the main thread.
6. **Start with a vertical slice**: implement and validate the minimal
   quick-reviewer agent first, then extend to the full specialist set.

## Scope

In scope:

- Define a managed reviewer-agent source surface for runtime-kit.
- Render/install the source to Codex custom agents and Claude Code subagents.
- Update support matrix, harness-shape docs, manifests, link maps, render
  output, goldens, and drift checks as needed.
- Update `code-review-quick-pass` to use one reviewer subagent by default.
- Update `code-review-specialists` to dispatch selected read-only specialist
  reviewer subagents and merge JSONL findings through existing CLI primitives.
- Add validation that catches missing rendered/installed reviewer agents.
- Verify the feature through the normal project gates and any feasible
  Codex/Claude runtime probes.

Out of scope:

- Changing OpenAI hosted GitHub review behavior.
- Changing Claude Code or Codex upstream products.
- Making every implementation task use subagents.
- Replacing `review-specialists` JSONL validation/merge contracts.
- Posting provider review comments from code-review skills directly; delivery
  workflows still own provider mutation.
- Escalating to L3 dispatch unless implementation must split into independent
  parallel PR lanes.

## Implementation Boundaries

- New reviewer agent source should live under a managed repo-owned source path
  that is not confused with runtime home local state.
- Generated Codex/Claude agent files must be render outputs, not handwritten
  runtime-home edits.
- Keep product-specific syntax at render/template boundaries. Skill behavior
  should refer to reviewer agent identities and contracts, not duplicate two
  full product-specific instruction sets.
- Prefer reusing existing specialist prompt files and
  `SPECIALIST_REVIEW_CONTRACT.md` over inventing new review rubrics.
- If nils-cli render/install support is missing, implement the primitive in
  `sympoies/nils-cli`, release it, then bump runtime-kit floors before claiming
  the final runtime-kit delivery complete.

## Requirements

- R1: A canonical reviewer-agent source exists for at least a quick reviewer and
  the specialist lenses needed by `code-review-specialists`.
- R2: Codex render/install produces custom agent TOML files in the Codex agent
  discovery location used by the runtime-kit activation surface.
- R3: Claude render/install produces Markdown/YAML subagents in the Claude
  plugin or managed agent discovery location used by runtime-kit.
- R4: `code-review-quick-pass` dispatches one read-only reviewer subagent by
  default and reports an explicit waiver/blocker when unavailable.
- R5: `code-review-specialists` dispatches selected read-only specialist
  reviewer subagents, collects findings in the existing JSONL schema, validates
  them, and merges them into the final report.
- R6: Main-agent synthesis remains responsible for confidence, residual-risk
  handling, and final review outcome.
- R7: Support matrix and harness-shape docs reflect the shipped/partial state
  accurately for both products.
- R8: Validation fails when declared reviewer-agent render/install artifacts are
  missing or drift from source.

## Acceptance Criteria

- A1: Codex and Claude runtime targets both include a managed quick-reviewer
  subagent/agent artifact generated from the same canonical source.
- A2: Codex and Claude runtime targets both include managed specialist reviewer
  artifacts for testing, maintainability, security, performance, api-contract,
  data-migration, and red-team, unless scope detection proves a smaller
  deliberate first release.
- A3: `code-review-quick-pass` documentation and rendered skills require the
  reviewer subagent path or an explicit waiver/blocker.
- A4: `code-review-specialists` documentation and rendered skills require
  specialist subagent dispatch for selected lenses and retain
  `review-specialists validate/merge` as the structured evidence gate.
- A5: `agent-runtime render --product codex`, `agent-runtime render --product
  claude`, support-matrix render, golden refresh, drift audit, sandbox install
  rehearsal, runtime-smoke, and hook tests pass.
- A6: A live or documented probe verifies that the installed Codex and Claude
  surfaces can see the reviewer agent definitions, or records the exact
  product/runtime limitation as a tracked blocker.

## Validation Plan

- Bundle/tracker:
  - `plan-tooling validate --file docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md --format text --explain`
  - `plan-issue record audit --profile tracking --expect-visible`
- Render and governance:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --target support-matrix`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/skill-governance-audit.sh`
- Runtime surface:
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`
  - product-specific probe commands for Codex and Claude reviewer-agent
    discovery when safe.
- Final project validation:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

## Risks And Guardrails

- **Product surface drift**: Codex custom agent authoring is newer than this
  repo's current surface docs. Guardrail: update manifests, support matrix, and
  acceptance checks before relying on the surface.
- **Over-review of tiny diffs**: running every review through all specialists
  would be expensive and noisy. Guardrail: quick-pass uses one reviewer;
  specialists still depend on scope/risk selection.
- **Silent fallback**: doing review inline after subagent dispatch fails would
  hide the feature gap. Guardrail: require explicit waiver or blocker.
- **Provider mutation leakage**: reviewer agents may propose comments or fixes.
  Guardrail: reviewer agents are read-only and output evidence only; delivery
  skills own comments, fixes, merges, and closeout.
- **Upstream renderer gap**: if nils-cli cannot render/install arbitrary agent
  definitions, runtime-kit alone cannot finish the feature. Guardrail: record
  the nils-cli dependency in the tracker and release/bump before final closeout.

## Execution

- Status: ready for L2 tracking.
- Recommended plan: docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md
- Recommended execution state: docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-execution-state.md
- Next-task source: this document.

## Retention Intent

Coordination material. Archive with the plan bundle after closeout unless the
cross-product agent-surface design becomes canonical, in which case promote the
stable design into the owning source docs and keep this as retained execution
history.

## Read-First References

- [U1] User request in this session: "my goal is to make Codex review use
  subagents in both Codex and Claude Code."
- [U2] Work-tier decision in this session: classify as L2 plan tracking issue.
- [W1] Codex Subagents documentation:
  <https://developers.openai.com/codex/subagents>
- [W2] Claude Code Subagents documentation:
  <https://docs.anthropic.com/en/docs/claude-code/sub-agents>
- [F1] `docs/source/harness-shape-codex.md`,
  `docs/source/harness-shape-claude.md`, and `manifests/surfaces.yaml`.
- [F2] `core/skills/code-review/code-review-specialists/SKILL.md.tera` and
  `core/skills/code-review/code-review-specialists/references/`.
- [F3] `core/skills/code-review/README.md`.

## Recommended Next Artifact

Open the lightweight plan-tracking issue from this bundle, initialize run state,
then execute Task 1.2 to baseline the currently shipped surfaces before editing
render/install code.
