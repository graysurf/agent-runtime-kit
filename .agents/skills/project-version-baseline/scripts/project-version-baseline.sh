#!/usr/bin/env bash
# project-version-baseline.sh — thin entrypoint for the version-baseline skill.
#
# Delegates to the canonical CI audit (scripts/ci/version-baseline-audit.py) so
# the skill and `scripts/ci/all.sh` Position 14 share one implementation.
#
#   check   deterministic, network-free consistency gate (default; exit 1 on drift)
#   report  advisory installed-vs-latest probe + the gate result (always exit 0)
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  project-version-baseline.sh [check|report]

Modes:
  check    Deterministic consistency gate over the version-baseline mirrors
           (README table, harness-shape docs, nils-cli-surface) vs their
           sources of truth (runtime-roots.yaml, nils-cli-pin.yaml).
           Exit 1 on any drift. Default.
  report   Advisory: probe installed + latest (npm) for codex / claude and
           print floor/installed/latest verdicts, then the gate result.

Options:
  -h, --help   Show this help.
USAGE
}

mode="check"
while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -h | --help)
      usage
      exit 0
      ;;
    check | report)
      mode="$1"
      shift
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$repo_root" ]; then
  echo "error: must run inside the agent-runtime-kit git work tree" >&2
  exit 1
fi

audit="$repo_root/scripts/ci/version-baseline-audit.py"
if [ ! -f "$audit" ]; then
  echo "error: missing $audit (run inside agent-runtime-kit)" >&2
  exit 1
fi

exec python3 "$audit" "$mode"
