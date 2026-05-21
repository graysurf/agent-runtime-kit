# Plan: Phase 4 — Domain Migration Sweep

## Overview

Final phase of the agent-runtime-kit migration. Five sprints rewrite every
remaining skill domain (`meta`, `media`, `browser`, `evidence`, `pr`,
`dispatch`) so that each body invokes the canonical nils-cli binary
instead of duplicating logic, then re-verifies the `reporting` POC from
Plan 03, then archives the two legacy source repos (`graysurf/agent-kit`,
`graysurf/claude-kit`) per Resolved Decision #3. After Sprint 5 closes,
`graysurf/agent-runtime-kit` is the sole content source of truth.

The per-skill checklist from `docs/source/inventory-target-architecture.md`
lines 1741-1750 drives every domain task: identify the binary, strip
inline logic, rewrite the body to invoke the binary with documented flags,
add `required_clis` with a verified minimum semver, and log any missing
binary as an extraction-backlog candidate instead of reinventing it inline.

## Read First

- Primary source: docs/plans/05-domain-migration/05-domain-migration-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Whether `agent-kit` archival should retain the public-content split decision or defer it. Default: defer.
  - Final cutover date for `$HOME/.agents` symlink removal. Recommended: 2026-06-30.
  - Whether dispatch:* skills should keep their plugin-namespaced names or simplify post-migration. Default: keep.

## Scope

- In scope:
  - Rewriting skill bodies under `skills/meta/`, `skills/media/`,
    `skills/browser/`, `skills/evidence/`, `skills/pr/`,
    `skills/dispatch/`, plus matching `plugins/<domain>/` plugin bundles
    where the domain ships as a plugin.
  - Updating `manifests/skills.yaml` `required_clis` entries with pinned
    minimum semvers for each migrated skill.
  - Refreshing render-golden snapshots under `tests/golden/<domain>/`.
  - Logging every "binary missing" finding in
    `docs/source/extraction-backlog.md`.
  - Re-verifying the `reporting` POC migrated in Plan 03 still passes
    sandbox + doctor gates.
  - Auditing `.private/` overlay merges after every domain rewrite.
  - Verifying project-local overlay smoke test (CI gate 8) for
    `bench`, `demo`, `deploy`, `pre-pr`, `release`, `bootstrap`.
  - Archiving `graysurf/agent-kit` and `graysurf/claude-kit` on GitHub
    (`gh repo edit --archived`, root `MOVED.md`, no delete).
  - Removing the legacy `$HOME/.agents` symlink.
  - Migrating any pre-existing `$XDG_STATE_HOME/claude-kit/` tree to
    `$XDG_STATE_HOME/agent-runtime-kit/claude/`.
- Out of scope:
  - Renaming skill manifest IDs (`pr:*`, `dispatch:*`); rename plan is
    a follow-up.
  - Adding new nils-cli binaries or flags — missing capability goes to
    the extraction backlog and the skill body becomes a stub that exits
    non-zero with a clear "blocked on extraction" message.
  - Public-content split of `graysurf/agent-kit`; deferred per Open
    Question.
  - Re-migrating the `reporting` domain (Plan 03 POC); Sprint 1
    re-verifies only.

## Assumptions

1. Live source repo skill counts captured 2026-05-20 via `find … -name SKILL.md`:
   - agent-kit:tools has 29 SKILL.md files (split across `agent-docs`,
     `agent-out`, `app-runtime`, `browser`, `computer-use`, `git`,
     `google-workspace`, `market-research`, `media`, `notifications`,
     `review`, `scope`, `skill-management`, `sql`, `testing`,
     `workflow-evidence`).
   - agent-kit:workflows has 34 SKILL.md files (split across
     `code-review`, `conversation`, `coordination`, `heuristic-system`,
     `issue`, `mr`, `plan`, `pr`, `prompts`, `qa`, `reporting`).
   - agent-kit:automation has 8 SKILL.md files (split across `bug`,
     `ci`, `commit`, `issue`, `release`, `security`).
   - agent-kit:_projects has 4 SKILL.md files (project overlays).
   - claude-kit:plugins/meta has 4 SKILL.md files
     (`create-project-skill`, `create-skill`, `remove-skill`,
     `skill-governance`).
   - claude-kit:plugins/media has 3 SKILL.md files
     (`image-processing`, `screen-record`, `screenshot`).
   - claude-kit:plugins/browser has 6 SKILL.md files (`agent-browser`,
     `browser-qa`, `browser-session`, `playwright`, `web-evidence`,
     `web-qa`).
   - claude-kit:plugins/evidence has 6 SKILL.md files (`canary-check`,
     `docs-impact`, `model-cross-check`, `review-evidence`,
     `skill-usage`, `test-first-evidence`).
   - claude-kit:plugins/pr has 13 SKILL.md files (`close-bug-pr`,
     `close-feature-pr`, `close-github-pr`, `close-gitlab-mr`,
     `create-bug-pr`, `create-dispatch-lane-pr`, `create-feature-pr`,
     `create-github-pr`, `create-gitlab-mr`, `deliver-bug-pr`,
     `deliver-feature-pr`, `deliver-github-pr`, `deliver-gitlab-mr`).
   - claude-kit:plugins/dispatch has 17 SKILL.md files (full
     plan / issue / execute / cleanup family).
   - claude-kit:plugins/reporting has 2 SKILL.md files (`daily-brief`,
     `project-retro`) — already migrated by Plan 03, re-verified here.
   - claude-kit:skills (root) has 17 SKILL.md files; the meta-equivalent
     subset migrating here is `agent-doc-init`, `agent-scope-lock`,
     `semantic-commit`, `semantic-commit-autostage`,
     `heuristic-error-inbox`.
2. The `meta` domain rewrite (Sprint 1) preserves the existing
   `semantic-commit` and `agent-docs` preflight contracts unchanged so
   downstream sprints (and any in-flight work that hot-reloads from this
   repo) still pass.
3. `forge-cli` semver pinned in Plan 04's `required_clis` bump is
   sufficient to cover the `pr deliver` macro used in Sprint 4; this plan
   does not bump it again.
4. Plan 04 has landed: the sandbox install rehearsal harness exists and
   doctor flags `required_clis` regressions. Sprint 4 cannot run before
   Plan 04 is green.
5. Plan 03 has landed: the `reporting` domain is already migrated and the
   render-golden snapshot exists; Sprint 1 task 1.0 only re-verifies it.
6. Both `graysurf/agent-kit` and `graysurf/claude-kit` are reachable via
   `gh` with archive permission; the operator running Sprint 5 has admin
   rights on both.

## Sprint 1: Migrate `meta` domain (and verify Plan 03 reporting POC)

**Goal**: Rewrite every meta-domain skill body to invoke its canonical
nils-cli binary, with `required_clis` pinned ≥0.2.0, render-golden
updated, and sandbox install rehearsal still passing — so subsequent
sprints rewrite against the new bodies rather than the legacy ones.

**Demo/Validation**:

- Commands:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `cargo test -p agent-runtime-cli render_golden_reporting`
  - `bash tests/sandbox/claude/run.sh`
  - `bash tests/sandbox/codex/run.sh`
  - `agent-runtime doctor --product claude`
  - `agent-runtime doctor --product codex`
- Verify: every migrated meta skill body contains no inline shell or
  Python, every `manifests/skills.yaml` entry for a meta skill carries
  `required_clis` ≥0.2.0, sandbox install rehearsal lists every meta
  skill, doctor reports all `required_clis` as `ok`.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.0: Re-verify Plan 03 reporting POC

- **Location**:
  - skills/reporting/daily-brief/SKILL.md
  - skills/reporting/project-retro/SKILL.md
  - tests/golden/reporting/daily-brief.snap
  - tests/golden/reporting/project-retro.snap
  - manifests/skills.yaml
- **Description**: Re-run the Plan 03 reporting POC validation gates
  against the current `main` to confirm Plan 04 did not regress them.
  Run `cargo test -p agent-runtime-cli render_golden_reporting`, the
  sandbox install rehearsal for both products, and `agent-runtime doctor`
  for both products. If any check fails, file a blocker in this plan's
  execution-state ledger and stop the sprint; do not patch reporting
  inside this plan.
- **Dependencies**:
  - none
- **Complexity**: 2
- **Acceptance criteria**:
  - `cargo test -p agent-runtime-cli render_golden_reporting` passes
    unchanged.
  - Sandbox install rehearsal for both products lists every reporting
    skill present after Plan 03.
  - `agent-runtime doctor --product claude` and `--product codex` report
    every reporting-domain `required_clis` as `ok`.
  - If any check fails, this plan's execution-state ledger is updated
    with a `Blockers` entry naming the failing gate.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_reporting`
  - `bash tests/sandbox/claude/run.sh`
  - `bash tests/sandbox/codex/run.sh`
  - `agent-runtime doctor --product claude`
  - `agent-runtime doctor --product codex`

### Task 1.1: Migrate `agent-docs` skill body

- **Location**:
  - skills/meta/agent-docs/SKILL.md
  - manifests/skills.yaml
  - tests/golden/meta/agent-docs.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify `agent-docs` (nils-cli workspace binary) as
  the owner of the deterministic logic. Strip every embedded shell /
  Python / inline body section from the legacy claude-kit
  `agent-doc-init` skill and any agent-kit `tools/agent-docs/` skill.
  Rewrite the body to invoke `agent-docs --docs-home "$HOME/.claude"`
  with the documented `resolve` / `baseline` flags, JSON output handling,
  and prose covering the strict-gate / status-present error recovery from
  the global CLAUDE.md preflight contract. Pin `required_clis: agent-docs
  >=0.2.0` in `manifests/skills.yaml`. Refresh the render-golden
  snapshot. If any flag needed by the body does not exist in the released
  binary, append an extraction-backlog entry naming the gap.
- **Dependencies**:
  - Task 1.0
- **Complexity**: 5
- **Acceptance criteria**:
  - `skills/meta/agent-docs/SKILL.md` contains no inline shell / Python
    code blocks beyond documented `agent-docs` invocations.
  - `manifests/skills.yaml` entry for `agent-docs` carries
    `required_clis: agent-docs >=0.2.0`.
  - `tests/golden/meta/agent-docs.snap` matches the rendered output.
  - Sandbox install rehearsal lists the migrated skill.
  - Any missing-binary capability is logged in
    `docs/source/extraction-backlog.md` with a one-line gap description.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `agent-runtime doctor --product claude`

### Task 1.2: Migrate `agent-scope-lock` skill body

- **Location**:
  - skills/meta/agent-scope-lock/SKILL.md
  - manifests/skills.yaml
  - tests/golden/meta/agent-scope-lock.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `agent-scope-lock` binary as
  owner. Strip inline logic from the existing skill bodies under
  claude-kit and agent-kit, rewrite to invoke `agent-scope-lock` with
  documented `create`, `read`, `validate`, and `clear` flags and JSON
  parsing. Pin `required_clis: agent-scope-lock >=0.2.0`. Refresh the
  render-golden snapshot. Log gaps to extraction-backlog if needed.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/meta/agent-scope-lock/SKILL.md` contains no inline shell /
    Python beyond binary invocations.
  - `manifests/skills.yaml` entry pins `agent-scope-lock >=0.2.0`.
  - `tests/golden/meta/agent-scope-lock.snap` matches rendered output.
  - Sandbox install rehearsal lists the migrated skill.
  - Any missing capability appears in `docs/source/extraction-backlog.md`.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `agent-runtime doctor --product claude`

### Task 1.3: Migrate `agent-out` skill body

- **Location**:
  - skills/meta/agent-out/SKILL.md
  - manifests/skills.yaml
  - tests/golden/meta/agent-out.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `agent-out` binary as owner.
  Rewrite the body to invoke `agent-out` for state-tree allocation under
  `$XDG_STATE_HOME/claude-kit/out/` (the contract named in the global
  CLAUDE.md preflight). Pin `required_clis: agent-out >=0.2.0`. Refresh
  golden. Log gaps if any.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/meta/agent-out/SKILL.md` contains no inline shell beyond
    binary invocations.
  - `manifests/skills.yaml` pins `agent-out >=0.2.0`.
  - `tests/golden/meta/agent-out.snap` matches rendered output.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `agent-runtime doctor --product claude`

### Task 1.4: Migrate `heuristic-inbox` skill body

- **Location**:
  - skills/meta/heuristic-inbox/SKILL.md
  - manifests/skills.yaml
  - tests/golden/meta/heuristic-inbox.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `heuristic-inbox` binary as
  owner (the legacy skill is `heuristic-error-inbox`). Rewrite the body
  to invoke `heuristic-inbox` for `new`, `promote`, `archive`, and
  `list` lifecycle commands matching the `HEURISTIC_SYSTEM.md` routing
  table from the global CLAUDE.md. Pin `required_clis: heuristic-inbox
  >=0.2.0`. Refresh golden. Log gaps.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - `skills/meta/heuristic-inbox/SKILL.md` invokes `heuristic-inbox` and
    contains no inline body logic.
  - `manifests/skills.yaml` pins `heuristic-inbox >=0.2.0`.
  - `tests/golden/meta/heuristic-inbox.snap` matches.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `agent-runtime doctor --product claude`

### Task 1.5: Migrate `repo-retro` skill body

- **Location**:
  - skills/meta/repo-retro/SKILL.md
  - manifests/skills.yaml
  - tests/golden/meta/repo-retro.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `repo-retro` binary (or log an
  extraction-backlog entry if not yet shipped) and rewrite the body to
  invoke it. If the binary does not exist, leave the skill body as a
  stub that exits non-zero with a clear "blocked on extraction" message
  per the per-skill checklist step 5, and log the gap. Pin
  `required_clis` once the binary exists.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/meta/repo-retro/SKILL.md` either invokes `repo-retro` or
    exits non-zero with a `blocked on extraction` message.
  - If invoked: `manifests/skills.yaml` pins a concrete semver.
  - If stubbed: `docs/source/extraction-backlog.md` carries an entry
    naming `repo-retro` and the required surface.
  - `tests/golden/meta/repo-retro.snap` matches the chosen path.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `agent-runtime doctor --product claude`

### Task 1.6: Migrate `semantic-commit` skill body

- **Location**:
  - skills/meta/semantic-commit/SKILL.md
  - manifests/skills.yaml
  - tests/golden/meta/semantic-commit.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `semantic-commit` binary as
  owner. Rewrite the body to invoke `semantic-commit commit` with the
  documented `--max-header-width` and `SEMANTIC_COMMIT_HEADER_WIDTH`
  envelope (per the nils-cli CLI UX plan that landed earlier). Preserve
  the commit body gate (1-2 bullets on non-trivial commits). Pin
  `required_clis: semantic-commit >=0.2.0`. Refresh golden. Log gaps.
  Critically, do not change the externally observable behaviour — every
  downstream sprint relies on `semantic-commit` to land its commits.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 6
- **Acceptance criteria**:
  - `skills/meta/semantic-commit/SKILL.md` invokes the binary and has no
    inline body logic.
  - `manifests/skills.yaml` pins `semantic-commit >=0.2.0`.
  - `tests/golden/meta/semantic-commit.snap` matches rendered output.
  - The body still enforces the 1-2 bullets body gate for non-trivial
    commits.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_meta`
  - `bash tests/sandbox/claude/run.sh`
  - `bash tests/sandbox/codex/run.sh`
  - `agent-runtime doctor --product claude`

## Sprint 2: Migrate `media` + `browser` domains

**Goal**: Rewrite the four low-risk wrapper skills (media: 2; browser: 2)
in parallel, pinning each `required_clis` entry and refreshing golden
snapshots.

**Demo/Validation**:

- Commands:
  - `cargo test -p agent-runtime-cli render_golden_media`
  - `cargo test -p agent-runtime-cli render_golden_browser`
  - `bash tests/sandbox/claude/run.sh`
  - `bash tests/sandbox/codex/run.sh`
  - `agent-runtime doctor --product claude`
  - `agent-runtime doctor --product codex`
- Verify: each of the four migrated skill bodies contains no inline
  shell / Python beyond binary invocations; doctor reports all four
  `required_clis` entries as `ok`.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 2.1: Migrate `image-processing` skill body

- **Location**:
  - skills/media/image-processing/SKILL.md
  - manifests/skills.yaml
  - tests/golden/media/image-processing.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `image-processing` binary as
  owner. Strip inline ImageMagick / Python from the legacy skill body,
  rewrite to invoke `image-processing` with documented resize / convert /
  optimize flags and JSON output. Pin `required_clis: image-processing
  >=0.2.0`. Refresh golden. Log gaps.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/media/image-processing/SKILL.md` contains no inline shell /
    Python.
  - `manifests/skills.yaml` pins `image-processing >=0.2.0`.
  - `tests/golden/media/image-processing.snap` matches.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_media`
  - `agent-runtime doctor --product claude`

### Task 2.2: Migrate `screen-record` skill body

- **Location**:
  - skills/media/screen-record/SKILL.md
  - manifests/skills.yaml
  - tests/golden/media/screen-record.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `screen-record` binary as
  owner. Rewrite the body to invoke `screen-record` for start / stop /
  status commands, with macOS-only guards documented in prose. Pin
  `required_clis: screen-record >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/media/screen-record/SKILL.md` contains no inline shell.
  - `manifests/skills.yaml` pins `screen-record >=0.2.0`.
  - `tests/golden/media/screen-record.snap` matches.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_media`
  - `agent-runtime doctor --product claude`

### Task 2.3: Migrate `browser-session` skill body

- **Location**:
  - skills/browser/browser-session/SKILL.md
  - manifests/skills.yaml
  - tests/golden/browser/browser-session.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `browser-session` binary as
  owner. Rewrite the body to invoke it for session open / close /
  inspect commands. Pin `required_clis: browser-session >=0.2.0`.
  Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/browser/browser-session/SKILL.md` has no inline shell /
    Python.
  - `manifests/skills.yaml` pins `browser-session >=0.2.0`.
  - `tests/golden/browser/browser-session.snap` matches.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_browser`
  - `agent-runtime doctor --product claude`

### Task 2.4: Migrate `canary-check` skill body

- **Location**:
  - skills/browser/canary-check/SKILL.md
  - manifests/skills.yaml
  - tests/golden/browser/canary-check.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `canary-check` binary as owner.
  Rewrite the body to invoke it. Pin `required_clis: canary-check
  >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `skills/browser/canary-check/SKILL.md` has no inline shell / Python.
  - `manifests/skills.yaml` pins `canary-check >=0.2.0`.
  - `tests/golden/browser/canary-check.snap` matches.
  - Sandbox install rehearsal lists the skill.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_browser`
  - `agent-runtime doctor --product claude`

## Sprint 3: Migrate `evidence` domain

**Goal**: Rewrite all six evidence-domain skills with per-skill task
scoping so each PR review stays small.

**Demo/Validation**:

- Commands:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `bash tests/sandbox/claude/run.sh`
  - `bash tests/sandbox/codex/run.sh`
  - `agent-runtime doctor --product claude`
  - `agent-runtime doctor --product codex`
- Verify: each of the six migrated skill bodies has no inline logic,
  each `required_clis` entry resolves `ok` under doctor, golden snapshot
  matches the new render.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 3.1: Migrate `web-evidence` skill body

- **Location**:
  - skills/evidence/web-evidence/SKILL.md
  - manifests/skills.yaml
  - tests/golden/evidence/web-evidence.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `web-evidence` binary as
  owner. Rewrite the body to invoke it for evidence capture commands.
  Pin `required_clis: web-evidence >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/evidence/web-evidence/SKILL.md` has no inline shell / Python.
  - `manifests/skills.yaml` pins `web-evidence >=0.2.0`.
  - `tests/golden/evidence/web-evidence.snap` matches.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `agent-runtime doctor --product claude`

### Task 3.2: Migrate `test-first-evidence` skill body

- **Location**:
  - skills/evidence/test-first-evidence/SKILL.md
  - manifests/skills.yaml
  - tests/golden/evidence/test-first-evidence.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `test-first-evidence` binary as
  owner. Rewrite the body to invoke it. Pin `required_clis:
  test-first-evidence >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/evidence/test-first-evidence/SKILL.md` has no inline logic.
  - `manifests/skills.yaml` pins `test-first-evidence >=0.2.0`.
  - `tests/golden/evidence/test-first-evidence.snap` matches.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `agent-runtime doctor --product claude`

### Task 3.3: Migrate `review-evidence` skill body

- **Location**:
  - skills/evidence/review-evidence/SKILL.md
  - manifests/skills.yaml
  - tests/golden/evidence/review-evidence.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `review-evidence` binary as
  owner. Rewrite the body to invoke it. Pin `required_clis:
  review-evidence >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/evidence/review-evidence/SKILL.md` has no inline logic.
  - `manifests/skills.yaml` pins `review-evidence >=0.2.0`.
  - `tests/golden/evidence/review-evidence.snap` matches.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `agent-runtime doctor --product claude`

### Task 3.4: Migrate `skill-usage` skill body

- **Location**:
  - skills/evidence/skill-usage/SKILL.md
  - manifests/skills.yaml
  - tests/golden/evidence/skill-usage.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `skill-usage` binary as owner.
  Rewrite the body to invoke it. Pin `required_clis: skill-usage
  >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `skills/evidence/skill-usage/SKILL.md` has no inline logic.
  - `manifests/skills.yaml` pins `skill-usage >=0.2.0`.
  - `tests/golden/evidence/skill-usage.snap` matches.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `agent-runtime doctor --product claude`

### Task 3.5: Migrate `docs-impact` skill body

- **Location**:
  - skills/evidence/docs-impact/SKILL.md
  - manifests/skills.yaml
  - tests/golden/evidence/docs-impact.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `docs-impact` binary as owner.
  Rewrite the body to invoke it. Pin `required_clis: docs-impact
  >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - `skills/evidence/docs-impact/SKILL.md` has no inline logic.
  - `manifests/skills.yaml` pins `docs-impact >=0.2.0`.
  - `tests/golden/evidence/docs-impact.snap` matches.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `agent-runtime doctor --product claude`

### Task 3.6: Migrate `model-cross-check` skill body

- **Location**:
  - skills/evidence/model-cross-check/SKILL.md
  - manifests/skills.yaml
  - tests/golden/evidence/model-cross-check.snap
  - docs/source/extraction-backlog.md
- **Description**: Identify the nils-cli `model-cross-check` binary as
  owner. Rewrite the body to invoke it. Pin `required_clis:
  model-cross-check >=0.2.0`. Refresh golden.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `skills/evidence/model-cross-check/SKILL.md` has no inline logic.
  - `manifests/skills.yaml` pins `model-cross-check >=0.2.0`.
  - `tests/golden/evidence/model-cross-check.snap` matches.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_evidence`
  - `agent-runtime doctor --product claude`

## Sprint 4: Migrate `pr` + `dispatch` domains

**Goal**: Rewrite the highest-risk surfaces. Every pr-domain skill
invokes `forge-cli`; every dispatch-domain skill invokes `plan-issue`,
`plan-issue-local`, or `plan-tooling`. Sprint passes only when a
deliver-lifecycle smoke test (open + close one throwaway PR on a sandbox
branch in a scratch fork) succeeds.

**Demo/Validation**:

- Commands:
  - `cargo test -p agent-runtime-cli render_golden_pr`
  - `cargo test -p agent-runtime-cli render_golden_dispatch`
  - `bash tests/sandbox/claude/run.sh`
  - `bash tests/sandbox/codex/run.sh`
  - `agent-runtime doctor --product claude`
  - `agent-runtime doctor --product codex`
  - `bash tests/smoke/deliver-lifecycle.sh --scratch-fork`
- Verify: deliver-lifecycle smoke test opens a draft PR via
  `pr:create-feature-pr` on a sandbox branch, the matching close path
  via `pr:close-feature-pr` succeeds, no skill body contains inline
  shell / Python beyond binary invocations.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 4.1: Migrate pr-domain create skills onto `forge-cli`

- **Location**:
  - skills/pr/create-feature-pr/SKILL.md
  - skills/pr/create-bug-pr/SKILL.md
  - skills/pr/create-gitlab-mr/SKILL.md
  - manifests/skills.yaml
  - tests/golden/pr/create-feature-pr.snap
  - tests/golden/pr/create-bug-pr.snap
  - tests/golden/pr/create-gitlab-mr.snap
  - docs/source/extraction-backlog.md
- **Description**: Rewrite each of the three create skills to invoke
  `forge-cli pr create` (GitHub) or `forge-cli mr create` (GitLab) with
  the documented `--draft`, `--branch`, `--title`, `--body-file` flags.
  Strip the legacy claude-kit inline gh / glab logic. Pin
  `required_clis: forge-cli >=<plan-04-version>` (carry the semver Plan
  04 published). Refresh golden snapshots. Log gaps if any flag is
  missing.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Each of the three create-skill bodies contains no inline gh / glab
    invocations.
  - `manifests/skills.yaml` pins `forge-cli` at the Plan 04 semver for
    each entry.
  - All three golden snapshots match.
  - Sandbox install rehearsal lists all three skills.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_pr`
  - `agent-runtime doctor --product claude`

### Task 4.2: Migrate pr-domain close skills onto `forge-cli`

- **Location**:
  - skills/pr/close-feature-pr/SKILL.md
  - skills/pr/close-bug-pr/SKILL.md
  - skills/pr/close-gitlab-mr/SKILL.md
  - manifests/skills.yaml
  - tests/golden/pr/close-feature-pr.snap
  - tests/golden/pr/close-bug-pr.snap
  - tests/golden/pr/close-gitlab-mr.snap
  - docs/source/extraction-backlog.md
- **Description**: Rewrite each close skill to invoke `forge-cli pr
  close` / `forge-cli mr close` with documented cleanup flags
  (branch delete, draft-to-ready, merge). Pin `required_clis: forge-cli`
  at the Plan 04 semver. Refresh golden.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Each of the three close-skill bodies has no inline gh / glab logic.
  - `manifests/skills.yaml` pins `forge-cli` at the Plan 04 semver.
  - All three golden snapshots match.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_pr`
  - `agent-runtime doctor --product claude`

### Task 4.3: Migrate pr-domain deliver skills onto `forge-cli`

- **Location**:
  - skills/pr/deliver-feature-pr/SKILL.md
  - skills/pr/deliver-bug-pr/SKILL.md
  - skills/pr/deliver-gitlab-mr/SKILL.md
  - manifests/skills.yaml
  - tests/golden/pr/deliver-feature-pr.snap
  - tests/golden/pr/deliver-bug-pr.snap
  - tests/golden/pr/deliver-gitlab-mr.snap
  - docs/source/extraction-backlog.md
  - tests/smoke/deliver-lifecycle.sh
- **Description**: Rewrite each deliver skill to invoke the macro
  composed of `forge-cli pr create` → wait CI → `forge-cli pr close`.
  Pin `required_clis: forge-cli` at the Plan 04 semver (per Assumption
  3 the semver is sufficient). Add or update
  `tests/smoke/deliver-lifecycle.sh` so it drives one throwaway PR on a
  scratch fork through the macro and asserts the merged state.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 8
- **Acceptance criteria**:
  - Each of the three deliver-skill bodies has no inline gh / glab logic.
  - `manifests/skills.yaml` pins `forge-cli` at the Plan 04 semver.
  - All three golden snapshots match.
  - `tests/smoke/deliver-lifecycle.sh --scratch-fork` opens and closes
    one throwaway PR successfully.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_pr`
  - `bash tests/smoke/deliver-lifecycle.sh --scratch-fork`
  - `agent-runtime doctor --product claude`

### Task 4.4: Migrate dispatch-domain skills onto `plan-issue` / `plan-issue-local` / `plan-tooling`

- **Location**:
  - skills/dispatch/dispatch-implementation/SKILL.md
  - skills/dispatch/dispatch-orchestrator/SKILL.md
  - skills/dispatch/dispatch-review/SKILL.md
  - skills/dispatch/dispatch-monitor/SKILL.md
  - manifests/skills.yaml
  - tests/golden/dispatch/dispatch-implementation.snap
  - tests/golden/dispatch/dispatch-orchestrator.snap
  - tests/golden/dispatch/dispatch-review.snap
  - tests/golden/dispatch/dispatch-monitor.snap
  - docs/source/extraction-backlog.md
- **Description**: Rewrite each dispatch skill to invoke the canonical
  nils-cli binary set: `plan-issue` for issue lifecycle, `plan-issue-local`
  for local-state ledger ops, `plan-tooling` for validate / spec / to-json
  operations. Strip the legacy claude-kit dispatch logic. Pin
  `required_clis: plan-issue >=0.8.0, plan-issue-local >=0.2.0,
  plan-tooling >=0.2.0` per entry as relevant. Refresh golden snapshots.
- **Dependencies**:
  - Task 4.3
- **Complexity**: 8
- **Acceptance criteria**:
  - Each of the four dispatch-skill bodies has no inline gh / shell
    logic.
  - `manifests/skills.yaml` pins each binary at the named semver.
  - All four golden snapshots match.
  - Sandbox install rehearsal lists all four skills.
- **Validation**:
  - `cargo test -p agent-runtime-cli render_golden_dispatch`
  - `agent-runtime doctor --product claude`
  - `agent-runtime doctor --product codex`

## Sprint 5: Overlays audit and legacy repo archival

**Goal**: Finalize the migration. Audit `.private/` shadow overlay
merges, verify project-local overlay smoke test, archive
`graysurf/agent-kit` and `graysurf/claude-kit` per Resolved Decision #3,
remove the `$HOME/.agents` symlink, and migrate any pre-existing
`$XDG_STATE_HOME/claude-kit/` tree to the new
`$XDG_STATE_HOME/agent-runtime-kit/claude/` path.

**Demo/Validation**:

- Commands:
  - `agent-runtime install --product claude --dry-run --print-effective-config`
  - `agent-runtime install --product codex --dry-run --print-effective-config`
  - `agent-runtime doctor --product claude --check-project $HOME/Project/graysurf/agent-runtime-kit`
  - `gh repo view graysurf/agent-kit --json isArchived,name`
  - `gh repo view graysurf/claude-kit --json isArchived,name`
  - `test ! -L "$HOME/.agents"`
  - `test -d "${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude"`
- Verify: post-merge effective config matches expected for both
  products, project-local overlay smoke test green, both legacy repos
  archived with a root `MOVED.md`, neither repo deleted, local symlink
  removed, state tree migrated.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 5.1: Audit `.private/` shadow overlay merges

- **Location**:
  - .private/runtime-roots.yaml
  - .private/link-map.overrides.yaml
  - profile.recommended.yaml
  - manifests/runtime-roots.yaml
  - targets/claude/link-map.yaml
  - targets/codex/link-map.yaml
- **Description**: Re-run `agent-runtime install --dry-run
  --print-effective-config` for both products against the current
  `.private/` overlay set after every domain migration sprint has
  landed. Confirm the post-merge effective config matches the Overlay
  Merge Semantics contract (deep merge for `runtime-roots`, replace for
  `link-map.overrides`, union / replace per profile for
  `profile.recommended`). Any drift becomes a blocker logged in this
  plan's execution-state ledger.
- **Dependencies**:
  - Task 4.4
- **Complexity**: 5
- **Acceptance criteria**:
  - `agent-runtime install --product claude --dry-run
    --print-effective-config` matches the expected merge for every
    `.private/` entry.
  - Same for `--product codex`.
  - Any drift is recorded as a `Blockers` entry in
    `05-domain-migration-execution-state.md` before the sprint
    continues.
- **Validation**:
  - `agent-runtime install --product claude --dry-run --print-effective-config`
  - `agent-runtime install --product codex --dry-run --print-effective-config`

### Task 5.2: Verify project-local overlay smoke test (CI gate 8)

- **Location**:
  - tests/sandbox/project-local/run.sh
  - skills/meta/bench/SKILL.md
  - skills/meta/demo/SKILL.md
  - skills/meta/deploy/SKILL.md
  - skills/meta/pre-pr/SKILL.md
  - skills/meta/release/SKILL.md
  - skills/meta/bootstrap/SKILL.md
- **Description**: Run the project-local overlay smoke test (CI gate
  position 8 per the architecture doc) against one consumer repo for
  each of the six overlay scripts (`bench`, `demo`, `deploy`, `pre-pr`,
  `release`, `bootstrap`). The skill body for each must still dispatch
  to `<repo>/.agents/scripts/<name>.sh` only when the script exists and
  is executable, and exit non-zero with the documented "no project-local
  implementation" message otherwise. Use this repo itself
  (`$HOME/Project/graysurf/agent-runtime-kit`) as the consumer
  for any script it implements.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 5
- **Acceptance criteria**:
  - `bash tests/sandbox/project-local/run.sh` exits 0.
  - For each of the six skill bodies, dispatch happens only when the
    target script exists and is executable; missing scripts produce a
    non-zero exit with the documented message.
  - `agent-runtime doctor --product claude --check-project
    $HOME/Project/graysurf/agent-runtime-kit` reports each
    overlay as wired or missing as expected.
- **Validation**:
  - `bash tests/sandbox/project-local/run.sh`
  - `agent-runtime doctor --product claude --check-project $HOME/Project/graysurf/agent-runtime-kit`

### Task 5.3: Archive `graysurf/agent-kit` and `graysurf/claude-kit`

- **Location**:
  - docs/source/inventory-target-architecture.md
  - docs/plans/05-domain-migration/05-domain-migration-execution-state.md
- **Description**: For each of `graysurf/agent-kit` and
  `graysurf/claude-kit`: (a) commit a root `MOVED.md` pointing at
  `https://github.com/graysurf/agent-runtime-kit` and naming the
  archival date; (b) run `gh repo edit graysurf/<repo> --archived` to
  flip the GitHub archived flag; (c) verify with `gh repo view
  graysurf/<repo> --json isArchived` that `isArchived` is `true`.
  Neither repo is deleted — history preservation is required per
  Resolved Decision #3. Record both archival commits and the final
  `gh repo view` JSON in the execution-state Session Log.
- **Dependencies**:
  - Task 5.2
- **Complexity**: 4
- **Acceptance criteria**:
  - `gh repo view graysurf/agent-kit --json isArchived` returns
    `{"isArchived":true}`.
  - `gh repo view graysurf/claude-kit --json isArchived` returns
    `{"isArchived":true}`.
  - Both repos still exist (not deleted) and carry a root `MOVED.md`
    pointing at `graysurf/agent-runtime-kit`.
  - Archival commit hashes are recorded in the execution-state Session
    Log.
- **Validation**:
  - `gh repo view graysurf/agent-kit --json isArchived,name`
  - `gh repo view graysurf/claude-kit --json isArchived,name`

### Task 5.4: Remove `$HOME/.agents` symlink

- **Location**:
  - docs/plans/05-domain-migration/05-domain-migration-execution-state.md
- **Description**: After Task 5.3 lands, remove the legacy
  `$HOME/.agents` symlink (it pointed at `$HOME/.config/agent-kit`).
  Recommended cutover date is 2026-06-30 per the source-doc Open
  Question. Verify with `test ! -L "$HOME/.agents"`. Record the removal
  command and timestamp in the execution-state Session Log.
- **Dependencies**:
  - Task 5.3
- **Complexity**: 2
- **Acceptance criteria**:
  - `test ! -L "$HOME/.agents"` exits 0.
  - Removal command and timestamp recorded in the execution-state
    Session Log.
- **Validation**:
  - `test ! -L "$HOME/.agents"`

### Task 5.5: Migrate `$XDG_STATE_HOME/claude-kit/` to `$XDG_STATE_HOME/agent-runtime-kit/claude/`

- **Location**:
  - docs/plans/05-domain-migration/05-domain-migration-execution-state.md
- **Description**: If `$XDG_STATE_HOME/claude-kit/` exists on the host
  running Sprint 5, move its tree into
  `$XDG_STATE_HOME/agent-runtime-kit/claude/` per the Runtime Root Model
  migration note. Use `rsync -a` to preserve permissions and
  timestamps, then remove the source after verifying the destination
  is intact (`diff -r` exits 0). If the source does not exist, record
  the no-op and move on. Update the execution-state Session Log with
  the source / destination paths and the `diff -r` result.
- **Dependencies**:
  - Task 5.4
- **Complexity**: 3
- **Acceptance criteria**:
  - If `$XDG_STATE_HOME/claude-kit/` existed: it now lives at
    `$XDG_STATE_HOME/agent-runtime-kit/claude/`, `diff -r` between any
    pre-migration snapshot and the destination is empty, and the old
    path no longer exists.
  - If it did not exist: a `no-op` entry is recorded in the
    execution-state Session Log.
  - `test -d "${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude"`
    exits 0 in either case (the destination is created as needed).
- **Validation**:
  - `test -d "${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude"`

## Testing Strategy

- Unit: none new (all logic lives in nils-cli binaries).
- Render-golden: refresh per migrated domain via
  `cargo test -p agent-runtime-cli render_golden_<domain>` (meta,
  media, browser, evidence, pr, dispatch). Plan 03's reporting golden
  is re-run as a regression gate in Task 1.0.
- Sandbox install rehearsal: `bash tests/sandbox/claude/run.sh` and
  `bash tests/sandbox/codex/run.sh` after every sprint. Plan 04's
  harness is the contract; this plan only consumes it.
- Doctor regression gate: `agent-runtime doctor --product claude` and
  `--product codex` after every sprint, asserting every `required_clis`
  entry resolves `ok`.
- Deliver-lifecycle smoke (Sprint 4 only):
  `bash tests/smoke/deliver-lifecycle.sh --scratch-fork` opens and
  closes one throwaway PR.
- Project-local overlay smoke (Sprint 5):
  `bash tests/sandbox/project-local/run.sh` plus
  `agent-runtime doctor --check-project <repo>` against this repo for
  the six overlay scripts.
- Plan-bundle gate: `plan-tooling validate --file
  docs/plans/05-domain-migration/05-domain-migration-plan.md --strict`
  before the first commit on each sprint branch.

## Risks & gotchas

- `meta` rewrite (Sprint 1) must not change the externally observable
  behaviour of `agent-docs` and `semantic-commit`. Downstream sprints
  rely on them; any drift cascades.
- Sprint 4 deliver-lifecycle smoke must use a **scratch fork** (not
  this repo's main) to open and close the throwaway PR. Hitting the
  real `graysurf/agent-runtime-kit` `main` with a smoke PR is
  prohibited.
- Archival (Task 5.3) is irreversible from the GitHub UI without
  `repo: admin` on both repos; confirm the operator has the right
  before kicking off the sprint.
- `$HOME/.agents` symlink removal (Task 5.4) breaks any in-flight
  shell that resolved the path at start. Recommend the 2026-06-30
  cutover date so existing sessions cycle out first.
- `.private/` overlay deep-merge semantics are subtle — a single
  `null` value removes a key from the merged config; reviewers must
  read the post-merge "effective config" emitted by `--dry-run`, not
  the input overlay files.
- Missing nils-cli binaries (any sprint task) must route to
  `docs/source/extraction-backlog.md` rather than inline shell. Inline
  logic re-introduction is the failure mode this plan explicitly
  prevents.
- `forge-cli` semver pinned in Plan 04 — if Plan 04 has not yet
  shipped, Sprint 4 cannot start. Block on it.

## Rollback plan

- Sprint 1: revert the meta-domain commits. Render-golden snapshots
  revert with the bodies. The legacy claude-kit / agent-kit skill
  sources are still present (this plan does not delete them until
  Sprint 5), so reverted sessions fall back to the legacy bodies.
- Sprints 2–4: per-domain revert. Each sprint's PRs are scoped to its
  domain (`group` PR grouping in every sprint, with parallel lanes
  where the Execution Profile says so) so a single revert restores the
  previous body and `required_clis` entries.
- Sprint 5 task 5.3 (archival): `gh repo edit graysurf/<repo>
  --no-archived` flips the flag back. The `MOVED.md` commit can be
  reverted via standard `git revert`.
- Sprint 5 task 5.4 (symlink removal): recreate the symlink with
  `ln -s "$HOME/.config/agent-kit" "$HOME/.agents"`.
- Sprint 5 task 5.5 (state migration): `rsync -a` is non-destructive
  until the source removal step; if `diff -r` flags drift, abort and
  keep the source.
