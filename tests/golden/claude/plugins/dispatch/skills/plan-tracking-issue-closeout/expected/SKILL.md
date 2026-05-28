---
name: plan-tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue after the strict close-ready audit, optional dashboard repair, and the canonical closeout post pass.
---

# Plan Tracking Issue Closeout

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=0.25.10`, `plan-tooling >=0.25.10`.
- Issue precondition: `tracking close-ready --profile tracking` returns
  `ready: true` and `blockers: []`. Required-check pass on every linked
  PR is part of that gate.
- Run state precondition: `run-state.json` is reconciled (FSM at
  `RECORD_READY_FOR_CLOSE`).
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`.
- Linked PR references (`OWNER_REPO#NUMBER`) — at least one required
  unless the user explicitly provides a no-PR waiver.
- Approval evidence (comment URL or non-empty approval text).
- Optional explicit dashboard-repair request when the latest dashboard
  is out of sync.

Outputs:

- `record repair-dashboard` for a pre-closeout dashboard fix when
  needed.
- `tracking run update --note "<closing summary>"` writes a final
  closeout summary event to `events.jsonl` immediately before
  `record close`. The summary must enumerate tasks done, linked
  PR(s), and any deferred follow-up; format is free-form because
  `events.jsonl` accepts free-form notes.
- `record close --profile tracking` posts the canonical `closeout`
  lifecycle comment and closes the provider issue.
- No run-state mutation beyond the final `--note` event and marking
  the issue closed.

Failure modes:

- Forbidden lifecycle roles for this skill: `state` / `session` /
  `validation` / `review` posts **after `record close` succeeds**;
  any `tracking checkpoint` for the `closeout` role (the controller
  refuses this anyway). Post-closeout direct posts abort with
  `forbidden-role-for-skill`. **Preflight repair** of any missing
  prerequisite role surfaced by `tracking close-ready` —
  `review-missing`, `state_complete-missing`, `session-missing`,
  `validation-missing` — is in scope; see Workflow step 1 for the
  repair procedure and the rationale for why closeout owns this last
  write opportunity.
- Controller refusal codes propagated: any `close-ready` blocker,
  `linked-pr-not-merged`, `linked-pr-checks-failed`,
  `linked-pr-missing-merge-sha`, `closeout-missing-approval`,
  `visible-completeness-failed` on the closeout body.
- Visible-completeness lint codes relevant here:
  `closeout-missing-approval`, `closeout-missing-linked-pr`,
  `closeout-missing-summary`.
- `ledger-rows-pending` (from `tracking close-ready`): a per-task
  ledger row is still `pending` or `in-progress` at
  `phase=ready_for_close`. Remediation: run `plan-tooling
  ledger-update --execution-state <path> --task '<id>' --status done
  --evidence <evidence>` for the offending row(s) before re-running
  the gate; never proceed to `record close` while the blocker fires.
- Scope-leak: implementing tasks, opening / closing PRs, or treating
  missing approval / PR evidence as implicit approval.

## Entrypoint

```bash
plan-issue --format json tracking close-ready \
  --profile tracking \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$LINKED_PR" \
  --approval "$APPROVAL" \
  --expect-visible

# Optional repair when the dashboard is stale:
plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

# Final closing summary written to events.jsonl before record close:
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --note "Closeout: <tasks>; PRs <linked-pr>; followup <none|...>" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --repo "$OWNER_REPO" --format json record close \
  --profile tracking \
  --issue "$ISSUE" \
  --bundle "$PLAN_BUNDLE" \
  --linked-pr "$LINKED_PR" \
  --approval "$APPROVAL" \
  --add-label state::closed \
  --remove-label state::needs-triage
```

## Workflow

1. **Preflight** — call `tracking close-ready --expect-visible`. If
   `ready: true`, continue. If `ready: false` with any combination of
   `review-missing`, `state_complete-missing`, `session-missing`, or
   `validation-missing`, the upstream `execute-plan-tracking-issue` /
   `deliver-plan-tracking-issue` handoff omitted those roles; repair
   them in scope through one canonical `tracking checkpoint --live`
   invocation. First bump the run state to `phase=ready-for-close`
   (kebab-case as accepted by the CLI; persisted as `ready_for_close`
   in `run-state.json`), record the delivery decision, and — when
   you have a real validation run — set `--validation-overall pass`
   plus its evidence fields. The controller derives
   `state.status=complete` from `phase=ready-for-close`. Then post
   every prerequisite role and refresh the dashboard in the same
   call. `tracking checkpoint --live --post state,session,validation,review
   --repair-dashboard` posts in declaration order and aborts on the
   first per-role failure with `tracking-checkpoint-live-post-failed`;
   only retry preflight once every required role posts. For any
   other blocker, stop and never patch around it.

   ```bash
   plan-issue --format json tracking run update \
     --run-state "$RUN_STATE" --phase ready-for-close \
     --linked-pr "$LINKED_PR" \
     --review-decision approve \
     --validation-overall pass \
     --validation-command "<validation command>" \
     --validation-status pass \
     --validation-evidence "$VALIDATION_LOG" \
     --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   plan-issue --format json tracking checkpoint \
     --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
     --run-state "$RUN_STATE" \
     --profile tracking --post state,session,validation,review \
     --repair-dashboard --live
   ```

2. **Dashboard repair (optional)** — only when the live dashboard is
   stale, call `record repair-dashboard` and confirm the rendered
   dashboard matches the latest evidence.
3. **Closing summary event** — immediately before `record close`,
   call `tracking run update --note "<closing summary>"` so
   `events.jsonl` carries a final summary event of the rollout. The
   summary must enumerate tasks done, linked PR(s), and any deferred
   follow-up; format is free-form. Example:

   ```bash
   plan-issue --format json tracking run update \
     --run-state "$RUN_STATE" \
     --note "Closeout: 1.1-3.8 done; PRs $OWNER_REPO#123; followup: none" \
     --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```

4. **Closeout post** — call `record close --profile tracking` with the
   linked PR refs and approval. The strict gate enforces required
   checks and merge SHAs.
5. **Read-back** — `record audit --profile tracking --expect-visible`
   against the closed issue body and comments; confirm the `closeout`
   role appears with `visible.codes` empty:

   ```bash
   gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,state,comments \
     >"$ISSUE_JSON"
   jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"
   plan-issue --format json record audit \
     --profile tracking \
     --body-file "$ISSUE_BODY" \
     --comments-json "$ISSUE_JSON" \
     --expect-visible
   ```

6. **Stop** on any Failure mode code; do not retry blindly.

## Boundary

Owns:

- The closeout decision (after the strict gate passes).
- Dashboard-repair judgement immediately before closeout.
- Approval interpretation and the read-back integrity check.

Does not own:

- Any progress posting (`state` / `session` / `validation` / `review`)
  — those belong to `execute-plan-tracking-issue` and
  `deliver-plan-tracking-issue`.
- Opening or attaching the issue — that is
  `create-plan-tracking-issue`.
- Dispatch closeout — see `dispatch-plan-closeout`.
- PR work — `forge-cli` and the active PR delivery skills.

Cross-references:

- Upstream: `deliver-plan-tracking-issue` (the close-ready handoff).
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
