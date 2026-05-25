---
name: create-plan-tracking-issue
description:
  Create or preview a lightweight issue-backed plan tracker with the shared dashboard and append-only lifecycle comments.
---

# Create Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling` and `plan-issue >=0.22.3` are available on `PATH`.
  `plan-issue >=0.22.3` is required because it renders lifecycle comments with
  visible evidence instead of Profile-only bodies.
- Run from the target git repository root unless explicit repository and plan
  paths are supplied.
- The source, plan, and execution-state markdown files exist on disk at the
  canonical bundle paths (`<slug>-discussion-source.md` or
  `<slug>-review-source.md`, `<slug>-plan.md`, `<slug>-execution-state.md`),
  are committed, and are pushed so the issue snapshots resolve to a traceable
  commit SHA. `plan-tooling validate` confirms the bundle pointers but does
  not require the referenced execution-state file to be physically present,
  so the skill body verifies file existence before `record open` to keep the
  initial state comment from rendering with an empty task ledger.
- Existing plan bundles have a valid `Read First` section.
- `plan-issue record` owns the issue-backed lifecycle. Do not compose
  lifecycle issues through generic `forge-cli issue` primitives.

Inputs:

- Plan bundle directory, provider repository slug, title, and dry-run/live mode.
- Selected issue labels from the shared taxonomy. Plan-tracking issues use
  `type::chore`, one primary `area::`, `state::needs-triage`,
  `workflow::plan`, and `workflow::tracking`, plus the compatibility `plan`
  label during rollout.
- Optional explicit source, plan, and execution-state paths when bundle
  discovery is not sufficient.

Outputs:

- A provider issue opened by `plan-issue record open` in live mode, or a
  deterministic preview in dry-run mode.
- Append-only source, plan, and initial state comments carrying
  `plan-issue-record:v2` markers. The initial state comment must visibly
  include `## Execution State` and `## Task Ledger`; because it is non-final,
  the Task Ledger rows should be folded under `<details>` by default.
- A mutable dashboard repaired by `plan-issue` after the initial comments are
  available.

Failure modes:

- Plan validation fails, required bundle files are missing, or local files are
  uncommitted/unpushed and no explicit waiver is acceptable.
- Quality review of source or plan markdown surfaces blocking findings.
- Provider auth, repository resolution, issue creation, comment posting, or
  dashboard repair fails inside `plan-issue record open`.
- A read-back audit cannot recognize the source, plan, and state lifecycle
  comments, or the state comment is only a profile/header plus hidden payload
  instead of visible execution-state evidence.

## Entrypoint

Verify all three bundle files exist before provider mutation. The plan and
execution-state files are mandatory; at least one source file
(`<slug>-discussion-source.md` or `<slug>-review-source.md`) must be present.

```bash
test -f "$PLAN_BUNDLE/$SLUG-plan.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-plan.md" >&2; exit 1; }
test -f "$PLAN_BUNDLE/$SLUG-execution-state.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-execution-state.md (record open will surface an empty task ledger if this file is absent — create it before continuing)" >&2; exit 1; }
test -f "$PLAN_BUNDLE/$SLUG-discussion-source.md" \
  || test -f "$PLAN_BUNDLE/$SLUG-review-source.md" \
  || { echo "missing $PLAN_BUNDLE/$SLUG-{discussion,review}-source.md" >&2; exit 1; }
```

Validate the bundle before provider mutation:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
```

Preview or open the tracking issue through the v3 record owner:

```bash
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
```

Replace `area::docs` with the primary `area::` value that matches the plan's
scope. After live creation, read back the issue and audit the recorded
lifecycle:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_JSON"
jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"

plan-issue --format json record audit \
  --profile tracking \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_JSON" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::tracking \
  --label plan
```

## Workflow

1. Resolve the bundle, repository, title, labels, and output directory.
2. Confirm all three bundle files exist on disk at the canonical paths
   (source, plan, execution-state) and then confirm they are committed and
   pushed. If any file is missing, stop and request creation before
   `record open` runs; a missing execution-state file causes the initial
   state comment to render without the issue-visible Task Ledger that humans
   need for review. If commit/push is the only blocker, the user may accept
   `--allow-dirty` for a preview.
3. Run `plan-tooling validate`; stop on plan syntax, source, or grouping errors.
4. Quality-review the source and plan markdown before they are immortalized in
   the issue.
5. Before live issue creation, run `forge-cli label ensure --catalog
   manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json` when the
   catalog exists and label mutation is allowed. Use `label audit` when
   mutation is not allowed; use `--update-existing` only with explicit drift
   repair approval.
6. Run `plan-issue record open --dry-run` and inspect the JSON preview.
7. In live mode, run `plan-issue record open`; record the issue URL and comment
   URLs in the local execution state.
8. Run `record audit` against the live body/comments and verify source, plan,
   and state markers are recognized.
9. Read back the state comment body and reject Profile-only output: it must
   visibly contain `## Execution State`, `## Task Ledger`, and a hidden
   `plan-issue-record-payload` carrier. Non-final tracking comments should
   fold the Task Ledger rows with `<details>` so the issue timeline stays
   readable.

## Boundary

`plan-tooling` owns plan validation, batching, and split modeling.
`plan-issue record` owns issue-backed provider creation, lifecycle comments,
dashboard repair, and marker audit. The skill body owns source readiness,
live-vs-dry-run judgment, and issue record completeness.
