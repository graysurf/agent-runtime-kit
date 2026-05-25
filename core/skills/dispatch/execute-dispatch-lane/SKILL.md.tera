---
name: execute-dispatch-lane
description:
  Execute an assigned dispatch task lane, open or update its PR through forge-cli, and report lane state back to the shared dispatch issue record.
---

# Execute Dispatch Lane

## Purpose

Execute one assigned dispatch lane end to end: keep lane facts scoped to
the assigned task or sprint, drive the PR through `forge-cli`, and post
lane progress back to the shared dispatch issue record. Lane work never
mutates other lanes or closes the shared issue.

## When to use

- `deliver-dispatch-plan` has assigned the lane and the lane has a
  branch, worktree, base PLAN_BRANCH, and task scope.
- An existing lane needs a resume after a session break.

## Inputs

- `OWNER_REPO`, `ISSUE` (shared dispatch issue), lane `TASK_ID` / sprint
  / PR group, `BRANCH`, `WORKTREE`, `RUN_STATE`.
- Optional existing lane PR reference (`OWNER_REPO#NUMBER`).

## Preflight

- `plan-issue >=0.22.3` and `forge-cli` are on `PATH`.
- `tracking status --profile dispatch --expect-visible` reports the
  shared issue as `RECORD_OPEN_ACTIVE` or later with no
  `run-state-stale` warning.
- The assigned `PLAN_BRANCH` is the base; never target the repository
  default branch.

## Allowed lifecycle roles

- Lane-scoped `state`, `session`, and `validation` checkpoints through
  `plan-issue tracking checkpoint --profile dispatch` constrained to the
  assigned lane scope.
- `tracking run update` to record branch, PR, validation, and notes for
  the assigned lane.
- PR creation and update through `forge-cli pr create` /
  `forge-cli pr update` (typically via `create-dispatch-lane-pr`).

## Forbidden actions

- No reassigning lane scope. The orchestrator decides scope.
- No mutating unrelated lanes' fields in run state.
- No `record close` and no closeout comment.
- No `review` lifecycle comments. `review-dispatch-lane-pr` owns review
  evidence.
- No targeting the repository default branch when a `PLAN_BRANCH` is
  assigned.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for lifecycle evidence.

## CLI flow

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" --expect-visible

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --selected-task "$TASK_ID" --branch "$BRANCH"

# After local work completes:
forge-cli pr create --repo "$OWNER_REPO" --base "$PLAN_BRANCH" \
  --head "$BRANCH" --format json

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --validation-overall pass --validation-command "cargo test" \
  --validation-status pass --validation-evidence "$VALIDATION_LOG"

plan-issue --format json tracking checkpoint \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --post state,session,validation
```

## Evidence requirements

- `forge-cli pr create` returns the PR URL and base branch matches
  `PLAN_BRANCH`.
- `tracking checkpoint` envelope shows the lane's `state` / `session` /
  `validation` roles posted with `lint_pass: true`.
- `events.jsonl` records `task_selected`, `validation_recorded`, and
  `checkpoint_posted` events.

## Stop conditions

- `tracking status` reports `run-state-stale` or any blocked code that
  requires reconciliation.
- `forge-cli pr create` fails because the base branch or worktree is
  wrong — surface and stop.
- Validation fails in a way that blocks lane progress.
- The orchestrator redirected the lane scope; finish the current update
  and stop instead of expanding.

## Validation

- `forge-cli pr <create|update>` returns success with the assigned base.
- `tracking checkpoint --profile dispatch` returns `lint_pass: true`.
- `tracking status` confirms the lane PR ref now appears in the
  reconciled view.

## Boundary

`forge-cli` owns PR mechanics. `plan-issue tracking` owns lifecycle
checkpoints and dashboard repair. The lane skill owns implementation,
validation execution, and the decision to post a lane checkpoint.
