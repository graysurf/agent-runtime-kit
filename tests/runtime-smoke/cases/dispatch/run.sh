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

build_plan_issue_fixture() {
  local stem="$1"
  local start_out="$DISPATCH_ARTIFACTS_DIR/$stem-start-plan.json"

  ensure_plan_fixture
  PLAN_BODY_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-issue-body.md"
  PLAN_TASK_SPEC_PATH="$DISPATCH_ARTIFACTS_DIR/$stem-task-spec.tsv"

  plan-issue-local start-plan \
    --plan "$MINI_PLAN" \
    --dry-run \
    --issue-body-out "$PLAN_BODY_PATH" \
    --task-spec-out "$PLAN_TASK_SPEC_PATH" \
    --format json \
    --strategy deterministic \
    --pr-grouping group \
    --pr-group 'Task 1.1=smoke' \
    --state-dir "$DISPATCH_STATE_DIR" >"$start_out" 2>&1

  grep -q '"schema_version":"plan-issue-cli.start.plan.v2"' "$start_out"
  grep -q '^# task_id' "$PLAN_TASK_SPEC_PATH"
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

## Test plan

- forge-cli dry-run (pass)
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
  local task_json="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-task-spec.json"
  local task_tsv="$DISPATCH_ARTIFACTS_DIR/create-plan-tracking-task-spec.tsv"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin plan-issue-local || return 1
  ensure_plan_fixture

  plan-tooling validate --file "$MINI_PLAN" --format text --explain >"$validate_out" 2>&1
  plan-issue-local build-plan-task-spec \
    --plan "$MINI_PLAN" \
    --task-spec-out "$task_tsv" \
    --format json \
    --strategy deterministic \
    --pr-grouping group \
    --pr-group 'Task 1.1=smoke' \
    --state-dir "$DISPATCH_STATE_DIR" >"$task_json" 2>&1

  grep -q '"schema_version":"plan-issue-cli.build.plan.task.spec.v1"' "$task_json"
  grep -q '^# task_id' "$task_tsv"
}

run_tracking_issue_closeout_probe() {
  local close_out="$DISPATCH_ARTIFACTS_DIR/tracking-issue-closeout.json"
  local rc
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin plan-issue-local || return 1
  build_plan_issue_fixture tracking-issue-closeout

  set +e
  plan-issue-local close-plan \
    --body-file "$PLAN_BODY_PATH" \
    --approved-comment-url https://github.com/example/repo/issues/1#issuecomment-1 \
    --dry-run \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$close_out" 2>&1
  rc=$?
  set -e

  [ "$rc" -ne 0 ]
  grep -q '"schema_version":"plan-issue-cli.close.plan.v1"' "$close_out"
  grep -q '"code":"close-gate-failed"' "$close_out"
}

run_execute_from_tracking_issue_probe() {
  local validate_out="$DISPATCH_ARTIFACTS_DIR/execute-validate.txt"
  local status_out="$DISPATCH_ARTIFACTS_DIR/execute-status.json"
  local pr_view_out="$DISPATCH_ARTIFACTS_DIR/execute-pr-view.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin plan-issue-local || return 1
  require_dispatch_bin forge-cli || return 1
  build_plan_issue_fixture execute-from-tracking-issue

  plan-tooling validate --file "$MINI_PLAN" --format text --explain >"$validate_out" 2>&1
  plan-issue-local status-plan \
    --body-file "$PLAN_BODY_PATH" \
    --no-comment \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$status_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    pr view 123 >"$pr_view_out" 2>&1

  grep -q '"schema_version":"plan-issue-cli.status.plan.v2"' "$status_out"
  grep -q '"schema_version":"cli.forge-cli.pr.view.v1"' "$pr_view_out"
}

run_deliver_tracking_issue_probe() {
  local verify_out="$DISPATCH_ARTIFACTS_DIR/deliver-review-verify.json"
  local checks_out="$DISPATCH_ARTIFACTS_DIR/deliver-pr-checks.json"
  local link_out="$DISPATCH_ARTIFACTS_DIR/deliver-link-pr.json"
  local specialist_out="$DISPATCH_ARTIFACTS_DIR/deliver-specialist-scope.json"
  require_dispatch_bin plan-tooling || return 1
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin plan-issue-local || return 1
  require_dispatch_bin forge-cli || return 1
  require_dispatch_bin review-evidence || return 1
  build_plan_issue_fixture deliver-tracking-issue

  run_specialist_scope_probe "$DISPATCH_WORKSPACE/deliver-specialist" \
    "feat/dispatch-deliver-specialist" \
    "$specialist_out" \
    --testing --maintainability
  write_review_evidence "$DISPATCH_ARTIFACTS_DIR/deliver-review" "$verify_out"
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    pr checks 123 >"$checks_out" 2>&1
  plan-issue-local link-pr \
    --body-file "$PLAN_BODY_PATH" \
    --task S1T1 \
    --pr '#123' \
    --dry-run \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$link_out" 2>&1

  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$verify_out"
  grep -q '"ok": true' "$verify_out"
  grep -q '"forced_specialists"' "$specialist_out"
  grep -q '"maintainability"' "$specialist_out"
  grep -q '"testing"' "$specialist_out"
  grep -q '"schema_version":"cli.forge-cli.pr.checks.v1"' "$checks_out"
  grep -q '"schema_version":"plan-issue-cli.link.pr.v1"' "$link_out"
}

run_dispatch_pr_review_probe() {
  local verify_out="$DISPATCH_ARTIFACTS_DIR/dispatch-pr-review-verify.json"
  local comment_body="$DISPATCH_ARTIFACTS_DIR/dispatch-pr-review-comment.md"
  local comment_out="$DISPATCH_ARTIFACTS_DIR/dispatch-pr-review-comment.json"
  local link_out="$DISPATCH_ARTIFACTS_DIR/dispatch-pr-review-link-pr.json"
  local specialist_out="$DISPATCH_ARTIFACTS_DIR/dispatch-pr-review-specialist-scope.json"
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin plan-issue-local || return 1
  require_dispatch_bin forge-cli || return 1
  require_dispatch_bin review-evidence || return 1
  build_plan_issue_fixture dispatch-pr-review

  run_specialist_scope_probe "$DISPATCH_WORKSPACE/dispatch-pr-review-specialist" \
    "feat/dispatch-pr-review-specialist" \
    "$specialist_out"
  write_review_evidence "$DISPATCH_ARTIFACTS_DIR/dispatch-pr-review-evidence" "$verify_out"
  printf 'Runtime smoke review evidence.\n' >"$comment_body"
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    pr comment 123 \
    --body-file "$comment_body" >"$comment_out" 2>&1
  plan-issue-local link-pr \
    --body-file "$PLAN_BODY_PATH" \
    --task S1T1 \
    --pr '#123' \
    --dry-run \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$link_out" 2>&1

  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$verify_out"
  grep -q '"suggested_specialists"' "$specialist_out"
  grep -q '"schema_version":"cli.forge-cli.pr.comment.v1"' "$comment_out"
  grep -q '"schema_version":"plan-issue-cli.link.pr.v1"' "$link_out"
}

run_dispatch_subagent_pr_probe() {
  local workspace="$DISPATCH_WORKSPACE/subagent-pr"
  local pr_body="$DISPATCH_ARTIFACTS_DIR/dispatch-subagent-pr-body.md"
  local create_out="$DISPATCH_ARTIFACTS_DIR/dispatch-subagent-pr-create.json"
  local link_out="$DISPATCH_ARTIFACTS_DIR/dispatch-subagent-pr-link-pr.json"
  require_dispatch_bin plan-issue || return 1
  require_dispatch_bin plan-issue-local || return 1
  require_dispatch_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  build_plan_issue_fixture dispatch-subagent-pr
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
      --title "Runtime smoke dispatch subagent PR" \
      --body-file "$pr_body" \
      --label dispatch
  ) >"$create_out" 2>&1
  plan-issue-local link-pr \
    --body-file "$PLAN_BODY_PATH" \
    --task S1T1 \
    --pr '#123' \
    --dry-run \
    --format json \
    --state-dir "$DISPATCH_STATE_DIR" >"$link_out" 2>&1

  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$create_out"
  grep -q '"dispatch"' "$create_out"
  grep -q '"schema_version":"plan-issue-cli.link.pr.v1"' "$link_out"
}

failures=0
record_case "dispatch.create-plan-tracking-issue" "plan-tooling and plan-issue-local task-spec probes passed" run_create_plan_tracking_issue_probe || failures=1
record_case "dispatch.tracking-issue-closeout" "plan-issue close-plan gate rejection classified as expected" run_tracking_issue_closeout_probe || failures=1
record_case "dispatch.execute-from-tracking-issue" "plan issue state and forge-cli pr view dry-run probes passed" run_execute_from_tracking_issue_probe || failures=1
record_case "dispatch.deliver-tracking-issue" "review-specialists, review-evidence, forge-cli checks, and issue link probes passed" run_deliver_tracking_issue_probe || failures=1
record_case "dispatch.dispatch-pr-review" "review-specialists, review evidence, PR comment, and issue sync probes passed" run_dispatch_pr_review_probe || failures=1
record_case "dispatch.dispatch-subagent-pr" "dispatch subagent PR create and issue sync probes passed" run_dispatch_subagent_pr_probe || failures=1

exit "$failures"
