# Dispatch-Profile `--live` And Ledger Parity Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-28
- Source: deferred Future Work item #2 from the
  `2026-05-28-plan-task-ledger-durability` rollout. The
  tracking-profile skills (`execute-plan-tracking-issue`,
  `deliver-plan-tracking-issue`, `plan-tracking-issue-closeout`) now
  use `tracking checkpoint --live` for live posting and
  `plan-tooling ledger-update` for per-task ledger durability; the
  dispatch-profile siblings (`execute-dispatch-lane`,
  `review-dispatch-lane-pr`, `deliver-dispatch-plan`,
  `dispatch-plan-closeout`) still describe the pre-`0.25.6`
  `record post` and pre-ledger-durability flows.
- Intended next step: generate the single-plan bundle under
  `docs/plans/2026-05-28-dispatch-profile-live-ledger-parity/`,
  then open a tracking issue via `create-plan-tracking-issue`.
  This is a source artifact, not an implementation plan.

## Execution

This document feeds **one** plan executed in one lane
(runtime-kit-only docs + SKILL body changes). No upstream
`sympoies/nils-cli` work; the controller surfaces already exist
(0.25.7 `ledger-update`, 0.25.6 `--live`, 0.25.7 `close-ready
ledger-rows-pending`).

- Recommended plan: docs/plans/2026-05-28-dispatch-profile-live-ledger-parity/2026-05-28-dispatch-profile-live-ledger-parity-plan.md
- Recommended execution state: docs/plans/2026-05-28-dispatch-profile-live-ledger-parity/2026-05-28-dispatch-profile-live-ledger-parity-execution-state.md
- Status: ready to implement immediately
- Next-task source: this document

## Purpose

The `tracking` and `dispatch` profiles share the same controller
surface but have diverged in how their owning SKILL bodies use it.
After the ledger-durability rollout (PRs #145 + #147 + #148), the
`tracking` profile skills wire:

1. CLI floor `plan-issue >=0.25.7, plan-tooling >=0.25.7`.
2. `tracking checkpoint --live --post <roles>` as the canonical
   posting hop (no more `record post` fallback to provider
   `gh issue comment`).
3. `plan-tooling ledger-update` after each task to keep the plan
   bundle's `execution-state.md` ledger durable per task.
4. `tracking run update --note "<closing summary>"` at closeout
   to seed an `events.jsonl` closing-summary event.
5. `tracking close-ready` blocker `ledger-rows-pending` so the
   gate refuses to close while any ledger row is still `pending`
   at `phase=ready_for_close`.

The `dispatch` profile skills still describe the pre-`0.25.6`
shape: `tracking checkpoint` without `--live`, no
`plan-tooling ledger-update` per-task wiring, no closing-summary
note, and no `ledger-rows-pending` failure-mode entry on the
closeout body. The controller surfaces (`--profile dispatch
--live`, `ledger-update`, `close-ready --profile dispatch`)
already exist at the right floor; only the SKILL bodies need to
catch up to match the tracking-profile shape.

This source captures the parity goal and the per-skill mapping
so the dispatch SKILL bodies land with the same lifecycle
invariants the tracking SKILL bodies enforce.

## Confirmed Facts

- [U1] User accepted "dispatch-profile parity" as the second of
  the three open Future Work items from the
  `2026-05-28-plan-task-ledger-durability` rollout, and asked
  for it to land as its own plan bundle.
- [F1] Four dispatch-profile SKILL bodies are in scope:
  - `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
    (Lane scope: per-lane `state,session,validation`).
  - `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
    (Lane scope: lane `review` + optional `state,session` if the
    review flips lane progress).
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
    (Dispatch-level rollup `state,session`, dashboard repair,
    and close-ready handoff to `dispatch-plan-closeout`).
  - `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
    (Strict close-ready gate + `record close --profile dispatch`).
- [F2] Current dispatch-profile floor reads
  `plan-issue >=0.22.3` across all four bodies
  (`execute-dispatch-lane/SKILL.md.tera:14`,
  `review-dispatch-lane-pr/SKILL.md.tera:14`,
  `deliver-dispatch-plan/SKILL.md.tera:14`,
  `dispatch-plan-closeout/SKILL.md.tera:14`).
  None mention `plan-tooling >=0.25.7`.
- [F3] Current dispatch-profile Entrypoint blocks use
  `tracking checkpoint --profile dispatch --post <roles>` with
  no `--live` flag. Example:
  `execute-dispatch-lane/SKILL.md.tera:85-88`. The `--live`
  switch is the canonical 0.25.6+ posting hop; without it,
  agents have to fall back to dry-run or a no-op
  `tracking checkpoint`.
- [F4] No dispatch-profile SKILL body references
  `plan-tooling ledger-update` per-task. The plan bundle's
  `execution-state.md` ledger is the canonical per-task record
  for dispatch plans as well as tracking plans — the same
  durability gap that the ledger-durability rollout closed for
  tracking applies one-to-one for dispatch.
- [F5] `dispatch-plan-closeout/SKILL.md.tera` does not list
  `ledger-rows-pending` under Failure modes (only `close-ready`
  blocker shape is described abstractly). The controller's
  `tracking close-ready --profile dispatch` returns the same
  `ledger-rows-pending` blocker the tracking profile does when
  any plan-bundle ledger row is still `pending` at
  `phase=ready_for_close`; the SKILL body needs to surface this
  explicitly.
- [F6] `deliver-dispatch-plan/SKILL.md.tera:48` already mentions
  `tracking checkpoint --repair-dashboard`, which is the same
  affordance the tracking profile uses; this part of the surface
  is already aligned.
- [F7] The C rollout
  (`docs/plans/2026-05-28-tracking-checkpoint-live/`) only
  scoped `--live` to the tracking profile; the dispatch-profile
  parity was deliberately deferred. The ledger-durability
  rollout (`docs/plans/2026-05-28-plan-task-ledger-durability/`)
  Task 4.4 was scoped to the tracking SKILLs only; "dispatch
  parity" appears in the Future Work list of both plan bundles.
- [F8] Render-pass parity contract: every `.tera` edit must be
  followed by `agent-runtime render --update-golden` to keep
  Codex / Claude / shared targets aligned, same as the
  ledger-durability rollout.

## Decisions

- **Decision 1**: Adopt the tracking-profile pattern one-to-one
  for the dispatch profile. The per-task ledger flow
  (`tracking run update --selected-task <id>` → local work →
  `plan-tooling ledger-update` → `tracking checkpoint --live`)
  applies to dispatch lanes the same way it applies to tracking
  task posts. The ledger row's `task_id` maps to the lane's
  `selected_task`.
- **Decision 2**: Bump the four dispatch-profile SKILL CLI floors
  to `plan-issue >=0.25.7, plan-tooling >=0.25.7` to match the
  tracking-profile floor. (The next floor bump — `0.25.8` lock-step
  catch-up — is a CHANGELOG-only release; no functional new
  surface, so `>=0.25.7` is the right semantic minimum. The plan
  may choose to set `>=0.25.8` instead for ecosystem coherence;
  this is an authoring detail, not a behavior decision.)
- **Decision 3**: Switch every dispatch-profile Entrypoint
  `tracking checkpoint --profile dispatch --post <roles>` line
  to `--live --post <roles>`. Lane scope and rollup scope are
  unchanged; only the posting hop becomes live by default.
- **Decision 4**: Add a `plan-tooling ledger-update` step to
  `execute-dispatch-lane` Workflow between "Implementation" and
  "Lane checkpoint", and to `deliver-dispatch-plan` Workflow
  immediately before the rollup checkpoint. The ledger update
  carries `--task-id "$TASK_ID" --status done --evidence
  "$VALIDATION_LOG"`.
- **Decision 5**: Add `ledger-rows-pending` to
  `dispatch-plan-closeout` Failure modes, parallel to the
  tracking-profile closeout entry. The strict gate already
  emits the blocker; the SKILL body just needs to name it.
- **Decision 6**: Add a "Closing summary event" step to
  `dispatch-plan-closeout` Workflow: call
  `tracking run update --profile dispatch --note "<closing
  summary>"` before `record close --profile dispatch`. Mirrors
  the tracking-profile closeout's Step 3.
- **Decision 7**: `review-dispatch-lane-pr` keeps its single
  `review` checkpoint; only the `--live` switch is added. The
  ledger-update wiring is owned by `execute-dispatch-lane`, not
  by the review skill — the review's writeback is review-decision
  metadata, not a task status flip.
- **Decision 8**: Render goldens for Codex / Claude / shared
  targets are regenerated in the same commit as the `.tera`
  edits ([F8]).
- **Decision 9**: Lift the retired
  `tracking-checkpoint-live-not-implemented` constant from
  these four SKILL Failure-modes blocks **only if** the
  `2026-05-28-checkpoint-live-constant-retirement` plan lands
  first or in the same cycle. If those two plans race, the
  later one absorbs the cleanup. This avoids a one-line conflict
  fight at render time.

## Scope

- **In**: Four dispatch-profile SKILL `.tera` bodies ([F1]):
  CLI floor bump, `--live` switch, ledger-update wiring (where
  appropriate), `ledger-rows-pending` failure-mode entry,
  closing-summary note step.
- **In**: Render-pass refresh for Codex / Claude / shared
  goldens.
- **In**: Validation across `scripts/ci/all.sh` 1-13 + render
  golden check + markdownlint + docs-placement audit.
- **In**: Optional smoke-probe parity: add deterministic
  smoke probes `dispatch.dispatch-closeout-gate-ledger-pending`
  and `…-ledger-clean` mirroring the tracking-profile probes
  already in
  `tests/runtime-smoke/cases/dispatch/run.sh` if and only if
  the dispatch profile path through `tracking close-ready`
  emits `ledger-rows-pending` distinctly (verify during
  implementation; the tracking-profile probe assumes profile is
  irrelevant to the blocker, but dispatch may carry an extra
  lane scope dimension worth probing).
- **Out**: Upstream `sympoies/nils-cli` changes. Controllers
  already expose every surface this plan consumes.
- **Out**: `dispatch-plan-closeout` strict-gate semantics. The
  gate's behavior is owned by the controller; this plan only
  documents the new failure-mode entry.
- **Out**: `create-dispatch-lane-pr` or `forge-cli` wiring. PR
  delivery is unchanged.
- **Out**: Dashboard rendering layout changes. The
  `--repair-dashboard` flag is unchanged.
- **Out**: `plan-archive-migrate` of past dispatch plan bundles.
  Past dispatch plans were closed under the old SKILL shape and
  are immutable historical artifacts.

## Implementation Boundaries

- The four SKILL bodies must remain symmetric in vocabulary with
  the tracking-profile bodies after the edit. Where tracking
  uses "task", dispatch uses "lane" — this is the established
  vocabulary boundary and must be preserved.
- No semantic change to the `tracking checkpoint --profile
  dispatch` controller. The `--live` switch is a posting-hop
  flag, not a profile semantic.
- Ledger-update calls in `execute-dispatch-lane` write the lane's
  task-id row; rollup ledger writes in `deliver-dispatch-plan`
  do not exist — the rollup checkpoint is a state/session
  rollup, not a task-row mutation.
- `dispatch-plan-closeout` does not call `plan-tooling
  ledger-update`. By the time closeout runs, every lane has
  already updated its row; closeout's job is to refuse to close
  if any row is still `pending`.
- Markdown line-length budget must stay within the existing
  rumdl MD013 contract (80 chars default; matching the
  surrounding `.tera` bodies which already conform).

## Requirements

- R1: Every dispatch-profile SKILL `.tera` ([F1]) names CLI
  floors `plan-issue >=0.25.7, plan-tooling >=0.25.7` (or
  `>=0.25.8` if the plan chooses that boundary).
- R2: Every dispatch-profile Entrypoint `tracking checkpoint`
  invocation includes `--live`.
- R3: `execute-dispatch-lane` Workflow includes a
  `plan-tooling ledger-update` step between local work and the
  lane checkpoint, with `--task-id`, `--status`, and
  `--evidence`.
- R4: `deliver-dispatch-plan` Workflow includes an analogous
  ledger-update step at the rollup boundary (per-lane, not
  per-rollup; this clarifies the deliver skill's role in
  finalizing the bundle's ledger before close-ready handoff).
- R5: `dispatch-plan-closeout` Failure modes include
  `ledger-rows-pending` as a propagated controller blocker.
- R6: `dispatch-plan-closeout` Workflow includes a Step (before
  `record close`) calling `tracking run update --note "<closing
  summary>"`.
- R7: Render-pass goldens for Codex / Claude / shared targets
  match the new `.tera` sources (no unstaged diff after
  `agent-runtime render --update-golden`).
- R8: `scripts/ci/all.sh` 1-13 passes after the parity edits.
- R9: If smoke probes are added (in-scope, optional), they
  follow the existing
  `tests/runtime-smoke/cases/dispatch/run.sh` shape and emit
  blocker codes the controller actually returns under
  `--profile dispatch`.

## Acceptance Criteria

- AC1: `grep -n "plan-issue >=0.22.3"
  core/skills/dispatch/{execute-dispatch-lane,review-dispatch-lane-pr,deliver-dispatch-plan,dispatch-plan-closeout}/SKILL.md.tera`
  returns zero hits (every floor bumped).
- AC2: `grep -n "tracking checkpoint" core/skills/dispatch/*/SKILL.md.tera`
  shows every dispatch-profile invocation carries `--live`.
- AC3: `grep -n "plan-tooling ledger-update"
  core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera
  core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  returns at least one hit per file.
- AC4: `grep -n "ledger-rows-pending"
  core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
  returns at least one hit.
- AC5: `grep -n "tracking run update --note"
  core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
  returns at least one hit.
- AC6: `agent-runtime render --update-golden` is a no-op after
  the `.tera` edits land (render is idempotent given the new
  source).
- AC7: `bash scripts/ci/all.sh` exits 0 across Positions 1-13.
- AC8: A dry-run end-to-end on a synthetic dispatch plan
  (or the next live dispatch plan, whichever ships first)
  shows the dispatch closeout body posts via `--live` and the
  ledger rows finalize before `record close`.

## Validation Plan

- Local: `bash scripts/ci/all.sh` after edits + render pass.
- Local: `agent-runtime render --check` for golden no-diff
  evidence.
- Local: `rumdl check --no-respect-gitignore
  core/skills/dispatch/` to confirm markdown lint stays clean.
- CI: runtime-kit standard `ci/all.sh` plus deterministic
  smoke probes (existing probes unchanged; new probes optional
  per R9).
- Live (optional, post-merge): the next dispatch plan run
  exercises the new shape end-to-end. Capture the ledger row
  states and the closeout body URL as live evidence.

## Risks And Guardrails

- **Risk**: `--live` posting hop fails under `--profile dispatch`
  in a way that did not surface under the tracking profile (e.g.
  dashboard repair semantics differ). **Guardrail**: keep
  `--repair-dashboard` on the dispatch deliver-rollup
  checkpoint ([F6]); add a runtime-smoke probe (R9) covering
  the dispatch close-ready gate.
- **Risk**: `plan-tooling ledger-update` semantics for "lane"
  rows differ from "task" rows (e.g. the plan-bundle ledger
  uses sprint/lane numbering, not task numbering).
  **Guardrail**: dispatch plan bundles already use the same
  `execution-state.md` ledger shape (`ID | Status | Task |
  Evidence | Notes`) — the schema is shared, only the
  vocabulary changes. Verify on the first real dispatch plan
  run after merge.
- **Risk**: Render goldens drift if `.tera` edits land without
  the matching golden refresh. **Guardrail**: AC6 + CI
  render-check.
- **Risk**: The retired
  `tracking-checkpoint-live-not-implemented` Failure-modes
  entries in three of the four dispatch SKILLs ([F1] minus
  closeout) collide with the retirement plan
  `2026-05-28-checkpoint-live-constant-retirement`.
  **Guardrail**: Decision 9 — whichever plan lands second
  absorbs the cleanup; both PRs touch the same lines, so the
  later one rebases cleanly with the entries already gone.
- **Risk**: Smoke probe addition turns into a larger smoke
  suite refactor. **Guardrail**: scope it to two probes
  copy-paste-shaped after the existing tracking-profile probes;
  if the copy needs nontrivial changes, defer probe addition
  to a follow-up plan and accept R8 + AC7 as sufficient
  coverage for the SKILL body edits.

## Retention Intent

- Plan-scoped source. Clean up after the parity plan lands
  (either archive with the plan bundle or migrate via
  `plan-archive-migrate` per the active retention policy). The
  underlying knowledge (the dispatch profile's lifecycle shape)
  is documented in the SKILL bodies themselves; this source
  document is decision capture for the implementation cycle.

## Read-First References

- `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  (tracking-profile precedent: per-task ledger-update wiring,
  `--live` posting, `>=0.25.7` floor).
- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  (tracking-profile precedent: `--live` posting + ledger-update
  ordering).
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
  (tracking-profile precedent: closing-summary note step,
  `ledger-rows-pending` failure mode).
- `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md`
  (Shared Family Rules and Failure-modes authoring guidance).
- `docs/plans/2026-05-28-plan-task-ledger-durability/`
  (ledger-durability rollout that established the tracking
  pattern; Task 4.4 explicitly scoped tracking-only).
- `docs/plans/2026-05-28-tracking-checkpoint-live/`
  (C rollout that established `--live` posting; deferred
  dispatch profile to Future Work).
- `tests/runtime-smoke/cases/dispatch/run.sh`
  (existing dispatch smoke probes; reference for optional R9
  parity probes).

## Recommended Next Artifact

- `docs/plans/2026-05-28-dispatch-profile-live-ledger-parity/2026-05-28-dispatch-profile-live-ledger-parity-plan.md`
  — task-by-task plan with one lane (runtime-kit-only) and one
  sprint covering the four SKILLs in parallel, plus an optional
  Sprint 2 for the parity smoke probes.
- `docs/plans/2026-05-28-dispatch-profile-live-ledger-parity/2026-05-28-dispatch-profile-live-ledger-parity-execution-state.md`
  — empty ledger seeded from the plan's task list.
