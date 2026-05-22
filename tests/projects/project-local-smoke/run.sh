#!/usr/bin/env bash
# Project-local overlay smoke gate for Plan 05 Sprint 8.

set -euo pipefail

FIXTURE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$FIXTURE_ROOT/../../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/agent-runtime-kit-project-local.XXXXXX")"
OUT_DIR="$TMP_ROOT/out"
RUNTIME_ROOT="$TMP_ROOT/runtime"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$OUT_DIR" "$RUNTIME_ROOT/live/codex" "$RUNTIME_ROOT/state/codex"

scripts="bench bootstrap demo deploy pre-pr release"

doctor_block_count() {
  local log="$1"
  sed -n '1s/.* block=\([0-9][0-9]*\).*/\1/p' "$log"
}

run_fixture_script() {
  local name="$1"
  local script="$FIXTURE_ROOT/.agents/scripts/${name}.sh"
  local stdout="$OUT_DIR/${name}.stdout"

  if [ ! -x "$script" ]; then
    echo "project-local-smoke: missing executable script: $script" >&2
    return 1
  fi

  (
    cd "$FIXTURE_ROOT"
    PROJECT_LOCAL_SMOKE_OUT="$OUT_DIR" "$script" --runtime-smoke "$name"
  ) >"$stdout" 2>&1
  grep -q "project-local-smoke:${name}:called" "$stdout"
  test -f "$OUT_DIR/${name}.invoked"
}

install_temp_runtime() {
  agent-runtime render --product codex >"$OUT_DIR/render.log" 2>&1
  agent-runtime install \
    --source-root "$REPO_ROOT" \
    --product codex \
    --live-home "$RUNTIME_ROOT/live/codex" \
    --state-home "$RUNTIME_ROOT/state/codex" \
    --apply >"$OUT_DIR/install.log" 2>&1
}

assert_doctor_wired() {
  local log="$OUT_DIR/doctor.wired.log"
  local code block name

  set +e
  agent-runtime doctor \
    --source-root "$REPO_ROOT" \
    --product codex \
    --live-home "$RUNTIME_ROOT/live/codex" \
    --state-home "$RUNTIME_ROOT/state/codex" \
    --check-project "$FIXTURE_ROOT" >"$log" 2>&1
  code=$?
  set -e

  block="$(doctor_block_count "$log")"
  if [ "$block" != "0" ]; then
    echo "project-local-smoke: doctor reported blocking findings for wired fixture (exit=$code)" >&2
    cat "$log" >&2
    return 1
  fi

  for name in $scripts; do
    grep -q "ok project-overlay status=wired script=${name} " "$log"
  done
}

assert_doctor_missing() {
  local copy_root="$TMP_ROOT/missing-project"
  local log="$OUT_DIR/doctor.missing.log"
  local code block

  mkdir -p "$copy_root"
  cp -R "$FIXTURE_ROOT/." "$copy_root/"
  rm "$copy_root/.agents/scripts/release.sh"

  set +e
  agent-runtime doctor \
    --source-root "$REPO_ROOT" \
    --product codex \
    --live-home "$RUNTIME_ROOT/live/codex" \
    --state-home "$RUNTIME_ROOT/state/codex" \
    --check-project "$copy_root" >"$log" 2>&1
  code=$?
  set -e

  block="$(doctor_block_count "$log")"
  if [ "$block" != "0" ]; then
    echo "project-local-smoke: missing-script doctor probe should be warning-only (exit=$code)" >&2
    cat "$log" >&2
    return 1
  fi
  grep -q 'warn project-overlay status=missing script=release ' "$log"
  grep -q 'project-local script is missing' "$log"
}

for script in $scripts; do
  run_fixture_script "$script"
done

install_temp_runtime
assert_doctor_wired
assert_doctor_missing

printf 'project-local-smoke: OK scripts=%s\n' "$scripts"
