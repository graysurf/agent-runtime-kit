# Guided Feature Build Skill Implementation Handoff

- **Status**: ready for implementation
- **Date**: 2026-06-13
- **Source**: `discussion-to-implementation-doc` capture of an in-session design
  discussion comparing `anthropics/claude-code` `plugins/feature-dev` against
  the kit's existing skill surface.
- **Intended next step**: implement a new repo-owned runtime-kit skill via
  `create-skill`. Implementation may be performed by Codex or Claude; the
  artifact is identical either way.

## Purpose

Add one opt-in, in-session **feature build conductor** skill,
`guided-feature-build`, that sequences a feature from discovery through a
quality-review gate. It fills the band between "just start editing" (L0) and an
issue-backed dispatch/plan-tracking workflow (L2/L3): disciplined phasing and
user gates without provider artifacts.

The design is inspired by `feature-dev` but reshaped to the kit's cross-product
skill model so it runs on both Codex and Claude.

## Confirmed Facts

- `feature-dev` ships as a Claude-only plugin: one `/feature-dev` command plus
  three subagents (`code-explorer`, `code-architect`, `code-reviewer`) driving a
  7-phase flow — Discovery, Codebase Exploration, Clarifying Questions,
  Architecture Design, Implementation, Quality Review, Summary. [W1]
- The kit ships skills, not subagents or slash commands, as its cross-product
  unit. Per `SUPPORT_MATRIX.md`:
  - Surface 15 (Codex local skill root) and surface 5 (Claude plugin-scoped
    skills): a skill renders to **both** products.
  - Surface 7 (`agents/<n>.md`): Codex **not-applicable** (no file-backed
    subagent loader); Claude **not-shipped** (kit ships none today).
  - Surface 6 (`commands/<n>.md`): Codex **not-applicable**; Claude shipped.
  - Surface 17 (prompt-mode delegation policy in `AGENT_HOME.md`): shipped to
    **both** products. [F1]
- The kit already covers `feature-dev`'s review concept, more rigorously:
  `core/skills/code-review/` has five skills plus a severity/confidence contract
  (`code-review-specialists/references/SPECIALIST_REVIEW_CONTRACT.md`, high
  confidence gated at `0.80`–`1.00`) and evidence capture. [F2]
- `conversation/` already hosts execution-mode and workflow skills that rely on
  in-skill delegation gated by runtime availability — `orchestrator-first`,
  `parallel-first`, `test-first` — using a `references/prompts/<name>.md`
  canonical-prompt pattern and the precondition "subagent delegation is
  available and allowed by active runtime instructions before any subagents are
  spawned." [F3]
- Repo-owned core skills use plain family-scoped kebab-case names (no
  `project-*` / `private-*` prefix). [F3]

## Decisions

1. **Name and home**: `guided-feature-build` in the `conversation/` family.
   No name prefix (repo-owned core skill convention). [F3]
2. **Form factor**: ship as a single **skill** only. Do **not** add
   `agents/<n>.md` (surface 7) or `commands/<n>.md` (surface 6); both leave
   Codex with no loadable artifact. This is what makes it cross-product. [F1]
3. **Delegated roles, not subagent files**: express `feature-dev`'s explorer and
   architect roles as in-skill delegated-role prompts under
   `references/prompts/` (mirroring the `orchestrator-first` precedent). The
   conductor spawns them at delegation points when delegation is available. [F3]
4. **Reuse review, do not re-author it**: the Quality Review phase delegates to
   the existing `code-review-specialists` for broad/risky diffs, and to
   `code-review-quick-pass` for small/ordinary diffs. No new reviewer role
   prompt ships. [F2]
5. **Graceful degradation**: when runtime delegation is unavailable or
   disallowed, the conductor runs the same explorer/architect role prompts
   **inline as sequential passes** rather than failing — so Codex remains usable
   even where its delegation is weaker than Claude's. [F1][F3]
6. **Work-tier placement**: the conductor is an in-session L0–L1 procedure that
   creates no provider artifacts. If work escalates (multiple lanes, durable
   issue tracking), it hands off to `deliver-plan-tracking-issue` or
   `deliver-dispatch-plan` rather than growing its own tracking. [F4]
7. **Mode composition, not duplication**: when the user already has
   `test-first` / `parallel-first` / `orchestrator-first` active, the
   Implementation phase honors those modes instead of re-implementing their
   behavior.

## Scope

- One new skill `core/skills/conversation/guided-feature-build/` with its
  `SKILL.md` source and `references/prompts/` role prompts (explorer,
  architect).
- Seven-phase conductor flow with explicit user gates at clarifying questions
  (phase 3), architecture choice (phase 4), implementation approval (phase 5),
  and review disposition (phase 6).
- Manifest, render-surface, golden, and governance wiring produced through
  `create-skill` so the skill renders to Codex (surface 15) and Claude
  (surface 5).

## Non-Scope

- No `agents/<n>.md` source and no change to surface 7's not-shipped status.
- No new slash command (surface 6).
- No new code-review skill; the review phase reuses existing code-review skills.
- No provider issue/PR/plan-tracking behavior inside the conductor.
- No new CLI binary or `nils-cli` change.
- No change to the `AGENT_HOME.md` delegation policy text; the skill consumes
  the existing policy.

## Implementation Boundaries

- Author only under `core/skills/conversation/guided-feature-build/` plus the
  manifest/render artifacts that `create-skill` owns.
- Phase-6 review must call the existing code-review skills by name; do not
  inline a bespoke confidence rubric.
- Delegation-availability handling must match the `orchestrator-first`
  precondition style; do not invent a new gating mechanism.

## Requirements

- R1: A `SKILL.md` with a `name`/`description` frontmatter that triggers on
  guided feature-build requests and is distinct from `dispatch` and from the
  `*-first` modes.
- R2: A seven-phase workflow: Discovery → Exploration → Clarifying Questions →
  Architecture Design → Implementation → Quality Review → Summary.
- R3: Exploration delegates 2–3 explorer-role passes, each returning entry
  points with `file:line` and a curated 5–10 file read list; the conductor reads
  those files before proceeding. [W1]
- R4: Architecture Design delegates 2–3 architect-role passes with distinct
  focuses (minimal-change / clean / pragmatic), then presents a comparison and a
  single recommendation and **waits** for the user's choice. [W1]
- R5: Clarifying Questions and Implementation are explicit gates; implementation
  does not start without user approval.
- R6: Quality Review routes to `code-review-specialists` or
  `code-review-quick-pass` by diff size, then presents findings and asks
  fix-now / fix-later / proceed-as-is.
- R7: When delegation is unavailable, the same explorer/architect role prompts
  run inline sequentially (degradation, not failure).
- R8: The skill renders identically to Codex and Claude with no product-specific
  source branch beyond what delegation availability dictates at runtime.

## Acceptance Criteria

- A1: `core/skills/conversation/guided-feature-build/SKILL.md` exists with role
  prompts under `references/prompts/`; no `agents/` or `commands/` files are
  added.
- A2: The skill appears in `manifests/skills.yaml` and renders into both
  `build/codex/.../skills/...` and `build/claude/.../skills/...`.
- A3: `SUPPORT_MATRIX.md` surface 7 stays `not-shipped` (Claude) /
  `not-applicable` (Codex) — i.e. no subagent source was introduced.
- A4: The `SKILL.md` body references `code-review-specialists` /
  `code-review-quick-pass` for phase 6 and does not define an independent
  confidence-scoring rubric.
- A5: `bash scripts/ci/all.sh && bash tests/hooks/run.sh` passes, including the
  render (gate 3), golden (gate 4), drift (gate 5), doctor skill-surface
  (gate 7), and runtime-smoke (gate 8) checks that apply to a new cross-product
  skill. [F1][F5]

## Validation Plan

- Add the skill through `create-skill` (owns source, manifest, render surfaces,
  acceptance coverage, governance). [F6]
- Run `bash scripts/ci/all.sh && bash tests/hooks/run.sh` (the declared
  `project-dev` validation). [F5]
- Confirm cross-product render with the kit's render/golden/drift gates rather
  than by hand. [F1]
- Spot-check the skill triggers on a guided feature-build request and that the
  review phase dispatches to an existing code-review skill.

## Risks And Guardrails

- **Overlap with `dispatch` and the `*-first` modes**: mitigated by Decision 6
  and 7 (in-session only; hand off on escalation; compose with active modes).
  The `description` must make the boundary discoverable.
- **Delegation assumption**: Claude and Codex differ in delegation strength;
  Decision 5 (inline degradation) is the guardrail. Do not hard-require
  subagents.
- **Review drift**: re-authoring a reviewer would fork the confidence rubric;
  Decision 4 forbids it.
- **Scope creep into surface 7**: tempting to ship "real" subagents for the
  Claude experience; explicitly out of scope (Non-Scope) because Codex can never
  consume them and it is a separate engineering track.

## Execution

- Status: not started; ready for `create-skill`.
- Next-task source: this document.
- Recommended next workflow: `create-skill`, then the declared validation.
  (No `Recommended plan` / `Recommended execution state` lines: this is a
  `docs/discussions/` capture, not an L2 plan bundle.)
- If the implementer is Codex, no special handling is required — the output is a
  cross-product skill by construction.

## Retention Intent

Coordination material; cleanup-eligible once `guided-feature-build` ships (or the
idea is abandoned). Promote to canon only if it becomes authoritative reference
beyond this one change.

## Read-First References

- `[W1]` `github.com/anthropics/claude-code` `plugins/feature-dev`
  (README + command + `code-explorer` / `code-architect` / `code-reviewer`
  agents; fetched 2026-06-13).
- `[F1]` `SUPPORT_MATRIX.md` — surfaces 5, 6, 7, 15, 17.
- `[F2]` `core/skills/code-review/` (README + `code-review-specialists`,
  `code-review-quick-pass`, `SPECIALIST_REVIEW_CONTRACT.md`).
- `[F3]` `core/skills/conversation/orchestrator-first/SKILL.md.tera` and the
  `parallel-first` / `test-first` siblings (delegation-gated mode pattern,
  `references/prompts/` convention, naming).
- `[F4]` `core/policies/work-tier-levels.md` (L0–L3 ladder).
- `[F5]` `DEVELOPMENT.md` validation entrypoint
  (`scripts/ci/all.sh`, `tests/hooks/run.sh`).
- `[F6]` `create-skill` skill (repo-owned skill scaffolding + governance).

## Recommended Next Artifact

`create-skill` invocation for `conversation/guided-feature-build`, followed by
the declared validation. If execution later needs tracked lanes, graduate this
capture into a `docs/plans/<YYYY-MM-DD>-<slug>/` bundle and use
`create-plan-tracking-issue`.
