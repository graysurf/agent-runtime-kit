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
#   - agent-runtime  (subcommands: render, audit-drift, doctor)
#   - plan-tooling   (subcommand: validate)
#   - python3        (for offline runtime-smoke loopback/sample probes,
#                    and for parsing the skill-surface doctor JSON output)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Git hooks export repo-local GIT_* variables. They are correct for the hook
# process, but they leak into temp git repositories used by runtime smoke tests.
if git_local_env="$(git rev-parse --local-env-vars 2>/dev/null)"; then
  while IFS= read -r env_name; do
    [[ -n "$env_name" ]] && unset "$env_name"
  done <<<"$git_local_env"
fi

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
# Position 1 — plan bundle and skill lifecycle governance validation
# -----------------------------------------------------------------------------
banner 1 "plan-tooling validate + skill-governance audit"
plan-tooling validate --format text --explain
bash scripts/ci/skill-governance-audit.sh
bash scripts/ci/skill-governance-audit.sh --fixture count-refresh
bash scripts/ci/skill-governance-audit.sh --fixture create
bash scripts/ci/skill-governance-audit.sh --fixture remove

# -----------------------------------------------------------------------------
# Position 2 — nils-cli surface floor alignment
#
# Compares the host's `agent-runtime --version` against the floor recorded in
# `docs/source/nils-cli-surface.md`. The floor line is matched by the literal
# prefix '- Active `git describe --tags` output:' so a future reorder of
# the snapshot header makes a parse miss visible in the gate banner. Closes
# the silent-drift class identified by the heuristic-inbox case
# `plan-issue-v2-marker-collapse-drift`: a host binary below the documented
# floor leaves downstream gates running against a binary the fixtures and skill
# bodies were not written for. Newer host binaries are allowed; later gates own
# compatibility checks for rendered output and runtime smoke.
#
# Probe binary: `agent-runtime --version`. Assumes the nils-cli workspace
# bumps every crate in lock-step (the `chore(release): bump cli versions
# to <vX.Y.Z>` convention from `1edf007`). v0.25.7 was a temporary exception
# that only bumped `plan-tooling` + `plan-issue-cli`; v0.25.8 restored the
# lock-step contract, so this probe is back on `agent-runtime`. If a future
# release breaks the lock-step contract again, fix the release rather than
# flipping the probe — the contract is the cheaper invariant to preserve.
# -----------------------------------------------------------------------------
banner 2 "nils-cli surface floor vs agent-runtime --version"
SURFACE_DOC="docs/source/nils-cli-surface.md"
# shellcheck disable=SC2016
# Single quotes intentional: the grep / sed patterns embed literal
# backticks from the snapshot doc and must not be expanded by the shell.
PIN_LINE="$(grep -E '^- Active `git describe --tags` output:' "$SURFACE_DOC" | head -n 1)"
if [ -z "$PIN_LINE" ]; then
  echo "ci/all.sh: nils-cli surface floor line not found in $SURFACE_DOC" >&2
  echo "  expected line prefix: - Active \`git describe --tags\` output:" >&2
  exit 1
fi
# shellcheck disable=SC2016
SURFACE_FLOOR="$(printf '%s\n' "$PIN_LINE" | sed -E 's/^- Active `git describe --tags` output: `([^`]+)`.*$/\1/')"
HOST_VERSION_RAW="$(agent-runtime --version 2>/dev/null | awk 'NR==1 {print $NF}')"
if [ -z "$HOST_VERSION_RAW" ]; then
  echo "ci/all.sh: agent-runtime --version produced no output" >&2
  exit 1
fi
case "$HOST_VERSION_RAW" in
  v*) HOST_TAG="$HOST_VERSION_RAW" ;;
  *) HOST_TAG="v$HOST_VERSION_RAW" ;;
esac

set +e
VERSION_CHECK="$(
  python3 - "$SURFACE_FLOOR" "$HOST_TAG" 2>&1 <<'PY'
from __future__ import annotations

import re
import sys


def parse_version(value: str, label: str):
    raw = value.strip()
    match = re.match(r"^v?([0-9]+)\.([0-9]+)\.([0-9]+)(?:[-+].*)?$", raw)
    if not match:
        print(f"invalid {label} version: {value}", file=sys.stderr)
        raise SystemExit(2)
    return tuple(int(part) for part in match.groups())


floor_raw, host_raw = sys.argv[1], sys.argv[2]
floor = parse_version(floor_raw, "surface floor")
host = parse_version(host_raw, "host")
if host < floor:
    print(
        f"host {host_raw} is below surface floor {floor_raw}",
        file=sys.stderr,
    )
    raise SystemExit(1)
print("ok")
PY
)"
VERSION_CHECK_EXIT=$?
set -e

if [ "$VERSION_CHECK_EXIT" -ne 0 ]; then
  echo "ci/all.sh: nils-cli surface floor check failed" >&2
  echo "  minimum in $SURFACE_DOC : $SURFACE_FLOOR" >&2
  echo "  host agent-runtime    : $HOST_TAG" >&2
  echo "  parsed line           : $PIN_LINE" >&2
  if [ -n "$VERSION_CHECK" ]; then
    printf '  detail: %s\n' "$VERSION_CHECK" >&2
  fi
  echo >&2
  echo "  Remediation:" >&2
  echo "  - If the snapshot doc is stale, refresh the floor (and any related" >&2
  echo "    consumers under core/skills/, tests/runtime-smoke/, tests/golden/)" >&2
  echo "    to the minimum supported surface, then re-run scripts/ci/all.sh." >&2
  echo "  - If the host is below the floor, run: brew upgrade sympoies/tap/nils-cli" >&2
  exit 1
fi
printf 'nils-cli surface floor: %s   host: %s   aligned (host >= floor)\n' "$SURFACE_FLOOR" "$HOST_TAG"

# -----------------------------------------------------------------------------
# Position 3 — render codex
# -----------------------------------------------------------------------------
banner 3 "agent-runtime render --product codex"
agent-runtime render --product codex

# -----------------------------------------------------------------------------
# Position 4 — render claude
# -----------------------------------------------------------------------------
banner 4 "agent-runtime render --product claude"
agent-runtime render --product claude

# -----------------------------------------------------------------------------
# Position 5 — render shared support matrix
# -----------------------------------------------------------------------------
banner 5 "agent-runtime render --target support-matrix"
agent-runtime render --target support-matrix

# -----------------------------------------------------------------------------
# Position 6 — golden diff (rendered build vs committed golden tree)
# -----------------------------------------------------------------------------
banner 6 "git diff --exit-code tests/golden/ (after --update-golden refresh)"
agent-runtime render --product codex --update-golden >/dev/null
agent-runtime render --product claude --update-golden >/dev/null
agent-runtime render --target support-matrix --update-golden >/dev/null
git diff --exit-code -- tests/golden/

# -----------------------------------------------------------------------------
# Position 7 — audit-drift (root sweep + four hermetic fixtures)
# -----------------------------------------------------------------------------
banner 7 "agent-runtime audit-drift (root + tests/drift fixtures)"
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
# Position 8 — surface registry schema + executable acceptance
# -----------------------------------------------------------------------------
banner 8 "validate surfaces manifest + executable acceptance"
if bash scripts/ci/validate-surfaces-manifest.sh tests/surfaces/invalid-acceptance.yaml; then
  echo "ci/all.sh: invalid surface acceptance fixture unexpectedly passed" >&2
  exit 1
fi
ACCEPTANCE_OUT_DIR="${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/ci-all/surface-acceptance"
ACCEPTANCE_CODEX_HOME="${ACCEPTANCE_OUT_DIR}/codex-home"
rm -rf "$ACCEPTANCE_CODEX_HOME"
mkdir -p "$ACCEPTANCE_CODEX_HOME"
ln -s "$REPO_ROOT/AGENT_HOME.md" "$ACCEPTANCE_CODEX_HOME/AGENTS.md"
CODEX_HOME="$ACCEPTANCE_CODEX_HOME" bash scripts/ci/validate-surfaces-manifest.sh --execute-acceptance

# -----------------------------------------------------------------------------
# Position 9 — Codex skill-surface shape diagnostic (preflight, not live)
#
# Shape validation only. Live Codex Desktop discovery still requires
# `codex debug prompt-input` in a fresh session — see
# docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/ for the live acceptance
# protocol. The expected check count is documented in that plan's execution
# state; bump SHAPE_EXPECTED_MIN_CHECKS together with a recorded reason.
# -----------------------------------------------------------------------------
SHAPE_EXPECTED_MIN_CHECKS=72
SHAPE_OUT_DIR="${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/ci-all"
mkdir -p "$SHAPE_OUT_DIR"
SHAPE_JSON="$SHAPE_OUT_DIR/shape-diagnostic.json"
SHAPE_SUMMARY="$SHAPE_OUT_DIR/shape-diagnostic.summary"

banner 9 "agent-runtime doctor --class skill-surface --product codex"
agent-runtime doctor \
  --class skill-surface \
  --product codex \
  --format json \
  --source-root "$REPO_ROOT" \
  >"$SHAPE_JSON"

SHAPE_VERDICT="$(
  SHAPE_JSON_PATH="$SHAPE_JSON" \
    SHAPE_EXPECTED_MIN_CHECKS="$SHAPE_EXPECTED_MIN_CHECKS" \
    python3 - <<'PY'
import json
import os
import sys

path = os.environ["SHAPE_JSON_PATH"]
expected_min = int(os.environ["SHAPE_EXPECTED_MIN_CHECKS"])
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

exit_code = data.get("exit_code")
checks = data.get("checks")
ok = data.get("ok")
warn = data.get("warn")
block = data.get("block")
findings = data.get("findings") or []
boundary = data.get("acceptance_boundary", "")

errors = []
if exit_code != 0:
    errors.append("doctor exit_code=%r (expected 0)" % exit_code)
if not isinstance(checks, int) or checks < expected_min:
    errors.append(
        "checks=%r below documented baseline %d "
        "(bump SHAPE_EXPECTED_MIN_CHECKS in scripts/ci/all.sh "
        "and record the reason in "
        "docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/"
        "codex-skill-surface-acceptance-cutover-execution-state.md)"
        % (checks, expected_min)
    )
if ok != checks:
    errors.append("ok=%r != checks=%r" % (ok, checks))
if warn != 0:
    errors.append("warn=%r (expected 0)" % warn)
if block != 0:
    errors.append("block=%r (expected 0)" % block)
if findings:
    errors.append("findings present: %d entries" % len(findings))

print("checks=%s ok=%s warn=%s block=%s exit_code=%s findings=%d"
      % (checks, ok, warn, block, exit_code, len(findings)))
print("acceptance-boundary: %s" % boundary)
if errors:
    print()
    print("skill-surface shape gate FAILED:")
    for err in errors:
        print("  - " + err)
    sys.exit(1)
PY
)" || {
  printf '%s\n' "$SHAPE_VERDICT" >&2
  printf '%s\n' "$SHAPE_VERDICT" >"$SHAPE_SUMMARY"
  echo "ci/all.sh: skill-surface shape gate failed (artifact: $SHAPE_JSON)" >&2
  exit 1
}
printf '%s\n' "$SHAPE_VERDICT"
printf '%s\n' "$SHAPE_VERDICT" >"$SHAPE_SUMMARY"

# -----------------------------------------------------------------------------
# Position 10 — sandbox install rehearsal
# -----------------------------------------------------------------------------
banner 10 "sandbox install rehearsal (dry-run skill-list diff)"
bash scripts/ci/sandbox-install-rehearsal.sh

# -----------------------------------------------------------------------------
# Position 11 — deterministic runtime skill smoke
# -----------------------------------------------------------------------------
banner 11 "runtime skill deterministic smoke"
bash tests/runtime-smoke/run.sh --mode deterministic

# -----------------------------------------------------------------------------
# Position 12 — project-local overlay smoke
# -----------------------------------------------------------------------------
banner 12 "project-local overlay smoke"
bash tests/projects/project-local-smoke/run.sh

# -----------------------------------------------------------------------------
# Position 13 — shared hook contract smoke
# -----------------------------------------------------------------------------
banner 13 "shared hook contract smoke"
bash tests/hooks/run.sh

printf '\nci/all.sh: positions 1-13 OK\n'
