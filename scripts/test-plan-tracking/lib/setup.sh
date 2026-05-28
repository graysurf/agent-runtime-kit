#!/usr/bin/env bash
# Prepare the testbed for a fresh run of the named fixture.
#
# 1. Sanity-check the testbed checkout and clean its working tree.
# 2. Run teardown.sh first so we always start from a known state.
# 3. Copy fixture bundle into docs/plans/<slug>/ in the testbed.
# 4. Create the test branch and commit the bundle (NOT pushed yet — the
#    create-plan-tracking-issue skill prereq says committed + pushed,
#    so the script pushes too).
# 5. Persist the run state for later phases.

set -euo pipefail

DRIVER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${DRIVER_ROOT}/lib/common.sh"

fixture="${1:?fixture name required}"
load_fixture "${fixture}"

require_cmd gh
require_cmd git
require_cmd plan-tooling
require_cmd plan-issue

[ -d "${TESTBED_ROOT}/.git" ] ||
  die "testbed not found at ${TESTBED_ROOT} (clone graysurf/plan-tracking-testbed first)"

log "running teardown to ensure clean starting state…"
bash "${DRIVER_ROOT}/lib/teardown.sh" --quiet

log "fetching latest main…"
testbed_git fetch origin main --quiet
testbed_git checkout main --quiet
testbed_git reset --hard origin/main --quiet

log "creating test branch ${FIXTURE_BRANCH}…"
testbed_git checkout -b "${FIXTURE_BRANCH}"

log "copying fixture bundle into docs/plans/${FIXTURE_SLUG}/…"
target_dir="${TESTBED_ROOT}/docs/plans/${FIXTURE_SLUG}"
mkdir -p "${target_dir}"
cp "${FIXTURE_BUNDLE_DIR}"/*.md "${target_dir}/"

log "validating plan markdown in canonical position…"
(cd "${TESTBED_ROOT}" &&
  plan-tooling validate \
    --file "docs/plans/${FIXTURE_SLUG}/${FIXTURE_SLUG}-plan.md" \
    --format json) |
  tee "${STATE_DIR}/plan-validate.json" |
  grep -q '"ok":true' ||
  die "plan-tooling validate failed; see ${STATE_DIR}/plan-validate.json"

log "committing fixture bundle…"
testbed_git add "docs/plans/${FIXTURE_SLUG}/"
(cd "${TESTBED_ROOT}" &&
  semantic-commit commit --message "$(
    cat <<EOF
chore: drop happy-path plan bundle for skill flow test

- Bundle copied from agent-runtime-kit/scripts/test-plan-tracking/
  fixtures/${fixture} for a single test run.
- Slug: ${FIXTURE_SLUG}.
EOF
  )") >/dev/null

log "pushing test branch to origin…"
testbed_git push -u origin "${FIXTURE_BRANCH}" --quiet

state_save \
  "FIXTURE_NAME=${FIXTURE_NAME}" \
  "FIXTURE_SLUG=${FIXTURE_SLUG}" \
  "FIXTURE_TITLE=${FIXTURE_TITLE}" \
  "FIXTURE_BRANCH=${FIXTURE_BRANCH}" \
  "FIXTURE_LABELS=${FIXTURE_LABELS}" \
  "FIXTURE_EXPECTED_ROLES_CREATE=${FIXTURE_EXPECTED_ROLES_CREATE}" \
  "FIXTURE_EXPECTED_ROLES_EXECUTE=${FIXTURE_EXPECTED_ROLES_EXECUTE}" \
  "FIXTURE_EXPECTED_ROLES_CLOSEOUT=${FIXTURE_EXPECTED_ROLES_CLOSEOUT}" \
  "FIXTURE_EXPECTED_FINAL_STATE=${FIXTURE_EXPECTED_FINAL_STATE}" \
  "TESTBED_REPO=${TESTBED_REPO}" \
  "TESTBED_ROOT=${TESTBED_ROOT}" \
  "BUNDLE_PATH=${TESTBED_ROOT}/docs/plans/${FIXTURE_SLUG}" \
  "PHASE=setup"

cat <<EOM

==============================================================
setup complete.

Next step (agent action):
  invoke /create-plan-tracking-issue with:
    OWNER_REPO   = ${TESTBED_REPO}
    PLAN_BUNDLE  = ${TESTBED_ROOT}/docs/plans/${FIXTURE_SLUG}
    PLAN         = ${TESTBED_ROOT}/docs/plans/${FIXTURE_SLUG}/${FIXTURE_SLUG}-plan.md
    SLUG         = ${FIXTURE_SLUG}
    TITLE        = ${FIXTURE_TITLE}
    BRANCH       = ${FIXTURE_BRANCH}
    LABELS       = ${FIXTURE_LABELS}

When the skill has finished, run:
  bash scripts/test-plan-tracking/run.sh assert create
==============================================================
EOM
