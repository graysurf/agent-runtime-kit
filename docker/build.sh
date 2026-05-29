#!/usr/bin/env bash
# docker/build.sh — build the agent-runtime-kit image with the nils-cli version
# taken from docs/source/nils-cli-pin.yaml (the repo's authoritative pin gate,
# enforced by scripts/ci/all.sh Position 2). This keeps the pin single-sourced:
# bump the pin file and the image follows, with no version hardcoded here.
#
# Usage:
#   docker/build.sh [-t TAG] [-n] [-- <extra docker build args>]
#
# Examples:
#   docker/build.sh                          # -> agent-runtime-kit:dev
#   docker/build.sh -t agent-runtime-kit:0.28.1
#   docker/build.sh -n                       # print the resolved command only
#   docker/build.sh -- --platform linux/amd64 --no-cache
#
# Compatibility: macOS system bash 3.2 and Linux bash. No bash-4 features.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIN_FILE="$REPO_ROOT/docs/source/nils-cli-pin.yaml"
DOCKERFILE="$REPO_ROOT/docker/Dockerfile"

IMAGE_TAG="agent-runtime-kit:dev"
DRY_RUN=0
EXTRA=""

usage() { sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    -t | --tag)
      [ "$#" -ge 2 ] || {
        echo "error: $1 requires a value" >&2
        exit 2
      }
      IMAGE_TAG="$2"
      shift 2
      ;;
    -n | --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      EXTRA="$*"
      break
      ;;
    *)
      echo "error: unknown argument: $1 (use -- to pass docker build flags)" >&2
      exit 2
      ;;
  esac
done

[ -f "$PIN_FILE" ] || {
  echo "error: pin file not found: $PIN_FILE" >&2
  exit 1
}

# Resolve pinned_tag (e.g. "v0.28.1"). Prefer yq; fall back to sed so the
# script works on a host without yq.
PIN=""
if command -v yq >/dev/null 2>&1; then
  PIN="$(yq -r '.nils_cli.pinned_tag' "$PIN_FILE" 2>/dev/null || true)"
fi
if [ -z "$PIN" ] || [ "$PIN" = "null" ]; then
  PIN="$(sed -n -E 's/^[[:space:]]*pinned_tag:[[:space:]]*"?([^"#]+)"?.*/\1/p' "$PIN_FILE" | head -1)"
  PIN="$(printf '%s' "$PIN" | tr -d '[:space:]')"
fi
[ -n "$PIN" ] || {
  echo "error: could not read nils_cli.pinned_tag from $PIN_FILE" >&2
  exit 1
}

echo "nils-cli pin : $PIN  (from docs/source/nils-cli-pin.yaml)"
echo "image tag    : $IMAGE_TAG"

# shellcheck disable=SC2086  # EXTRA is an intentional word-split passthrough.
set -- docker build -f "$DOCKERFILE" \
  --build-arg "NILS_CLI_VERSION=$PIN" \
  -t "$IMAGE_TAG" \
  $EXTRA \
  "$REPO_ROOT"

printf '+ '
printf '%q ' "$@"
printf '\n'
if [ "$DRY_RUN" = "1" ]; then
  exit 0
fi
exec "$@"
