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
LABEL_CATALOG="$REPO_ROOT/manifests/forge-labels.yaml"
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
{"body":"<!-- plan-issue-record:v2 role=source profile=tracking -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"source\",\"profile\":\"tracking\",\"data\":{\"path\":\"docs/source.md\",\"commit\":\"abc123\"}}\n```\n","url":"https://github.com/example/repo/issues/1#issuecomment-source","createdAt":"2026-01-01T00:00:00Z"},
{"body":"<!-- plan-issue-record:v2 role=plan profile=tracking -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"plan\",\"profile\":\"tracking\",\"data\":{\"path\":\"docs/plan.md\",\"commit\":\"abc123\"}}\n```\n","url":"https://github.com/example/repo/issues/1#issuecomment-plan","createdAt":"2026-01-01T00:00:01Z"},
{"body":"<!-- plan-issue-record:v2 role=state profile=tracking -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"state\",\"profile\":\"tracking\",\"data\":{\"status\":\"complete\",\"target_scope\":\"runtime smoke tracking\",\"current\":\"complete\",\"next_action\":\"closeout\",\"tasks\":[{\"id\":\"1.1\",\"status\":\"done\",\"title\":\"Validate dispatch smoke\"}],\"prs\":[{\"ref\":\"graysurf/agent-runtime-kit#123\",\"url\":\"https://github.com/graysurf/agent-runtime-kit/pull/123\",\"status\":\"merged\"}],\"blockers\":[],\"links\":{}}}\n```\n","url":"https://github.com/example/repo/issues/1#issuecomment-state","createdAt":"2026-01-01T00:00:02Z"},
{"body":"<!-- plan-issue-record:v2 role=session profile=tracking -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"session\",\"profile\":\"tracking\",\"data\":{\"summary\":\"Runtime smoke session\"}}\n```\n","url":"https://github.com/example/repo/issues/1#issuecomment-session","createdAt":"2026-01-01T00:00:03Z"},
{"body":"<!-- plan-issue-record:v2 role=validation profile=tracking -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"validation\",\"profile\":\"tracking\",\"data\":{\"overall\":\"pass\",\"commands\":[{\"command\":\"true\",\"status\":\"pass\"}],\"waivers\":[]}}\n```\n","url":"https://github.com/example/repo/issues/1#issuecomment-validation","createdAt":"2026-01-01T00:00:04Z"},
{"body":"<!-- plan-issue-record:v2 role=review profile=tracking -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"review\",\"profile\":\"tracking\",\"data\":{\"decision\":\"approve\",\"lenses\":[\"testing\",\"maintainability\"],\"findings\":[]}}\n```\n","url":"https://github.com/example/repo/issues/1#issuecomment-review","createdAt":"2026-01-01T00:00:05Z"}]}
JSON
}

write_dispatch_comments_json() {
  local path="$1"
  cat >"$path" <<'JSON'
{"comments":[
{"body":"<!-- plan-issue-record:v2 role=source profile=dispatch -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"source\",\"profile\":\"dispatch\",\"data\":{\"path\":\"docs/source.md\",\"commit\":\"abc123\"}}\n```\n","url":"https://github.com/example/repo/issues/2#issuecomment-source","createdAt":"2026-01-01T00:00:00Z"},
{"body":"<!-- plan-issue-record:v2 role=plan profile=dispatch -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"plan\",\"profile\":\"dispatch\",\"data\":{\"path\":\"docs/plan.md\",\"commit\":\"abc123\"}}\n```\n","url":"https://github.com/example/repo/issues/2#issuecomment-plan","createdAt":"2026-01-01T00:00:01Z"},
{"body":"<!-- plan-issue-record:v2 role=state profile=dispatch -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"state\",\"profile\":\"dispatch\",\"data\":{\"status\":\"complete\",\"target_scope\":\"runtime smoke dispatch\",\"current\":\"complete\",\"next_action\":\"closeout\",\"tasks\":[{\"id\":\"1.1\",\"status\":\"done\",\"title\":\"Validate dispatch smoke\"}],\"prs\":[{\"ref\":\"graysurf/agent-runtime-kit#123\",\"url\":\"https://github.com/graysurf/agent-runtime-kit/pull/123\",\"status\":\"merged\"}],\"blockers\":[],\"links\":{}}}\n```\n","url":"https://github.com/example/repo/issues/2#issuecomment-state","createdAt":"2026-01-01T00:00:02Z"},
{"body":"<!-- plan-issue-record:v2 role=session profile=dispatch -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"session\",\"profile\":\"dispatch\",\"data\":{\"summary\":\"Runtime smoke dispatch session\"}}\n```\n","url":"https://github.com/example/repo/issues/2#issuecomment-session","createdAt":"2026-01-01T00:00:03Z"},
{"body":"<!-- plan-issue-record:v2 role=validation profile=dispatch -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"validation\",\"profile\":\"dispatch\",\"data\":{\"overall\":\"pass\",\"commands\":[{\"command\":\"true\",\"status\":\"pass\"}],\"waivers\":[]}}\n```\n","url":"https://github.com/example/repo/issues/2#issuecomment-validation","createdAt":"2026-01-01T00:00:04Z"},
{"body":"<!-- plan-issue-record:v2 role=review profile=dispatch -->\n\n```plan-issue-record-payload\n{\"schema\":\"plan-issue-record.payload.v2\",\"role\":\"review\",\"profile\":\"dispatch\",\"data\":{\"decision\":\"approve\",\"lenses\":[\"testing\",\"maintainability\"],\"findings\":[]}}\n```\n","url":"https://github.com/example/repo/issues/2#issuecomment-review","createdAt":"2026-01-01T00:00:05Z"}]}
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

write_execution_state_content() {
  local path="$1"
  local profile="$2"
  cat >"$path" <<CONTENT
# Runtime Smoke $profile Execution State

## Execution State

- Status: complete
- Profile: $profile
- Current: runtime smoke complete
- Next action: closeout

## Task Ledger

| ID | Status | Task |
| --- | --- | --- |
| 1.1 | done | Validate dispatch smoke |

## Validation

| Command | Status |
| --- | --- |
| true | pass |
CONTENT
}

write_state_payload() {
  local path="$1"
  local profile="$2"
  cat >"$path" <<JSON
{"status":"complete","target_scope":"runtime smoke $profile","current":"complete","next_action":"closeout","tasks":[{"id":"1.1","status":"done","title":"Validate dispatch smoke"}],"prs":[{"ref":"graysurf/agent-runtime-kit#123","url":"https://github.com/graysurf/agent-runtime-kit/pull/123","status":"merged"}],"blockers":[],"links":{}}
JSON
}

assert_state_comment_shape() {
  local path="$1"

  grep -q '## Execution State' "$path"
  [ "$(grep -o '## Execution State' "$path" | wc -l | tr -d ' ')" = "1" ]
  [ "$(grep -o -- '- Profile:' "$path" | wc -l | tr -d ' ')" = "1" ]
  ! grep -q '# Runtime Smoke' "$path"
}

write_validation_payload() {
  local path="$1"
  cat >"$path" <<'JSON'
{"overall":"pass","commands":[{"command":"true","status":"pass"}],"waivers":[]}
JSON
}

write_review_payload() {
  local path="$1"
  cat >"$path" <<'JSON'
{"decision":"approve","lenses":["testing","maintainability"],"findings":[]}
JSON
}

write_session_payload() {
  local path="$1"
  cat >"$path" <<'JSON'
{"summary":"Runtime smoke session"}
JSON
}

write_close_fixture() {
  local fixture="$1"
  local comments_json="$2"
  mkdir -p "$fixture/prs"
  printf '## Current Dashboard\n\n- Status: in-progress\n' >"$fixture/issue-body.md"
  cp "$comments_json" "$fixture/comments.json"
  cat >"$fixture/prs/graysurf__agent-runtime-kit__123.json" <<'JSON'
{"state":"MERGED","mergeCommit":{"oid":"deadbeefcafebabe"},"statusCheckRollup":{"state":"success"},"url":"https://github.com/graysurf/agent-runtime-kit/pull/123"}
JSON
}

build_tracking_record_fixture() {
  local stem="$1"
  local dashboard_out="$DISPATCH_ARTIFACTS_DIR/$stem-repair-dashboard.json"
  local state_md="$DISPATCH_ARTIFACTS_DIR/$stem-state.md"
  local state_payload="$DISPATCH_ARTIFACTS_DIR/$stem-state-payload.json"
  local state_out="$DISPATCH_ARTIFACTS_DIR/$stem-state-post.json"

  ensure_plan_fixture
  PLAN_BODY_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-issue-body.md"
  COMMENTS_JSON_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-comments.json"

  printf '## Current Dashboard\n\n- Status: pending\n' >"$PLAN_BODY_PATH"
  write_execution_state_content "$state_md" tracking
  write_state_payload "$state_payload" tracking
  write_tracking_comments_json "$COMMENTS_JSON_PATH"
  plan-issue record repair-dashboard \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --state-dir "$DISPATCH_STATE_DIR" \
    --out "$PLAN_BODY_PATH.repaired" >"$dashboard_out" 2>&1
  plan-issue record post \
    --dry-run \
    --issue 1 \
    --profile tracking \
    --kind state \
    --payload-file "$state_payload" \
    --execution-state-file "$state_md" \
    --task-ledger-display expanded \
    --state-dir "$DISPATCH_STATE_DIR" >"$state_out" 2>&1

  grep -q 'plan-issue-cli.record.repair.dashboard.v2' "$dashboard_out"
  grep -q 'plan-issue-cli.record.post.v2' "$state_out"
  assert_state_comment_shape "$state_out"
  grep -q '## Task Ledger' "$state_out"
  grep -q 'Validate dispatch smoke' "$state_out"
  grep -q 'plan-issue-record-payload' "$state_out"
  ! grep -q '<details>' "$state_out"
}

build_dispatch_record_fixture() {
  local stem="$1"
  local dashboard_out="$DISPATCH_ARTIFACTS_DIR/$stem-repair-dashboard.json"
  local split_out="$DISPATCH_ARTIFACTS_DIR/$stem-split.json"
  local state_md="$DISPATCH_ARTIFACTS_DIR/$stem-state.md"
  local state_payload="$DISPATCH_ARTIFACTS_DIR/$stem-state-payload.json"
  local state_out="$DISPATCH_ARTIFACTS_DIR/$stem-state-post.json"

  ensure_plan_fixture
  PLAN_BODY_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-issue-body.md"
  PLAN_TASK_SPEC_PATH="$split_out"
  COMMENTS_JSON_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-comments.json"

  printf '## Current Dashboard\n\n- Status: pending\n' >"$PLAN_BODY_PATH"
  write_execution_state_content "$state_md" dispatch
  write_state_payload "$state_payload" dispatch
  write_dispatch_comments_json "$COMMENTS_JSON_PATH"
  plan-issue record repair-dashboard \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --state-dir "$DISPATCH_STATE_DIR" \
    --out "$PLAN_BODY_PATH.repaired" >"$dashboard_out" 2>&1
  plan-tooling split-prs \
    --file "$MINI_PLAN" \
    --scope plan \
    --strategy deterministic \
    --pr-grouping group \
    --pr-group 'Task 1.1=smoke' \
    --format json >"$split_out" 2>&1
  plan-issue record post \
    --dry-run \
    --issue 2 \
    --profile dispatch \
    --kind state \
    --payload-file "$state_payload" \
    --execution-state-file "$state_md" \
    --task-ledger-display expanded \
    --state-dir "$DISPATCH_STATE_DIR" >"$state_out" 2>&1

  grep -q 'plan-issue-cli.record.repair.dashboard.v2' "$dashboard_out"
  grep -q '"records"' "$split_out"
  grep -q 'plan-issue-cli.record.post.v2' "$state_out"
  assert_state_comment_shape "$state_out"
  grep -q '## Task Ledger' "$state_out"
  grep -q 'Validate dispatch smoke' "$state_out"
  grep -q 'plan-issue-record-payload' "$state_out"
  ! grep -q '<details>' "$state_out"
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
  local open_fixture="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-open-fixture"
  local open_out="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-open.json"
  local audit_out="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-audit.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  ensure_plan_fixture

  plan-tooling validate --file "$MINI_PLAN" --format text --explain >"$validate_out" 2>&1
  build_tracking_record_fixture create-plan-tracking
  mkdir -p "$open_fixture"
  printf '## Current Dashboard\n\n- Status: pending\n' >"$open_fixture/issue-body.md"
  cp "$COMMENTS_JSON_PATH" "$open_fixture/comments.json"
  plan-issue record open \
    --profile tracking \
    --fixture "$open_fixture" \
    --title "Runtime Smoke Tracking" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$open_out" 2>&1
  plan-issue record audit \
    --profile tracking \
    --body-file "$PLAN_BODY_PATH" \
    --comments-json "$COMMENTS_JSON_PATH" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$audit_out" 2>&1

  grep -q 'plan-issue-cli.record.open.v2' "$open_out"
  grep -q '"missing_required":\[\]' "$audit_out"
  grep -q '"profile":"tracking"' "$audit_out"
}

run_tracking_issue_closeout_probe() {
  local fixture="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-fixture"
  local close_out="$DISPATCH_ARTIFACTS_DIR/plan-tracking-issue-closeout-close.json"
  require_dispatch_bin plan-issue || return 1
  build_tracking_record_fixture plan-tracking-issue-closeout
  write_close_fixture "$fixture" "$COMMENTS_JSON_PATH"

  plan-issue record close \
    --issue 1 \
    --profile tracking \
    --approval "runtime smoke approval" \
    --linked-pr 'graysurf/agent-runtime-kit#123' \
    --fixture "$fixture" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$close_out" 2>&1

  grep -q 'plan-issue-cli.record.close.v2' "$close_out"
  grep -q '"mode":"fixture"' "$close_out"
  grep -q 'Final status' "$close_out"
  grep -q 'Merge SHA' "$close_out"
  grep -q 'deadbeefcafebabe' "$close_out"
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

  grep -q '"missing_required":\[\]' "$audit_out"
  grep -q '"records"' "$PLAN_TASK_SPEC_PATH"
  grep -q '"forced_specialists"' "$specialist_out"
}

run_dispatch_issue_closeout_probe() {
  local fixture="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-fixture"
  local close_out="$DISPATCH_ARTIFACTS_DIR/dispatch-plan-closeout-close.json"
  require_dispatch_bin plan-issue || return 1
  build_dispatch_record_fixture dispatch-plan-closeout
  write_close_fixture "$fixture" "$COMMENTS_JSON_PATH"

  plan-issue record close \
    --issue 2 \
    --profile dispatch \
    --approval "runtime smoke approval" \
    --linked-pr 'graysurf/agent-runtime-kit#123' \
    --fixture "$fixture" \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$close_out" 2>&1

  grep -q 'plan-issue-cli.record.close.v2' "$close_out"
  grep -q '"mode":"fixture"' "$close_out"
  grep -q 'Final status' "$close_out"
  grep -q 'Merge SHA' "$close_out"
  grep -q 'deadbeefcafebabe' "$close_out"
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

  grep -q '"missing_required":\[\]' "$audit_out"
  grep -q '"schema_version":"cli.forge-cli.pr.view.v1"' "$pr_view_out"
}

run_deliver_tracking_issue_probe() {
  local verify_out="$DISPATCH_ARTIFACTS_DIR/deliver-review-verify.json"
  local checks_out="$DISPATCH_ARTIFACTS_DIR/deliver-pr-checks.json"
  local validation_md="$DISPATCH_ARTIFACTS_DIR/deliver-validation.md"
  local validation_payload="$DISPATCH_ARTIFACTS_DIR/deliver-validation-payload.json"
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
  write_validation_payload "$validation_payload"
  plan-issue record post \
    --dry-run \
    --issue 1 \
    --profile tracking \
    --kind validation \
    --payload-file "$validation_payload" \
    --summary-file "$validation_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$validation_out" 2>&1

  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$verify_out"
  grep -q '"ok": true' "$verify_out"
  grep -q '"forced_specialists"' "$specialist_out"
  grep -q '"maintainability"' "$specialist_out"
  grep -q '"testing"' "$specialist_out"
  grep -q '"schema_version":"cli.forge-cli.pr.checks.v1"' "$checks_out"
  grep -q 'plan-issue-cli.record.post.v2' "$validation_out"
  grep -q 'Overall: pass' "$validation_out"
  grep -q 'true' "$validation_out"
}

run_dispatch_pr_review_probe() {
  local verify_out="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-verify.json"
  local comment_body="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-comment.md"
  local comment_out="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-comment.json"
  local review_md="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr.md"
  local review_payload="$DISPATCH_ARTIFACTS_DIR/review-dispatch-lane-pr-payload.json"
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
  write_review_payload "$review_payload"
  plan-issue record post \
    --dry-run \
    --issue 2 \
    --profile dispatch \
    --kind review \
    --payload-file "$review_payload" \
    --summary-file "$review_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$review_out" 2>&1

  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$verify_out"
  grep -q '"suggested_specialists"' "$specialist_out"
  grep -q '"schema_version":"cli.forge-cli.pr.comment.v1"' "$comment_out"
  grep -q 'plan-issue-cli.record.post.v2' "$review_out"
  grep -q 'Decision: approve' "$review_out"
  grep -q 'testing, maintainability' "$review_out"
}

run_dispatch_subagent_pr_probe() {
  local workspace="$DISPATCH_WORKSPACE/subagent-pr"
  local pr_body="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-body.md"
  local create_out="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-create.json"
  local session_md="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-session.md"
  local session_payload="$DISPATCH_ARTIFACTS_DIR/execute-dispatch-lane-session-payload.json"
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
      --label type::feature \
      --label area::skills \
      --label size::s \
      --label workflow::dispatch \
      --label-catalog "$LABEL_CATALOG" \
      --strict-labels
  ) >"$create_out" 2>&1
  write_record_content "$session_md" dispatch
  write_session_payload "$session_payload"
  plan-issue record post \
    --dry-run \
    --issue 2 \
    --profile dispatch \
    --kind session \
    --payload-file "$session_payload" \
    --summary-file "$session_md" \
    --state-dir "$DISPATCH_STATE_DIR" >"$session_out" 2>&1

  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$create_out"
  grep -q '"workflow::dispatch"' "$create_out"
  grep -q '"size::s"' "$create_out"
  grep -q 'plan-issue-cli.record.post.v2' "$session_out"
}

failures=0
record_case "dispatch.create-plan-tracking-issue" "plan-tooling plus tracking post/repair/audit probes passed" run_create_plan_tracking_issue_probe || failures=1
record_case "dispatch.deliver-dispatch-plan" "dispatch post/repair/audit, split, and specialist scope probes passed" run_deliver_dispatch_plan_probe || failures=1
record_case "dispatch.dispatch-plan-closeout" "dispatch record close fixture probe passed" run_dispatch_issue_closeout_probe || failures=1
record_case "dispatch.plan-tracking-issue-closeout" "tracking record close fixture probe passed" run_tracking_issue_closeout_probe || failures=1
record_case "dispatch.execute-plan-tracking-issue" "tracking audit and forge-cli pr view dry-run probes passed" run_execute_from_tracking_issue_probe || failures=1
record_case "dispatch.deliver-plan-tracking-issue" "review-specialists, review-evidence, forge-cli checks, and tracking validation post probes passed" run_deliver_tracking_issue_probe || failures=1
record_case "dispatch.review-dispatch-lane-pr" "review-specialists, review evidence, PR comment, and dispatch review post probes passed" run_dispatch_pr_review_probe || failures=1
record_case "dispatch.execute-dispatch-lane" "execute dispatch lane PR create and dispatch session post probes passed" run_dispatch_subagent_pr_probe || failures=1

exit "$failures"
