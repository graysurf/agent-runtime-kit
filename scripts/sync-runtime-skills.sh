#!/usr/bin/env bash
# Compatibility wrapper for the former daily runtime refresh entrypoint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
printf '%s\n' "warning: scripts/sync-runtime-skills.sh is deprecated; use scripts/sync-runtime-surfaces.sh" >&2
exec bash "$SCRIPT_DIR/sync-runtime-surfaces.sh" "$@"
