---
name: plan-tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue after the strict close-ready audit, optional dashboard repair, and the canonical closeout post pass.
---

# Plan Tracking Issue Closeout

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=1.0.1`, `plan-tooling >=1.0.1`.
- `tracking close-ready --profile tracking --expect-visible` returns
  `ready: true` and `blockers: []`, unless this skill is taking the
  explicit final-prerequisite repair branch below.
- `run-state.json` is reconciled at `RECORD_READY_FOR_CLOSE`.
- Linked PR evidence exists unless the user gives an explicit no-PR waiver.
  Approval evidence is a comment URL or non-empty approval text.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`, `PLAN_BUNDLE`, `LINKED_PR`,
  `APPROVAL`.
- Optional dashboard repair request.
- Optional validation evidence only when a real validation run exists and
  the final-prerequisite repair branch needs it.

Outputs:

- Optional final-prerequisite checkpoint for missing `state`, `session`,
  `validation`, or `review` roles immediately before closeout.
- Optional `record repair-dashboard` when the dashboard is stale.
- `tracking run update --note "<closing summary>"` for the final
  `events.jsonl` note.
- `record close --profile tracking --bundle <bundle>` posts `closeout`,
  closes the provider issue, updates state labels, and writes terminal
  execution-state fields back to the bundle.

Failure modes:

- Stop on any close-ready blocker other than the explicit repairable role
  set: `state_complete-missing`, `session-missing`,
  `validation-missing`, `review-missing`.
- Stop on linked PR failures, missing merge SHA, missing approval,
  `ledger-rows-pending`, or closeout visible-lint failures.
- Forbidden writes after successful `record close`: any progress,
  validation, review, or closeout checkpoint. Never hand-post the closeout
  body through raw provider comments.

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

# Repair branch only for missing prerequisite roles surfaced by close-ready.
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" \
  --phase ready-for-close \
  --linked-pr "$LINKED_PR" \
  --review-decision approve \
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
  --post state,session,validation,review \
  --repair-dashboard

plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

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

1. **Preflight** — run `tracking close-ready --expect-visible`.
2. **Repair branch** — if and only if the blockers are limited to
   missing prerequisite roles (`state_complete-missing`,
   `session-missing`, `validation-missing`, `review-missing`), post one
   final `state,session,validation,review` checkpoint with real evidence
   and rerun close-ready. For any other blocker, stop.
3. **Dashboard branch** — run `record repair-dashboard` only when the live
   dashboard is stale after prerequisite evidence is complete.
4. **Closing summary** — write one final run-state note that enumerates
   tasks done, linked PRs, and deferred follow-up.
5. **Closeout mutation** — call `record close --profile tracking` with
   linked PR and approval evidence. Include `--bundle` so terminal state is
   written back to the execution-state Markdown; commit that patch.
6. **Read-back** — audit the closed issue with
   `record audit --profile tracking --expect-visible`; confirm the
   `closeout` role is visible and lint-clean.
7. **Stop** on any failure; do not retry blindly and do not post after
   close.

## Boundary

Owns:

- Final closeout decision after strict gates pass, final prerequisite-role
  repair in the closeout window, dashboard repair judgement, approval
  interpretation, and read-back integrity.

Must not:

- Implement tasks, create or update PRs, skip approval/PR evidence, close on
  unresolved blockers, or use dispatch closeout rules.

Handoff:

- Upstream: `deliver-plan-tracking-issue` or an
  `execute-plan-tracking-issue` happy path that already has closeout-ready
  evidence.
- Archive after close: `plan-archive-migrate`.
