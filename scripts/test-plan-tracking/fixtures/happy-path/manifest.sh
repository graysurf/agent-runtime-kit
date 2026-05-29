#!/usr/bin/env bash
# Happy-path fixture manifest. Sourced by run.sh; variables are
# consumed by setup.sh, assert.sh, and teardown.sh after sourcing.

# shellcheck disable=SC2034  # fixture variables consumed by sibling scripts.
FIXTURE_NAME="happy-path"
FIXTURE_SLUG="fixture-happy-path-flow"
FIXTURE_TITLE="Plan-Tracking Happy Path Flow Fixture"
FIXTURE_BRANCH="chore/happy-path-flow"
FIXTURE_BUNDLE_DIR="${FIXTURE_ROOT}/bundle"

# Comma-separated label list (forge-labels.yaml entries) chosen for the
# tracking issue. Matches create-plan-tracking-issue SKILL recommendation
# plus the rollout `plan` label.
FIXTURE_LABELS="type::chore,area::docs,state::needs-triage,workflow::plan,workflow::tracking,plan"

# Expected lifecycle comment roles in order, used by assert.sh. The lightweight
# happy-path has no deliver/PR, so its completion `review` is recorded at
# closeout: `tracking close-ready` reports `review-missing` and the
# plan-tracking-issue-closeout preflight posts a `review` (+ final complete
# `state`) before `record close`. Hence `review` appears in the closeout role
# set even though there is no deliver phase.
FIXTURE_EXPECTED_ROLES_CREATE="source plan state"
FIXTURE_EXPECTED_ROLES_EXECUTE="source plan state state"
FIXTURE_EXPECTED_ROLES_CLOSEOUT="source plan state state review closeout"

# Expected final state label after closeout (close-ready audit pass).
FIXTURE_EXPECTED_FINAL_STATE="state::closed"

# Task IDs that must appear in the state lifecycle body's `## Task Ledger`
# table. Used by assert.sh to regression-guard the rendered ledger from
# finding #9 (state body rendered single-row "selected" instead of the
# full per-task ledger). Space-separated.
FIXTURE_EXPECTED_LEDGER_TASK_IDS="1.1 1.2"
