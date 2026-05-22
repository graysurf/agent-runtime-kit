---
name: dispatch-subagent-pr
description:
  Execute an assigned dispatch task lane, open or update its PR through forge-cli, and synchronize the owning plan issue row.
---

# Dispatch Subagent PR

## Contract

Prereqs:

- `forge-cli`, `plan-issue`, and `review-evidence` are installed from released
  nils-cli packages and available on `PATH`.
- The caller has assigned task-lane facts: issue, task ID, owner, branch,
  worktree, execution mode, base branch, and PR state.
- When dispatched by `deliver-dispatch-plan`, the lane includes
  `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`,
  `workflow_role=implementation`, exact plan task context, and `PLAN_BRANCH`.
- In live mode, provider auth is available and the local worktree is the
  assigned lane.

Inputs:

- Issue number, task ID, base branch, assigned branch/worktree, PR title, PR
  body file, validation commands, and optional follow-up comment URL.
- Dispatch record facts for lane continuity: owner, branch, worktree,
  execution mode, current PR, `workflow_role`, and optional runtime-role
  fallback rationale.

Outputs:

- A draft or updated PR for the assigned task lane through `forge-cli pr create`
  or `forge-cli pr comment`.
- Review-response evidence recorded through `review-evidence` when responding
  to main-agent comments.
- Issue row synchronized through `plan-issue link-pr`.
- A blocker packet when required context is missing or conflicting, preserving
  the current task-lane facts.

Failure modes:

- Assigned lane facts are missing, conflicting, or point outside the approved
  worktree root.
- Dispatch record is missing required artifact paths, or declares a non-
  implementation `workflow_role`.
- PR body lacks required sections `## Summary`, `## Scope`, `## Testing`,
  `## Test plan`, and `## Issue`, or still contains placeholders.
- PR base branch differs from the assigned base branch; in dispatch-plan mode
  this must be `PLAN_BRANCH`.
- Local validation fails.
- `forge-cli` PR creation/comment operations fail.
- `plan-issue link-pr` cannot update the selected task row.

## Entrypoint

Open a task-lane PR:

```bash
forge-cli pr create \
  --provider github \
  --repo "$OWNER_REPO" \
  --kind feature \
  --base "$BASE_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY" \
  --format json
```

`forge-cli pr create` opens drafts by default; add `--no-draft` only when the
lane is explicitly ready for immediate review.

Synchronize the owning issue row:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

Respond to review follow-up:

```bash
review-evidence init --out "$REVIEW_OUT" --subject "PR #$PR_NUMBER follow-up"
forge-cli pr comment "$PR_NUMBER" \
  --provider github \
  --repo "$OWNER_REPO" \
  --body-file "$RESPONSE_BODY" \
  --format json
```

## Workflow

1. Confirm assigned task-lane facts from the issue row and main-agent handoff.
2. If the issue came from `deliver-dispatch-plan`, verify the mandatory bundle:
   `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`,
   `workflow_role=implementation`, `PLAN_BRANCH`, and exact task context.
3. Re-enter the assigned worktree/branch and existing PR when present. Create
   lane artifacts only when they do not exist yet or main-agent explicitly
   reassigned the lane.
4. If required context is missing or conflicting, stop with a blocker packet
   instead of inventing replacement lane facts.
5. Implement only the assigned task scope and run task validation. For
   production behavior changes, capture failing-test evidence or an explicit
   waiver before editing production behavior.
6. Validate PR body sections `## Summary`, `## Scope`, `## Testing`,
   `## Test plan`, and `## Issue`; remove placeholders such as `TBD`, `TODO`,
   `<...>`, and `#<number>`.
7. Use `forge-cli pr create` to open the draft PR against the assigned base, or
   `forge-cli pr comment` to respond to review follow-up on the existing PR.
8. Use `plan-issue link-pr` to write the PR reference and in-progress or
   blocked status to the owning issue row.
9. Report validation, PR URL, issue sync result, lane facts, and any blocker
   back to the main agent.

## Boundary

Native `git` owns local worktree mechanics. `forge-cli` owns provider PR
creation and comments. `plan-issue` owns issue row synchronization.
`review-evidence` owns retained review response records. The skill body owns
task-lane judgment, implementation scope, validation, and blocker handoff.

## References

- Task lane continuity:
  `skills/dispatch/deliver-dispatch-plan/references/TASK_LANE_CONTINUITY.md`
