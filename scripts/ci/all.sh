#!/usr/bin/env bash
# scripts/ci/all.sh — agent-runtime-kit CI gate stack.
#
# Linear, ordered gate stack — do not parallelize. Each position prints a
# banner, runs its check, and exits non-zero on the first failure.
#
# Compatibility: must run on macOS (system bash 3.2) and Linux runners.
# Avoid associative arrays, mapfile, and `${var,,}` lowercasing.
#
# Required on PATH (installed via `brew install sympoies/tap/nils-cli`):
#   - agent-runtime  (subcommands: render, audit-drift)
#   - plan-tooling   (subcommand: validate)
#   - python3        (for offline runtime-smoke loopback/sample probes)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

banner() {
  local position="$1"
  local title="$2"
  printf '\n==[ ci/all.sh position %s ]== %s\n' "$position" "$title"
}

require_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "ci/all.sh: required binary not on PATH: $bin" >&2
    exit 127
  fi
}

require_bin plan-tooling
require_bin agent-runtime
require_bin python3

# -----------------------------------------------------------------------------
# Position 1 — plan bundle validation
# -----------------------------------------------------------------------------
banner 1 "plan-tooling validate --format text --explain"
plan-tooling validate --format text --explain

# -----------------------------------------------------------------------------
# Position 2 — render codex
# -----------------------------------------------------------------------------
banner 2 "agent-runtime render --product codex"
agent-runtime render --product codex

# -----------------------------------------------------------------------------
# Position 3 — render claude
# -----------------------------------------------------------------------------
banner 3 "agent-runtime render --product claude"
agent-runtime render --product claude

# -----------------------------------------------------------------------------
# Position 4 — golden diff (rendered build vs committed golden tree)
# -----------------------------------------------------------------------------
banner 4 "git diff --exit-code tests/golden/ (after --update-golden refresh)"
agent-runtime render --product codex --update-golden >/dev/null
agent-runtime render --product claude --update-golden >/dev/null
git diff --exit-code -- tests/golden/

# -----------------------------------------------------------------------------
# Position 5 — audit-drift (root sweep + four hermetic fixtures)
# -----------------------------------------------------------------------------
banner 5 "agent-runtime audit-drift (root + tests/drift fixtures)"
agent-runtime audit-drift

drift_fixtures=(
  agent-home-leak
  docs-home-mismatch
  rendered-target-diff
  source-manifest-missing
)

for fixture in "${drift_fixtures[@]}"; do
  fixture_root="tests/drift/${fixture}"
  expected_txt="${fixture_root}/expected.txt"
  expected_exit_file="${fixture_root}/expected.exit"
  if [[ ! -f "$expected_txt" || ! -f "$expected_exit_file" ]]; then
    echo "ci/all.sh: drift fixture missing expected artifacts: $fixture_root" >&2
    exit 1
  fi
  expected_exit="$(cat "$expected_exit_file")"
  printf 'drift fixture: %s (expected exit=%s)\n' "$fixture" "$expected_exit"
  set +e
  actual_output="$(agent-runtime audit-drift --source-root "${fixture_root}/" 2>&1)"
  actual_exit=$?
  set -e
  if [[ "$actual_exit" != "$expected_exit" ]]; then
    echo "ci/all.sh: drift fixture $fixture exit mismatch: got=$actual_exit expected=$expected_exit" >&2
    echo "$actual_output" >&2
    exit 1
  fi
  if ! diff -u "$expected_txt" <(printf '%s\n' "$actual_output") >/tmp/ci-all-drift.diff 2>&1; then
    echo "ci/all.sh: drift fixture $fixture output mismatch:" >&2
    cat /tmp/ci-all-drift.diff >&2
    exit 1
  fi
done

# -----------------------------------------------------------------------------
# Position 6 — sandbox install rehearsal
# -----------------------------------------------------------------------------
banner 6 "sandbox install rehearsal (dry-run skill-list diff)"
bash scripts/ci/sandbox-install-rehearsal.sh

# -----------------------------------------------------------------------------
# Position 7 — deterministic runtime skill smoke
# -----------------------------------------------------------------------------
banner 7 "runtime skill deterministic smoke"
bash tests/runtime-smoke/run.sh --mode deterministic

printf '\nci/all.sh: positions 1-7 OK\n'
