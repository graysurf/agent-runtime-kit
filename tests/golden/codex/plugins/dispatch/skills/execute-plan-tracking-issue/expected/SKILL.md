---
name: execute-plan-tracking-issue
description:
  Resume lightweight issue-backed plan execution from lifecycle comments and keep the dashboard current.
---

# Execute Plan Tracking Issue

## Purpose

Resume one lightweight plan-tracking issue for the selected task or sprint
scope. Reconcile provider issue lifecycle evidence with the local
run-state before implementation, update the run-state while work
progresses, and post a checkpoint when issue-visible truth changes.
`plan-issue tracking` owns reconciliation, rendering, and dashboard
repair; the skill body owns judgment about what changed and whether to
post.

## When to use

- A tracking issue already exists with `source`, `plan`, and an initial
  `state` lifecycle comment, and the user wants to advance the selected
  task without re-opening the issue.
- The provider issue may have newer evidence than the local run-state and
  the next step needs reconciliation.

## Inputs

- `OWNER_REPO`, `ISSUE`, `PLAN_BUNDLE`, `BRANCH`.
- `RUN_STATE` — path to the existing `run-state.json` (created by
  `create-plan-tracking-issue` or a previous run of this skill).
- Optional `--task <id>` or `--sprint <number>` selection when the run
  state does not already name it.

## Preflight

- `plan-issue >=0.22.3` and `plan-tooling` are on `PATH`.
- The bundle files exist at canonical paths and the local execution-state
  Markdown is up to date for the rendered state checkpoint.
- A `run-state.json` exists or is initialized with `tracking run init`
  before this skill posts any progress comment.

## Allowed lifecycle roles

- `state` checkpoint through `plan-issue tracking checkpoint --post state`
  (use `--task-ledger-display collapsed` for intermediate updates).
- `session` checkpoint when a meaningful work session ended or a handoff
  needs durable context.
- `validation` checkpoint when validation actually ran and changed
  issue-visible status.
- Dashboard repair only through `plan-issue tracking checkpoint
  --repair-dashboard` or, if a lower-level surface is needed, through
  `plan-issue record repair-dashboard`.

## Forbidden actions

- No `record open` or `record attach` — the issue already exists.
- No `record close` and no closeout comment.
- No `review` lifecycle comments — those belong to
  `deliver-plan-tracking-issue` (which has the review surface in scope).
- No rewriting `source` or `plan` snapshots.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for lifecycle evidence.
- No posting when `tracking status` reports `run-state-stale`,
  `issue-evidence-missing`, or any other blocked code without
  reconciliation.
- No comments for purely local edits, speculative notes, or unchanged
  validation reruns.

## CLI flow

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --expect-visible

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --selected-task "$TASK_ID" \
  --branch "$BRANCH" \
  --note "starting $TASK_ID"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" \
  --post state
```

After validation results land, update run-state and re-checkpoint:

```bash
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase validating \
  --validation-overall pass \
  --validation-command "cargo test -p ..." \
  --validation-status pass \
  --validation-evidence "$VALIDATION_LOG"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" \
  --post state,session,validation \
  --repair-dashboard
```

## Evidence requirements

- The `tracking status` envelope reports `fsm_state` and an empty
  `warnings.run-state-stale` set before any checkpoint posts go live.
- The `tracking checkpoint` envelope lists every planned `roles_planned`
  with `lint_pass: true` and an empty `blocked` array.
- Every progress update appends events to `events.jsonl` under the issue
  run root.

## Stop conditions

- `tracking status` reports `run-state-stale` — refuse to post until run
  state is synchronized or explicitly repaired.
- `tracking status` reports missing required source/plan/state evidence —
  return to `create-plan-tracking-issue` rather than papering over the
  gap.
- `tracking checkpoint` returns a `visible-completeness-failed` blocker —
  fix the run state / execution-state Markdown before retrying.
- The FSM reports `RECORD_BLOCKED` — record the blocker through
  `tracking run update --note` and stop.

## Validation

- `plan-issue tracking status --expect-visible` shows a `fsm_state` that
  is consistent with the run state phase.
- `plan-issue tracking checkpoint` (dry-run) writes rendered bodies under
  `runs/<run-id>/rendered/` and passes the visible lint.
- For live mode, the audit step from `create-plan-tracking-issue`
  confirms the new comment appeared with the expected role.

## Boundary

`plan-issue tracking` owns reconciliation, checkpoint rendering, and
dashboard repair. `plan-issue record` is the primitive layer this
controller adapts. The skill body owns scope selection, validation
interpretation, and the decision to post a checkpoint at all.
