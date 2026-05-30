#!/usr/bin/env bash
# Print the current run's state, the latest tracking-issue snapshot, and
# the open issue list in the testbed. Read-only.

set -euo pipefail

DRIVER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${DRIVER_ROOT}/lib/common.sh"

if [ -f "${STATE_FILE}" ]; then
  printf '== run state ==\n'
  cat "${STATE_FILE}"
  printf '\n'
else
  printf '(no current run state — run setup first)\n\n'
fi

if [ -f "${STATE_DIR}/provenance.md" ]; then
  printf '== run provenance ==\n'
  cat "${STATE_DIR}/provenance.md"
  printf '\n'
fi

printf '== open issues in %s ==\n' "${TESTBED_REPO}"
forge-cli issue list --repo "${TESTBED_REPO}" --state open

printf '\n== branches on remote ==\n'
tb_remote_branches
