#!/usr/bin/env bash
#
# SessionStart hook: surface agent-docs baseline issues once per day.
#
# The hook is product-neutral. Product activation sets AGENT_RUNTIME_PRODUCT so
# cache keys and labels stay readable, while the check itself uses the shared
# agent-docs baseline contract.

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
docs_home="${AGENT_RUNTIME_DOCS_HOME:-$HOME/.config/agent-kit}"
stamp_dir="$HOME/.cache/agent-runtime-kit"
stamp="$stamp_dir/health-${product}-$(date +%Y%m%d).stamp"
[[ -f "$stamp" ]] && exit 0

baseline_output="$(
  agent-docs --docs-home "$docs_home" baseline --check --target all --strict --format text 2>&1 || true
)"
[[ -z "$baseline_output" ]] && exit 0

mkdir -p "$stamp_dir"
: >"$stamp"

if ! printf '%s\n' "$baseline_output" | grep -Eq '^missing_required: [1-9][0-9]*'; then
  exit 0
fi

context="[agent-runtime-kit:${product} health]
Required baseline docs are missing in the current workspace:

${baseline_output}"

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
