#!/usr/bin/env bash
# Deterministic probes for provider issue workflow skills.
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

ISSUE_ARTIFACTS_DIR="$ARTIFACTS_DIR/issue"
mkdir -p "$ISSUE_ARTIFACTS_DIR"

require_issue_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke issue: required binary not on PATH: $bin" >&2
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

run_issue_follow_up_probe() {
  local body="$ISSUE_ARTIFACTS_DIR/issue-body.md"
  local comment="$ISSUE_ARTIFACTS_DIR/comment.md"
  local create_out="$ISSUE_ARTIFACTS_DIR/create.json"
  local view_out="$ISSUE_ARTIFACTS_DIR/view.json"
  local comment_out="$ISSUE_ARTIFACTS_DIR/comment.json"
  require_issue_bin forge-cli || return 1

  printf 'Runtime smoke issue follow-up body.\n' >"$body"
  printf 'Runtime smoke follow-up checkpoint.\n' >"$comment"

  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    issue create \
    --title "Runtime smoke issue follow-up" \
    --body-file "$body" \
    --label issue >"$create_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    issue view 123 >"$view_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    issue comment 123 \
    --body-file "$comment" >"$comment_out" 2>&1

  grep -q '"schema_version":"cli.forge-cli.issue.create.v1"' "$create_out"
  grep -q '"schema_version":"cli.forge-cli.issue.view.v1"' "$view_out"
  grep -q '"schema_version":"cli.forge-cli.issue.comment.v1"' "$comment_out"
}

run_issue_triage_probe() {
  local status_out="$ISSUE_ARTIFACTS_DIR/inbox-status.json"
  local list_out="$ISSUE_ARTIFACTS_DIR/inbox-list.json"
  local next_out="$ISSUE_ARTIFACTS_DIR/inbox-next.json"
  local view_out="$ISSUE_ARTIFACTS_DIR/triage-view.json"
  require_issue_bin forge-cli || return 1

  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    inbox status \
    --item-type issue >"$status_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    inbox list \
    --item-type issue >"$list_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    inbox next \
    --item-type issue \
    --limit 3 >"$next_out" 2>&1
  forge-cli --provider github --repo graysurf/agent-runtime-kit \
    --dry-run --format json \
    issue view 123 >"$view_out" 2>&1

  grep -q '"schema_version":"cli.forge-cli.inbox.status.v1"' "$status_out"
  grep -q '"schema_version":"cli.forge-cli.inbox.list.v1"' "$list_out"
  grep -q '"schema_version":"cli.forge-cli.inbox.next.v1"' "$next_out"
  grep -q '"schema_version":"cli.forge-cli.issue.view.v1"' "$view_out"
}

failures=0
record_case "issue.issue-follow-up" "forge-cli issue create/view/comment dry-run probes passed" run_issue_follow_up_probe || failures=1
record_case "issue.issue-triage" "forge-cli inbox issue triage dry-run probes passed" run_issue_triage_probe || failures=1

exit "$failures"
