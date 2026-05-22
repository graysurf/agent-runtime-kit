---
name: deliver-dispatch-plan
description:
  Deliver a dispatch-ready plan by creating one plan issue, dispatching sprint task lanes, enforcing review and acceptance gates, and closing the plan through plan-issue.
---

# Deliver Dispatch Plan

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, `plan-issue-local`, `forge-cli`,
  `review-evidence`, and `review-specialists` are installed from released
  nils-cli packages and available on `PATH`.
- The target repository, default branch, plan file, and provider repository
  slug are known before live mutation.
- In live mode, provider auth is available and the repository can create or use
  the `issue` and `plan` labels.
- The main agent owns orchestration, review, issue synchronization, and final
  integration. Subagents own implementation lanes.

Inputs:

- Plan path, repository slug, default branch, grouping strategy, and optional
  deterministic `--pr-group` mappings.
- One plan issue number after `start-plan` succeeds.
- `PLAN_BRANCH`, created from the default branch and used as the base for every
  sprint lane PR.
- Sprint number, sprint approval comment URL, and final plan approval comment
  URL.
- Mandatory dispatch bundle per assigned lane:
  `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`, selected
  `workflow_role`, `PLAN_BRANCH`, and exact plan task context.
- Final integration PR from `PLAN_BRANCH` to the default branch, plus
  conformance, required-check, delivery-outcome, and issue-mention evidence.

Outputs:

- Exactly one provider issue for the whole plan (`1 plan = 1 issue`) with a
  `Task Decomposition` table as runtime truth.
- Issue-hosted source and plan snapshots, plus dispatch state/session/
  validation/closeout checkpoints using `deliver-dispatch-plan:*` markers.
- Sprint task specs, subagent prompt artifacts, and dispatch records generated
  from issue/runtime truth.
- Draft sprint lane PRs targeting `PLAN_BRANCH`, linked back through
  `plan-issue link-pr`.
- Main-agent review evidence for sprint PR decisions and final integration.
- Final close through `plan-issue close-plan` only after sprint PRs, final
  integration PR, approval, issue mention, conformance, checks, and cleanup
  gates pass.

Failure modes:

- Plan validation, grouping, or task decomposition is ambiguous.
- `PLAN_BRANCH` is missing, stale, or not used as the base for sprint PRs.
- A dispatch lane lacks the mandatory bundle or changes task-lane facts without
  explicit reassignment.
- Main agent starts implementing task-lane code instead of routing work to the
  assigned subagent.
- Review evidence, specialist review, provider checks, sprint acceptance, final
  integration, issue mention, or close gates fail.
- Local runtime artifacts are missing or provider issue state cannot be
  recovered from issue-hosted records.

## Entrypoint

Validate the plan and create one plan issue:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-issue start-plan \
  --plan "$PLAN" \
  --repo "$OWNER_REPO" \
  --strategy auto \
  --default-pr-grouping group \
  --format json
```

Start a sprint and emit dispatch artifacts:

```bash
plan-issue start-sprint \
  --plan "$PLAN" \
  --repo "$OWNER_REPO" \
  --issue "$ISSUE" \
  --sprint "$SPRINT" \
  --strategy auto \
  --default-pr-grouping group \
  --subagent-prompts-out "$SPRINT_ROOT/prompts" \
  --format json
```

Synchronize sprint PRs and gates:

```bash
plan-issue link-pr --issue "$ISSUE" --repo "$OWNER_REPO" --task "$TASK_ID" --pr "#$PR_NUMBER" --status in-progress --format json
plan-issue ready-sprint --plan "$PLAN" --issue "$ISSUE" --repo "$OWNER_REPO" --sprint "$SPRINT" --format json
plan-issue accept-sprint --plan "$PLAN" --issue "$ISSUE" --repo "$OWNER_REPO" --sprint "$SPRINT" --approved-comment-url "$SPRINT_APPROVAL_URL" --format json
```

Close the plan after final integration:

```bash
plan-issue ready-plan --issue "$ISSUE" --repo "$OWNER_REPO" --summary-file "$PLAN_REVIEW_SUMMARY" --format json
plan-issue close-plan --issue "$ISSUE" --repo "$OWNER_REPO" --approved-comment-url "$PLAN_APPROVAL_URL" --format json
```

Use `plan-issue-local` only for explicit offline rehearsal; see
`references/LOCAL_REHEARSAL.md`.

## Workflow

1. Resolve repository, default branch, plan path, issue labels, grouping
   strategy, and validation commands.
2. Validate the plan with `plan-tooling`; stop on plan syntax or grouping
   ambiguity.
3. Run `plan-issue start-plan` to create or prepare one plan issue. Persist the
   issue number and `PLAN_BRANCH`.
4. Verify issue-hosted source and plan snapshots. Keep `Task Decomposition` as
   runtime truth; dispatch checkpoints are derived evidence.
5. For each sprint, run `start-sprint` only after the previous sprint is
   accepted and synchronized.
6. Dispatch subagents with the full lane bundle. Ad-hoc prompts that omit
   `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`, task
   context, or `PLAN_BRANCH` are invalid.
7. Require lane PRs to target `PLAN_BRANCH`; open them through
   `create-dispatch-lane-pr` or `dispatch-subagent-pr`, then synchronize rows
   with `plan-issue link-pr`.
8. Review sprint PRs through `dispatch-pr-review`. Use
   `code-review-specialists` as supplemental read-only evidence when risk
   warrants it, and force `testing` plus `maintainability` for delivery PRs.
9. Run `ready-sprint` before merge decisions and `accept-sprint` only after the
   sprint PRs are merged into `PLAN_BRANCH`.
10. After the final sprint, open a final integration PR from `PLAN_BRANCH` to
    the default branch. Before merge, record plan conformance, required checks,
    and a delivery review outcome comment URL.
11. Post or verify a plan-issue comment that mentions the final integration PR.
12. Run `ready-plan`, then `close-plan` with the final approval comment URL.
13. Verify one `deliver-dispatch-plan:closeout:v1` checkpoint, current dashboard
    links, worktree cleanup, and local branch synchronization.

## Boundary

`plan-tooling` owns plan parsing. `plan-issue` owns the issue task table,
sprint gates, plan gates, comments, and close operation. `forge-cli` owns
provider PR lifecycle. `review-evidence` owns retained review records.
`code-review-specialists` is read-only. This skill owns orchestration judgment,
lane assignment, review decisions, issue evidence completeness, final
integration readiness, and stop/continue decisions.

## References

- Local rehearsal: `references/LOCAL_REHEARSAL.md`
- Task lane continuity: `references/TASK_LANE_CONTINUITY.md`
- Main-agent review rubric: `references/MAIN_AGENT_REVIEW_RUBRIC.md`
- Post-review outcomes: `references/POST_REVIEW_OUTCOMES.md`
- Dispatch issue record contract: `references/DISPATCH_ISSUE_RECORD_CONTRACT.md`
