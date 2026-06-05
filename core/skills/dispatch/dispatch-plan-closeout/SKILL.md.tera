---
name: dispatch-plan-closeout
description:
  Close a shared dispatch plan issue after lane PRs, review, validation, integration, approval, and the strict dispatch close-ready audit pass.
---

# Dispatch Plan Closeout

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=1.0.1`, `plan-tooling >=1.0.1`.
- `tracking close-ready --profile dispatch --expect-visible` returns
  `ready: true` and `blockers: []`.
- Every lane PR is merged with required checks passing, every lane review
  has no unresolved blocker findings, and the dashboard names every lane.
- Dispatch `run-state.json` is reconciled at `RECORD_READY_FOR_CLOSE`.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`.
- Linked PR refs for every lane and any final integration PR.
- Approval evidence as a comment URL or non-empty approval text.
- Optional dashboard repair request.

Outputs:

- Optional `record repair-dashboard` when the dispatch dashboard is stale.
- `tracking run update --profile dispatch --note "<closing summary>"`
  for the final `events.jsonl` note.
- `record close --profile dispatch` posts `closeout`, closes the provider
  issue, and changes labels from `state::needs-triage` to
  `state::closed`.

Failure modes:

- Stop on any close-ready blocker, linked PR failure, missing merge SHA,
  missing approval, `ledger-rows-pending`, or closeout visible-lint
  failure.
- Forbidden writes: lane implementation, lane PR creation/update/merge,
  progress/review checkpoints during closeout, lightweight tracking
  closeout rules, or raw provider lifecycle comments.

## Entrypoint

```bash
plan-issue --format json tracking close-ready \
  --profile dispatch \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$LANE_PR_1" \
  --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" \
  --expect-visible

plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

plan-issue --format json tracking run update \
  --profile dispatch \
  --run-state "$RUN_STATE" \
  --note "Closeout: <lanes/tasks>; PRs <linked-pr>; followup <none|...>" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --repo "$OWNER_REPO" --format json record close \
  --profile dispatch \
  --issue "$ISSUE" \
  --linked-pr "$LANE_PR_1" \
  --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" \
  --add-label state::closed \
  --remove-label state::needs-triage
```

## Workflow

1. **Preflight** — run `tracking close-ready --profile dispatch
   --expect-visible`; stop on any blocker and do not patch around it.
2. **Dashboard branch** — run `record repair-dashboard` only when the
   live dispatch dashboard is stale.
3. **Closing summary** — write one final run-state note enumerating
   lanes/tasks done, linked PRs, and deferred follow-up.
4. **Closeout mutation** — call `record close --profile dispatch` with
   every lane PR ref and approval. Include the state label transition.
5. **Read-back** — audit the closed issue with
   `record audit --profile dispatch --expect-visible`; confirm the
   `closeout` role is visible and lint-clean.
6. **Stop** on any failure; do not retry blindly.

## Boundary

Owns:

- Dispatch closeout decision after strict gates pass, approval
  interpretation, lane integration verification, and read-back integrity.

Must not:

- Implement lane work, review lanes, create/update/merge PRs, apply
  lightweight-tracking closeout rules, or close with missing lane evidence.

Handoff:

- Upstream: `deliver-dispatch-plan`.
