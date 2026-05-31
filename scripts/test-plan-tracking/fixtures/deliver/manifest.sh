#!/usr/bin/env bash
# Deliver-flow fixture manifest. Sourced by run.sh; variables are
# consumed by setup.sh, assert.sh, and teardown.sh after sourcing.
#
# Difference vs the happy-path fixture: the agent runs
# /deliver-plan-tracking-issue between execute and closeout, which
# opens a PR via `forge-cli pr deliver`, posts a review checkpoint,
# and runs a non-mutating close-ready probe before handoff. The
# branch prefix must therefore be `feat/...` (not `chore/...`) so
# `forge-cli pr create` accepts it.

# shellcheck disable=SC2034  # fixture variables consumed by sibling scripts.
FIXTURE_NAME="deliver"
FIXTURE_SLUG="fixture-deliver-flow"
FIXTURE_TITLE="Plan-Tracking Deliver Flow Fixture"
FIXTURE_BRANCH="feat/deliver-flow"
FIXTURE_BUNDLE_DIR="${FIXTURE_ROOT}/bundle"

# Conventional commit kind used by setup.sh when committing the bundle
# drop. Must align with the branch prefix so `forge-cli pr create
# --kind feature` is happy later.
FIXTURE_COMMIT_TYPE="feat"

# Comma-separated label list. Mirrors the create-plan-tracking-issue
# SKILL recommendation but swaps `type::chore` for `type::feature` to
# reflect the deliver flow's PR-bearing intent. At most one label per scope
# (GitLab scoped-label exclusivity): keep `workflow::tracking`, drop
# `workflow::plan`. See graysurf/plan-tracking-testbed#58.
FIXTURE_LABELS="type::feature,area::docs,state::needs-triage,workflow::tracking,plan"

# Expected lifecycle comment roles per phase, used by assert.sh.
FIXTURE_EXPECTED_ROLES_CREATE="source plan state"
FIXTURE_EXPECTED_ROLES_EXECUTE="source plan state state"
FIXTURE_EXPECTED_ROLES_DELIVER="source plan state state review"
FIXTURE_EXPECTED_ROLES_CLOSEOUT="source plan state state review closeout"

# Expected final state label after closeout (close-ready audit pass).
FIXTURE_EXPECTED_FINAL_STATE="state::closed"

# Task IDs that must appear in the state lifecycle body's `## Task Ledger`
# table. Used by assert.sh to regression-guard the rendered ledger from
# finding #9.
FIXTURE_EXPECTED_LEDGER_TASK_IDS="1.1 1.2"
