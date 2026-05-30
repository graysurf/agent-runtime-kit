#!/usr/bin/env bash
#
# SessionStart hook: surface agent-docs repo-health problems once per day.
#
# The hook is product-neutral. Product activation sets AGENT_RUNTIME_PRODUCT so
# cache keys and labels stay readable, while the check itself uses the shared
# `agent-docs audit` contract: install-symlink wiring, declared-doc presence
# and validity, and catalog validity.

set -uo pipefail

if [[ "${AGENT_RUNTIME_SUPPRESS_HEALTH:-0}" == "1" ||
  "${AGENT_KIT_SUPPRESS_HEALTH:-0}" == "1" ||
  "${CLAUDE_KIT_SUPPRESS_HEALTH:-0}" == "1" ]]; then
  exit 0
fi

command -v agent-docs >/dev/null 2>&1 || exit 0
python_bin="$(command -v python3 || true)"
[[ -z "$python_bin" ]] && exit 0

product="${AGENT_RUNTIME_PRODUCT:-agent-runtime}"
stamp_dir="$HOME/.cache/agent-runtime-kit"
stamp="$stamp_dir/health-${product}-$(date +%Y%m%d).stamp"
[[ -f "$stamp" ]] && exit 0

# docs-home is derived from the install symlink by agent-docs; only pass an
# explicit override when the environment provides one.
docs_home="${AGENT_RUNTIME_DOCS_HOME:-${AGENT_DOCS_HOME:-}}"
dh_args=()
[[ -n "$docs_home" ]] && dh_args=(--docs-home "$docs_home")

audit_output="$(
  agent-docs "${dh_args[@]}" audit --target all --strict --format text 2>&1 || true
)"
[[ -z "$audit_output" ]] && exit 0

mkdir -p "$stamp_dir"
: >"$stamp"

# `problems: N` counts wiring, declared-doc, and catalog issues; only nudge when
# there is at least one.
if ! printf '%s\n' "$audit_output" | grep -Eq '^problems: [1-9][0-9]*'; then
  exit 0
fi

context="[agent-runtime-kit:${product} health]
agent-docs audit found repo-health problems in the current workspace:

${audit_output}"

CTX="$context" "$python_bin" -c '
import json
import os

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": os.environ["CTX"],
    }
}))
'
