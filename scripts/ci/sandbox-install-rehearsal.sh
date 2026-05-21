#!/usr/bin/env bash
# scripts/ci/sandbox-install-rehearsal.sh — Plan 04 CI gate position 6.
#
# The product CLIs do not yet expose a stable `--home <dir> --list-skills`
# contract, so this gate uses the released `agent-runtime install --dry-run`
# plan as the skill-list source. It extracts canonical skill ids from planned
# SKILL.md symlink surfaces and diffs them against committed pins.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/agent-runtime-kit-sandbox.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

cd "$REPO_ROOT"

require_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "sandbox-install-rehearsal.sh: required binary not on PATH: $bin" >&2
    exit 127
  fi
}

validate_expected_file() {
  local expected="$1"
  local sorted="$TMP_ROOT/expected.sorted"
  if [ ! -s "$expected" ]; then
    echo "sandbox-install-rehearsal.sh: expected skill pin missing or empty: $expected" >&2
    exit 1
  fi
  if grep -n '^$' "$expected" >/tmp/sandbox-install-empty-lines.txt 2>&1; then
    echo "sandbox-install-rehearsal.sh: blank line(s) in $expected:" >&2
    cat /tmp/sandbox-install-empty-lines.txt >&2
    exit 1
  fi
  sort -u "$expected" >"$sorted"
  if ! diff -u "$expected" "$sorted" >/tmp/sandbox-install-expected-sort.diff 2>&1; then
    echo "sandbox-install-rehearsal.sh: expected skill pin is not sorted/unique: $expected" >&2
    cat /tmp/sandbox-install-expected-sort.diff >&2
    exit 1
  fi
}

extract_skill_ids() {
  local dry_run_output="$1"
  sed -n 's#.* /.*plugins/\([^/][^/]*\)/skills/\([^/][^/]*\)/SKILL\.md ->.*#\1.\2#p' "$dry_run_output" | sort -u
}

run_product() {
  local product="$1"
  local expected="tests/sandbox/${product}/expected-skills.txt"
  local live_home="$TMP_ROOT/${product}-home"
  local state_home="$TMP_ROOT/state/${product}"
  local dry_run_output="$TMP_ROOT/${product}.dry-run.txt"
  local observed="$TMP_ROOT/${product}.observed-skills.txt"

  validate_expected_file "$expected"

  echo "sandbox install rehearsal: $product"
  if ! agent-runtime install \
    --source-root "$REPO_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    --dry-run >"$dry_run_output" 2>&1; then
    echo "sandbox-install-rehearsal.sh: dry-run install failed for $product" >&2
    cat "$dry_run_output" >&2
    exit 1
  fi

  extract_skill_ids "$dry_run_output" >"$observed"
  if [ ! -s "$observed" ]; then
    echo "sandbox-install-rehearsal.sh: no SKILL.md surfaces found in dry-run output for $product" >&2
    cat "$dry_run_output" >&2
    exit 1
  fi

  if ! diff -u "$expected" "$observed" >/tmp/sandbox-install-"${product}".diff 2>&1; then
    echo "sandbox-install-rehearsal.sh: skill pin mismatch for $product:" >&2
    cat /tmp/sandbox-install-"${product}".diff >&2
    exit 1
  fi
}

require_bin agent-runtime

run_product claude
run_product codex

echo "sandbox-install-rehearsal.sh: OK"
