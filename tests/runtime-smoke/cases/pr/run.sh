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
  local tree commit

  git -C "$workspace" init -q
  git -C "$workspace" config user.email runtime-smoke@example.invalid
  git -C "$workspace" config user.name "Runtime Smoke"
  printf 'runtime-smoke pr fixture\n' >"$workspace/pr-fixture.txt"
  git -C "$workspace" add .
  tree="$(git -C "$workspace" write-tree)"
  commit="$(printf 'runtime-smoke fixture\n' | git -C "$workspace" commit-tree "$tree")"
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
  require_pr_bin forge-cli || return 1
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
  grep -q '"schema_version":"cli.forge-cli.pr.create.v1"' "$out"
  grep -q '"provider":"github"' "$out"
  grep -q '"dispatch"' "$out"
}

run_close_github_probe() {
  local workspace="$PR_WORKSPACE/close-github"
  local out="$PR_ARTIFACTS_DIR/close-github.jsonl"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-close-github" \
    "git@github.com:graysurf/agent-runtime-kit.git"
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
}

run_close_gitlab_probe() {
  local workspace="$PR_WORKSPACE/close-gitlab"
  local out="$PR_ARTIFACTS_DIR/close-gitlab.jsonl"
  require_pr_bin forge-cli || return 1
  mkdir -p "$workspace"
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$workspace"
  init_pushed_branch_fixture "$workspace" "feat/runtime-smoke-close-gitlab" \
    "git@gitlab.com:group/project.git"
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
}

failures=0
record_case "pr.create-github-pr" "forge-cli GitHub pr create dry-run passed" run_create_github_probe || failures=1
record_case "pr.create-gitlab-mr" "forge-cli GitLab pr create dry-run passed" run_create_gitlab_probe || failures=1
record_case "pr.create-dispatch-lane-pr" "forge-cli dispatch lane pr create dry-run passed" run_create_dispatch_lane_probe || failures=1
record_case "pr.close-github-pr" "forge-cli GitHub checks, ready, merge, and close dry-runs passed" run_close_github_probe || failures=1
record_case "pr.close-gitlab-mr" "forge-cli GitLab checks, ready, merge, and close dry-runs passed" run_close_gitlab_probe || failures=1

exit "$failures"
