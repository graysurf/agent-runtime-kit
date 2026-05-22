#!/usr/bin/env bash
# Deterministic probes for Plan 06 meta skills.
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

META_ARTIFACTS_DIR="$ARTIFACTS_DIR/meta"
META_WORKSPACE="$TMP_ROOT/workspaces/meta-basic-repo"
mkdir -p "$META_ARTIFACTS_DIR" "$TMP_ROOT/workspaces"
cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$META_WORKSPACE"
git -C "$META_WORKSPACE" init -q

require_meta_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke meta: required binary not on PATH: $bin" >&2
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

run_agent_docs_probe() {
  local out="$META_ARTIFACTS_DIR/agent-docs.checklist.txt"
  require_meta_bin agent-docs || return 1
  (
    cd "$META_WORKSPACE"
    agent-docs \
      --docs-home "$REPO_ROOT" \
      --project-path "$REPO_ROOT" \
      resolve --context project-dev --strict --format checklist
  ) >"$out" 2>&1
  grep -q 'REQUIRED_DOCS_END .*missing=0' "$out"
}

run_agent_out_probe() {
  local out="$META_ARTIFACTS_DIR/agent-out.json"
  local agent_home="$TMP_ROOT/meta-agent-home"
  local path physical_agent_home physical_path
  require_meta_bin agent-out || return 1
  mkdir -p "$agent_home"
  (
    cd "$META_WORKSPACE"
    AGENT_HOME="$agent_home" agent-out project \
      --repo "$META_WORKSPACE" \
      --topic runtime-smoke-meta \
      --mkdir \
      --format json
  ) >"$out" 2>&1
  grep -q '"ok": true' "$out"
  path="$(sed -n 's/.*"path": "\([^"]*\)".*/\1/p' "$out" | head -1)"
  physical_agent_home="$(cd "$agent_home" && pwd -P)"
  physical_path="$(cd "$path" && pwd -P)"
  case "$physical_path" in
    "$physical_agent_home"/out/*)
      test -d "$path"
      ;;
    *)
      echo "runtime-smoke meta: agent-out path outside temp AGENT_HOME: $path" >&2
      return 1
      ;;
  esac
}

run_agent_scope_lock_probe() {
  local create_out="$META_ARTIFACTS_DIR/agent-scope-lock.create.json"
  local validate_out="$META_ARTIFACTS_DIR/agent-scope-lock.validate.json"
  require_meta_bin agent-scope-lock || return 1
  mkdir -p "$META_WORKSPACE/tests/runtime-smoke"
  printf 'scope-lock fixture\n' >"$META_WORKSPACE/tests/runtime-smoke/scope-lock.txt"
  (
    cd "$META_WORKSPACE"
    agent-scope-lock create \
      --path README.md \
      --path tests/runtime-smoke \
      --owner runtime-smoke \
      --format json
    agent-scope-lock validate --changes all --format json
  ) >"$create_out" 2>&1
  sed -n '/"schema_version": "cli.agent-scope-lock.validate.v1"/,$p' "$create_out" >"$validate_out"
  grep -q '"schema_version": "cli.agent-scope-lock.create.v1"' "$create_out"
  grep -q '"schema_version": "cli.agent-scope-lock.validate.v1"' "$create_out"
  grep -q '"ok": true' "$validate_out"
}

run_heuristic_inbox_probe() {
  local out="$META_ARTIFACTS_DIR/heuristic-inbox.json"
  local inbox_dir="$TMP_ROOT/heuristic-system/error-inbox"
  require_meta_bin heuristic-inbox || return 1
  mkdir -p "$inbox_dir"
  (
    cd "$META_WORKSPACE"
    heuristic-inbox list --inbox-dir "$inbox_dir" --format json
  ) >"$out" 2>&1
  grep -q '"schema_version": "cli.heuristic-inbox.list.v1"' "$out"
  grep -q '"ok": true' "$out"
  grep -q '"entries": \[\]' "$out"
}

run_repo_retro_probe() {
  local out="$META_ARTIFACTS_DIR/repo-retro.json"
  require_meta_bin repo-retro || return 1
  (
    cd "$META_WORKSPACE"
    repo-retro report \
      --repo "$META_WORKSPACE" \
      --from 2026-05-01 \
      --to 2026-05-02 \
      --format json
  ) >"$out" 2>&1
  grep -q '"schema_version": "cli.repo-retro.report.v1"' "$out"
  grep -q '"ok": true' "$out"
}

run_semantic_commit_probe() {
  local out="$META_ARTIFACTS_DIR/semantic-commit.dry-run.txt"
  local msg="$META_ARTIFACTS_DIR/semantic-commit-message.txt"
  require_meta_bin semantic-commit || return 1
  printf 'semantic fixture\n' >"$META_WORKSPACE/semantic-fixture.txt"
  printf '%s\n' \
    'test(runtime-smoke): validate semantic commit probe' \
    '' \
    '- Adds a staged temp fixture for dry-run validation.' >"$msg"
  (
    cd "$META_WORKSPACE"
    git add semantic-fixture.txt
    semantic-commit commit --repo "$META_WORKSPACE" --message-file "$msg" --dry-run --summary none
    ! git rev-parse --verify HEAD >/dev/null 2>&1
  ) >"$out" 2>&1
}

failures=0
record_case "meta.agent-docs" "project-dev docs resolve passed from fixture workspace" run_agent_docs_probe || failures=1
record_case "meta.agent-out" "agent-out wrote under temp AGENT_HOME" run_agent_out_probe || failures=1
record_case "meta.agent-scope-lock" "scope lock create and validate passed in temp git workspace" run_agent_scope_lock_probe || failures=1
record_case "meta.heuristic-inbox" "heuristic inbox empty-list probe passed against temp inbox" run_heuristic_inbox_probe || failures=1
record_case "meta.repo-retro" "repo-retro JSON report probe passed against temp git workspace" run_repo_retro_probe || failures=1
record_case "meta.semantic-commit" "semantic-commit dry-run validated staged temp change without commit" run_semantic_commit_probe || failures=1

exit "$failures"
