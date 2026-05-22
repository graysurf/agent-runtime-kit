---
name: execute-dispatch-lane
description:
  Execute an assigned dispatch task lane, open or update its PR through forge-cli, and report lane state back to the shared dispatch issue record.
---

# Execute Dispatch Lane

## Contract

Prereqs:

- `forge-cli`, `plan-issue`, and `review-evidence` are available on `PATH`.
  Dispatch lifecycle comment rendering requires `plan-issue >=0.17.4`; before
  release, prepend the scoped nils-cli debug binary directory to `PATH`.
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
- Path to a dispatch state/session markdown update prepared for the main issue.

Outputs:

- A draft or updated PR for the assigned task lane through `forge-cli pr create`
  or `forge-cli pr comment`.
- Review-response evidence recorded through `review-evidence` when responding
  to main-agent comments.
- A dispatch session or state comment body rendered through
  `plan-issue record render-comment --profile dispatch`.
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
- Local validation fails, provider PR operations fail, or the lane state update
  cannot be rendered.

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

Render the issue-visible lane update:

```bash
plan-issue record render-comment \
  --profile dispatch \
  --marker-family shared \
  --kind session \
  --content-file "$LANE_SESSION_MD" \
  --out "$LANE_SESSION_COMMENT"

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$LANE_SESSION_COMMENT" --format json
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

1. Confirm assigned task-lane facts from the dispatch ledger and main-agent
   handoff.
2. Verify the mandatory bundle: `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`,
   `DISPATCH_RECORD_PATH`, `workflow_role=implementation`, `PLAN_BRANCH`, and
   exact task context.
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
8. Render a dispatch session/state comment that records PR URL, validation,
   lane facts, and any blocker. Post it to the owning issue through
   `forge-cli issue comment`.
9. Report validation, PR URL, issue comment URL, lane facts, and any blocker
   back to the main agent.

## Boundary

Native `git` owns local worktree mechanics. `forge-cli` owns provider PR
creation and comments. `plan-issue record` owns dispatch comment rendering.
`review-evidence` owns retained review response records. The skill body owns
task-lane judgment, implementation scope, validation, and blocker handoff.

## References

- Task lane continuity:
  `skills/dispatch/deliver-dispatch-plan/references/TASK_LANE_CONTINUITY.md`
