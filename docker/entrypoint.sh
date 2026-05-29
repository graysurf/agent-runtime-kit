#!/usr/bin/env bash
# entrypoint for the agent-runtime-kit container.
#
# Responsibilities (intentionally thin for the v1 PoC):
#   - print a short capability banner (suppress with AGENT_RUNTIME_KIT_QUIET=1)
#   - exec the requested command (default CMD: an interactive login shell)
#
# Auth is supplied at RUNTIME, never baked into the image:
#   Claude Code : pass ANTHROPIC_API_KEY, or run `claude login`, or mount a
#                 credentials file to ~/.claude/.credentials.json
#   Codex CLI   : pass OPENAI_API_KEY, or run `codex login`, or mount
#                 ~/.codex/auth.json
#   forge-cli/gh: pass GH_TOKEN (or GITHUB_TOKEN)
set -euo pipefail

banner() {
  cat <<EOF
agent-runtime-kit container (Codex + Claude)
  claude        : $(claude --version 2>/dev/null || echo 'n/a')
  codex         : $(codex --version 2>/dev/null || echo 'n/a')
  agent-runtime : $(agent-runtime --version 2>/dev/null || echo 'n/a')
  source        : ${AGENT_KIT_SRC:-unset}
  docs home     : ${AGENT_DOCS_HOME:-unset}
  auth          : claude=$([ -n "${ANTHROPIC_API_KEY:-}" ] && echo env || echo none), codex=$([ -n "${OPENAI_API_KEY:-}" ] && echo env || echo none)
EOF
}

if [ "${AGENT_RUNTIME_KIT_QUIET:-0}" != "1" ]; then
  banner >&2
fi

# No command given (shouldn't happen because CMD provides one) -> login shell.
if [ "$#" -eq 0 ]; then
  set -- bash -l
fi

exec "$@"
