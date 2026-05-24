---
name: deliver-dispatch-plan
description:
  Deliver a dispatch-ready plan by creating one shared issue-backed plan record, dispatching task lanes, reviewing PRs, and closing through lifecycle gates.
---

# Deliver Dispatch Plan

## Contract

Prereqs:

- `plan-tooling`, `plan-issue >=0.20.0`, `forge-cli`,
  `review-evidence`, and `review-specialists` are available on `PATH`.
- The target repository, default branch, plan bundle, grouping strategy, and
  provider repository slug are known before live mutation.
- The main agent owns orchestration, review, issue synchronization, and final
  integration. Subagents own implementation lanes.

Inputs:

- Plan bundle/path, repository slug, default branch, grouping strategy, and
  optional deterministic `--pr-group` mappings.
- One provider issue opened by `plan-issue record open --profile dispatch`.
- Selected provider issue labels: `type::chore`, one primary `area::`,
  `state::needs-triage`, `workflow::plan`, `workflow::dispatch`, and the
  compatibility `plan` label during rollout.
- `PLAN_BRANCH`, created from the default branch and used as the base for every
  dispatch lane PR.
- Mandatory dispatch bundle per lane: `TASK_PROMPT_PATH`,
  `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`, selected `workflow_role`,
  `PLAN_BRANCH`, and exact plan task context.
- Sprint/lane approval comment URLs, review evidence, final plan approval
  comment URL, and final integration PR ref.
- Optional `--no-closeout` to stop after delivery readiness checks.

Outputs:

- Exactly one provider issue for the whole plan (`1 plan = 1 issue`) opened by
  `plan-issue record open --profile dispatch`.
- Dispatch state, session, validation, and review comments posted through
  `plan-issue record post`.
- Draft lane PRs targeting `PLAN_BRANCH`, with lane status reflected in the
  latest dispatch state/session payload.
- Final close only after lane PRs, final integration PR, approval, issue
  mention, validation, review, and cleanup gates pass.
- When closeout runs, `plan-issue record close --profile dispatch` posts
  closeout evidence, repairs the dashboard, verifies linked PRs, and closes the
  issue.

Failure modes:

- Plan validation, grouping, or lane assignment is ambiguous.
- `PLAN_BRANCH` is missing, stale, or not used as the base for lane PRs.
- A lane lacks the mandatory bundle or changes task-lane facts without explicit
  reassignment.
- Main agent starts implementing lane code instead of routing work to the
  assigned subagent.
- Review evidence, specialist review, provider checks, final integration,
  issue mention, approval, or lifecycle closeout gates fail.

## Entrypoint

Validate the plan and open the shared dispatch record:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-tooling split-prs --file "$PLAN" --scope plan --strategy auto --default-pr-grouping group --format json

plan-issue --repo "$OWNER_REPO" --format json record open \
  --profile dispatch \
  --bundle "$PLAN_BUNDLE" \
  --title "$TITLE" \
  --label type::chore \
  --label area::cli \
  --label state::needs-triage \
  --label workflow::plan \
  --label workflow::dispatch \
  --label plan
```

Replace `area::cli` with the primary `area::` value that matches the plan's
scope. Post dispatch lifecycle updates:

```bash
plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile dispatch \
  --kind state \
  --payload-file "$DISPATCH_STATE_PAYLOAD" \
  --summary-file "$DISPATCH_STATE_MD"

plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --profile dispatch \
  --kind validation \
  --payload-file "$VALIDATION_PAYLOAD" \
  --summary-file "$VALIDATION_MD"

plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"
```

Run closeout inline unless `--no-closeout` was supplied:

```bash
plan-issue --repo "$OWNER_REPO" --format json record close \
  --issue "$ISSUE" \
  --profile dispatch \
  --linked-pr "$OWNER_REPO#$FINAL_PR" \
  --approval "$APPROVAL" \
  --bundle "$PLAN_BUNDLE" \
  --add-label state::closed \
  --remove-label state::needs-triage
```

Use `plan-tooling split-prs` for PR grouping analysis only. Do not create a
`Task Decomposition` issue body for new dispatch plans.

## Workflow

1. Resolve repository, default branch, plan bundle, issue labels, grouping
   strategy, and validation commands.
2. Validate the plan with `plan-tooling`; stop on syntax or grouping ambiguity.
3. Before live issue creation, run `forge-cli label ensure --catalog
   manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json` when the
   catalog exists and label mutation is allowed. Use `label audit` when
   mutation is not allowed; use `--update-existing` only with explicit drift
   repair approval.
4. Open the dispatch record through `plan-issue record open --profile dispatch`.
5. Create `PLAN_BRANCH` from the default branch.
6. For each lane, write a mandatory dispatch bundle and route implementation to
   `execute-dispatch-lane`.
7. Require lane PRs to target `PLAN_BRANCH`; record PR URLs, labels, and status
   in the next dispatch state/session comment.
8. Review lane PRs through `review-dispatch-lane-pr`. Use
   `code-review-specialists` as supplemental read-only evidence when risk
   warrants it, and force `testing` plus `maintainability` for delivery PRs.
9. Append dispatch validation and review comments after each gate; dashboards
   are repaired through `record repair-dashboard`.
10. After all lanes are accepted, open the final integration PR from
   `PLAN_BRANCH` to the default branch and record conformance, required checks,
   and delivery review outcome evidence.
11. Run `record audit --profile dispatch` before final closeout.
12. After final approval, run `record close --profile dispatch` unless
    `--no-closeout` was supplied. Stop on any blocked code and leave the issue
    open with the exact unblock action surfaced by `plan-issue`.
13. If the issue is a lightweight tracking runtime, route to
    `plan-tracking-issue-closeout` instead.

## Boundary

`plan-tooling` owns plan validation, batching, and PR split modeling.
`plan-issue record` owns provider issue creation, lifecycle comments,
dashboard repair, marker audit, strict closeout, linked PR verification, and
issue close. `forge-cli` owns PR lifecycle. `review-evidence` owns retained
review records. `code-review-specialists` is read-only. This skill owns
orchestration judgment, lane assignment, review decisions, issue evidence
completeness, and stop/continue decisions.

## References

- Local rehearsal: `references/LOCAL_REHEARSAL.md`
- Task lane continuity: `references/TASK_LANE_CONTINUITY.md`
- Main-agent review rubric: `references/MAIN_AGENT_REVIEW_RUBRIC.md`
- Post-review outcomes: `references/POST_REVIEW_OUTCOMES.md`
- Dispatch issue record contract: `references/DISPATCH_ISSUE_RECORD_CONTRACT.md`
