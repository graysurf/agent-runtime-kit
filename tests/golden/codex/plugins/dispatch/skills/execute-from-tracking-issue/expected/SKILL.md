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
- Issue contract classification: lightweight plan-tracking issue, or
  heavyweight dispatch/`plan-issue` runtime.

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

## Issue Contract Selection

- Lightweight plan-tracking issues use append-only markers:
  - `<!-- plan-tracking-issue:snapshot:v1 kind=source -->`
  - `<!-- plan-tracking-issue:snapshot:v1 kind=plan -->`
  - `<!-- execute-from-tracking-issue:state:v1 -->`
  - `<!-- execute-from-tracking-issue:session:v1 -->`
  - `<!-- execute-from-tracking-issue:validation:v1 -->`
- The lightweight mutable body is only the dashboard; the latest valid
  `execute-from-tracking-issue:state:v1` comment is the durable task ledger.
- Heavyweight dispatch issues use `Task Decomposition` rows plus
  `deliver-dispatch-plan:*` markers. Route whole-plan/sprint orchestration to
  `deliver-dispatch-plan` and closeout to `dispatch-issue-closeout`.
- Do not mix marker families in one issue. If a lightweight issue is being
  promoted to dispatch, create or prepare a new dispatch issue through the
  dispatch workflow instead of rewriting the existing ledger in place.

## Workflow

1. Read the issue dashboard, latest issue state, and plan snapshot.
2. Validate the local or issue-hosted plan with `plan-tooling`.
3. Classify the issue contract before edits. Use `plan-issue status-plan` for
   dispatch task rows; otherwise recover the lightweight snapshots and latest
   `execute-from-tracking-issue:state:v1` ledger.
4. For lightweight issues, initialize or update the issue-backed state comment
   before code edits; keep the canonical ledger columns
   `ID | Status | Task | Evidence | Notes`.
5. Implement only the selected task/sprint scope.
6. Run required validation and deterministic acceptance before PR delivery.
7. Create or update the PR through `forge-cli`, then synchronize the issue with
   `plan-issue link-pr` when task rows are present.
8. For lightweight issues, post session and validation comments with the marker
   lines above and update the body dashboard to link latest evidence.
9. Before PR merge, auto-close, closeout, or final success reporting, confirm
   the latest lightweight state is `complete` with done/deferred rows and
   validation/PR evidence; for dispatch issues, use the `plan-issue` gates.

## Boundary

`plan-tooling` owns plan parsing and validation. `plan-issue` owns task-row
state when the issue follows the Task Decomposition contract. `forge-cli` owns
provider PR lifecycle. The skill body owns scope selection, implementation
judgment, validation interpretation, and handoff decisions.
