#!/usr/bin/env bash
# Deterministic probes for Plan 05 dispatch skills.
# shellcheck disable=SC2329

set -euo pipefail

: "${REPO_ROOT:?}"
: "${SCRIPT_DIR:?}"
: "${TMP_ROOT:?}"
: "${ARTIFACTS_DIR:?}"
: "${RESULTS_FILE:?}"

# shellcheck disable=SC1091
# shellcheck source=tests/runtime-smoke/lib/results.sh
. "$SCRIPT_DIR/lib/results.sh"

DISPATCH_ARTIFACTS_DIR="$ARTIFACTS_DIR/dispatch"
DISPATCH_WORKSPACE="$TMP_ROOT/workspaces/dispatch-basic-repo"
DISPATCH_STATE_DIR="$TMP_ROOT/state/plan-issue"
MINI_PLAN="$DISPATCH_ARTIFACTS_DIR/runtime-smoke-mini-plan.md"
PLAN_BODY_PATH=""
PLAN_TASK_SPEC_PATH=""
COMMENTS_JSON_PATH=""

mkdir -p "$DISPATCH_ARTIFACTS_DIR" "$DISPATCH_STATE_DIR" "$TMP_ROOT/workspaces"
cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$DISPATCH_WORKSPACE"

require_dispatch_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke dispatch: required binary not on PATH: $bin" >&2
    return 1
  fi
}

record_case() {
  local id="$1"
  local note="$2"
  shift 2

  if "$@"; then
    results_add "$id" "shared-cli" "pass" "1" "$note"
    return 0
  fi

  results_add "$id" "shared-cli" "fail" "0" "$note"
  return 1
}

init_pushed_branch_fixture() {
  local workspace="$1"
  local branch="$2"
  local remote_url="$3"
  local base_tree base_commit tree commit

  git -C "$workspace" init -q
  git -C "$workspace" config user.email runtime-smoke@example.invalid
  git -C "$workspace" config user.name "Runtime Smoke"
  printf 'runtime-smoke dispatch base\n' >"$workspace/dispatch-base.txt"
  git -C "$workspace" add .
  base_tree="$(git -C "$workspace" write-tree)"
  base_commit="$(printf 'runtime-smoke dispatch base\n' | git -C "$workspace" commit-tree "$base_tree")"
  git -C "$workspace" update-ref refs/heads/main "$base_commit"
  git -C "$workspace" update-ref refs/remotes/origin/main "$base_commit"
  printf 'runtime-smoke dispatch fixture\n' >"$workspace/dispatch-fixture.txt"
  git -C "$workspace" add .
  tree="$(git -C "$workspace" write-tree)"
  commit="$(printf 'runtime-smoke dispatch fixture\n' | git -C "$workspace" commit-tree "$tree" -p "$base_commit")"
  git -C "$workspace" update-ref "refs/heads/$branch" "$commit"
  git -C "$workspace" symbolic-ref HEAD "refs/heads/$branch"
  git -C "$workspace" remote add origin "$remote_url"
  git -C "$workspace" update-ref "refs/remotes/origin/$branch" "$commit"
  git -C "$workspace" branch --set-upstream-to "origin/$branch" "$branch" >/dev/null
}

write_mini_plan() {
  cat >"$MINI_PLAN" <<'PLAN'
# Plan: Runtime Smoke Mini Plan

## Overview

Minimal plan fixture for dispatch runtime smoke.

## Read First

- Primary source: tests/runtime-smoke/README.md
- Source type: existing issue/spec
- Open questions carried into execution: none

## Scope

- In scope: one deterministic task.
- Out of scope: live GitHub mutation.

## Assumptions

1. Dry-run commands must not mutate provider state.

## Sprint 1: Smoke Sprint

**Goal**: Validate issue lifecycle surfaces.

**Demo/Validation**:

- Commands:
  - `true`
- Verify: command passes.

**PR grouping intent**: group
**Execution Profile**: serial

- **TotalComplexity**: 1
- **CriticalPathComplexity**: 1
- **MaxBatchWidth**: 1
- **OverlapHotspots**: none
- **Split command**: `plan-tooling split-prs --file mini-plan.md --scope sprint --sprint 1 --strategy deterministic --pr-grouping group --pr-group 'Task 1.1=smoke' --format json`

### Task 1.1: Validate dispatch smoke

- **Location**:
  - `tests/runtime-smoke/cases/dispatch/run.sh`
- **Description**: Exercise deterministic issue lifecycle command surfaces.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - Dry-run issue lifecycle commands return typed output.
- **Validation**:
  - `true`
PLAN
}

ensure_plan_fixture() {
  if [ ! -f "$MINI_PLAN" ]; then
    write_mini_plan
  fi
}

write_tracking_comments_json() {
  local path="$1"
  cat >"$path" <<'JSON'
{"comments":[
{"body":"<!-- plan-tracking-issue:snapshot:v1 kind=source -->\n\n## Source Snapshot\n\n- Status: open","url":"https://github.com/example/repo/issues/1#issuecomment-source","createdAt":"2026-01-01T00:00:00Z"},
{"body":"<!-- plan-tracking-issue:snapshot:v1 kind=plan -->\n\n## Plan Snapshot","url":"https://github.com/example/repo/issues/1#issuecomment-plan","createdAt":"2026-01-01T00:00:01Z"},
{"body":"<!-- execute-from-tracking-issue:state:v1 -->\n\n## Execution State\n\n- Status: complete\n\n| ID | Status | Task | Evidence | Notes |\n| --- | --- | --- | --- | --- |\n| S1T1 | done | Validate dispatch smoke | #123 | runtime smoke |","url":"https://github.com/example/repo/issues/1#issuecomment-state","createdAt":"2026-01-01T00:00:02Z"},
{"body":"<!-- execute-from-tracking-issue:session:v1 -->\n\n## Execution Session\n\n- Status: complete\n- PR: #123","url":"https://github.com/example/repo/issues/1#issuecomment-session","createdAt":"2026-01-01T00:00:03Z"},
{"body":"<!-- execute-from-tracking-issue:validation:v1 -->\n\n## Validation Evidence\n\n- Status: complete\n- PR: #123","url":"https://github.com/example/repo/issues/1#issuecomment-validation","createdAt":"2026-01-01T00:00:04Z"},
{"body":"<!-- code-review-specialists:review:v1 -->\n\n## Review Evidence\n\n- Status: complete\n- PR: #123","url":"https://github.com/example/repo/issues/1#issuecomment-review","createdAt":"2026-01-01T00:00:05Z"}]}
JSON
}

write_dispatch_comments_json() {
  local path="$1"
  cat >"$path" <<'JSON'
{"comments":[
{"body":"<!-- issue-backed-plan:snapshot:v1 kind=source profile=dispatch -->\n\n## Source Snapshot\n\n- Status: open","url":"https://github.com/example/repo/issues/2#issuecomment-source","createdAt":"2026-01-01T00:00:00Z"},
{"body":"<!-- issue-backed-plan:snapshot:v1 kind=plan profile=dispatch -->\n\n## Plan Snapshot","url":"https://github.com/example/repo/issues/2#issuecomment-plan","createdAt":"2026-01-01T00:00:01Z"},
{"body":"<!-- issue-backed-plan:state:v1 profile=dispatch -->\n\n## Execution State\n\n- Status: complete\n- PR: #123\n\n## Dispatch Ledger\n\n| Task | Summary | Sprint | Owner/Subagent | Branch | Worktree | Execution Mode | PR Group | PR | Status | Validation | Review | Notes |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n| S1T1 | Validate dispatch smoke | S1 | subagent-s1-t1 | issue/s1-t1 | issue-s1-t1 | pr-shared | smoke | #123 | done | pass | pass | runtime smoke |","url":"https://github.com/example/repo/issues/2#issuecomment-state","createdAt":"2026-01-01T00:00:02Z"},
{"body":"<!-- issue-backed-plan:session:v1 profile=dispatch -->\n\n## Execution Session\n\n- Status: complete\n- PR: #123","url":"https://github.com/example/repo/issues/2#issuecomment-session","createdAt":"2026-01-01T00:00:03Z"},
{"body":"<!-- issue-backed-plan:validation:v1 profile=dispatch -->\n\n## Validation Evidence\n\n- Status: complete\n- PR: #123","url":"https://github.com/example/repo/issues/2#issuecomment-validation","createdAt":"2026-01-01T00:00:04Z"},
{"body":"<!-- issue-backed-plan:review:v1 profile=dispatch -->\n\n## Review Evidence\n\n- Status: complete\n- PR: #123","url":"https://github.com/example/repo/issues/2#issuecomment-review","createdAt":"2026-01-01T00:00:05Z"}]}
JSON
}

write_record_content() {
  local path="$1"
  local profile="$2"
  cat >"$path" <<CONTENT
- Status: complete
- Profile: $profile
- PR: #123
- Validation: pass
CONTENT
}

build_tracking_record_fixture() {
  local stem="$1"
  local dashboard_out="$DISPATCH_ARTIFACTS_DIR/$stem-dashboard.json"
  local state_md="$DISPATCH_ARTIFACTS_DIR/$stem-state.md"
  local state_out="$DISPATCH_ARTIFACTS_DIR/$stem-state-comment.json"

  ensure_plan_fixture
  PLAN_BODY_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-issue-body.md"
  COMMENTS_JSON_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-comments.json"

  write_record_content "$state_md" tracking
  plan-issue record render-dashboard \
    --profile tracking \
    --status complete \
    --target-scope "runtime smoke tracking" \
    --current "S1T1" \
    --next-action none \
    --validation pass \
    --linked-pr '#123' \
    --approval "runtime smoke approval" \
    --title "Runtime Smoke Tracking" \
    --issue-url "https://github.com/example/repo/issues/1" \
    --state-dir "$DISPATCH_STATE_DIR" \
    --out "$PLAN_BODY_PATH" >"$dashboard_out" 2>&1
  plan-issue record render-comment \
    --profile tracking \
    --marker-family compat \
    --kind state \
    --content-file "$state_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$state_out" 2>&1
  write_tracking_comments_json "$COMMENTS_JSON_PATH"

  grep -q 'plan-issue-cli.record.render.dashboard.v1' "$dashboard_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$state_out"
}

build_dispatch_record_fixture() {
  local stem="$1"
  local dashboard_out="$DISPATCH_ARTIFACTS_DIR/$stem-dashboard.json"
  local ledger_out="$DISPATCH_ARTIFACTS_DIR/$stem-ledger.json"
  local state_md="$DISPATCH_ARTIFACTS_DIR/$stem-state.md"
  local state_out="$DISPATCH_ARTIFACTS_DIR/$stem-state-comment.json"

  ensure_plan_fixture
  PLAN_BODY_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-issue-body.md"
  PLAN_TASK_SPEC_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-dispatch-ledger.md"
  COMMENTS_JSON_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-comments.json"

  write_record_content "$state_md" dispatch
  plan-issue record render-dashboard \
    --profile dispatch \
    --status complete \
    --target-scope "runtime smoke dispatch" \
    --current "S1T1" \
    --next-action none \
    --validation pass \
    --linked-pr '#123' \
    --approval "runtime smoke approval" \
    --title "Runtime Smoke Dispatch" \
    --issue-url "https://github.com/example/repo/issues/2" \
    --state-dir "$DISPATCH_STATE_DIR" \
    --out "$PLAN_BODY_PATH" >"$dashboard_out" 2>&1
  plan-issue record build-dispatch-ledger \
    --plan "$MINI_PLAN" \
    --strategy deterministic \
    --pr-grouping group \
    --pr-group 'Task 1.1=smoke' \
    --state-dir "$DISPATCH_STATE_DIR" \
    --out "$PLAN_TASK_SPEC_PATH" >"$ledger_out" 2>&1
  plan-issue record render-comment \
    --profile dispatch \
    --marker-family shared \
    --kind state \
    --content-file "$state_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$state_out" 2>&1
  write_dispatch_comments_json "$COMMENTS_JSON_PATH"

  grep -q 'plan-issue-cli.record.render.dashboard.v1' "$dashboard_out"
  grep -q 'plan-issue-cli.record.build.dispatch.ledger.v1' "$ledger_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$state_out"
  grep -q '^## Dispatch Ledger' "$PLAN_TASK_SPEC_PATH"
}

write_review_evidence() {
  local review_dir="$1"
  local verify_out="$2"
  mkdir -p "$review_dir"

  review-evidence init \
    --out "$review_dir" \
    --subject "PR #123" \
    --format json >"$review_dir/init.json" 2>&1
  review-evidence record-finding \
    --out "$review_dir" \
    --severity low \
    --path tests/runtime-smoke/cases/dispatch/run.sh \
    --summary "runtime smoke fixture observation" \
    --status accepted-risk \
    --format json >"$review_dir/finding.json" 2>&1
  review-evidence record-validation \
    --out "$review_dir" \
    --command "runtime smoke dispatch" \
    --status pass \
    --summary "dispatch runtime smoke validation" \
    --format json >"$review_dir/validation.json" 2>&1
  review-evidence verify \
    --out "$review_dir" \
    --format json >"$verify_out" 2>&1
}

write_pr_body() {
  local path="$1"
  cat >"$path" <<'BODY'
## Summary

Runtime smoke validates the dispatch PR dry-run contract.

## Scope

- Validate the assigned dispatch lane only.

## Testing

- forge-cli dry-run (pass)

## Test plan

- forge-cli dry-run (pass)

## Issue

- Refs #999
BODY
}

run_specialist_scope_probe() {
  local workspace="$1"
  local branch="$2"
  local out="$3"
  shift 3
  require_dispatch_bin review-specialists || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "$branch" \
    "git@github.com:graysurf/agent-runtime-kit.git"
  review-specialists scope \
    --repo "$workspace" \
    --base main \
    "$@" \
    --format json >"$out" 2>&1
  grep -q '"schema_version": "cli.review-specialists.scope.v1"' "$out"
}

run_create_plan_tracking_issue_probe() {
  local validate_out="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-validate.txt"
  local audit_out="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-audit.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  ensure_plan_fixture

  plan-tooling validate --file "$MINI_PLAN" --format text --explain >"$validate_out" 2>&1
  build_tracking_record_fixture create-plan-tracking
  plan-issue record audit \
    --profile tracking \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$audit_out" 2>&1

  grep -q '"missing_required":\\[\\]' "$audit_out"
  grep -q '"profile":"tracking"' "$audit_out"
}

run_tracking_issue_closeout_probe() {
  local closeout_md="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout.md"
  local gate_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-gate.json"
  local dashboard_body="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-final-dashboard.md"
  local render_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-render.json"
  local dashboard_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-dashboard.json"
  local comment_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-comment.json"
  local edit_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-edit.json"
  local close_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-close.json"
  local comment_body="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-comment.md"
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin forge-cli || return 1
  build_tracking_record_fixture plan-tracking-issue-closeout

  cat >"$closeout_md" <<'COMMENT'
- Status: complete
- Approval: runtime smoke approval
- Linked PRs: #123
COMMENT
  plan-issue record closeout-gate \
    --profile tracking \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --require-complete \
    --require-session \
    --require-validation \
    --approval "runtime smoke approval" \
    --linked-pr '#123' \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$gate_out" 2>&1
  plan-issue record render-comment \
    --profile tracking \
    --marker-family compat \
    --kind closeout \
    --content-file "$closeout_md" \
    --out "$comment_body" \
    --state-dir "$DISPATCH_STATE_DIR" >"$render_out" 2>&1
  plan-issue record render-dashboard \
    --profile tracking \
    --status complete \
    --target-scope "runtime smoke tracking" \
    --current complete \
    --next-action none \
    --validation pass \
    --linked-pr '#123' \
    --approval "runtime smoke approval" \
    --closeout-url "https://github.com/example/repo/issues/1#issuecomment-closeout" \
    --out "$dashboard_body" \
    --state-dir "$DISPATCH_STATE_DIR" >"$dashboard_out" 2>&1

  forge-cli issue comment 123 \
    --provider github \
    --repo graysurf/agent-runtime-kit \
    --dry-run \
    --format json \
    --body-file "$comment_body" >"$comment_out" 2>&1
  forge-cli issue edit 123 \
    --provider github \
    --repo graysurf/agent-runtime-kit \
    --dry-run \
    --format json \
    --body-file "$dashboard_body" >"$edit_out" 2>&1
  forge-cli issue close 123 \
    --provider github \
    --repo graysurf/agent-runtime-kit \
    --dry-run \
    --format json >"$close_out" 2>&1

  grep -q '"ready":true' "$gate_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$render_out"
  grep -q 'plan-issue-cli.record.render.dashboard.v1' "$dashboard_out"
  grep -q '"schema_version":"cli.forge-cli.issue.comment.v1"' "$comment_out"
  grep -q '"schema_version":"cli.forge-cli.issue.edit.v1"' "$edit_out"
  grep -q '"schema_version":"cli.forge-cli.issue.close.v1"' "$close_out"
}

run_deliver_dispatch_plan_probe() {
  local validate_out="$DISPATCH_ARTIFACTS_DIR/deliver-dispatch-plan-validate.txt"
  local audit_out="$DISPATCH_ARTIFACTS_DIR/deliver-dispatch-plan-audit.json"
  local specialist_out="$DISPATCH_ARTIFACTS_DIR/deliver-dispatch-plan-specialist-scope.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin review-specialists || return 1

  plan-tooling validate --file "$MINI_PLAN" --format text --explain >"$validate_out" 2>&1
  build_dispatch_record_fixture deliver-dispatch-plan
  plan-issue record audit \
    --profile dispatch \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$audit_out" 2>&1
  run_specialist_scope_probe "$DISPATCH_WORKSPACE/deliver-dispatch-plan-specialist" \
    "feat/deliver-dispatch-plan-specialist" \
    "$specialist_out" \
    --testing --maintainability

  grep -q '"missing_required":\\[\\]' "$audit_out"
  grep -q '^## Dispatch Ledger' "$PLAN_TASK_SPEC_PATH"
  grep -q '"forced_specialists"' "$specialist_out"
}

run_dispatch_issue_closeout_probe() {
  local gate_out="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-gate.json"
  local closeout_md="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout.md"
  local closeout_comment="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-comment.md"
  local render_out="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-render.json"
  local dashboard_out="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-dashboard.json"
  require_dispatch_bin plan-issue || return 1
  build_dispatch_record_fixture dispatch-plan-closeout

  cat >"$closeout_md" <<'COMMENT'
- Status: complete
- Approval: runtime smoke approval
- Final PR: #123
COMMENT
  plan-issue record closeout-gate \
    --profile dispatch \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --require-complete \
    --require-session \
    --require-validation \
    --require-review \
    --approval "runtime smoke approval" \
    --linked-pr '#123' \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$gate_out" 2>&1
  plan-issue record render-comment \
    --profile dispatch \
    --marker-family shared \
    --kind closeout \
    --content-file "$closeout_md" \
    --out "$closeout_comment" \
    --state-dir "$DISPATCH_STATE_DIR" >"$render_out" 2>&1
  plan-issue record render-dashboard \
    --profile dispatch \
    --status complete \
    --target-scope "runtime smoke dispatch" \
    --current complete \
    --next-action none \
    --validation pass \
    --linked-pr '#123' \
    --approval "runtime smoke approval" \
    --closeout-url "https://github.com/example/repo/issues/2#issuecomment-closeout" \
    --out "$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-dashboard.md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$dashboard_out" 2>&1

  grep -q '"ready":true' "$gate_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$render_out"
  grep -q 'plan-issue-cli.record.render.dashboard.v1' "$dashboard_out"
}

run_execute_from_tracking_issue_probe() {
  local validate_out="$DISPATCH_ARTIFACTS_DIR/execute-validate.txt"
  local audit_out="$DISPATCH_ARTIFACTS_DIR/execute-audit.json"
  local pr_view_out="$DISPATCH_ARTIFACTS_DIR/execute-pr-view.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin forge-cli || return 1
  build_tracking_record_fixture execute-plan-tracking-issue

  plan-tooling validate --file "$MINI_PLAN" --format text --explain >"$validate_out" 2>&1
  plan-issue record audit \
    --profile tracking \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$audit_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    pr view 123 >"$pr_view_out" 2>&1

  grep -q '"missing_required":\\[\\]' "$audit_out"
  grep -q '"schema_version":"cli.forge-cli.pr.view.v1"' "$pr_view_out"
}

run_deliver_tracking_issue_probe() {
  local verify_out="$DISPATCH_ARTIFACTS_DIR/deliver-review-verify.json"
  local checks_out="$DISPATCH_ARTIFACTS_DIR/deliver-pr-checks.json"
  local validation_md="$DISPATCH_ARTIFACTS_DIR/deliver-validation.md"
  local validation_out="$DISPATCH_ARTIFACTS_DIR/deliver-validation-comment.json"
  local specialist_out="$DISPATCH_ARTIFACTS_DIR/deliver-specialist-scope.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin forge-cli || return 1
  require_dispatch_bin review-evidence || return 1
  build_tracking_record_fixture deliver-plan-tracking-issue

  run_specialist_scope_probe "$DISPATCH_WORKSPACE/deliver-specialist" \
    "feat/dispatch-deliver-specialist" \
    "$specialist_out" \
    --testing --maintainability
  write_review_evidence "$DISPATCH_ARTIFACTS_DIR/deliver-review" "$verify_out"
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    pr checks 123 >"$checks_out" 2>&1
  write_record_content "$validation_md" tracking
  plan-issue record render-comment \
    --profile tracking \
    --marker-family compat \
    --kind validation \
    --content-file "$validation_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$validation_out" 2>&1

  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$verify_out"
  grep -q '"ok": true' "$verify_out"
  grep -q '"forced_specialists"' "$specialist_out"
  grep -q '"maintainability"' "$specialist_out"
  grep -q '"testing"' "$specialist_out"
  grep -q '"schema_version":"cli.forge-cli.pr.checks.v1"' "$checks_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$validation_out"
}

run_dispatch_pr_review_probe() {
  local verify_out="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-verify.json"
  local comment_body="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-comment.md"
  local comment_out="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-comment.json"
  local review_md="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr.md"
  local review_out="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-record-comment.json"
  local specialist_out="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-specialist-scope.json"
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin forge-cli || return 1
  require_dispatch_bin review-evidence || return 1
  build_dispatch_record_fixture review-dispatch-lane-pr

  run_specialist_scope_probe "$DISPATCH_WORKSPACE/review-dispatch-lane-pr-specialist" \
    "feat/review-dispatch-lane-pr-specialist" \
    "$specialist_out"
  write_review_evidence "$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-evidence" "$verify_out"
  printf 'Runtime smoke review evidence.\n' >"$comment_body"
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    pr comment 123 \
    --body-file "$comment_body" >"$comment_out" 2>&1
  write_record_content "$review_md" dispatch
  plan-issue record render-comment \
    --profile dispatch \
    --marker-family shared \
    --kind review \
    --content-file "$review_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$review_out" 2>&1

  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$verify_out"
  grep -q '"suggested_specialists"' "$specialist_out"
  grep -q '"schema_version":"cli.forge-cli.pr.comment.v1"' "$comment_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$review_out"
}

run_dispatch_subagent_pr_probe() {
  local workspace="$DISPATCH_WORKSPACE/subagent-pr"
  local pr_body="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-body.md"
  local create_out="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-create.json"
  local session_md="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-session.md"
  local session_out="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-session-comment.json"
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  build_dispatch_record_fixture execute-dispatch-lane
  init_pushed_branch_fixture "$workspace" "feat/dispatch-subagent-runtime-smoke" \
    "git@github.com:graysurf/agent-runtime-kit.git"
  write_pr_body "$pr_body"

  (
    cd "$workspace"
    forge-cli --provider github --repo graysurf/agent-runtime-kit \
      --dry-run --format json \
      pr create \
      --kind feature \
      --base plan/issue-26 \
      --title "Runtime smoke execute dispatch lane" \
      --body-file "$pr_body" \
      --label dispatch
  ) >"$create_out" 2>&1
  write_record_content "$session_md" dispatch
  plan-issue record render-comment \
    --profile dispatch \
    --marker-family shared \
    --kind session \
    --content-file "$session_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$session_out" 2>&1

  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$create_out"
  grep -q '"dispatch"' "$create_out"
  grep -q 'plan-issue-cli.record.render.comment.v1' "$session_out"
}

failures=0
record_case "dispatch.create-plan-tracking-issue" "plan-tooling plus shared tracking dashboard/comment/audit probes passed" run_create_plan_tracking_issue_probe || failures=1
record_case "dispatch.deliver-dispatch-plan" "shared dispatch dashboard, ledger, audit, and specialist scope probes passed" run_deliver_dispatch_plan_probe || failures=1
record_case "dispatch.dispatch-plan-closeout" "shared dispatch closeout gate and rendering probes passed" run_dispatch_issue_closeout_probe || failures=1
record_case "dispatch.plan-tracking-issue-closeout" "tracking closeout gate, render, and forge-cli dry-run probes passed" run_tracking_issue_closeout_probe || failures=1
record_case "dispatch.execute-plan-tracking-issue" "tracking audit and forge-cli pr view dry-run probes passed" run_execute_from_tracking_issue_probe || failures=1
record_case "dispatch.deliver-plan-tracking-issue" "review-specialists, review-evidence, forge-cli checks, and tracking validation comment probes passed" run_deliver_tracking_issue_probe || failures=1
record_case "dispatch.review-dispatch-lane-pr" "review-specialists, review evidence, PR comment, and dispatch review comment probes passed" run_dispatch_pr_review_probe || failures=1
record_case "dispatch.execute-dispatch-lane" "execute dispatch lane PR create and dispatch session comment probes passed" run_dispatch_subagent_pr_probe || failures=1

exit "$failures"
