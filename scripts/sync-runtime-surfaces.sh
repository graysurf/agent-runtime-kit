#!/usr/bin/env bash
# scripts/sync-runtime-surfaces.sh - refresh managed surfaces into local runtimes.
#
# Compatibility: must run on macOS (system bash 3.2) and Linux (bash 4+).
# Avoid associative arrays, mapfile, and `${var,,}` lowercasing.

set -euo pipefail

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

readonly PROG_NAME="sync-runtime-surfaces.sh"

APPLY=0
PRODUCT="both"
NO_PULL=0
NO_VERIFY=0
NO_PRUNE=0
SOURCE_ROOT=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_PROMPT_STATUS="not-run"
CLAUDE_PLUGIN_STATUS="not-run"
CODEX_PLUGIN_STATUS="not-run"
# Activation gate for the Codex plugin marketplace. Default off: runtime-kit
# keeps the flat $CODEX_HOME/skills root (surface 15) as Codex's live skill
# discovery path, and registering the marketplace alongside it would list every
# skill twice (bare `<skill>` from the flat root AND `<plugin>:<skill>` from the
# plugin). Set CODEX_PLUGIN_ACTIVATION=1 (or pass --codex-plugin-activation) to
# register + install the marketplace; the planned commands stay dry-run-visible.
CODEX_PLUGIN_ACTIVATION="${CODEX_PLUGIN_ACTIVATION:-0}"
PRUNE_SKIPPED_TOTAL=0
PRUNE_LAST_SKIPPED=0

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

print_help() {
  cat <<EOF
Usage: $PROG_NAME [--apply] [--product codex|claude|both] [--source-root PATH] [--no-pull] [--no-prune] [--no-verify] [--codex-plugin-activation]

Refresh graysurf/agent-runtime-kit managed runtime surfaces into local Codex
and Claude runtime homes. This is the daily runtime surface refresh entrypoint
after source changes land. For first-time host setup, run scripts/setup.sh
first.

By default, this command is a dry-run: it prints the pull, render, install,
prune, doctor, and optional Codex prompt-input commands without mutating runtime
homes. Pass --apply to run the commands.

Options:
  --apply
      Execute the refresh. Without this flag, commands are printed only.
  --product codex|claude|both
      Limit the refresh to one product. Default: both.
  --source-root PATH
      Use a specific agent-runtime-kit checkout. Defaults to this script's
      repository root. For --apply, this must be a durable primary checkout;
      linked git worktrees and Codex transient worktrees are refused.
  --no-pull
      Skip git pull --ff-only and refresh the current checkout state.
  --no-prune
      Skip stale managed-surface pruning. With --apply, stale runtime surfaces
      may remain until a later refresh runs without this flag.
  --no-verify
      Skip post-install skill-surface doctor and Codex prompt-input probes.
  --codex-plugin-activation
      Register and install the Codex plugin marketplace
      (codex plugin marketplace add + codex plugin add <plugin>@codex-kit).
      Off by default: the flat \$CODEX_HOME/skills root stays Codex's live skill
      discovery path so skills are not listed twice. Equivalent to setting
      CODEX_PLUGIN_ACTIVATION=1. Combine with --apply to register live.
  -h, --help
      Print this help and exit.
EOF
}

# -----------------------------------------------------------------------------
# Logging helpers
# -----------------------------------------------------------------------------

log() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

print_cmd() {
  printf '+'
  while [ "$#" -gt 0 ]; do
    printf ' %q' "$1"
    shift
  done
  printf '\n'
}

run_cmd() {
  print_cmd "$@"
  if [ "$APPLY" = "0" ]; then
    return 0
  fi
  "$@"
}

require_commands() {
  local missing=""
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing="${missing}${cmd}
"
    fi
  done
  if [ -n "$missing" ]; then
    err "missing required command(s):"
    printf '%s' "$missing" | sed 's/^/  - /' >&2
    exit 127
  fi
}

# -----------------------------------------------------------------------------
# Arg parsing and path resolution
# -----------------------------------------------------------------------------

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --apply)
        APPLY=1
        shift
        ;;
      --dry-run)
        APPLY=0
        shift
        ;;
      --product)
        if [ "$#" -lt 2 ]; then
          err "--product requires a value"
          exit 2
        fi
        PRODUCT="$2"
        shift 2
        ;;
      --product=*)
        PRODUCT="${1#--product=}"
        shift
        ;;
      --source-root)
        if [ "$#" -lt 2 ]; then
          err "--source-root requires a value"
          exit 2
        fi
        SOURCE_ROOT="$2"
        shift 2
        ;;
      --source-root=*)
        SOURCE_ROOT="${1#--source-root=}"
        shift
        ;;
      --no-pull)
        NO_PULL=1
        shift
        ;;
      --no-prune)
        NO_PRUNE=1
        shift
        ;;
      --no-verify)
        NO_VERIFY=1
        shift
        ;;
      --codex-plugin-activation)
        CODEX_PLUGIN_ACTIVATION=1
        shift
        ;;
      -h | --help)
        print_help
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        err "unknown argument: $1"
        echo
        print_help
        exit 2
        ;;
    esac
  done

  case "$PRODUCT" in
    codex | claude | both) ;;
    *)
      err "invalid --product value: $PRODUCT (expected codex|claude|both)"
      exit 2
      ;;
  esac
}

resolve_source_root() {
  local root_candidate
  local top_level

  if [ -n "$SOURCE_ROOT" ]; then
    root_candidate="$SOURCE_ROOT"
  else
    root_candidate="$SCRIPT_DIR/.."
  fi

  if [ ! -d "$root_candidate" ]; then
    err "source root does not exist: $root_candidate"
    exit 2
  fi

  if ! top_level="$(git -C "$root_candidate" rev-parse --show-toplevel 2>/dev/null)"; then
    err "source root is not inside a git checkout: $root_candidate"
    exit 2
  fi

  SOURCE_ROOT="$(cd "$top_level" && pwd)"
}

absolute_git_dir() {
  local path="$1"
  local candidate

  case "$path" in
    /*) candidate="$path" ;;
    *) candidate="$SOURCE_ROOT/$path" ;;
  esac

  if [ ! -d "$candidate" ]; then
    err "git directory does not exist: $candidate"
    exit 2
  fi

  (cd "$candidate" && pwd -P)
}

source_root_is_linked_worktree() {
  local git_dir
  local common_dir
  local git_dir_abs
  local common_dir_abs

  git_dir="$(git -C "$SOURCE_ROOT" rev-parse --git-dir)"
  common_dir="$(git -C "$SOURCE_ROOT" rev-parse --git-common-dir)"
  git_dir_abs="$(absolute_git_dir "$git_dir")"
  common_dir_abs="$(absolute_git_dir "$common_dir")"

  [ "$git_dir_abs" != "$common_dir_abs" ]
}

source_root_is_codex_transient_worktree() {
  local source_physical
  local codex_home
  local codex_worktrees

  source_physical="$(cd "$SOURCE_ROOT" && pwd -P)"
  case "$source_physical" in
    */.codex/worktrees | */.codex/worktrees/*)
      return 0
      ;;
  esac

  codex_home="${CODEX_HOME:-$HOME/.codex}"
  if [ -d "$codex_home" ]; then
    codex_worktrees="$(cd "$codex_home" && pwd -P)/worktrees"
    case "$source_physical" in
      "$codex_worktrees" | "$codex_worktrees"/*)
        return 0
        ;;
    esac
  fi

  return 1
}

validate_live_sync_source_root() {
  if [ "$APPLY" = "0" ]; then
    return 0
  fi

  if source_root_is_linked_worktree; then
    err "refusing live sync from a git worktree: $SOURCE_ROOT"
    err "sync-runtime-surfaces --apply installs runtime-home symlinks; run it from a durable primary checkout or pass --source-root to one."
    exit 2
  fi

  if source_root_is_codex_transient_worktree; then
    err "refusing live sync from a Codex transient worktree: $SOURCE_ROOT"
    err "sync-runtime-surfaces --apply installs runtime-home symlinks; use a durable primary checkout outside runtime scratch worktrees."
    exit 2
  fi
}

selected_products() {
  case "$PRODUCT" in
    codex) printf '%s\n' codex ;;
    claude) printf '%s\n' claude ;;
    both)
      printf '%s\n' codex
      printf '%s\n' claude
      ;;
  esac
}

product_label() {
  case "$PRODUCT" in
    codex) printf '%s\n' codex ;;
    claude) printf '%s\n' claude ;;
    both) printf '%s\n' codex+claude ;;
  esac
}

selected_includes_codex() {
  case "$PRODUCT" in
    codex | both) return 0 ;;
    claude) return 1 ;;
  esac
}

product_live_home() {
  case "$1" in
    claude) printf '%s\n' "$HOME/.claude" ;;
    codex) printf '%s\n' "${CODEX_HOME:-$HOME/.codex}" ;;
    *)
      err "unknown product: $1"
      exit 2
      ;;
  esac
}

product_state_home() {
  local state_root="${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit"
  case "$1" in
    claude) printf '%s\n' "${CLAUDE_KIT_STATE_HOME:-$state_root/claude}" ;;
    codex) printf '%s\n' "${CODEX_AGENT_STATE_HOME:-$state_root/codex}" ;;
    *)
      err "unknown product: $1"
      exit 2
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Refresh steps
# -----------------------------------------------------------------------------

pull_source() {
  if [ "$NO_PULL" = "1" ]; then
    log "git pull skipped (--no-pull)"
    return 0
  fi
  run_cmd git -C "$SOURCE_ROOT" pull --ff-only
}

check_source_counts() {
  local audit_script="$SOURCE_ROOT/scripts/ci/skill-governance-audit.sh"

  if [ ! -f "$audit_script" ]; then
    err "source root is missing skill governance audit: $audit_script"
    exit 2
  fi

  log "checking source skill counts"
  print_cmd bash "$audit_script" --check-counts
  bash "$audit_script" --check-counts
}

render_product() {
  local product="$1"
  log "rendering product=$product"
  run_cmd agent-runtime render \
    --source-root "$SOURCE_ROOT" \
    --product "$product"
}

install_product() {
  local product="$1"
  local live_home
  local state_home
  local mode_flag="--dry-run"

  if [ "$APPLY" = "1" ]; then
    mode_flag="--apply"
  fi

  live_home="$(product_live_home "$product")"
  state_home="$(product_state_home "$product")"

  log "installing product=$product live_home=$live_home"
  run_cmd agent-runtime install \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    "$mode_flag"
}

sync_claude_settings_hooks() {
  local live_home="$1"
  local fragment="$SOURCE_ROOT/core/hooks/claude/settings.hooks.jsonc"
  local settings_path="$live_home/settings.json"

  if [ ! -f "$fragment" ]; then
    err "missing Claude settings hook fragment: $fragment"
    exit 2
  fi

  log "syncing Claude settings hooks live_home=$live_home"
  print_cmd python3 - "$fragment" "$settings_path" "$APPLY"
  python3 - "$fragment" "$settings_path" "$APPLY" <<'PY'
import copy
import json
import os
import stat
import sys

fragment_path, settings_path, apply_flag = sys.argv[1:4]


def strip_line_comments(text):
    lines = []
    for line in text.splitlines():
        if line.lstrip().startswith("//"):
            continue
        lines.append(line)
    return "\n".join(lines)


def load_fragment(path):
    with open(path, encoding="utf-8") as handle:
        wrapped = "{\n" + strip_line_comments(handle.read()) + "\n}\n"
    data = json.loads(wrapped)
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        raise SystemExit(f"Claude hook fragment must contain an object hooks block: {path}")
    return hooks


def load_settings(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit(f"Claude settings root must be a JSON object: {path}")
    return data


def is_managed_hook(hook):
    if not isinstance(hook, dict):
        return False
    command = hook.get("command")
    status = hook.get("statusMessage")
    if isinstance(status, str) and status.startswith("agent-runtime-kit:"):
        return True
    return (
        isinstance(command, str)
        and "AGENT_RUNTIME_PRODUCT=claude" in command
        and "$HOME/.claude/hooks/" in command
    )


def remove_managed_hooks(settings_hooks):
    for event in list(settings_hooks):
        groups = settings_hooks.get(event)
        if not isinstance(groups, list):
            continue
        kept_groups = []
        for group in groups:
            if not isinstance(group, dict) or not isinstance(group.get("hooks"), list):
                kept_groups.append(group)
                continue
            kept_hooks = [hook for hook in group["hooks"] if not is_managed_hook(hook)]
            if kept_hooks:
                next_group = copy.deepcopy(group)
                next_group["hooks"] = kept_hooks
                kept_groups.append(next_group)
        if kept_groups:
            settings_hooks[event] = kept_groups
        else:
            settings_hooks.pop(event, None)


def append_source_hooks(settings_hooks, source_hooks):
    managed_count = 0
    for event, source_groups in source_hooks.items():
        if not isinstance(source_groups, list):
            raise SystemExit(f"Claude hook fragment event must be a list: {event}")
        target_groups = settings_hooks.setdefault(event, [])
        if not isinstance(target_groups, list):
            raise SystemExit(f"Claude settings hooks.{event} must be a list")
        for source_group in source_groups:
            if not isinstance(source_group, dict) or not isinstance(source_group.get("hooks"), list):
                raise SystemExit(f"Claude hook fragment group must contain hooks list: {event}")
            matcher = source_group.get("matcher", "")
            target_group = None
            for group in target_groups:
                if (
                    isinstance(group, dict)
                    and group.get("matcher", "") == matcher
                    and isinstance(group.get("hooks"), list)
                ):
                    target_group = group
                    break
            if target_group is None:
                target_group = copy.deepcopy(source_group)
                target_group["hooks"] = []
                target_groups.append(target_group)
            for hook in source_group["hooks"]:
                target_group["hooks"].append(copy.deepcopy(hook))
                managed_count += 1
    return managed_count


source_hooks = load_fragment(fragment_path)
settings = load_settings(settings_path)
settings_hooks = settings.setdefault("hooks", {})
if not isinstance(settings_hooks, dict):
    raise SystemExit(f"Claude settings hooks block must be a JSON object: {settings_path}")

remove_managed_hooks(settings_hooks)
managed_count = append_source_hooks(settings_hooks, source_hooks)

if apply_flag != "1":
    print(f"claude settings hooks dry-run: managed_hooks={managed_count} target={settings_path}")
    raise SystemExit(0)

settings_dir = os.path.dirname(settings_path)
os.makedirs(settings_dir, exist_ok=True)
tmp_path = settings_path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as handle:
    json.dump(settings, handle, indent=2)
    handle.write("\n")
if os.path.exists(settings_path):
    os.chmod(tmp_path, stat.S_IMODE(os.stat(settings_path).st_mode))
else:
    os.chmod(tmp_path, 0o600)
os.replace(tmp_path, settings_path)
print(f"claude settings hooks synced: managed_hooks={managed_count} target={settings_path}")
PY
}

claude_marketplace_json_path() {
  local live_home="$1"
  local live_marketplace="$live_home/.claude-plugin/marketplace.json"
  local source_marketplace="$SOURCE_ROOT/targets/claude/.claude-plugin/marketplace.json"

  if [ -f "$source_marketplace" ]; then
    printf '%s\n' "$source_marketplace"
    return 0
  fi

  if [ -f "$live_marketplace" ]; then
    printf '%s\n' "$live_marketplace"
    return 0
  fi

  err "missing Claude marketplace manifest: $live_marketplace (or source fallback $source_marketplace)"
  return 1
}

claude_marketplace_name() {
  local marketplace_json="$1"
  python3 - "$marketplace_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
name = data.get("name")
if not isinstance(name, str) or not name:
    raise SystemExit(f"Claude marketplace manifest missing non-empty name: {sys.argv[1]}")
print(name)
PY
}

claude_marketplace_plugins() {
  local marketplace_json="$1"
  python3 - "$marketplace_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
plugins = data.get("plugins")
if not isinstance(plugins, list):
    raise SystemExit(f"Claude marketplace manifest plugins must be a list: {sys.argv[1]}")
for entry in plugins:
    if not isinstance(entry, dict):
        raise SystemExit(f"Claude marketplace plugin entry must be an object: {sys.argv[1]}")
    name = entry.get("name")
    if not isinstance(name, str) or not name:
        raise SystemExit(f"Claude marketplace plugin entry missing non-empty name: {sys.argv[1]}")
    print(name)
PY
}

claude_materialized_marketplace_home() {
  local state_home="$1"
  local marketplace="$2"

  case "$marketplace" in
    "" | *[!A-Za-z0-9._-]*)
      err "unsafe Claude marketplace name for state path: $marketplace"
      return 1
      ;;
  esac

  printf '%s\n' "$state_home/plugin-marketplaces/$marketplace"
}

materialize_claude_plugin_marketplace() {
  local marketplace_json="$1"
  local materialized_home="$2"

  log "materializing Claude plugin marketplace source=$marketplace_json target=$materialized_home"
  print_cmd python3 - "$SOURCE_ROOT" "$marketplace_json" "$materialized_home" "$APPLY"
  python3 - "$SOURCE_ROOT" "$marketplace_json" "$materialized_home" "$APPLY" <<'PY'
import json
import os
import shutil
import sys

source_root, marketplace_json, materialized_home, apply_flag = sys.argv[1:5]


def load_marketplace(path):
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        raise SystemExit(f"Claude marketplace manifest plugins must be a list: {path}")
    names = []
    for entry in plugins:
        if not isinstance(entry, dict):
            raise SystemExit(f"Claude marketplace plugin entry must be an object: {path}")
        name = entry.get("name")
        if not isinstance(name, str) or not name:
            raise SystemExit(f"Claude marketplace plugin entry missing non-empty name: {path}")
        if any(ch not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-" for ch in name):
            raise SystemExit(f"Claude marketplace plugin entry has unsafe name: {name}")
        names.append(name)
    return names


plugin_names = load_marketplace(marketplace_json)
if apply_flag != "1":
    print(f"claude plugin marketplace materialize dry-run: target={materialized_home} plugins={len(plugin_names)}")
    raise SystemExit(0)

tmp_home = materialized_home + ".tmp"
if os.path.exists(tmp_home):
    shutil.rmtree(tmp_home)
os.makedirs(os.path.join(tmp_home, ".claude-plugin"), exist_ok=True)
os.makedirs(os.path.join(tmp_home, "plugins"), exist_ok=True)
shutil.copy2(marketplace_json, os.path.join(tmp_home, ".claude-plugin", "marketplace.json"))

for plugin in plugin_names:
    build_plugin = os.path.join(source_root, "build", "claude", "plugins", plugin)
    target_manifest = os.path.join(source_root, "targets", "claude", "plugins", plugin, ".claude-plugin")
    dest_plugin = os.path.join(tmp_home, "plugins", plugin)
    dest_manifest = os.path.join(dest_plugin, ".claude-plugin")

    if not os.path.isdir(build_plugin):
        raise SystemExit(f"missing rendered Claude plugin tree: {build_plugin}")
    if not os.path.isdir(target_manifest):
        raise SystemExit(f"missing Claude plugin manifest tree: {target_manifest}")

    shutil.copytree(build_plugin, dest_plugin, symlinks=False)
    if os.path.exists(dest_manifest):
        shutil.rmtree(dest_manifest)
    shutil.copytree(target_manifest, dest_manifest, symlinks=False)

for root, dirs, files in os.walk(tmp_home):
    for name in dirs + files:
        path = os.path.join(root, name)
        if os.path.islink(path):
            raise SystemExit(f"materialized Claude marketplace contains symlink: {path}")

os.makedirs(os.path.dirname(materialized_home), exist_ok=True)
if os.path.exists(materialized_home):
    shutil.rmtree(materialized_home)
os.replace(tmp_home, materialized_home)
print(f"claude plugin marketplace materialized: target={materialized_home} plugins={len(plugin_names)}")
PY
}

claude_marketplace_registered() {
  local marketplaces_json="$1"
  local marketplace="$2"

  python3 - "$marketplaces_json" "$marketplace" <<'PY'
import json
import sys

try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    raise SystemExit(1)
marketplace = sys.argv[2]
for entry in data:
    if isinstance(entry, dict) and entry.get("name") == marketplace:
        raise SystemExit(0)
raise SystemExit(1)
PY
}

claude_plugin_installed() {
  local installed_json="$1"
  local plugin_ref="$2"

  python3 - "$installed_json" "$plugin_ref" <<'PY'
import json
import sys

try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    raise SystemExit(1)
plugin_ref = sys.argv[2]
for entry in data:
    if isinstance(entry, dict) and entry.get("id") == plugin_ref and entry.get("scope") == "user":
        raise SystemExit(0)
raise SystemExit(1)
PY
}

sync_claude_plugin_registry() {
  local live_home="$1"
  local state_home="$2"
  local marketplace_json
  local marketplace
  local materialized_home
  local marketplaces_json=""
  local installed_json=""
  local plugin_ref
  local plugin
  local plugin_count=0
  local refresh_count=0

  marketplace_json="$(claude_marketplace_json_path "$live_home")"
  marketplace="$(claude_marketplace_name "$marketplace_json")"
  materialized_home="$(claude_materialized_marketplace_home "$state_home" "$marketplace")"

  if [ "$APPLY" = "1" ] && ! command -v claude >/dev/null 2>&1; then
    CLAUDE_PLUGIN_STATUS="skipped"
    log "claude plugin registry skipped (claude binary not on PATH)"
    return 0
  fi

  materialize_claude_plugin_marketplace "$marketplace_json" "$materialized_home"

  log "syncing Claude plugin registry marketplace=$marketplace source=$materialized_home"
  if [ "$APPLY" = "1" ]; then
    installed_json="$(claude plugins list --json)"
    while IFS= read -r plugin; do
      [ -n "$plugin" ] || continue
      plugin_ref="$plugin@$marketplace"
      if claude_plugin_installed "$installed_json" "$plugin_ref"; then
        run_cmd claude plugin uninstall "$plugin_ref" --scope user --keep-data
        refresh_count=$((refresh_count + 1))
      fi
    done <<EOF_REFRESH_PLUGINS
$(claude_marketplace_plugins "$marketplace_json")
EOF_REFRESH_PLUGINS

    marketplaces_json="$(claude plugin marketplace list --json)"
    if claude_marketplace_registered "$marketplaces_json" "$marketplace"; then
      run_cmd claude plugin marketplace remove "$marketplace" --scope user
    fi
  else
    run_cmd claude plugin marketplace remove "$marketplace" --scope user
  fi
  run_cmd claude plugin marketplace add "$materialized_home" --scope user

  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    plugin_ref="$plugin@$marketplace"
    run_cmd claude plugin install "$plugin_ref" --scope user
    plugin_count=$((plugin_count + 1))
  done <<EOF_PLUGINS
$(claude_marketplace_plugins "$marketplace_json")
EOF_PLUGINS

  if [ "$APPLY" = "1" ]; then
    CLAUDE_PLUGIN_STATUS="installed"
  else
    CLAUDE_PLUGIN_STATUS="planned"
  fi
  log "claude plugin registry ${CLAUDE_PLUGIN_STATUS}: marketplace=$marketplace source=$materialized_home plugins=$plugin_count refreshed=$refresh_count"
}

codex_marketplace_json_path() {
  local live_home="$1"
  local live_marketplace="$live_home/.agents/plugins/marketplace.json"
  local source_marketplace="$SOURCE_ROOT/targets/codex/.agents/plugins/marketplace.json"

  if [ -f "$source_marketplace" ]; then
    printf '%s\n' "$source_marketplace"
    return 0
  fi

  if [ -f "$live_marketplace" ]; then
    printf '%s\n' "$live_marketplace"
    return 0
  fi

  err "missing Codex marketplace manifest: $live_marketplace (or source fallback $source_marketplace)"
  return 1
}

codex_marketplace_name() {
  local marketplace_json="$1"
  python3 - "$marketplace_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
name = data.get("name")
if not isinstance(name, str) or not name:
    raise SystemExit(f"Codex marketplace manifest missing non-empty name: {sys.argv[1]}")
print(name)
PY
}

codex_marketplace_plugins() {
  local marketplace_json="$1"
  python3 - "$marketplace_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
plugins = data.get("plugins")
if not isinstance(plugins, list):
    raise SystemExit(f"Codex marketplace manifest plugins must be a list: {sys.argv[1]}")
for entry in plugins:
    if not isinstance(entry, dict):
        raise SystemExit(f"Codex marketplace plugin entry must be an object: {sys.argv[1]}")
    name = entry.get("name")
    if not isinstance(name, str) or not name:
        raise SystemExit(f"Codex marketplace plugin entry missing non-empty name: {sys.argv[1]}")
    print(name)
PY
}

codex_materialized_marketplace_home() {
  local state_home="$1"
  local marketplace="$2"

  case "$marketplace" in
    "" | *[!A-Za-z0-9._-]*)
      err "unsafe Codex marketplace name for state path: $marketplace"
      return 1
      ;;
  esac

  printf '%s\n' "$state_home/plugin-marketplaces/$marketplace"
}

materialize_codex_plugin_marketplace() {
  local marketplace_json="$1"
  local materialized_home="$2"

  log "materializing Codex plugin marketplace source=$marketplace_json target=$materialized_home"
  print_cmd python3 - "$SOURCE_ROOT" "$marketplace_json" "$materialized_home" "$APPLY"
  python3 - "$SOURCE_ROOT" "$marketplace_json" "$materialized_home" "$APPLY" <<'PY'
import json
import os
import shutil
import sys

source_root, marketplace_json, materialized_home, apply_flag = sys.argv[1:5]


def load_marketplace(path):
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        raise SystemExit(f"Codex marketplace manifest plugins must be a list: {path}")
    names = []
    for entry in plugins:
        if not isinstance(entry, dict):
            raise SystemExit(f"Codex marketplace plugin entry must be an object: {path}")
        name = entry.get("name")
        if not isinstance(name, str) or not name:
            raise SystemExit(f"Codex marketplace plugin entry missing non-empty name: {path}")
        if any(ch not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-" for ch in name):
            raise SystemExit(f"Codex marketplace plugin entry has unsafe name: {name}")
        names.append(name)
    return names


plugin_names = load_marketplace(marketplace_json)
if apply_flag != "1":
    print(f"codex plugin marketplace materialize dry-run: target={materialized_home} plugins={len(plugin_names)}")
    raise SystemExit(0)

tmp_home = materialized_home + ".tmp"
if os.path.exists(tmp_home):
    shutil.rmtree(tmp_home)
os.makedirs(os.path.join(tmp_home, ".agents", "plugins"), exist_ok=True)
os.makedirs(os.path.join(tmp_home, "plugins"), exist_ok=True)
shutil.copy2(marketplace_json, os.path.join(tmp_home, ".agents", "plugins", "marketplace.json"))

for plugin in plugin_names:
    build_plugin = os.path.join(source_root, "build", "codex", "plugins", plugin)
    target_manifest = os.path.join(source_root, "targets", "codex", "plugins", plugin, ".codex-plugin")
    dest_plugin = os.path.join(tmp_home, "plugins", plugin)
    dest_manifest = os.path.join(dest_plugin, ".codex-plugin")

    if not os.path.isdir(build_plugin):
        raise SystemExit(f"missing rendered Codex plugin tree: {build_plugin}")
    if not os.path.isdir(target_manifest):
        raise SystemExit(f"missing Codex plugin manifest tree: {target_manifest}")

    shutil.copytree(build_plugin, dest_plugin, symlinks=False)
    if os.path.exists(dest_manifest):
        shutil.rmtree(dest_manifest)
    shutil.copytree(target_manifest, dest_manifest, symlinks=False)

for root, dirs, files in os.walk(tmp_home):
    for name in dirs + files:
        path = os.path.join(root, name)
        if os.path.islink(path):
            raise SystemExit(f"materialized Codex marketplace contains symlink: {path}")

os.makedirs(os.path.dirname(materialized_home), exist_ok=True)
if os.path.exists(materialized_home):
    shutil.rmtree(materialized_home)
os.replace(tmp_home, materialized_home)
print(f"codex plugin marketplace materialized: target={materialized_home} plugins={len(plugin_names)}")
PY
}

codex_marketplace_registered() {
  local marketplaces_json="$1"
  local marketplace="$2"

  python3 - "$marketplaces_json" "$marketplace" <<'PY'
import json
import sys

try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    raise SystemExit(1)
marketplace = sys.argv[2]
entries = data.get("marketplaces", []) if isinstance(data, dict) else []
for entry in entries:
    if isinstance(entry, dict) and entry.get("name") == marketplace:
        raise SystemExit(0)
raise SystemExit(1)
PY
}

codex_plugin_installed() {
  local installed_json="$1"
  local plugin_ref="$2"

  python3 - "$installed_json" "$plugin_ref" <<'PY'
import json
import sys

try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    raise SystemExit(1)
plugin_ref = sys.argv[2]
entries = data.get("installed", []) if isinstance(data, dict) else []
for entry in entries:
    if isinstance(entry, dict) and entry.get("pluginId") == plugin_ref:
        raise SystemExit(0)
raise SystemExit(1)
PY
}

# Mirror of sync_claude_plugin_registry for Codex, adapted to the Codex plugin
# CLI (`codex plugin add` / `remove`, `codex plugin marketplace add` / `remove`,
# no `--scope`) and the `{installed:[...],available:[...]}` /
# `{marketplaces:[...]}` JSON shapes. Gated by CODEX_PLUGIN_ACTIVATION: off by
# default so the live `codex plugin marketplace add` never doubles the flat
# skill root (see the CODEX_PLUGIN_ACTIVATION global). Codex discovers each
# installed plugin's bundled skills/<skill>/SKILL.md and ignores the
# `.codex-plugin/plugin.json` `skills` field, so the audit array stays as-is.
sync_codex_plugin_registry() {
  local live_home="$1"
  local state_home="$2"
  local marketplace_json
  local marketplace
  local materialized_home
  local marketplaces_json=""
  local installed_json=""
  local plugin_ref
  local plugin
  local plugin_count=0
  local refresh_count=0

  marketplace_json="$(codex_marketplace_json_path "$live_home")"
  marketplace="$(codex_marketplace_name "$marketplace_json")"
  materialized_home="$(codex_materialized_marketplace_home "$state_home" "$marketplace")"

  if [ "$CODEX_PLUGIN_ACTIVATION" != "1" ]; then
    CODEX_PLUGIN_STATUS="gated"
    log "codex plugin registry gated: marketplace=$marketplace (flat \$CODEX_HOME/skills root stays the live discovery path; set CODEX_PLUGIN_ACTIVATION=1 or pass --codex-plugin-activation to register the marketplace)"
    return 0
  fi

  if [ "$APPLY" = "1" ] && ! command -v codex >/dev/null 2>&1; then
    CODEX_PLUGIN_STATUS="skipped"
    log "codex plugin registry skipped (codex binary not on PATH)"
    return 0
  fi

  materialize_codex_plugin_marketplace "$marketplace_json" "$materialized_home"

  log "syncing Codex plugin registry marketplace=$marketplace source=$materialized_home"
  if [ "$APPLY" = "1" ]; then
    installed_json="$(codex plugin list --json)"
    while IFS= read -r plugin; do
      [ -n "$plugin" ] || continue
      plugin_ref="$plugin@$marketplace"
      if codex_plugin_installed "$installed_json" "$plugin_ref"; then
        run_cmd codex plugin remove "$plugin_ref"
        refresh_count=$((refresh_count + 1))
      fi
    done <<EOF_REFRESH_CODEX_PLUGINS
$(codex_marketplace_plugins "$marketplace_json")
EOF_REFRESH_CODEX_PLUGINS

    marketplaces_json="$(codex plugin marketplace list --json)"
    if codex_marketplace_registered "$marketplaces_json" "$marketplace"; then
      run_cmd codex plugin marketplace remove "$marketplace"
    fi
  else
    run_cmd codex plugin marketplace remove "$marketplace"
  fi
  run_cmd codex plugin marketplace add "$materialized_home"

  while IFS= read -r plugin; do
    [ -n "$plugin" ] || continue
    plugin_ref="$plugin@$marketplace"
    run_cmd codex plugin add "$plugin_ref"
    plugin_count=$((plugin_count + 1))
  done <<EOF_CODEX_PLUGINS
$(codex_marketplace_plugins "$marketplace_json")
EOF_CODEX_PLUGINS

  if [ "$APPLY" = "1" ]; then
    CODEX_PLUGIN_STATUS="installed"
  else
    CODEX_PLUGIN_STATUS="planned"
  fi
  log "codex plugin registry ${CODEX_PLUGIN_STATUS}: marketplace=$marketplace source=$materialized_home plugins=$plugin_count refreshed=$refresh_count"
}

sync_product_activation() {
  local product="$1"
  local live_home
  local state_home

  case "$product" in
    claude)
      live_home="$(product_live_home "$product")"
      state_home="$(product_state_home "$product")"
      sync_claude_settings_hooks "$live_home"
      sync_claude_plugin_registry "$live_home" "$state_home"
      ;;
    codex)
      live_home="$(product_live_home "$product")"
      state_home="$(product_state_home "$product")"
      sync_codex_plugin_registry "$live_home" "$state_home"
      ;;
    *)
      err "unknown product: $product"
      exit 2
      ;;
  esac
}

# Read the skipped count from one prune-stale JSON blob, accumulate it into the
# run-wide total, and surface the skipped rel_paths so the operator sees exactly
# which stale candidates prune-stale could not auto-remove. prune-stale only
# removes provably owned symlinks and empty directories; a retired recursive-file
# managed skill directory (real files, non-empty dir) is reported as skipped and
# left in place, so a blind prune=ok is misleading. See the inbox case
# core/policies/heuristic-system/error-inbox/sync-runtime-surfaces-prune-stale-dir-gap.
# Sets PRUNE_LAST_SKIPPED and bumps PRUNE_SKIPPED_TOTAL.
account_prune_skipped() {
  local product="$1"
  local json="$2"
  local skipped

  skipped="$(printf '%s\n' "$json" | json_number skipped)"
  : "${skipped:=0}"
  PRUNE_LAST_SKIPPED="$skipped"

  if [ "$skipped" -gt 0 ]; then
    PRUNE_SKIPPED_TOTAL=$((PRUNE_SKIPPED_TOTAL + skipped))
    printf '%s\n' "$json" |
      sed -n 's/.*"rel_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/  ? prune-stale left stale candidate for review (product='"$product"'): \1/p'
  fi
}

prune_product() {
  local product="$1"
  local live_home
  local prune_json
  local code
  local changes

  live_home="$(product_live_home "$product")"

  if [ "$NO_PRUNE" = "1" ]; then
    if [ "$APPLY" = "1" ]; then
      log "warning: prune skipped (--no-prune) for product=$product; stale managed runtime surfaces may remain"
    else
      log "prune skipped (--no-prune) for product=$product"
    fi
    return 0
  fi

  log "pruning stale managed surfaces product=$product live_home=$live_home"

  if [ "$APPLY" = "0" ]; then
    run_cmd agent-runtime prune-stale \
      --source-root "$SOURCE_ROOT" \
      --product "$product" \
      --live-home "$live_home" \
      --dry-run
    return 0
  fi

  print_cmd agent-runtime prune-stale \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --apply --format json

  set +e
  prune_json="$(agent-runtime prune-stale \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --apply --format json 2>&1)"
  code=$?
  set -e

  if [ "$code" -ne 0 ]; then
    printf '%s\n' "$prune_json" >&2
    err "prune-stale failed for product=$product (exit=$code); run agent-runtime prune-stale --product $product --live-home $live_home --apply for details"
    return 1
  fi

  changes="$(printf '%s\n' "$prune_json" | json_number changes)"
  account_prune_skipped "$product" "$prune_json"
  log "prune product=$product changes=${changes:-0} skipped=${PRUNE_LAST_SKIPPED:-0}"
}

json_number() {
  local key="$1"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\\([0-9][0-9]*\\).*/\\1/p" | head -n 1
}

doctor_product() {
  local product="$1"
  local live_home
  local state_home
  local doctor_json
  local code
  local block
  local checks
  local exit_code

  live_home="$(product_live_home "$product")"
  state_home="$(product_state_home "$product")"

  if [ "$APPLY" = "0" ]; then
    run_cmd agent-runtime doctor \
      --source-root "$SOURCE_ROOT" \
      --product "$product" \
      --live-home "$live_home" \
      --state-home "$state_home" \
      --class skill-surface \
      --format json
    return 0
  fi

  print_cmd agent-runtime doctor \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    --class skill-surface \
    --format json

  set +e
  doctor_json="$(agent-runtime doctor \
    --source-root "$SOURCE_ROOT" \
    --product "$product" \
    --live-home "$live_home" \
    --state-home "$state_home" \
    --class skill-surface \
    --format json 2>&1)"
  code=$?
  set -e

  block="$(printf '%s\n' "$doctor_json" | json_number block)"
  checks="$(printf '%s\n' "$doctor_json" | json_number checks)"
  exit_code="$(printf '%s\n' "$doctor_json" | json_number exit_code)"

  if [ "$code" -ne 0 ] || [ -z "$block" ] || [ "$block" -gt 0 ]; then
    printf '%s\n' "$doctor_json" >&2
    err "doctor failed for product=$product (exit=$code block=${block:-unknown}); run agent-runtime doctor --product $product --class skill-surface --format json for details"
    return 1
  fi

  log "doctor product=$product ok (checks=${checks:-unknown} block=$block exit=${exit_code:-$code})"
}

verify_codex_prompt_input() {
  if ! selected_includes_codex; then
    CODEX_PROMPT_STATUS="skipped"
    log "codex prompt-input skipped (product=$PRODUCT)"
    return 0
  fi

  if ! command -v codex >/dev/null 2>&1; then
    CODEX_PROMPT_STATUS="skipped"
    log "codex prompt-input skipped (binary not on PATH)"
    return 0
  fi

  if [ "$APPLY" = "0" ]; then
    CODEX_PROMPT_STATUS="planned"
    run_cmd codex debug prompt-input
    return 0
  fi

  CODEX_PROMPT_STATUS="verified"
  run_cmd codex debug prompt-input
}

run_verification() {
  local product

  if [ "$NO_VERIFY" = "1" ]; then
    CODEX_PROMPT_STATUS="skipped"
    log "verification skipped (--no-verify)"
    return 0
  fi

  for product in $(selected_products); do
    doctor_product "$product"
  done

  verify_codex_prompt_input
}

print_summary() {
  local mode="dry-run"
  local doctor_status="planned"
  local prune_status="planned"

  if [ "$APPLY" = "1" ]; then
    mode="apply"
    doctor_status="ok"
    prune_status="ok"
    if [ "$PRUNE_SKIPPED_TOTAL" -gt 0 ]; then
      prune_status="review-needed"
    fi
  fi
  if [ "$NO_PRUNE" = "1" ]; then
    prune_status="skipped"
  fi
  if [ "$NO_VERIFY" = "1" ]; then
    doctor_status="skipped"
  fi

  log "summary: synced surfaces for $(product_label); mode=$mode; prune=$prune_status; doctor=$doctor_status; codex prompt-input=$CODEX_PROMPT_STATUS; codex plugins=$CODEX_PLUGIN_STATUS; claude plugins=$CLAUDE_PLUGIN_STATUS"

  if [ "$prune_status" = "review-needed" ]; then
    log "note: prune-stale could not auto-remove $PRUNE_SKIPPED_TOTAL stale candidate(s) (real files / non-empty managed dirs). Review the paths above and remove any retired managed skill directories by hand. Tracked in core/policies/heuristic-system/error-inbox/sync-runtime-surfaces-prune-stale-dir-gap."
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  local product

  parse_args "$@"
  require_commands git python3
  resolve_source_root
  validate_live_sync_source_root

  if [ "$APPLY" = "1" ]; then
    require_commands agent-runtime
  fi

  log "$PROG_NAME starting (source_root=$SOURCE_ROOT product=$PRODUCT apply=$APPLY no_pull=$NO_PULL no_prune=$NO_PRUNE no_verify=$NO_VERIFY)"

  pull_source
  check_source_counts
  for product in $(selected_products); do
    render_product "$product"
    install_product "$product"
    prune_product "$product"
    sync_product_activation "$product"
  done
  run_verification
  print_summary
}

# Allow tests to source this script as a library (to exercise helpers like
# account_prune_skipped / print_summary in isolation) without running main.
if [ "${SYNC_RUNTIME_SURFACES_LIB:-0}" != "1" ]; then
  main "$@"
fi
