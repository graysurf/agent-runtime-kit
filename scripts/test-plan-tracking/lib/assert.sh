#!/usr/bin/env bash
# Shape-only assertions on the tracking issue for the current run phase.
#
# Phases:
#   create    — issue exists; labels match; source/plan/state markers
#               present in body+comments at least once each.
#   execute   — issue still open; ≥2 distinct state-role comments.
#   deliver   — issue still open; ≥1 review-role comment posted; the
#               final state body still carries the full Task Ledger; and
#               the linked PR (resolved by head branch) is MERGED with a
#               real merge SHA. (Only used by fixtures that declare
#               FIXTURE_EXPECTED_ROLES_DELIVER.)
#   closeout  — issue closed; closeout-role comment present;
#               state label transitioned to FIXTURE_EXPECTED_FINAL_STATE.
#
# Output is PASS / FAIL lines per check, plus a final summary line. A
# non-zero exit means at least one check failed.

set -euo pipefail

DRIVER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${DRIVER_ROOT}/lib/common.sh"

phase="${1:?phase required: create | execute | closeout}"
state_load

require_cmd gh
require_cmd jq

snap_dir="${STATE_DIR}/snapshots/${phase}"
mkdir -p "${snap_dir}"

log "looking up tracking issue by title…"
issue_number=$(gh issue list \
  --repo "${TESTBED_REPO}" \
  --state all \
  --limit 10 \
  --search "in:title \"${FIXTURE_TITLE}\"" \
  --json number,title,state \
  --jq ".[] | select(.title == \"${FIXTURE_TITLE}\") | .number" |
  head -1)

if [ -z "${issue_number}" ]; then
  echo "FAIL: no tracking issue found with title '${FIXTURE_TITLE}'"
  exit 1
fi

log "found issue #${issue_number}; snapshotting…"
gh issue view "${issue_number}" \
  --repo "${TESTBED_REPO}" \
  --json number,title,state,labels,body,comments \
  >"${snap_dir}/issue.json"

state_update "ISSUE_NUMBER=${issue_number}"

# ---- Collect facts ----------------------------------------------------

issue_state=$(jq -r '.state' "${snap_dir}/issue.json")
label_names=$(jq -r '.labels[].name' "${snap_dir}/issue.json" | sort -u)

# Extract role markers from body + all comment bodies. Markers look
# like `<!-- plan-issue-record:v2 role=<role> ... -->`.
{
  jq -r '.body' "${snap_dir}/issue.json"
  jq -r '.comments[].body' "${snap_dir}/issue.json"
} >"${snap_dir}/all-text.md"

roles_present=$(grep -oE 'plan-issue-record:v[0-9]+ role=[a-z][a-z0-9_-]*' \
  "${snap_dir}/all-text.md" |
  sed -E 's/.*role=//' |
  sort -u)

role_counts=$(grep -oE 'plan-issue-record:v[0-9]+ role=[a-z][a-z0-9_-]*' \
  "${snap_dir}/all-text.md" |
  sed -E 's/.*role=//' |
  sort | uniq -c | awk '{print $2"="$1}')

printf 'phase: %s\n' "${phase}"
printf 'issue: #%s (%s)\n' "${issue_number}" "${issue_state}"
printf 'labels:\n'
# Intentional word-splitting: each name on its own line.
# shellcheck disable=SC2086
printf '  %s\n' ${label_names}
printf 'role markers (unique):\n'
# shellcheck disable=SC2086
printf '  %s\n' ${roles_present}
printf 'role counts:\n'
# shellcheck disable=SC2086
printf '  %s\n' ${role_counts}
printf '\n'

# ---- Generic checks (every phase) -------------------------------------

fail_count=0
pass() { printf 'PASS: %s\n' "$*"; }
fail() {
  printf 'FAIL: %s\n' "$*"
  fail_count=$((fail_count + 1))
}

check_label_present() {
  local label="$1"
  if echo "${label_names}" | grep -qx "${label}"; then
    pass "label present: ${label}"
  else
    fail "label missing: ${label}"
  fi
}

check_role_present() {
  local role="$1"
  if echo "${roles_present}" | grep -qx "${role}"; then
    pass "role marker present: ${role}"
  else
    fail "role marker missing: ${role}"
  fi
}

check_role_min_count() {
  local role="$1" min="$2"
  local n
  n=$(echo "${role_counts}" | awk -F= -v r="${role}" '$1==r{print $2}')
  n="${n:-0}"
  if [ "${n}" -ge "${min}" ]; then
    pass "role count >= ${min}: ${role} (got ${n})"
  else
    fail "role count <${min}: ${role} (got ${n})"
  fi
}

# Concatenate every state-role comment body into a single blob so the
# rendered `## Task Ledger` row can be matched against expected task ids
# regardless of which checkpoint posted it.
state_bodies_blob() {
  local out="${snap_dir}/state-bodies.md"
  jq -r '
    .comments[]
    | select(.body | test("plan-issue-record:v[0-9]+ role=state"))
    | .body
  ' "${snap_dir}/issue.json" >"${out}"
  printf '%s\n' "${out}"
}

check_state_body_contains_ledger_row() {
  local task_id="$1"
  local bodies
  bodies="$(state_bodies_blob)"
  # Match a pipe-table row whose first cell is exactly the task id, in
  # any state lifecycle body. Status column is intentionally not pinned
  # (rows transition pending → in-progress → done).
  if grep -E -q "^\| ${task_id} \|" "${bodies}"; then
    pass "state body has ledger row: ${task_id}"
  else
    fail "state body missing ledger row: ${task_id}"
  fi
}

check_state_body_not_synthesized_fallback() {
  # Finding #9 regression guard: the pre-fix renderer emitted a single
  # synthesized row of the form `| Task <id> | <status> | selected |`
  # when no execution_state_file was wired up. Real per-task ledger rows
  # start with the bare id (`| 1.1 |`), never `| Task 1.1 |`.
  local bodies
  bodies="$(state_bodies_blob)"
  if grep -E -q '^\| Task [0-9.]+ \| [a-z-]+ \| selected \|' "${bodies}"; then
    fail "state body regressed to synthesized fallback ledger row (finding #9)"
  else
    pass "state body has no synthesized fallback ledger row"
  fi
}

check_linked_pr_merged() {
  # Finding #16 (deliver scope): a deliver run must produce a *merged* PR
  # with a real merge SHA. The lifecycle markers alone do not prove the PR
  # actually landed. Resolve the PR by its head branch (retained on the PR
  # record even after the branch is auto-deleted on merge); newest first.
  local pr_json pr_number pr_state merge_sha
  pr_json=$(gh pr list \
    --repo "${TESTBED_REPO}" \
    --head "${FIXTURE_BRANCH}" \
    --state all \
    --json number,state,mergeCommit \
    --jq 'sort_by(.number) | reverse | .[0] // empty')
  if [ -z "${pr_json}" ]; then
    fail "no PR found for head branch ${FIXTURE_BRANCH}"
    return
  fi
  pr_number=$(echo "${pr_json}" | jq -r '.number')
  pr_state=$(echo "${pr_json}" | jq -r '.state')
  merge_sha=$(echo "${pr_json}" | jq -r '.mergeCommit.oid // empty')
  if [ "${pr_state}" = "MERGED" ]; then
    pass "linked PR #${pr_number} merged"
  else
    fail "linked PR #${pr_number} state ${pr_state} (expected MERGED)"
  fi
  if [ -n "${merge_sha}" ]; then
    pass "linked PR #${pr_number} has merge SHA (${merge_sha:0:7})"
  else
    fail "linked PR #${pr_number} missing merge SHA"
  fi
}

# ---- Per-phase checks -------------------------------------------------

case "${phase}" in
  create)
    # Issue must be OPEN.
    if [ "${issue_state}" = "OPEN" ]; then
      pass "issue state OPEN"
    else
      fail "issue state ${issue_state} (expected OPEN)"
    fi
    # All expected labels.
    IFS=',' read -ra labels_arr <<<"${FIXTURE_LABELS}"
    for l in "${labels_arr[@]}"; do
      check_label_present "${l}"
    done
    # Source / plan / state roles, each at least once.
    for r in ${FIXTURE_EXPECTED_ROLES_CREATE}; do
      check_role_present "${r}"
    done
    ;;
  execute)
    if [ "${issue_state}" = "OPEN" ]; then
      pass "issue state OPEN"
    else
      fail "issue state ${issue_state} (expected OPEN)"
    fi
    # State role should have grown to at least 2 (initial + per-task).
    check_role_min_count state 2
    # Original roles still present.
    for r in source plan; do
      check_role_present "${r}"
    done
    # Rendered state body must carry every expected per-task ledger row.
    for tid in ${FIXTURE_EXPECTED_LEDGER_TASK_IDS}; do
      check_state_body_contains_ledger_row "${tid}"
    done
    check_state_body_not_synthesized_fallback
    ;;
  deliver)
    if [ -z "${FIXTURE_EXPECTED_ROLES_DELIVER:-}" ]; then
      die "fixture ${FIXTURE_NAME} has no deliver phase (no FIXTURE_EXPECTED_ROLES_DELIVER)"
    fi
    if [ "${issue_state}" = "OPEN" ]; then
      pass "issue state OPEN"
    else
      fail "issue state ${issue_state} (expected OPEN — closeout has not run yet)"
    fi
    # Roles up to and including review.
    for r in source plan state review; do
      check_role_present "${r}"
    done
    # State role should have grown further (initial + per-task + final
    # state-complete after phase=ready_for_close), so require >= 2.
    check_role_min_count state 2
    # The final state body must still carry the per-task ledger.
    for tid in ${FIXTURE_EXPECTED_LEDGER_TASK_IDS}; do
      check_state_body_contains_ledger_row "${tid}"
    done
    check_state_body_not_synthesized_fallback
    # The delivery must have landed: linked PR merged with a merge SHA.
    check_linked_pr_merged
    ;;
  closeout)
    if [ "${issue_state}" = "CLOSED" ]; then
      pass "issue state CLOSED"
    else
      fail "issue state ${issue_state} (expected CLOSED)"
    fi
    check_role_present closeout
    check_label_present "${FIXTURE_EXPECTED_FINAL_STATE}"
    # Every role the fixture expects at closeout must be present, including
    # `review`: the lightweight happy-path records its completion review at
    # closeout (the plan-tracking-issue-closeout preflight posts it when
    # close-ready reports `review-missing`), and the deliver flow records the
    # PR review upstream — so both carry `review` by closeout.
    # shellcheck disable=SC2086  # intentional word-splitting of the role list.
    for r in ${FIXTURE_EXPECTED_ROLES_CLOSEOUT}; do
      check_role_present "${r}"
    done
    # Deliver fixtures additionally require the linked PR to remain merged.
    if [ -n "${FIXTURE_EXPECTED_ROLES_DELIVER:-}" ]; then
      check_linked_pr_merged
    fi
    # Final state body must also reflect the full per-task ledger.
    for tid in ${FIXTURE_EXPECTED_LEDGER_TASK_IDS}; do
      check_state_body_contains_ledger_row "${tid}"
    done
    check_state_body_not_synthesized_fallback
    ;;
  *)
    die "unknown phase: ${phase}"
    ;;
esac

printf '\n'
if [ "${fail_count}" -eq 0 ]; then
  printf 'SUMMARY: %s phase PASS\n' "${phase}"
  state_update "PHASE=${phase}"
  exit 0
else
  printf 'SUMMARY: %s phase FAIL (%d check(s) failed)\n' "${phase}" "${fail_count}"
  exit 1
fi
