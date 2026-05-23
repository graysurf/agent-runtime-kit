# Execution State: Retire claude-kit Scripts

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: planning landed; implementation pending
- Target scope: migrate `~/.claude/scripts/` and `~/.claude/commands/`
  ownership from claude-kit into agent-runtime-kit and remove duplicated
  dispatcher wiring
- Current task: Sprint 1 Task 1.1 — add Claude-only scripts to arkit
- Next task: Sprint 1 Task 1.2 — add runtime-agnostic helpers
- Last updated: 2026-05-23
- Branch: feat/retire-claude-kit-scripts
- Source document: docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-discussion-source.md
- Plan document: docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-plan.md
- Direct source-doc execution waiver: user explicitly requested the plan be
  committed first so the next session can pick up implementation directly.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add Claude-only scripts to arkit | | `memory-snapshot.sh` only; `doctor.sh` and `upstream-drift.sh` dropped per scope refinement. |
| 1.2 | pending | Add runtime-agnostic helpers to arkit | | `new-project-skill.sh`, `plan-issue-adapter`. |
| 1.3 | pending | Add Claude command surface to arkit | | `new-project-skill.md`, `memory-clean.md`. `/doctor` dropped. |
| 1.4 | pending | Wire link-map entries | | New `symlinked-file` entries only; no `recursive: true` needed. |
| 2.1 | pending | Live install onto `~/.claude/` | | `agent-runtime install --product claude --apply`. |
| 2.2 | pending | Smoke-test migrated surfaces | | `--help` smoke for each migrated entry. |
| 3.1 | pending | Drop duplicated dispatchers and slash commands | | Plan-level decision: `plugin:meta:*` skills replace them. |
| 3.2 | pending | Drop claude-kit-only infrastructure | | scripts/ci/, install wiring, pre-commit hook, plus dropped `doctor.sh`/`upstream-drift.sh`/`drift-baseline.json`. |
| 3.3 | pending | Record archive marker on claude-kit | | `MOVED.md` should link the tracking issue. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-plan.md --explain` | pending | Run before committing. |
| `agent-runtime install --product claude --dry-run` | pending | Runs after Sprint 1. |
| `agent-runtime audit-drift` | pending | Runs after Sprint 1. |
| `bash $HOME/.claude/scripts/doctor.sh` | pending | Runs after Sprint 2 cutover. |
| `bash $HOME/.claude/scripts/upstream-drift.sh` | pending | Runs after Sprint 2 cutover. |

## Closeout Gate

- Close condition: `~/.claude/scripts/` and `~/.claude/commands/` resolve
  entirely through `agent-runtime-kit/targets/claude/`; the six dispatcher
  files plus claude-kit-only infrastructure are removed from claude-kit;
  `doctor`, `upstream-drift`, `new-project-skill`, and `memory-clean` all
  succeed against the arkit-managed install.
- Reopen triggers: any new file added to `~/.claude/scripts/` or
  `~/.claude/commands/` resolves into claude-kit instead of arkit; any
  `plugin:meta:*` skill loses dispatch parity with the dropped slash
  commands.
