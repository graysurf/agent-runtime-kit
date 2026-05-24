---
name: deliver-dispatch-plan
description:
  Deliver a dispatch-ready plan by creating one shared issue-backed plan record, dispatching task lanes, reviewing PRs, and closing through lifecycle gates.
---

# Deliver Dispatch Plan

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, `forge-cli`, `review-evidence`,
  `review-specialists`, and `gh` are available on `PATH`. The lifecycle
  record commands require `plan-issue >=0.17.4`; before release, prepend
  the scoped nils-cli debug binary directory to `PATH`. `gh` is required
  for the chained closeout step because `forge-cli issue view
  --format json` (forge-cli 0.17.6) does not include comments.
- The target repository, default branch, plan file, grouping strategy, and
  provider repository slug are known before live mutation.
- In live mode, provider auth is available and the repository can create or use
  the shared label taxonomy plus the compatibility `plan` label.
- The main agent owns orchestration, review, issue synchronization, and final
  integration. Subagents own implementation lanes.

Inputs:

- Plan path, repository slug, default branch, grouping strategy, and optional
  deterministic `--pr-group` mappings.
- One provider issue number after `forge-cli issue create` succeeds.
- Selected provider issue labels: `type::chore`, one primary `area::`,
  `state::needs-triage`, `workflow::plan`, `workflow::dispatch`, and the
  compatibility `plan` label during rollout.
- `PLAN_BRANCH`, created from the default branch and used as the base for every
  dispatch lane PR.
- Mandatory dispatch bundle per assigned lane:
  `TASK_PROMPT_PATH`, `PLAN_SNAPSHOT_PATH`, `DISPATCH_RECORD_PATH`, selected
  `workflow_role`, `PLAN_BRANCH`, and exact plan task context.
- Sprint/lane approval comment URLs, review evidence, and final plan approval
  comment URL.
- Optional `--no-closeout` to stop the workflow after delivery readiness checks
  and before any chained closeout. Use when closeout is owned by a separate
  downstream skill invocation or by a human reviewer. Does not bypass the
  final integration PR or any lane merge; PR delivery still completes.

Outputs:

- Exactly one provider issue for the whole plan (`1 plan = 1 issue`) whose body
  uses the same shared dashboard shape as lightweight tracking issues.
- Source, plan, dispatch ledger, state, session, validation, review, and
  closeout comments rendered through `plan-issue record`.
- Dispatch ledger table with task, owner/subagent, branch, worktree,
  execution-mode, PR group, PR, status, validation, review, and notes columns.
- Draft lane PRs targeting `PLAN_BRANCH`, with lane status reflected in the
  latest dispatch state/session comments.
- Final close only after lane PRs, final integration PR, approval, issue
  mention, validation, review, and cleanup gates pass.
- When chained closeout runs (default, unless `--no-closeout` was supplied
  or any closeout gate rejects): a closed provider issue, a rendered
  dispatch closeout comment, and a final dashboard repaired to link the
  closeout comment URL.

Failure modes:

- Plan validation, grouping, or dispatch ledger generation is ambiguous.
- `PLAN_BRANCH` is missing, stale, or not used as the base for lane PRs.
- A lane lacks the mandatory bundle or changes task-lane facts without explicit
  reassignment.
- Main agent starts implementing lane code instead of routing work to the
  assigned subagent.
- Review evidence, specialist review, provider checks, final integration,
  issue mention, approval, or lifecycle closeout gates fail.

## Entrypoint

Validate the plan and render the shared dashboard:

```bash
plan-tooling validate --file "$PLAN" --format text --explain

plan-issue record render-dashboard \
  --profile dispatch \
  --status in-progress \
  --target-scope "$TARGET_SCOPE" \
  --current "$CURRENT_GATE" \
  --next-action "$NEXT_ACTION" \
  --validation pending \
  --approval pending \
  --title "$TITLE" \
  --out "$ISSUE_BODY"
```

Render the dispatch ledger and lifecycle comments:

```bash
plan-issue record build-dispatch-ledger \
  --plan "$PLAN" \
  --strategy auto \
  --default-pr-grouping group \
  --out "$DISPATCH_LEDGER"

plan-issue record render-comment --profile dispatch --kind plan \
  --path "$PLAN" \
  --commit "$(git rev-parse HEAD)" \
  --content-file "$PLAN" \
  --out "$PLAN_COMMENT"

plan-issue record render-comment --profile dispatch --kind state \
  --content-file "$DISPATCH_STATE" \
  --out "$STATE_COMMENT"
```

Create the provider issue and post records through `forge-cli`:

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
  --label workflow::dispatch \
  --label plan \
  --format json

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$PLAN_COMMENT" --format json
forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$STATE_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$UPDATED_DASHBOARD" --format json
```

Run the chained closeout inline (default, unless `--no-closeout`).
Fetch the body + comments through `gh` because `forge-cli issue view
--format json` omits comments under forge-cli 0.17.6:

```bash
gh issue view "$ISSUE" --repo "$OWNER_REPO" --json body,comments >"$ISSUE_COMMENTS_JSON"
jq -r .body "$ISSUE_COMMENTS_JSON" >"$ISSUE_BODY"

plan-issue record closeout-gate \
  --profile dispatch \
  --body-file "$ISSUE_BODY" \
  --comments-json "$ISSUE_COMMENTS_JSON" \
  --require-complete \
  --require-session \
  --require-validation \
  --require-review \
  --approval "$APPROVAL" \
  --linked-pr "#$FINAL_PR" \
  --format json

plan-issue record render-comment --profile dispatch --kind closeout \
  --content-file "$CLOSEOUT_MD" --out "$CLOSEOUT_COMMENT"

forge-cli issue comment "$ISSUE" --repo "$OWNER_REPO" --body-file "$CLOSEOUT_COMMENT" --format json
forge-cli issue edit "$ISSUE" --repo "$OWNER_REPO" --body-file "$FINAL_DASHBOARD" --format json
forge-cli issue close "$ISSUE" --repo "$OWNER_REPO" --format json
```

Use `plan-tooling split-prs` for PR grouping analysis only. Do not create a
`Task Decomposition` issue body for new dispatch plans.

## Workflow

1. Resolve repository, default branch, plan path, issue labels, grouping
   strategy, and validation commands.
2. Validate the plan with `plan-tooling`; stop on syntax or grouping ambiguity.
3. Render the shared dashboard, source snapshot, plan snapshot, dispatch ledger,
   and initial dispatch state through `plan-issue record`.
4. Before live issue creation, run `forge-cli label ensure --catalog
   manifests/forge-labels.yaml --repo "$OWNER_REPO" --format json` when the
   catalog exists and label mutation is allowed. Use `label audit` when
   mutation is not allowed; use `--update-existing` only with explicit drift
   repair approval.
5. Create one provider issue through `forge-cli`, post the comments, then
   re-render/edit the dashboard with exact durable-record URLs.
6. Create `PLAN_BRANCH` from the default branch.
7. For each lane, write a mandatory dispatch bundle and route implementation to
   `execute-dispatch-lane`.
8. Require lane PRs to target `PLAN_BRANCH`; record PR URLs, labels, and status in the
   next dispatch state/session comment.
9. Review lane PRs through `review-dispatch-lane-pr`. Use
   `code-review-specialists` as supplemental read-only evidence when risk
   warrants it, and force `testing` plus `maintainability` for delivery PRs.
10. Append dispatch validation and review comments after each gate; dashboard
   edits should only summarize and link durable comments.
11. After all lanes are accepted, open the final integration PR from
    `PLAN_BRANCH` to the default branch and record conformance, required checks,
    and delivery review outcome evidence.
12. Run `plan-issue record audit --profile dispatch` and
    `plan-issue record closeout-gate --profile dispatch` before closeout.
13. After final approval, run the chained closeout inline unless
    `--no-closeout` was supplied. The sequence mirrors
    `dispatch-plan-closeout` exactly: re-fetch the latest issue body and
    comments through `gh issue view --json body,comments` (forge-cli
    0.17.6's `issue view --format json` does not include comments), run
    `plan-issue record closeout-gate --profile dispatch --require-complete
    --require-session --require-validation --require-review --approval
    "$APPROVAL" --linked-pr "#$FINAL_PR"`, render a closeout comment
    through `plan-issue record render-comment --profile dispatch
    --kind closeout`, post the closeout comment
    through `forge-cli issue comment`, repair the final dashboard through
    `forge-cli issue edit`, then close the issue through `forge-cli
    issue close` (no `--reason`; forge-cli 0.17.6 rejects it). Stop the
    chain on any step failure, leave the issue open with the exact
    unblock action surfaced by the failing step, and recommend rerunning
    `dispatch-plan-closeout` directly to diagnose or complete. If the
    issue is a lightweight tracking runtime, route to
    `plan-tracking-issue-closeout` instead.

## Boundary

`plan-tooling` owns plan validation, batching, and PR split modeling only.
`plan-issue record` owns dashboard/comment rendering, dispatch ledger
generation, marker audit, and closeout-gate evidence. `forge-cli` owns provider
issue and PR lifecycle. `review-evidence` owns retained review records.
`code-review-specialists` is read-only. This skill owns orchestration judgment,
lane assignment, review decisions, issue evidence completeness, and stop/continue
decisions.

The chained closeout in Step 13 reuses the same `plan-issue record
closeout-gate`, `plan-issue record render-comment --kind closeout`, and
`forge-cli issue close` calls that `dispatch-plan-closeout` wraps; that
skill remains the canonical reference for the sequence and the recovery
surface when chaining fails or when `--no-closeout` is supplied. The
boundary does not move: `plan-issue record` still owns gate evaluation
and marker rendering, and `forge-cli` still owns the provider close call.

## References

- Local rehearsal: `references/LOCAL_REHEARSAL.md`
- Task lane continuity: `references/TASK_LANE_CONTINUITY.md`
- Main-agent review rubric: `references/MAIN_AGENT_REVIEW_RUBRIC.md`
- Post-review outcomes: `references/POST_REVIEW_OUTCOMES.md`
- Dispatch issue record contract: `references/DISPATCH_ISSUE_RECORD_CONTRACT.md`
