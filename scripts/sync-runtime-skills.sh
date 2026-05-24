#!/usr/bin/env bash
# scripts/sync-runtime-skills.sh - refresh rendered skills into local runtimes.
#
# Compatibility: must run on macOS (system bash 3.2) and Linux (bash 4+).
# Avoid associative arrays, mapfile, and `${var,,}` lowercasing.

set -euo pipefail

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

readonly PROG_NAME="sync-runtime-skills.sh"

APPLY=0
PRODUCT="both"
NO_PULL=0
NO_VERIFY=0
SOURCE_ROOT=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_PROMPT_STATUS="not-run"

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

print_help() {
  cat <<EOF
Usage: $PROG_NAME [--apply] [--product codex|claude|both] [--source-root PATH] [--no-pull] [--no-verify]

Refresh graysurf/agent-runtime-kit skills into local Codex and Claude runtime
homes. This is the daily skill refresh entrypoint after source changes land.
For first-time host setup, run scripts/setup.sh first.

By default, this command is a dry-run: it prints the pull, render, install,
doctor, and optional Codex prompt-input commands without mutating runtime homes.
Pass --apply to run the commands.

Options:
  --apply
      Execute the refresh. Without this flag, commands are printed only.
  --product codex|claude|both
      Limit the refresh to one product. Default: both.
  --source-root PATH
      Use a specific agent-runtime-kit checkout. Defaults to this script's
      repository root.
  --no-pull
      Skip git pull --ff-only and refresh the current checkout state.
  --no-verify
      Skip post-install skill-surface doctor and Codex prompt-input probes.
  -h, --help
      Print this help and exit.
EOF
}

# -----------------------------------------------------------------------------
# Logging helpers
# -----------------------------------------------------------------------------

log() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

print_cmd() {
  printf '+'
  while [ "$#" -gt 0 ]; do
    printf ' %q' "$1"
    shift
  done
  printf '\n'
}

run_cmd() {
  print_cmd "$@"
  if [ "$APPLY" = "0" ]; then
    return 0
  fi
  "$@"
}

require_commands() {
  local missing=""
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing="${missing}${cmd}
"
    fi
  done
  if [ -n "$missing" ]; then
    err "missing required command(s):"
    printf '%s' "$missing" | sed 's/^/  - /' >&2
    exit 127
  fi
}

# -----------------------------------------------------------------------------
# Arg parsing and path resolution
# -----------------------------------------------------------------------------

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --apply)
        APPLY=1
        shift
        ;;
      --dry-run)
        APPLY=0
        shift
        ;;
      --product)
        if [ "$#" -lt 2 ]; then
          err "--product requires a value"
          exit 2
        fi
        PRODUCT="$2"
        shift 2
        ;;
      --product=*)
        PRODUCT="${1#--product=}"
        shift
        ;;
      --source-root)
        if [ "$#" -lt 2 ]; then
          err "--source-root requires a value"
          exit 2
        fi
        SOURCE_ROOT="$2"
        shift 2
        ;;
      --source-root=*)
        SOURCE_ROOT="${1#--source-root=}"
        shift
        ;;
      --no-pull)
        NO_PULL=1
        shift
        ;;
      --no-verify)
        NO_VERIFY=1
        shift
        ;;
      -h | --help)
        print_help
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        err "unknown argument: $1"
        echo
        print_help
        exit 2
        ;;
    esac
  done

  case "$PRODUCT" in
    codex | claude | both) ;;
    *)
      err "invalid --product value: $PRODUCT (expected codex|claude|both)"
      exit 2
      ;;
  esac
}

resolve_source_root() {
  local root_candidate
  local top_level

  if [ -n "$SOURCE_ROOT" ]; then
    root_candidate="$SOURCE_ROOT"
  else
    root_candidate="$SCRIPT_DIR/.."
  fi

  if [ ! -d "$root_candidate" ]; then
    err "source root does not exist: $root_candidate"
    exit 2
  fi

  if ! top_level="$(git -C "$root_candidate" rev-parse --show-toplevel 2>/dev/null)"; then
    err "source root is not inside a git checkout: $root_candidate"
    exit 2
  fi

  SOURCE_ROOT="$(cd "$top_level" && pwd)"
}

selected_products() {
  case "$PRODUCT" in
    codex) printf '%s\n' codex ;;
    claude) printf '%s\n' claude ;;
    both)
      printf '%s\n' codex
      printf '%s\n' claude
      ;;
  esac
}

product_label() {
  case "$PRODUCT" in
    codex) printf '%s\n' codex ;;
    claude) printf '%s\n' claude ;;
    both) printf '%s\n' codex+claude ;;
  esac
}

selected_includes_codex() {
  case "$PRODUCT" in
    codex | both) return 0 ;;
    claude) return 1 ;;
  esac
}

product_live_home() {
  case "$1" in
    claude) printf '%s\n' "$HOME/.claude" ;;
    codex) printf '%s\n' "${CODEX_HOME:-$HOME/.codex}" ;;
    *)
      err "unknown product: $1"
      exit 2
      ;;
  esac
}

product_state_home() {
  local state_root="${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit"
  case "$1" in
    claude) printf '%s\n' "${CLAUDE_KIT_STATE_HOME:-$state_root/claude}" ;;
    codex) printf '%s\n' "${CODEX_AGENT_STATE_HOME:-$state_root/codex}" ;;
    *)
      err "unknown product: $1"
      exit 2
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Refresh steps
# -----------------------------------------------------------------------------

pull_source() {
  if [ "$NO_PULL" = "1" ]; then
    log "git pull skipped (--no-pull)"
    return 0
  fi
  run_cmd git -C "$SOURCE_ROOT" pull --ff-only
}

check_source_counts() {
  local audit_script="$SOURCE_ROOT/scripts/ci/skill-governance-audit.sh"

  if [ ! -f "$audit_script" ]; then
    err "source root is missing skill governance audit: $audit_script"
    exit 2
  fi

  log "checking source skill counts"
  print_cmd bash "$audit_script" --check-counts
  bash "$audit_script" --check-counts
}

render_product() {
  local product="$1"
  log "rendering product=$product"
  run_cmd agent-runtime render \
    --source-root "$SOURCE_ROOT" \
    --product "$product"
}

install_product() {
  local product="$1"
  local live_home
  local state_home
  local mode_flag="--dry-run"

  if [ "$APPLY" = "1" ]; then
    mode_flag="--apply"
  fi

  live_home="$(product_live_home "$product")"
  state_home="$(product_state_home "$product")"

  log "installing product=$product live_home=$live_home"
  run_cmd agent-runtime install \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    "$mode_flag"
}

json_number() {
  local key="$1"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\\([0-9][0-9]*\\).*/\\1/p" | head -n 1
}

doctor_product() {
  local product="$1"
  local live_home
  local state_home
  local doctor_json
  local code
  local block
  local checks
  local exit_code

  live_home="$(product_live_home "$product")"
  state_home="$(product_state_home "$product")"

  if [ "$APPLY" = "0" ]; then
    run_cmd agent-runtime doctor \
      --source-root "$SOURCE_ROOT" \
      --product "$product" \
      --live-home "$live_home" \
      --state-home "$state_home" \
      --class skill-surface \
      --format json
    return 0
  fi

  print_cmd agent-runtime doctor \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    --class skill-surface \
    --format json

  set +e
  doctor_json="$(agent-runtime doctor \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    --class skill-surface \
    --format json 2>&1)"
  code=$?
  set -e

  block="$(printf '%s\n' "$doctor_json" | json_number block)"
  checks="$(printf '%s\n' "$doctor_json" | json_number checks)"
  exit_code="$(printf '%s\n' "$doctor_json" | json_number exit_code)"

  if [ "$code" -ne 0 ] || [ -z "$block" ] || [ "$block" -gt 0 ]; then
    printf '%s\n' "$doctor_json" >&2
    err "doctor failed for product=$product (exit=$code block=${block:-unknown}); run agent-runtime doctor --product $product --class skill-surface --format json for details"
    return 1
  fi

  log "doctor product=$product ok (checks=${checks:-unknown} block=$block exit=${exit_code:-$code})"
}

verify_codex_prompt_input() {
  if ! selected_includes_codex; then
    CODEX_PROMPT_STATUS="skipped"
    log "codex prompt-input skipped (product=$PRODUCT)"
    return 0
  fi

  if ! command -v codex >/dev/null 2>&1; then
    CODEX_PROMPT_STATUS="skipped"
    log "codex prompt-input skipped (binary not on PATH)"
    return 0
  fi

  if [ "$APPLY" = "0" ]; then
    CODEX_PROMPT_STATUS="planned"
    run_cmd codex debug prompt-input
    return 0
  fi

  CODEX_PROMPT_STATUS="verified"
  run_cmd codex debug prompt-input
}

run_verification() {
  local product

  if [ "$NO_VERIFY" = "1" ]; then
    CODEX_PROMPT_STATUS="skipped"
    log "verification skipped (--no-verify)"
    return 0
  fi

  for product in $(selected_products); do
    doctor_product "$product"
  done

  verify_codex_prompt_input
}

print_summary() {
  local mode="dry-run"
  local doctor_status="planned"

  if [ "$APPLY" = "1" ]; then
    mode="apply"
    doctor_status="ok"
  fi
  if [ "$NO_VERIFY" = "1" ]; then
    doctor_status="skipped"
  fi

  log "summary: synced skills for $(product_label); mode=$mode; doctor=$doctor_status; codex prompt-input=$CODEX_PROMPT_STATUS"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  local product

  parse_args "$@"
  require_commands git
  resolve_source_root

  if [ "$APPLY" = "1" ]; then
    require_commands agent-runtime
  fi

  log "$PROG_NAME starting (source_root=$SOURCE_ROOT product=$PRODUCT apply=$APPLY no_pull=$NO_PULL no_verify=$NO_VERIFY)"

  pull_source
  check_source_counts
  for product in $(selected_products); do
    render_product "$product"
    install_product "$product"
  done
  run_verification
  print_summary
}

main "$@"
