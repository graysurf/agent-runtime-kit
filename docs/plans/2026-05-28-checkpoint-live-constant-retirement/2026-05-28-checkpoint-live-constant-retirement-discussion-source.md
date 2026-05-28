# Checkpoint-Live Not-Implemented Constant Retirement Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-28
- Source: deferred Future Work item #1 from the
  `2026-05-28-plan-task-ledger-durability` rollout. Identified at the
  tail of plan-tracking issue #146 closeout
  (`graysurf/agent-runtime-kit#146`) as the cleanest near-term
  follow-up once `tracking checkpoint --live --post` shipped in
  `plan-issue-cli@0.25.6` (`sympoies/nils-cli#606` → `1edf007`) and
  was consumed at runtime-kit by PR #145 + #147.
- Intended next step: generate the single-plan bundle under
  `docs/plans/2026-05-28-checkpoint-live-constant-retirement/`, then
  open a tracking issue via `create-plan-tracking-issue` or absorb
  into the next `deliver-plan-tracking-issue` cycle. This is a source
  artifact, not an implementation plan.

## Execution

This document feeds **one** plan executed in two lanes
(upstream `sympoies/nils-cli` constant + doc-comment cleanup with
no behavior change → runtime-kit Failure-modes scrub across the
five active dispatch / tracking SKILL bodies and one spec mention).

- Recommended plan: docs/plans/2026-05-28-checkpoint-live-constant-retirement/2026-05-28-checkpoint-live-constant-retirement-plan.md
- Recommended execution state: docs/plans/2026-05-28-checkpoint-live-constant-retirement/2026-05-28-checkpoint-live-constant-retirement-execution-state.md
- Status: ready to implement immediately; both lanes are
  independent docs-only diffs and can run in parallel
- Next-task source: this document

## Purpose

`tracking-checkpoint-live-not-implemented` was the stable blocker
code returned by the controller while `plan-issue tracking
checkpoint --live` was still a refusal stub. The C rollout
(`docs/plans/2026-05-28-tracking-checkpoint-live/`) shipped the live
posting hop in `plan-issue-cli@0.25.6`, after which no live-mode
invocation can emit the code (the upstream integration test
`tracking_checkpoint_refusals.rs:139-145` documents the retirement
explicitly, and `execute.rs:2117` keeps the constant only as a
forward-compatibility marker against future regression).

Five active SKILL bodies in this repo still list
`tracking-checkpoint-live-not-implemented` as a controller refusal
code skills must propagate, and one spec section in
`docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
names it as the canonical example refusal code. Those references
made sense before `0.25.6`, but on `>=0.25.6` they describe a
code path that no longer reaches user-facing tooling. New
implementers reading the dispatch / tracking SKILL bodies today
will treat the code as a live refusal class they need to handle,
which is documentation drift.

This source captures the agreed retirement scope and the
non-scope guardrails so the cleanup lands without weakening the
forward-compatibility marker on the upstream constant.

## Confirmed Facts

- [U1] User accepted "constant retirement" as the cleanest of the
  three open Future Work items from the
  `2026-05-28-plan-task-ledger-durability` rollout, and asked for
  it to land as its own plan bundle rather than be absorbed into a
  later unrelated cycle.
- [F1] Five active `core/skills/dispatch/<skill>/SKILL.md.tera`
  files list `tracking-checkpoint-live-not-implemented` under
  Failure modes as a controller-surfaced refusal code skills must
  propagate:
  - `deliver-plan-tracking-issue/SKILL.md.tera:58`
  - `execute-dispatch-lane/SKILL.md.tera:53`
  - `execute-plan-tracking-issue/SKILL.md.tera:59`
  - `review-dispatch-lane-pr/SKILL.md.tera:53`
  - `deliver-dispatch-plan/SKILL.md.tera:62`
- [F2] One spec body in
  `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md:464`
  names `tracking-checkpoint-live-not-implemented` as the canonical
  example for "controller-surfaced refusal codes the skill must
  propagate" in the Failure-modes section authoring guidance.
- [F3] One archived heuristic-inbox entry references the code in
  body text only:
  `core/policies/heuristic-system/error-inbox/archive/2026/tracking-closeout-review-state-complete-gap/ENTRY.md:10`.
  This is post-mortem narrative — the entry's `Status: promoted`
  resolution explicitly cites `0.25.6` as the resolution and the
  code reference is descriptive, not prescriptive.
- [F4] Upstream `sympoies/nils-cli` retains the constant in two
  intentional, well-commented places that document why it is
  retained:
  - `crates/plan-issue-cli/src/execute.rs:2117` — a doc comment
    on `post_checkpoint_live` stating "retained as a stable error
    code for any future regression that reintroduces a refusal
    branch on the `--live` path; the live-mode posting branch
    above no longer emits it."
  - `crates/plan-issue-cli/tests/integration/tracking_checkpoint_refusals.rs:139-145`
    — a NOTE comment recording that the refusal coverage was
    retired and pointing positive coverage to
    `tracking_checkpoint_live.rs`.
  - Two positive-path assertions in
    `tracking_checkpoint_live.rs:148` and `tracking_checkpoint_live.rs:305`
    assert the code is **absent** from the blocked-codes list,
    which is the regression guard the doc-comment refers to.
- [F5] `crates/plan-issue-cli/CHANGELOG.md:29` Unreleased section
  describes the `--live` rollout and the historical refusal
  blocker shape. The reference is in the v0.25.6 release-notes
  context; it is historical narrative not subject to retirement.
- [F6] Runtime-kit consumes the live behavior at floor
  `plan-issue >=0.25.7` (raised to `>=0.25.8` after the
  workspace lock-step catch-up `sympoies/nils-cli#608` → tag
  `v0.25.8` and tap bump `nils-cli-v0.25.8`). Both
  the dispatch / tracking skills and `scripts/ci/all.sh`
  Position 2 surface-floor probe lock that floor.
- [F7] The C plan bundle (`docs/plans/2026-05-28-tracking-checkpoint-live/`)
  still references the code in plan body text and execution-state
  notes. That bundle is post-execution narrative — it is a
  candidate for `plan-archive-migrate` to `agent-plan-archive`,
  not for in-place edits, per the rollout's own retention
  intent.

## Decisions

- **Decision 1**: Drop
  `tracking-checkpoint-live-not-implemented` from every
  active-skill Failure-modes block ([F1]) on the runtime-kit side,
  because skills cannot encounter it on `>=0.25.6` and naming it
  trains readers to handle a dead code path.
- **Decision 2**: Rewrite the spec example in
  `plan-issue-skill-family-redesign-v1.md:464` ([F2]) to use a
  different controller-surfaced refusal code that is still live
  (e.g. `run-state-stale`, `RECORD_BLOCKED`, or
  `visible-completeness-failed`) so the authoring guidance does
  not point to a retired code.
- **Decision 3**: **Retain** the upstream constant, doc-comment,
  retired-refusal NOTE, and the two positive-path absence
  assertions ([F4]) as the forward-compatibility marker. Removing
  them would weaken the regression guard against a future change
  that reintroduces a refusal branch on the `--live` path. The
  upstream lane of this plan is a no-op behavior change; if any
  upstream edits land, they only tighten the doc comment to
  reflect the now-shipped + consumed posting hop.
- **Decision 4**: **Do not touch** the archived heuristic-inbox
  entry ([F3]) or the C plan bundle text ([F7]). Both are
  immutable historical narrative; rewriting them rewrites
  history. The plan archives the cleanup of *active reference
  surfaces* only.
- **Decision 5**: Skill body changes are docs-only (`.tera`
  templates) and require the standard render pass
  (`agent-runtime render --update-golden`) to refresh Codex /
  Claude / shared targets. No CLI floor bump, no smoke-probe
  changes, no behavior contract changes.
- **Decision 6**: Spec wording change is docs-only and does not
  touch the redesign's normative content; it only swaps the
  example refusal code used to illustrate Failure-modes authoring.
- **Decision 7**: Heuristic-inbox entry creation is out of scope
  — the gap that motivates this retirement is already a "promoted"
  archived entry ([F3]) and the existing `0.25.6` resolution
  narrative already covers the why. The plan only acts on the
  surface drift, not the underlying class of incident.

## Scope

- **In**: Five active-skill `.tera` Failure-modes blocks ([F1]);
  one spec example sentence ([F2]); render-pass refresh for
  Codex / Claude / shared goldens; optional upstream doc-comment
  tightening on `execute.rs:2117` if it improves clarity (no
  symbol or test removal).
- **In**: Validation that `scripts/ci/all.sh` 1-13 + skill
  render goldens + markdownlint + docs-placement audit all pass
  after the scrub. No new tests; the existing upstream positive
  absence assertions ([F4]) already guard regression.
- **Out**: Removing the upstream constant `Cow<'static, str>` or
  any associated `blocked` push site (none exist) on
  `plan-issue-cli`. **Retained intentionally** ([F4]).
- **Out**: Removing the upstream test note or positive-path
  absence assertions ([F4]). **Retained intentionally**.
- **Out**: Editing the archived heuristic-inbox entry text
  ([F3]). Archived = immutable.
- **Out**: Editing C plan bundle text ([F7]). Plan-archive
  migration is a separate work item (deferred to a later cycle).
- **Out**: CHANGELOG edits on
  `plan-issue-cli/CHANGELOG.md` ([F5]). The release-notes
  narrative for 0.25.6 is correct and historical.
- **Out**: Bumping the upstream nils-cli workspace; no CLI floor
  change.

## Implementation Boundaries

- Stay docs-only in this repo. Any upstream edits ([F4]
  doc-comment) are optional and must remain no-op on behavior;
  the constant must stay defined and the positive-path absence
  assertions must keep asserting.
- Do not introduce a deprecation marker on the upstream constant.
  The constant is retained as a forward-compatibility marker, not
  marked for removal; deprecating it would defeat its purpose.
- Do not collapse multiple Failure-modes refusal codes into one
  line per `.tera` file; preserve the existing list shape and
  only drop the retired entry.
- Render goldens must be regenerated in the same commit / PR as
  the `.tera` edits to keep Codex / Claude / shared targets
  in sync with the source templates.
- Markdown line-length budget on the spec edit must stay within
  the project's existing rumdl MD013 contract (80 chars by
  default for the prose lines this edit touches).

## Requirements

- R1: Every active-skill `.tera` ([F1]) no longer lists
  `tracking-checkpoint-live-not-implemented` under Failure modes
  as a controller-surfaced refusal code. The list ordering and
  surrounding bullets are preserved minus the retired entry.
- R2: The spec example in
  `plan-issue-skill-family-redesign-v1.md:464` ([F2]) cites a
  refusal code that is still live as of `plan-issue-cli >=0.25.8`.
- R3: Render-pass goldens for Codex / Claude / shared targets
  ([F1] consumers) match the new `.tera` source. No golden drift.
- R4: `scripts/ci/all.sh` 1-13 passes (rumdl, plan-bundle-validate,
  docs-placement, smoke probes, render-check). Smoke probes
  unchanged; no new probe added.
- R5: Upstream constant, doc-comment, retired-refusal test NOTE,
  and the two positive-path absence assertions ([F4]) remain in
  place. If the upstream doc-comment is reworded for clarity, the
  reword does not weaken the "retained as a stable error code
  for forward compatibility" semantics.
- R6: Archived heuristic-inbox entry ([F3]) and C plan bundle
  text ([F7]) are untouched.

## Acceptance Criteria

- AC1: `grep -rn "tracking-checkpoint-live-not-implemented"
  core/skills/dispatch/*/SKILL.md.tera` returns zero hits.
- AC2: `grep -rn "tracking-checkpoint-live-not-implemented"
  docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
  returns zero hits.
- AC3: `grep -rn "tracking-checkpoint-live-not-implemented"
  core/policies/heuristic-system/error-inbox/archive/`
  still returns the existing archived hit ([F3]) — proves the
  cleanup did not touch immutable history.
- AC4: `agent-runtime render --update-golden` produces no
  unstaged diff after the `.tera` edits land (render is idempotent
  given the new source).
- AC5: `bash scripts/ci/all.sh` exits 0 across Positions 1-13.
- AC6: `cargo test -p plan-issue-cli --test tracking_checkpoint_live`
  passes on the upstream checkout (proves positive absence
  assertions still hold). If the upstream lane is a no-op
  (no doc-comment reword), this is implicit; if it edits the
  doc comment, the test run is explicit evidence.
- AC7: `git grep "tracking-checkpoint-live-not-implemented"`
  across runtime-kit returns only the archived inbox entry
  ([F3]) and the C plan bundle text ([F7]).

## Validation Plan

- Local: `bash scripts/ci/all.sh` (full 1-13 stack) after the
  scrub + render pass.
- Local: targeted `agent-runtime render --check` to confirm
  goldens match `.tera` sources without `--update-golden`.
- Local: `rumdl check --no-respect-gitignore docs/source/plan-issue-redesign/`
  to confirm spec edit stays within MD013 budget.
- Upstream (only if doc-comment is reworded):
  `cargo test -p plan-issue-cli --test tracking_checkpoint_live`
  and `cargo test -p plan-issue-cli --test tracking_checkpoint_refusals`.
- CI: standard runtime-kit `ci/all.sh` plus the deterministic
  smoke probes (no new probes needed).

## Risks And Guardrails

- **Risk**: Future regression reintroduces a `--live` refusal branch
  but the SKILL Failure-modes lists no longer name the code, so
  the dispatch skills do not propagate it cleanly. **Guardrail**:
  the upstream positive-path absence assertions
  (`tracking_checkpoint_live.rs:148,305`) catch the regression at
  upstream CI before any release tag ships; the runtime-kit floor
  probe catches a downstream consumer that lands a regressed
  upstream tag.
- **Risk**: A reader of an active SKILL body assumes the code is
  still a live refusal class and writes new error-handling for
  it. **Guardrail**: the retirement landed at controller-level
  (no emission on `>=0.25.6`) and is documented in the upstream
  doc comment plus the retired-refusal test NOTE; the source of
  truth for "is this code live?" is the upstream code, not the
  SKILL bodies.
- **Risk**: Spec edit changes the example refusal code in a way
  that subtly changes the authoring guidance's tone. **Guardrail**:
  the example codes must come from the existing live set
  (`run-state-stale`, `RECORD_BLOCKED`, `visible-completeness-failed`,
  role-specific codes from
  `plan-tracking-issue-comment-taxonomy-v1.md`); the spec already
  enumerates the live set in the same paragraph.
- **Risk**: Render goldens drift if the `.tera` edits land
  without the matching golden refresh. **Guardrail**: AC4 +
  CI render-check.

## Retention Intent

- This source document is plan-scoped: clean up after the
  retirement plan lands and either archive with the plan bundle
  or migrate to `agent-plan-archive` per the active retention
  policy. No promotion to a domain doc; the underlying knowledge
  (constant retired but retained for forward compat) already
  lives in the upstream doc comment + retired-refusal test NOTE,
  which is the durable record.

## Read-First References

- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  (does not list the code today but is part of the same family
  and should be confirmed to stay clean)
- `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
  (section: Failure-modes authoring guidance, around line 461-467)
- Upstream `crates/plan-issue-cli/src/execute.rs:2102-2119`
  (`post_checkpoint_live` doc comment)
- Upstream `crates/plan-issue-cli/tests/integration/tracking_checkpoint_refusals.rs:139-145`
  (retired-refusal NOTE)
- Upstream `crates/plan-issue-cli/tests/integration/tracking_checkpoint_live.rs:148,305`
  (positive-path absence assertions)
- Predecessor plan bundle (do not edit):
  `docs/plans/2026-05-28-tracking-checkpoint-live/`
- Predecessor heuristic-inbox entry (archived, do not edit):
  `core/policies/heuristic-system/error-inbox/archive/2026/tracking-closeout-review-state-complete-gap/ENTRY.md`

## Recommended Next Artifact

- `docs/plans/2026-05-28-checkpoint-live-constant-retirement/2026-05-28-checkpoint-live-constant-retirement-plan.md`
  — task-by-task plan with two lanes (runtime-kit scrub +
  optional upstream doc-comment reword) and a single sprint.
- `docs/plans/2026-05-28-checkpoint-live-constant-retirement/2026-05-28-checkpoint-live-constant-retirement-execution-state.md`
  — empty ledger seeded from the plan's task list.
