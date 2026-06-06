---
name: create-plan-tracking-issue
description:
  Open or preview one lightweight issue-backed plan tracker with frozen source / plan snapshots and an initial state checkpoint.
---

# Create Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=1.0.11`, `plan-tooling >=1.0.1`.
  `forge-cli` is not required by this skill.
- A complete, committed plan bundle exists at
  `docs/plans/<YYYY-MM-DD>-<slug>/` with `<slug>-plan.md`,
  `<slug>-execution-state.md`, and either
  `<slug>-discussion-source.md` or `<slug>-review-source.md`.
- No live tracker exists for the bundle unless the explicit decision is
  to attach/repair that same bundle.
- Shared family rules apply from
  `core/skills/dispatch/plan-issue-spec/skill-family.md`.

Inputs:

- `OWNER_REPO`, `PLAN_BUNDLE`, `PLAN`, `SLUG`, `TITLE`.
- One primary taxonomy label set. GitHub uses `workflow::plan` plus
  `workflow::tracking`; GitLab uses only `workflow::tracking` plus a
  bare `plan` rollout marker because scoped labels collapse per
  `key::` scope.
- Optional explicit source / plan / execution-state paths only when
  bundle discovery is insufficient.

Outputs:

- `record open --profile tracking` posts `source`, `plan`, and initial
  `state`, opens or attaches the provider issue, and writes the issue URL
  back to `<slug>-execution-state.md`.
- Optional `tracking run init` creates `run-state.json` and `events.jsonl`
  for the next skill.
- No PR / MR creation and no progress, validation, review, or closeout
  lifecycle posts.

Failure modes:

- Stop when bundle files are missing, `plan-tooling validate` fails, the
  dry-run shape is not the intended issue, or live mutation lacks explicit
  approval.
- Stop on visible audit failures such as `state-missing-task-ledger` or
  `source-missing-snapshot`.
- Stop on provider payload privacy failures such as `local_path_present`; rewrite
  useful evidence paths to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.
- Stop on wrong-provider label shape: on GitLab, do not pass both
  `workflow::plan` and `workflow::tracking`.
- Forbidden writes: progress `state`, `session`, `validation`, `review`,
  `closeout`, PR work, or writes into an unrelated existing issue.

## Entrypoint

```bash
plan-tooling validate --file "$PLAN" --format text --explain

# GitHub label form. For GitLab, drop workflow::plan and add --label plan.
plan-issue --repo "$OWNER_REPO" --format json --dry-run record open \
  --profile tracking \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::tracking

plan-issue --repo "$OWNER_REPO" --format json record open \
  --profile tracking \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::tracking

plan-issue --format json tracking run init \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --bundle "$PLAN_BUNDLE" \
  --execution-state-file "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --branch "$BRANCH" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Replace `area::docs` with the plan's primary `area::` label. Add
project-local rollout labels only when the target repo declares them.

## Workflow

1. **Preflight** — confirm the canonical bundle files exist and
   `plan-tooling validate` passes.
2. **Provider branch** — choose the label set:
   - GitHub: `workflow::plan` + `workflow::tracking`.
   - GitLab: `workflow::tracking` + bare `plan`; never both
     `workflow::*` labels.
3. **Dry-run decision** — run `record open --dry-run`; continue only
   when the issue body, lifecycle comments, labels, and target repo are
   correct and live mutation is approved.
4. **Live open / attach** — run `record open --profile tracking`. Commit
   the execution-state URL sync before moving to execution.
5. **Optional branch** — run `tracking run init` only when the next step
   will resume through run state.
6. **Read-back** — audit the live issue with
   `record audit --profile tracking --expect-visible`. Stop on any
   failure code instead of repairing by hand.

## Boundary

Owns:

- The open-vs-attach decision for one validated bundle.
- Provider label selection and live-open approval.
- The initial read-back integrity check.

Must not:

- Assemble the bundle, implement tasks, post progress, create PRs, or close
  the issue.

Handoff:

- Upstream bundle source: `discussion-to-implementation-doc`.
- Downstream execution: `execute-plan-tracking-issue`.
- Closeout: `plan-tracking-issue-closeout`.
