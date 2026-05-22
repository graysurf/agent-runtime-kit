# Dispatch Issue Closeout Local Rehearsal

Use this playbook only when the user explicitly asks for offline rehearsal.

## Commands

```bash
plan-issue-local status-plan --body-file "$ISSUE_BODY" --no-comment --format json --state-dir "$STATE_DIR"
plan-issue-local link-pr --body-file "$ISSUE_BODY" --task "$TASK_ID" --pr "#123" --status in-progress --dry-run --format json --state-dir "$STATE_DIR"
plan-issue ready-plan --body-file "$ISSUE_BODY" --dry-run --summary-file "$SUMMARY" --format json --state-dir "$STATE_DIR"
plan-issue close-plan --body-file "$ISSUE_BODY" --dry-run --approved-comment-url "$APPROVAL_URL" --format json --state-dir "$STATE_DIR"
```

## Exit Criteria

Rehearsal success means command shape and close gates were exercised against a
local body file. Production completion still requires live
`plan-issue close-plan --issue "$ISSUE"`.
