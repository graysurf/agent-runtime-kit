---
name: create-plan-tracking-issue
description:
  Create or preview a lightweight issue-backed plan tracker with the shared dashboard and append-only lifecycle comments.
---

# Create Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, and `forge-cli` are available on `PATH`.
  The lifecycle record commands require
  `plan-issue >=0.17.7`; before release, prepend the scoped nils-cli debug
  binary directory to `PATH`.
- Run from the target git repository root unless an explicit repository or plan
  path is supplied.
- The source markdown and plan markdown are both committed and pushed to a
  remote (any branch is acceptable) so their commit SHAs resolve for anyone
  reading the issue. A URL-only source or an explicit plan-only waiver can
  substitute for the source artifact, but the plan markdown itself must always
  be committed and pushed.
- Existing plan bundles have a valid `Read First` section.
- Live provider mutation is done through `forge-cli`. `plan-issue record`
  renders/audits markdown only; `plan-tooling` validates and models the plan.

Inputs:

- Plan markdown path, source markdown path when different, provider repository
  slug, title, labels, and dry-run/live mode.
- Selected issue labels from the shared taxonomy. Plan-tracking issues use
  `type::chore`, one primary `area::`, `state::needs-triage`,
  `workflow::plan`, and `workflow::tracking`, plus the compatibility `plan`
  label during rollout.
- Optional paths for rendered dashboard and source/plan/state comment bodies.

Outputs:

- A compact mutable issue dashboard with `Current Dashboard`, `Durable Record`,
  `Guardrails`, and `Original Tracker` sections matching the existing
  plan-tracking issue format.
- Append-only source, plan, and initial state comments rendered with the
  compatibility marker family used by issue #43.
- A live provider issue in live mode, or deterministic artifacts in dry-run
  mode.

Failure modes:

- Plan validation fails, the source or plan markdown is uncommitted or
  unpushed to a remote, or the source/plan comments cannot be rendered.
- Quality review of the source or plan markdown surfaces blocking findings
  (unclear scope, missing or shallow `Read First`, incoherent grouping,
  obvious gaps) and the caller cannot resolve them before issue creation.
- Provider auth, repository resolution, issue creation, comment creation, or
  dashboard edit fails.
- The issue body drifts from the dashboard/comment record after creation.

## Entrypoint

Validate the bundle before provider mutation:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
```

Render the initial dashboard and lifecycle comments:

```bash
plan-issue record render-dashboard \
  --profile tracking \
  --status in-progress \
  --target-scope "$TARGET_SCOPE" \
  --current "$CURRENT_TASK" \
  --next-action "$NEXT_ACTION" \
  --validation pending \
  --approval pending \
  --title "$TITLE" \
  --out "$ISSUE_BODY"

plan-issue record render-comment \
  --profile tracking \
  --kind source \
  --path "$SOURCE" \
  --commit "$(git rev-parse HEAD)" \
  --content-file "$SOURCE" \
  --out "$SOURCE_COMMENT"

plan-issue record render-comment \
  --profile tracking \
  --kind plan \
  --path "$PLAN" \
  --commit "$(git rev-parse HEAD)" \
  --content-file "$PLAN" \
  --out "$PLAN_COMMENT"
```

Create and finalize the provider issue:

```bash
forge-cli issue create \
  --provider github \
  --repo "$OWNER_REPO" \
  --title "$TITLE" \
  --body-file "$ISSUE_BODY" \
  --label type::chore \
  --label area::docs \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::tracking \
  --label plan \
  --format json

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$SOURCE_COMMENT" --format json
forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$PLAN_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$UPDATED_DASHBOARD" --format json
```

Use `forge-cli --dry-run` and `plan-issue record ... --out <path>` for local
preview. Do not use `plan-issue start-plan` for lightweight tracking issues.

## Workflow

1. Resolve the plan, source, repository, title, labels, and output directory.
2. Confirm the source markdown (when present) and plan markdown are committed
   and pushed to a remote; stop and request a commit/push if either SHA cannot
   be resolved remotely.
3. Run `plan-tooling validate`; stop on plan syntax, source, or grouping
   errors.
4. Quality-review the source and plan markdown before they are immortalized in
   the issue. The main agent assesses scope clarity, `Read First`
   completeness, grouping coherence, and obvious gaps. Blocking findings must
   be fixed (with re-commit and re-push) before proceeding; ambiguous or
   high-impact findings stop and ask the user instead of being silently
   patched.
5. Render the initial tracking dashboard with pending durable-record links.
6. Render source, plan, and initial state comments through
   `plan-issue record render-comment --profile tracking --kind <source|plan|state>`.
   The rendered marker family is `plan-issue-record:v2`; the retired
   `--marker-family compat` / `shared` flags are not accepted by
   `plan-issue >=0.17.7`.
7. Before live issue creation, run `forge-cli label ensure --catalog
   manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json` when the
   catalog exists and label mutation is allowed. Use `label audit` when
   mutation is not allowed; use `--update-existing` only with explicit drift
   repair approval.
8. In live mode, create the issue through `forge-cli issue create`, post the
   rendered comments, then re-render/edit the dashboard with exact comment URLs.
9. Run `plan-issue record audit --profile tracking` against the issue body and
   comments. Record the issue URL and snapshot URLs in the execution state.

## Boundary

`plan-tooling` owns plan validation, batching, and split modeling only.
`plan-issue record` owns deterministic dashboard/comment rendering and marker
audit. `forge-cli` owns provider issue create/comment/edit calls. The skill
body owns source readiness, live-vs-dry-run judgment, and issue record
completeness.
