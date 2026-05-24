# Dispatch Plan Closeout Local Rehearsal

Use this playbook only when the user explicitly asks for offline rehearsal.

## Commands

```bash
plan-issue --format json --state-dir "$STATE_DIR" record audit --profile dispatch --body-file "$ISSUE_BODY" --comments-json "$COMMENTS_JSON"
plan-issue --repo "$OWNER_REPO" --dry-run --format json --state-dir "$STATE_DIR" record close --issue "$ISSUE" --profile dispatch --approval "$APPROVAL" --linked-pr "$OWNER_REPO#$FINAL_PR" --bundle "$PLAN_BUNDLE"
plan-issue --repo "$OWNER_REPO" --dry-run --format json --state-dir "$STATE_DIR" record repair-dashboard --issue "$ISSUE"
```

## Exit Criteria

Rehearsal success means audit, closeout command shape, and dashboard repair
were exercised against local body/comment artifacts. Production completion uses
live provider mutation through `plan-issue record close`.
