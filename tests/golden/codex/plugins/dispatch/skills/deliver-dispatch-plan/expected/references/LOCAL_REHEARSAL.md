# Deliver Dispatch Plan Local Rehearsal

Use this playbook only when the user explicitly requests offline rehearsal.

## Contract

- Use `plan-issue record` for local dashboard, comment, dispatch ledger, audit,
  and closeout-gate rehearsal.
- Pass `--state-dir "$STATE_DIR"` or set `PLAN_ISSUE_HOME` so rehearsal
  artifacts stay in the intended runtime root.
- Keep the live branch model: sprint PRs target `PLAN_BRANCH`; the final
  integration PR targets the default branch.

## Commands

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-issue record render-dashboard --profile dispatch --out "$ISSUE_BODY" --state-dir "$STATE_DIR"
plan-issue record build-dispatch-ledger --plan "$PLAN" --strategy auto --default-pr-grouping group --out "$DISPATCH_LEDGER" --state-dir "$STATE_DIR"
plan-issue record render-comment --profile dispatch --kind state --content-file "$DISPATCH_STATE" --out "$STATE_COMMENT" --state-dir "$STATE_DIR"
plan-issue record audit --profile dispatch --body-file "$ISSUE_BODY" --comments-json "$COMMENTS_JSON" --format json --state-dir "$STATE_DIR"
plan-issue record closeout-gate --profile dispatch --body-file "$ISSUE_BODY" --comments-json "$COMMENTS_JSON" --require-session --require-validation --approval "$APPROVAL" --linked-pr "#123" --format json --state-dir "$STATE_DIR"
```

## Exit Criteria

Local rehearsal proves command shape, dashboard/comment rendering, dispatch
ledger generation, audit, and gate behavior. It does not complete production
delivery; live completion still requires provider mutation through `forge-cli`.
