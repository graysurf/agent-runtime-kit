# Plan: Phase 4 Domain Migration Sweep

## Overview

Final migration phase for `agent-runtime-kit`. The work imports the remaining
skill domains into `core/skills/<domain>/<skill>/`, wires product adapter
metadata under `targets/<product>/`, pins `required_clis` in
`manifests/skills.yaml`, refreshes rendered golden snapshots, and then closes
the legacy-repo cutover. The plan keeps `reporting` as the already-landed Plan
03 POC and re-verifies it before migrating the heavier domains.

Every migrated skill follows the Phase 4 checklist from
`docs/source/inventory-target-architecture.md`: identify the owning nils-cli
binary, remove embedded shell/Python logic from the skill body, rewrite the
body as CLI invocation guidance with JSON/error handling, pin a concrete
`required_clis` semver, and log any missing binary surface in
`docs/source/extraction-backlog.md`.

## Read First

- Primary source: docs/plans/2026-05-20-05-domain-migration/05-domain-migration-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Whether `agent-kit` archival should retain the public-content split decision or defer it. Default: defer.
  - Final cutover date for `$HOME/.agents` compatibility alias removal.
    Recommended: after Codex Desktop skill discovery no longer needs the legacy
    `agent-kit` checkout.
  - Whether dispatch skills should keep plugin-namespaced names. Default: keep current names and defer aliases.

## Scope

- In scope:
  - Add portable skill sources under `core/skills/meta/`, `core/skills/media/`,
    `core/skills/browser/`, `core/skills/evidence/`, `core/skills/pr/`, and
    `core/skills/dispatch/`.
  - Add or update product adapter metadata under `targets/codex/plugins/<domain>/`
    and `targets/claude/plugins/<domain>/`.
  - Update `manifests/skills.yaml` and `manifests/plugins.yaml` with concrete
    `required_clis` floors against the current nils-cli surface snapshot.
  - Refresh generated output and committed golden snapshots under
    `tests/golden/<product>/plugins/<domain>/skills/<skill>/expected/`.
  - Log missing nils-cli surfaces in `docs/source/extraction-backlog.md`.
  - Extend sandbox install expected skill pins under `tests/sandbox/`.
  - Add project-local overlay smoke coverage under `tests/projects/` when the
    overlay shims land.
  - Archive `graysurf/agent-kit` and `graysurf/claude-kit` after migration,
    preserving history with root `MOVED.md` files.
  - Retire canonical use of the legacy `$HOME/.agents` symlink and migrate any
    `$XDG_STATE_HOME/claude-kit/` state tree after repository archival.
- Out of scope:
  - Adding new nils-cli binaries or flags inside this repo.
  - Renaming canonical skill IDs during the migration.
  - Deleting either legacy repository.
  - Re-migrating the Plan 03 `reporting` domain beyond regression checks.
  - Touching `sympoies/homebrew-tap` except through a separate nils-cli release
    workflow if a missing binary blocks a task.

## Assumptions

1. `docs/source/nils-cli-surface.md` is current at `v0.16.0`, and every new
   `required_clis` floor introduced by this plan defaults to `>=0.16.0` unless
   the execution lane proves a newer nils-cli release is required.
2. Plan 03 reporting migration has landed and remains the render/golden shape
   to copy for new domains.
3. Plan 04 installer, doctor, audit-drift, and sandbox rehearsal gates have
   landed in the released `agent-runtime` binary.
4. Any skill whose owning binary is absent or missing a required flag becomes a
   documented blocked stub plus an extraction-backlog entry; inline logic is not
   reintroduced.
5. Sprints are sequential integration gates. Parallelism is only within a sprint
   and only where same-batch shared-file ownership is separated.
6. External archival tasks require GitHub admin permission on
   `graysurf/agent-kit` and `graysurf/claude-kit`.

## Sprint 1: Meta Foundation

**Goal**: Re-verify the reporting POC, then migrate the meta skills that later
sprints depend on for docs resolution, output allocation, scope locks,
heuristic routing, retrospectives, and semantic commits.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
- Verify: reporting remains unchanged, all meta skills render for both
  products, sandbox expected skill pins include the meta skills, and audit-drift
  reports no source/target/manifest mismatch.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

- **TotalComplexity**: 19
- **CriticalPathComplexity**: 13
- **MaxBatchWidth**: 2
- **OverlapHotspots**: `manifests/skills.yaml`, `manifests/plugins.yaml`, and
  `docs/source/extraction-backlog.md` are owned by Task 1.4 after the parallel
  source-body lanes complete.
- **Split command**: `plan-tooling split-prs --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 1 --strategy deterministic --pr-grouping group --pr-group 'Task 1.1=s1-reporting-guard' --pr-group 'Task 1.2=s1-meta-policy-state' --pr-group 'Task 1.3=s1-meta-workflow' --pr-group 'Task 1.4=s1-meta-integration' --format json`

### Task 1.1: Re-verify Plan 03 reporting POC

- **Location**:
  - `core/skills/reporting/daily-brief/SKILL.md.tera`
  - `core/skills/reporting/project-retro/SKILL.md.tera`
  - `core/skills/reporting/topic-radar/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
- **Description**: Run the current render, golden refresh, sandbox rehearsal,
  and audit-drift gates before changing meta. If reporting changes unexpectedly,
  stop the sprint and record a blocker in the execution-state ledger instead of
  patching reporting as part of this plan.
- **Dependencies**:
  - none
- **Complexity**: 2
- **Acceptance criteria**:
  - Rendering both products succeeds before meta edits.
  - Golden refresh produces no unexpected reporting diff.
  - Sandbox rehearsal still lists the three reporting skills.
  - Any regression is captured as a blocker in
    `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

### Task 1.2: Migrate policy and state meta skills

- **Location**:
  - `core/skills/meta/agent-docs/SKILL.md.tera`
  - `core/skills/meta/agent-out/SKILL.md.tera`
  - `core/skills/meta/agent-scope-lock/SKILL.md.tera`
- **Description**: Create portable source bodies for `agent-docs`,
  `agent-out`, and `agent-scope-lock`. Each body should describe when to invoke
  the nils-cli binary, the required flags, JSON/error handling expectations, and
  product path rendering rules without embedding implementation shell or
  Python.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Each source body invokes only its owning nils-cli binary for deterministic
    behavior.
  - Product-specific paths are expressed through render helpers or prose, not
    hard-coded `$AGENT_HOME` references.
  - Missing flags or surfaces are noted for Task 1.4 to record in the shared
    extraction backlog.
  - No manifest or golden ownership is taken in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime audit-drift`

### Task 1.3: Migrate workflow meta skills

- **Location**:
  - `core/skills/meta/heuristic-inbox/SKILL.md.tera`
  - `core/skills/meta/repo-retro/SKILL.md.tera`
  - `core/skills/meta/semantic-commit/SKILL.md.tera`
- **Description**: Create portable source bodies for `heuristic-inbox`,
  `repo-retro`, and `semantic-commit`. Preserve the external behavior of
  semantic commits and heuristic routing while replacing embedded workflow
  logic with nils-cli invocation guidance.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 6
- **Acceptance criteria**:
  - `heuristic-inbox`, `repo-retro`, and `semantic-commit` source bodies contain
    no inline deterministic implementation logic.
  - `semantic-commit` keeps the existing commit-message and body-quality
    contract in prose.
  - Missing surfaces are noted for Task 1.4 to record in the shared extraction
    backlog.
  - No manifest or golden ownership is taken in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime audit-drift`

### Task 1.4: Wire meta manifests, adapters, and golden snapshots

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/meta/.codex-plugin/plugin.json`
  - `targets/claude/plugins/meta/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Register the six meta skills for both products, pin
  `required_clis` to concrete semvers, refresh golden snapshots, and update
  sandbox expected skill lists. This task owns the shared manifest/backlog files
  to avoid parallel write conflicts.
- **Dependencies**:
  - Task 1.2
  - Task 1.3
- **Complexity**: 5
- **Acceptance criteria**:
  - All six meta skills appear in `manifests/skills.yaml` with concrete
    `required_clis` floors.
  - Both product adapter plugin manifests exist and render without drift.
  - Golden snapshots are refreshed for Codex and Claude.
  - Sandbox expected skill pins include the meta skills in sorted order.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

## Sprint 2: Media And Browser Wrappers

**Goal**: Migrate low-risk media and browser wrapper skills while keeping shared
manifest/golden writes in one integration lane.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
- Verify: media/browser skills render for both products, sandbox pins are
  updated, and doctor/audit coverage catches missing `required_clis`.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

- **TotalComplexity**: 15
- **CriticalPathComplexity**: 10
- **MaxBatchWidth**: 2
- **OverlapHotspots**: Task 2.3 owns shared manifests, plugin metadata, golden
  snapshots, and sandbox pins after source-body lanes complete.
- **Split command**: `plan-tooling split-prs --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 2 --strategy deterministic --pr-grouping group --pr-group 'Task 2.1=s2-media-source' --pr-group 'Task 2.2=s2-browser-source' --pr-group 'Task 2.3=s2-media-browser-integration' --format json`

### Task 2.1: Migrate media skill sources

- **Location**:
  - `core/skills/media/image-processing/SKILL.md.tera`
  - `core/skills/media/screen-record/SKILL.md.tera`
- **Description**: Create portable source bodies for `image-processing` and
  `screen-record`, replacing ImageMagick/Python/shell implementation details
  with nils-cli invocation contracts and macOS availability notes where needed.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Both media bodies invoke their owning nils-cli binaries.
  - `screen-record` documents macOS-specific behavior and failure handling.
  - Missing binary surfaces are noted for Task 2.3 to record in the shared
    extraction backlog.
  - No shared manifest or golden files are edited in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 2.2: Migrate browser skill sources

- **Location**:
  - `core/skills/browser/browser-session/SKILL.md.tera`
  - `core/skills/browser/canary-check/SKILL.md.tera`
- **Description**: Create portable source bodies for `browser-session` and
  `canary-check`, routing deterministic evidence or session recording behavior
  through the nils-cli binaries and keeping browser-operation prose in the
  skill body.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Both browser bodies invoke their owning nils-cli binaries.
  - Browser interaction prose stays product-neutral.
  - Missing binary surfaces are noted for Task 2.3 to record in the shared
    extraction backlog.
  - No shared manifest or golden files are edited in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 2.3: Wire media/browser manifests, adapters, and golden snapshots

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/media/.codex-plugin/plugin.json`
  - `targets/codex/plugins/browser/.codex-plugin/plugin.json`
  - `targets/claude/plugins/media/.claude-plugin/plugin.json`
  - `targets/claude/plugins/browser/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Register the media and browser skills, add product plugin
  metadata, refresh golden snapshots, and update sandbox expected skill pins.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Four new skill entries have concrete `required_clis` floors.
  - Product plugin metadata exists for media and browser.
  - Golden snapshots and sandbox expected skill pins include the new skills.
  - Audit-drift reports no dangling source or rendered-target mismatch.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

## Sprint 3: Evidence Capture Records

**Goal**: Migrate the high-use evidence capture skills in two source lanes and
one shared integration lane.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
- Verify: the first four evidence skills render for both products and preserve
  deterministic record-writing guidance.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

- **TotalComplexity**: 17
- **CriticalPathComplexity**: 11
- **MaxBatchWidth**: 2
- **OverlapHotspots**: Task 3.3 owns shared manifest, plugin, golden, sandbox,
  and extraction-backlog writes after source-body lanes complete.
- **Split command**: `plan-tooling split-prs --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 3 --strategy deterministic --pr-grouping group --pr-group 'Task 3.1=s3-web-test-evidence' --pr-group 'Task 3.2=s3-review-usage-evidence' --pr-group 'Task 3.3=s3-evidence-capture-integration' --format json`

### Task 3.1: Migrate web and test-first evidence sources

- **Location**:
  - `core/skills/evidence/web-evidence/SKILL.md.tera`
  - `core/skills/evidence/test-first-evidence/SKILL.md.tera`
- **Description**: Create portable source bodies for `web-evidence` and
  `test-first-evidence`, preserving redaction, failure, and evidence-retention
  guidance while delegating deterministic record creation to nils-cli.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Both source bodies invoke their owning nils-cli binaries.
  - Evidence-retention and redaction guidance remains explicit.
  - Missing surfaces are noted for Task 3.3 to record in the shared extraction
    backlog.
  - No shared manifest or golden files are edited in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 3.2: Migrate review and skill-usage evidence sources

- **Location**:
  - `core/skills/evidence/review-evidence/SKILL.md.tera`
  - `core/skills/evidence/skill-usage/SKILL.md.tera`
- **Description**: Create portable source bodies for `review-evidence` and
  `skill-usage`, keeping workflow judgment in prose and deterministic envelope
  writing in nils-cli.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Both source bodies invoke their owning nils-cli binaries.
  - `skill-usage` documents serialized writes to one record directory.
  - Missing surfaces are noted for Task 3.3 to record in the shared extraction
    backlog.
  - No shared manifest or golden files are edited in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 3.3: Wire evidence capture manifests, adapters, and golden snapshots

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/evidence/.codex-plugin/plugin.json`
  - `targets/claude/plugins/evidence/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Register the four evidence capture skills, add product
  adapter metadata, refresh golden snapshots, and update sandbox expected skill
  pins.
- **Dependencies**:
  - Task 3.1
  - Task 3.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Four evidence capture skill entries have concrete `required_clis` floors.
  - Evidence plugin metadata exists for both products.
  - Golden snapshots and sandbox expected skill pins include the new skills.
  - Audit-drift reports no source or rendered-target mismatch.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

## Sprint 4: Evidence Analysis And Impact

**Goal**: Finish evidence migration with the analysis/impact record skills and
run the evidence-domain integration gate as a serial lane to avoid shared-file
conflicts.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
- Verify: all evidence-domain skills render and the sandbox expected skill pins
  match the installed dry-run plan.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

- **TotalComplexity**: 12
- **CriticalPathComplexity**: 12
- **MaxBatchWidth**: 1
- **OverlapHotspots**: Serial execution intentionally owns
  `manifests/skills.yaml`, plugin metadata, and sandbox pins in one lane.

### Task 4.1: Migrate docs-impact source

- **Location**:
  - `core/skills/evidence/docs-impact/SKILL.md.tera`
  - `docs/source/extraction-backlog.md`
- **Description**: Create the portable `docs-impact` source body with
  nils-cli invocation guidance, output interpretation, and docs-impact
  escalation behavior.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - The body invokes `docs-impact` for deterministic analysis.
  - The body separates docs-impact judgment from record writing.
  - Missing surfaces are logged to the extraction backlog.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 4.2: Migrate model-cross-check source

- **Location**:
  - `core/skills/evidence/model-cross-check/SKILL.md.tera`
  - `docs/source/extraction-backlog.md`
- **Description**: Create the portable `model-cross-check` source body with
  nils-cli invocation guidance, provider-boundary notes, and evidence summary
  handling.
- **Dependencies**:
  - Task 4.1
- **Complexity**: 4
- **Acceptance criteria**:
  - The body invokes `model-cross-check` for deterministic record handling.
  - Provider calls remain outside the primitive and are described as caller
    responsibility.
  - Missing surfaces are logged to the extraction backlog.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 4.3: Finalize evidence domain integration

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/evidence/.codex-plugin/plugin.json`
  - `targets/claude/plugins/evidence/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Add the final evidence skill entries, refresh plugin metadata
  and golden snapshots, and run the evidence-domain sandbox/audit gate.
- **Dependencies**:
  - Task 4.2
- **Complexity**: 4
- **Acceptance criteria**:
  - `docs-impact` and `model-cross-check` are registered with concrete
    `required_clis` floors.
  - Evidence plugin metadata and golden snapshots are current for both
    products.
  - Sandbox expected skill pins include the complete evidence domain.
  - Audit-drift reports no source or rendered-target mismatch.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

## Sprint 5: PR Create And Close

**Goal**: Migrate the lower-risk PR/MR create and close surfaces onto
`forge-cli` before touching delivery macros.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
- Verify: create/close skills invoke `forge-cli`, render for both products, and
  do not perform inline `gh`/`glab` lifecycle logic.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

- **TotalComplexity**: 12
- **CriticalPathComplexity**: 12
- **MaxBatchWidth**: 1
- **OverlapHotspots**: `manifests/skills.yaml` and golden snapshots are serially
  updated in this sprint because create/close wrappers share `forge-cli` naming
  and product aliases.

### Task 5.1: Migrate PR/MR create skills

- **Location**:
  - `core/skills/pr/create-github-pr/SKILL.md.tera`
  - `core/skills/pr/create-gitlab-mr/SKILL.md.tera`
  - `core/skills/pr/create-dispatch-lane-pr/SKILL.md.tera`
  - `docs/source/extraction-backlog.md`
- **Description**: Create portable source bodies for create flows that invoke
  `forge-cli` for GitHub PRs, GitLab MRs, and dispatch-lane PR creation. Keep
  provider-specific judgment in prose and route missing flags to the extraction
  backlog.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Create skill bodies contain no inline provider lifecycle implementation.
  - Each body names the relevant `forge-cli` command shape and failure handling.
  - Missing surfaces are logged to the extraction backlog.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 5.2: Migrate PR/MR close skills and wire create/close integration

- **Location**:
  - `core/skills/pr/close-github-pr/SKILL.md.tera`
  - `core/skills/pr/close-gitlab-mr/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/pr/.codex-plugin/plugin.json`
  - `targets/claude/plugins/pr/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Create close-flow source bodies, register create/close PR
  skills, refresh product plugin metadata and golden snapshots, and update
  sandbox expected skill pins.
- **Dependencies**:
  - Task 5.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Create and close PR/MR skill entries pin `forge-cli >=0.16.0` or the newer
    required released floor.
  - Product plugin metadata exists for the PR domain.
  - Golden snapshots and sandbox expected skill pins include create/close PR
    skills.
  - Audit-drift reports no source or rendered-target mismatch.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

## Sprint 6: PR Delivery Macros

**Goal**: Migrate end-to-end delivery skills after create/close primitives are
rendering, then add a controlled smoke test for the delivery macro.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
  - `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke`
- Verify: delivery skills use `forge-cli` macro guidance and the smoke test
  operates only on a scratch fork/branch.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

- **TotalComplexity**: 15
- **CriticalPathComplexity**: 15
- **MaxBatchWidth**: 1
- **OverlapHotspots**: Smoke harness, golden snapshots, and PR skill manifest
  entries are intentionally serialized.

### Task 6.1: Migrate delivery skill sources

- **Location**:
  - `core/skills/pr/deliver-github-pr/SKILL.md.tera`
  - `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera`
  - `docs/source/extraction-backlog.md`
- **Description**: Create portable delivery skill bodies that compose create,
  wait/check, repair, and close behavior through `forge-cli` while leaving
  review judgment and failure recovery in prose.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Delivery bodies contain no inline provider lifecycle implementation.
  - GitHub and GitLab differences are handled through documented `forge-cli`
    command shapes.
  - Missing surfaces are logged to the extraction backlog.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 6.2: Add delivery lifecycle smoke harness

- **Location**:
  - `tests/smoke/deliver-lifecycle.sh`
  - `docs/source/extraction-backlog.md`
  - `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`
- **Description**: Add a smoke harness that drives one throwaway PR on a scratch
  fork/branch through create and close flows. The script must refuse to run
  against `main` or the canonical repository without an explicit scratch target.
- **Dependencies**:
  - Task 6.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Smoke harness exits non-zero if no scratch fork/branch is supplied.
  - Smoke harness records the created PR URL and final merged/closed state in
    execution evidence.
  - The harness never targets `graysurf/agent-runtime-kit` `main`.
- **Validation**:
  - `if bash tests/smoke/deliver-lifecycle.sh; then exit 1; else test $? -ne 0; fi`
  - `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke`

### Task 6.3: Wire delivery manifests, golden snapshots, and PR domain gate

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/pr/.codex-plugin/plugin.json`
  - `targets/claude/plugins/pr/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Register delivery skills, refresh PR plugin metadata and
  golden snapshots, update sandbox pins, and run the full PR-domain render,
  sandbox, audit, and smoke checks.
- **Dependencies**:
  - Task 6.2
- **Complexity**: 4
- **Acceptance criteria**:
  - Delivery skill entries pin `forge-cli` at a concrete released semver.
  - Golden snapshots and sandbox expected skill pins include delivery skills.
  - Audit-drift reports no PR-domain source/render mismatch.
  - Delivery smoke passes against the scratch target.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
  - `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke`

## Sprint 7: Dispatch Domain

**Goal**: Migrate plan/issue/dispatch skills onto `plan-tooling`,
`plan-issue`, and `plan-issue-local`, with `forge-cli` mentioned only where PR
mirroring is explicitly part of the workflow.

**Demo/Validation**:

- Commands:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`
- Verify: dispatch skills render for both products, use nils-cli planning/issue
  primitives, and keep orchestration policy in prose.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

- **TotalComplexity**: 17
- **CriticalPathComplexity**: 11
- **MaxBatchWidth**: 2
- **OverlapHotspots**: Task 7.3 owns shared manifest, plugin metadata, sandbox,
  golden, and extraction-backlog writes after source-body lanes complete.
- **Split command**: `plan-tooling split-prs --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 7 --strategy deterministic --pr-grouping group --pr-group 'Task 7.1=s7-issue-lifecycle' --pr-group 'Task 7.2=s7-execution-orchestration' --pr-group 'Task 7.3=s7-dispatch-integration' --format json`

### Task 7.1: Migrate issue lifecycle dispatch sources

- **Location**:
  - `core/skills/dispatch/plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/issue-lifecycle/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
- **Description**: Create portable source bodies for issue creation,
  maintenance, and closeout workflows using `plan-issue`, `plan-issue-local`,
  and `plan-tooling` where appropriate.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Issue lifecycle bodies invoke nils-cli issue/planning primitives.
  - GitHub/GitLab provider distinctions remain explicit in prose.
  - Missing surfaces are noted for Task 7.3 to record in the shared extraction
    backlog.
  - No shared manifest or golden files are edited in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 7.2: Migrate execution and dispatch orchestration sources

- **Location**:
  - `core/skills/dispatch/execute-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera`
  - `core/skills/dispatch/execute-dispatch-lane/SKILL.md.tera`
- **Description**: Create portable source bodies for issue-backed execution,
  delivery, review, and subagent PR handoff workflows. Use planning primitives
  for durable state and `forge-cli` only for PR/MR provider operations.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - Execution and review bodies invoke nils-cli primitives instead of inline
    issue/PR state manipulation.
  - Subagent handoff guidance remains prose-level and does not create hidden
    runtime state.
  - Missing surfaces are noted for Task 7.3 to record in the shared extraction
    backlog.
  - No shared manifest or golden files are edited in this task.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 7.3: Wire dispatch manifests, adapters, and golden snapshots

- **Location**:
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `targets/codex/plugins/dispatch/.codex-plugin/plugin.json`
  - `targets/claude/plugins/dispatch/.claude-plugin/plugin.json`
  - `tests/sandbox/claude/expected-skills.txt`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/golden/`
  - `docs/source/extraction-backlog.md`
- **Description**: Register dispatch skills, add product plugin metadata,
  refresh golden snapshots, update sandbox pins, and run the dispatch-domain
  render/sandbox/audit gate.
- **Dependencies**:
  - Task 7.1
  - Task 7.2
- **Complexity**: 5
- **Acceptance criteria**:
  - Dispatch skill entries pin `plan-tooling`, `plan-issue`,
    `plan-issue-local`, and `forge-cli` only where used.
  - Product plugin metadata exists for dispatch.
  - Golden snapshots and sandbox expected skill pins include dispatch skills.
  - Audit-drift reports no dispatch-domain source/render mismatch.
- **Validation**:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `agent-runtime audit-drift`

## Sprint 8: Overlay Gates

**Goal**: Verify `.private` shadow overlays and project-local overlay shims
after all migrated domains render.

**Demo/Validation**:

- Commands:
  - `agent-runtime install --product claude --dry-run`
  - `agent-runtime install --product codex --dry-run`
  - `bash tests/projects/project-local-smoke/run.sh`
  - `agent-runtime doctor --check-project tests/projects/project-local-smoke`
  - `bash scripts/ci/all.sh`
- Verify: effective config and project-local dispatch behavior match the
  architecture contract.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

- **TotalComplexity**: 10
- **CriticalPathComplexity**: 10
- **MaxBatchWidth**: 1
- **OverlapHotspots**: Overlay fixtures, expected install output, and sandbox
  pins are serialized because they validate the whole migrated surface.

### Task 8.1: Audit private overlay effective config

- **Location**:
  - `manifests/runtime-roots.yaml`
  - `targets/claude/link-map.yaml`
  - `targets/codex/link-map.yaml`
  - `tests/sandbox/`
  - `drift-audit.allow.yaml`
- **Description**: Verify `.private/runtime-roots.yaml`,
  `.private/link-map.overrides.yaml`, and `profile.recommended.yaml` merge
  semantics through `agent-runtime install --dry-run`. Add durable fixture or
  expected-output coverage only for behavior that should become a repo gate.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Dry-run install output shows the expected post-merge roots, link map, and
    profile behavior for both products.
  - Any overlay drift is recorded as a blocker before project-local smoke work.
  - New expected-output fixtures are added only for stable, non-private values.
- **Validation**:
  - `agent-runtime install --product claude --dry-run`
  - `agent-runtime install --product codex --dry-run`
  - `agent-runtime audit-drift`

### Task 8.2: Verify project-local overlay smoke gate

- **Location**:
  - `tests/projects/project-local-smoke/run.sh`
  - `tests/projects/project-local-smoke/.agents/scripts`
  - `core/skills/meta/bench/SKILL.md.tera`
  - `core/skills/meta/demo/SKILL.md.tera`
  - `core/skills/meta/deploy/SKILL.md.tera`
  - `core/skills/meta/pre-pr/SKILL.md.tera`
  - `core/skills/meta/release/SKILL.md.tera`
  - `core/skills/meta/bootstrap/SKILL.md.tera`
  - `scripts/ci/all.sh`
- **Description**: Add or verify the project-local overlay smoke fixture for
  `bench`, `demo`, `deploy`, `pre-pr`, `release`, and `bootstrap` shims. The
  gate should prove executable project-local scripts are called and missing
  scripts fail with the documented message.
- **Dependencies**:
  - Task 8.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Project-local smoke fixture exits 0.
  - `agent-runtime doctor --check-project` reports expected wired/missing shim
    status for the sample project.
  - `scripts/ci/all.sh` includes the project-local smoke gate only after its
    expected outputs are stable.
- **Validation**:
  - `bash tests/projects/project-local-smoke/run.sh`
  - `agent-runtime doctor --check-project tests/projects/project-local-smoke`
  - `bash scripts/ci/all.sh`

## Sprint 9: Legacy Archive And Local Cutover

**Goal**: Preserve the two legacy repositories as archived records and remove
local legacy pointers only after all migrated surfaces are validated.

**Demo/Validation**:

- Commands:
  - `gh repo view graysurf/agent-kit --json isArchived,name`
  - `gh repo view graysurf/claude-kit --json isArchived,name`
  - `test ! -L "$HOME/.agents"`
  - `state_root="${XDG_STATE_HOME:-$HOME/.local/state}"; if [ -d "$state_root/agent-runtime-kit/claude" ]; then test ! -d "$state_root/claude-kit"; else rg -q 'claude-kit state migration no-op' docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md; fi`
- Verify: both repositories are archived but not deleted, each has a root
  `MOVED.md`, local legacy symlink is gone, and Claude state is present under
  the new runtime-kit state path.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

- **TotalComplexity**: 10
- **CriticalPathComplexity**: 10
- **MaxBatchWidth**: 1
- **OverlapHotspots**: External repo commits, GitHub archive flags, local symlink
  removal, and state migration are intentionally serialized and recorded in the
  execution-state ledger.

### Task 9.1: Prepare legacy repository archive markers

- **Location**:
  - `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`
  - `docs/source/inventory-target-architecture.md`
- **Description**: In the legacy `graysurf/agent-kit` and
  `graysurf/claude-kit` checkouts, add root `MOVED.md` files pointing to
  `https://github.com/graysurf/agent-runtime-kit`, commit them, and record both
  commit hashes in this plan's execution-state ledger.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - Each legacy repo has a committed root `MOVED.md` pointing at
    `graysurf/agent-runtime-kit`.
  - Commit hashes are recorded in the execution-state Session Log.
  - No legacy repository is deleted.
- **Validation**:
  - `git -C "$HOME/.config/agent-kit" log -1 --format=%H -- MOVED.md`
  - `git -C "$HOME/.config/claude" log -1 --format=%H -- MOVED.md`
  - `gh api repos/graysurf/agent-kit/contents/MOVED.md --jq '.download_url' | xargs curl -fsSL | rg 'graysurf/agent-runtime-kit'`
  - `gh api repos/graysurf/claude-kit/contents/MOVED.md --jq '.download_url' | xargs curl -fsSL | rg 'graysurf/agent-runtime-kit'`

### Task 9.2: Archive legacy repositories on GitHub

- **Location**:
  - `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`
- **Description**: Run `gh repo edit graysurf/agent-kit --archived` and
  `gh repo edit graysurf/claude-kit --archived`, then verify the archived flags.
  Record command evidence and JSON verification in the execution-state ledger.
- **Dependencies**:
  - Task 9.1
- **Complexity**: 3
- **Acceptance criteria**:
  - `gh repo view graysurf/agent-kit --json isArchived,name` returns
    `isArchived: true`.
  - `gh repo view graysurf/claude-kit --json isArchived,name` returns
    `isArchived: true`.
  - Neither repository is deleted.
- **Validation**:
  - `gh repo view graysurf/agent-kit --json isArchived,name`
  - `gh repo view graysurf/claude-kit --json isArchived,name`

### Task 9.3: Retire canonical local legacy pointers and migrate Claude state

- **Location**:
  - `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`
  - `docs/source/inventory-target-architecture.md`
- **Description**: Move `$HOME/.codex/AGENTS.md` from the legacy
  `$HOME/.agents/CODEX_AGENTS.md` indirection to the runtime-kit-owned
  `<source_root>/CODEX_AGENTS.md`, stop routing canonical shell/docs/hook
  configuration through `$HOME/.agents`, keep `$HOME/.agents` only as a
  temporary compatibility alias when Codex Desktop skill discovery still needs
  the legacy `agent-kit` checkout, then migrate any
  `$XDG_STATE_HOME/claude-kit/` tree to
  `$XDG_STATE_HOME/agent-runtime-kit/claude/` using a verify-before-remove flow.
- **Dependencies**:
  - Task 9.2
- **Complexity**: 3
- **Acceptance criteria**:
  - `$HOME/.codex/AGENTS.md` resolves to a real
    `<source_root>/CODEX_AGENTS.md` file and no longer routes through
    `$HOME/.agents`.
  - New zsh shells export `AGENT_HOME`, `AGENT_DOCS_HOME`, and
    `PLAN_ISSUE_HOME` to a real path instead of `$HOME/.agents`.
  - Codex managed hook commands point to real hook files and no longer route
    through `$HOME/.agents`.
  - If `$HOME/.agents` exists, it is documented as a compatibility alias and
    resolves to the active docs/skills checkout.
  - Codex app launch environment exports the same real docs/skills checkout for
    `AGENT_HOME`, `AGENT_DOCS_HOME`, and `PLAN_ISSUE_HOME`.
  - If the old Claude state tree existed, the new destination matches it before
    source removal.
  - If the old state tree did not exist, the no-op is recorded.
  - The execution-state Session Log captures paths, timestamp, and verification
    result.
- **Validation**:
  - `readlink "$HOME/.codex/AGENTS.md" | rg '/agent-runtime-kit/CODEX_AGENTS.md$'`
  - `test -f "$(readlink "$HOME/.codex/AGENTS.md")"`
  - `zsh -lc 'test "$AGENT_HOME" = "$HOME/.config/agent-kit" && test "$AGENT_DOCS_HOME" = "$AGENT_HOME" && test "$PLAN_ISSUE_HOME" = "$AGENT_HOME"'`
  - `! rg -n '/Users/[^/]+/\.agents|\$HOME/\.agents' "$HOME/.zshenv" "$HOME/.config/zsh/scripts/_internal/paths.exports.zsh" "$HOME/.codex/config.toml"`
  - `if [ -L "$HOME/.agents" ]; then readlink "$HOME/.agents" | rg '/\.config/agent-kit$'; else test ! -e "$HOME/.agents"; fi`
  - `agent-docs --docs-home "$HOME/.agents" resolve --context startup --strict --format checklist`
  - `launchctl getenv AGENT_HOME | rg '^/Users/[^/]+/\.config/agent-kit$'`
  - `state_root="${XDG_STATE_HOME:-$HOME/.local/state}"; if [ -d "$state_root/agent-runtime-kit/claude" ]; then test ! -d "$state_root/claude-kit"; else rg -q 'claude-kit state migration no-op' docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md; fi`

## Testing Strategy

- Plan bundle: `plan-tooling validate --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --format text --explain`.
- Dispatch grouping: run `for n in 1 2 3 4 5 6 7 8 9; do plan-tooling batches
  --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --sprint
  "$n" --format json; done`, then run each sprint's deterministic split
  command from its scorecard or the per-sprint deterministic command for
  Sprints 4, 5, 6, 8, and 9.
- Render: `agent-runtime render --product codex` and
  `agent-runtime render --product claude` after each source lane.
- Golden: `agent-runtime render --product codex --update-golden` and
  `agent-runtime render --product claude --update-golden` in each integration
  lane, followed by review of `tests/golden/`.
- Sandbox install: `bash scripts/ci/sandbox-install-rehearsal.sh` after each
  domain integration lane.
- Drift: `agent-runtime audit-drift` after each domain integration lane.
- Full repo gate: `bash scripts/ci/all.sh` before closing each sprint.
- External smoke: `bash tests/smoke/deliver-lifecycle.sh --scratch-fork
  graysurf/agent-runtime-kit-smoke --scratch-branch
  agent-runtime-kit-delivery-smoke` only for Sprint 6 and never against the
  canonical repo's `main`.

## Risks & Gotchas

- Meta migration is a dependency multiplier. Preserve `agent-docs`,
  `agent-out`, and `semantic-commit` observable behavior or downstream sprints
  become noisy.
- Same-sprint parallel lanes must not edit shared manifest/golden/sandbox files;
  each sprint has an explicit integration task for those files.
- `tests/golden/` paths are product-rendered snapshots, not skill-source paths.
  Review rendered diffs before committing them.
- Missing nils-cli capability is a release-boundary blocker, not permission to
  restore inline shell/Python.
- Delivery smoke must use a scratch fork/branch. Running a throwaway PR against
  `graysurf/agent-runtime-kit` `main` is prohibited.
- GitHub archival requires admin permission. Verify access before Sprint 9.
- `$HOME/.agents` removal can affect in-flight sessions and Codex Desktop skill
  discovery. Keep it as a compatibility alias until a live Codex session
  confirms the app no longer needs it. Before removal, `$HOME/.codex/AGENTS.md`
  must first point at a real runtime-kit-owned `CODEX_AGENTS.md` source file.
- `.private` overlay values can be machine-specific. Do not commit private
  values; commit only stable fixtures or redacted expected outputs.

## Rollback Plan

- Sprints 1-7: revert the domain's source, manifest, adapter, sandbox, and
  golden changes together. Because shared-file writes are isolated to each
  sprint's integration task, one revert per sprint should restore the previous
  rendered surface.
- Sprint 6 smoke harness: disable or revert the harness if scratch-fork behavior
  is unsafe, but keep delivery skill bodies reverted with the same sprint
  change set.
- Sprint 8 overlays: revert only stable fixture/gate changes. Do not commit or
  preserve `.private` machine-local files.
- Sprint 9 archival: `gh repo edit graysurf/<repo> --no-archived` reverses the
  archive flag. Revert each legacy repo's `MOVED.md` commit if needed.
- Sprint 9 local cutover: point `$HOME/.codex/AGENTS.md` back to
  `$HOME/.config/agent-kit/CODEX_AGENTS.md`, ensure `$HOME/.agents` exists with
  `ln -s "$HOME/.config/agent-kit" "$HOME/.agents"`, and restore Claude state
  from the pre-migration copy if verification failed.
