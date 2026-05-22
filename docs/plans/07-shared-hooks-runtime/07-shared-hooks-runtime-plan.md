# Plan: Shared Hooks Runtime

## Overview

Move duplicated agent-kit and claude-kit hook behavior into
`agent-runtime-kit` with one shared source directory for common behavior and
thin product activation files for Codex and Claude.

## Read First

- Primary source: docs/plans/07-shared-hooks-runtime/07-shared-hooks-runtime-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: whether Claude settings structural
  merge belongs in nils-cli; default is to keep a source fragment and avoid
  whole-file settings replacement.

## Scope

- In scope:
  - Shared hook scripts under `core/hooks/shared/`.
  - Codex hook activation source under `targets/codex/hooks/` and Claude hook
    settings source under `core/hooks/claude/`.
  - Product link-map entries for shared hook script installation.
  - Codex managed hook block activation through `targets/codex/link-map.yaml`.
  - Deterministic hook contract tests and CI wiring.
- Out of scope:
  - Live runtime home mutation.
  - Whole-file Claude `settings.json` replacement.
  - New nils-cli JSON merge behavior.

## Sprint 1: Shared Hook Migration

**Goal**: Land the shared hook source layout, product activation artifacts, and
local validation in one implementation slice.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Migrate shared hook source

- **Location**:
  - `core/hooks/`
- **Description**: Add `core/hooks/shared/` as the canonical source for hook
  logic shared by Codex and Claude. Preserve legacy agent-kit and claude-kit
  environment variables while adding neutral `AGENT_RUNTIME_*` names.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Shared hook source includes the migrated hook scripts and skill-usage
    reminder catalog.
  - Shared PR and Python hooks accept both neutral and legacy migration env
    variables.
- **Validation**:
  - `bash tests/hooks/run.sh`

### Task 1.2: Add product activation artifacts

- **Location**:
  - `targets/codex/hooks/`
  - `core/hooks/claude/`
  - `targets/codex/link-map.yaml`
  - `targets/claude/link-map.yaml`
- **Description**: Add product-specific activation source that points Codex and
  Claude at the same installed shared hook script names. Wire Codex through a
  managed `config.toml` block and keep Claude as a settings hook fragment next
  to hook source to avoid replacing a user-owned settings file.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - Codex install planning includes shared hook script symlinks and a managed
    `config.toml` hook block.
  - Claude install planning includes shared hook script symlinks.
  - Claude settings hook source exists as a fragment rather than a whole
    settings replacement.
- **Validation**:
  - `agent-runtime install --source-root "$PWD" --product codex --live-home "$tmp/codex" --state-home "$tmp/state/codex" --dry-run`
  - `agent-runtime install --source-root "$PWD" --product claude --live-home "$tmp/claude" --state-home "$tmp/state/claude" --dry-run`

### Task 1.3: Wire hook validation into CI

- **Location**:
  - `tests/hooks/`
  - `scripts/ci/all.sh`
- **Description**: Add deterministic hook contract tests covering the migrated
  guardrails and make them part of the repository CI entrypoint.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Acceptance criteria**:
  - Hook contract tests cover commit, semantic-commit body, Python, PR/MR,
    project-memory, MCP secret, portable path, and skill-usage reminders.
  - `scripts/ci/all.sh` runs the hook smoke after runtime skill smoke.
- **Validation**:
  - `bash tests/hooks/run.sh`
  - `bash scripts/ci/all.sh`

## Issue Closeout Gate

Issue #41 is ready for closeout only after the merged hook source is installed
into the local Codex live home. The closeout step must be dry-run-first and
then, only after explicit approval, apply the Codex install so:

- `$HOME/.codex/hooks` points at `core/hooks/shared/` from this checkout.
- `$HOME/.codex/config.toml` references `$CODEX_HOME/hooks/...` commands from
  the managed hook block.
- Legacy `$HOME/.config/agent-kit/hooks/codex/...` commands are no longer the
  active Codex hook paths.
- Auth, history, sessions, logs, caches, plugin install artifacts, and other
  runtime state are not modified.
- A fresh Codex invocation proves at least one installed hook actually runs.
- Issue #43 remains the owner for Codex skill discovery and broader
  `$HOME/.agents` compatibility alias retirement.

Validation:

- `state_home="${CODEX_AGENT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/codex}" && agent-runtime install --source-root "$PWD" --product codex --live-home "$HOME/.codex" --state-home "$state_home" --dry-run`
- After explicit approval only:
  `state_home="${CODEX_AGENT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/codex}" && agent-runtime install --source-root "$PWD" --product codex --live-home "$HOME/.codex" --state-home "$state_home" --apply`
- `test "$(readlink "$HOME/.codex/hooks")" = "$PWD/core/hooks/shared"`
- `rg -n 'command = ".*\\.config/agent-kit/hooks/codex' "$HOME/.codex/config.toml"` returns no matches.
- `rg -n 'AGENT_RUNTIME_PRODUCT=codex.*\\$CODEX_HOME/hooks' "$HOME/.codex/config.toml"` shows the managed hook commands.
- `codex exec --json --cd "$PWD" --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox 'Use the Bash tool to run exactly: git commit -m test. Do not run any other command.'` is blocked by the direct-commit PreToolUse hook.

Current outcome as of 2026-05-23:

- The local closeout gate has been applied and verified with a hook-only overlay
  to avoid unrelated Codex runtime surface changes.
- `$HOME/.codex/hooks` points at this checkout's `core/hooks/shared/`.
- `$HOME/.codex/config.toml` contains the `agent-runtime-kit:hooks` managed
  block and no active legacy Codex hook commands.
- `$HOME/.agents/hooks/codex` has been removed after verification. The broader
  `$HOME/.agents` compatibility alias is intentionally left to issue #43.
- Python hook bytecode generation through the live source symlink is suppressed
  in the hook entrypoints and covered by `bash tests/hooks/run.sh`.
