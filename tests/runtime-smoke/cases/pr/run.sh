#!/usr/bin/env bash
# Deterministic probes for Plan 05 PR/MR skills.
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

PR_ARTIFACTS_DIR="$ARTIFACTS_DIR/pr"
PR_WORKSPACE="$TMP_ROOT/workspaces/pr-basic-repo"
mkdir -p "$PR_ARTIFACTS_DIR" "$TMP_ROOT/workspaces"
cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$PR_WORKSPACE"

require_pr_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke pr: required binary not on PATH: $bin" >&2
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
  printf 'runtime-smoke pr base\n' >"$workspace/pr-base.txt"
  git -C "$workspace" add .
  base_tree="$(git -C "$workspace" write-tree)"
  base_commit="$(printf 'runtime-smoke pr base\n' | git -C "$workspace" commit-tree "$base_tree")"
  git -C "$workspace" update-ref refs/heads/main "$base_commit"
  git -C "$workspace" update-ref refs/remotes/origin/main "$base_commit"
  printf 'runtime-smoke pr fixture\n' >"$workspace/pr-fixture.txt"
  git -C "$workspace" add .
  tree="$(git -C "$workspace" write-tree)"
  commit="$(printf 'runtime-smoke fixture\n' | git -C "$workspace" commit-tree "$tree" -p "$base_commit")"
  git -C "$workspace" update-ref "refs/heads/$branch" "$commit"
  git -C "$workspace" symbolic-ref HEAD "refs/heads/$branch"
  git -C "$workspace" remote add origin "$remote_url"
  git -C "$workspace" update-ref "refs/remotes/origin/$branch" "$commit"
  git -C "$workspace" branch --set-upstream-to "origin/$branch" "$branch" >/dev/null
}

write_pr_body() {
  local path="$1"
  cat >"$path" <<'BODY'
## Summary

Runtime smoke validates the forge-cli PR create dry-run contract.

## Test plan

- forge-cli dry-run (pass)
BODY
}

write_dispatch_session_record() {
  local path="$1"
  cat >"$path" <<'BODY'
## Dispatch Lane PR

- Lane: L1
- PR: https://github.com/graysurf/agent-runtime-kit/pull/123
- Status: draft PR created
- Validation: forge-cli dry-run (pass)
BODY
}

run_specialist_scope_probe() {
  local workspace="$1"
  local out="$2"
  shift 2
  require_pr_bin review-specialists || return 1
  review-specialists scope \
    --repo "$workspace" \
    --base main \
    "$@" \
    --format json >"$out" 2>&1
  grep -q '"schema_version": "cli.review-specialists.scope.v1"' "$out"
}

run_create_github_probe() {
  local workspace="$PR_WORKSPACE/create-github"
  local body="$PR_ARTIFACTS_DIR/create-github-body.md"
  local out="$PR_ARTIFACTS_DIR/create-github.json"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-github" \
    "git@github.com:graysurf/agent-runtime-kit.git"
  write_pr_body "$body"
  (
    cd "$workspace"
    forge-cli --provider github --repo graysurf/agent-runtime-kit \
      --dry-run --format json \
      pr create \
      --kind feature \
      --base main \
      --title "Runtime smoke GitHub PR" \
      --body-file "$body" \
      --no-draft
  ) >"$out" 2>&1
  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$out"
  grep -q '"provider":"github"' "$out"
  grep -q '"gh"' "$out"
}

run_create_gitlab_probe() {
  local workspace="$PR_WORKSPACE/create-gitlab"
  local body="$PR_ARTIFACTS_DIR/create-gitlab-body.md"
  local out="$PR_ARTIFACTS_DIR/create-gitlab.json"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-gitlab" \
    "git@gitlab.com:group/project.git"
  write_pr_body "$body"
  (
    cd "$workspace"
    forge-cli --provider gitlab --repo group/project \
      --dry-run --format json \
      pr create \
      --kind feature \
      --base main \
      --title "Runtime smoke GitLab MR" \
      --body-file "$body"
  ) >"$out" 2>&1
  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$out"
  grep -q '"provider":"gitlab"' "$out"
  grep -q '"glab"' "$out"
}

run_create_dispatch_lane_probe() {
  local workspace="$PR_WORKSPACE/create-dispatch"
  local body="$PR_ARTIFACTS_DIR/create-dispatch-body.md"
  local out="$PR_ARTIFACTS_DIR/create-dispatch.json"
  local session="$PR_ARTIFACTS_DIR/create-dispatch-session.md"
  local comment="$PR_ARTIFACTS_DIR/create-dispatch-comment.md"
  local render_out="$PR_ARTIFACTS_DIR/create-dispatch-comment-render.json"
  local issue_comment_out="$PR_ARTIFACTS_DIR/create-dispatch-issue-comment.json"
  require_pr_bin forge-cli || return 1
  require_pr_bin plan-issue || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/dispatch-lane-runtime-smoke" \
    "git@github.com:graysurf/agent-runtime-kit.git"
  write_pr_body "$body"
  (
    cd "$workspace"
    forge-cli --provider github --repo graysurf/agent-runtime-kit \
      --dry-run --format json \
      pr create \
      --kind feature \
      --base plan/issue-26 \
      --title "Runtime smoke dispatch lane" \
      --body-file "$body" \
      --label dispatch
  ) >"$out" 2>&1
  write_dispatch_session_record "$session"
  plan-issue record render-comment \
    --profile dispatch \
    --kind session \
    --content-file "$session" \
    --out "$comment" \
    --format json >"$render_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    issue comment 50 \
    --body-file "$comment" >"$issue_comment_out" 2>&1
  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$out"
  grep -q '"provider":"github"' "$out"
  grep -q '"dispatch"' "$out"
  grep -q '"schema_version":"plan-issue-cli.record.render.comment.v2"' "$render_out"
  grep -q '<!-- plan-issue-record:v2 role=session profile=dispatch -->' "$comment"
  grep -q '"schema_version":"cli.forge-cli.issue.comment.v1"' "$issue_comment_out"
}

run_close_github_probe() {
  local workspace="$PR_WORKSPACE/close-github"
  local out="$PR_ARTIFACTS_DIR/close-github.jsonl"
  local review_out="$PR_ARTIFACTS_DIR/close-github-specialist-scope.json"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-close-github" \
    "git@github.com:graysurf/agent-runtime-kit.git"
  run_specialist_scope_probe "$workspace" "$review_out"
  (
    cd "$workspace"
    {
      forge-cli --provider github --repo graysurf/agent-runtime-kit \
        --dry-run --format json pr checks 123
      forge-cli --provider github --repo graysurf/agent-runtime-kit \
        --dry-run --format json pr ready 123
      forge-cli --provider github --repo graysurf/agent-runtime-kit \
        --dry-run --format json pr merge 123 --method merge
      forge-cli --provider github --repo graysurf/agent-runtime-kit \
        --dry-run --format json pr close 123
    } >"$out" 2>&1
  )
  grep -q '"schema_version":"cli.forge-cli.pr.checks.v1"' "$out"
  grep -q '"schema_version":"cli.forge-cli.pr.ready.v1"' "$out"
  grep -q '"schema_version":"cli.forge-cli.pr.merge.v1"' "$out"
  grep -q '"schema_version":"cli.forge-cli.pr.close.v1"' "$out"
  grep -q '"provider":"github"' "$out"
  grep -q '"suggested_specialists"' "$review_out"
}

run_close_gitlab_probe() {
  local workspace="$PR_WORKSPACE/close-gitlab"
  local out="$PR_ARTIFACTS_DIR/close-gitlab.jsonl"
  local review_out="$PR_ARTIFACTS_DIR/close-gitlab-specialist-scope.json"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-close-gitlab" \
    "git@gitlab.com:group/project.git"
  run_specialist_scope_probe "$workspace" "$review_out"
  (
    cd "$workspace"
    {
      forge-cli --provider gitlab --repo group/project \
        --dry-run --format json pr checks 123
      forge-cli --provider gitlab --repo group/project \
        --dry-run --format json pr ready 123
      forge-cli --provider gitlab --repo group/project \
        --dry-run --format json pr merge 123 --method merge
      forge-cli --provider gitlab --repo group/project \
        --dry-run --format json pr close 123
    } >"$out" 2>&1
  )
  grep -q '"schema_version":"cli.forge-cli.pr.checks.v1"' "$out"
  grep -q '"schema_version":"cli.forge-cli.pr.ready.v1"' "$out"
  grep -q '"schema_version":"cli.forge-cli.pr.merge.v1"' "$out"
  grep -q '"schema_version":"cli.forge-cli.pr.close.v1"' "$out"
  grep -q '"provider":"gitlab"' "$out"
  grep -q '"suggested_specialists"' "$review_out"
}

run_deliver_github_probe() {
  local workspace="$PR_WORKSPACE/deliver-github"
  local body="$PR_ARTIFACTS_DIR/deliver-github-body.md"
  local out="$PR_ARTIFACTS_DIR/deliver-github.json"
  local review_out="$PR_ARTIFACTS_DIR/deliver-github-specialist-scope.json"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-deliver-github" \
    "git@github.com:graysurf/agent-runtime-kit.git"
  run_specialist_scope_probe "$workspace" "$review_out" --testing --maintainability
  write_pr_body "$body"
  (
    cd "$workspace"
    forge-cli --provider github --repo graysurf/agent-runtime-kit \
      --dry-run --format json \
      pr deliver \
      --kind feature \
      --base main \
      --title "Runtime smoke GitHub delivery" \
      --body-file "$body" \
      --no-merge
  ) >"$out" 2>&1
  grep -q '"schema_version":"cli.forge-cli.pr.deliver.v1"' "$out"
  grep -q '"provider":"github"' "$out"
  grep -q '"wait_checks"' "$out"
  grep -q '"gh"' "$out"
  grep -q '"forced_specialists"' "$review_out"
  grep -q '"maintainability"' "$review_out"
  grep -q '"testing"' "$review_out"
}

run_deliver_gitlab_probe() {
  local workspace="$PR_WORKSPACE/deliver-gitlab"
  local body="$PR_ARTIFACTS_DIR/deliver-gitlab-body.md"
  local out="$PR_ARTIFACTS_DIR/deliver-gitlab.json"
  local review_out="$PR_ARTIFACTS_DIR/deliver-gitlab-specialist-scope.json"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-deliver-gitlab" \
    "git@gitlab.com:group/project.git"
  run_specialist_scope_probe "$workspace" "$review_out" --testing --maintainability
  write_pr_body "$body"
  (
    cd "$workspace"
    forge-cli --provider gitlab --repo group/project \
      --dry-run --format json \
      pr deliver \
      --kind feature \
      --base main \
      --title "Runtime smoke GitLab delivery" \
      --body-file "$body" \
      --no-merge
  ) >"$out" 2>&1
  grep -q '"schema_version":"cli.forge-cli.pr.deliver.v1"' "$out"
  grep -q '"provider":"gitlab"' "$out"
  grep -q '"wait_checks"' "$out"
  grep -q '"glab"' "$out"
  grep -q '"forced_specialists"' "$review_out"
  grep -q '"maintainability"' "$review_out"
  grep -q '"testing"' "$review_out"
}

failures=0
record_case "pr.create-github-pr" "forge-cli GitHub pr create dry-run passed" run_create_github_probe || failures=1
record_case "pr.create-gitlab-mr" "forge-cli GitLab pr create dry-run passed" run_create_gitlab_probe || failures=1
record_case "pr.create-dispatch-lane-pr" "forge-cli dispatch lane pr create dry-run passed" run_create_dispatch_lane_probe || failures=1
record_case "pr.close-github-pr" "forge-cli GitHub close dry-runs and optional specialist scope passed" run_close_github_probe || failures=1
record_case "pr.close-gitlab-mr" "forge-cli GitLab close dry-runs and optional specialist scope passed" run_close_gitlab_probe || failures=1
record_case "pr.deliver-github-pr" "forge-cli GitHub delivery macro and mandatory specialist scope passed" run_deliver_github_probe || failures=1
record_case "pr.deliver-gitlab-mr" "forge-cli GitLab delivery macro and mandatory specialist scope passed" run_deliver_gitlab_probe || failures=1

exit "$failures"
