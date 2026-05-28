---
name: execute-plan-tracking-issue
description:
  Resume a lightweight issue-backed plan tracker, reconcile run state with provider evidence, and post state / session / validation checkpoints.
---

# Execute Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=0.25.10`, `plan-tooling >=0.25.10`.
- Issue precondition: the tracking issue exists with at least `source`,
  `plan`, and an initial `state` lifecycle comment.
- Run state precondition: a `run-state.json` exists for this issue (or
  the skill must defer to `create-plan-tracking-issue` /
  `tracking run init` first).
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO`, `ISSUE`, `PLAN_BUNDLE`, `BRANCH`.
- `RUN_STATE` — path to the existing `run-state.json`.
- Optional `TASK_ID` or sprint number when the run state does not
  already name it.
- Validation evidence path (`$VALIDATION_LOG`) when a validation run
  has actually completed.

Outputs:

- `tracking checkpoint --live --post state[,session[,validation]]` for
  in-progress updates. `--live` is the default execution path so the
  prescribed lifecycle posting writes to the provider instead of
  returning a dry-run envelope. `tracking close-ready` later treats
  `session` and `validation` as required, so post both at least once
  before handing off to `plan-tracking-issue-closeout` (post them in
  the final combined checkpoint after the last task transitions).
- `tracking run update` writes `selected_task`, `branch`, `phase`,
  `validation_*`, and notes back into the typed run state.
- `plan-tooling ledger-update --execution-state <path> --task <id>
  --status <status> --evidence <evidence>` patches the canonical
  per-task ledger row in `<slug>-execution-state.md` immediately after
  each task transitions (started → done / blocked / waived), so the
  bundle's `## Task Ledger` stays faithful to actual execution.
- Dashboard repair through `tracking checkpoint --live
  --repair-dashboard` (or `record repair-dashboard` if a lower-level
  fix is needed).

Failure modes:

- Forbidden lifecycle roles for this skill: `record open` / `record
  attach` (issue already exists), `review` posts (that belongs to
  `deliver-plan-tracking-issue`), `closeout` posts. Any of these abort
  with `forbidden-role-for-skill`.
- Controller refusal codes propagated: `run-state-stale`,
  `issue-evidence-missing`, `RECORD_BLOCKED`,
  `visible-completeness-failed`.
- Visible-completeness lint codes relevant here:
  `state-missing-task-ledger`, `validation-missing-overall`,
  `session-missing-summary`.
- `ledger-rows-pending` (from `tracking close-ready`): a per-task
  ledger row is still `pending` or `in-progress` at
  `phase=ready_for_close`. Remediation: run `plan-tooling
  ledger-update --execution-state <path> --task '<id>' --status done
  --evidence <evidence>` for the offending row(s) before re-running
  the gate.
- Scope-leak: rewriting `source` / `plan` snapshots, posting for
  purely local edits, or posting unchanged validation reruns.

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

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --live \
  --post state
```

After validation results land, update run state and re-checkpoint:

```bash
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase validating \
  --validation-overall pass \
  --validation-command "cargo test -p ..." \
  --validation-status pass \
  --validation-evidence "$VALIDATION_LOG" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --live \
  --post state,session,validation \
  --repair-dashboard
```

After each task transitions, patch the canonical ledger row:

```bash
plan-tooling ledger-update \
  --execution-state "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --task "$TASK_ID" \
  --status done \
  --evidence "$EVIDENCE"
```

`--evidence` is required; pass the PR / commit / comment URL or other
verifiable citation. Status values: `pending | in-progress | done |
blocked | waived`. `--notes` is the only path that mutates the
`Notes` column; omit it to leave `Notes` untouched.

## Workflow

1. **Preflight** — run `tracking status --expect-visible` and confirm
   `fsm_state` is consistent with the run state; refuse to post on
   `run-state-stale` or `issue-evidence-missing`.
2. **Scope decision** — choose the task / sprint subset for this
   resume; decide whether a comment would teach a reader something
   new (started, completed, validation flipped, blocker discovered,
   PR opened, sprint status changed).
3. **Implementation** — do the local work outside this skill's CLI
   flow; the skill resumes after work produces a postable change.
4. **Lifecycle checkpoint** — call `tracking run update` with the
   changed fields, then `tracking checkpoint --live` with only the
   role(s) whose body actually changed.
5. **Per-task ledger update** — immediately after a task transitions
   (started → done / blocked / waived), call `plan-tooling
   ledger-update --execution-state <path> --task <id> --status
   <status> --evidence <evidence>` so the bundle's canonical
   `## Task Ledger` table is patched before the next checkpoint
   reads it.
6. **Read-back** — re-run `tracking status --expect-visible` and
   confirm the new role appears in the reconciled evidence with
   `lint_pass: true`.
7. **Stop** on any Failure mode code; record blockers via
   `tracking run update --note` and surface to the user.

## Boundary

Owns:

- Scope selection for the resumed task / sprint.
- The judgement of when a checkpoint is worth posting.
- Validation interpretation and the choice of roles to include in a
  combined checkpoint.

Does not own:

- Opening or attaching the issue — that is
  `create-plan-tracking-issue`.
- `review` checkpoints — those belong to `deliver-plan-tracking-issue`
  (which carries delivery-grade review evidence).
- Closeout and `record close` — that is
  `plan-tracking-issue-closeout`.
- Reconciliation algorithms and visible-lint enforcement — those are
  owned by `plan-issue tracking`.

Cross-references:

- Upstream: `create-plan-tracking-issue` provides the issue and
  initial run state.
- Downstream: `deliver-plan-tracking-issue` takes over when the
  selected scope is ready to be carried through PR delivery and
  close-readiness.
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
