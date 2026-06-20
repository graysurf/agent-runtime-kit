---
name: create-dispatch-lane-pr
description: >
  Create one provider PR / MR for an assigned dispatch lane through forge-cli pr create. Returns the PR ref for the caller's tracking run update; never posts plan-issue lifecycle comments.
---

# Create Dispatch Lane PR

## Contract

Prereqs:

- Profile: helper (no plan-issue profile attached; the caller carries
  the dispatch profile).
- CLI floors: `forge-cli >=1.11.2`.
- Shared provider and branch rules in
  `core/skills/pr/pr-lifecycle/README.md` are satisfied.
- Lane precondition: the lane has an assigned `BRANCH` (pushed),
  `BASE` (`PLAN_BRANCH`), `TASK_ID`, and ready body content.
- Run state precondition: a dispatch `run-state.json` exists for the
  shared dispatch issue; the caller will record the PR ref via
  `tracking run update --linked-pr`.
- Shared family rules from the Plan Issue Skill Family
  spec apply (see the Shared Family Rules section in
  core/skills/dispatch/plan-issue-spec/).

Inputs:

- `OWNER_REPO`, `BRANCH`, `BASE` (assigned `PLAN_BRANCH`).
- Lane `TASK_ID`, `LANE_TITLE`, and `LANE_BODY` (path to body content,
  typically rendered from the lane task scope).
- `RUN_STATE` path so the calling dispatch skill can record the
  resulting PR ref.

Outputs:

- `forge-cli pr create` returns `pr_url` and `pr_number` in the JSON
  envelope.
- The PR base matches the assigned `PLAN_BRANCH`.
- No plan-issue lifecycle role posts. The PR ref is returned for the
  calling dispatch skill to record through `plan-issue tracking run
  update --linked-pr "$OWNER_REPO#$PR_NUMBER"`.

Failure modes:

- Forbidden lifecycle roles for this skill: every plan-issue lifecycle
  role — direct posts of any of them abort with
  `forbidden-role-for-skill`. The skill must not call `record post`,
  `tracking checkpoint`, `gh issue comment`, `glab issue note`, or
  `forge-cli issue comment`.
- `forge-cli pr create` failures: auth, missing branch, wrong base,
  unpushed branch — surface and stop.
- `local_path_present`: rewrite useful evidence paths in provider-visible PR
  content to `$HOME/...` and omit remote-useless local artifact paths before
  retrying.
- Scope-leak: selecting or expanding lane scope (that lives in
  `deliver-dispatch-plan` / `execute-dispatch-lane`); targeting the
  repository default branch when a `PLAN_BRANCH` is assigned;
  bypassing `forge-cli pr create`.

## Entrypoint

```bash
forge-cli pr create \
  --repo "$OWNER_REPO" \
  --base "$BASE" \
  --head "$BRANCH" \
  --title "$LANE_TITLE" \
  --body-file "$LANE_BODY" \
  --test-first-evidence "$EVIDENCE_DIR" \
  --format json
```

When the lane is a `--kind feature` / `bug` record and the test-first gate is
enabled (`[test_first].require = true` in a repo `.forge-cli.toml` or the
user-global `${XDG_CONFIG_HOME:-~/.config}/forge-cli/config.toml`), pass
`--test-first-evidence "$EVIDENCE_DIR"` — the `verify`-clean directory the
`test-first-evidence` skill produces — or the create fails closed with
`test_first_evidence_required`. Omit it for the exempt kinds (`docs` / `chore` /
`ci` / `refactor`).

The calling dispatch skill then records the PR ref back into the run
state:

```bash
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --linked-pr "$OWNER_REPO#$PR_NUMBER" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## Workflow

1. **Preflight** — confirm `BASE` is the dispatch `PLAN_BRANCH`,
   `BRANCH` is pushed, and `LANE_BODY` is non-empty.
2. **Create PR** — call `forge-cli pr create` with the assigned base
   and head. Capture `pr_url` and `pr_number` from the JSON envelope.
3. **Return** — surface `OWNER_REPO#$PR_NUMBER` to the caller. The
   skill itself does not write run state.
4. **Read-back (by caller)** — the calling dispatch skill records the
   PR ref via `tracking run update --linked-pr` and then verifies
   `tracking status --profile dispatch` reflects the new ref.
5. **Stop** on any Failure mode code; do not paper over an unpushed
   branch or empty body file.

## Boundary

Owns:

- Provider PR / MR creation for one assigned dispatch lane.

Does not own:

- Lane scope selection — `deliver-dispatch-plan` /
  `execute-dispatch-lane`.
- Lifecycle comment posting on the plan issue — the calling dispatch
  skill via `plan-issue tracking`.
- Updates to the run state — the calling dispatch skill.
- PR / MR review or merge — `forge-cli` and the active PR delivery
  skills.

Cross-references:

- Upstream: `execute-dispatch-lane` (and occasionally
  `deliver-dispatch-plan`) call this helper.
- Downstream: the calling dispatch skill records the PR ref through
  `tracking run update --linked-pr`.
- Family rules: Plan Issue Skill Family, Shared Family
  Rules section (under core/skills/dispatch/plan-issue-spec/).
- PR/MR rules: `core/skills/pr/pr-lifecycle/README.md`.
