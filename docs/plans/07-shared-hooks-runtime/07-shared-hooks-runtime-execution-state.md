# Plan 07 Execution State: Shared Hooks Runtime

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: complete
- Target scope: migrate shared hook source and validation
- Current task: Task 1.3 complete
- Next task: decide whether Claude settings structural merge belongs in nils-cli
- Last updated: 2026-05-22
- Branch: feat/shared-hooks-runtime
- Source document: docs/plans/07-shared-hooks-runtime/07-shared-hooks-runtime-plan.md
- Direct source-doc execution waiver: user explicitly requested implementation
  in a new worktree.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1 | done | Migrate hook source into `core/hooks/shared/` | `core/hooks/shared/` | Shared env names added while preserving legacy agent-kit and claude-kit env names. |
| 2 | done | Add product activation source and link-map entries | `targets/codex/hooks/config.block.toml`, `core/hooks/claude/settings.hooks.jsonc`, product link maps | Claude settings fragment is source-only to avoid whole-file settings replacement. |
| 3 | done | Add and run validation | `tests/hooks/run.sh`, `scripts/ci/all.sh` | Full local gate passed. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `bash tests/hooks/run.sh` | pass | Eight shared hook contract tests passed. |
| `agent-runtime install --source-root "$PWD" --product codex --live-home "$tmp/codex" --state-home "$tmp/state/codex" --dry-run` | pass | Planned `hooks -> core/hooks/shared` and Codex `config.toml` managed block. |
| `agent-runtime install --source-root "$PWD" --product claude --live-home "$tmp/claude" --state-home "$tmp/state/claude" --dry-run` | pass | Planned `hooks -> core/hooks/shared`. |
| `agent-runtime audit-drift` | pass | Clean with only documented intentional plugin manifest differences. |
| `bash scripts/ci/all.sh` | pass | Positions 1-8 completed. |
