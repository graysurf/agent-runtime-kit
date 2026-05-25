---
name: create-plan-tracking-issue
description:
  Create or preview a lightweight issue-backed plan tracker with the shared dashboard and append-only lifecycle comments.
---

# Create Plan Tracking Issue

## Purpose

Open one lightweight plan-tracking issue from a validated local plan bundle.
The skill freezes the source and plan documents as immutable snapshots and
posts an initial `state` comment so the issue timeline is useful from the
first commit. Lifecycle mechanics belong to `plan-issue record` and
`plan-issue tracking`; this skill owns scope readiness and live-vs-dry-run
judgment.

## When to use

- A new plan bundle (`<slug>-discussion-source.md` or
  `<slug>-review-source.md`, `<slug>-plan.md`,
  `<slug>-execution-state.md`) is ready and the user wants the issue
  opened, or wants a deterministic preview before going live.
- An existing issue must be re-attached with v2 lifecycle evidence after a
  bundle revision (use `record attach` rather than re-opening).

## Inputs

- `PLAN_BUNDLE` — absolute path to the bundle directory.
- `PLAN` — path to the plan markdown (usually `$PLAN_BUNDLE/<slug>-plan.md`).
- `OWNER_REPO` — provider repository slug.
- `TITLE` — issue title.
- Selected labels from the shared taxonomy:
  `type::chore`, one primary `area::`, `state::needs-triage`,
  `workflow::plan`, `workflow::tracking`, plus the rollout `plan` label.
- Optional explicit source / plan / execution-state paths when bundle
  discovery is not enough.

## Preflight

- `plan-tooling` and `plan-issue >=0.22.3` are available on `PATH`.
- Run from the target git repository root unless an explicit repo and plan
  path are supplied.
- All three bundle files exist on disk at the canonical paths and are
  committed and pushed so the snapshot resolves to a traceable commit SHA.
  A missing execution-state file is a hard stop — `record open` would
  otherwise emit an empty task ledger.

```bash
test -f "$PLAN_BUNDLE/$SLUG-plan.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-plan.md" >&2; exit 1; }
test -f "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-execution-state.md" >&2; exit 1; }
test -f "$PLAN_BUNDLE/$SLUG-discussion-source.md" \
  || test -f "$PLAN_BUNDLE/$SLUG-review-source.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-{discussion,review}-source.md" >&2; exit 1; }
plan-tooling validate --file "$PLAN" --format text --explain
```

## Allowed lifecycle roles

- `source` and `plan` snapshots through `record open --profile tracking`
  (or `record attach` against an existing issue).
- Initial `state` comment through the same `record open` flow.
- Optional `plan-issue tracking run init` after live creation to persist a
  typed local run state for the next skill in the family.

## Forbidden actions

- No `record post --kind state|session|validation|review`. Progress
  belongs to `execute-plan-tracking-issue`.
- No `record close` and no closeout comment.
- No raw `gh issue comment`, `glab issue note`, or `forge-cli issue
  comment` for lifecycle evidence.
- No PR creation or update.
- No skipping the `plan-tooling validate` gate.
- No live `record open` against a dirty bundle without an explicit
  `--allow-dirty` waiver in the user instruction.

## CLI flow

```bash
plan-tooling validate --file "$PLAN" --format text --explain

plan-issue --repo "$OWNER_REPO" --format json --dry-run record open \
  --profile tracking \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::tracking \
  --label plan

plan-issue --repo "$OWNER_REPO" --format json record open \
  --profile tracking \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::tracking \
  --label plan

plan-issue --format json tracking run init \
  --provider-repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --bundle "$PLAN_BUNDLE" \
  --execution-state-file "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  --branch "$BRANCH"
```

Replace `area::docs` with the primary `area::` value that matches the
plan's scope.

## Evidence requirements

- The `record open` result envelope names the issue URL and the source,
  plan, and state comment URLs.
- A `record audit --expect-visible` against the live body and comments
  recognizes `source`, `plan`, and `state` markers, and reports no
  visible-completeness findings.
- `tracking run init` writes `run-state.json` and `events.jsonl` under the
  issue runtime root, recording `run_started`.

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON" \
  --expect-visible
```

## Stop conditions

- Bundle file missing, dirty without waiver, or `plan-tooling validate`
  reports errors — fix the bundle before any provider mutation.
- Quality review of source or plan markdown surfaces blocking findings —
  stop and request edits.
- `record audit --expect-visible` reports a missing role or any
  visible-completeness code — investigate before declaring success.
- The state comment is Profile-only (only the role heading and
  `- Profile: tracking` line) — treat as failure and rerun
  `record open` after fixing the execution-state Markdown.

## Validation

- `plan-tooling validate --file "$PLAN" --format text --explain` is green.
- `plan-issue record open --dry-run` returns a deterministic preview.
- Live `record open` returns issue + comment URLs.
- `plan-issue record audit --profile tracking --body-file "$ISSUE_BODY"
  --comments-json "$ISSUE_JSON" --expect-visible` shows recognized
  source/plan/state markers and an empty `visible.codes` list.

## Boundary

`plan-tooling` owns plan validation. `plan-issue record` owns lifecycle
comment rendering and dashboard repair. `plan-issue tracking` owns local
run state and FSM reconciliation. This skill owns scope readiness,
labels, dry-run / live decisions, and the read-back integrity check.
