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
- In live mode, provider auth is available and the local worktree is the
  assigned lane.

Inputs:

- Issue number, task ID, base branch, assigned branch/worktree, PR title, PR
  body file, validation commands, and optional follow-up comment URL.

Outputs:

- A draft or updated PR for the assigned task lane through `forge-cli pr create`
  or `forge-cli pr comment`.
- Review-response evidence recorded through `review-evidence` when responding
  to main-agent comments.
- Issue row synchronized through `plan-issue link-pr`.

Failure modes:

- Assigned lane facts are missing, conflicting, or point outside the approved
  worktree root.
- PR body lacks required sections or still contains placeholders.
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
2. Re-enter the assigned worktree/branch or stop with a blocker if the lane
   facts conflict.
3. Implement only the assigned task scope and run task validation.
4. Validate PR body sections and remove template placeholders.
5. Use `forge-cli pr create` to open the draft PR, or `forge-cli pr comment` to
   respond to review follow-up on the existing PR.
6. Use `plan-issue link-pr` to write the PR reference and in-progress status to
   the owning issue row.
7. Report validation, PR URL, issue sync result, and any blocker back to the
   main agent.

## Boundary

Native `git` owns local worktree mechanics. `forge-cli` owns provider PR
creation and comments. `plan-issue` owns issue row synchronization.
`review-evidence` owns retained review response records. The skill body owns
task-lane judgment, implementation scope, validation, and blocker handoff.
