---
name: create-project-skill
description:
  Scaffold a project-local skill under a consuming repo's `.agents/skills`
  tree with optional scripts, references, tests, and Claude bridge surfaces.
---

# Create Project Skill

## Contract

Prereqs:

- Run inside the target consuming project's git work tree.
- The request is for a project-local skill, not a repo-owned runtime-kit managed
  skill. Use `create-skill` for `agent-runtime-kit` managed skills.
- The caller has supplied or accepted a lowercase hyphenated skill name.
- Existing files are never overwritten without explicit user approval.

Inputs:

- Skill name, description, intended entrypoint, and whether the skill needs
  skill-owned `scripts/`, `tests/`, `references/`, `fixtures/`, or `bin/`.
- Optional Claude exposure mode:
  - `.claude/skills -> ../.agents/skills` symlink for Claude skill discovery.
  - `.agents/scripts/<command>.sh` thin wrapper for project slash-command style
    dispatch.
- Optional project validation command to run after scaffolding.

Outputs:

- `.agents/skills/<skill>/SKILL.md`.
- Optional `.agents/skills/<skill>/scripts/<skill>.sh` executable stub.
- Optional `.agents/skills/<skill>/{tests,references,fixtures,bin}/` support
  directories.
- Optional `.claude/skills` symlink and `.gitignore` entry for `.claude/`.
- Optional `.agents/scripts/<command>.sh` wrapper that delegates to the
  skill-owned script or another canonical project command.
- A validation summary with created paths and any skipped optional surfaces.

Failure modes:

- The current directory is not inside a git work tree.
- The skill name is malformed, ambiguous, or collides with an existing
  `.agents/skills/<skill>` path.
- A requested wrapper path already exists and replacement was not approved.
- The workflow would mutate runtime-kit manifests, product render output,
  golden snapshots, or global runtime homes.
- Validation fails after scaffolding.

## Entrypoint

Use the target project shape directly:

```bash
project_root="$(git rev-parse --show-toplevel)"
skill="<skill-name>"
skill_dir="$project_root/.agents/skills/$skill"

case "$skill" in
  *[!a-z0-9-]* | -* | *- | "" )
    echo "invalid project skill name: $skill" >&2
    exit 2
    ;;
esac

test ! -e "$skill_dir"
mkdir -p "$skill_dir/scripts" "$skill_dir/references" "$skill_dir/tests"
$EDITOR "$skill_dir/SKILL.md"
```

When a script entrypoint is needed:

```bash
script="$skill_dir/scripts/$skill.sh"
$EDITOR "$script"
chmod +x "$script"
```

When Claude skill discovery is requested:

```bash
mkdir -p "$project_root/.claude"
ln -s ../.agents/skills "$project_root/.claude/skills"
```

When a project command wrapper is requested:

```bash
mkdir -p "$project_root/.agents/scripts"
$EDITOR "$project_root/.agents/scripts/<command>.sh"
chmod +x "$project_root/.agents/scripts/<command>.sh"
```

## Workflow

1. Resolve the target project root with `git rev-parse --show-toplevel`.
2. Confirm this is a project-local skill request. If the user wants a
   runtime-kit managed skill, switch to `create-skill`.
3. Normalize and validate the skill name as lowercase hyphenated text.
4. Inspect `.agents/skills/`, `.agents/scripts/`, `.claude/`, project
   `AGENTS.md` / `CLAUDE.md`, and nearby local skill conventions before
   editing.
5. Refuse to overwrite existing skill directories, scripts, wrappers, symlinks,
   or project policy files unless the user explicitly approves replacement.
6. Create `SKILL.md` with front matter, H1, Contract, Entrypoint or Scripts,
   Workflow, and Boundary sections.
7. Add only the support folders the workflow needs. Keep stubs small and mark
   TODO behavior clearly when implementation remains.
8. If Claude discovery is requested, create or verify `.claude/skills ->
   ../.agents/skills` and ensure `.claude/` is ignored when appropriate.
9. If a slash-command style wrapper is requested, create a thin
   `.agents/scripts/<command>.sh` wrapper that delegates to the skill-owned
   script or another canonical project command.
10. Run focused validation: `test -f`, shell syntax for generated scripts,
    project-owned checks when available, and the user's requested validation
    command.
11. Report created paths, skipped optional paths, validation status, and next
    implementation work.

## Boundary

This skill owns project-local skill scaffolding only. It does not mutate
`manifests/skills.yaml`, `manifests/plugins.yaml`, `targets/`, `build/`,
`tests/golden/`, sandbox expected skill lists, or live global runtime homes. If
project-local creation needs a reusable dry-run/apply planner, reference graph,
or machine-readable mutation contract, extract that deterministic behavior to
released `nils-cli` first and then call it from this workflow.
