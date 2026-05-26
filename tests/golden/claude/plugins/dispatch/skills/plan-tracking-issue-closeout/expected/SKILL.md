---
name: plan-tracking-issue-closeout
description:
  Close a lightweight plan-tracking issue after the strict close-ready audit, optional dashboard repair, and the canonical closeout post pass.
---

# Plan Tracking Issue Closeout

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=0.22.3`.
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
- `record close --profile tracking` posts the canonical `closeout`
  lifecycle comment and closes the provider issue.
- No run-state mutation beyond marking the issue closed in events.

Failure modes:

- Forbidden lifecycle roles for this skill: `state` / `session` /
  `validation` / `review` posts during the closeout window; any
  `tracking checkpoint` for the `closeout` role (the controller
  refuses this anyway). Direct posts abort with
  `forbidden-role-for-skill`.
- Controller refusal codes propagated: any `close-ready` blocker,
  `linked-pr-not-merged`, `linked-pr-checks-failed`,
  `linked-pr-missing-merge-sha`, `closeout-missing-approval`,
  `visible-completeness-failed` on the closeout body.
- Visible-completeness lint codes relevant here:
  `closeout-missing-approval`, `closeout-missing-linked-pr`,
  `closeout-missing-summary`.
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

plan-issue --repo "$OWNER_REPO" --format json record close \
  --profile tracking \
  --issue "$ISSUE" \
  --linked-pr "$LINKED_PR" \
  --approval "$APPROVAL"
```

## Workflow

1. **Preflight** — call `tracking close-ready --expect-visible`. Stop
   on any blocker; never patch around it.
2. **Dashboard repair (optional)** — only when the live dashboard is
   stale, call `record repair-dashboard` and confirm the rendered
   dashboard matches the latest evidence.
3. **Closeout post** — call `record close --profile tracking` with the
   linked PR refs and approval. The strict gate enforces required
   checks and merge SHAs.
4. **Read-back** — `record audit --profile tracking --expect-visible`
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

5. **Stop** on any Failure mode code; do not retry blindly.

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
