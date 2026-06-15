#!/usr/bin/env bash
#
# SessionStart hook: surface health problems once per day.
#
# Two independent, opt-in-aware checks share one daily nudge:
#   1. agent-docs repo health (when `agent-docs` is installed): install-symlink
#      wiring, declared-doc presence and validity, and catalog validity.
#   2. evidence-archive wiring (only when the user has opted in via
#      $AGENT_EVIDENCE_ARCHIVE_HOME, a machine-local config, or a default clone):
#      clone presence, local config validity, and hosts.yaml validity.
#
# The hook is product-neutral. Product activation sets AGENT_RUNTIME_PRODUCT so
# cache keys and labels stay readable. A user who has not opted into the
# evidence-archive is never nagged about it.

set -uo pipefail

if [[ "${AGENT_RUNTIME_SUPPRESS_HEALTH:-0}" == "1" ||
  "${AGENT_KIT_SUPPRESS_HEALTH:-0}" == "1" ||
  "${CLAUDE_KIT_SUPPRESS_HEALTH:-0}" == "1" ]]; then
  exit 0
fi

python_bin="$(command -v python3 || true)"
[[ -z "$python_bin" ]] && exit 0

product="${AGENT_RUNTIME_PRODUCT:-agent-runtime}"
stamp_dir="$HOME/.cache/agent-runtime-kit"
stamp="$stamp_dir/health-${product}-$(date +%Y%m%d).stamp"
[[ -f "$stamp" ]] && exit 0

# --- opt-in detection for the evidence-archive lane -------------------------

evidence_config_path() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/agent-evidence-archive/config.yaml"
}

evidence_opted_in() {
  [[ -n "${AGENT_EVIDENCE_ARCHIVE_HOME:-}" ]] && return 0
  [[ -f "$(evidence_config_path)" ]] && return 0
  [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive/.git" ]] && return 0
  return 1
}

resolve_archive_path() {
  # Mirrors the documented precedence: env > local config > XDG default.
  if [[ -n "${AGENT_EVIDENCE_ARCHIVE_HOME:-}" ]]; then
    printf '%s\n' "$AGENT_EVIDENCE_ARCHIVE_HOME"
    return
  fi
  local cfg p
  cfg="$(evidence_config_path)"
  if [[ -f "$cfg" ]]; then
    p="$(sed -n 's/^archive_clone_path:[[:space:]]*//p' "$cfg" | head -1)"
    if [[ -n "$p" ]]; then
      printf '%s\n' "$p"
      return
    fi
  fi
  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive"
}

evidence_problems() {
  # Caller guarantees the user has opted in. Emits one problem per line.
  if ! command -v evidence >/dev/null 2>&1; then
    printf '%s\n' "- evidence-archive is opted in but the \`evidence\` CLI is not on PATH (install the nils-cli evidence surface)."
    return
  fi
  local out="" cfg archive hosts
  cfg="$(evidence_config_path)"
  if [[ -f "$cfg" ]] && ! evidence validate-local --input "$cfg" >/dev/null 2>&1; then
    out="${out}- local config is invalid: ${cfg}
"
  fi
  archive="$(resolve_archive_path)"
  if [[ ! -d "$archive/.git" ]]; then
    out="${out}- archive clone not found at: ${archive}
"
  else
    hosts="$archive/config/hosts.yaml"
    if [[ ! -f "$hosts" ]]; then
      out="${out}- hosts.yaml missing at: ${hosts}
"
    elif ! evidence validate-hosts --input "$hosts" >/dev/null 2>&1; then
      out="${out}- hosts.yaml is invalid: ${hosts}
"
    fi
  fi
  printf '%s' "$out"
}

# --- decide whether either lane can run today -------------------------------

have_agent_docs=0
command -v agent-docs >/dev/null 2>&1 && have_agent_docs=1
opted_in=0
evidence_opted_in && opted_in=1

# Nothing to check today: do not stamp, so a later session can re-check.
if [[ "$have_agent_docs" -eq 0 && "$opted_in" -eq 0 ]]; then
  exit 0
fi

mkdir -p "$stamp_dir"
: >"$stamp"

# --- lane 1: agent-docs repo health -----------------------------------------

docs_block=""
if [[ "$have_agent_docs" -eq 1 ]]; then
  # docs-home is derived from the install symlink by agent-docs; only pass an
  # explicit override when the environment provides one.
  docs_home="${AGENT_RUNTIME_DOCS_HOME:-${AGENT_DOCS_HOME:-}}"
  dh_args=()
  [[ -n "$docs_home" ]] && dh_args=(--docs-home "$docs_home")
  audit_output="$(
    agent-docs ${dh_args[@]+"${dh_args[@]}"} audit --target all --strict --format text 2>&1 || true
  )"
  # `problems: N` counts wiring, declared-doc, and catalog issues; only nudge
  # when there is at least one.
  if [[ -n "$audit_output" ]] && printf '%s\n' "$audit_output" | grep -Eq '^problems: [1-9][0-9]*'; then
    docs_block="agent-docs audit found repo-health problems in the current workspace:

${audit_output}"
  fi
fi

# --- lane 2: evidence-archive wiring (opt-in) -------------------------------

evid_block=""
if [[ "$opted_in" -eq 1 ]]; then
  evid_problems="$(evidence_problems)"
  if [[ -n "$evid_problems" ]]; then
    evid_block="evidence-archive wiring problems (you have opted in via \$AGENT_EVIDENCE_ARCHIVE_HOME, a local config, or a local clone):

${evid_problems}"
  fi
fi

# --- combine + emit ---------------------------------------------------------

if [[ -z "$docs_block" && -z "$evid_block" ]]; then
  exit 0
fi

context="[agent-runtime-kit:${product} health]"
[[ -n "$docs_block" ]] && context="${context}

${docs_block}"
[[ -n "$evid_block" ]] && context="${context}

${evid_block}"

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
