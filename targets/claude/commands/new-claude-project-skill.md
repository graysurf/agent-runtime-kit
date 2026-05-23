---
name: new-project-skill
description: >
  Scaffold a project-local Claude Code skill in the current git repo
  (.agents/skills/<name>/ layout with a .claude/skills symlink), so any
  repo can own repo-specific orchestration skills. Wraps
  scripts/new-project-skill.sh.
allowed-tools: Bash, Read
argument-hint: "SKILL-NAME [--description \"...\"]"
---

# /new-project-skill

Bootstrap a project-local skill in the current repo. Follows the nils-cli
layout for project-local agent surface:

- `.agents/skills/<name>/SKILL.md` — tracked contract
- `.agents/skills/<name>/scripts/<name>.sh` — tracked stub (executable)
- `.claude/skills -> ../.agents/skills` — gitignored symlink
- `.gitignore` picks up `.claude/` when missing

## Behaviour

```bash
bash $HOME/.claude/scripts/new-project-skill.sh $ARGUMENTS
```

## Usage

```text
/new-project-skill <skill-name>
/new-project-skill <skill-name> --description "One-line description."
```

`<skill-name>` must be kebab-case with at least one hyphen. Convention is
to prefix with the project name so skills sort and disambiguate cleanly:
`my-cli-release`, `my-cli-deliver-pr`, `my-cli-verify-checks`.

## What gets created

| Path | Purpose |
| ---- | ------- |
| `.agents/skills/<name>/SKILL.md` | Frontmatter stub + Contract / Workflow TODO sections |
| `.agents/skills/<name>/scripts/<name>.sh` | `set -euo pipefail` skeleton + `--help` parser |
| `.claude/skills -> ../.agents/skills` | Per-clone symlink (gitignored) |
| `.gitignore` | Appends `.claude/` when not already matched |
| `.agents/scripts/pre-pr.sh` | TODO stub wiring up `/pre-pr` for this repo (only when missing) |

## Guardrails

- Refuses to run outside a git work tree.
- Refuses to overwrite an existing `.agents/skills/<name>/` directory.
- Refuses to replace `.claude/skills` if it already exists as a non-symlink
  (won't destroy your data); prints a warning if it's a symlink to a
  different target.

## Next steps after scaffolding

1. Fill in `SKILL.md` frontmatter `description` (and `argument-hint` if
   relevant); describe the skill's **Contract** sections (Prereqs / Inputs
   / Outputs / Failure modes).
2. Implement `scripts/<name>.sh`.
3. Fill in `.agents/scripts/pre-pr.sh` with the repo's real pre-push gate
   stack — or delete it if `/pre-pr` isn't wanted here.
4. Sanity check: `bash .agents/skills/<name>/scripts/<name>.sh --help`.
5. Commit when the skill actually does something useful.

## References

- `scripts/new-project-skill.sh`
- `docs/dispatcher-commands.md` — when to build a skill vs extend a dispatcher
- `AGENTS.md` — "Project-local skills" entry
