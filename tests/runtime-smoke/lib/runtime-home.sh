#!/usr/bin/env bash
# Temporary runtime home helpers for the runtime smoke harness.

runtime_live_home() {
  local tmp_root="$1"
  local product="$2"
  printf '%s/live/%s' "$tmp_root" "$product"
}

runtime_state_home() {
  local tmp_root="$1"
  local product="$2"
  printf '%s/state/%s' "$tmp_root" "$product"
}

runtime_validate_expected_file() {
  local expected="$1"
  local sorted="$2"

  if [ ! -s "$expected" ]; then
    echo "runtime-smoke: expected skill pin missing or empty: $expected" >&2
    return 1
  fi
  if grep -n '^$' "$expected" >"$sorted.blank-lines" 2>&1; then
    echo "runtime-smoke: blank line(s) in $expected:" >&2
    cat "$sorted.blank-lines" >&2
    return 1
  fi
  sort -u "$expected" >"$sorted"
  if ! diff -u "$expected" "$sorted" >"$sorted.diff" 2>&1; then
    echo "runtime-smoke: expected skill pin is not sorted/unique: $expected" >&2
    cat "$sorted.diff" >&2
    return 1
  fi
}

runtime_collect_installed_skills() {
  local live_home="$1"
  local product="$2"

  case "$product" in
    codex)
      find "$live_home/plugins" -path '*/skills/*/SKILL.md' -print |
        sed "s#^$live_home/plugins/##" |
        sed 's#/skills/#.#' |
        sed 's#/SKILL\.md$##' |
        sort -u
      ;;
    *)
      find "$live_home/plugins" -path '*/skills/*/SKILL.md' -print |
        sed "s#^$live_home/plugins/##" |
        sed 's#/skills/#.#' |
        sed 's#/SKILL\.md$##' |
        sort -u
      ;;
  esac
}

runtime_doctor_block_count() {
  local doctor_log="$1"
  local first_line
  first_line="$(sed -n '1p' "$doctor_log")"
  printf '%s\n' "$first_line" | sed -n 's/.* block=\([0-9][0-9]*\).*/\1/p'
}

runtime_install_product() {
  local repo_root="$1"
  local tmp_root="$2"
  local product="$3"
  local artifacts_dir="$4"
  local live_home state_home expected observed sorted install_log doctor_log doctor_exit block_count

  live_home="$(runtime_live_home "$tmp_root" "$product")"
  state_home="$(runtime_state_home "$tmp_root" "$product")"
  expected="$repo_root/tests/sandbox/${product}/expected-skills.txt"
  observed="$artifacts_dir/${product}.observed-skills.txt"
  sorted="$artifacts_dir/${product}.expected.sorted"
  install_log="$artifacts_dir/${product}.install.log"
  doctor_log="$artifacts_dir/${product}.doctor.log"

  mkdir -p "$live_home" "$state_home" "$artifacts_dir"
  runtime_validate_expected_file "$expected" "$sorted" || return 1

  if ! agent-runtime render --product "$product" >"$artifacts_dir/${product}.render.log" 2>&1; then
    echo "runtime-smoke: render failed for $product" >&2
    cat "$artifacts_dir/${product}.render.log" >&2
    return 1
  fi

  if ! agent-runtime install \
    --source-root "$repo_root" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    --apply >"$install_log" 2>&1; then
    echo "runtime-smoke: install --apply failed for $product" >&2
    cat "$install_log" >&2
    return 1
  fi

  runtime_collect_installed_skills "$live_home" "$product" >"$observed"
  if [ ! -s "$observed" ]; then
    echo "runtime-smoke: no installed SKILL.md surfaces found for $product" >&2
    cat "$install_log" >&2
    return 1
  fi
  if ! diff -u "$expected" "$observed" >"$artifacts_dir/${product}.skills.diff" 2>&1; then
    echo "runtime-smoke: installed skill mismatch for $product" >&2
    cat "$artifacts_dir/${product}.skills.diff" >&2
    return 1
  fi

  set +e
  agent-runtime doctor \
    --source-root "$repo_root" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" >"$doctor_log" 2>&1
  doctor_exit=$?
  set -e

  block_count="$(runtime_doctor_block_count "$doctor_log")"
  if [ -z "$block_count" ]; then
    echo "runtime-smoke: could not parse doctor block count for $product (exit=$doctor_exit)" >&2
    cat "$doctor_log" >&2
    return 1
  fi
  if [ "$block_count" != "0" ]; then
    echo "runtime-smoke: doctor reported blocking findings for $product (exit=$doctor_exit)" >&2
    cat "$doctor_log" >&2
    return 1
  fi

  # shellcheck disable=SC2034 # consumed by run.sh after this sourced helper returns
  RUNTIME_SMOKE_SKILL_COUNT="$(wc -l <"$observed" | tr -d ' ')"
  return 0
}
