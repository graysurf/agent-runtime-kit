# Plan Issue vNext Implementation Handoff

- Status: ready for implementation planning
- Date: 2026-05-26
- Source: user-directed redesign of the plan-tracking issue workflow,
  including comment templates, workflow state transitions, deterministic
  `nils-cli` control, and runtime-kit skill family rewrite.
- Intended next step: execute
  `docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md`
  directly, without using the existing plan issue skill family as the
  execution driver.

## Execution

- Recommended plan: docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md
- Recommended execution state: docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-execution-state.md

## Purpose

The plan issue workflow needs a clean vNext implementation. The current
behavior can create valid hidden payloads while visible issue comments drift in
format, timing, and usefulness. The redesign moves lifecycle mechanics into
`nils-cli`, keeps provider issue comments as durable truth, and rewrites
runtime-kit skills as concise orchestration contracts over the CLI.

This handoff ties the five design documents together into one implementation
source. It is intentionally execution-oriented: future work should follow the
plan bundle and the design documents, not the old plan issue skill bodies.

## Read-First Design Documents

| Document | Role |
| --- | --- |
| `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md` | Canonical lifecycle role inventory, visible templates, posting policies, and comment completeness rules. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md` | Workflow state model, lifecycle diagram, checkpoint timing rules, and progress-reporting rules. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md` | `nils-cli` vNext architecture, complete rewrite boundary, CLI workstreams, and runtime-kit consumption strategy. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md` | Deterministic FSM, typed `run-state.json`, event journal, runtime layout, reconciliation rules, and command behavior. |
| `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md` | Skill inventory, skill boundaries, allowed lifecycle roles, forbidden actions, and rewrite order. |

## Decisions

- Implement Option B: deterministic finite state machine plus typed local run
  state in `nils-cli`.
- Do not embed a LangGraph-style dynamic orchestration runtime in
  `nils-cli` core.
- Treat provider issue lifecycle comments as durable truth; local run state is
  a resumable secondary cache.
- Rewrite the plan issue workflow core inside the existing
  `crates/plan-issue-cli` crate instead of deleting the entire crate.
- Preserve `plan-issue` and `plan-issue-local` binary names, global flags,
  output envelope, exit-code conventions, provider abstraction, runtime
  layout, fixture assets, and released command compatibility until
  runtime-kit has migrated.
- Build a clean vNext core for lifecycle templates, visible completeness,
  run-state reconciliation, FSM decisions, checkpoint rendering, and close
  readiness.
- Implement and validate `nils-cli` first, then rewrite runtime-kit skills
  against a local binary, then consume the released CLI floor.
- In runtime-kit, delete or replace the existing plan issue skill source
  bodies during the rewrite. Do not incrementally patch the old prompt text.
- Use this plan bundle as the execution driver. Do not use
  `create-plan-tracking-issue`, `execute-plan-tracking-issue`,
  `deliver-plan-tracking-issue`, `plan-tracking-issue-closeout`,
  `deliver-dispatch-plan`, `execute-dispatch-lane`,
  `review-dispatch-lane-pr`, `dispatch-plan-closeout`, or
  `create-dispatch-lane-pr` to drive this implementation.

## Scope

- `sympoies/nils-cli`:
  - Add lifecycle vNext modules under `crates/plan-issue-cli/src/`.
  - Add a lifecycle role registry, visible completeness lint, template preview,
    tracking run-state controller, FSM reconciliation, checkpoint behavior, and
    close-readiness probe.
  - Migrate existing `record` rendering internals to the vNext registry after
    new surfaces have deterministic fixture coverage.
  - Preserve compatibility shell behavior until runtime-kit migrates.
- `graysurf/agent-runtime-kit`:
  - Rewrite the plan issue skill family from the redesign docs.
  - Audit or rewrite related references.
  - Render Codex and Claude targets.
  - Refresh golden outputs.
  - Update `docs/source/nils-cli-surface.md` and `required_clis` floors after
    the new `nils-cli` release is available.
  - Add or update runtime smoke coverage for visible comment bodies,
    checkpoint dry-runs, stale run-state refusal, and close-readiness gates.

## Non-Scope

- Bulk-rewriting historical issue comments.
- Making dashboards the durable state source.
- Parsing human prose as closeout truth.
- Routing plan record lifecycle writes through raw provider CLIs.
- Replacing `plan-tooling` plan validation.
- Replacing `forge-cli` for provider PR lifecycle work.
- Rewriting unrelated PR delivery skills that do not own plan issue lifecycle
  comments.

## Skill Inventory And Boundaries

| Skill | Target function | Boundary |
| --- | --- | --- |
| `create-plan-tracking-issue` | Create or preview one lightweight tracking issue from a validated plan bundle. | May open or attach source, plan, and initial state only; must not implement tasks or post progress. |
| `execute-plan-tracking-issue` | Resume one lightweight tracking issue and post useful progress checkpoints. | May checkpoint state, session, and validation; must not close the issue or rewrite source/plan snapshots. |
| `deliver-plan-tracking-issue` | Carry one lightweight tracking issue through implementation, validation, review, and close-readiness handoff. | May use checkpoint and close-ready probes; must not hand-write closeout or bypass closeout gates. |
| `plan-tracking-issue-closeout` | Close a lightweight tracking issue after audit, validation, approval, PR evidence, and visible completeness pass. | May repair dashboard and call `record close`; must not implement tasks or post progress checkpoints. |
| `deliver-dispatch-plan` | Create or resume one shared dispatch plan issue and coordinate lanes. | Must keep main-agent orchestration separate from lane implementation and final closeout. |
| `execute-dispatch-lane` | Execute one assigned dispatch lane and report lane progress. | Must not reassign scope, mutate unrelated lanes, or close the dispatch issue. |
| `review-dispatch-lane-pr` | Review one dispatch lane PR or MR and report review status. | Must not implement fixes unless redirected and must not skip retained review evidence when findings exist. |
| `dispatch-plan-closeout` | Close a shared dispatch plan after lane, review, validation, approval, and integration evidence pass. | Must not implement lane work or use lightweight tracking closeout rules. |
| `create-dispatch-lane-pr` | Create a provider PR or MR for one assigned dispatch lane. | Must not write plan issue lifecycle comments directly. |

## Implementation Guardrails

- Every lifecycle comment role must have a deterministic template.
- Every role template must be generated from typed data and tested.
- Hidden payload audit remains required but is not sufficient; visible comment
  completeness is also required.
- `source` and `plan` are open/attach-only snapshots.
- `state` is generated from the canonical execution-state Markdown and must
  include a visible `## Task Ledger`.
- `session`, `validation`, and `review` comments must only be posted when they
  expose meaningful issue-visible evidence.
- `closeout` is owned by `record close`; skills must not hand-post final
  closeout comments.
- `tracking checkpoint` must reconcile provider issue evidence before live
  mutation and refuse stale local run state.
- `tracking close-ready` must be non-mutating and return precise blocked
  reasons.
- Runtime-kit final validation must pass against a released `nils-cli` version,
  not only an unreleased local binary.

## Cross-Repo Location Convention

This plan is stored and validated in `agent-runtime-kit`. `plan-tooling`
validates `Location` entries relative to this repository. For `sympoies/nils-cli`
implementation tasks, `Location` points at this bundle and the source design
docs, while task descriptions name the actual nils-cli repo-relative target
paths. During execution, record exact nils-cli paths, commits, and validation
evidence in the execution-state ledger.

## Acceptance Criteria

- `nils-cli` exposes the vNext lifecycle registry, visible lint, template
  preview, tracking status, run init/update, checkpoint, and close-ready
  surfaces with deterministic fixture coverage.
- `nils-cli` preserves the existing public binary shell and compatibility
  command behavior until runtime-kit migrates.
- Runtime-kit plan issue skill source bodies are rewritten from the redesign
  docs, not patched from the old bodies.
- Rendered Codex and Claude targets and golden outputs match the rewritten
  sources.
- Runtime smoke proves visible lifecycle comment shape, hidden payload audit,
  stale run-state refusal, checkpoint dry-run, live checkpoint behavior in
  provider-safe mode, and close-readiness blocking.
- Final runtime-kit docs and manifest floors refer to a released `nils-cli`
  version that contains the required surfaces.

## Validation Plan

- `plan-tooling validate --file docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md --format text --explain`
- In `sympoies/nils-cli`: focused `nils-plan-issue-cli` tests for lifecycle
  registry, visible lint, run-state schema, FSM reconciliation, checkpoint
  rendering, close-ready gates, and compatibility behavior.
- In `sympoies/nils-cli`: the repository check command required by its
  `DEVELOPMENT.md`.
- In `agent-runtime-kit`: `agent-runtime render --product codex`
- In `agent-runtime-kit`: `agent-runtime render --product claude`
- In `agent-runtime-kit`: rendered golden refresh checks after source rewrite.
- In `agent-runtime-kit`: focused dispatch and PR runtime smoke.
- In `agent-runtime-kit`: full project validation required by `DEVELOPMENT.md`
  before final delivery.

## Retention Intent

This bundle is coordination material for the vNext implementation. Keep it
through delivery. After delivery, promote only stable behavior into canonical
docs such as `docs/source/nils-cli-surface.md`, runtime-kit skill bodies, and
maintained nils-cli documentation.
