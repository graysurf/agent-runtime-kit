#!/usr/bin/env bash
# entrypoint for the agent-runtime-kit container.
#
# Responsibilities (intentionally thin for the v1 PoC):
#   - print a short capability banner (suppress with AGENT_RUNTIME_KIT_QUIET=1)
#   - optionally apply an operator-supplied zsh repo with zsh-kit
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
  zsh-kit       : $(zsh-kit --version 2>/dev/null || echo 'n/a')
  source        : ${AGENT_KIT_SRC:-unset}
  docs home     : ${AGENT_DOCS_HOME:-unset}
  auth          : claude=$([ -n "${ANTHROPIC_API_KEY:-}" ] && echo env || echo none), codex=$([ -n "${OPENAI_API_KEY:-}" ] && echo env || echo none)
EOF
}

apply_zsh_setup() {
  [ -n "${ZSH_SETUP_REPO_URL:-}" ] || return 0

  local dest="${ZSH_SETUP_DEST:-$HOME/.config/zsh}"
  local features="${ZSH_SETUP_FEATURES:-docker}"
  local install_tools="${ZSH_SETUP_INSTALL_TOOLS:-skip}"
  local -a cmd=(
    zsh-kit setup
    --repo "$ZSH_SETUP_REPO_URL"
    --dest "$dest"
    --apply
    --install-tools "$install_tools"
    --write-zshenv
  )

  if [ -n "$features" ]; then
    cmd+=(--features "$features")
  fi
  if [ -n "${ZSH_SETUP_BRANCH:-}" ]; then
    cmd+=(--branch "$ZSH_SETUP_BRANCH")
  fi
  if [ -n "${ZSH_SETUP_REF:-}" ]; then
    cmd+=(--ref "$ZSH_SETUP_REF")
  fi
  if [ "${ZSH_SETUP_FORCE:-0}" = "1" ]; then
    cmd+=(--force)
  fi

  "${cmd[@]}"
}

if [ "${AGENT_RUNTIME_KIT_QUIET:-0}" != "1" ]; then
  banner >&2
fi

apply_zsh_setup

# No command given (shouldn't happen because CMD provides one) -> login shell.
if [ "$#" -eq 0 ]; then
  set -- zsh -il
fi

exec "$@"
