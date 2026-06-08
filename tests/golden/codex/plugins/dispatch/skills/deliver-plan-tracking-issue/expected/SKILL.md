---
name: deliver-plan-tracking-issue
description:
  Carry one lightweight issue-backed plan tracker through implementation, validation, review, PR delivery, final state, and non-mutating close-ready handoff.
---

# Deliver Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=1.0.13`, `plan-tooling >=1.0.1`,
  `forge-cli >=1.0.14`.
- The tracking issue is open, visible, and reconciled with
  `run-state.json`; FSM is not blocked or stale.
- PR work is authorized by the active PR delivery workflow. Review
  evidence is available or will be produced before close-ready.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`, `PLAN_BUNDLE`, `SLUG`, `BRANCH`.
- Optional `LINKED_PR` when a PR already exists and should be verified
  instead of created.
- Approval evidence for the later close-ready probe.
- `REVIEW_OUTCOME_COMMENT`: provider comment URL or retained evidence
  path for the review outcome. `REVIEW_FINDINGS_JSON` is optional and
  contains finding rows when findings exist.

Outputs:

- Progress checkpoints: `tracking checkpoint --live --post
  state[,session[,validation]]`.
- Delivery checkpoint: `tracking checkpoint --live --post review`.
- Per-task ledger sync through `plan-tooling ledger-update`.
- PR delivery through `forge-cli pr deliver`, or verification of an
  already linked PR through the active PR workflow.
- Non-mutating `tracking close-ready --expect-visible` handoff result.

Failure modes:

- Stop on `run-state-stale`, `issue-evidence-missing`, `RECORD_BLOCKED`,
  `visible-completeness-failed`, PR delivery failure, or any
  `close-ready` blocker.
- Stop on provider payload privacy failures such as `local_path_present`; rewrite
  useful evidence paths to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.
- Stop on `ledger-rows-pending`; repair the named task rows with
  `plan-tooling ledger-update` before retrying the gate.
- Forbidden writes: `record open`, `record attach`, `record close`,
  dispatch-profile posts, raw lifecycle comments, or PR merge outside the
  approved delivery workflow.

## Entrypoint

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --expect-visible

plan-tooling ledger-update \
  --execution-state "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --task "$TASK_ID" \
  --status done \
  --evidence "$EVIDENCE"

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase validating \
  --validation-overall pass \
  --validation-command "$VALIDATION_COMMAND" \
  --validation-status pass \
  --validation-evidence "$VALIDATION_LOG" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --live \
  --post state,session,validation \
  --repair-dashboard

forge-cli pr deliver --repo "$OWNER_REPO" \
  --kind feature --title "$PR_TITLE" \
  --head "$BRANCH" --base main \
  --body-file "$PR_BODY_FILE" \
  --format json

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase ready-for-close \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --review-decision approve \
  --review-lens testing \
  --review-lens maintainability \
  --review-outcome-comment "$REVIEW_OUTCOME_COMMENT" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --live \
  --post state,review \
  --repair-dashboard

plan-issue --format json tracking close-ready \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --profile tracking \
  --run-state "$RUN_STATE" \
  --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --approval "$APPROVAL" \
  --expect-visible
```

`forge-cli pr deliver` creates, checks, marks ready, and merges the PR for
the supplied branch; it does not take an existing `--pr`. When `LINKED_PR`
already exists, verify that PR through the active PR workflow and record the
ref with `tracking run update --linked-pr`.

## Workflow

1. **Preflight** — run `tracking status --expect-visible`; stop on stale,
   missing, blocked, or non-visible evidence.
2. **Implementation / validation** — do local work, update the task ledger
   after every task transition, and checkpoint only changed roles.
3. **PR branch**:
   - If no PR exists, deliver with `forge-cli pr deliver`.
   - If `LINKED_PR` exists, verify it is the intended merged PR and record
     it; do not re-run the create/merge macro.
4. **Review branch** — record review decision/evidence before close-ready.
   Single-author plans may use `decision=approve` when the merged PR or
   delivery-review outcome comment is the evidence; multi-author plans use the
   upstream reviewer decision. Always record review lenses and an outcome
   evidence URL/path; include `--review-findings-file "$REVIEW_FINDINGS_JSON"`
   when findings exist.
5. **Final checkpoint** — set `phase=ready-for-close`, record linked PR,
   review decision, lenses, and outcome evidence, then post `state,review`
   in one live checkpoint.
6. **Close-ready probe** — run `tracking close-ready --expect-visible`.
   If `ready: true`, hand off to `plan-tracking-issue-closeout`; if
   `ready: false`, surface blockers and stop.
7. **Never close** — this skill does not call `record close`.

## Boundary

Owns:

- Delivery-scope judgement, validation strength, review interpretation,
  PR delivery/verification, final state/review checkpoint timing, and the
  non-mutating close-ready handoff.

Must not:

- Open the original tracker, close the issue, use dispatch-profile
  semantics, or bypass the PR workflow.

Handoff:

- Upstream: `execute-plan-tracking-issue` or
  `create-plan-tracking-issue`.
- Closeout: `plan-tracking-issue-closeout`.
