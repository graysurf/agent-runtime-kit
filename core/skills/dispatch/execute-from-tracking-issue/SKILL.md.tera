---
name: execute-from-tracking-issue
description:
  Resume issue-backed plan execution from issue-hosted state while using plan-issue and plan-tooling for durable planning surfaces.
---

# Execute From Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, `plan-issue-local`, and `forge-cli` are
  installed from released nils-cli packages and available on `PATH`.
- The issue has source/plan snapshots or a `plan-issue` Task Decomposition
  body that can be inspected before edits.
- Repository preflight and dirty-tree triage have passed.

Inputs:

- Issue number or URL, optional repository override, plan path, task/sprint
  selector, branch name, and validation scope.
- Existing state comment or task decomposition row that identifies current
  work, next work, blockers, and validation expectations.

Outputs:

- A scoped implementation branch and PR for the selected issue-backed task or
  sprint.
- Updated issue state through `plan-issue` task rows or issue-backed comments,
  depending on the issue contract in use.
- Validation evidence, PR links, and next-task status recorded on the issue.

Failure modes:

- The issue lacks recoverable source/plan/task state.
- The selected task is ambiguous or conflicts with existing issue status.
- Required validation fails and cannot be repaired within scope.
- Provider PR operations through `forge-cli` fail.

## Entrypoint

Inspect plan and issue state before edits:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-issue status-plan --issue "$ISSUE" --repo "$OWNER_REPO" --format json
```

For local rehearsals or issue-body fixtures:

```bash
plan-issue-local build-task-spec \
  --plan "$PLAN" \
  --sprint "$SPRINT" \
  --strategy auto \
  --format json
```

Link the delivery PR after it is opened:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

Use `forge-cli pr create`, `forge-cli pr checks`, and `forge-cli pr deliver`
for provider PR lifecycle steps.

## Workflow

1. Read the issue dashboard, latest issue state, and plan snapshot.
2. Validate the local or issue-hosted plan with `plan-tooling`.
3. Use `plan-issue status-plan` when the issue has task rows; otherwise keep
   the issue-backed state comment as the durable ledger and record the selected
   scope explicitly.
4. Implement only the selected task/sprint scope.
5. Run required validation and deterministic acceptance before PR delivery.
6. Create or update the PR through `forge-cli`, then synchronize the issue with
   `plan-issue link-pr` when task rows are present.
7. Post validation/session evidence and repair the issue dashboard before
   handoff or close.

## Boundary

`plan-tooling` owns plan parsing and validation. `plan-issue` owns task-row
state when the issue follows the Task Decomposition contract. `forge-cli` owns
provider PR lifecycle. The skill body owns scope selection, implementation
judgment, validation interpretation, and handoff decisions.
