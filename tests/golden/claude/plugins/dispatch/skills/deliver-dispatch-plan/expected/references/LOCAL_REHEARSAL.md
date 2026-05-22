# Deliver Dispatch Plan Local Rehearsal

Use this playbook only when the user explicitly requests offline rehearsal.

## Contract

- Use `plan-issue-local` for local sprint orchestration.
- Use `plan-issue --dry-run --body-file ...` for plan-level ready/close gate
  checks.
- Pass `--state-dir "$STATE_DIR"` or set `PLAN_ISSUE_HOME` so rehearsal
  artifacts stay in the intended runtime root.
- Keep the live branch model: sprint PRs target `PLAN_BRANCH`; the final
  integration PR targets the default branch.

## Commands

```bash
plan-tooling validate --file "$PLAN" --format text --explain
plan-issue-local start-plan --plan "$PLAN" --dry-run --format json --state-dir "$STATE_DIR"
plan-issue-local start-sprint --plan "$PLAN" --issue 999 --sprint "$SPRINT" --dry-run --format json --state-dir "$STATE_DIR"
plan-issue-local link-pr --body-file "$ISSUE_BODY" --task "$TASK_ID" --pr "#123" --status in-progress --dry-run --format json --state-dir "$STATE_DIR"
plan-issue-local status-plan --body-file "$ISSUE_BODY" --no-comment --format json --state-dir "$STATE_DIR"
plan-issue ready-plan --body-file "$ISSUE_BODY" --dry-run --summary-file "$SUMMARY" --format json --state-dir "$STATE_DIR"
plan-issue close-plan --body-file "$ISSUE_BODY" --dry-run --approved-comment-url "$APPROVAL_URL" --format json --state-dir "$STATE_DIR"
```

## Exit Criteria

Local rehearsal proves command shape, issue body parsing, and gate behavior. It
does not complete production delivery; live completion still requires
`plan-issue close-plan --issue "$ISSUE"`.
