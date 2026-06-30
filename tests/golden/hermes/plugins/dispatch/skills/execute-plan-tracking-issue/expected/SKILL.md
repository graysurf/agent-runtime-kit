---
name: execute-plan-tracking-issue
description: >
  Resume a lightweight issue-backed plan tracker, reconcile run state with provider evidence, and post state / session / validation checkpoints.
---

# Execute Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=1.0.13`, `plan-tooling >=1.0.1`.
- The tracking issue exists with visible `source`, `plan`, and initial
  `state` evidence.
- `run-state.json` exists for this issue. If not, defer to
  `create-plan-tracking-issue` / `tracking run init`.
- Provider issue evidence wins over local run state. Any stale-state code
  is a hard stop until reconciled.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `ISSUE`, `PLAN_BUNDLE`, `SLUG`, `RUN_STATE`, `BRANCH`.
- Optional `TASK_ID` or sprint identifier when run state does not already
  select the work.
- Validation command/result/evidence only after validation actually ran.

Outputs:

- `tracking run update` for selected task, branch, phase, notes, blockers,
  validation fields, and evidence pointers.
- `tracking checkpoint --live --post state[,session[,validation]]` for
  useful progress only.
- `plan-tooling ledger-update` after each task row changes status.
- Dashboard repair only as part of a controller checkpoint or an explicit
  lower-level repair.

Failure modes:

- Stop on `run-state-stale`, `issue-evidence-missing`, `RECORD_BLOCKED`,
  `visible-completeness-failed`, or `tracking close-ready` blockers such
  as `ledger-rows-pending`.
- Stop on provider payload privacy failures such as `local_path_present`; rewrite
  useful evidence paths to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.
- Stop on execution-state issue mismatch. Use
  `plan-tooling exec-state-sync` only when the issue URL is known and the
  mismatch is a placeholder/missing-url repair, not a genuine wrong issue.
- Forbidden writes: `record open`, `record attach`, `review`, `closeout`,
  PR delivery, source/plan snapshot rewrites, or unchanged validation noise.

## Entrypoint

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
  --note "starting $TASK_ID" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-tooling ledger-update \
  --execution-state "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --task "$TASK_ID" \
  --status done \
  --evidence "$EVIDENCE"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --live \
  --post state,session,validation \
  --repair-dashboard
```

For validation, set `--validation-*` fields in `tracking run update` only
after the command completed and evidence exists.

## Workflow

1. **Preflight** — run `tracking status --expect-visible`; stop on stale
   run state, missing issue evidence, blocked FSM state, or visible lint.
2. **Scope decision** — choose the current task/sprint. Post only when the
   issue-visible truth changes: task started/completed, validation changed,
   blocker changed, PR state changed, sprint status changed, or handoff
   context would prevent a wrong next decision.
3. **Local work** — implement outside lifecycle calls.
4. **Checkpoint branch**:
   - If a task row changed, run `plan-tooling ledger-update` first.
   - If validation ran, update validation fields and include
     `validation`.
   - If useful session context exists, include `session`.
   - Otherwise post only `state`, or skip the post when it would repeat
     the dashboard.
5. **Read-back** — rerun `tracking status --expect-visible`; confirm the
   new roles are visible and lint-clean.
6. **Stop / handoff** — stop on any failure code. Hand off to
   `deliver-plan-tracking-issue` when PR delivery or review evidence is in
   scope; hand off to closeout only after required roles exist.

## Boundary

Owns:

- Resume scope selection, progress checkpoint judgement, validation
  interpretation, and per-task ledger sync.

Must not:

- Open/attach the issue, post review evidence, create/merge PRs, post
  closeout, or rewrite source/plan snapshots.

Handoff:

- Upstream: `create-plan-tracking-issue`.
- Delivery/review: `deliver-plan-tracking-issue`.
- Closeout: `plan-tracking-issue-closeout`.
