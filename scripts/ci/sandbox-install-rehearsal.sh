#!/usr/bin/env bash
# scripts/ci/sandbox-install-rehearsal.sh — CI gate sandbox install rehearsal.
#
# Uses `agent-runtime list-skills --format json` (cli.agent-runtime.list-skills.v1)
# as the source of truth for the per-product skill list, then diffs against the
# committed `tests/sandbox/<product>/expected-skills.txt` pin. Falls back to
# the legacy dry-run-text regex parser when `list-skills` is not available on
# the installed `agent-runtime`, so this script keeps working against
# pre-0.22.0 binaries during rollout.
#
# It also diffs the installed reviewer subagent files (the `agents-tree`
# link-map entry, parsed from the dry-run plan) against the committed
# `tests/sandbox/<product>/expected-agents.txt` pin, so a missing or renamed
# reviewer agent fails the gate in both product homes.

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

# Probe whether the installed agent-runtime exposes the `list-skills`
# subcommand. Returns 0 when available, 1 otherwise. This keeps the
# rehearsal compatible with pre-0.22.0 binaries during release rollout.
has_list_skills() {
  agent-runtime list-skills --help >/dev/null 2>&1
}

extract_skill_ids_via_list_skills() {
  local product="$1"
  local out="$2"
  local live_home="$3"
  require_bin jq
  agent-runtime list-skills \
    --source-root "$REPO_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --format json \
    >"$TMP_ROOT/${product}.list-skills.json"
  jq -r '.skills[].id' "$TMP_ROOT/${product}.list-skills.json" | sort -u >"$out"
}

extract_skill_ids_via_dry_run_regex() {
  local product="$1"
  local dry_run_output="$2"
  local out="$3"

  case "$product" in
    codex)
      {
        sed -n 's#.* (\([a-z0-9][a-z0-9._-]*\)\.codex-skill-dir)#\1#p' "$dry_run_output"
        sed -n 's#.* /.*skills/\([^/][^/]*\)/\([^/][^/]*\)/SKILL\.md ->.*#\1.\2#p' "$dry_run_output"
      } | sort -u >"$out"
      ;;
    *)
      sed -n 's#.* /.*plugins/\([^/][^/]*\)/skills/\([^/][^/]*\)/SKILL\.md ->.*#\1.\2#p' "$dry_run_output" | sort -u >"$out"
      ;;
  esac
}

extract_agent_names() {
  local dry_run_output="$1"
  local out="$2"
  # `agents-tree` installs one file symlink per reviewer agent into the product
  # home's `agents/` dir; capture each agent name (basename without the
  # product-specific .toml / .md extension) from the dry-run plan.
  sed -n 's#.*/agents/\([^/]*\)\.[a-z][a-z]* -> .*(agents-tree)#\1#p' "$dry_run_output" | sort -u >"$out"
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

  if [[ "${USE_LIST_SKILLS:-1}" = "1" ]] && has_list_skills; then
    extract_skill_ids_via_list_skills "$product" "$observed" "$live_home"
  else
    extract_skill_ids_via_dry_run_regex "$product" "$dry_run_output" "$observed"
  fi

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

  # Reviewer subagent surfaces: the `agents-tree` link-map entry installs one
  # file per reviewer agent into the product home `agents/` dir.
  local expected_agents="tests/sandbox/${product}/expected-agents.txt"
  local observed_agents="$TMP_ROOT/${product}.observed-agents.txt"
  validate_expected_file "$expected_agents"
  extract_agent_names "$dry_run_output" "$observed_agents"
  if [ ! -s "$observed_agents" ]; then
    echo "sandbox-install-rehearsal.sh: no reviewer agent surfaces found in dry-run output for $product" >&2
    cat "$dry_run_output" >&2
    exit 1
  fi
  if ! diff -u "$expected_agents" "$observed_agents" >/tmp/sandbox-install-"${product}"-agents.diff 2>&1; then
    echo "sandbox-install-rehearsal.sh: reviewer agent pin mismatch for $product:" >&2
    cat /tmp/sandbox-install-"${product}"-agents.diff >&2
    exit 1
  fi
}

require_bin agent-runtime

run_product claude
run_product codex

echo "sandbox-install-rehearsal.sh: OK"
