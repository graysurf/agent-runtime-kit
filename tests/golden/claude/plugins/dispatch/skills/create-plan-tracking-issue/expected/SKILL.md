---
name: create-plan-tracking-issue
description:
  Open or preview one lightweight issue-backed plan tracker with frozen source / plan snapshots and an initial state checkpoint.
---

# Create Plan Tracking Issue

## Contract

Prereqs:

- Profile: `tracking`.
- CLI floors: `plan-issue >=1.0.1`, `plan-tooling >=1.0.1` — the release that
  writes the tracking issue URL into execution-state on open.
  `forge-cli` is not required by this skill.
- Bundle precondition: a complete plan bundle already exists at
  `docs/plans/<YYYY-MM-DD>-<slug>/` — `<slug>-plan.md`,
  `<slug>-execution-state.md`, and a `<slug>-discussion-source.md` (or
  `<slug>-review-source.md`). This skill opens a tracker from that bundle; it
  does not assemble it. The `*-source.md` may have started as a
  `docs/discussions/<YYYY-MM-DD>-<slug>.md` capture promoted into the bundle
  (moved in and renamed, original retired) when the work graduated to L2 — see
  `discussion-to-implementation-doc`.
- Issue precondition: the tracking issue does not exist yet (or the
  bundle was just revised and `record attach` is the right call).
- Run state precondition: no `run-state.json` for this bundle yet — the
  skill may initialize one after a successful live open.
- Shared family rules from the Plan Issue Skill Family
  spec apply (see the Shared Family Rules section in
  core/skills/dispatch/plan-issue-spec/).

Inputs:

- `OWNER_REPO` — provider repository slug.
- `PLAN_BUNDLE` — absolute path to the assembled
  `docs/plans/<YYYY-MM-DD>-<slug>/` bundle directory.
- `PLAN` — path to `<slug>-plan.md` inside the bundle.
- `SLUG`, `TITLE` — bundle slug for canonical-path checks and the issue
  title.
- Selected labels from the shared taxonomy: `type::chore`, one primary
  `area::*`, `state::needs-triage`, `workflow::plan`,
  `workflow::tracking`. Projects that maintain a non-taxonomy rollout
  marker (e.g. a bare `plan` label) may add it as an extra
  `--label` — it is project-local, not part of the shared catalog.
- **GitLab scoped-label exclusivity:** GitLab keeps only one label per
  `key::` scope, so applying both `workflow::plan` and `workflow::tracking`
  silently drops the first — no warning, and a later `assert create` fails
  with `label missing: workflow::plan` (graysurf/plan-tracking-testbed#58).
  On GitLab apply only the lifecycle value `workflow::tracking` and use a
  bare `plan` label as the rollout marker. GitHub treats `::` labels as
  independent names, so keep both there — the board's `Plan-tracking` lane
  selects on `workflow::plan`.
- Optional explicit source / plan / execution-state paths when bundle
  discovery is not enough.

Outputs:

- `record open --profile tracking` posts the `source`, `plan`, and
  initial `state` lifecycle comments and opens the provider issue.
- Optional `tracking run init` writes `run-state.json` and
  `events.jsonl` under the issue runtime root, recording `run_started`.
- After a live open, `record open` writes the live tracking issue URL into the
  bundle's `<slug>-execution-state.md` `- Tracking issue:` bullet (reported
  under `execution_state_sync`) so the durable state matches run-state and
  `plan-archive discover` can infer the provider ref offline. Commit the
  patched bundle before continuing.
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
plan-tooling validate --file "$PLAN" --format text --explain

# The --label set below is the GitHub form (both workflow:: labels survive).
# On GitLab, scoped labels are mutually exclusive per scope: pass only
# workflow::tracking here plus a bare 'plan' label, or workflow::plan is
# silently dropped (graysurf/plan-tracking-testbed#58).
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

1. **Preflight** — confirm the bundle is complete at canonical paths, is
   committed and pushed, and `plan-tooling validate` is green. The
   `*-source.md` must already be inside the bundle: if the work started as a
   `docs/discussions/` capture, promote it first via
   `discussion-to-implementation-doc` (move it in as
   `<slug>-discussion-source.md`, retire the `docs/discussions/` original).
   This skill never pulls a source from outside the bundle.

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
   live with the chosen labels. `record open` is idempotent: re-running
   for the same bundle resumes the existing tracker (matched by the
   source snapshot identity — repo-relative path + last-commit SHA) and
   attaches only the missing lifecycle comments instead of opening a
   duplicate, so a partial open is safe to retry from the same cwd.
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

- Upstream: `discussion-to-implementation-doc` produces the bundle's
  `*-source.md` — born in the bundle for L2, or promoted from a
  `docs/discussions/` capture when the work graduates to L2.
- Downstream: `execute-plan-tracking-issue` consumes the issue URL and
  optional `run-state.json` produced here.
- Family rules: Plan Issue Skill Family, Shared Family
  Rules section (under core/skills/dispatch/plan-issue-spec/).
