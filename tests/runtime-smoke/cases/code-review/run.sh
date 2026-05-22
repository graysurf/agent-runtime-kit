#!/usr/bin/env bash
# Deterministic probes for code review workflow skills.
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

CODE_REVIEW_ARTIFACTS_DIR="$ARTIFACTS_DIR/code-review"
CODE_REVIEW_WORKSPACE="$TMP_ROOT/workspaces/code-review-basic-repo"
mkdir -p "$CODE_REVIEW_ARTIFACTS_DIR" "$CODE_REVIEW_WORKSPACE"

require_code_review_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke code-review: required binary not on PATH: $bin" >&2
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

init_diff_fixture() {
  local tree commit

  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$CODE_REVIEW_WORKSPACE"
  git -C "$CODE_REVIEW_WORKSPACE" init -q
  git -C "$CODE_REVIEW_WORKSPACE" config user.email runtime-smoke@example.invalid
  git -C "$CODE_REVIEW_WORKSPACE" config user.name "Runtime Smoke"
  mkdir -p "$CODE_REVIEW_WORKSPACE/src" "$CODE_REVIEW_WORKSPACE/tests"
  printf 'def handler():\n    return {"ok": True}\n' >"$CODE_REVIEW_WORKSPACE/src/api.py"
  printf 'def test_handler():\n    assert True\n' >"$CODE_REVIEW_WORKSPACE/tests/test_api.py"
  git -C "$CODE_REVIEW_WORKSPACE" add .
  tree="$(git -C "$CODE_REVIEW_WORKSPACE" write-tree)"
  commit="$(printf 'runtime smoke code review base\n' | git -C "$CODE_REVIEW_WORKSPACE" commit-tree "$tree")"
  git -C "$CODE_REVIEW_WORKSPACE" update-ref refs/heads/main "$commit"
  git -C "$CODE_REVIEW_WORKSPACE" symbolic-ref HEAD refs/heads/main
  printf '\n\ndef new_handler():\n    return {"ok": False}\n' >>"$CODE_REVIEW_WORKSPACE/src/api.py"
}

write_findings() {
  local findings="$1"

  cat >"$findings" <<'JSONL'
{"severity":"HIGH","confidence":0.82,"path":"src/api.py","line":1,"category":"api-contract","summary":"Runtime smoke finding.","evidence":"Fixture evidence anchors the changed API file.","recommendation":"Keep the fixture stable.","specialist":"api-contract","test_suggestion":"Keep a focused smoke test."}
JSONL
}

run_code_review_specialists_probe() {
  local scope_out="$CODE_REVIEW_ARTIFACTS_DIR/scope.json"
  local findings="$CODE_REVIEW_ARTIFACTS_DIR/findings.jsonl"
  local validate_out="$CODE_REVIEW_ARTIFACTS_DIR/validate.json"
  local merge_out="$CODE_REVIEW_ARTIFACTS_DIR/merge.json"
  local summary_out="$CODE_REVIEW_ARTIFACTS_DIR/specialist-review.md"
  local render_out="$CODE_REVIEW_ARTIFACTS_DIR/render.json"
  local rendered_report="$CODE_REVIEW_ARTIFACTS_DIR/rendered-report.md"
  require_code_review_bin review-specialists || return 1
  init_diff_fixture
  write_findings "$findings"

  review-specialists scope \
    --repo "$CODE_REVIEW_WORKSPACE" \
    --base main \
    --format json >"$scope_out" 2>&1
  review-specialists validate \
    --input "$findings" \
    --repo "$CODE_REVIEW_WORKSPACE" \
    --validate-paths \
    --validate-lines \
    --format json >"$validate_out" 2>&1
  review-specialists merge \
    --input "$findings" \
    --summary-out "$summary_out" \
    --format json >"$merge_out" 2>&1
  review-specialists render \
    --profile report \
    --input "$merge_out" \
    --out "$rendered_report" \
    --format json >"$render_out" 2>&1

  grep -q '"schema_version": "cli.review-specialists.scope.v1"' "$scope_out"
  grep -q '"schema_version": "cli.review-specialists.validate.v1"' "$validate_out"
  grep -q '"schema_version": "cli.review-specialists.merge.v1"' "$merge_out"
  grep -q '"schema_version": "cli.review-specialists.render.v1"' "$render_out"
  grep -q 'Runtime smoke finding' "$summary_out"
  grep -q 'Specialist Review Report' "$rendered_report"
}

failures=0
record_case "code-review.code-review-specialists" "review-specialists scope, validate, merge, and render probes passed" run_code_review_specialists_probe || failures=1

exit "$failures"
