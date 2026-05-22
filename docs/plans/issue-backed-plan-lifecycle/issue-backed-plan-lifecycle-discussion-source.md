# Issue-Backed Plan Lifecycle Implementation Handoff

- Status: open, implementation planning requested
- Date: 2026-05-23
- Source: user direction in the current Codex thread, the legacy `agent-kit`
  tracking issue workflows, current `agent-runtime-kit` dispatch skill bodies,
  and current `nils-cli` plan tooling surfaces.
- Scope: unify the issue body and comment lifecycle for tracking-plan and
  dispatch-plan workflows while preserving current public skill names and the
  dispatch-only subagent execution capabilities.
- Intended next step: write and execute the implementation plan from this
  source document.

## Execution

- Recommended plan: docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md
- Recommended execution state: docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-execution-state.md

## Purpose

The current `agent-runtime-kit` dispatch skill series diverged from the
workflow the user wants. It moved `create-plan-tracking-issue` and related
skills toward the `plan-issue start-plan` / `Task Decomposition` issue body
runtime. The desired model is the older `agent-kit` issue-backed plan lifecycle:
the provider issue body is a compact mutable dashboard, while durable source,
plan, state, session, validation, review, and closeout records live in
append-only issue comments with stable HTML markers.

This source document defines the implementation target before code changes. The
implementation should use current skill names, align tracking and dispatch
outputs, and move deterministic rendering, audit, and gate logic into
`nils-cli` instead of relying on long-lived skill-local shell or Python helpers.

## Confirmed Facts

- [U1] Current public skill names should remain in use, including
  `create-plan-tracking-issue`, `execute-from-tracking-issue`,
  `tracking-issue-closeout`, `deliver-dispatch-plan`, `dispatch-subagent-pr`,
  `dispatch-pr-review`, and `dispatch-issue-closeout`.
- [U2] Dispatch plan workflows are conceptually tracking plan workflows plus
  subagent lane dispatch, task splitting, review confirmation, PR grouping, and
  close gates.
- [U3] Tracking and dispatch issue output should be aligned as much as possible:
  same body/dashboard style and same comment-marker lifecycle, with dispatch
  adding only the metadata it needs.
- [U4] `nils-cli` changes should be integrated with `agent-runtime-kit` while
  the CLI is still under development by using debug binaries from
  `/Users/terry/Project/sympoies/nils-cli/target/debug`, instead of waiting for
  a released version before integration.
- [F1] The legacy `agent-kit` `plan-tracking-issue` workflow creates a
  lightweight provider issue body that links the primary source, plan, inferred
  execution state, provider, and next action, and it posts source/plan
  snapshots as append-only comments.
- [F2] The legacy `agent-kit` `execute-from-tracking-issue` workflow treats
  issue-hosted source and plan snapshots plus
  `execute-from-tracking-issue:state:v1` comments as the durable execution
  record; local execution-state Markdown is only scratchpad or recovery input
  once issue-backed execution begins.
- [F3] The legacy `agent-kit` `tracking-issue-closeout` workflow gates closeout
  on source snapshot, plan snapshot, complete state, session evidence,
  validation evidence, explicit approval, and merged PR evidence, then repairs
  the final dashboard and posts a `tracking-issue-closeout:v1` comment.
- [F4] Current `agent-runtime-kit` `create-plan-tracking-issue` points at
  `plan-issue start-plan`, which renders a plan body with `## Task
  Decomposition`; this does not match the desired lightweight tracking issue
  body.
- [F5] Current `agent-runtime-kit` dispatch skills rely on `Task
  Decomposition` as runtime truth and use dispatch-specific
  `deliver-dispatch-plan:*` markers, creating a separate issue record family.
- [F6] Current `nils-cli` `plan-tooling` already parses, validates, batches,
  and splits plan tasks and PR groups; current `plan-issue-cli` owns
  `Task Decomposition` issue body parsing/rendering and sprint/plan gates.
- [F7] `forge-cli` already owns provider issue view/comment/edit/close atoms,
  so lifecycle-specific CLI work does not need to reimplement provider CRUD.

## Decisions

1. Keep current `agent-runtime-kit` skill names. Do not rename back to the old
   `agent-kit` `plan-tracking-issue` skill name.
2. Define one shared issue-backed plan record contract with two profiles:
   `tracking` and `dispatch`.
3. Treat tracking as the base profile and dispatch as a superset that adds
   subagent lane, sprint, PR grouping, review, and approval metadata.
4. Make the issue body a compact mutable dashboard for both profiles.
5. Make append-only comments the durable record for both profiles.
6. Keep `plan-tooling` focused on plan parsing, validation, dependency
   batching, and PR split modeling. Do not put GitHub/GitLab dashboard wording,
   comment rendering, marker audit, or closeout mutation in `plan-tooling`.
7. Add or modify `nils-cli` lifecycle commands so skills call deterministic
   CLI surfaces instead of skill-local long-lived shell/Python helpers.
8. Integrate `nils-cli` and `agent-runtime-kit` before release by preferring
   debug binaries in targeted validation commands.

## Scope

In scope:

- Define and implement shared issue body/dashboard and append-only comment
  templates for issue-backed plan lifecycle workflows.
- Rework `create-plan-tracking-issue`, `execute-from-tracking-issue`, and
  `tracking-issue-closeout` to match the tracking profile while keeping their
  current names.
- Rework `deliver-dispatch-plan`, `dispatch-subagent-pr`,
  `dispatch-pr-review`, and `dispatch-issue-closeout` to use the shared issue
  record contract while preserving dispatch-only subagent features.
- Add or refactor `nils-cli` commands for lifecycle rendering, marker audit,
  dashboard repair, state validation, dispatch ledger generation, and closeout
  readiness.
- Use `plan-tooling` only for plan/task metadata extraction and split modeling.
- Update `agent-runtime-kit` rendered skills, golden outputs, runtime smoke
  probes, acceptance matrix entries, and required CLI guidance.
- Validate cross-repo integration with local debug binaries before release.
- Run `code-review-specialists` before PR/delivery completion and fix concrete
  findings.

Out of scope:

- Renaming the public skill surfaces back to the old `agent-kit` names.
- Making dispatch mandatory for all tracking plans.
- Removing subagent dispatch, PR grouping, sprint approval, or review gates.
- Replacing `forge-cli` provider issue/PR atoms.
- Waiting for a `nils-cli` release before proving `agent-runtime-kit`
  integration.
- Mutating unrelated runtime homes, auth, history, sessions, caches, or
  secrets.

## Shared Issue Record Contract

The shared issue body should be a dashboard with the same high-level sections
for tracking and dispatch profiles:

- Current dashboard: status, profile, target scope, current task/lane, next
  action, latest validation, linked PRs, blockers, and approval state.
- Durable record: links to source snapshot, plan snapshot, latest state,
  latest session, latest validation, latest review/approval, and closeout when
  present.
- Profile metadata: `tracking` or `dispatch`, repository, plan path, source
  path, execution-state path, and CLI/debug-binary provenance when relevant.
- Guardrails: source of truth is the append-only issue comments; body is
  mutable dashboard only.

The shared comment marker family should be profile-aware but structurally
aligned. A practical target shape is:

- `<!-- issue-backed-plan:snapshot:v1 kind=source profile=tracking|dispatch -->`
- `<!-- issue-backed-plan:snapshot:v1 kind=plan profile=tracking|dispatch -->`
- `<!-- issue-backed-plan:state:v1 profile=tracking|dispatch -->`
- `<!-- issue-backed-plan:session:v1 profile=tracking|dispatch -->`
- `<!-- issue-backed-plan:validation:v1 profile=tracking|dispatch -->`
- `<!-- issue-backed-plan:review:v1 profile=dispatch -->`
- `<!-- issue-backed-plan:closeout:v1 profile=tracking|dispatch -->`

Backward compatibility with existing
`plan-tracking-issue:*`, `execute-from-tracking-issue:*`, and
`tracking-issue-closeout:*` markers should be deliberate. The first
implementation can either parse both marker families or provide a migration
mode, but new output should converge on one shared family unless the plan finds
a hard compatibility reason not to.

## Tracking Profile

The tracking profile covers single-agent issue-backed plan execution.

Requirements:

1. `create-plan-tracking-issue` creates or previews a lightweight dashboard
   body and source/plan snapshot comments.
2. `execute-from-tracking-issue` recovers source, plan, state, session,
   validation, PR links, and blockers from issue comments, not chat history.
3. The state ledger can stay close to the legacy
   `ID | Status | Task | Evidence | Notes` shape.
4. Completion gates require complete state, done/deferred task rows,
   validation evidence, PR evidence when PRs exist, and current dashboard
   links.
5. `tracking-issue-closeout` handles final dashboard repair, closeout comment,
   and close gate after explicit approval.

## Dispatch Profile

The dispatch profile covers the same issue-backed plan lifecycle with subagent
orchestration added.

Requirements:

1. `deliver-dispatch-plan` starts from the shared dashboard/comment contract.
2. Dispatch task decomposition remains required, but its durable location
   should be a state/dispatch ledger comment or linked artifact rather than the
   top-level issue body.
3. Dispatch state must include task id, summary, sprint, owner/subagent,
   branch, worktree, execution mode, PR group, PR, status, validation, review
   state, and notes.
4. `dispatch-subagent-pr` and `dispatch-pr-review` update the dispatch state
   through the lifecycle CLI, preserving lane continuity and review evidence.
5. `dispatch-issue-closeout` enforces dispatch-specific gates: every lane
   complete or deferred, required reviews complete, linked PRs merged or
   explicitly waived, final validation present, approval present, and dashboard
   current.
6. Dispatch comments should use the same visible section names as tracking
   comments where possible, adding dispatch-specific tables rather than
   inventing a separate issue-family vocabulary.

## CLI Boundary

Recommended `nils-cli` responsibilities:

- `plan-tooling`: keep plan validation, plan JSON extraction, dependency
  batches, split-prs, and PR grouping model.
- `plan-issue-cli` or a new nearby lifecycle command: render/audit shared issue
  body dashboards, render/audit snapshot/state/session/validation/review/
  closeout comments, convert plan metadata into tracking or dispatch ledgers,
  repair stale dashboards, and enforce closeout readiness.
- `forge-cli`: continue provider issue/PR view/comment/edit/close/create
  operations.

The implementation plan should inspect the current `plan-issue-cli` code before
choosing whether to extend it or add a new command namespace. The default
preference is to reuse `plan-issue-cli` if the command names can stay clear.
If existing `start-plan`/`status-plan` semantics are too tightly coupled to
`Task Decomposition`, add a new command group rather than overloading old
commands into ambiguous behavior.

## Integration Strategy

Do not wait for a `nils-cli` release before integrating.

1. Implement the CLI contract in `/Users/terry/Project/sympoies/nils-cli`.
2. Build debug binaries with `cargo build` or `cargo run` as appropriate.
3. Run `agent-runtime-kit` validation with
   `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH`.
4. Update `agent-runtime-kit` skills and runtime smoke to use the new CLI
   behavior while the debug binary is active.
5. Stabilize fixtures and golden outputs.
6. Only after the cross-repo contract passes, cut the `nils-cli` release or
   update required CLI floors.

## Requirements

1. Tracking and dispatch issue bodies share the same dashboard structure.
2. Tracking and dispatch comments share the same marker and section structure,
   with profile-specific extensions only where required.
3. New output no longer uses `Task Decomposition` as the top-level issue body
   runtime.
4. Dispatch task decomposition remains available as a durable dispatch ledger
   and supports subagent lane execution.
5. `plan-tooling` remains non-provider and non-UI: it supplies plan/task split
   data only.
6. CLI fixtures include at least one legacy tracking issue fixture based on
   issue #43 and one dispatch fixture.
7. `agent-runtime-kit` runtime smoke verifies the new tracking body, snapshot
   markers, state ledger, dispatch ledger, and closeout gates.
8. The implementation uses debug-binary integration before requiring a released
   `nils-cli`.
9. Specialist review runs before final PR/delivery closeout, and concrete
   findings are fixed or explicitly dispositioned.

## Acceptance Criteria

- `create-plan-tracking-issue` dry-run renders a lightweight dashboard body and
  source/plan snapshot comment artifacts, not a `Task Decomposition` issue
  body.
- `execute-from-tracking-issue` guidance and smoke tests recover issue state
  from shared snapshot/state/session/validation comments.
- `tracking-issue-closeout` guidance and smoke tests gate on shared comments
  and repair the dashboard.
- `deliver-dispatch-plan` guidance and smoke tests create a shared dashboard
  body plus dispatch ledger comments that include subagent lane data.
- `dispatch-subagent-pr`, `dispatch-pr-review`, and `dispatch-issue-closeout`
  update or validate dispatch ledger comments through the shared CLI contract.
- `plan-tooling validate`, `batches`, and `split-prs` still pass for the plan
  bundle.
- `nils-cli` tests for the new or modified CLI pass.
- `agent-runtime-kit` render, golden, drift, runtime smoke, and full CI pass
  with the `nils-cli` debug binary on `PATH`.
- `code-review-specialists` reports no unresolved concrete findings before
  closeout.

## Validation Plan

- In `nils-cli`:
  - `cargo test -p plan-tooling`
  - `cargo test -p plan-issue-cli`
  - targeted tests for the new lifecycle renderer/auditor fixtures
  - any workspace gate required by the changed crates
- In `agent-runtime-kit`:
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product codex`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime render --product claude`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH agent-runtime audit-drift`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash tests/runtime-smoke/run.sh --mode deterministic`
  - `PATH=/Users/terry/Project/sympoies/nils-cli/target/debug:$PATH bash scripts/ci/all.sh`
- Review:
  - `review-specialists scope --base <merge-base> --format json`
  - forced `testing` and `maintainability` review for the combined diff

## Risks And Guardrails

- Existing `plan-issue-cli` tests and users may depend on `Task
  Decomposition`. Preserve old commands or provide explicit migration behavior
  instead of silently changing semantics.
- Trying to make `plan-tooling` render GitHub issue comments would blur its
  current parser/splitter boundary and should be avoided.
- Dispatch must not lose subagent lane continuity while adopting the shared
  comment contract.
- Marker migration can accidentally misread quoted markers inside source
  snapshots. Parsers should require standalone marker lines.
- Issue body repair must remain idempotent and must not duplicate closeout or
  snapshot comments.
- Debug-binary integration must be scoped to commands that need unreleased
  behavior; do not permanently hard-code local debug paths in tracked docs
  except as development instructions.

## Open Questions

- Should the shared lifecycle CLI live under existing `plan-issue` commands,
  under a new `plan-issue record ...` subcommand group, or as a separate binary?
- Should new output keep old marker names for compatibility or emit the new
  shared `issue-backed-plan:*` marker family while parsing old names?
- How much of the old `agent-kit` Python helper behavior should be ported
  exactly, and how much should be normalized during the Rust CLI migration?
- Should dispatch closeout reuse `tracking-issue-closeout` with
  `profile=dispatch`, or remain a separate skill that calls the same lower-level
  CLI gates?

## Read First References

- `/Users/terry/.config/agent-kit/skills/workflows/plan/plan-tracking-issue/SKILL.md`
- `/Users/terry/.config/agent-kit/skills/workflows/plan/plan-tracking-issue/scripts/plan-tracking-issue.sh`
- `/Users/terry/.config/agent-kit/skills/workflows/issue/execute-from-tracking-issue/SKILL.md`
- `/Users/terry/.config/agent-kit/skills/workflows/issue/execute-from-tracking-issue/bin/tracking_issue_lifecycle.py`
- `/Users/terry/.config/agent-kit/skills/workflows/issue/tracking-issue-closeout/SKILL.md`
- `/Users/terry/.config/agent-kit/skills/workflows/issue/tracking-issue-closeout/bin/tracking_issue_closeout.py`
- `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/execute-from-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/tracking-issue-closeout/SKILL.md.tera`
- `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `core/skills/dispatch/dispatch-subagent-pr/SKILL.md.tera`
- `core/skills/dispatch/dispatch-pr-review/SKILL.md.tera`
- `core/skills/dispatch/dispatch-issue-closeout/SKILL.md.tera`
- `/Users/terry/Project/sympoies/nils-cli/crates/plan-tooling`
- `/Users/terry/Project/sympoies/nils-cli/crates/plan-issue-cli`
- `/Users/terry/Project/sympoies/nils-cli/crates/forge-cli`

## Recommended Next Artifact

Create
`docs/plans/issue-backed-plan-lifecycle/issue-backed-plan-lifecycle-plan.md`
from this source document. The plan should split work into source/contract
fixtures, `nils-cli` CLI implementation, `agent-runtime-kit` skill migration,
debug-binary integration, review, and final closeout.

## Retention Intent

This plan-source document is execution coordination. After implementation is
complete, promote the durable shared issue-backed lifecycle contract into a
maintained source document or CLI reference, then clean up temporary plan
coordination artifacts when no longer needed.
