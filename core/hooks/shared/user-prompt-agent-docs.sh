#!/usr/bin/env bash
#
# UserPromptSubmit hook: inject a short, language-agnostic agent-docs awareness
# cue for repos that declare a project-dev intent in AGENT_DOCS.toml.
#
# There is no English-keyword gating: the cue is driven by what the repo
# declares (resolved via `agent-docs preflight --intent`), so a non-English
# prompt in a policy repo still gets the cue. It fires at most once per session
# per repo (falling back to once per day) so it is a start-of-task nudge, not a
# per-prompt reminder.
#
set -uo pipefail

if [[ "${AGENT_RUNTIME_SUPPRESS_PREFLIGHT:-0}" == "1" ||
  "${AGENT_KIT_SUPPRESS_PREFLIGHT:-0}" == "1" ||
  "${CLAUDE_KIT_SUPPRESS_PREFLIGHT:-0}" == "1" ]]; then
  exit 0
fi

command -v git >/dev/null 2>&1 || exit 0
command -v agent-docs >/dev/null 2>&1 || exit 0
python_bin="$(command -v python3 || true)"
[[ -z "$python_bin" ]] && exit 0

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -z "$repo_root" ]] && exit 0
[[ -f "$repo_root/AGENT_DOCS.toml" ]] || exit 0

payload="$(cat)"

# Dedupe: at most one cue per session per repo (fall back to per-day when no
# session id is present), so the cue stays a start-of-task nudge.
session_id="$(
  "$python_bin" -c '
import json, sys
try:
    p = json.load(sys.stdin)
except Exception:
    p = {}
for k in ("session_id", "sessionId", "session", "conversation_id"):
    v = p.get(k) if isinstance(p, dict) else None
    if isinstance(v, str) and v:
        print(v)
        break
' <<<"$payload" 2>/dev/null || true
)"
product="${AGENT_RUNTIME_PRODUCT:-agent-runtime}"
repo_hash="$(printf '%s' "$repo_root" | cksum 2>/dev/null | awk '{print $1}' || true)"
key="${session_id:-$(date +%Y%m%d)}"
stamp_dir="$HOME/.cache/agent-runtime-kit"
stamp="$stamp_dir/preflight-cue-${product}-${repo_hash}-${key}.stamp"
[[ -f "$stamp" ]] && exit 0

docs_home="${AGENT_RUNTIME_DOCS_HOME:-${AGENT_DOCS_HOME:-}}"
dh_args=()
[[ -n "$docs_home" ]] && dh_args=(--docs-home "$docs_home")

preflight_json="$(
  agent-docs "${dh_args[@]}" --project-path "$repo_root" \
    preflight --intent project-dev --format json 2>/dev/null || true
)"
[[ -z "$preflight_json" ]] && exit 0

cue="$(
  CTX_JSON="$preflight_json" "$python_bin" -c '
import json, os
try:
    d = json.loads(os.environ["CTX_JSON"])
except Exception:
    raise SystemExit(0)
docs = [x for x in d.get("documents", []) if x.get("required")]
val = d.get("validation") or {}
cmds = val.get("commands") or []
if not docs and not cmds:
    raise SystemExit(0)
lines = []
if docs:
    names = ", ".join(os.path.basename(x.get("path", "")) for x in docs[:6])
    lines.append(
        f"Required project-dev docs ({len(docs)}): {names}. Read them before writing."
    )
if cmds:
    lines.append(
        "Before declaring this task done, run the declared validation: "
        + " && ".join(cmds)
        + " (the finish-line gate enforces this; state a waiver to override)."
    )
print("\n".join(lines))
' 2>/dev/null || true
)"
[[ -z "$cue" ]] && exit 0

reminder="[agent-runtime-kit:${product}] This repo declares an agent-docs project-dev contract.
${cue}"

CTX="$reminder" "$python_bin" -c '
import json
import os

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": os.environ["CTX"],
    }
}))
'

mkdir -p "$stamp_dir"
: >"$stamp"
