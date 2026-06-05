# Bootstrap Hardening Implementation Handoff

Status: ready for issue creation
Date: 2026-06-05
Source: clean reinstall session for `agent-runtime-kit`, `zsh-kit`, and
`nils-cli` on macOS
Intended next step: create one umbrella issue plus scoped implementation issues

## Purpose

Capture the installation problems and hardening opportunities found during a
fresh macOS bootstrap so future implementation can improve first-time setup,
dry-run/apply behavior, failure recovery, and verification across
`agent-runtime-kit`, `zsh-kit`, and `nils-cli`.

The desired end state is a host bootstrap path that a non-technical user can
run safely: it previews mutations, backs up or refuses risky paths, renders
before installing runtime surfaces, verifies home prompt/docs wiring, reports
actionable failures, and can resume cleanly after interruption.

## Confirmed Facts

- `scripts/setup.sh` in `agent-runtime-kit` currently clones or reuses the
  checkout, installs CLI tools, then calls `agent-runtime install` for Claude
  and Codex.
- On a fresh checkout, `build/<product>/...` does not exist until
  `agent-runtime render --product <product>` runs.
- During the observed reinstall, `scripts/setup.sh --profile core
  --skip-homebrew-install` failed at Claude activation because
  `build/claude/plugins/reporting/skills` was missing.
- `scripts/sync-runtime-surfaces.sh` already performs the safer order:
  pull, source count audit, render, install, prune, doctor, and Codex
  `prompt-input`.
- `agent-runtime doctor --class skill-surface` passed after using
  `scripts/sync-runtime-surfaces.sh --apply`.
- `agent-docs audit --target all --strict` initially failed because the home
  prompt symlinks were missing:
  - `$CODEX_HOME/AGENTS.md`
  - `$HOME/.claude/CLAUDE.md`
- Creating those symlinks to `<source-root>/AGENT_HOME.md` made
  `agent-docs audit --target all --strict` pass.
- `zsh-kit` setup succeeded, wrote `~/.zshenv`, and set `ZDOTDIR` to
  `$HOME/.config/zsh`.
- `zsh-kit` optional tool installation through the user-facing
  `install-tools.zsh` wrapper failed after installing Homebrew `coreutils` with
  `env: zsh: No such file or directory`.
- Directly invoking the inner installer with `/bin/zsh -f
  ./bootstrap/install-tools.zsh --yes` completed successfully.
- The optional tools installed successfully afterward:
  `git-delta`, `eza`, `neovim`, `starship`, `tree`, and `zoxide`.

## Decisions

- Fix the known script-level issues first, then build a unified bootstrap
  command.
- Keep dry-run-first behavior as a hard requirement for any command that writes
  runtime homes, shell startup files, or Homebrew-managed tools.
- Treat authentication as user-owned and out of scope for bootstrap automation.
- Do not delete or wholesale replace `$HOME/.codex` or `$HOME/.claude`; only
  manage declared surfaces and home prompt files.
- Prefer one future unified entrypoint, tentatively
  `agent-runtime bootstrap-host`, for the end-to-end host bootstrap.
- Keep legacy scripts as compatibility wrappers or documented fallbacks until
  the unified command is stable.

## Scope

- First-time setup and clean reinstall flows for:
  - `agent-runtime-kit`
  - `zsh-kit`
  - `nils-cli`
- Render/install ordering for Codex and Claude runtime surfaces.
- Home prompt and docs-home wiring checks.
- Homebrew install/upgrade side effects and reporting.
- Machine-readable bootstrap status, final report, and resume checkpoints.
- Actionable error messages for missing rendered build output.
- Validation commands that prove the runtime surfaces are usable after install.

## Non-Scope

- Managing Codex or Claude login state, sessions, tokens, private keys, or API
  keys.
- Deleting whole runtime homes such as `$HOME/.codex` or `$HOME/.claude`.
- Rewriting all shell startup behavior or replacing zsh-kit design.
- Replacing Homebrew itself or supporting every non-Homebrew package manager in
  the first iteration.
- Changing skill content unrelated to bootstrap/install behavior.

## Findings

| Priority | Issue | Evidence | Likely fix location | Acceptance criteria |
| --- | --- | --- | --- | --- |
| P0 | First-time `setup.sh` installs before rendering | Fresh checkout failed on missing `build/claude/plugins/reporting/skills` | `scripts/setup.sh`, possibly `scripts/sync-runtime-surfaces.sh` reuse | Fresh setup renders Codex and Claude before install; no missing build path error |
| P0 | `agent-runtime install` reports missing rendered paths without actionable remediation | Error surfaced a low-level missing source path | `nils-cli` `agent-runtime install` | Missing build output error says which render or sync command to run |
| P1 | Home prompt/docs wiring is not part of setup verification | `agent-docs audit --strict` failed until `$CODEX_HOME/AGENTS.md` and `$HOME/.claude/CLAUDE.md` were created | link maps, `agent-runtime install`, `agent-docs`, setup verification | Setup creates or verifies declared home prompt symlinks without overwriting unrelated files |
| P1 | Setup verification can pass skill surfaces while docs-home wiring fails | `agent-runtime doctor --class skill-surface` passed; `agent-docs audit` failed | `scripts/setup.sh`, `agent-runtime doctor`, `agent-docs` | End-to-end setup report includes both skill surface and docs/home prompt checks |
| P1 | `zsh-kit` tool installer wrapper is sensitive to GNU `env` / PATH changes after `coreutils` install | Wrapper failed with `env: zsh: No such file or directory`; inner `/bin/zsh -f` invocation passed | `zsh-kit/install-tools.zsh` | User-facing installer works after `coreutils` is newly installed and PATH includes gnubin |
| P2 | Homebrew side effects are not summarized clearly enough for non-technical users | Setup upgraded existing tools and Homebrew performed auto-update/cleanup | `scripts/setup.sh`, future bootstrap command | Dry-run and final report distinguish install, upgrade, cleanup, and skipped tools |
| P2 | Bootstrap has no durable resume/checkpoint state | Mid-run failure left partial progress but no single status artifact | future `agent-runtime bootstrap-host`, state-home conventions | Interrupted bootstrap can report completed, failed, and pending steps on rerun |
| P2 | Version alignment is not part of the first-time setup gate | nils-cli version was manually checked after install | `agent-runtime doctor --class version-alignment`, setup verification | Setup verifies host `nils-cli` against repo pin/manifest before final success |

## Recommended Issue Breakdown

### Umbrella Issue

Title: Bootstrap hardening: render-first setup, zsh installer resilience, and
unified host bootstrap

Purpose:

- Track the cross-repository work needed to make first-time host bootstrap safe,
  resumable, and verifiable.
- Link this document as the read-first source.
- Track completion of the child issues below.

Acceptance criteria:

- A fresh macOS setup can run dry-run then apply without manual workaround.
- Final report includes install status, backup/checkpoint location, tool
  versions, docs audit, zsh-kit smoke, Codex doctor, Claude doctor, and Codex
  prompt-input status.
- Known failure modes produce actionable remediation commands.

### Child Issue 1: Render Before Install In First-Time Setup

Repository: `agent-runtime-kit`

Problem:

- `scripts/setup.sh` can call `agent-runtime install` before rendered build
  output exists.

Scope:

- Make first-time setup render Codex and Claude outputs before install.
- Prefer reusing `scripts/sync-runtime-surfaces.sh` behavior or shared helpers
  so setup and sync do not drift.

Acceptance criteria:

- Fresh clone setup succeeds without pre-existing `build/`.
- Dry-run prints render steps before install steps.
- Apply runs `agent-runtime render --product codex` and
  `agent-runtime render --product claude` before install.
- Regression test covers a missing `build/` directory.

Validation:

```bash
bash scripts/setup.sh --profile core --skip-homebrew-install --dry-run
rm -rf build
bash scripts/setup.sh --profile core --skip-homebrew-install
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product codex --class skill-surface --format json
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product claude --class skill-surface --format json
```

### Child Issue 2: Include Home Prompt And Docs Wiring In Setup Verification

Repository: `agent-runtime-kit` and possibly `nils-cli`

Problem:

- Skill surface doctor can pass while `agent-docs audit --strict` fails because
  home prompt symlinks are missing.

Scope:

- Ensure `$CODEX_HOME/AGENTS.md` and `$HOME/.claude/CLAUDE.md` are created or
  verified according to declared surfaces.
- Add `agent-docs audit --target all --strict` to setup verification or add an
  equivalent `doctor` class.
- Refuse to overwrite existing non-managed files unless the caller explicitly
  opts in through a guarded backup/replace flow.

Acceptance criteria:

- Fresh setup results in passing `agent-docs audit --target all --strict`.
- Existing real files at those paths are not overwritten without an explicit
  guarded action.
- Final setup report clearly lists home prompt status.

Validation:

```bash
agent-docs audit --target all --strict
test -L "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
test -L "$HOME/.claude/CLAUDE.md"
```

### Child Issue 3: Harden zsh-kit Install-Tools Wrapper Against GNU env/PATH

Repository: `zsh-kit`

Problem:

- The user-facing `install-tools.zsh` wrapper can fail after installing
  `coreutils` because the shebang-based `exec "$bootstrap_script"` resolves
  through `env zsh` in an altered PATH.

Scope:

- Make the wrapper invoke the inner installer with an explicit zsh executable,
  preferably the current shell's zsh or `/bin/zsh`.
- Ensure PATH includes system directories after Homebrew/coreutils path
  manipulation.
- Add a regression test where `coreutils` gnubin is first on PATH.

Acceptance criteria:

- `./install-tools.zsh --yes` succeeds when `coreutils` was just installed.
- `./install-tools.zsh --dry-run` remains non-mutating.
- The wrapper does not require the caller to know about
  `bootstrap/install-tools.zsh`.

Validation:

```bash
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --dry-run
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --yes
./tools/check.zsh --smoke
```

### Child Issue 4: Improve Missing Render Output Errors

Repository: `nils-cli`

Problem:

- `agent-runtime install` reports missing source paths, but does not explain
  that rendered output is missing or how to generate it.

Scope:

- Detect when `build/<product>` or specific rendered skill-tree roots are
  missing.
- Return a concise error that names the product and suggests the exact render
  or sync command.
- Consider adding a structured error code for bootstrap tooling.

Acceptance criteria:

- Missing build output produces an actionable message.
- JSON output, if applicable, includes product, missing path, and suggested
  remediation.
- Existing install behavior for other missing source errors remains intact.

Example message:

```text
agent-runtime install: rendered output is missing for product=claude.
Expected: build/claude/plugins/reporting/skills
Run: agent-runtime render --source-root <root> --product claude
Or:  bash scripts/sync-runtime-surfaces.sh --source-root <root> --apply
```

### Child Issue 5: Design Unified Host Bootstrap Command

Repository: `nils-cli`, with consumers in `agent-runtime-kit` and `zsh-kit`

Problem:

- Bootstrap is split across shell scripts and CLI subcommands, making dry-run,
  resume, status reporting, and error handling inconsistent.

Scope:

- Design and implement `agent-runtime bootstrap-host` or an equivalent command.
- Support at least:
  - `--dry-run`
  - `--apply`
  - `--profile core|recommended|full`
  - `--source-root`
  - `--backup-root`
  - `--skip-homebrew-install`
  - `--skip-cli-tools`
  - `--product codex|claude|both`
  - `--format text|json`
- Produce a checkpoint file under the agent-runtime-kit state home.
- Keep authentication out of scope.

Acceptance criteria:

- One command can preview and apply the full host bootstrap.
- The command writes a machine-readable status/checkpoint record.
- A rerun after failure can identify completed, failed, and pending steps.
- Legacy setup scripts can call the command or clearly delegate to it.

Suggested phases:

1. Preflight host and source-root.
2. Prepare backup/checkpoint root.
3. Install or verify Homebrew/nils-cli.
4. Install or verify CLI profile tools.
5. Render product surfaces.
6. Install product surfaces.
7. Prune stale managed surfaces.
8. Verify skill surfaces.
9. Verify home prompt/docs wiring.
10. Verify zsh-kit shell setup if requested.
11. Print final report.

### Child Issue 6: Add Final Report And Resume State

Repository: `nils-cli` and `agent-runtime-kit`

Problem:

- Human-readable logs are not enough to diagnose partial bootstrap completion.

Scope:

- Define a stable report schema, for example
  `agent-runtime.bootstrap-report.v1`.
- Record each phase with status, command, exit code, started/ended timestamps,
  and concise evidence.
- Print a text summary for non-technical users and a JSON report for tools.

Acceptance criteria:

- Final report includes:
  - Installed: yes/no
  - Backup/checkpoint folder
  - `agent-runtime` version
  - `zsh-kit` version
  - `agent-docs audit` status
  - zsh-kit smoke status
  - Codex doctor status
  - Claude doctor status
  - Codex prompt-input status
  - skipped optional steps
- Report is available even when bootstrap fails midway.

## Implementation Boundaries

- `agent-runtime-kit` should remain the source repository for skills, manifests,
  targets, and human-oriented setup docs.
- `nils-cli` should own durable cross-platform runtime mechanics, structured
  errors, `doctor`, `render`, `install`, and future unified bootstrap behavior.
- `zsh-kit` should own shell setup and shell tool installation behavior.
- `agent-runtime-kit` scripts may wrap or orchestrate, but should avoid
  duplicating durable CLI logic once `nils-cli` exposes it.

## Requirements

- Every mutating bootstrap command must have a dry-run mode.
- Dry-run output must include render/install ordering and planned Homebrew
  actions.
- Mutating commands must avoid deleting user data and must not overwrite
  unmanaged files without explicit guarded approval.
- Missing rendered output must be detected before low-level path errors are
  shown to the user.
- Setup verification must include both runtime skill surfaces and home
  prompt/docs wiring.
- zsh-kit tool installation must be robust when Homebrew `coreutils` gnubin is
  first on PATH.
- Final status must be understandable by a non-technical user and parseable by
  automation.

## Acceptance Criteria

- A clean macOS host can run:

```bash
bash scripts/setup.sh --profile core --skip-homebrew-install --dry-run
bash scripts/setup.sh --profile core --skip-homebrew-install
```

  without a missing `build/<product>` failure.

- After setup, these pass:

```bash
agent-docs audit --target all --strict
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product codex --class skill-surface --format json
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product claude --class skill-surface --format json
codex debug prompt-input
```

- zsh-kit install tools passes in the coreutils/GNU env path scenario:

```bash
cd "$HOME/.config/zsh"
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --dry-run
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --yes
./tools/check.zsh --smoke
```

- A future unified bootstrap command produces a text and JSON report that can be
  used to open or update a tracking issue.

## Validation Plan

For `agent-runtime-kit` changes:

```bash
bash scripts/sync-runtime-surfaces.sh --source-root "$PWD"
bash scripts/sync-runtime-surfaces.sh --source-root "$PWD" --apply
agent-docs audit --target all --strict
```

For `nils-cli` changes:

```bash
agent-runtime render --source-root "$HOME/.config/agent-runtime-kit" --product codex
agent-runtime render --source-root "$HOME/.config/agent-runtime-kit" --product claude
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product codex --class skill-surface --format json
agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product claude --class skill-surface --format json
```

For `zsh-kit` changes:

```bash
cd "$HOME/.config/zsh"
./tests/run.zsh
./tools/check.zsh --smoke
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin" ./install-tools.zsh --dry-run
```

## Risks And Guardrails

- Do not make the unified bootstrap command silently own all of
  `$HOME/.codex` or `$HOME/.claude`; it should own only declared surfaces.
- Do not hide Homebrew upgrades in a vague "setup complete" message; report
  upgrades separately from fresh installs.
- Do not make `--render-if-missing` the only fix for missing builds; users
  still need clear diagnostics when source manifests are genuinely wrong.
- Keep the old scripts usable until the unified command has proven stable in at
  least one clean install and one reinstall scenario.
- Preserve a manual escape hatch for users who want to run setup phases one by
  one.

## Retention Intent

This is a coordination document. It is cleanup-eligible after the hardening work
ships or is abandoned. Promote relevant sections into `DEVELOPMENT.md`,
`docs/source/`, or command help text only if they become durable setup policy.

## Read-First References

- `scripts/setup.sh`
- `scripts/sync-runtime-surfaces.sh`
- `AGENT_HOME.md`
- `AGENT_DOCS.toml`
- `SUPPORT_MATRIX.md`
- `docs/source/docs-placement-retention-policy-v1.md`
- `docs/source/nils-cli-surface.md`
- zsh-kit `install-tools.zsh`
- zsh-kit `bootstrap/install-tools.zsh`

## Recommended Next Artifact

Create the umbrella issue first, then create the six child issues listed above.
Each issue should link this document and copy only the relevant problem,
scope, acceptance criteria, and validation commands.

## Execution

- Recommended plan: docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md
- Recommended execution state: docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-execution-state.md
