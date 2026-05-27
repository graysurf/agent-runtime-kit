---
name: deliver-plan-tracking-issue
description:
  Carry one lightweight issue-backed plan tracker through implementation, validation, review, PR delivery, final state, and non-mutating close-ready handoff.
---

# Deliver Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=0.22.3`, `plan-tooling`, `forge-cli`.
- Issue precondition: the tracking issue is open with at least
  `source`, `plan`, and `state` evidence; FSM is at least
  `RECORD_OPEN_INITIAL` with no `run-state-stale` warning.
- Run state precondition: `run-state.json` exists for this issue and
  reconciles against provider evidence.
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`, `PLAN_BUNDLE`, `BRANCH`.
- Optional `LINKED_PR` (e.g., `$OWNER_REPO#$PR_NUMBER`) when the PR
  already exists.
- Approval evidence (URL or text) when ready for close-ready handoff.

Outputs:

- `tracking checkpoint --post state[,session[,validation]]` for
  progress checkpoints.
- `tracking checkpoint --post review` for delivery-grade review
  evidence.
- `tracking checkpoint --repair-dashboard` to keep the lightweight
  dashboard fresh.
- `forge-cli pr deliver` for the merged PR.
- Non-mutating `tracking close-ready --expect-visible` probe before
  handoff to `plan-tracking-issue-closeout`.

Failure modes:

- Forbidden lifecycle roles for this skill: `record open` / `record
  attach` (issue already exists), `record close` (owned by
  `plan-tracking-issue-closeout`). Either aborts with
  `forbidden-role-for-skill`.
- Controller refusal codes propagated: `run-state-stale`,
  `issue-evidence-missing`, `RECORD_BLOCKED`,
  `visible-completeness-failed`,
  `tracking-checkpoint-live-not-implemented`,
  any `close-ready` blocker.
- Visible-completeness lint codes relevant here:
  `state-missing-task-ledger`, `validation-missing-overall`,
  `review-missing-decision`, `review-missing-disposition`,
  `session-missing-summary`.
- Scope-leak: bypassing `tracking close-ready` before claiming
  close-ready handoff; merging a PR without `forge-cli pr deliver`
  authorization; dispatch-profile bypass.

## Entrypoint

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --expect-visible

# Implementation, validation, review — each followed by run update +
# checkpoint:
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --phase validating \
  --validation-overall pass --validation-command "cargo test" \
  --validation-status pass --validation-evidence "$VALIDATION_LOG" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" --post state,session,validation \
  --repair-dashboard

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --review-decision approve \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" --post review --repair-dashboard

forge-cli pr deliver --repo "$OWNER_REPO" --pr "$PR_NUMBER" --format json

# Final state when validation / review are complete and PR is merged:
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --phase ready_for_close \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --run-state "$RUN_STATE" --post state --repair-dashboard

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --expect-visible
```

## Workflow

1. **Preflight** — `tracking status --expect-visible`; abort on
   `run-state-stale` or `RECORD_BLOCKED`.
2. **Implementation** — local work and validation runs happen outside
   the lifecycle calls; come back here when there is durable evidence
   to post.
3. **Lifecycle checkpoints** — for each truthful change call
   `tracking run update` first, then the smallest combined
   `tracking checkpoint --post …` covering only changed roles.
4. **PR delivery** — `forge-cli pr deliver`; record the merged PR ref
   through `tracking run update --linked-pr`.
5. **Final state checkpoint** — once merged, post the final `state`
   role with `--repair-dashboard`.
6. **Close-ready probe** — `tracking close-ready --expect-visible`
   (non-mutating). If `ready: true`, hand off to
   `plan-tracking-issue-closeout`. If `ready: false`, surface
   blockers and stop.
7. **Stop** on any Failure mode code; never call `record close`.

## Boundary

Owns:

- Scope judgement, validation strength, and review interpretation for
  the lightweight tracking flow.
- The combined `state` / `session` / `validation` / `review`
  checkpoint timing.
- The non-mutating close-ready handoff decision.

Does not own:

- Opening the issue — that is `create-plan-tracking-issue`.
- The closeout post and the `record close` mutation — those belong to
  `plan-tracking-issue-closeout`.
- Dispatch-profile flows — see `deliver-dispatch-plan` and siblings.
- PR creation, update, or review mechanics — those go through
  `forge-cli` and the active PR delivery skills.

Cross-references:

- Upstream: `execute-plan-tracking-issue` (or
  `create-plan-tracking-issue` directly) seeds the issue and run
  state.
- Downstream: `plan-tracking-issue-closeout` consumes the close-ready
  audit and runs `record close`.
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
