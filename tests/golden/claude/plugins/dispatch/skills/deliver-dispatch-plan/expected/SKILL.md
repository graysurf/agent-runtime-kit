---
name: deliver-dispatch-plan
description: >
  Open or resume one shared dispatch plan issue, dispatch task lanes, coordinate lane PRs and reviews, and hand off to dispatch closeout.
---

# Deliver Dispatch Plan

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=1.0.13`, `plan-tooling >=1.0.1`,
  `forge-cli >=1.11.2`.
- The dispatch issue is either not opened yet, or the existing issue is
  the same shared plan being resumed by the orchestrator.
- Dispatch `run-state.json` is either uninitialized or reconciled.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `PLAN_BUNDLE`, `PLAN`, `SLUG`, optional `ISSUE`.
- `RUN_STATE` for the dispatch run.
- Lane assignments with `TASK_ID` / sprint / PR group, `PLAN_BRANCH`,
  exact task context, and the dispatch bundle
  (`TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`).
- Dispatch labels. GitHub uses `workflow::plan` plus
  `workflow::dispatch`; GitLab uses only `workflow::dispatch` plus bare
  `plan` because scoped labels collapse per `key::` scope.
- Lane approval URLs, review evidence paths, linked PRs, and final
  integration evidence for close-ready.

Outputs:

- `record open|attach --profile dispatch` for source, plan, and initial
  state snapshots.
- `tracking run init --profile dispatch --execution-state-file ...`.
  Always pass `--execution-state-file`; otherwise later dispatch state
  checkpoints render a synthesized single-row ledger instead of the
  accumulative task table.
- Dispatch-level checkpoints through `tracking checkpoint --profile
  dispatch --live --post state[,session[,validation[,review]]]`.
- Final per-lane ledger repair through `plan-tooling ledger-update`.
- Non-mutating `tracking close-ready --profile dispatch --expect-visible`
  handoff result.

Failure modes:

- Stop on `run-state-stale`, `RECORD_BLOCKED`,
  `visible-completeness-failed`, or any close-ready blocker.
- Stop on provider payload privacy failures such as `local_path_present`; rewrite
  useful evidence paths to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.
- Stop on `ledger-rows-pending`; repair only the named task rows before
  retrying close-ready.
- Forbidden writes: `record close`, lane-scoped implementation posts,
  lane review posts, lightweight-tracking closeout rules, multiple shared
  issues for one dispatch plan, or raw lifecycle comments.

## Entrypoint

```bash
plan-tooling validate --file "$PLAN" --format text --explain

# GitHub label form. For GitLab, drop workflow::plan and keep
# workflow::dispatch plus the bare plan marker.
plan-issue --repo "$OWNER_REPO" --format json record open \
  --profile dispatch \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::dispatch \
  --label plan

plan-issue --format json tracking run init \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile dispatch \
  --bundle "$PLAN_BUNDLE" \
  --execution-state-file "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --live \
  --post state,session \
  --repair-dashboard

plan-tooling ledger-update \
  --execution-state "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --task "$TASK_ID" \
  --status done \
  --evidence "$LANE_PR_1"

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --linked-pr "$LANE_PR_1" \
  --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" \
  --expect-visible
```

Replace `area::docs` with the dispatch plan's primary `area::` label.

## Workflow

1. **Preflight** — run `plan-tooling validate`; when resuming, also run
   `tracking status --profile dispatch --expect-visible`. Stop on stale
   or blocked state.
2. **Provider branch** — choose labels:
   - GitHub: `workflow::plan` + `workflow::dispatch`.
   - GitLab: `workflow::dispatch` + bare `plan`.
3. **Open / resume** — open or attach the shared dispatch issue, then run
   `tracking run init` with `--execution-state-file`.
4. **Lane dispatch** — assign each lane to `execute-dispatch-lane` with
   its exact scope and `PLAN_BRANCH`; the orchestrator does not implement
   lane code.
5. **Dispatch checkpoints** — post plan-level state/session/validation/review
   only when orchestration truth changes across lanes.
6. **Ledger finalize branch** — before close-ready, patch any lane row not
   already updated by `execute-dispatch-lane`.
7. **Read-back** — run `tracking status --profile dispatch
   --expect-visible` after dispatch checkpoints.
8. **Close-ready probe** — run the non-mutating close-ready gate. On
   `ready: true`, hand off to `dispatch-plan-closeout`; otherwise stop
   with blockers.

## Boundary

Owns:

- Plan-level orchestration, lane assignment, integration judgement,
  dispatch dashboard freshness, and the non-mutating close-ready handoff.

Must not:

- Implement lane tasks, review lane PRs, close the dispatch issue, merge
  PRs outside the active delivery workflow, or apply lightweight tracking
  closeout rules.

Handoff:

- Lanes: `execute-dispatch-lane`.
- Lane PR helper: `create-dispatch-lane-pr`.
- Lane review: `review-dispatch-lane-pr`.
- Closeout: `dispatch-plan-closeout`.
