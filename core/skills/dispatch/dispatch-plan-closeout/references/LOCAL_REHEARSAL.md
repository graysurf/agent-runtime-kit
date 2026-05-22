# Dispatch Plan Closeout Local Rehearsal

Use this playbook only when the user explicitly asks for offline rehearsal.

## Commands

```bash
plan-issue record audit --profile dispatch --body-file "$ISSUE_BODY" --comments-json "$COMMENTS_JSON" --format json --state-dir "$STATE_DIR"
plan-issue record closeout-gate --profile dispatch --body-file "$ISSUE_BODY" --comments-json "$COMMENTS_JSON" --require-complete --require-session --require-validation --require-review --approval "$APPROVAL" --linked-pr "#123" --format json --state-dir "$STATE_DIR"
plan-issue record render-comment --profile dispatch --marker-family shared --kind closeout --content-file "$CLOSEOUT_MD" --out "$CLOSEOUT_COMMENT" --state-dir "$STATE_DIR"
plan-issue record render-dashboard --profile dispatch --status complete --closeout-url "$CLOSEOUT_URL" --out "$FINAL_DASHBOARD" --state-dir "$STATE_DIR"
```

## Exit Criteria

Rehearsal success means audit, closeout gates, closeout comment rendering, and
final dashboard rendering were exercised against local body/comment artifacts.
Production completion still requires live provider mutation through `forge-cli`.
