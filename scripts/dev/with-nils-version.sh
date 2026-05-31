#!/usr/bin/env bash
# scripts/dev/with-nils-version.sh — run a command with a chosen nils-cli
# surface on PATH, without touching the Homebrew install or the pinned surface.
#
# Use it to reproduce a regression against an older release (downgrade), or to
# develop coupled changes against an unreleased build before it ships. The pin
# in docs/source/nils-cli-pin.yaml and the meta:nils-cli-bump skill remain the
# only way to actually move the surface. Full workflows:
#   docs/source/nils-cli-version-workflows.md
#
# Compatibility: macOS system bash 3.2 and Linux bash 4+.
# Avoid associative arrays, mapfile, and ${var,,} lowercasing.

set -euo pipefail

PROG="with-nils-version.sh"

NILS_CLI_REPO="${NILS_CLI_REPO:-$HOME/Project/sympoies/nils-cli}"
NILS_REPO_SLUG="${NILS_REPO_SLUG:-sympoies/nils-cli}"
STATE_OUT="${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out"
CACHE_ROOT="$STATE_OUT/nils-versions"

# Surface binaries the kit consumes; missing ones are warned about, not fatal.
SURFACE_BINS="agent-runtime plan-issue plan-tooling forge-cli plan-archive agent-docs"

die() {
  echo "$PROG: $*" >&2
  exit 1
}
note() { echo "$PROG: $*" >&2; }

print_help() {
  cat <<EOF
Usage: $PROG <spec> [-- <command> [args...]]

Resolve a nils-cli surface from <spec>, prepend it to PATH, print the resolved
agent-runtime --version, and exec <command>. With no command, print the resolved
bin dir to stdout and exit.

<spec>:
  release:<tag>   Download released binaries from the GitHub release page.
  <tag>           Shorthand for release:<tag> when it looks like vX.Y.Z.
  src:<ref>       Build the whole workspace from <ref> (tag/branch/sha) in the
                  nils-cli checkout, via a dedicated --detach worktree.
  local           Use the nils-cli checkout's target/debug build (build if missing).
  path:<dir>      Use binaries already present in <dir>.

Environment:
  NILS_CLI_REPO               nils-cli checkout for src:/local
                              (default: \$HOME/Project/sympoies/nils-cli)
  NILS_REPO_SLUG              GitHub owner/repo for release: (default: sympoies/nils-cli)
  NILS_RELEASE_ASSET_PATTERN  gh release download --pattern glob, when the
                              platform auto-pick does not match asset names
  NILS_BUILD_ARGS             extra cargo build args for src:/local

Cache: $CACHE_ROOT/<tag>/  (release: extractions; remove to force a fresh download)

Examples:
  $PROG release:v0.30.0 -- agent-runtime audit-drift
  $PROG src:my-fix -- bash tests/hooks/run.sh
  $PROG local -- agent-runtime render --product codex
  $PROG path:/abs/target/debug        # just resolve and print the bin dir
EOF
}

# --- release: download + extract --------------------------------------------

choose_release_asset() {
  # stdin: asset names (one per line). Echoes the best platform match, if any.
  local os arch os_re arch_re line
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Darwin) os_re='darwin|macos|apple' ;;
    Linux) os_re='linux' ;;
    *) os_re="$os" ;;
  esac
  case "$arch" in
    arm64 | aarch64) arch_re='aarch64|arm64' ;;
    x86_64 | amd64) arch_re='x86_64|amd64' ;;
    *) arch_re="$arch" ;;
  esac
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if printf '%s\n' "$line" | grep -Eqi "$os_re" &&
      printf '%s\n' "$line" | grep -Eqi "$arch_re"; then
      printf '%s\n' "$line"
      return 0
    fi
  done
  return 1
}

resolve_release() {
  # $1 = tag. Echoes the resolved bin dir on stdout. Errors go to stderr.
  local tag dest existing assets chosen archive
  tag="$1"
  dest="$CACHE_ROOT/$tag"

  existing="$(find "$dest" -type f -name agent-runtime 2>/dev/null | head -1 || true)"
  if [ -n "$existing" ]; then
    dirname "$existing"
    return 0
  fi

  command -v gh >/dev/null 2>&1 || die "gh CLI required for release:<tag> downloads"
  mkdir -p "$dest"

  if [ -n "${NILS_RELEASE_ASSET_PATTERN:-}" ]; then
    chosen=""
    note "downloading $NILS_REPO_SLUG@$tag assets matching '$NILS_RELEASE_ASSET_PATTERN'"
    gh release download "$tag" --repo "$NILS_REPO_SLUG" \
      --pattern "$NILS_RELEASE_ASSET_PATTERN" --dir "$dest" --clobber ||
      die "gh release download failed for $tag (pattern: $NILS_RELEASE_ASSET_PATTERN)"
  else
    assets="$(gh release view "$tag" --repo "$NILS_REPO_SLUG" \
      --json assets --jq '.assets[].name' 2>/dev/null || true)"
    [ -n "$assets" ] || die "no assets found for $NILS_REPO_SLUG@$tag (does the release exist?)"
    chosen="$(printf '%s\n' "$assets" | choose_release_asset || true)"
    if [ -z "$chosen" ]; then
      note "could not auto-pick a $(uname -s)/$(uname -m) asset for $tag. Available assets:"
      printf '%s\n' "$assets" | while IFS= read -r asset_name; do
        [ -n "$asset_name" ] && printf '  %s\n' "$asset_name" >&2
      done
      die "set NILS_RELEASE_ASSET_PATTERN to one of the above and retry"
    fi
    note "downloading asset: $chosen"
    gh release download "$tag" --repo "$NILS_REPO_SLUG" \
      --pattern "$chosen" --dir "$dest" --clobber ||
      die "gh release download failed for $tag (asset: $chosen)"
  fi

  # Extract any archive; raw binaries are left in place.
  mkdir -p "$dest/extract"
  for archive in "$dest"/*.tar.gz "$dest"/*.tgz "$dest"/*.zip; do
    [ -e "$archive" ] || continue
    case "$archive" in
      *.zip) unzip -oq "$archive" -d "$dest/extract" ;;
      *) tar -xzf "$archive" -C "$dest/extract" ;;
    esac
  done

  existing="$(find "$dest" -type f -name agent-runtime 2>/dev/null | head -1 || true)"
  [ -n "$existing" ] || die "downloaded $tag but found no agent-runtime binary under $dest"
  chmod +x "$(dirname "$existing")"/* 2>/dev/null || true
  dirname "$existing"
}

# --- src:/local build --------------------------------------------------------

resolve_src() {
  # $1 = ref. Builds the whole workspace in a dedicated detached worktree.
  local ref sanitized wt_root wt
  ref="$1"
  [ -d "$NILS_CLI_REPO/.git" ] || die "nils-cli checkout not found at $NILS_CLI_REPO (set NILS_CLI_REPO)"
  sanitized="$(printf '%s' "$ref" | tr '/ :' '---')"
  wt_root="${NILS_CLI_REPO}-worktrees"
  wt="$wt_root/wnv-$sanitized"
  mkdir -p "$wt_root"
  if [ ! -d "$wt/.git" ] && [ ! -f "$wt/.git" ]; then
    git -C "$NILS_CLI_REPO" fetch --quiet origin 2>/dev/null || true
    git -C "$NILS_CLI_REPO" worktree add --detach "$wt" "$ref" >&2 ||
      die "could not create worktree for ref '$ref'"
  fi
  note "building nils-cli workspace at $ref (this can take a while)"
  # Word-split NILS_BUILD_ARGS so multiple cargo args pass through (bash 3.2: no arrays).
  # shellcheck disable=SC2086
  (cd "$wt" && cargo build ${NILS_BUILD_ARGS:-} >&2) || die "cargo build failed at $ref"
  printf '%s\n' "$wt/target/debug"
}

resolve_local() {
  local bindir
  [ -d "$NILS_CLI_REPO/.git" ] || die "nils-cli checkout not found at $NILS_CLI_REPO (set NILS_CLI_REPO)"
  bindir="$NILS_CLI_REPO/target/debug"
  if [ ! -x "$bindir/agent-runtime" ]; then
    note "building nils-cli workspace in $NILS_CLI_REPO (this can take a while)"
    # Word-split NILS_BUILD_ARGS so multiple cargo args pass through (bash 3.2: no arrays).
    # shellcheck disable=SC2086
    (cd "$NILS_CLI_REPO" && cargo build ${NILS_BUILD_ARGS:-} >&2) || die "cargo build failed in $NILS_CLI_REPO"
  fi
  printf '%s\n' "$bindir"
}

# --- dispatch ----------------------------------------------------------------

resolve_bindir() {
  local spec="$1"
  case "$spec" in
    release:*) resolve_release "${spec#release:}" ;;
    src:*) resolve_src "${spec#src:}" ;;
    local) resolve_local ;;
    path:*) printf '%s\n' "${spec#path:}" ;;
    v[0-9]*.[0-9]*.[0-9]* | [0-9]*.[0-9]*.[0-9]*) resolve_release "$spec" ;;
    *) die "unknown spec: '$spec' (expected release:<tag>|<tag>|src:<ref>|local|path:<dir>)" ;;
  esac
}

main() {
  if [ "$#" -eq 0 ]; then
    print_help >&2
    exit 2
  fi
  case "$1" in
    -h | --help)
      print_help
      exit 0
      ;;
  esac

  local spec bindir missing b
  spec="$1"
  shift
  if [ "${1:-}" = "--" ]; then
    shift
  fi

  bindir="$(resolve_bindir "$spec")"
  [ -n "$bindir" ] || die "could not resolve a bin dir for spec: $spec"
  [ -x "$bindir/agent-runtime" ] || die "agent-runtime not found or not executable in: $bindir"

  missing=""
  for b in $SURFACE_BINS; do
    [ -x "$bindir/$b" ] || missing="$missing $b"
  done
  [ -z "$missing" ] || note "warning: surface binaries missing from $bindir:$missing"

  note "using nils-cli surface from $bindir"
  "$bindir/agent-runtime" --version >&2 || true

  if [ "$#" -eq 0 ]; then
    # No command: print the resolved bin dir for scripting and exit.
    printf '%s\n' "$bindir"
    exit 0
  fi

  exec env PATH="$bindir:$PATH" "$@"
}

main "$@"
