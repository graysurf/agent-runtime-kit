#!/usr/bin/env bash
# .agents/scripts/bootstrap.sh — /bootstrap dispatcher for agent-runtime-kit.
#
# Re-provision / repair path for an ALREADY-onboarded host: forwards to
# scripts/setup.sh with all flags passed through (e.g. --profile full,
# --dry-run).
#
# Not a first-time entry point. The /bootstrap skill, agent-run, and the repo
# clone all come from scripts/setup.sh itself, so a fresh host must run
# `bash scripts/setup.sh` directly.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

echo "bootstrap: re-provision/repair path — running scripts/setup.sh on an" \
  "already-onboarded host (first-time install uses 'bash scripts/setup.sh'" \
  "directly)." >&2

exec bash scripts/setup.sh "$@"
