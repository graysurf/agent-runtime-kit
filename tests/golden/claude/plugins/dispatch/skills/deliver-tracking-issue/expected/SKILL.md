---
name: deliver-tracking-issue
description:
  Deliver an issue-backed plan scope through validation, review, PR delivery, issue synchronization, and close readiness gates.
---

# Deliver Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, `forge-cli`, and `review-evidence` are
  installed from released nils-cli packages and available on `PATH`.
- The target issue has recoverable plan/task state and linked source context.
- The delivery branch contains only the intended issue scope.

Inputs:

- Issue number or URL, optional plan path, task/sprint selector, repository
  override, close policy, and validation commands.
- Review evidence or an explicit approval/deferral decision for all findings.

Outputs:

- A pushed branch and PR for the selected issue scope.
- Required checks and review evidence completed before merge.
- Issue task rows or issue-backed state updated with PR, validation, and next
  task status.
- Closeout readiness evidence when the selected scope completes the issue.

Failure modes:

- Issue state is incomplete, stale, or ambiguous.
- Local or remote validation fails.
- Review findings remain unresolved.
- `forge-cli` PR checks, ready, merge, or close operations fail.
- `plan-issue` close or accept gates reject the current task state.

## Entrypoint

Start with the issue and plan gates:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-issue status-plan --issue "$ISSUE" --repo "$OWNER_REPO" --format json
```

Open or deliver the PR through `forge-cli`:

```bash
forge-cli pr deliver \
  --provider github \
  --repo "$OWNER_REPO" \
  --kind feature \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY" \
  --base main \
  --method squash
```

Record review evidence before merge:

```bash
review-evidence init --out "$REVIEW_OUT" --subject "PR #$PR_NUMBER"
review-evidence record-validation --out "$REVIEW_OUT" --command "$COMMAND" --status pass
review-evidence verify --out "$REVIEW_OUT" --format json
```

Synchronize the issue row:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

## Workflow

1. Resolve issue state, plan path, selected task/sprint, and close policy.
2. Validate the plan and current issue status.
3. Implement and validate the selected scope.
4. Create or deliver the PR with `forge-cli`.
5. Run review, record review evidence, and repair concrete findings.
6. Merge only after checks and review evidence pass.
7. Synchronize the issue with `plan-issue link-pr`, `ready-sprint`,
   `accept-sprint`, or `close-plan` as appropriate for the issue contract.
8. Leave the issue open with an exact unblock action if any gate fails.

## Boundary

`plan-issue` owns issue task state and close/accept gates. `forge-cli` owns PR
provider lifecycle. `review-evidence` owns retained review records. The skill
body owns implementation, review judgment, repair decisions, and final status
reporting.
