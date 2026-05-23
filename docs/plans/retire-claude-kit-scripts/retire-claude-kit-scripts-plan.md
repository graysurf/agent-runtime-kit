# Plan: Retire claude-kit Scripts

## Overview

Take ownership of the last live install surfaces still resolving through
claude-kit — `~/.claude/scripts/` and `~/.claude/commands/` — and move them
into `agent-runtime-kit`. The migration is additive in arkit first, verified
on the local Claude home, then claude-kit's now-unused wiring is removed.
Anything that is duplicated by `plugin:meta:*` skills is dropped instead of
moved.

## Read First

- Primary source: docs/plans/retire-claude-kit-scripts/retire-claude-kit-scripts-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: long-term home of
  `upstream-drift.sh` (script vs. `agent-runtime` subcommand);
  `memory-snapshot.sh` relevance after a future Claude Code built-in surface.

## Scope

- In scope:
  - New `agent-runtime-kit/targets/claude/scripts/` source directory holding
    `doctor.sh`, `memory-snapshot.sh`, `upstream-drift.sh`, and
    `drift-baseline.json`.
  - New `agent-runtime-kit/targets/claude/commands/` source directory holding
    `doctor.md`, `new-project-skill.md`, and `memory-clean.md`.
  - New runtime-agnostic `agent-runtime-kit/scripts/` entries
    `new-project-skill.sh` and `plan-issue-adapter`.
  - `targets/claude/link-map.yaml` entries that install each new file under
    `~/.claude/scripts/<name>` and `~/.claude/commands/<name>` respectively.
  - Live install verification on the user's `~/.claude/` home.
  - Removal of claude-kit assets that are either duplicated by
    `plugin:meta:*` skills or no longer have any consumer once claude-kit
    stops being referenced.
- Out of scope:
  - Pointing Codex at the new runtime-agnostic helpers (no Codex consumer
    exists today).
  - Deleting the claude-kit checkout or remote repository.
  - Rewriting any migrated script's behavior or interface.
  - Adding new behavior to `plugin:meta:*` skills.

## Sprint 1: arkit takes ownership

**Goal**: Make `agent-runtime-kit` the source of truth for the surviving
scripts and slash commands without yet removing the claude-kit copy.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 1.1: Add Claude-only scripts to arkit

- **Location**:
  - `targets/claude/scripts/doctor.sh`
  - `targets/claude/scripts/memory-snapshot.sh`
  - `targets/claude/scripts/upstream-drift.sh`
  - `targets/claude/scripts/drift-baseline.json`
- **Description**: Copy the three Claude-only operator scripts and the drift
  baseline from claude-kit `scripts/` and `docs/drift-baseline.json` into the
  Claude target. Preserve script behavior, argument parsing, and exit codes
  unchanged. Keep shebang and `set -euo pipefail`. No content rewrite in this
  task.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Each migrated file is byte-equivalent to its claude-kit source aside from
    header comments noting the new location.
  - `bash targets/claude/scripts/doctor.sh --help` works from the arkit
    checkout.
- **Validation**:
  - `bash targets/claude/scripts/doctor.sh --help`
  - `bash targets/claude/scripts/upstream-drift.sh --help`

### Task 1.2: Add runtime-agnostic helpers to arkit

- **Location**:
  - `scripts/new-project-skill.sh`
  - `scripts/plan-issue-adapter`
- **Description**: Move `new-project-skill.sh` and the `plan-issue-adapter`
  binary into a runtime-agnostic `scripts/` directory at the arkit root.
  Do not change adapter argument parsing; `--runtime claude|codex|opencode`
  must keep working. Update any embedded path strings that referenced
  `claude-kit` to use neutral wording.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - `bash scripts/new-project-skill.sh --help` works from the arkit checkout.
  - `scripts/plan-issue-adapter --help` works from the arkit checkout.
  - No string match for `claude-kit` inside either file.
- **Validation**:
  - `bash scripts/new-project-skill.sh --help`
  - `scripts/plan-issue-adapter --help`

### Task 1.3: Add Claude command surface to arkit

- **Location**:
  - `targets/claude/commands/doctor.md`
  - `targets/claude/commands/new-project-skill.md`
  - `targets/claude/commands/memory-clean.md`
- **Description**: Migrate the three slash commands that back surviving
  scripts (or, for `memory-clean`, a surviving skill wrapper). Rewrite the
  embedded shell snippet to call `bash $HOME/.claude/scripts/<name>.sh`
  unchanged — the install destination path is preserved deliberately so
  invocations and muscle memory survive the migration.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Each migrated `.md` keeps its frontmatter `allowed-tools` set and
    `argument-hint` text.
  - Embedded shell snippet still points at `$HOME/.claude/scripts/<name>.sh`.
- **Validation**:
  - `grep -E '\\$HOME/.claude/scripts/' targets/claude/commands/*.md`

### Task 1.4: Wire link-map entries

- **Location**:
  - `targets/claude/link-map.yaml`
- **Description**: Add `symlinked-file` entries that install every file
  added in Tasks 1.1–1.3 into the live Claude home:
  - `targets/claude/scripts/<name>` → `scripts/<name>` (for the three Claude
    operator scripts and `drift-baseline.json`)
  - `scripts/<name>` → `scripts/<name>` (for `new-project-skill.sh` and
    `plan-issue-adapter`)
  - `targets/claude/commands/<name>` → `commands/<name>` (for the three slash
    commands)
- **Dependencies**:
  - Task 1.1, Task 1.2, Task 1.3
- **Acceptance criteria**:
  - `agent-runtime install --product claude --dry-run` plans the new
    symlinks against a temp home.
  - Drift audit against the existing baseline records only the expected new
    entries.
- **Validation**:
  - `agent-runtime install --source-root "$PWD" --product claude --live-home "$tmp/claude" --state-home "$tmp/state/claude" --dry-run`
  - `agent-runtime audit-drift`

## Sprint 2: Cut over the local Claude home

**Goal**: Confirm the local `~/.claude/` install resolves through arkit and
not through claude-kit.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Live install onto `~/.claude/`

- **Location**:
  - `$HOME/.claude/scripts`
  - `$HOME/.claude/commands`
- **Description**: Run `agent-runtime install --product claude --apply`
  against the real Claude home with a scripts-and-commands overlay so the
  install only mutates the two new surfaces. Verify every link points into
  the arkit checkout rather than the claude-kit checkout.
- **Dependencies**:
  - Task 1.4
- **Acceptance criteria**:
  - `readlink "$HOME/.claude/scripts/doctor.sh"` resolves into
    `agent-runtime-kit/targets/claude/scripts/`.
  - `readlink "$HOME/.claude/scripts/new-project-skill.sh"` resolves into
    `agent-runtime-kit/scripts/`.
  - `readlink "$HOME/.claude/commands/doctor.md"` resolves into
    `agent-runtime-kit/targets/claude/commands/`.
  - No live `~/.claude/scripts/*` or `~/.claude/commands/*` entry resolves
    into the claude-kit checkout after the apply step.
- **Validation**:
  - `agent-runtime install --source-root "$PWD" --product claude --live-home "$HOME/.claude" --state-home "$state_home" --overlay-path /tmp/agent-runtime-kit-claude-scripts-commands-overlay.yaml --dry-run`
  - `agent-runtime install --source-root "$PWD" --product claude --live-home "$HOME/.claude" --state-home "$state_home" --overlay-path /tmp/agent-runtime-kit-claude-scripts-commands-overlay.yaml --apply`
  - `find "$HOME/.claude/scripts" "$HOME/.claude/commands" -maxdepth 1 -type l -exec readlink {} \; | grep -v agent-runtime-kit || true`

### Task 2.2: Smoke-test migrated surfaces

- **Location**:
  - live Claude home
- **Description**: Run each migrated script and slash command against the
  installed link to confirm the behavior survived the move. Exercise
  `doctor.sh` in both text and JSON modes, `upstream-drift.sh` against the
  migrated baseline, and `new-project-skill.sh --help`. Use a fresh Claude
  session to drive `/doctor`, `/new-project-skill --help`, and
  `/memory-clean --dry-run` so the slash-command path is exercised end to
  end.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - `bash ~/.claude/scripts/doctor.sh --json` exits zero or warns only.
  - `bash ~/.claude/scripts/upstream-drift.sh` resolves the baseline at the
    arkit-managed path.
  - Slash commands invoked from a fresh Claude session execute the migrated
    script without `command not found`.
- **Validation**:
  - `bash $HOME/.claude/scripts/doctor.sh`
  - `bash $HOME/.claude/scripts/doctor.sh --json`
  - `bash $HOME/.claude/scripts/upstream-drift.sh`

## Sprint 3: Retire claude-kit script wiring

**Goal**: Remove claude-kit assets that are either redundant with
`plugin:meta:*` skills or have no consumer once arkit owns the surface.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 3.1: Drop duplicated dispatchers and slash commands

- **Location**:
  - claude-kit `scripts/bench.sh`, `scripts/bootstrap.sh`,
    `scripts/demo.sh`, `scripts/deploy.sh`, `scripts/release.sh`,
    `scripts/pre-pr.sh`
  - claude-kit `commands/bench.md`, `commands/bootstrap.md`,
    `commands/demo.md`, `commands/deploy.md`, `commands/release.md`,
    `commands/pre-pr.md`
- **Description**: Delete the six dispatcher scripts and their matching
  slash commands from claude-kit. `plugin:meta:<name>` skills already cover
  the dispatch behavior for both Codex and Claude, so no replacement is
  needed.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - The twelve files no longer exist in claude-kit working tree.
  - `~/.claude/commands/` contains no `bench`, `bootstrap`, `demo`,
    `deploy`, `release`, or `pre-pr` entry after the next install run.
- **Validation**:
  - `git -C $HOME/.config/claude status`
  - `ls $HOME/.claude/commands | grep -E '^(bench|bootstrap|demo|deploy|release|pre-pr)\\.md$' || true`

### Task 3.2: Drop claude-kit-only infrastructure

- **Location**:
  - claude-kit `scripts/ci/`
  - claude-kit `scripts/_plugins.env`
  - claude-kit `scripts/_symlinks.env`
  - claude-kit `install.sh`, `uninstall.sh`, `.githooks/pre-commit`
- **Description**: Remove claude-kit's repo-local CI gates, install wiring,
  and pre-commit hook. None of these have a consumer once claude-kit stops
  receiving commits.
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - Each listed file or directory is removed from claude-kit working tree.
  - `~/.claude/` install no longer resolves any path back into claude-kit.
- **Validation**:
  - `find $HOME/.claude -maxdepth 2 -lname '*claude-kit*' -o -lname '*config/claude/*' | grep -v projects | grep -v sessions || true`

### Task 3.3: Record archive marker on claude-kit

- **Location**:
  - claude-kit `README.md`
  - claude-kit `MOVED.md`
- **Description**: Add a single archive marker stating that scripts,
  commands, and install wiring are now owned by
  `graysurf/agent-runtime-kit`. The marker does not delete the repository or
  remote.
- **Dependencies**:
  - Task 3.1, Task 3.2
- **Acceptance criteria**:
  - `MOVED.md` references the migration plan path inside arkit and the
    tracking issue URL.
- **Validation**:
  - `grep -E 'agent-runtime-kit' $HOME/.config/claude/MOVED.md`

## Closeout

- Close condition: `~/.claude/scripts/` and `~/.claude/commands/` resolve
  entirely through `agent-runtime-kit/targets/claude/`, the six dispatcher
  files plus claude-kit-only infrastructure are removed from claude-kit,
  and the local Claude home runs `/doctor`, `/new-project-skill`,
  `/memory-clean`, and `bash ~/.claude/scripts/upstream-drift.sh` without
  touching claude-kit paths.
- Out-of-band follow-ups: deleting the claude-kit repository or remote
  archive, promoting `upstream-drift.sh` to an `agent-runtime` subcommand,
  pointing Codex at the runtime-agnostic helpers.
