#!/usr/bin/env bash
# Phase dispatcher for the plan-tracking skill flow test driver.
#
# Usage:
#   run.sh setup [fixture]    # fixture: happy-path | deliver | dispatch
#   run.sh status
#   run.sh assert <phase>     # phase: create | execute | deliver | closeout
#   run.sh teardown
#
# Agent-in-the-loop (tracking — happy-path / deliver): between `setup`
# and the first `assert`, the agent invokes /create-plan-tracking-issue.
# Between `assert create` and `assert execute`, /execute-plan-tracking-issue.
# For fixtures that declare a deliver phase (e.g. `fixtures/deliver/`),
# the agent then invokes /deliver-plan-tracking-issue and the driver
# moves to `assert deliver`. Closeout follows in both shapes.
#
# Agent-in-the-loop (dispatch): there is no separate create skill.
# /deliver-dispatch-plan opens the shared dispatch issue (record open
# --profile dispatch); `assert create` checks it. The agent then drives
# each lane via /execute-dispatch-lane and each lane PR via
# /review-dispatch-lane-pr (`assert execute`), /deliver-dispatch-plan
# posts the dispatch rollup + close-ready handoff (`assert deliver`),
# and /dispatch-plan-closeout closes (`assert closeout`).

set -euo pipefail

DRIVER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${DRIVER_ROOT}/lib/common.sh"

cmd="${1:-help}"
shift || true

case "${cmd}" in
  setup)
    fixture="${1:-happy-path}"
    bash "${DRIVER_ROOT}/lib/setup.sh" "${fixture}"
    ;;
  status)
    bash "${DRIVER_ROOT}/lib/status.sh"
    ;;
  assert)
    phase="${1:?phase required: create | execute | deliver | closeout}"
    bash "${DRIVER_ROOT}/lib/assert.sh" "${phase}"
    ;;
  teardown)
    bash "${DRIVER_ROOT}/lib/teardown.sh"
    ;;
  help | --help | -h)
    sed -n '2,23p' "$0"
    ;;
  *)
    die "unknown command: ${cmd} (run 'run.sh help')"
    ;;
esac
