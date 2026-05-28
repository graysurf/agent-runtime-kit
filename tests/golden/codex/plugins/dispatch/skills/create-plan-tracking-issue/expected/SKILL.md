---
name: create-plan-tracking-issue
description:
  Open or preview one lightweight issue-backed plan tracker with frozen source / plan snapshots and an initial state checkpoint.
---

# Create Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=0.22.3`, `plan-tooling`. `forge-cli` is not
  required by this skill.
- Issue precondition: the tracking issue does not exist yet (or the
  bundle was just revised and `record attach` is the right call).
- Run state precondition: no `run-state.json` for this bundle yet — the
  skill may initialize one after a successful live open.
- Shared family rules from the Plan Issue Skill Family Redesign V1
  spec apply (see the Shared Family Rules section in
  docs/source/plan-issue-redesign/).

Inputs:

- `OWNER_REPO` — provider repository slug.
- `PLAN_BUNDLE` — absolute path to the bundle directory.
- `PLAN` — path to `<slug>-plan.md` inside the bundle.
- `SLUG`, `TITLE` — bundle slug for canonical-path checks and the issue
  title.
- Selected labels from the shared taxonomy: `type::chore`, one primary
  `area::*`, `state::needs-triage`, `workflow::plan`,
  `workflow::tracking`. Projects that maintain a non-taxonomy rollout
  marker (e.g. a bare `plan` label) may add it as an extra
  `--label` — it is project-local, not part of the shared catalog.
- Optional explicit source / plan / execution-state paths when bundle
  discovery is not enough.

Outputs:

- `record open --profile tracking` posts the `source`, `plan`, and
  initial `state` lifecycle comments and opens the provider issue.
- Optional `tracking run init` writes `run-state.json` and
  `events.jsonl` under the issue runtime root, recording `run_started`.
- No PR / MR creation.

Failure modes:

- Forbidden lifecycle roles for this skill: `state` / `session` /
  `validation` / `review` / `closeout` posts after the initial open.
  Direct posts of these roles abort with `forbidden-role-for-skill`.
- Refusal codes propagated: visible-completeness codes
  (`state-missing-task-ledger`, `source-missing-snapshot`, …) returned
  by `record audit --expect-visible`.
- A missing execution-state file is a hard stop — `record open` would
  otherwise emit an empty task ledger.
- Scope-leak: writing into an unrelated existing issue, or skipping the
  `plan-tooling validate` gate.

## Entrypoint

```bash
# Run every plan-issue command from the bundle's git toplevel — the
# CLI uses the cwd's repo for source / plan commit verification.
cd "$(git -C "$PLAN_BUNDLE" rev-parse --show-toplevel)"

plan-tooling validate --file "$PLAN" --format text --explain

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

Replace `area::docs` with the primary `area::` value that matches the
plan's scope. Append project-local rollout labels (e.g. `--label
plan`) only when the target repo declares them.

## Workflow

1. **Preflight** — confirm all three bundle files exist at canonical
   paths, are committed and pushed, and `plan-tooling validate` is
   green:

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

2. **Scope decision** — confirm the dry-run preview is the expected
   open shape; obtain explicit user approval for live mutation.
3. **Lifecycle checkpoint** — run `record open --profile tracking`
   live with the chosen labels.
4. **Optional run-state bootstrap** — run `tracking run init` so the
   next skill has a typed local run state.
5. **Read-back** — confirm `source`, `plan`, and `state` markers via
   `record audit --expect-visible`:

   ```bash
   gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments \
     >"$ISSUE_JSON"
   jq -r .body "$ISSUE_JSON" >"$ISSUE_BODY"
   plan-issue --format json record audit \
     --profile tracking \
     --body-file "$ISSUE_BODY" \
     --comments-json "$ISSUE_JSON" \
     --expect-visible
   ```

6. **Stop** on any Failure mode code; do not paper over a Profile-only
   state comment (re-run `record open` after fixing the
   execution-state Markdown).

## Boundary

Owns:

- The decision to open (or attach) the tracking issue.
- Label selection for the new issue.
- The dry-run / live judgement and the read-back integrity check.

Does not own:

- `state` / `session` / `validation` progress posting — that is
  `execute-plan-tracking-issue`.
- Closeout and `record close` — that is
  `plan-tracking-issue-closeout`.
- PR work — that is the active PR delivery skill.
- Plan bundle validation mechanics — that is `plan-tooling`.

Cross-references:

- Downstream: `execute-plan-tracking-issue` consumes the issue URL and
  optional `run-state.json` produced here.
- Family rules: Plan Issue Skill Family Redesign V1, Shared Family
  Rules section (under docs/source/plan-issue-redesign/).
