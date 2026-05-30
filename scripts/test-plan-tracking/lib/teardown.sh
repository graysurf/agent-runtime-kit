#!/usr/bin/env bash
# Wipe testbed state so the next setup runs from a known baseline.
#
# 1. Close every open issue in the testbed repo.
# 2. Delete every non-main branch (local + remote).
# 3. Hard-reset local main to origin.
# 4. Drop the run state file.

set -euo pipefail

DRIVER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${DRIVER_ROOT}/lib/common.sh"

quiet=false
if [ "${1:-}" = "--quiet" ]; then
  quiet=true
fi

require_cmd forge-cli
require_cmd git

[ -d "${TESTBED_ROOT}/.git" ] ||
  die "testbed not found at ${TESTBED_ROOT}"

# Close every open *e2e fixture* issue, but preserve the durable
# plan-issue-finding tracker issues — this repo doubles as the bug
# tracker for the plan-issue / plan-tracking skill family, and those
# issues must survive driver resets.
$quiet || log "closing open e2e issues in ${TESTBED_REPO} (preserving plan-issue-finding)…"
open_issues=$(tb_open_issues_except_finding 2>/dev/null || true)
if [ -n "${open_issues}" ]; then
  while IFS= read -r n; do
    [ -z "${n}" ] && continue
    $quiet || log "  closing #${n}"
    tb_issue_close "${n}" \
      "Test teardown — closed by scripts/test-plan-tracking/teardown.sh."
  done <<<"${open_issues}"
fi

$quiet || log "deleting non-main remote branches…"
remote_branches=$(tb_remote_branches | grep -v '^main$' || true)
if [ -n "${remote_branches}" ]; then
  while IFS= read -r b; do
    [ -z "${b}" ] && continue
    $quiet || log "  deleting remote branch ${b}"
    tb_remote_branch_delete "${b}" >/dev/null
  done <<<"${remote_branches}"
fi

$quiet || log "resetting local main…"
testbed_git fetch origin --prune --quiet
# Force the switch so an uncommitted working tree never blocks teardown.
# Flows append working-tree edits to the bundle execution-state via
# `plan-tooling ledger-update`; teardown is destructive by design, so those
# edits must be discarded, not preserved (`checkout main` without `-f` aborts
# on a dirty tree).
testbed_git checkout -f main --quiet 2>/dev/null ||
  testbed_git checkout -fB main origin/main --quiet
testbed_git reset --hard origin/main --quiet

$quiet || log "deleting local non-main branches…"
local_branches=$(testbed_git branch --format '%(refname:short)' |
  grep -v '^main$' || true)
if [ -n "${local_branches}" ]; then
  while IFS= read -r b; do
    [ -z "${b}" ] && continue
    $quiet || log "  deleting local branch ${b}"
    testbed_git branch -D "${b}" --quiet
  done <<<"${local_branches}"
fi

if [ -f "${STATE_FILE}" ]; then
  rm -f "${STATE_FILE}"
fi

$quiet || log "teardown done."
