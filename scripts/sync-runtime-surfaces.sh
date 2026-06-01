#!/usr/bin/env bash
# scripts/sync-runtime-surfaces.sh - refresh managed surfaces into local runtimes.
#
# Compatibility: must run on macOS (system bash 3.2) and Linux (bash 4+).
# Avoid associative arrays, mapfile, and `${var,,}` lowercasing.

set -euo pipefail

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

readonly PROG_NAME="sync-runtime-surfaces.sh"

APPLY=0
PRODUCT="both"
NO_PULL=0
NO_VERIFY=0
NO_PRUNE=0
SOURCE_ROOT=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_PROMPT_STATUS="not-run"
PRUNE_SKIPPED_TOTAL=0
PRUNE_LAST_SKIPPED=0

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

print_help() {
  cat <<EOF
Usage: $PROG_NAME [--apply] [--product codex|claude|both] [--source-root PATH] [--no-pull] [--no-prune] [--no-verify]

Refresh graysurf/agent-runtime-kit managed runtime surfaces into local Codex
and Claude runtime homes. This is the daily runtime surface refresh entrypoint
after source changes land. For first-time host setup, run scripts/setup.sh
first.

By default, this command is a dry-run: it prints the pull, render, install,
prune, doctor, and optional Codex prompt-input commands without mutating runtime
homes. Pass --apply to run the commands.

Options:
  --apply
      Execute the refresh. Without this flag, commands are printed only.
  --product codex|claude|both
      Limit the refresh to one product. Default: both.
  --source-root PATH
      Use a specific agent-runtime-kit checkout. Defaults to this script's
      repository root. For --apply, this must be a durable primary checkout;
      linked git worktrees and Codex transient worktrees are refused.
  --no-pull
      Skip git pull --ff-only and refresh the current checkout state.
  --no-prune
      Skip stale managed-surface pruning. With --apply, stale runtime surfaces
      may remain until a later refresh runs without this flag.
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
      --no-prune)
        NO_PRUNE=1
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

absolute_git_dir() {
  local path="$1"
  local candidate

  case "$path" in
    /*) candidate="$path" ;;
    *) candidate="$SOURCE_ROOT/$path" ;;
  esac

  if [ ! -d "$candidate" ]; then
    err "git directory does not exist: $candidate"
    exit 2
  fi

  (cd "$candidate" && pwd -P)
}

source_root_is_linked_worktree() {
  local git_dir
  local common_dir
  local git_dir_abs
  local common_dir_abs

  git_dir="$(git -C "$SOURCE_ROOT" rev-parse --git-dir)"
  common_dir="$(git -C "$SOURCE_ROOT" rev-parse --git-common-dir)"
  git_dir_abs="$(absolute_git_dir "$git_dir")"
  common_dir_abs="$(absolute_git_dir "$common_dir")"

  [ "$git_dir_abs" != "$common_dir_abs" ]
}

source_root_is_codex_transient_worktree() {
  local source_physical
  local codex_home
  local codex_worktrees

  source_physical="$(cd "$SOURCE_ROOT" && pwd -P)"
  case "$source_physical" in
    */.codex/worktrees | */.codex/worktrees/*)
      return 0
      ;;
  esac

  codex_home="${CODEX_HOME:-$HOME/.codex}"
  if [ -d "$codex_home" ]; then
    codex_worktrees="$(cd "$codex_home" && pwd -P)/worktrees"
    case "$source_physical" in
      "$codex_worktrees" | "$codex_worktrees"/*)
        return 0
        ;;
    esac
  fi

  return 1
}

validate_live_sync_source_root() {
  if [ "$APPLY" = "0" ]; then
    return 0
  fi

  if source_root_is_linked_worktree; then
    err "refusing live sync from a git worktree: $SOURCE_ROOT"
    err "sync-runtime-surfaces --apply installs runtime-home symlinks; run it from a durable primary checkout or pass --source-root to one."
    exit 2
  fi

  if source_root_is_codex_transient_worktree; then
    err "refusing live sync from a Codex transient worktree: $SOURCE_ROOT"
    err "sync-runtime-surfaces --apply installs runtime-home symlinks; use a durable primary checkout outside runtime scratch worktrees."
    exit 2
  fi
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

# Read the skipped count from one prune-stale JSON blob, accumulate it into the
# run-wide total, and surface the skipped rel_paths so the operator sees exactly
# which stale candidates prune-stale could not auto-remove. prune-stale only
# removes provably owned symlinks and empty directories; a retired recursive-file
# managed skill directory (real files, non-empty dir) is reported as skipped and
# left in place, so a blind prune=ok is misleading. See the inbox case
# core/policies/heuristic-system/error-inbox/sync-runtime-surfaces-prune-stale-dir-gap.
# Sets PRUNE_LAST_SKIPPED and bumps PRUNE_SKIPPED_TOTAL.
account_prune_skipped() {
  local product="$1"
  local json="$2"
  local skipped

  skipped="$(printf '%s\n' "$json" | json_number skipped)"
  : "${skipped:=0}"
  PRUNE_LAST_SKIPPED="$skipped"

  if [ "$skipped" -gt 0 ]; then
    PRUNE_SKIPPED_TOTAL=$((PRUNE_SKIPPED_TOTAL + skipped))
    printf '%s\n' "$json" |
      sed -n 's/.*"rel_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/  ? prune-stale left stale candidate for review (product='"$product"'): \1/p'
  fi
}

prune_product() {
  local product="$1"
  local live_home
  local prune_json
  local code
  local changes

  live_home="$(product_live_home "$product")"

  if [ "$NO_PRUNE" = "1" ]; then
    if [ "$APPLY" = "1" ]; then
      log "warning: prune skipped (--no-prune) for product=$product; stale managed runtime surfaces may remain"
    else
      log "prune skipped (--no-prune) for product=$product"
    fi
    return 0
  fi

  log "pruning stale managed surfaces product=$product live_home=$live_home"

  if [ "$APPLY" = "0" ]; then
    run_cmd agent-runtime prune-stale \
      --source-root "$SOURCE_ROOT" \
      --product "$product" \
      --live-home "$live_home" \
      --dry-run
    return 0
  fi

  print_cmd agent-runtime prune-stale \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --apply --format json

  set +e
  prune_json="$(agent-runtime prune-stale \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --apply --format json 2>&1)"
  code=$?
  set -e

  if [ "$code" -ne 0 ]; then
    printf '%s\n' "$prune_json" >&2
    err "prune-stale failed for product=$product (exit=$code); run agent-runtime prune-stale --product $product --live-home $live_home --apply for details"
    return 1
  fi

  changes="$(printf '%s\n' "$prune_json" | json_number changes)"
  account_prune_skipped "$product" "$prune_json"
  log "prune product=$product changes=${changes:-0} skipped=${PRUNE_LAST_SKIPPED:-0}"
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
  local prune_status="planned"

  if [ "$APPLY" = "1" ]; then
    mode="apply"
    doctor_status="ok"
    prune_status="ok"
    if [ "$PRUNE_SKIPPED_TOTAL" -gt 0 ]; then
      prune_status="review-needed"
    fi
  fi
  if [ "$NO_PRUNE" = "1" ]; then
    prune_status="skipped"
  fi
  if [ "$NO_VERIFY" = "1" ]; then
    doctor_status="skipped"
  fi

  log "summary: synced surfaces for $(product_label); mode=$mode; prune=$prune_status; doctor=$doctor_status; codex prompt-input=$CODEX_PROMPT_STATUS"

  if [ "$prune_status" = "review-needed" ]; then
    log "note: prune-stale could not auto-remove $PRUNE_SKIPPED_TOTAL stale candidate(s) (real files / non-empty managed dirs). Review the paths above and remove any retired managed skill directories by hand. Tracked in core/policies/heuristic-system/error-inbox/sync-runtime-surfaces-prune-stale-dir-gap."
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  local product

  parse_args "$@"
  require_commands git python3
  resolve_source_root
  validate_live_sync_source_root

  if [ "$APPLY" = "1" ]; then
    require_commands agent-runtime
  fi

  log "$PROG_NAME starting (source_root=$SOURCE_ROOT product=$PRODUCT apply=$APPLY no_pull=$NO_PULL no_prune=$NO_PRUNE no_verify=$NO_VERIFY)"

  pull_source
  check_source_counts
  for product in $(selected_products); do
    render_product "$product"
    install_product "$product"
    prune_product "$product"
  done
  run_verification
  print_summary
}

# Allow tests to source this script as a library (to exercise helpers like
# account_prune_skipped / print_summary in isolation) without running main.
if [ "${SYNC_RUNTIME_SURFACES_LIB:-0}" != "1" ]; then
  main "$@"
fi
