#!/usr/bin/env bash
# Dispatch-flow fixture manifest. Sourced by run.sh; variables are
# consumed by setup.sh, assert.sh, and teardown.sh after sourcing.
#
# Difference vs the tracking fixtures: this exercises the *dispatch*
# profile. There is no separate create skill — `deliver-dispatch-plan`
# opens the shared dispatch issue via `record open --profile dispatch`,
# then dispatches two task lanes. Each lane (`execute-dispatch-lane`)
# bases its PR on the shared plan branch (`FIXTURE_BRANCH`) and posts a
# lane-scoped state / session / validation checkpoint; each lane PR is
# reviewed (`review-dispatch-lane-pr`); `dispatch-plan-closeout` closes
# the shared issue after every lane PR is merged.

# shellcheck disable=SC2034  # fixture variables consumed by sibling scripts.
FIXTURE_NAME="dispatch"
FIXTURE_SLUG="fixture-dispatch-flow"
FIXTURE_TITLE="Plan-Tracking Dispatch Flow Fixture"
# Shared plan / integration branch each lane PR targets.
FIXTURE_BRANCH="feat/dispatch-flow"
FIXTURE_BUNDLE_DIR="${FIXTURE_ROOT}/bundle"

# Conventional commit kind used by setup.sh when committing the bundle
# drop onto the plan branch. Matches the dispatch `type::chore` label.
FIXTURE_COMMIT_TYPE="chore"

# Lifecycle profile. Drives `record open --profile dispatch`, the
# profile=dispatch marker assertion, and the dispatch dashboard /
# multi-lane PR checks in assert.sh. Tracking fixtures omit this (it
# defaults to `tracking`).
FIXTURE_PROFILE="dispatch"

# Dispatch lane task ids (one lane per task) and their PR head branches.
# assert.sh uses FIXTURE_LANE_BRANCHES to resolve and verify that every
# lane PR is merged.
FIXTURE_LANES="1.1 1.2"
FIXTURE_LANE_BRANCHES="feat/dispatch-flow-lane-1 feat/dispatch-flow-lane-2"

# Comma-separated label list. Mirrors the deliver-dispatch-plan SKILL
# recommendation: type::chore + workflow::dispatch (not workflow::tracking).
# At most one label per scope (GitLab scoped-label exclusivity): keep
# `workflow::dispatch`, drop `workflow::plan`. See
# graysurf/plan-tracking-testbed#58.
FIXTURE_LABELS="type::chore,area::docs,state::needs-triage,workflow::dispatch,plan"

# Expected lifecycle comment roles per phase, used by assert.sh. Lane
# checkpoints add session + validation; lane reviews add review.
FIXTURE_EXPECTED_ROLES_CREATE="source plan state"
FIXTURE_EXPECTED_ROLES_EXECUTE="source plan state session validation"
FIXTURE_EXPECTED_ROLES_DELIVER="source plan state session validation review"
FIXTURE_EXPECTED_ROLES_CLOSEOUT="source plan state session validation review closeout"

# Expected final state label after closeout (close-ready audit pass).
FIXTURE_EXPECTED_FINAL_STATE="state::closed"

# Task IDs that must appear in the state lifecycle body's `## Task Ledger`
# table — one per lane. Space-separated.
FIXTURE_EXPECTED_LEDGER_TASK_IDS="1.1 1.2"
