#!/usr/bin/env bash
# scripts/setup.sh — host bootstrap skeleton.
#
# Plan 01 ships this as a SKELETON. The `brew tap` / `brew install` plumbing,
# profile parsing, and clone-on-missing block are real; the actual product
# activation calls (`agent-runtime install --product claude` /
# `agent-runtime install --product codex`) are stubbed and deferred to
# Plan 04 (`04-install-and-bootstrap`).
#
# Compatibility: must run on macOS (system bash 3.2) and Linux (bash 4+).
# Avoid associative arrays, mapfile, and `${var,,}` lowercasing.
#
# References:
#   - docs/source/inventory-target-architecture.md `### Brew-First Bootstrap`
#   - manifests/cli-tools.yaml (third-party CLI catalog this script installs)

set -euo pipefail

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

readonly PROG_NAME="setup.sh"
readonly REPO_HOME_DEFAULT="$HOME/.config/agent-runtime-kit"
readonly REPO_REMOTE_DEFAULT="https://github.com/graysurf/agent-runtime-kit.git"
readonly TAP_SPEC="sympoies/tap"
readonly TAP_FORMULA="sympoies/tap/nils-cli"
readonly STUB_BANNER="[stub] agent-runtime install ..."

PROFILE="core"
SKIP_HOMEBREW_INSTALL=0
DRY_RUN=0

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

print_help() {
  cat <<EOF
Usage: $PROG_NAME [--profile core|recommended|full] [--skip-homebrew-install] [--dry-run]

Bootstrap a host so it can run graysurf/agent-runtime-kit. Installs Homebrew
when missing, taps sympoies/tap, installs nils-cli (which ships the
agent-runtime binary), installs the profile-selected third-party CLI tools
from manifests/cli-tools.yaml, clones agent-runtime-kit into
\$HOME/.config/agent-runtime-kit when missing, and (in Plan 04) activates
each product runtime home via \`agent-runtime install --product <p>\`.

Options:
  --profile core|recommended|full
      Pick the third-party CLI install set defined in manifests/cli-tools.yaml.
      core         minimum daily-use floor (7 tools).
      recommended  productivity tools every author touches (~17 tools).
      full         everything from core/policies/cli-tools.md.
      Default: core.
  --skip-homebrew-install
      Skip the \`brew\` install step (useful for CI runners and Linuxbrew
      hosts that pre-install brew separately).
  --dry-run
      Print every command that WOULD run, without executing brew / git /
      agent-runtime. The agent-runtime activation calls are stubbed regardless
      of this flag (deferred to Plan 04); --dry-run additionally skips brew
      install, git clone, and tap.
  -h, --help
      Print this help and exit.
EOF
}

# -----------------------------------------------------------------------------
# Logging helpers
# -----------------------------------------------------------------------------

log() { printf '%s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
err() { printf 'error: %s\n' "$*" >&2; }

run_cmd() {
  # When --dry-run, echo the command instead of executing it.
  if [ "$DRY_RUN" = "1" ]; then
    log "+ $*"
    return 0
  fi
  log "+ $*"
  "$@"
}

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        if [ "$#" -lt 2 ]; then
          err "--profile requires a value"
          exit 2
        fi
        PROFILE="$2"
        shift 2
        ;;
      --profile=*)
        PROFILE="${1#--profile=}"
        shift
        ;;
      --skip-homebrew-install)
        SKIP_HOMEBREW_INSTALL=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
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

  case "$PROFILE" in
    core|recommended|full) ;;
    *)
      err "invalid --profile value: $PROFILE (expected core|recommended|full)"
      exit 2
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Phase implementations
# -----------------------------------------------------------------------------

detect_host() {
  # Detect platform via brew --prefix; fall back to uname when brew is absent.
  if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix 2>/dev/null || echo "")"
    if [ -n "${BREW_PREFIX:-}" ]; then
      log "detected brew prefix: $BREW_PREFIX"
    fi
  else
    BREW_PREFIX=""
    log "detected platform: $(uname -s) (brew not yet installed)"
  fi
}

ensure_homebrew() {
  if [ "$SKIP_HOMEBREW_INSTALL" = "1" ]; then
    log "skipping homebrew install (--skip-homebrew-install)"
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    log "brew already on PATH"
    return 0
  fi
  if [ "$DRY_RUN" = "1" ]; then
    log "+ /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 0
  fi
  err "Homebrew is not installed. Re-run with --dry-run to preview the install command, or install brew first."
  exit 1
}

tap_and_install_nils_cli() {
  run_cmd brew tap "$TAP_SPEC"
  run_cmd brew install "$TAP_FORMULA"
}

install_cli_tools_profile() {
  # The full reader is Plan 04 work; this skeleton just announces intent.
  log "select profile=$PROFILE from manifests/cli-tools.yaml (resolver deferred to Plan 04)"
  if [ "$DRY_RUN" = "1" ]; then
    log "+ brew install \$(yq -r \".profiles.$PROFILE[]\" manifests/cli-tools.yaml | xargs -I{} yq -r \".formulas.{}.brew\" manifests/cli-tools.yaml)"
  fi
}

ensure_repo_clone() {
  if [ -d "$REPO_HOME_DEFAULT/.git" ]; then
    log "agent-runtime-kit already cloned at $REPO_HOME_DEFAULT"
    return 0
  fi
  run_cmd git clone "$REPO_REMOTE_DEFAULT" "$REPO_HOME_DEFAULT"
}

activate_products() {
  # defer to Plan 04
  #
  # These are the real activation calls per Brew-First Bootstrap step 6.
  # Plan 01 ships them as STUBS — they print a banner and return 0 — so the
  # install ladder is reviewable end-to-end without mutating a live ~/.codex
  # or ~/.claude home. Plan 04 replaces these with real invocations.
  log "$STUB_BANNER --product claude"
  log "$STUB_BANNER --product codex"
}

run_doctor() {
  log "+ agent-runtime doctor"
  log "$STUB_BANNER doctor (defer to Plan 04)"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  parse_args "$@"

  log "$PROG_NAME starting (profile=$PROFILE skip_homebrew=$SKIP_HOMEBREW_INSTALL dry_run=$DRY_RUN)"

  detect_host
  ensure_homebrew
  tap_and_install_nils_cli
  install_cli_tools_profile
  ensure_repo_clone
  activate_products
  run_doctor

  log "$PROG_NAME complete"
}

main "$@"
