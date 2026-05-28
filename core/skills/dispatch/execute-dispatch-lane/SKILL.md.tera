---
name: execute-dispatch-lane
description:
  Execute one assigned dispatch task lane, drive its PR through forge-cli, and post lane-scoped state / session / validation back to the shared dispatch issue.
---

# Execute Dispatch Lane

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=0.22.3`, `forge-cli`.
- Issue precondition: the shared dispatch issue exists and is at least
  `RECORD_OPEN_ACTIVE` with no `run-state-stale` warning.
- Run state precondition: the dispatch `run-state.json` is reconciled
  and names this lane.
- Lane precondition: an assigned `TASK_ID` (or sprint / PR group),
  `BRANCH`, `WORKTREE`, and `PLAN_BRANCH`. The dispatch bundle
  (`TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`)
  is on hand.
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO`, `ISSUE` (shared dispatch issue), `RUN_STATE`.
- Lane scope: `TASK_ID` / sprint / PR group, `BRANCH`, `WORKTREE`,
  `PLAN_BRANCH`.
- Optional existing lane PR reference (`OWNER_REPO#NUMBER`).
- Validation evidence path (`$VALIDATION_LOG`).

Outputs:

- Lane-scoped `tracking checkpoint --profile dispatch --post
  state[,session[,validation]]` (only for this lane's task subset).
- `tracking run update` writes lane fields (`selected_task`,
  `branch`, `linked_pr`, `validation_*`, notes) for this lane only.
- `forge-cli pr create` / `forge-cli pr update` (typically through
  `create-dispatch-lane-pr`).

Failure modes:

- Forbidden lifecycle roles for this skill: `record open` (issue
  already exists), `record close`, dispatch-level state / session
  rollups (owned by `deliver-dispatch-plan`), `review` posts (owned
  by `review-dispatch-lane-pr`). Direct posts abort with
  `forbidden-role-for-skill`.
- Controller refusal codes propagated: `run-state-stale`,
  `RECORD_BLOCKED`,
  `visible-completeness-failed`.
- Visible-completeness lint codes relevant here:
  `state-missing-task-ledger`, `validation-missing-overall`,
  `session-missing-summary`.
- Scope-leak: reassigning lane scope; mutating unrelated lanes'
  fields; targeting the repository default branch when a
  `PLAN_BRANCH` is assigned; raw `gh issue comment` / `glab issue
  note` / `forge-cli issue comment` for lifecycle evidence.

## Entrypoint

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" --expect-visible

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --selected-task "$TASK_ID" --branch "$BRANCH" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# After local work completes:
forge-cli pr create --repo "$OWNER_REPO" --base "$PLAN_BRANCH" \
  --head "$BRANCH" --format json

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --validation-overall pass --validation-command "cargo test" \
  --validation-status pass --validation-evidence "$VALIDATION_LOG" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --post state,session,validation
```

## Workflow

1. **Preflight** — `tracking status --profile dispatch --expect-visible`;
   refuse to mutate on `run-state-stale` or any blocker. Confirm the
   assigned `PLAN_BRANCH` matches the shared dispatch run state.
2. **Implementation** — do the lane work in the assigned worktree on
   `BRANCH`. Validation runs locally and produces `$VALIDATION_LOG`.
3. **PR creation** — call `create-dispatch-lane-pr` (or `forge-cli pr
   create` directly) with `--base "$PLAN_BRANCH"`. Never target the
   repository default branch.
4. **Run state update** — `tracking run update` records the lane PR
   ref and validation evidence.
5. **Lane checkpoint** — `tracking checkpoint --profile dispatch
   --post state,session,validation` (lane scope only).
6. **Read-back** — `tracking status --profile dispatch
   --expect-visible` and confirm the lane PR ref appears in the
   reconciled view.
7. **Stop** on any Failure mode code; if the orchestrator redirected
   lane scope, finish the current update and stop instead of
   expanding.

## Boundary

Owns:

- This lane's implementation, validation execution, and lane-scoped
  checkpoint timing.
- The decision to post a lane checkpoint (after a meaningful change).

Does not own:

- Dispatch-level orchestration, integration, or scope reassignment —
  that is `deliver-dispatch-plan`.
- Lane reviews — that is `review-dispatch-lane-pr`.
- Closeout — that is `dispatch-plan-closeout`.
- PR merge mechanics — `forge-cli` and the active PR delivery skills.

Cross-references:

- Upstream: `deliver-dispatch-plan` assigns the lane and provides the
  dispatch bundle and `PLAN_BRANCH`.
- Sibling helper: `create-dispatch-lane-pr` for the PR creation step.
- Downstream: `review-dispatch-lane-pr` once the lane PR is ready for
  review.
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
