#!/usr/bin/env bash
# Runtime skill smoke harness.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$REPO_ROOT/tests/runtime-smoke"
MATRIX_FILE="$SCRIPT_DIR/acceptance-matrix.yaml"

# shellcheck source=tests/runtime-smoke/lib/results.sh
. "$SCRIPT_DIR/lib/results.sh"
# shellcheck source=tests/runtime-smoke/lib/runtime-home.sh
. "$SCRIPT_DIR/lib/runtime-home.sh"

MODE=""
FORMAT="text"
PRODUCT=""
KEEP_ARTIFACTS=0
ARTIFACTS_DIR=""

usage() {
  cat <<'USAGE'
Usage: tests/runtime-smoke/run.sh --mode <matrix|install> [options]

Options:
  --mode <mode>           Smoke mode to run.
  --format <text|json>    Output format. Default: text.
  --product <product>     Product for install mode: codex or claude. Default: both.
  --artifacts-dir <path>  Write run logs and observed files to this directory.
  --keep-artifacts        Keep the temporary runtime root after the run.
  -h, --help              Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --format)
      FORMAT="${2:-}"
      shift 2
      ;;
    --product)
      PRODUCT="${2:-}"
      shift 2
      ;;
    --artifacts-dir)
      ARTIFACTS_DIR="${2:-}"
      shift 2
      ;;
    --keep-artifacts)
      KEEP_ARTIFACTS=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "runtime-smoke: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$MODE" ]; then
  echo "runtime-smoke: --mode is required" >&2
  usage >&2
  exit 2
fi

case "$MODE" in
  matrix | install)
    ;;
  *)
    echo "runtime-smoke: unsupported mode: $MODE" >&2
    exit 2
    ;;
esac

case "$FORMAT" in
  text | json)
    ;;
  *)
    echo "runtime-smoke: unsupported format: $FORMAT" >&2
    exit 2
    ;;
esac

case "$PRODUCT" in
  "" | codex | claude)
    ;;
  *)
    echo "runtime-smoke: unsupported product: $PRODUCT" >&2
    exit 2
    ;;
esac

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/agent-runtime-kit-runtime-smoke.XXXXXX")"
if [ -z "$ARTIFACTS_DIR" ]; then
  ARTIFACTS_DIR="$TMP_ROOT/artifacts"
fi
mkdir -p "$ARTIFACTS_DIR"
RESULTS_FILE="$ARTIFACTS_DIR/results.tsv"

cleanup() {
  if [ "$KEEP_ARTIFACTS" -eq 1 ]; then
    echo "runtime-smoke: kept temp root: $TMP_ROOT" >&2
  else
    rm -rf "$TMP_ROOT"
  fi
}
trap cleanup EXIT

require_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke: required binary not on PATH: $bin" >&2
    exit 127
  fi
}

count_lines() {
  wc -l <"$1" | tr -d ' '
}

validate_matrix_contract() {
  local matrix="$1"
  local expected_codex="$REPO_ROOT/tests/sandbox/codex/expected-skills.txt"
  local expected_claude="$REPO_ROOT/tests/sandbox/claude/expected-skills.txt"
  local case_ids="$ARTIFACTS_DIR/matrix.case-ids.txt"
  local skill_ids="$ARTIFACTS_DIR/matrix.skill-ids.txt"
  local skill_ids_sorted="$ARTIFACTS_DIR/matrix.skill-ids.sorted"
  local dispositions="$ARTIFACTS_DIR/matrix.dispositions.txt"
  local case_count key key_count

  if [ ! -s "$matrix" ]; then
    echo "runtime-smoke: matrix missing or empty: $matrix" >&2
    return 1
  fi

  sed -n 's/^  - id:[[:space:]]*//p' "$matrix" >"$case_ids"
  case_count="$(count_lines "$case_ids")"
  if [ "$case_count" -eq 0 ]; then
    echo "runtime-smoke: matrix has no cases" >&2
    return 1
  fi

  for key in id product domain skill_id mode fixture_workspace setup invocation expected_exit_code expected_artifacts cleanup expected_disposition skip_policy; do
    if [ "$key" = "id" ]; then
      key_count="$(sed -n 's/^  - id:[[:space:]]*//p' "$matrix" | wc -l | tr -d ' ')"
    else
      key_count="$(sed -n "s/^    $key:[[:space:]]*//p" "$matrix" | wc -l | tr -d ' ')"
    fi
    if [ "$key_count" != "$case_count" ]; then
      echo "runtime-smoke: matrix key '$key' count mismatch: got=$key_count expected=$case_count" >&2
      return 1
    fi
  done

  sed -n 's/^    skill_id:[[:space:]]*//p' "$matrix" | sort -u >"$skill_ids"
  if [ "$(count_lines "$skill_ids")" != "$case_count" ]; then
    echo "runtime-smoke: matrix skill_id values must be unique and one-per-case" >&2
    return 1
  fi
  sort "$skill_ids" >"$skill_ids_sorted"
  if ! diff -u "$skill_ids" "$skill_ids_sorted" >"$ARTIFACTS_DIR/matrix.skill-sort.diff" 2>&1; then
    echo "runtime-smoke: matrix skill_id values are not sorted/unique after extraction" >&2
    cat "$ARTIFACTS_DIR/matrix.skill-sort.diff" >&2
    return 1
  fi
  if ! diff -u "$expected_codex" "$skill_ids" >"$ARTIFACTS_DIR/matrix.codex-skills.diff" 2>&1; then
    echo "runtime-smoke: matrix skill_id set does not match codex expected skills" >&2
    cat "$ARTIFACTS_DIR/matrix.codex-skills.diff" >&2
    return 1
  fi
  if ! diff -u "$expected_claude" "$skill_ids" >"$ARTIFACTS_DIR/matrix.claude-skills.diff" 2>&1; then
    echo "runtime-smoke: matrix skill_id set does not match claude expected skills" >&2
    cat "$ARTIFACTS_DIR/matrix.claude-skills.diff" >&2
    return 1
  fi

  sed -n 's/^    expected_disposition:[[:space:]]*//p' "$matrix" >"$dispositions"
  while IFS= read -r disposition; do
    case "$disposition" in
      pass | fail | skip-host-capability | blocked-design)
        ;;
      *)
        echo "runtime-smoke: unknown disposition: $disposition" >&2
        return 1
        ;;
    esac
  done <"$dispositions"

  if ! awk '
    /^  - id:/ {
      if (case_id != "" && domain != "" && skill_id !~ "^" domain "\\.") {
        printf "case %s has domain=%s but skill_id=%s\n", case_id, domain, skill_id > "/dev/stderr"
        bad = 1
      }
      case_id = $0
      sub(/^  - id:[[:space:]]*/, "", case_id)
      domain = ""
      skill_id = ""
    }
    /^    domain:/ {
      domain = $0
      sub(/^    domain:[[:space:]]*/, "", domain)
    }
    /^    skill_id:/ {
      skill_id = $0
      sub(/^    skill_id:[[:space:]]*/, "", skill_id)
    }
    END {
      if (case_id != "" && domain != "" && skill_id !~ "^" domain "\\.") {
        printf "case %s has domain=%s but skill_id=%s\n", case_id, domain, skill_id > "/dev/stderr"
        bad = 1
      }
      exit bad
    }
  ' "$matrix"; then
    return 1
  fi

  RUNTIME_SMOKE_MATRIX_COUNT="$case_count"
  return 0
}

run_matrix_mode() {
  results_init "$RESULTS_FILE"
  if validate_matrix_contract "$MATRIX_FILE"; then
    results_add "matrix.contract" "shared-cli" "pass" "$RUNTIME_SMOKE_MATRIX_COUNT" "acceptance matrix covers expected skill ids"
  else
    results_add "matrix.contract" "shared-cli" "fail" "0" "acceptance matrix validation failed"
  fi
}

run_install_mode() {
  local products product status note skill_count
  require_bin agent-runtime
  results_init "$RESULTS_FILE"

  if [ -n "$PRODUCT" ]; then
    products="$PRODUCT"
  else
    products="codex claude"
  fi

  for product in $products; do
    if runtime_install_product "$REPO_ROOT" "$TMP_ROOT" "$product" "$ARTIFACTS_DIR"; then
      status="pass"
      note="install apply and doctor block=0"
      skill_count="$RUNTIME_SMOKE_SKILL_COUNT"
    else
      status="fail"
      note="install or doctor validation failed"
      skill_count="0"
    fi
    results_add "install.$product" "$product" "$status" "$skill_count" "$note"
  done
}

case "$MODE" in
  matrix)
    run_matrix_mode
    ;;
  install)
    run_install_mode
    ;;
esac

if [ "$FORMAT" = "json" ]; then
  results_print_json "$MODE"
else
  results_print_text "$MODE"
fi

if results_has_failures; then
  exit 1
fi
