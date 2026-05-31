---
name: deliver-dispatch-plan
description:
  Open or resume one shared dispatch plan issue, dispatch task lanes, coordinate lane PRs and reviews, and hand off to dispatch closeout.
---

# Deliver Dispatch Plan

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=0.25.10`, `plan-tooling >=0.25.10`, `forge-cli`.
- Issue precondition: the dispatch issue does not exist yet, or exists
  and is being resumed by the same orchestrator.
- Run state precondition: `run-state.json` for the dispatch issue is
  either uninitialized (skill bootstraps it) or reconciled.
- Shared family rules from the Plan Issue Skill Family
  spec apply (see the Shared Family Rules section in
  core/skills/dispatch/plan-issue-spec/).

Inputs:

- `OWNER_REPO`, `PLAN_BUNDLE`, `PLAN`, optional `ISSUE` when resuming.
- `RUN_STATE` path for the dispatch run state.
- Lane assignments (task / sprint / PR-group) — derived from the plan
  or passed explicitly. Each lane carries a mandatory dispatch bundle
  (`TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`,
  selected `workflow_role`, `PLAN_BRANCH`, exact plan task context).
- Dispatch labels from the shared taxonomy:
  `type::chore`, primary `area::*`, `state::needs-triage`,
  `workflow::plan`, `workflow::dispatch`, plus the rollout `plan`
  label. **GitLab scoped-label exclusivity:** GitLab keeps only one
  label per `key::` scope, so `workflow::plan` + `workflow::dispatch`
  silently collapses to the last one. On GitLab apply only
  `workflow::dispatch` and rely on the bare `plan` rollout marker;
  GitHub keeps both `workflow::*` labels (graysurf/plan-tracking-testbed#58).
- Sprint / lane approval comment URLs, review evidence paths, and
  final integration PR ref.

Outputs:

- `record open --profile dispatch` (or `record attach --profile
  dispatch`) posts `source`, `plan`, and initial `state` snapshots and
  opens the shared dispatch issue.
- `tracking run init --profile dispatch --execution-state-file
  <bundle>/<slug>-execution-state.md` writes the dispatch run state.
  Always pass `--execution-state-file`: it is what lets every later
  `tracking checkpoint --post state` render the **accumulative** per-task
  ledger. Omit it (init with `--bundle` alone) and the run state has no
  execution-state path, so checkpoints fall back to a single-row
  synthesized ledger instead of the full table.
- Dispatch-level `tracking checkpoint --profile dispatch --live --post
  state[,session[,validation[,review]]]` for orchestrator-grade
  evidence. `--live` is the default posting hop so dispatch-level
  evidence writes to the provider instead of a dry-run envelope.
- `plan-tooling ledger-update --execution-state <path> --task <id>
  --status <status> --evidence <evidence>` finalizes any per-lane
  ledger row not already patched by `execute-dispatch-lane`, so the
  bundle's `## Task Ledger` is complete before the close-ready handoff
  to `dispatch-plan-closeout`.
- `tracking checkpoint --live --repair-dashboard` (or
  `record repair-dashboard`) to keep the dispatch dashboard fresh.
- Non-mutating `tracking close-ready --profile dispatch --expect-visible`
  probe before handing off to `dispatch-plan-closeout`.

Failure modes:

- Forbidden lifecycle roles for this skill: `record close` (owned by
  `dispatch-plan-closeout`); lane-scope state / session / validation
  posts (owned by `execute-dispatch-lane`); lane `review` posts
  (owned by `review-dispatch-lane-pr`). Direct posts abort with
  `forbidden-role-for-skill`.
- Controller refusal codes propagated: `run-state-stale`,
  `RECORD_BLOCKED`, any `close-ready` blocker,
  `visible-completeness-failed`.
- Visible-completeness lint codes relevant here:
  `state-missing-task-ledger`, `validation-missing-overall`,
  `review-missing-decision`, `session-missing-summary`.
- Scope-leak: opening multiple shared issues for one dispatch plan;
  lightweight-tracking closeout rules applied to a dispatch issue;
  main agent implementing lane code instead of routing.

## Entrypoint

```bash
plan-tooling validate --file "$PLAN" --format text --explain

# The --label set below is the GitHub form (both workflow:: labels survive).
# On GitLab, scoped labels are mutually exclusive per scope: drop
# workflow::plan and keep workflow::dispatch + the bare 'plan' marker, or
# workflow::plan is silently dropped (graysurf/plan-tracking-testbed#58).
plan-issue --repo "$OWNER_REPO" --format json record open \
  --profile dispatch \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore --label area::docs \
  --label state::needs-triage --label workflow::plan \
  --label workflow::dispatch --label plan

plan-issue --format json tracking run init \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --bundle "$PLAN_BUNDLE" \
  --execution-state-file "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# For each lane: dispatch `execute-dispatch-lane` with the lane scope.
# After lane PRs and reviews land, post dispatch-level state / session
# evidence:
plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --live \
  --post state,session --repair-dashboard

# Finalize any per-lane ledger row not already patched by the lane:
plan-tooling ledger-update \
  --execution-state "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --task "$TASK_ID" --status done --evidence "$LANE_PR_1"

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" \
  --linked-pr "$LANE_PR_1" --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" --expect-visible
```

Replace `area::docs` with the primary `area::` value that matches the
dispatch plan's scope.

## Workflow

1. **Preflight** — `plan-tooling validate` plus
   `tracking status --profile dispatch --expect-visible` (when
   resuming). Refuse to mutate on `run-state-stale`.
2. **Open or resume** — `record open --profile dispatch` (first
   session) or confirm the existing dispatch issue is the
   orchestrator's to drive.
3. **Lane dispatch** — assign each lane to `execute-dispatch-lane`
   with its mandatory bundle and `PLAN_BRANCH` base.
4. **Dispatch-level checkpoints** — between lane completions, post
   dispatch state / session / validation / review evidence through
   `tracking checkpoint --profile dispatch --live`.
5. **Ledger finalize** — before the close-ready probe, run
   `plan-tooling ledger-update` for any per-lane row not already
   patched by `execute-dispatch-lane`, so the bundle's
   `## Task Ledger` is complete (`tracking close-ready` refuses on
   `ledger-rows-pending` otherwise).
6. **Read-back** — `tracking status --profile dispatch --expect-visible`
   after each dispatch checkpoint; confirm dashboard names every lane
   PR and merge status.
7. **Close-ready probe** — `tracking close-ready --profile dispatch
   --expect-visible`. On `ready: true`, hand off to
   `dispatch-plan-closeout`.
8. **Stop** on any Failure mode code; never close the dispatch issue
   from this skill.

## Boundary

Owns:

- Plan-level orchestration, lane scope dispatch, and integration
  judgement.
- Dispatch dashboard freshness while lanes run.
- The non-mutating close-ready handoff decision.

Does not own:

- Implementing lane tasks — that is `execute-dispatch-lane`.
- Reviewing lane PRs — that is `review-dispatch-lane-pr`.
- Closing the dispatch issue — that is `dispatch-plan-closeout`.
- PR merge mechanics — `forge-cli` and the active PR delivery skills.
- Lightweight-tracking closeout rules.

Cross-references:

- Downstream lanes: `execute-dispatch-lane` (implementation),
  `create-dispatch-lane-pr` (PR creation),
  `review-dispatch-lane-pr` (review evidence).
- Downstream closeout: `dispatch-plan-closeout`.
- Family rules: Plan Issue Skill Family, Shared Family
  Rules section (under core/skills/dispatch/plan-issue-spec/).
