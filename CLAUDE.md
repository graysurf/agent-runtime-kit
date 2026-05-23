# CLAUDE.md

Project context for the `agent-runtime-kit` repository. This file is loaded
into the Claude Code context for any session whose `cwd` is this repo, and is
also linked from `$HOME/.claude/CLAUDE.md` as the canonical home-scope Claude
policy. Personal global instructions belong in your own auto-memory directory
(`~/.config/agent-memory/global/`), not here.

## Working with Files

- Before editing, beyond the target file itself, also read its definitions, call
  sites, and dependencies — not just the lines being changed.
- Debug/test artifacts: write to
  `${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/`
  instead of `/tmp`, and reference that path in the reply.

## agent-docs Preflight

`agent-docs` is the mandatory entrypoint to validate applicable docs/policies
before implementation work. The `UserPromptSubmit` hook reminds with
`--docs-home "$HOME/.config/agent-kit"`; the same path also resolves through
the `~/.claude/AGENT_DOCS.toml` and `~/.claude/AGENTS.md` symlinks. Run the
preflight sequence before edits/tests/commits:

1. Determine runtime intent (`startup`, `project implementation`,
   `technical research`, `skill authoring`).
2. `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist`
3. Run the strict gate for the active intent:
   - Project implementation:
     `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist`
   - Technical research:
     `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context task-tools --strict --format checklist`
   - Skill authoring:
     `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context skill-dev --strict --format checklist`
4. If any required doc is missing or strict resolve fails, stop write actions
   and run
   `agent-docs --docs-home "$HOME/.config/agent-kit" baseline --check --target all --strict --format text`.
5. Proceed with edits/tests/commits only when required preflight docs are
   `status=present`.

New repository bootstrap (missing baseline docs): run `agent-doc-init` and
then verify with the baseline check above.

## Commit Rules

Always use the `/semantic-commit` skill — direct `git commit` is blocked by
`core/hooks/shared/block-direct-git-commit.py`, and the body gate enforces
1–2 bullets on non-trivial commits.

Pre-commit: follow `DEVELOPMENT.md` to run the relevant tests/checks before
committing.

## PR Rules

PR / MR lifecycle is split per host. Direct `gh pr create` / `glab mr create`
are blocked by hook — pick by phase + branch type:

| Phase | GitHub feat (`feat/*`) | GitHub bug (`fix/*`) | GitLab feat | GitLab bug |
| --- | --- | --- | --- | --- |
| Open draft | `pr:create-feature-pr` | `pr:create-bug-pr` | `pr:create-gitlab-mr` | `pr:create-gitlab-mr` |
| Merge + cleanup | `pr:close-feature-pr` | `pr:close-bug-pr` | `pr:close-gitlab-mr` | `pr:close-gitlab-mr` |
| End-to-end | `pr:deliver-feature-pr` | `pr:deliver-bug-pr` | `pr:deliver-gitlab-mr` | `pr:deliver-gitlab-mr` |

- "ship it" / "deliver" → run the matching `pr:deliver-*` skill (preflight →
  create → wait CI → close).
- Branch: `feat/<slug>` or `fix/<slug>` (lowercase, hyphenated, 3–6 words;
  ticket id `ABC-123` → `feat/abc-123-<slug>`).
- Confirm a 1–2 sentence summary the user has approved before opening — never
  derive title / body from `git log -1`.
- Never force-push `main`.

## Heuristic System

`HEURISTIC_SYSTEM.md` (under `$HOME/.config/agent-kit/`) defines how skill
workflow failures get compressed into durable knowledge. When a skill
misbehaves, gets worked around, or produces a useful lesson, route the
signal by the table below:

| Signal | Route |
| --- | --- |
| Transient failure fixed in the same turn | No durable artifact; mention in reply only |
| Unresolved, important workflow gap | `heuristic-error-inbox new --from-skill-usage <record>` |
| Reproducible bug | Focused test or script fix |
| Repeated, cross-skill failure | `heuristic-system/operation-records/<slug>.md` |
| Stable project policy | CLAUDE.md / AGENTS.md / the skill's `SKILL.md` |

Active inbox lives at `heuristic-system/error-inbox/` under
`$HOME/.config/agent-kit/`. After an entry is `promoted` or `wontfix` with no
remaining next action, archive it under
`heuristic-system/error-inbox/archive/YYYY/` via the `heuristic-error-inbox`
skill — never delete in place.
