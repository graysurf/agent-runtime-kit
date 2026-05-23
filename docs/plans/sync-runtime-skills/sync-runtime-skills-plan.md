# Plan: sync-runtime-skills Refresh Entrypoint

## Overview

Land `scripts/sync-runtime-skills.sh` as the daily-use entrypoint for
refreshing the active `agent-runtime-kit` checkout into both Codex and
Claude runtime homes. The script pulls the source checkout, renders both
product targets, installs both runtime homes, and verifies skill
discovery / runtime shape — the workflow a skill author needs after
merging a new skill but before their next session sees it. The current
gap is that `scripts/setup.sh` covers a broader bootstrap path
(Homebrew, nils-cli formula, cli-tools profile) and does not serve as a
focused "refresh my runtime skills" command.

This plan delivers the shell script first and a thin `DEVELOPMENT.md`
cross-reference. A `meta:sync-runtime-skills` skill wrapper is
explicitly deferred until the script has been exercised against at
least one real skill-add cycle and the user accepts the workflow shape.

## Read First

- Primary source: docs/plans/sync-runtime-skills/sync-runtime-skills-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - [Q1] Overlay handling: defer to `agent-runtime install` overlay
    flag default (do not touch `.private/link-map.overrides.yaml`
    from the script).
  - [Q2] Whether `--apply` should auto-run `agent-runtime audit-drift`
    (default in this plan: **no**; leave drift to CI to keep the
    daily loop short).
  - [Q4] Whether the script logs a one-line summary at the end
    (default in this plan: **yes**, one summary line for greppability).

## Scope

- In scope:
  - New `scripts/sync-runtime-skills.sh` that wraps
    `git pull --ff-only` → `agent-runtime render` →
    `agent-runtime install --apply` → `agent-runtime doctor --class
    skill-surface` → optional `codex debug prompt-input` for both
    products.
  - Flags: `--apply`, `--product <codex|claude|both>` (default
    `both`), `--no-pull`, `--no-verify`, `-h|--help`.
  - Dry-run by default; `--apply` performs writes.
  - Reuses the `log` / `err` / `run_cmd` / `print_cmd` helper shape
    from `scripts/setup.sh`; either by direct copy or by factoring
    a shared helper file (execution-side judgement).
  - `DEVELOPMENT.md` cross-reference pointing skill authors at the
    new entrypoint for daily refreshes.
  - `scripts/setup.sh --help` gains a one-line pointer to the new
    script.
- Out of scope:
  - A `meta:sync-runtime-skills` skill wrapper (defer per source
    [D1]).
  - Changes to `agent-runtime install`, `render`, or `doctor`
    surfaces.
  - Auto-bumping nils-cli or other third-party CLIs.
  - A new CI position that asserts daily-refresh behaviour
    (existing `runtime-smoke` / `skill-surface` doctor / `audit-drift`
    positions cover this).
  - Touching `manifests/skills.yaml` (no skill entry until a wrapper
    lands).

## Assumptions

1. `agent-runtime install --product <p> --dry-run` is idempotent and
   safe to run in default mode without `--apply`.
2. `agent-runtime render --product <p>` is idempotent and rewrites
   `build/<product>/` from the current `core/` + `targets/<product>/`
   contents.
3. `agent-runtime doctor --product <p> --class skill-surface`
   returns non-zero (or `block>0` in the JSON envelope) only when a
   real skill-surface defect is present.
4. macOS bash 3.2 + `grep` + `sed` is sufficient; no Python or new
   nils-cli surface needed.
5. `manifests/runtime-roots.yaml` continues to be the canonical
   source of `live_home` / `state_home` per product, matching the
   resolution `scripts/setup.sh` uses today.

## Sprint 1: Ship sync-runtime-skills.sh and Doc Pointers

**Goal**: Land the script with dry-run-first behaviour, both-product
default, post-install doctor verification, and a `DEVELOPMENT.md`
cross-reference; prove pass and failure modes with worktree
experiments.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add scripts/sync-runtime-skills.sh

- **Location**:
  - `scripts/sync-runtime-skills.sh`
- **Description**: Create the new shell script with the helper shape
  used in `scripts/setup.sh` (`log`, `err`, `run_cmd`, `print_cmd`,
  `DRY_RUN` gating). Implement argument parsing for `--apply`,
  `--product`, `--no-pull`, `--no-verify`, and `-h|--help`. Resolve
  the source root via `git rev-parse --show-toplevel` (override with
  `--source-root` if supplied). Run `git pull --ff-only` unless
  `--no-pull` is passed, stopping on any git failure. For each
  selected product, call
  `agent-runtime render --source-root <root> --product <p>`, then
  `agent-runtime install --source-root <root> --product <p>
  --live-home <live> --state-home <state>
  [--apply|--dry-run]`. After install, when not in `--no-verify`
  mode, call
  `agent-runtime doctor --source-root <root> --product <p>
  --class skill-surface` and aggregate the highest exit code as the
  script's exit code. If `command -v codex` returns 0, also run
  `codex debug prompt-input` and surface its output. Emit a one-line
  trailing summary
  ("synced skills for codex+claude; doctor=ok; codex prompt-input
  verified") so daily output is greppable.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Default `bash scripts/sync-runtime-skills.sh` runs in dry-run
    mode, prints planned commands for both products, and exits 0
    without mutating runtime homes.
  - `bash scripts/sync-runtime-skills.sh --apply` runs end-to-end
    on an aligned host and reports `block=0` for both products.
  - `--product <claude|codex>` limits the run to that product
    only.
  - `--no-pull` skips `git pull --ff-only` and continues against
    the current checkout.
  - `--no-verify` skips the doctor + codex probes (used only for
    fast iteration).
  - Script follows bash 3.2 rules: no associative arrays, no
    `mapfile`, no `${var,,}`; `shellcheck` and `shfmt` clean.
  - One-line trailing summary present in both dry-run and apply
    modes.
- **Validation**:
  - `bash scripts/sync-runtime-skills.sh` on an aligned host (expect
    pass, no writes).
  - `bash scripts/sync-runtime-skills.sh --apply` on the same host
    (expect both `install --apply` and both
    `doctor --class skill-surface` to succeed).
  - Deliberate-failure experiment: perturb a rendered file under
    `build/claude/`, run `bash scripts/sync-runtime-skills.sh
    --apply --product claude`, expect the post-install doctor to
    fail and the script to exit non-zero; restore the file.
  - Pull-refusal experiment: leave an unstaged change in the working
    tree to force `git pull --ff-only` to abort, expect the script
    to stop before render with the git error visible.
  - `shellcheck scripts/sync-runtime-skills.sh` and `shfmt -d`
    (clean).
  - `bash scripts/ci/all.sh` (expect green).

### Task 1.2: Cross-reference the new script in DEVELOPMENT.md and setup.sh

- **Location**:
  - `DEVELOPMENT.md`
  - `scripts/setup.sh`
- **Description**: Add a short subsection (or extend an existing one)
  in `DEVELOPMENT.md` that explains the difference between
  `scripts/setup.sh` (first-time host bootstrap) and
  `scripts/sync-runtime-skills.sh` (daily skill refresh), and tells
  skill authors which one to run after merging a new skill. Add a
  single line to `scripts/setup.sh`'s help text
  ("For daily skill refreshes, see
  `scripts/sync-runtime-skills.sh`") without changing any
  setup.sh behaviour. Confirm the new doc paragraph passes
  `rumdl check` and the help-text edit does not break the existing
  usage string.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `DEVELOPMENT.md` contains a paragraph or bullet that names both
    scripts and links the new one for a skill author.
  - `scripts/setup.sh --help` output includes the one-line pointer
    to `scripts/sync-runtime-skills.sh`.
  - No other docs (`README.md`, `AGENT_HOME.md`, plan source) drift
    out of sync; cross-references stay accurate.
- **Validation**:
  - `rumdl check DEVELOPMENT.md`
  - `bash scripts/setup.sh --help` (confirm the new pointer line is
    present and the usage block still renders).
  - `agent-runtime audit-drift` (expect clean — these are tracked
    docs, no drift class should trip).

## Issue Closeout Gate

The tracking issue is complete when:

- Task 1.1 and Task 1.2 are landed on `main`.
- Both deliberate-failure experiments in Task 1.1 (rendered-file
  perturbation; pull refusal) have been run and a redacted snippet
  of each is posted as a comment on the tracking issue.
- Full `bash scripts/ci/all.sh` runs green on `main` after the
  script lands.
- The issue dashboard links to current validation evidence and the
  state comment shows `validation=passed`, `approval=approved`.

A future `meta:sync-runtime-skills` skill wrapper is explicitly
**not** required for this tracker to close. Open a follow-up tracker
when its preconditions are met (the script has been exercised against
at least one real skill-add cycle and the user accepts the workflow).

## Future Work (Out Of Scope For This Tracker)

- Skill wrapper: `meta:sync-runtime-skills` that wraps the script,
  defaults to dry-run, explains the runtime homes it will mutate,
  and reports installed skill / discovery evidence in a
  `skill-usage.record.v1` envelope. Defer per source [D1] until the
  script is exercised.
- Optional `--audit-drift` tail probe — would let the daily loop
  also surface manifest drift, at the cost of overlap with CI.
  Reassess after the script has run for a few skill-add cycles.
