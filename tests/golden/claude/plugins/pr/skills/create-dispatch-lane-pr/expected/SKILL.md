---
name: create-dispatch-lane-pr
description:
  Create a dispatch-lane pull / merge request with `forge-cli pr create` after a plan issue assigns the lane (GitHub PR or GitLab MR; provider auto-detected from the cwd remote or `--repo`).
---

# Create Dispatch Lane PR

## Purpose

Create one provider PR (GitHub) or MR (GitLab) for an assigned dispatch
lane through `forge-cli pr create`. The skill never writes plan-issue
lifecycle comments directly; lane progress is reported by the calling
dispatch skill via `plan-issue tracking checkpoint`.

## When to use

- A dispatch lane has been assigned by `deliver-dispatch-plan` or
  `execute-dispatch-lane` with a branch, base PLAN_BRANCH, task scope,
  body content, and validation evidence on hand.
- The PR/MR does not yet exist (use `forge-cli pr update` for existing
  ones — outside this skill's scope).

## Inputs

- `OWNER_REPO`, `BRANCH`, `BASE` (assigned `PLAN_BRANCH`).
- Lane `TASK_ID` and the body content (typically rendered from the lane
  task scope).
- `RUN_STATE` path so the skill can record the resulting PR ref.

## Preflight

- `forge-cli` is on `PATH`.
- The branch exists locally and has been pushed.
- `BASE` is the dispatch `PLAN_BRANCH`, not the repository default.

## Allowed lifecycle roles

- None directly on the plan issue. The PR / MR is created and its
  reference is returned for the calling dispatch skill to record through
  `plan-issue tracking run update --linked-pr ...`.

## Forbidden actions

- No plan-issue lifecycle comments (no `record post`, no `tracking
  checkpoint`, no raw `gh issue comment`).
- No selecting or expanding lane scope; that decision lives in
  `deliver-dispatch-plan` and `execute-dispatch-lane`.
- No targeting the repository default branch when a `PLAN_BRANCH` is
  assigned.
- No bypass of `forge-cli pr create`.

## CLI flow

```bash
forge-cli pr create \
  --repo "$OWNER_REPO" \
  --base "$BASE" \
  --head "$BRANCH" \
  --title "$LANE_TITLE" \
  --body-file "$LANE_BODY" \
  --format json
```

The calling dispatch skill records the PR ref back into the run state:

```bash
plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --linked-pr "$OWNER_REPO#$PR_NUMBER"
```

## Evidence requirements

- `forge-cli pr create` returns the PR URL and number.
- The PR base matches the assigned `PLAN_BRANCH`.
- The dispatch run state captures the new PR ref before the next
  checkpoint posts.

## Stop conditions

- `forge-cli pr create` fails (auth, branch missing, wrong base) — surface
  and stop.
- The branch is unpushed or behind the base — push or rebase before
  retry; do not paper over.
- The body file is missing or empty — return for body assembly before
  creating the PR.

## Validation

- `forge-cli pr create` exits 0 with `pr_url` and `pr_number` in the JSON
  envelope.
- Subsequent `plan-issue tracking status --profile dispatch` reflects the
  new lane PR ref.

## Boundary

`forge-cli pr create` owns the provider PR / MR creation. The dispatch
skill that calls this helper owns scope selection, body content, and
lifecycle reporting through `plan-issue tracking`.
