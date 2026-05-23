#!/usr/bin/env bash
#
# Snapshot / restore ~/.claude/projects/*/memory/ trees.
#
# Out:    tar -czf <out> [encryption optional via openssl enc -aes-256-cbc -salt]
# In:     reverses the above; refuses to overwrite existing memory/ unless --force.
#
# Snapshots are NEVER tracked in this repo — the script refuses to write a
# snapshot path that resolves inside CLAUDE_KIT_REPO (or the discovered
# repo root if unset).
#
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  memory-snapshot.sh --out <PATH> [--encrypt]
  memory-snapshot.sh --restore <PATH> [--force]

Modes:
  --out PATH      Tar.gz every ~/.claude/projects/*/memory/ tree into PATH.
                  With --encrypt, wraps tarball with openssl enc -aes-256-cbc
                  (asks for passphrase via openssl prompt).
  --restore PATH  Extract PATH back into ~/.claude/projects/*/memory/.
                  Refuses to overwrite an existing memory/ dir unless --force.
                  Detects encrypted snapshots automatically (openssl Salted__ header).

Safety:
  * The output PATH must NOT resolve inside this repository or any tracked
    runtime-kit checkout — snapshots are personal data and stay out of source
    control.
  * --restore --force is required to overwrite an existing memory/ directory.
  * The script never modifies projects/<id>/sessions/, history.jsonl, or
    auth-context.json — only memory/ trees.

Examples:
  bash scripts/memory-snapshot.sh --out ~/Backups/claude-memory-2026-04-17.tar.gz
  bash scripts/memory-snapshot.sh --out ~/Backups/x.tar.gz.enc --encrypt
  bash scripts/memory-snapshot.sh --restore ~/Backups/x.tar.gz
USAGE
}

mode=""
target=""
encrypt=0
force=0
while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --out)
      mode="out"
      target="${2:-}"
      shift 2
      ;;
    --restore)
      mode="restore"
      target="${2:-}"
      shift 2
      ;;
    --encrypt)
      encrypt=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$mode" || -z "$target" ]]; then
  usage >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${CLAUDE_KIT_REPO:-$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || true)}"
claude="$HOME/.claude"
projects="$claude/projects"

# Resolve absolute path for safety check (handles ~ in user input).
# shellcheck disable=SC2088  # case patterns deliberately match literal ~/ from CLI input
case "$target" in
  '~/'*) target="$HOME/${target#'~/'}" ;;
  '~') target="$HOME" ;;
esac
target_abs="$(cd "$(dirname -- "$target")" 2>/dev/null && pwd)/$(basename -- "$target")" || target_abs="$target"

if [[ -n "$repo_root" ]]; then
  case "$target_abs" in
    "$repo_root"/*)
      echo "error: refuse to write snapshot inside repo ($repo_root)" >&2
      echo "       choose a path outside the working tree (e.g. ~/Backups/)" >&2
      exit 2
      ;;
  esac
fi

if [[ "$mode" == "out" ]]; then
  if [[ ! -d "$projects" ]]; then
    echo "error: $projects not found — nothing to snapshot" >&2
    exit 2
  fi

  # Build a list of memory/ trees relative to ~/.claude/.
  pushd "$claude" >/dev/null
  mapfile -t mem_dirs < <(find projects -mindepth 2 -maxdepth 2 -type d -name memory)
  popd >/dev/null

  if [[ "${#mem_dirs[@]}" -eq 0 ]]; then
    echo "error: no projects/*/memory/ trees under $claude" >&2
    exit 2
  fi

  echo "Snapshotting ${#mem_dirs[@]} memory tree(s) -> $target_abs"
  if [[ "$encrypt" -eq 1 ]]; then
    if ! command -v openssl >/dev/null 2>&1; then
      echo "error: --encrypt requires openssl on PATH" >&2
      exit 2
    fi
    tar -C "$claude" -czf - "${mem_dirs[@]}" |
      openssl enc -aes-256-cbc -salt -pbkdf2 -out "$target_abs"
  else
    tar -C "$claude" -czf "$target_abs" "${mem_dirs[@]}"
  fi
  echo "wrote: $target_abs ($(du -h "$target_abs" | cut -f1))"
  exit 0
fi

if [[ "$mode" == "restore" ]]; then
  if [[ ! -f "$target_abs" ]]; then
    echo "error: snapshot file not found: $target_abs" >&2
    exit 2
  fi

  # Detect encryption by reading the first 8 bytes safely (avoids null-byte warnings).
  is_enc="$(
    python3 - "$target_abs" <<'PY'
import sys
with open(sys.argv[1], "rb") as fh:
    print(1 if fh.read(8) == b"Salted__" else 0)
PY
  )"

  # Pre-flight: peek at member list to find which memory/ dirs would be overwritten.
  declare -a planned=()
  if [[ "$is_enc" -eq 1 ]]; then
    if ! command -v openssl >/dev/null 2>&1; then
      echo "error: encrypted snapshot but openssl not on PATH" >&2
      exit 2
    fi
    mapfile -t planned < <(openssl enc -d -aes-256-cbc -pbkdf2 -in "$target_abs" | tar -tzf - 2>/dev/null | awk -F/ 'NF>=3 && $3=="memory" {print $1"/"$2"/"$3}' | sort -u)
  else
    mapfile -t planned < <(tar -tzf "$target_abs" 2>/dev/null | awk -F/ 'NF>=3 && $3=="memory" {print $1"/"$2"/"$3}' | sort -u)
  fi

  if [[ "${#planned[@]}" -eq 0 ]]; then
    echo "error: snapshot has no projects/<id>/memory/ entries" >&2
    exit 2
  fi

  conflicts=()
  for p in "${planned[@]}"; do
    [[ -d "$claude/$p" ]] && conflicts+=("$p")
  done

  if [[ "${#conflicts[@]}" -gt 0 && "$force" -ne 1 ]]; then
    echo "error: would overwrite existing memory dir(s):" >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    echo "pass --force to proceed" >&2
    exit 1
  fi

  echo "Restoring ${#planned[@]} memory tree(s) from $target_abs"
  if [[ "$is_enc" -eq 1 ]]; then
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$target_abs" |
      tar -C "$claude" -xzf -
  else
    tar -C "$claude" -xzf "$target_abs"
  fi
  echo "restored ${#planned[@]} tree(s)."
  exit 0
fi
