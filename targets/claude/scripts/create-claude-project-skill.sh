#!/usr/bin/env bash
#
# create-claude-project-skill.sh — scaffold a project-local skill so Claude
# Code picks it up in the current git repo, or just wire up the
# `.agents/skills` → `.claude/skills` bridge in a repo that already has
# skills.
#
# Default mode (with <skill-name>) writes:
#
#   <repo>/.agents/skills/<name>/SKILL.md           (tracked, canonical source)
#   <repo>/.agents/skills/<name>/scripts/<name>.sh  (tracked, stub)
#   <repo>/.claude/skills -> ../.agents/skills      (gitignored, Claude entry)
#
# `--link-only` mode skips the skill scaffold and only sets up the bridge —
# the `.claude/skills` symlink, the `.gitignore` entry, and the
# `.agents/scripts/pre-pr.sh` stub. Use this when a repo already has
# `.agents/skills/` populated and just needs Claude to see it.
#
# The `.agents/skills/` tree follows the Codex/nils-cli skill convention so
# the source can be promoted later, but Claude Code does not read it
# directly — the `.claude/skills` symlink is the part that actually exposes
# the skill to Claude. This script's reason for existing is that bridging
# step; without it, Claude would not see the skill regardless of how good
# the SKILL.md is.
#
# Also:
#   - Adds `.claude/` to .gitignore when missing.
#   - Refuses to overwrite an existing skill directory of the same name.
#
# The skill starts as a TODO stub; the caller fills in the frontmatter
# description, contract sections, and script body.
#
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  create-claude-project-skill.sh <skill-name> [--description "..."]
  create-claude-project-skill.sh --link-only

Arguments:
  <skill-name>         kebab-case, must contain at least one hyphen. Convention:
                       prefix with the project name so the skill sorts and
                       disambiguates cleanly, e.g. `my-cli-release` or
                       `my-cli-deliver-pr`.

Options:
  --description TEXT   Seed the SKILL.md `description:` field. Defaults to a
                       `TODO:` placeholder you fill in before committing.
  --link-only          Skip skill scaffolding. Only build the `.claude/skills`
                       symlink, `.gitignore` entry, and `.agents/scripts/pre-pr.sh`
                       stub. Use when `.agents/skills/` already exists in this
                       repo and you just want Claude to see it. Not combinable
                       with <skill-name> or --description.
  -h, --help           Show this help.

What it creates (all paths relative to the current repo root):

  .agents/skills/<skill-name>/SKILL.md                   (skill mode only)
  .agents/skills/<skill-name>/scripts/<skill-name>.sh    (skill mode only, chmod +x)
  .claude/skills -> ../.agents/skills                    (symlink)
  .gitignore entry for .claude/                          (when missing)

Next steps printed on success (skill mode):

  1. Edit SKILL.md (frontmatter + Contract sections).
  2. Implement scripts/<skill-name>.sh.
  3. Commit once the skill actually does something.
USAGE
}

name=""
description=""
link_only=false

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --description)
      description="${2:-}"
      shift 2
      ;;
    --link-only)
      link_only=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "error: unknown flag: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$name" ]]; then
        echo "error: unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      name="$1"
      shift
      ;;
  esac
done

if [[ "$link_only" == true ]]; then
  if [[ -n "$name" || -n "$description" ]]; then
    echo "error: --link-only does not take a skill name or --description" >&2
    usage >&2
    exit 2
  fi
else
  if [[ -z "$name" ]]; then
    usage >&2
    exit 2
  fi
  if ! [[ "$name" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)+$ ]]; then
    echo "error: skill name must be kebab-case with at least one hyphen" >&2
    echo "       (got: '$name' — e.g. 'my-cli-release')" >&2
    exit 2
  fi
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "error: must run inside a git work tree" >&2
  exit 1
fi
cd "$repo_root"

if [[ "$link_only" == false ]]; then
  skill_dir=".agents/skills/$name"
  skill_md="$skill_dir/SKILL.md"
  script_file="$skill_dir/scripts/$name.sh"

  if [[ -e "$skill_dir" ]]; then
    echo "error: $skill_dir already exists — pick a different name or remove it first" >&2
    exit 1
  fi
fi

if [[ "$link_only" == false ]]; then

  # Derive a Title Case heading from the skill name.
  heading="$(
    printf '%s' "$name" |
      awk -F- '{
        for (i = 1; i <= NF; i++) {
          $i = toupper(substr($i, 1, 1)) substr($i, 2)
        }
        out = $1
        for (i = 2; i <= NF; i++) out = out " " $i
        print out
      }'
  )"

  desc_line="${description:-TODO: one-line description of what this skill does, including the trigger phrases a user would say to invoke it.}"

  mkdir -p "$skill_dir/scripts"

  # --- SKILL.md template ------------------------------------------------------

  cat >"$skill_md" <<SKILL_EOF
---
name: $name
description: >
  $desc_line
argument-hint: "<arg-shape>"
allowed-tools: Bash, Read
---

# $heading

TODO: short paragraph describing what this skill orchestrates and when the
user should invoke it.

## Contract

Prereqs:

- TODO: required commands / tools / git work tree conditions.

Inputs:

- Required:
  - \`<--flag VALUE>\` — TODO
- Optional:
  - \`<--other-flag>\` — TODO

Outputs:

- TODO: list the concrete things this skill mutates or produces.

Exit codes:

- \`0\`: success
- \`1\`: command failed or a prerequisite is missing
- \`2\`: usage error or invalid inputs

Failure modes:

- TODO: enumerate the conditions under which this skill aborts.

## Scripts (only entrypoints)

- \`.agents/skills/$name/scripts/$name.sh\`

## Workflow

1. TODO: step.
2. TODO: step.
SKILL_EOF

  # --- script template --------------------------------------------------------

  cat >"$script_file" <<'SCRIPT_HEADER'
#!/usr/bin/env bash
SCRIPT_HEADER

  cat >>"$script_file" <<SCRIPT_BODY
#
# $name.sh — TODO: one-line description.
#
# See sibling SKILL.md for the full contract.
#
set -euo pipefail

SCRIPT_NAME="$name.sh"

usage() {
  cat <<'USAGE'
Usage:
  $name.sh [options]

Options:
  -h, --help   Show this help.
USAGE
}

while [[ \$# -gt 0 ]]; do
  case "\${1:-}" in
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: \$1" >&2; usage >&2; exit 2 ;;
  esac
done

echo "\$SCRIPT_NAME — not yet implemented" >&2
exit 1
SCRIPT_BODY

  chmod +x "$script_file"

fi # link_only == false

# --- .claude/skills symlink -------------------------------------------------

mkdir -p .claude
symlink_target="../.agents/skills"
symlink_path=".claude/skills"
symlink_note=""

if [[ -L "$symlink_path" ]]; then
  current="$(readlink "$symlink_path")"
  if [[ "$current" == "$symlink_target" ]]; then
    symlink_note="ok (already pointing at $symlink_target)"
  else
    symlink_note="WARNING: points at $current (expected $symlink_target) — leaving as-is"
  fi
elif [[ -e "$symlink_path" ]]; then
  echo "error: $symlink_path exists and is not a symlink; resolve manually before re-running" >&2
  exit 1
else
  ln -s "$symlink_target" "$symlink_path"
  symlink_note="created $symlink_path -> $symlink_target"
fi

# --- .gitignore -------------------------------------------------------------

gitignore_note=""
if [[ -f .gitignore ]]; then
  if grep -qE '^\.claude/?$' .gitignore; then
    gitignore_note="ok (.claude/ already ignored)"
  else
    {
      printf '\n'
      printf '# Project-local Claude Code directory (skills live in .agents/skills/)\n'
      printf '.claude/\n'
    } >>.gitignore
    gitignore_note="added .claude/ entry"
  fi
else
  cat >.gitignore <<'GITIGNORE_EOF'
# Project-local Claude Code directory (skills live in .agents/skills/)
.claude/
GITIGNORE_EOF
  gitignore_note="created .gitignore with .claude/"
fi

# --- .agents/scripts/pre-pr.sh (repo's /pre-pr gate stack) -----------------

pre_pr_path=".agents/scripts/pre-pr.sh"
pre_pr_note=""
if [[ -e "$pre_pr_path" ]]; then
  pre_pr_note="ok ($pre_pr_path already exists)"
else
  mkdir -p .agents/scripts
  cat >"$pre_pr_path" <<'PREPR_EOF'
#!/usr/bin/env bash
#
# Pre-push gate stack for this repo — invoked by the global /pre-pr
# dispatcher when cwd is this repo. Replace the TODO below with the real
# checks this project runs before a PR / push.
#
set -euo pipefail

# TODO: fill in the gate stack for this repo. Examples:
#   Rust:    cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
#   Node/TS: npm run lint && npm run typecheck && npm test
#   Python:  ruff check . && mypy . && pytest
#   Go:      go vet ./... && go test ./...
#   docs:    rumdl check --config .rumdl.toml .

echo ".agents/scripts/pre-pr.sh — TODO: fill in your gate stack" >&2
exit 1
PREPR_EOF
  chmod +x "$pre_pr_path"
  pre_pr_note="created $pre_pr_path (TODO stub)"
fi

# --- summary ---------------------------------------------------------------

if [[ "$link_only" == true ]]; then
  cat <<SUMMARY
Bridged .agents/skills/ into Claude (no skill scaffolded):

Symlink:    $symlink_note
.gitignore: $gitignore_note
/pre-pr:    $pre_pr_note

Next steps:

  1. Confirm .agents/skills/ exists in this repo — without it, the symlink target is empty.
  2. Fill in $pre_pr_path with the repo's real gate stack (or delete if /pre-pr isn't wanted here).
  3. To add a new skill later:  create-claude-project-skill.sh <skill-name>
SUMMARY
else
  cat <<SUMMARY
Scaffolded project-local skill:

  $skill_md
  $script_file

Symlink:    $symlink_note
.gitignore: $gitignore_note
/pre-pr:    $pre_pr_note

Next steps:

  1. Edit $skill_md — fill in description, Contract sections, Workflow.
  2. Implement $script_file.
  3. Fill in $pre_pr_path with the repo's real gate stack (or delete if /pre-pr isn't wanted here).
  4. Try it:  bash $script_file --help
  5. Commit once the skill does something real.
SUMMARY
fi
