# plan-issue V3 Surface Alignment Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-24
- Source: user request to record the drift in the heuristic system, align all
  affected `agent-runtime-kit` skills, and remove retired transitional helper
  support from `nils-cli`.
- Intended next step: use this document as the source artifact for an
  issue-backed plan delivered through `deliver-plan-tracking-issue`.

## Execution

- Recommended plan: docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md
- Recommended execution state: docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-execution-state.md

## Purpose

`plan-issue 0.20.0` has moved the issue-backed plan record workflow to the v3
surface: `record open`, `record post`, `record repair-dashboard`,
`record close`, and `record audit`. The older helper commands still exist but
are explicitly labeled retired transitional helpers. Keeping runtime-kit skills
and smoke tests on those helpers creates a maintenance trap: future agents keep
learning the compatibility path instead of the supported contract.

This work aligns the runtime-kit source, rendered skills, docs, tests, and
manifest pins with the v3 surface, and then removes the retired helper support
from `nils-cli` so the old path cannot silently survive.

## Confirmed Facts

- [U1] The user requested that this drift be tracked in the heuristic system,
  that all affected runtime-kit skills be corrected and tracked, and that
  `nils-cli` remove the retired transitional helper support and docs.
- [A1] `plan-issue --version` reports `nils-plan-issue-cli 0.20.0`.
- [A2] `plan-issue record --help` lists `open`, `post`,
  `repair-dashboard`, `close`, and `audit` as the primary record commands.
- [A3] `plan-issue record render-dashboard --help`,
  `render-comment --help`, `closeout-gate --help`, and
  `build-dispatch-ledger --help` state that those commands are retired
  transitional helpers.
- [F1] `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
  still documents `render-dashboard` / `render-comment` plus manual
  `forge-cli issue create/comment/edit` as the normal issue creation flow.
- [F2] `docs/source/nils-cli-surface.md` still describes the `plan-issue`
  surface in v0.17.7 / v0.18.0 terms and does not document the v3 primary
  surface.
- [F3] `tests/runtime-smoke/acceptance-matrix.yaml` and
  `tests/runtime-smoke/cases/{dispatch,pr}/run.sh` still exercise retired
  helper commands as acceptance paths.
- [F4] `core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift/ENTRY.md`
  now tracks the drift and the affected runtime-kit source skills.

## Decisions

- [D1] New and maintained runtime-kit workflow text must use only the v3
  primary surface.
- [D2] `record open` owns initial source, plan, dashboard, and execution-state
  creation for plan bundles.
- [D3] `record post` owns append-only lifecycle comments after issue creation:
  state, session, validation, review, and closeout.
- [D4] `record repair-dashboard` owns dashboard recomputation after comments or
  lifecycle evidence change.
- [D5] `record close` owns strict close readiness and provider issue closure.
- [D6] Runtime-kit docs and tests should not preserve retired helper examples
  outside historical retained records under `docs/plans/**` or archived
  heuristic entries.
- [D7] `nils-cli` should remove the retired helper subcommands and their
  compatibility tests/docs instead of continuing to carry them.

## Scope

- Update all active runtime-kit source skills that still document or invoke
  retired helper commands.
- Regenerate rendered Codex and Claude skill outputs and golden snapshots.
- Update runtime-smoke matrix/cases so acceptance proves the v3 surface.
- Update `docs/source/nils-cli-surface.md` and manifest `required_clis` floors
  so the documented minimum matches the v3 contract.
- Keep the heuristic inbox entry linked and update it as the durable tracking
  record for this drift.
- In `/Users/terry/Project/sympoies/nils-cli`, remove the retired
  `plan-issue record` helper subcommands, docs, and tests.

## Non-Scope

- Rewriting historical plan bundles or archived heuristic entries.
- Changing the semantic shape of `plan-issue-record:v2` markers unless
  `nils-cli` already requires it for v3.
- Reintroducing compatibility aliases or wrapper commands for the removed
  helpers.
- Changing `forge-cli` label management unless live `forge-cli` evidence shows
  a real label subcommand exists and is needed.

## Affected Runtime-Kit Skills

The active source skills that need direct review and, where applicable, edits:

- `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
- `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/pr/deliver-github-pr/SKILL.md.tera`
- `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`

The broader verification pass must also scan rendered skills, golden outputs,
runtime-smoke scripts, acceptance matrix text, reference docs, and manifests.

## Requirements

- Runtime-kit skill bodies must stop presenting `render-dashboard`,
  `render-comment`, `closeout-gate`, or `build-dispatch-ledger` as supported
  current workflows.
- Any workflow that creates a tracker from a source/plan bundle must use
  `plan-issue record open`.
- Any workflow that appends lifecycle comments must use `plan-issue record
  post --kind <state|session|validation|review|closeout>`.
- Any workflow that repairs dashboard links must use `plan-issue record
  repair-dashboard`.
- Any workflow that closes an issue-backed plan record must use
  `plan-issue record close`.
- Runtime-smoke should fail if active runtime-kit source or rendered skills
  reintroduce retired helper names as current commands.
- `nils-cli` should reject removed helper commands rather than logging a
  deprecation warning.
- Historical retained records may still mention old commands as historical
  evidence, but active docs and examples must not.

## Acceptance Criteria

- All active runtime-kit source skills listed above are aligned to v3 or have a
  documented no-change reason.
- Rendered Codex and Claude skills match the source changes.
- Golden snapshots and runtime-smoke cases are updated.
- `docs/source/nils-cli-surface.md` describes the v3 primary surface and the
  removed helper policy.
- `manifests/skills.yaml` pins affected `plan-issue` consumers to a version
  that provides the v3 surface and, after release, no retired helpers.
- `nils-cli` no longer exposes `plan-issue record render-dashboard`,
  `render-comment`, `closeout-gate`, or `build-dispatch-ledger`.
- The heuristic inbox entry remains strict-valid and links the delivery plan or
  final evidence when promoted.

## Validation Plan

- `heuristic-inbox verify core/policies/heuristic-system/error-inbox/plan-issue-v3-surface-drift --strict --format json`
- `plan-tooling validate --file docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md --format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `agent-runtime audit-drift`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
- `bash scripts/ci/all.sh`
- In `nils-cli`: focused `plan-issue` crate tests, repo checks required by its
  `DEVELOPMENT.md`, and live `plan-issue record --help` confirmation that the
  retired helpers are gone.

## Risks And Guardrails

- The current `deliver-plan-tracking-issue` skill body itself still documents
  retired helpers. During this delivery, use the live v3 CLI surface as the
  operational source of truth and update the skill as part of the scope.
- Removing `nils-cli` helper commands can break downstream skills that were
  not scanned. Search all active runtime-kit source, rendered outputs, tests,
  and source docs before considering the removal complete.
- Do not rewrite retained historical docs under `docs/plans/**` unless they
  are current plan bundle files for this work.
- Do not make `forge-cli` label changes based on stale notes. Live
  `forge-cli 0.20.0` does not expose a top-level `label` subcommand.

## Retention Intent

This source document is coordination material. Keep it through delivery and
closeout, then either leave it as retained plan evidence or promote only the
stable v3 surface policy into `docs/source/nils-cli-surface.md` and the
affected skill bodies.

## Open Questions

- [Q1] Should the `nils-cli` removal land before the runtime-kit PR, or should
  runtime-kit align first and pin to the already-installed v3 surface until the
  removal release exists?
- [Q2] Does `record close` already post a closeout comment and repair the
  dashboard, or must runtime-kit still call `record post --kind closeout` and
  `record repair-dashboard` before `record close`?
- [Q3] What released `nils-cli` version should runtime-kit require after the
  retired helpers are removed?

## Recommended Next Artifact

Use
`docs/plans/plan-issue-v3-surface-alignment/plan-issue-v3-surface-alignment-plan.md`
as the execution plan and open a tracking issue with `plan-issue record open`
after the bundle is committed and pushed.
