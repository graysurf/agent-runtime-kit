# Plan: Bootstrap Hardening

## Overview

Harden first-time and clean-reinstall bootstrap for `agent-runtime-kit`,
`zsh-kit`, and `nils-cli` after a fresh macOS install exposed three classes of
problems:

- `agent-runtime-kit` setup can install runtime surfaces before rendering build
  output.
- home prompt/docs wiring can be absent even when skill-surface doctor passes.
- `zsh-kit` tool installation can fail after `coreutils` changes the PATH/env
  behavior.

The plan follows the agreed sequence: fix the known script-level failures first,
then introduce a unified host bootstrap command, and fold durable CLI
diagnostics into `nils-cli`.

## Read First

- Primary source:
  `docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Runtime-kit anchors:
  - `scripts/setup.sh`
  - `scripts/sync-runtime-surfaces.sh`
  - `AGENT_HOME.md`
  - `AGENT_DOCS.toml`
  - `SUPPORT_MATRIX.md`
  - `docs/source/docs-placement-retention-policy-v1.md`
  - `docs/source/nils-cli-surface.md`
- zsh-kit anchors:
  - `$HOME/.config/zsh/install-tools.zsh`
  - `$HOME/.config/zsh/bootstrap/install-tools.zsh`
  - `$HOME/.config/zsh/scripts/_internal/paths.exports.zsh`
- nils-cli anchors:
  - `agent-runtime render`
  - `agent-runtime install`
  - `agent-runtime doctor`
  - future `agent-runtime bootstrap-host`
- Open questions carried into execution: none

## Scope

In scope:

- Open an L2 plan-tracking issue from this bundle.
- Create child issues for each independently executable hardening item.
- Update `agent-runtime-kit` first-time setup so rendered output exists before
  install.
- Include home prompt and docs-home wiring in setup verification.
- Harden the `zsh-kit` install-tools wrapper against GNU `env` / PATH changes.
- Improve `nils-cli` missing render output diagnostics.
- Design a unified host bootstrap command with dry-run/apply/resume/report
  behavior.
- Define a machine-readable final report and checkpoint state.

Out of scope:

- Managing Codex or Claude authentication, sessions, tokens, API keys, private
  keys, browser data, or Keychain entries.
- Deleting or replacing all of `$HOME/.codex` or `$HOME/.claude`.
- Replacing Homebrew or supporting every package manager in the first pass.
- Rewriting unrelated shell startup or skill content.

## Assumptions

1. GitHub is the provider for the runtime-kit tracking issue, so both
   `workflow::plan` and `workflow::tracking` labels can be applied.
2. `nils-cli` remains the durable owner for cross-platform runtime mechanics,
   structured errors, render/install/doctor behavior, and any future unified
   bootstrap command.
3. `agent-runtime-kit` can keep compatibility shell scripts, but they should
   delegate to shared helpers or `nils-cli` once the new command is stable.
4. `zsh-kit` remains the owner of shell setup and shell tool installation.

## Sprint 1: Plan Tracking And Issue Setup

**Goal**: Open the umbrella tracker and child issues so future implementation
can start without rediscovering scope.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 1.1: Open the plan tracker and child issues

- **Location**:
  - `docs/plans/2026-06-05-bootstrap-hardening/`
- **Description**: Validate this bundle, open the provider-backed tracking
  issue, initialize local run state, and create the scoped child issues listed
  in this plan.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - Plan bundle has source, plan, and execution-state files.
  - `plan-tooling validate --file <plan> --format text --explain` passes.
  - Provider tracker contains source, plan, and initial state lifecycle
    comments.
  - Local run state is initialized.
  - Child issues exist and link back to the tracker and source bundle.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md --format text --explain`
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened tracker.

## Sprint 2: Known Script-Level Fixes

**Goal**: Fix the already observed bootstrap failures before building a larger
unified command.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 2.1: Render before install in first-time runtime-kit setup

- **Location**:
  - `scripts/setup.sh`
  - `scripts/sync-runtime-surfaces.sh`
- **Description**: Ensure first-time setup renders Codex and Claude outputs
  before calling `agent-runtime install`, preferably by sharing or delegating to
  the existing sync flow.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Fresh setup succeeds without a pre-existing `build/` directory.
  - Dry-run prints render steps before install steps.
  - Regression coverage fails if setup can install before render.
- **Validation**:
  - `bash scripts/setup.sh --profile core --skip-homebrew-install --dry-run`
  - `rm -rf build && bash scripts/setup.sh --profile core --skip-homebrew-install`
  - `agent-runtime doctor --source-root "$PWD" --product codex --class skill-surface --format json`
  - `agent-runtime doctor --source-root "$PWD" --product claude --class skill-surface --format json`

### Task 2.2: Include home prompt and docs wiring in setup verification

- **Location**:
  - `scripts/setup.sh`
  - `targets/codex/link-map.yaml`
  - `targets/claude/link-map.yaml`
  - `AGENT_HOME.md`
  - `agent-docs` or `agent-runtime doctor` if a CLI probe is added
- **Description**: Make setup create or verify the declared home prompt
  symlinks and include `agent-docs audit --target all --strict` or equivalent
  in the final setup gate.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Fresh setup leaves `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` and
    `$HOME/.claude/CLAUDE.md` correctly wired to `AGENT_HOME.md`.
  - Existing unmanaged files are not overwritten without an explicit guarded
    action.
  - Setup final report includes docs/home prompt status.
- **Validation**:
  - `agent-docs audit --target all --strict`
  - `test -L "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"`
  - `test -L "$HOME/.claude/CLAUDE.md"`

### Task 2.3: Harden zsh-kit install-tools wrapper

- **Location**:
  - zsh-kit `install-tools.zsh`
  - zsh-kit `bootstrap/install-tools.zsh`
  - zsh-kit tests
- **Description**: Prevent the user-facing installer from failing when
  Homebrew `coreutils` adds GNU `env`/gnubin behavior to PATH. Invoke the inner
  installer with an explicit zsh executable and keep system directories
  available.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `./install-tools.zsh --yes` succeeds after `coreutils` is newly installed.
  - `./install-tools.zsh --dry-run` remains non-mutating.
  - A regression test covers `coreutils` gnubin first on PATH.
- **Validation**:
  - `PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --dry-run`
  - `PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --yes`
  - `./tools/check.zsh --smoke`

## Sprint 3: nils-cli Diagnostics And Bootstrap Design

**Goal**: Move durable failure handling and bootstrap orchestration into the
CLI layer where it can be reused by scripts and future installers.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 3.1: Improve missing render output errors

- **Location**:
  - `sympoies/nils-cli` `agent-runtime install`
- **Description**: Detect missing `build/<product>` or rendered skill-tree
  roots and return an actionable error naming the render or sync command to
  run.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 2
- **Acceptance criteria**:
  - Missing render output error names product, expected path, and suggested
    remediation.
  - JSON output includes machine-readable product, missing path, and suggested
    command if the command supports JSON errors.
  - Other missing-source errors keep their existing semantics.
- **Validation**:
  - Create a fixture with missing `build/<product>`.
  - `cargo test -p nils-agent-runtime install_missing_render_output_reports_render_command -- --nocapture`

### Task 3.2: Design unified host bootstrap command

- **Location**:
  - `sympoies/nils-cli`
  - `agent-runtime-kit` wrapper scripts
- **Description**: Specify and implement the first skeleton of
  `agent-runtime bootstrap-host` with dry-run/apply, source-root, product,
  profile, skip flags, backup root, and text/json output.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
  - Task 3.1
- **Complexity**: 4
- **Acceptance criteria**:
  - One command can preview and apply the full host bootstrap.
  - The command records phases and can identify completed, failed, and pending
    work on rerun.
  - Legacy setup scripts can call or clearly delegate to the new command.
- **Validation**:
  - `agent-runtime bootstrap-host --source-root "$HOME/.config/agent-runtime-kit" --profile core --product both --dry-run`
  - `agent-runtime bootstrap-host --source-root "$HOME/.config/agent-runtime-kit" --profile core --product both --apply --format json`

### Task 3.3: Add final report and resume checkpoint state

- **Location**:
  - `sympoies/nils-cli`
  - `agent-runtime-kit` state conventions
- **Description**: Define and emit a stable bootstrap report schema that records
  phase status, commands, exit codes, timestamps, backup roots, and verification
  results.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Report is emitted on success and failure.
  - Text summary is useful for non-technical users.
  - JSON report is parseable by automation.
  - Report includes installed versions, docs audit, zsh-kit smoke, Codex
    doctor, Claude doctor, and Codex prompt-input status.
- **Validation**:
  - Simulate a mid-run failure and confirm the report/checkpoint names the
    failed and completed phases.
  - Run a successful bootstrap and validate JSON against the chosen schema.

## Sprint 4: Integration And Deprecation Path

**Goal**: Make the new path the default while keeping old entrypoints safe.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 4.1: Route legacy setup flow through the hardened path

- **Location**:
  - `scripts/setup.sh`
  - `DEVELOPMENT.md`
  - `docs/source/nils-cli-surface.md`
- **Description**: Update runtime-kit setup docs and scripts to use the
  hardened bootstrap path, with a clear fallback for phase-by-phase manual
  setup.
- **Dependencies**:
  - Task 3.2
  - Task 3.3
- **Complexity**: 2
- **Acceptance criteria**:
  - `scripts/setup.sh --dry-run` and `--apply` stay compatible or delegate to
    the new command.
  - Docs point users to the recommended bootstrap path.
  - Manual phase commands remain documented for recovery.
- **Validation**:
  - `bash scripts/setup.sh --profile core --skip-homebrew-install --dry-run`
  - `agent-docs audit --target all --strict`
  - runtime-kit project-dev validation.

## Validation Summary

Before closeout, run:

```bash
agent-docs audit --target all --strict
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product codex --class skill-surface --format json
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product claude --class skill-surface --format json
codex debug prompt-input
```

For zsh-kit:

```bash
cd "$HOME/.config/zsh"
./tests/run.zsh
./tools/check.zsh --smoke
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --dry-run
```

## Closeout Criteria

- All child issues are either complete or explicitly superseded.
- Fresh setup and clean reinstall flows pass dry-run/apply verification.
- The final bootstrap report identifies versions, backup/checkpoint root,
  docs audit, zsh-kit smoke, Codex doctor, Claude doctor, and Codex
  prompt-input status.
- The legacy setup path no longer exposes the missing render-output failure.
