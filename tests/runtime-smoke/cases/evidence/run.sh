#!/usr/bin/env bash
# Deterministic probes for evidence skills.
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

EVIDENCE_ARTIFACTS_DIR="$ARTIFACTS_DIR/evidence"
EVIDENCE_WORKSPACE="$TMP_ROOT/workspaces/evidence-basic-repo"
mkdir -p "$EVIDENCE_ARTIFACTS_DIR" "$TMP_ROOT/workspaces"
cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$EVIDENCE_WORKSPACE"

require_evidence_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke evidence: required binary not on PATH: $bin" >&2
    return 1
  fi
}

record_case() {
  results_record_case "$@"
}

run_web_evidence_probe() {
  local root="$EVIDENCE_ARTIFACTS_DIR/web-root"
  local out_dir="$EVIDENCE_ARTIFACTS_DIR/web-evidence"
  local out_json="$EVIDENCE_ARTIFACTS_DIR/web-evidence.capture.json"
  local port_file="$EVIDENCE_ARTIFACTS_DIR/web-server.port"
  local server_out="$EVIDENCE_ARTIFACTS_DIR/web-server.stdout.txt"
  local server_err="$EVIDENCE_ARTIFACTS_DIR/web-server.stderr.txt"
  local server_pid port attempt
  require_evidence_bin web-evidence || return 1
  require_evidence_bin python3 || return 1
  mkdir -p "$root" "$out_dir"
  printf 'runtime smoke web evidence\n' >"$root/index.txt"
  python3 - "$root" "$port_file" >"$server_out" 2>"$server_err" <<'PY' &
import http.server
import os
import socketserver
import sys

root = sys.argv[1]
port_file = sys.argv[2]
os.chdir(root)

class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

with socketserver.TCPServer(("127.0.0.1", 0), Handler) as httpd:
    with open(port_file, "w", encoding="utf-8") as handle:
        handle.write(str(httpd.server_address[1]))
    httpd.serve_forever()
PY
  server_pid="$!"
  attempt=0
  while [ "$attempt" -lt 10 ]; do
    if [ -s "$port_file" ]; then
      break
    fi
    attempt=$((attempt + 1))
    sleep 0.1
  done
  if [ ! -s "$port_file" ]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" 2>/dev/null || true
    echo "runtime-smoke evidence: local web server did not publish a port" >&2
    return 1
  fi
  port="$(cat "$port_file")"
  (
    cd "$EVIDENCE_WORKSPACE"
    web-evidence capture "http://127.0.0.1:$port/index.txt" \
      --out "$out_dir" \
      --method get \
      --format json \
      --timeout-seconds 3 \
      --max-body-bytes 1024 \
      --body-preview-bytes 128
  ) >"$out_json" 2>&1
  kill "$server_pid" >/dev/null 2>&1 || true
  wait "$server_pid" 2>/dev/null || true
  grep -q '"schema_version": "cli.web-evidence.capture.v1"' "$out_json"
  grep -q '"ok": true' "$out_json"
  grep -q '"status_code": 200' "$out_json"
  test -s "$out_dir/summary.json"
  test -s "$out_dir/body-preview.redacted.txt"
}

run_test_first_evidence_probe() {
  local out_dir="$EVIDENCE_ARTIFACTS_DIR/test-first-evidence"
  require_evidence_bin test-first-evidence || return 1
  mkdir -p "$out_dir"
  test-first-evidence init \
    --out "$out_dir" \
    --classification docs-only \
    --production-path README.md \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/test-first.init.json"
  test-first-evidence record-waiver \
    --out "$out_dir" \
    --reason "docs-only runtime smoke fixture" \
    --substitute-validation "bash -n tests/runtime-smoke/run.sh" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/test-first.waiver.json"
  test-first-evidence record-final \
    --out "$out_dir" \
    --command "bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence" \
    --status pass \
    --summary "runtime smoke evidence fixture passed" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/test-first.final.json"
  test-first-evidence verify \
    --out "$out_dir" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/test-first.verify.json"
  grep -q '"schema_version": "cli.test-first-evidence.verify.v1"' "$EVIDENCE_ARTIFACTS_DIR/test-first.verify.json"
  grep -q '"ok": true' "$EVIDENCE_ARTIFACTS_DIR/test-first.verify.json"
  grep -q '"complete": true' "$EVIDENCE_ARTIFACTS_DIR/test-first.verify.json"
}

run_review_evidence_probe() {
  local out_dir="$EVIDENCE_ARTIFACTS_DIR/review-evidence"
  local artifact="$EVIDENCE_ARTIFACTS_DIR/review-artifact.txt"
  require_evidence_bin review-evidence || return 1
  mkdir -p "$out_dir"
  printf 'runtime smoke review artifact\n' >"$artifact"
  review-evidence init \
    --out "$out_dir" \
    --subject "runtime smoke evidence fixture" \
    --reviewer runtime-smoke \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/review.init.json"
  review-evidence record-finding \
    --out "$out_dir" \
    --severity low \
    --path README.md \
    --line 1 \
    --summary "fixture finding recorded and fixed" \
    --status fixed \
    --artifact "$artifact" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/review.finding.json"
  review-evidence record-validation \
    --out "$out_dir" \
    --command "true" \
    --status pass \
    --summary "fixture validation passed" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/review.validation.json"
  review-evidence verify \
    --out "$out_dir" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/review.verify.json"
  grep -q '"schema_version": "cli.review-evidence.verify.v1"' "$EVIDENCE_ARTIFACTS_DIR/review.verify.json"
  grep -q '"ok": true' "$EVIDENCE_ARTIFACTS_DIR/review.verify.json"
  grep -q '"complete": true' "$EVIDENCE_ARTIFACTS_DIR/review.verify.json"
}

run_skill_usage_probe() {
  local out_dir="$EVIDENCE_ARTIFACTS_DIR/skill-usage"
  local linked_record="$EVIDENCE_ARTIFACTS_DIR/review-evidence/review-evidence.json"
  require_evidence_bin skill-usage || return 1
  test -s "$linked_record"
  mkdir -p "$out_dir"
  skill-usage init \
    --out "$out_dir" \
    --skill evidence.review-evidence \
    --intent "runtime smoke evidence probe" \
    --user-request-summary "evidence smoke" \
    --trigger agent-selected \
    --referenced-file README.md \
    --cwd "$EVIDENCE_WORKSPACE" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/skill-usage.init.json"
  skill-usage link-record \
    --out "$out_dir" \
    --type review-evidence \
    --path "$linked_record" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/skill-usage.link.json"
  skill-usage record-validation \
    --out "$out_dir" \
    --command "review-evidence verify --out fixture" \
    --status pass \
    --summary "child review evidence verified" \
    --artifact "$linked_record" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/skill-usage.validation.json"
  skill-usage record-outcome \
    --out "$out_dir" \
    --status pass \
    --summary "skill usage fixture completed" \
    --artifact "$out_dir/skill-usage.record.json" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/skill-usage.outcome.json"
  skill-usage verify \
    --out "$out_dir" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/skill-usage.verify.json"
  grep -q '"schema_version": "cli.skill-usage.verify.v1"' "$EVIDENCE_ARTIFACTS_DIR/skill-usage.verify.json"
  grep -q '"ok": true' "$EVIDENCE_ARTIFACTS_DIR/skill-usage.verify.json"
  grep -q '"complete": true' "$EVIDENCE_ARTIFACTS_DIR/skill-usage.verify.json"
}

run_docs_impact_probe() {
  local docs_workspace="$TMP_ROOT/workspaces/docs-impact-repo"
  local out_json="$EVIDENCE_ARTIFACTS_DIR/docs-impact.scan.json"
  require_evidence_bin docs-impact || return 1
  cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$docs_workspace"
  git -C "$docs_workspace" init -q
  git -C "$docs_workspace" config user.email runtime-smoke@example.invalid
  git -C "$docs_workspace" config user.name "Runtime Smoke"
  git -C "$docs_workspace" add README.md
  git -C "$docs_workspace" commit -q -m "Initial fixture"
  mkdir -p "$docs_workspace/docs"
  printf 'docs impact fixture\n' >"$docs_workspace/docs/runtime-smoke.md"
  docs-impact scan \
    --repo "$docs_workspace" \
    --include-untracked \
    --format json >"$out_json"
  grep -q '"schema_version": "cli.docs-impact.scan.v1"' "$out_json"
  grep -q '"ok": true' "$out_json"
  grep -q '"docs_changed": true' "$out_json"
  grep -q '"docs/runtime-smoke.md"' "$out_json"
}

run_model_cross_check_probe() {
  local out_dir="$EVIDENCE_ARTIFACTS_DIR/model-cross-check"
  local artifact="$EVIDENCE_ARTIFACTS_DIR/model-artifact.txt"
  require_evidence_bin model-cross-check || return 1
  mkdir -p "$out_dir"
  printf 'runtime smoke model cross-check artifact\n' >"$artifact"
  model-cross-check init \
    --out "$out_dir" \
    --prompt "runtime smoke fixture" \
    --primary-model primary-fixture \
    --checker-model checker-fixture \
    --criterion "records both roles without provider calls" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/model.init.json"
  model-cross-check record-observation \
    --out "$out_dir" \
    --role primary \
    --model primary-fixture \
    --verdict pass \
    --summary "primary observation fixture" \
    --artifact "$artifact" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/model.primary.json"
  model-cross-check record-observation \
    --out "$out_dir" \
    --role checker \
    --model checker-fixture \
    --verdict pass \
    --summary "checker observation fixture" \
    --artifact "$artifact" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/model.checker.json"
  model-cross-check verify \
    --out "$out_dir" \
    --format json >"$EVIDENCE_ARTIFACTS_DIR/model.verify.json"
  grep -q '"schema_version": "cli.model-cross-check.verify.v1"' "$EVIDENCE_ARTIFACTS_DIR/model.verify.json"
  grep -q '"ok": true' "$EVIDENCE_ARTIFACTS_DIR/model.verify.json"
  grep -q '"complete": true' "$EVIDENCE_ARTIFACTS_DIR/model.verify.json"
}

failures=0
record_case "evidence.web-evidence" "web-evidence captured local loopback HTTP fixture" run_web_evidence_probe
record_case "evidence.test-first-evidence" "test-first evidence waiver and final validation verified" run_test_first_evidence_probe
record_case "evidence.review-evidence" "review evidence finding and validation verified" run_review_evidence_probe
record_case "evidence.skill-usage" "skill usage record linked child evidence and verified outcome" run_skill_usage_probe
record_case "evidence.docs-impact" "docs-impact classified controlled untracked docs fixture" run_docs_impact_probe
record_case "evidence.model-cross-check" "model cross-check recorded primary and checker observations without provider calls" run_model_cross_check_probe

exit "$failures"
