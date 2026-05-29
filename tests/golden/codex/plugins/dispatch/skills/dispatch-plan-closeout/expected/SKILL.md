---
name: dispatch-plan-closeout
description:
  Close a shared dispatch plan issue after lane PRs, review, validation, integration, approval, and the strict dispatch close-ready audit pass.
---

# Dispatch Plan Closeout

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=0.25.10`, `plan-tooling >=0.25.10`.
- Issue precondition: `tracking close-ready --profile dispatch` returns
  `ready: true` and `blockers: []`. Every lane PR must be merged with
  required-check pass, every lane review must have no unresolved
  blocker findings, and the dispatch dashboard must name every lane.
- Run state precondition: the dispatch `run-state.json` is reconciled
  and at `RECORD_READY_FOR_CLOSE`.
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO`, `ISSUE`, `RUN_STATE`.
- Linked PR references for every dispatch lane.
- Approval evidence (comment URL or non-empty approval text).
- Optional explicit dashboard-repair request when the latest dispatch
  dashboard is out of sync.

Outputs:

- `record repair-dashboard` for a pre-closeout dispatch dashboard fix
  when needed.
- `tracking run update --profile dispatch --note "<closing summary>"`
  writes a final closeout summary event to `events.jsonl` immediately
  before `record close`. The summary must enumerate lanes / tasks done,
  linked PR(s), and any deferred follow-up; format is free-form.
- `record close --profile dispatch` posts the canonical dispatch
  `closeout` lifecycle comment, closes the provider issue, and
  transitions the workflow-state label `state::needs-triage` ->
  `state::closed` (parity with `plan-tracking-issue-closeout`).
- No run-state mutation beyond the final `--note` event and marking the
  issue closed in events.

Failure modes:

- Forbidden lifecycle roles for this skill: `state` / `session` /
  `validation` / `review` posts during the closeout window; any
  `tracking checkpoint` for the `closeout` role (the controller
  refuses this anyway). Direct posts abort with
  `forbidden-role-for-skill`.
- Controller refusal codes propagated: any `close-ready` blocker,
  `linked-pr-not-merged`, `linked-pr-checks-failed`,
  `linked-pr-missing-merge-sha`, `closeout-missing-approval`,
  `visible-completeness-failed` on the dispatch closeout body.
- Visible-completeness lint codes relevant here:
  `closeout-missing-approval`, `closeout-missing-linked-pr`,
  `closeout-missing-summary`.
- `ledger-rows-pending` (from `tracking close-ready --profile
  dispatch`): a per-lane ledger row is still `pending` or
  `in-progress` at `phase=ready_for_close`. Remediation: run
  `plan-tooling ledger-update --execution-state <path> --task '<id>'
  --status done --evidence <evidence>` for the offending row(s) before
  re-running the gate; never proceed to `record close` while the
  blocker fires.
- Scope-leak: lane implementation; PR creation, update, or merge;
  lightweight-tracking closeout rules applied to a dispatch issue;
  raw `gh issue comment` / `glab issue note` / `forge-cli issue
  comment` for the closeout body.

## Entrypoint

```bash
plan-issue --format json tracking close-ready \
  --profile dispatch \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --run-state "$RUN_STATE" \
  --linked-pr "$LANE_PR_1" --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" --expect-visible

# Optional repair when the dashboard is stale:
plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

# Final closing summary written to events.jsonl before record close:
plan-issue --format json tracking run update \
  --profile dispatch --run-state "$RUN_STATE" \
  --note "Closeout: <lanes/tasks>; PRs <linked-pr>; followup <none|...>" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --repo "$OWNER_REPO" --format json record close \
  --profile dispatch \
  --issue "$ISSUE" \
  --linked-pr "$LANE_PR_1" --linked-pr "$LANE_PR_2" \
  --approval "$APPROVAL" \
  --add-label state::closed \
  --remove-label state::needs-triage
```

## Workflow

1. **Preflight** — call `tracking close-ready --profile dispatch
   --expect-visible`. Stop on any blocker; never patch around it.
2. **Dashboard repair (optional)** — only when the live dispatch
   dashboard is stale, call `record repair-dashboard` and confirm it
   matches the latest lane evidence.
3. **Closing summary event** — immediately before `record close`, call
   `tracking run update --profile dispatch --note "<closing summary>"`
   so `events.jsonl` carries a final summary event of the rollout. The
   summary must enumerate lanes / tasks done, linked PR(s), and any
   deferred follow-up; format is free-form.
4. **Closeout post** — call `record close --profile dispatch` with
   every lane PR ref and approval, plus `--add-label state::closed
   --remove-label state::needs-triage` so the closed dispatch issue
   lands on `state::closed` (parity with `plan-tracking-issue-closeout`).
   The strict gate enforces required checks and merge SHAs.
5. **Read-back** — `record audit --profile dispatch --expect-visible`
   against the closed issue body and comments; confirm the
   `closeout` role appears with `visible.codes` empty.
6. **Stop** on any Failure mode code; do not retry blindly.

## Boundary

Owns:

- The dispatch closeout decision (after the strict gate passes).
- Approval interpretation, lane integration verification, and the
  final read-back integrity check.

Does not own:

- Lane work — that is `execute-dispatch-lane`.
- Lane reviews — that is `review-dispatch-lane-pr`.
- PR creation, update, or merge — `forge-cli` and the active PR
  delivery skills.
- Lightweight-tracking closeout — see `plan-tracking-issue-closeout`.

Cross-references:

- Upstream: `deliver-dispatch-plan` (the close-ready handoff after
  every lane finishes).
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
