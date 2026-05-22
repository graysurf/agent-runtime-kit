---
name: issue-lifecycle
description:
  Maintain plan issue task rows, sprint status, PR links, and review readiness through the released plan-issue command surface.
---

# Issue Lifecycle

## Contract

Prereqs:

- `plan-issue` and `plan-issue-local` are installed from the released nils-cli
  package and available on `PATH`.
- The issue body follows the `plan-issue` task decomposition contract, or the
  caller supplies an offline issue body file for rehearsal.
- Live mutations require provider auth and a confirmed repository target.

Inputs:

- Plan issue number or offline issue body path.
- Optional plan path, sprint number, task ID, PR group, PR reference, review
  summary, and state directory.
- Status transitions: planned, in-progress, blocked, ready-for-review,
  accepted, or closed according to the `plan-issue` command being invoked.

Outputs:

- Machine-readable status snapshots from `plan-issue status-plan`.
- Issue task rows updated with PR references and runtime status.
- Sprint-ready, sprint-accepted, or plan-ready comments when requested.
- Deterministic local artifacts when using `--body-file` or `--dry-run`.

Failure modes:

- The issue body lacks a valid Task Decomposition table.
- A sprint/task/PR group selector matches no rows or multiple ambiguous rows.
- A close or accept gate fails because tasks are not done, PR references are
  missing, required approval is absent, or linked PRs are not merged.
- Live provider auth or issue mutation fails.

## Entrypoint

Inspect issue state:

```bash
plan-issue status-plan \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --format json
```

Link a PR to a task or sprint lane:

```bash
plan-issue link-pr \
  --issue "$ISSUE" \
  --repo "$OWNER_REPO" \
  --task "$TASK_ID" \
  --pr "#$PR_NUMBER" \
  --status in-progress \
  --format json
```

Prepare and accept sprint checkpoints:

```bash
plan-issue ready-sprint --plan "$PLAN" --issue "$ISSUE" --sprint "$SPRINT"
plan-issue accept-sprint \
  --plan "$PLAN" \
  --issue "$ISSUE" \
  --sprint "$SPRINT" \
  --approved-comment-url "$APPROVAL_URL"
```

Use `--body-file <path> --dry-run` whenever rehearsing the transition or
validating a fixture without live provider writes.

## Workflow

1. Run `plan-issue status-plan` to read the current task-row truth.
2. Choose the narrowest selector: task ID first, then sprint plus PR group when
   the work is a shared lane.
3. Use `plan-issue link-pr` immediately after opening or reusing a PR so the
   issue timeline and task row agree.
4. Use `ready-sprint` only after local validation and task-lane evidence exist.
5. Use `accept-sprint` only after review approval and merged PR gates pass.
6. Record status JSON, comments, PR links, and approval URLs in the linked
   session or validation evidence.

## Boundary

`plan-issue` owns task-row parsing, PR-link synchronization, sprint checkpoint
comments, and close/accept gates. The skill body owns lifecycle judgment,
selector choice, review interpretation, and whether a failed gate is a blocker
or a repair loop.
