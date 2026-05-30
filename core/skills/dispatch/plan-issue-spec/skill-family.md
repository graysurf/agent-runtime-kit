# Plan Issue Skill Family Spec

## Status

- Status: implemented; canonical plan-issue skill family spec (the
  Shared Family Rules referenced by the shipped dispatch / pr skills)
- Date: 2026-05-26
- Depends on:
  - `core/skills/dispatch/plan-issue-spec/comment-taxonomy.md`
  - `core/skills/dispatch/plan-issue-spec/workflow.md`
  - `core/skills/dispatch/plan-issue-spec/run-state-controller.md`
  - `core/skills/dispatch/plan-issue-spec/cli.md`
- Owning implementation repos:
  - `sympoies/nils-cli`
  - `graysurf/agent-runtime-kit`

## Purpose

This document defines the plan issue skill family after the redesign. It lists
the skill surfaces that currently participate in plan-backed issues, assigns a
target role to each skill, and sets the rewrite boundary for the next
implementation.

The goal is to prevent old prompt wording from leaking into the new workflow.
`nils-cli` must own lifecycle mechanics, templates, run-state reconciliation,
checkpoint rendering, dashboard repair, and closeout gates. Runtime-kit skills
must become concise orchestration contracts that select scope, interpret work,
and call the CLI surfaces.

## Rewrite Rule

The implementation phase uses two different rewrite boundaries:

- `nils-cli`: complete rewrite of the plan issue workflow core inside the
  existing `crates/plan-issue-cli` crate.
- runtime-kit: delete or replace the current plan issue skill bodies and
  rewrite them from these redesign documents.

For `nils-cli`, "complete rewrite" does not mean deleting the crate or changing
the public binary contract. It means preserving the compatibility shell while
building a clean vNext core for templates, visible lint, run state, FSM
reconciliation, checkpoints, and close readiness.

Preserve on the `nils-cli` side:

- `plan-issue` and `plan-issue-local` binary names.
- Global flags, output envelope, and exit-code model.
- Provider abstraction and GitHub/GitLab routing.
- Runtime layout and state-dir resolution.
- Existing fixture tests as compatibility regression coverage.
- Released `record` command compatibility until runtime-kit migrates.

Rewrite on the `nils-cli` side:

- Lifecycle template registry.
- Visible completeness lint.
- `record template` preview.
- Tracking run-state controller.
- Checkpoint and close-ready behavior.
- `record` rendering internals after the vNext core is covered.

The runtime-kit skill implementation phase should not incrementally patch the
current plan issue skill bodies.

Required approach:

1. Implement and test the `nils-cli` vNext core first.
2. Keep the old CLI shell and released command compatibility while the new
   core is built.
3. Build a local `nils-cli` binary from that branch.
4. Validate the local binary against the comment taxonomy, workflow, and
   run-state controller documents.
5. In runtime-kit, remove the current plan issue skill source bodies and
   rewrite them from these redesign documents.
6. Render Codex and Claude targets from the rewritten sources.
7. Refresh goldens from the rendered targets.
8. Run focused runtime-kit smoke against the local binary.
9. After `nils-cli` is released, update runtime-kit CLI floors and rerun final
   validation against the released binary.

Do not globally replace the user's installed CLI while developing skills. Use a
scoped `PATH` or explicit local binary path in validation commands.

## Current Skill Inventory

The plan issue family currently spans the `dispatch` and `pr` skill domains.

| Current skill | Source path | Target family |
| --- | --- | --- |
| `create-plan-tracking-issue` | `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera` | Lightweight tracking issue |
| `execute-plan-tracking-issue` | `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera` | Lightweight tracking issue |
| `deliver-plan-tracking-issue` | `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera` | Lightweight tracking issue |
| `plan-tracking-issue-closeout` | `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera` | Lightweight tracking issue |
| `deliver-dispatch-plan` | `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera` | Dispatch plan issue |
| `execute-dispatch-lane` | `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera` | Dispatch lane |
| `review-dispatch-lane-pr` | `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera` | Dispatch lane review |
| `dispatch-plan-closeout` | `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera` | Dispatch plan closeout |
| `create-dispatch-lane-pr` | `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera` | Dispatch lane PR helper |

Rendered Codex and Claude target files and golden files are generated outputs.
They must be refreshed after source skill rewrites, not hand-edited as the
source of truth.

## Shared Family Rules

Every rewritten skill in this family follows these rules:

- Do not hand-compose lifecycle comments.
- Do not post lifecycle comments through raw provider CLIs.
- Do not call generic issue comment commands for plan-record state.
- Do not make Profile-only comments acceptable.
- Do not infer closeout readiness from prose alone.
- Do not treat local run state as durable truth over provider issue evidence.
- Do not mutate source/plan/state lifecycle roles outside the allowed skill
  boundary.
- Use `plan-tooling` for plan bundle validation.
- Use `plan-issue record` for lifecycle record primitives.
- Use `plan-issue tracking` for run-state controller, status, checkpoint, and
  close-readiness behavior.
- Use `forge-cli` for PR and provider lifecycle outside the plan issue record.

## Lightweight Tracking Issue Skills

Lightweight tracking issue skills operate on one issue-backed plan record
without dispatch lanes. They should use `--profile tracking`.

### `create-plan-tracking-issue`

Function:

- Create or preview one lightweight issue-backed plan tracker from a validated
  local plan bundle.
- Open the provider issue with source, plan, and initial state lifecycle
  evidence.
- Optionally initialize a run state after issue creation when the CLI controller
  supports it.

Allowed lifecycle writes:

- `record open --profile tracking`
- Future controller-assisted run initialization after open.

Boundaries:

- Must not implement plan tasks.
- Must not post progress, validation, review, or closeout comments.
- Must not create a PR.
- Must not repair or close an unrelated existing issue.
- Must not accept missing source, plan, or execution-state files as normal.

Primary CLI surface after redesign:

```bash
plan-tooling validate ...
plan-issue record open --profile tracking ...
plan-issue tracking run init ...
```

### `execute-plan-tracking-issue`

Function:

- Resume a lightweight tracking issue for a selected task or sprint.
- Reconcile live issue evidence with local run state before implementation.
- Update local run state while work proceeds.
- Post useful progress checkpoints when there is issue-visible information to
  report.

Allowed lifecycle writes:

- `tracking checkpoint --post state`
- `tracking checkpoint --post state,session`
- `tracking checkpoint --post state,session,validation`
- Dashboard repair only through controller or record primitives.

Boundaries:

- Must not open the tracking issue.
- Must not call `record close`.
- Must not decide final closeout readiness.
- Must not rewrite source or plan snapshots.
- Must not post comments for every local edit.
- Must not continue when provider issue evidence is newer than run state until
  reconciliation succeeds.

Progress posting rule:

- Post when a human scanning the issue learns a new durable fact: task started,
  task completed, validation result changed, blocker discovered, PR opened, or
  sprint status changed.
- Do not post for purely local edits, speculative notes, or unchanged
  validation reruns.

Primary CLI surface after redesign:

```bash
plan-issue tracking status ...
plan-issue tracking run update ...
plan-issue tracking checkpoint ...
```

### `deliver-plan-tracking-issue`

Function:

- Carry one lightweight tracking issue scope through implementation,
  validation, review, PR delivery, final state, and close-readiness checks.
- Use the run-state controller for progress and final checkpoint decisions.
- Prepare the issue for closeout without bypassing the closeout skill.

Allowed lifecycle writes:

- Same checkpoint writes as `execute-plan-tracking-issue`.
- Final state checkpoint.
- Review and validation checkpoints through `tracking checkpoint`.
- Close-readiness audit through `tracking close-ready`.

Boundaries:

- Must not create the original tracking issue.
- Must not use dispatch lane semantics.
- Must not hand-write closeout comments.
- Must not close the provider issue directly.
- Must not merge PRs unless the active PR delivery workflow authorizes that
  step.
- Must stop when close-readiness reports blocked.

Primary CLI surface after redesign:

```bash
plan-issue tracking status ...
plan-issue tracking checkpoint ...
plan-issue tracking close-ready ...
forge-cli pr ...
```

### `plan-tracking-issue-closeout`

Function:

- Close a lightweight plan-tracking issue after lifecycle audit, validation,
  approval, linked PR evidence, and visible completeness gates pass.
- Repair the dashboard when closeout is not yet allowed and repair-only mode is
  requested.

Allowed lifecycle writes:

- `record repair-dashboard`
- `record close --profile tracking`

Boundaries:

- Must not implement tasks.
- Must not create or update PRs.
- Must not post progress checkpoints.
- Must not close if `tracking close-ready` or `record close` gates fail.
- Must not treat missing approval or missing PR evidence as implicit approval.

Primary CLI surface after redesign:

```bash
plan-issue tracking close-ready ...
plan-issue record close --profile tracking ...
```

## Dispatch Plan Issue Skills

Dispatch plan issue skills operate on one shared plan issue plus implementation
lanes. They should use `--profile dispatch` and must keep main-agent ownership
separate from lane ownership.

### `deliver-dispatch-plan`

Function:

- Create or resume one dispatch-ready plan issue.
- Assign plan tasks into lanes.
- Coordinate lane PRs, reviews, validation, integration evidence, and final
  closeout readiness.
- Keep the main issue synchronized as the durable orchestration record.

Allowed lifecycle writes:

- Dispatch-profile open or attach through `record open` or `record attach`.
- Dispatch state, session, validation, and review checkpoints through the
  dispatch-compatible record or tracking surfaces once implemented.
- Final closeout only through the dispatch closeout path.

Boundaries:

- Must not act as a lane implementer unless explicitly re-entering through
  `execute-dispatch-lane`.
- Must not let subagents own final integration, review judgment, or issue
  closeout.
- Must not use lightweight tracking closeout rules for dispatch issues.
- Must not create multiple shared plan issues for one dispatch plan unless the
  user explicitly splits scope.

Primary CLI surface after redesign:

```bash
plan-tooling validate ...
plan-issue record open --profile dispatch ...
plan-issue tracking status ...
plan-issue tracking checkpoint ...
```

### `execute-dispatch-lane`

Function:

- Execute one assigned dispatch lane.
- Keep lane facts scoped to the assigned task, branch, worktree, base branch,
  and PR.
- Report lane progress back to the shared dispatch issue record.

Allowed lifecycle writes:

- Lane state/session/validation updates for the assigned lane only.
- PR creation or update through `forge-cli` or the lane PR helper.

Boundaries:

- Must not reassign lane scope.
- Must not mutate unrelated lanes.
- Must not close the dispatch issue.
- Must not perform plan-level review or final integration decisions.
- Must not target the repository default branch when a dispatch `PLAN_BRANCH`
  is assigned.

Primary CLI surface after redesign:

```bash
plan-issue tracking status ...
plan-issue tracking run update ...
plan-issue tracking checkpoint ...
forge-cli pr ...
```

### `review-dispatch-lane-pr`

Function:

- Review one dispatch lane PR or MR.
- Record review evidence.
- Post provider review comments or follow-up requests through the approved PR
  workflow.
- Update the shared dispatch issue with review status.

Allowed lifecycle writes:

- Review evidence checkpoint for the reviewed lane.
- Dispatch issue state/session update when review outcome changes lane state.

Boundaries:

- Must not implement fixes unless the user explicitly changes the task from
  review to implementation.
- Must not close the dispatch issue.
- Must not merge without review policy and PR workflow approval.
- Must not skip retained review evidence when findings exist.

Primary CLI surface after redesign:

```bash
review-evidence ...
plan-issue tracking checkpoint ...
forge-cli pr review ...
```

### `dispatch-plan-closeout`

Function:

- Close a shared dispatch plan issue after all lanes, reviews, validation,
  approvals, integration PR evidence, and dashboard gates pass.

Allowed lifecycle writes:

- Dispatch dashboard repair.
- Dispatch-profile `record close`.

Boundaries:

- Must not implement lane work.
- Must not create or update lane PRs.
- Must not use lightweight tracking closeout rules.
- Must not close when lane evidence, review evidence, integration evidence, or
  final approval is missing.

Primary CLI surface after redesign:

```bash
plan-issue tracking close-ready ...
plan-issue record close --profile dispatch ...
```

## Dispatch Lane PR Helper

### `create-dispatch-lane-pr`

Function:

- Create a provider PR or MR for one dispatch lane after the lane has an
  assigned branch, base plan branch, task scope, body, and validation evidence.

Allowed lifecycle writes:

- None directly to the plan issue record.
- May return PR evidence for a lane checkpoint posted by a dispatch skill.

Boundaries:

- Must not implement lane work.
- Must not post plan issue lifecycle comments directly.
- Must not choose task scope.
- Must not target the wrong base branch.
- Must not bypass `forge-cli pr create`.

Primary CLI surface after redesign:

```bash
forge-cli pr create ...
plan-issue tracking run update ...
```

## Related But Out Of Scope

General PR/MR delivery skills such as `create-pr`, `deliver-pr`, and
`close-pr` are not plan issue skills. They may be called by a plan
issue skill for PR/MR lifecycle work, but they do not own plan issue lifecycle
comments, dashboards, run state, or closeout gates.

Evidence skills such as `review-evidence`, `test-first-evidence`, and
`web-evidence` produce retained evidence. They do not post plan issue lifecycle
comments by themselves.

## Skill Contract Content

Every rewritten skill in this family follows the repo-wide `/create-skill`
section structure: `## Contract`, `## Entrypoint`, `## Workflow`, `## Boundary`.
The family layers additional content requirements *inside* those sections so
the nine skills stay readable as a coherent series.

Required content slotting per skill:

- `## Contract` → Prereqs / Inputs / Outputs / Failure modes (four labelled
  sublists).
  - Prereqs lead with the issue `Profile: tracking | dispatch` (one value
    only) and list the CLI floors (`plan-issue >=X.Y.Z`, `plan-tooling`,
    `forge-cli`, optional evidence binaries). Add issue / run-state
    preconditions and a one-line cross-ref to the
    [Shared Family Rules](#shared-family-rules).
  - Inputs name the required environment values (`OWNER_REPO`, `ISSUE`,
    `RUN_STATE`, …) plus skill-specific scope (task / lane / payload
    paths).
  - Outputs name the **allowed lifecycle role posts** explicitly with the
    `--profile` flag they invoke, the run-state mutations the skill is
    permitted to make, and the provider artifacts it returns. Lifecycle
    roles outside this list are forbidden.
  - Failure modes name the **forbidden lifecycle roles** that abort the
    skill with `forbidden-role-for-skill`, the controller-surfaced refusal
    codes the skill must propagate (`run-state-stale`,
    `RECORD_BLOCKED`, `visible-completeness-failed`,
    role-specific codes from
    [`comment-taxonomy.md`](comment-taxonomy.md)),
    and the scope-leak refusals.
- `## Entrypoint` → the three to six bash invocations the skill actually
  makes. Each envelope-consuming call ends with `--format json`.
- `## Workflow` → an ordered list of steps. The list must include a
  preflight step (`plan-tooling validate` and/or
  `tracking status --expect-visible`), the lifecycle checkpoint(s) the
  skill owns, and a read-back step
  (`tracking status --expect-visible` or `record audit --expect-visible`)
  before the skill claims success.
- `## Boundary` → `Owns` and `Does not own` sublists that name sibling
  skills explicitly when delegating, plus a `Cross-references` line that
  links upstream / downstream skills and the Shared Family Rules.

Every skill must explicitly surface:

- the issue profile (`tracking` or `dispatch`).
- the lifecycle roles it may write (in Outputs).
- the lifecycle roles it must not write (in Failure modes and Boundary).
- the required `plan-issue tracking` commands (in Entrypoint).
- the required `forge-cli` commands when PR work is in scope (in Entrypoint).
- the provider mutation points and read-back evidence (in Workflow).

## Implementation Order

The implementation order is intentionally CLI-first:

1. Create the vNext core boundary inside `crates/plan-issue-cli` without
   deleting the crate, binaries, provider abstraction, runtime layout, or
   released command compatibility.
2. Implement `nils-cli` template registry and visible completeness lint in the
   vNext core.
3. Implement `record template` preview.
4. Implement run-state schema, runtime layout, and event journal.
5. Implement `tracking run init`, `tracking run update`, and
   `tracking status`.
6. Implement `tracking checkpoint --dry-run`.
7. Validate rendered checkpoint bodies against this document and the taxonomy.
8. Implement live `tracking checkpoint`.
9. Implement `tracking close-ready`.
10. Migrate `record` rendering internals to the vNext registry/controller.
11. Run `nils-cli` fixture tests and local provider-safe smoke.
12. Build a local `nils-cli` binary.
13. Rewrite runtime-kit skill sources from these documents.
14. Render Codex and Claude targets.
15. Refresh golden outputs.
16. Run runtime-kit smoke with the local binary.
17. Release `nils-cli`.
18. Update runtime-kit required CLI floors and docs.
19. Run final runtime-kit validation against the released binary.

## Deletion And Rewrite Scope

When the runtime-kit rewrite starts, the implementation should treat these as
replaceable source surfaces:

- `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
- `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
- `core/skills/dispatch/dispatch-plan-closeout/SKILL.md.tera`
- `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera`

Existing reference files may be deleted, rewritten, or retained only when the
new source skill explicitly depends on them. Retained reference files must be
audited for old lifecycle command names, direct comment assembly, obsolete CLI
floors, and stale provider assumptions.

Generated targets and goldens to refresh after source rewrite:

- `targets/codex/...`
- `targets/claude/...`
- `tests/golden/codex/...`
- `tests/golden/claude/...`

Do not manually edit generated target or golden files as the primary
implementation.

## Acceptance

The skill family redesign is ready for implementation when:

- Every plan issue skill is assigned to exactly one target role.
- Every skill has explicit lifecycle write permissions.
- Every skill has explicit forbidden actions.
- The implementation order is CLI-first and local-binary verified.
- No rewritten skill requires hand-authored lifecycle comment templates.
- No rewritten skill depends on hidden payloads without visible evidence.
- Runtime-kit final validation can use a released `nils-cli` floor.
