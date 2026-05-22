#!/usr/bin/env bash
# Product-in-the-loop isolation probes for Plan 06.
# shellcheck disable=SC2329

set -euo pipefail

: "${REPO_ROOT:?}"
: "${SCRIPT_DIR:?}"
: "${TMP_ROOT:?}"
: "${ARTIFACTS_DIR:?}"
: "${RESULTS_FILE:?}"
: "${PROBE_ONLY:?}"

# shellcheck disable=SC1091
# shellcheck source=tests/runtime-smoke/lib/results.sh
. "$SCRIPT_DIR/lib/results.sh"

PRODUCT_ARTIFACTS_DIR="$ARTIFACTS_DIR/product"
PRODUCT_WORKSPACE="$TMP_ROOT/workspaces/product-basic-repo"
mkdir -p "$PRODUCT_ARTIFACTS_DIR" "$TMP_ROOT/workspaces"
cp -R "$SCRIPT_DIR/workspaces/basic-repo/." "$PRODUCT_WORKSPACE"

require_product_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "runtime-smoke product: required binary not on PATH: $bin" >&2
    return 1
  fi
}

record_product_case() {
  local id="$1"
  local product="$2"
  local note="$3"
  shift 3

  if "$@"; then
    results_add "$id" "$product" "pass" "1" "$note"
    return 0
  fi

  results_add "$id" "$product" "blocked-design" "0" "$note"
  return 1
}

run_codex_probe() {
  local root="$PRODUCT_ARTIFACTS_DIR/codex"
  local home="$root/home"
  local codex_home="$root/codex-home"
  local xdg="$root/xdg"
  local version_out="$root/codex.version.txt"
  local help_out="$root/codex.help.txt"
  local exec_help_out="$root/codex.exec-help.txt"
  local prompt_out="$root/codex.prompt.stdout.jsonl"
  local prompt_err="$root/codex.prompt.stderr.txt"
  local prompt_exit="$root/codex.prompt.exit"
  local files_out="$root/files.txt"
  local exit_code

  require_product_bin codex || return 1
  mkdir -p "$home" "$codex_home" "$xdg"

  HOME="$home" CODEX_HOME="$codex_home" XDG_CONFIG_HOME="$xdg" \
    codex --version >"$version_out" 2>&1
  HOME="$home" CODEX_HOME="$codex_home" XDG_CONFIG_HOME="$xdg" \
    codex --help >"$help_out" 2>&1
  HOME="$home" CODEX_HOME="$codex_home" XDG_CONFIG_HOME="$xdg" \
    codex exec --help >"$exec_help_out" 2>&1

  grep -q 'Run Codex non-interactively' "$exec_help_out"
  grep -q -- '--ephemeral' "$exec_help_out"
  grep -q -- '--ignore-user-config' "$exec_help_out"

  set +e
  HOME="$home" CODEX_HOME="$codex_home" XDG_CONFIG_HOME="$xdg" \
    codex --ask-for-approval never exec \
    --ignore-user-config \
    --ephemeral \
    --skip-git-repo-check \
    --sandbox read-only \
    --oss \
    --local-provider ollama \
    --model llama3.2 \
    -C "$PRODUCT_WORKSPACE" \
    --json \
    "Reply with ok." >"$prompt_out" 2>"$prompt_err"
  exit_code="$?"
  set -e

  printf '%s\n' "$exit_code" >"$prompt_exit"
  find "$root" -maxdepth 5 \( -type f -o -type d \) | sort >"$files_out"

  if [ "$exit_code" -eq 0 ]; then
    return 0
  fi

  grep -Eq 'No running Ollama server detected|OSS setup failed|Failed to connect to Ollama' "$prompt_err"
}

run_claude_probe() {
  local root="$PRODUCT_ARTIFACTS_DIR/claude"
  local home="$root/home"
  local claude_config_dir="$root/claude-config"
  local xdg="$root/xdg"
  local version_out="$root/claude.version.txt"
  local help_out="$root/claude.help.txt"
  local prompt_out="$root/claude.prompt.stdout.json"
  local prompt_err="$root/claude.prompt.stderr.txt"
  local prompt_exit="$root/claude.prompt.exit"
  local files_out="$root/files.txt"
  local exit_code

  require_product_bin claude || return 1
  mkdir -p "$home" "$claude_config_dir" "$xdg"

  HOME="$home" CLAUDE_CONFIG_DIR="$claude_config_dir" XDG_CONFIG_HOME="$xdg" \
    claude --version >"$version_out" 2>&1
  HOME="$home" CLAUDE_CONFIG_DIR="$claude_config_dir" XDG_CONFIG_HOME="$xdg" \
    claude --help >"$help_out" 2>&1

  grep -q -- '--bare' "$help_out"
  grep -q -- '--no-session-persistence' "$help_out"
  grep -q -- '--print' "$help_out"

  set +e
  env -u ANTHROPIC_API_KEY \
    HOME="$home" \
    CLAUDE_CONFIG_DIR="$claude_config_dir" \
    XDG_CONFIG_HOME="$xdg" \
    claude -p \
    --bare \
    --no-session-persistence \
    --setting-sources project \
    --settings '{}' \
    --tools '' \
    --model sonnet \
    --output-format json \
    --max-budget-usd 0.01 \
    "Reply with ok." >"$prompt_out" 2>"$prompt_err"
  exit_code="$?"
  set -e

  printf '%s\n' "$exit_code" >"$prompt_exit"
  find "$root" -maxdepth 5 \( -type f -o -type d \) | sort >"$files_out"

  if [ "$exit_code" -eq 0 ]; then
    return 0
  fi

  grep -q 'Not logged in' "$prompt_out"
}

if [ "$PROBE_ONLY" -ne 1 ]; then
  echo "runtime-smoke product: product mode currently requires --probe-only" >&2
  results_add "product.contract" "${PRODUCT:-all}" "blocked-design" "0" "representative product prompt cases are added in Task 3.2"
  exit 1
fi

if [ -n "${PRODUCT:-}" ]; then
  products="$PRODUCT"
else
  products="codex claude"
fi

failures=0
for product in $products; do
  case "$product" in
    codex)
      record_product_case \
        "product.codex.probe" \
        "codex" \
        "isolation=supported via CODEX_HOME and ephemeral exec; prompt smoke is manual-only without provider/auth" \
        run_codex_probe || failures=1
      ;;
    claude)
      record_product_case \
        "product.claude.probe" \
        "claude" \
        "isolation=supported via CLAUDE_CONFIG_DIR and bare print; prompt smoke is manual-only without API key" \
        run_claude_probe || failures=1
      ;;
    *)
      echo "runtime-smoke product: unsupported product: $product" >&2
      results_add "product.$product.probe" "$product" "fail" "0" "unsupported product"
      failures=1
      ;;
  esac
done

exit "$failures"
