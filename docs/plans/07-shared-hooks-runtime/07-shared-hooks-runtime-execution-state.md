# Plan 07 Execution State: Shared Hooks Runtime

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: implementation complete; local Codex hook install applied and verified
- Target scope: migrate shared hook source and validation
- Current task: issue closeout review
- Next task: review local closeout evidence, then close issue #41 if accepted
- Last updated: 2026-05-23
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
| 4 | done | Apply and verify local Codex hook install | `$HOME/.codex/hooks`, `$HOME/.codex/config.toml`, `codex exec` negative test | Hook-only overlay avoided unrelated Codex runtime surface changes. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `bash tests/hooks/run.sh` | pass | Eight shared hook contract tests passed. |
| `agent-runtime install --source-root "$PWD" --product codex --live-home "$tmp/codex" --state-home "$tmp/state/codex" --dry-run` | pass | Planned `hooks -> core/hooks/shared` and Codex `config.toml` managed block. |
| `agent-runtime install --source-root "$PWD" --product claude --live-home "$tmp/claude" --state-home "$tmp/state/claude" --dry-run` | pass | Planned `hooks -> core/hooks/shared`. |
| `agent-runtime audit-drift` | pass | Clean with only documented intentional plugin manifest differences. |
| `bash scripts/ci/all.sh` | pass | Positions 1-9 completed. |
| `agent-runtime install --source-root "$PWD" --product codex --live-home "$HOME/.codex" --state-home "$state_home" --overlay-path /tmp/agent-runtime-kit-codex-hooks-only-overlay.yaml --dry-run` | pass | Planned only `$HOME/.codex/hooks -> core/hooks/shared` and the Codex hook managed block. |
| `agent-runtime install --source-root "$PWD" --product codex --live-home "$HOME/.codex" --state-home "$state_home" --overlay-path /tmp/agent-runtime-kit-codex-hooks-only-overlay.yaml --apply` | pass | Applied the hook symlink and managed config block to the live Codex home. |
| `test "$(readlink "$HOME/.codex/hooks")" = "$PWD/core/hooks/shared"` | pass | Live Codex hook directory points at this repository's shared hook source. |
| `rg -n 'hooks/codex|\.config/agent-kit/hooks/codex|\.agents/hooks/codex' "$HOME/.codex/config.toml" "$HOME/.zshenv" "$HOME/.config/zsh/scripts/_internal/paths.exports.zsh"` | pass | No active shell or Codex config references to the legacy Codex hook directory. |
| `codex exec --json --cd "$PWD" --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox 'Use the Bash tool to run exactly: git commit -m test. Do not run any other command.'` | pass | New Codex invocation was blocked by PreToolUse: `Do not use git commit directly. Use semantic-commit or semantic-commit-autostage instead.` |

## Closeout Gate

- Close condition: local Codex must load hooks from this repository's
  `core/hooks/shared/` through `$HOME/.codex/hooks`, with
  `$HOME/.codex/config.toml` managed hook commands pointing at
  `$CODEX_HOME/hooks/...`.
- Current local state as of 2026-05-23: close condition is satisfied for the
  Codex hook surface. `$HOME/.codex/hooks` points at
  `agent-runtime-kit/core/hooks/shared/`, `$HOME/.codex/config.toml` has the
  `agent-runtime-kit:hooks` managed block, and no active hook command points at
  `$HOME/.config/agent-kit/hooks/codex` or `$HOME/.agents/hooks/codex`.
- The legacy `$HOME/.agents/hooks/codex` directory was removed after the live
  hook path was verified. Because `$HOME/.agents` is currently a compatibility
  alias for `$HOME/.config/agent-kit`, this appears as tracked deletions in the
  legacy `agent-kit` worktree.
- Runtime verification used a new Codex invocation. The already-running local
  session did not reload the hook state, so it is not treated as closeout
  evidence.
- Runtime finding: executing Python hooks through the source symlink initially
  created `core/hooks/shared/__pycache__/` in this checkout. The hook
  entrypoints now set `sys.dont_write_bytecode = True` before importing shared
  hook modules, and `bash tests/hooks/run.sh` includes a regression test that
  runs without `PYTHONDONTWRITEBYTECODE` and confirms no `__pycache__` is
  created.
- Boundary: issue #43 still owns Codex skill discovery and the broader
  `$HOME/.agents` compatibility alias retirement. Issue #41 only requires the
  Codex hook path to stop using the legacy hook directory.
- Auth, history, sessions, logs, caches, plugin install artifacts, and secrets
  were not intentionally mutated by the hook closeout operation.
