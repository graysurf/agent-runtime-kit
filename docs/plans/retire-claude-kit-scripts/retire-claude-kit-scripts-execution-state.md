# Execution State: Retire claude-kit Scripts

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: complete
- Target scope: migrate `~/.claude/scripts/` and `~/.claude/commands/`
  ownership from claude-kit into agent-runtime-kit and remove duplicated
  dispatcher wiring
- Current task: closeout
- Next task: none
- Last updated: 2026-05-23
- Branch: feat/retire-claude-kit-scripts (Sprint 1, merged as #59),
  feat/retire-claude-kit-scripts-closeout (closeout), and
  claude-kit/feat/retire-script-surface (Sprint 3, local-only because the
  claude-kit GitHub repo is archived / read-only)
- Source document: docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-plan.md
- Plan document: docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-plan.md
- Direct source-doc execution waiver: user explicitly requested the plan
  be committed first so the next session could pick up implementation
  directly.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add Claude-only scripts to arkit | PR #59 (`0aae4cc`) | `memory-snapshot.sh` migrated; `doctor.sh` and `upstream-drift.sh` dropped per scope refinement. |
| 1.2 | done | Add runtime-agnostic helpers to arkit | PR #59 (`0aae4cc`) | `new-project-skill.sh`, `plan-issue-adapter` parked under `targets/claude/scripts/`. |
| 1.3 | done | Add Claude command surface to arkit | PR #59 (`0aae4cc`) | `new-project-skill.md`, `memory-clean.md`. `/doctor` dropped. |
| 1.4 | done | Wire link-map entries | PR #59 (`0aae4cc`) | Two directory symlinks: `claude.scripts-tree` and `claude.commands-tree`. |
| 2.1 | done | Live install onto `~/.claude/` | live `agent-runtime install --apply` on 2026-05-23 | `~/.claude/scripts` and `~/.claude/commands` now resolve into `agent-runtime-kit/targets/claude/`. |
| 2.2 | done | Smoke-test migrated surfaces | live `--help` invocations of all three migrated scripts | All three exited zero. |
| 3.1 | done | Drop duplicated dispatchers and slash commands | claude-kit `59a8e79` (local) | Twelve files removed from claude-kit working tree; `~/.claude/commands/` after re-install carries only the arkit two. |
| 3.2 | done | Drop claude-kit-only infrastructure | claude-kit `59a8e79` (local) | `scripts/ci/`, `_plugins.env`, `_symlinks.env`, `install.sh`, `uninstall.sh`, `.githooks/pre-commit`, `.github/workflows/ci.yml`, `docs/drift-baseline.json`, `doctor.sh`, `upstream-drift.sh` all removed. |
| 3.3 | done | Record archive marker on claude-kit | claude-kit `59a8e79` (local) | `MOVED.md` extended with live-install migration record and links to plan + issue. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-plan.md --explain` | pass | Clean. |
| `agent-runtime install --product claude --dry-run` | pass | 5 new symlinks planned (2 directory, 3 individual files inside the new tree). |
| `agent-runtime audit-drift` | pass | Clean (20 intentional-difference findings only). |
| `bash $HOME/.claude/scripts/memory-snapshot.sh --help` | pass | Live install verified. |
| `bash $HOME/.claude/scripts/new-project-skill.sh --help` | pass | Live install verified. |
| `$HOME/.claude/scripts/plan-issue-adapter --help` | pass | Live install verified. |
| GitHub Actions `scripts/ci/all.sh` on PR #59 | pass | 51s. |

## Closeout Gate

- Close condition met: `~/.claude/scripts/` and `~/.claude/commands/`
  resolve entirely through `agent-runtime-kit/targets/claude/`; the six
  dispatcher files plus claude-kit-only infrastructure are removed from
  claude-kit working tree; `new-project-skill`, `memory-clean`, and
  `memory-snapshot.sh` all run against the arkit-managed install.
- Reopen triggers: any new file added to `~/.claude/scripts/` or
  `~/.claude/commands/` resolves into claude-kit instead of arkit; any
  `plugin:meta:*` skill loses dispatch parity with the dropped slash
  commands.
- Sprint 3 limitation: the claude-kit GitHub repo is archived and
  read-only. Cleanup commit `59a8e79` exists on the local
  `feat/retire-script-surface` branch but cannot be pushed. The user's
  stated principle of "no new references to claude-kit" treats this as
  acceptable; the live install no longer reads through claude-kit.
