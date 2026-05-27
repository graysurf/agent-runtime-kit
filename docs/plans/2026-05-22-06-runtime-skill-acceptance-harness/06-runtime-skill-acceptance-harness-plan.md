# Plan: Runtime Skill Acceptance Harness

## Overview

Build the missing acceptance layer for `agent-runtime-kit` skills before
continuing Plan 05 beyond Sprint 4. The plan adds an isolated runtime smoke
environment, an explicit acceptance matrix for the currently migrated skills,
deterministic command-level probes, and a product-in-the-loop lane that is
enabled only when Codex or Claude can run safely against temporary runtime
homes.

The work is allowed to fix small repo defects discovered by the new tests while
executing this plan. Major runtime-design breaks must stop for user
confirmation before changing architecture.

## Read First

- Primary source: docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Whether product-in-the-loop smoke can be stable enough for CI. Default: deterministic smoke is blocking; product smoke starts manual/quarantined.
  - Whether failed cases should preserve committed reports. Default: runtime reports go to `agent-out`; committed fixtures hold expected outputs only.
  - Whether Plan 05 Sprint 5 should require every Sprint 1-4 skill to pass. Default: every skill needs deterministic pass or explicit host-capability skip.

## Scope

- In scope:
  - Add `tests/runtime-smoke/` with fixture workspaces, setup helpers,
    acceptance matrix, expected outputs, and runner scripts.
  - Validate both temporary Codex and Claude runtime homes through
    `agent-runtime install --apply` and `agent-runtime doctor`.
  - Add deterministic acceptance probes for the Plan 05 Sprint 1-4 skills:
    meta, media, browser, and evidence.
  - Keep reporting skills in the matrix as regression coverage.
  - Add result classification and a machine-readable summary.
  - Wire the stable deterministic runner into `scripts/ci/all.sh`.
  - Update `DEVELOPMENT.md` with the new acceptance commands.
  - Fix small repo bugs found by the harness during execution.
- Out of scope:
  - Continuing Plan 05 Sprint 5+ migration.
  - Touching real `$HOME/.codex` or `$HOME/.claude`.
  - Making default CI depend on network, credentials, screenshots, desktop
    permissions, or product session history.
  - Adding new nils-cli binary behavior inside this repo.
  - Treating product-in-the-loop flakes as blocking until the invocation
    contract is stable.

## Assumptions

1. `agent-runtime`, `plan-tooling`, and the Sprint 1-4 nils-cli binaries are
   available through the released Homebrew `nils-cli` install.
2. Temporary `live_home` and `state_home` paths are sufficient to validate
   install and doctor behavior without touching real runtime homes.
3. Deterministic command-level probes can validate the skill contract for most
   migrated skills, even when full LLM product invocation is not stable.
4. Host-sensitive skills such as `screen-record` may need a
   `skip-host-capability` result on CI while still requiring a local manual
   acceptance path.
5. Small repo fixes discovered while running the harness are within this
   plan's implementation scope.

## Sprint 1: Acceptance Harness Foundation

**Goal**: Add the committed test structure, fixture workspace, acceptance
matrix schema, and install/doctor smoke mode without yet asserting every skill
case.

**Demo/Validation**:

- Commands:
  - `bash tests/runtime-smoke/run.sh --mode install`
  - `bash tests/runtime-smoke/run.sh --mode matrix`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
- Verify: the harness creates temporary product homes, installs current
  rendered surfaces with `--apply`, runs doctor with no block findings, validates
  matrix shape, and cleans up temp files.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 1.1: Define acceptance matrix contract

- **Location**:
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `tests/runtime-smoke/README.md`
  - `docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-execution-state.md`
- **Description**: Define the matrix fields, result dispositions, and initial
  rows for all currently migrated skills. Include product, domain, skill id,
  mode, fixture workspace, command or prompt, expected exit code, expected
  artifacts, and skip policy.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - Matrix contains all 16 Plan 05 Sprint 1-4 skills plus the three reporting
    regression skills.
  - Each row has an explicit deterministic or host-capability disposition path.
  - Matrix validation fails on missing required fields or unknown skill ids.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode matrix`

### Task 1.2: Add isolated fixture workspace and temp runtime setup

- **Location**:
  - `tests/runtime-smoke/workspaces/basic-repo/README.md`
  - `tests/runtime-smoke/lib/runtime-home.sh`
  - `tests/runtime-smoke/run.sh`
- **Description**: Add a minimal committed workspace and Bash helpers that
  allocate temp roots, create product `live_home` and `state_home` paths, run
  `agent-runtime install --apply`, run `agent-runtime doctor`, and clean up
  without touching real runtime homes.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - Running install mode creates both Codex and Claude temporary homes.
  - Installed skill file count matches `tests/sandbox/<product>/expected-skills.txt`.
  - Doctor reports no block findings for both products.
  - Cleanup removes temp homes unless an explicit keep-artifacts flag is used.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode install`

### Task 1.3: Add result summary and artifact policy

- **Location**:
  - `tests/runtime-smoke/lib/results.sh`
  - `tests/runtime-smoke/expected/install-summary.json`
  - `DEVELOPMENT.md`
- **Description**: Implement a stable result summary format and document where
  manual run artifacts go. Keep committed expected outputs small and deterministic;
  write full run artifacts to `agent-out` or a caller-supplied temp directory.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Runner emits a machine-readable summary with `pass`, `fail`,
    `skip-host-capability`, and `blocked-design` counts.
  - `DEVELOPMENT.md` documents install and deterministic smoke commands.
  - No run-specific timestamps or temp paths are committed as expected output.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode install --format json`

## Sprint 2: Deterministic Skill Acceptance

**Goal**: Add CI-friendly probes for the currently migrated skills and use the
feedback loop to fix small repo defects discovered by those probes.

**Demo/Validation**:

- Commands:
  - `bash tests/runtime-smoke/run.sh --mode deterministic`
  - `bash scripts/ci/all.sh`
- Verify: every Sprint 1-4 skill has a deterministic pass or a documented
  `skip-host-capability`; failures either get fixed directly or become explicit
  blockers.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 2.1: Add meta skill probes

- **Location**:
  - `tests/runtime-smoke/cases/meta/run.sh`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `core/skills/meta/`
  - `manifests/skills.yaml`
- **Description**: Add deterministic probes for `agent-docs`, `agent-out`,
  `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, and `semantic-commit`.
  Fix small repo issues found by the probes, such as stale command examples,
  missing required CLI pins, or unclear temp-output guidance.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 6
- **Acceptance criteria**:
  - All meta probes run inside the fixture workspace.
  - Outputs are confined to temp output directories or fixture-local scratch.
  - `semantic-commit` probe uses validate/dry-run behavior and never creates a
    real commit in the fixture unless the fixture is intentionally isolated.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`

### Task 2.2: Add media and browser probes

- **Location**:
  - `tests/runtime-smoke/cases/media/run.sh`
  - `tests/runtime-smoke/cases/browser/run.sh`
  - `tests/runtime-smoke/fixtures/sample.svg`
  - `core/skills/media/`
  - `core/skills/browser/`
- **Description**: Add safe probes for `image-processing`, `screen-record`,
  `browser-session`, and `canary-check`. Use tiny committed fixtures for image
  conversion and command canaries. Treat desktop permission requirements as
  host-capability skips, not silent passes.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 6
- **Acceptance criteria**:
  - `image-processing` validates a local sample conversion or probe without
    network access.
  - `canary-check` records a passing canary for a trivial command and a failing
    canary for a controlled non-zero command.
  - `browser-session` can initialize or validate a local session record without
    browser network access.
  - `screen-record` has a clear pass or `skip-host-capability` path based on
    host permissions.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain media`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser`

### Task 2.3: Add evidence probes

- **Location**:
  - `tests/runtime-smoke/cases/evidence/run.sh`
  - `tests/runtime-smoke/workspaces/basic-repo/README.md`
  - `core/skills/evidence/`
  - `docs/source/extraction-backlog.md`
- **Description**: Add deterministic probes for `web-evidence`,
  `test-first-evidence`, `review-evidence`, `skill-usage`, `docs-impact`, and
  `model-cross-check`. Prefer local files and no-network checks. Log missing
  nils-cli capability surfaces as blockers instead of inventing inline logic.
- **Dependencies**:
  - Task 1.3
- **Complexity**: 7
- **Acceptance criteria**:
  - Each evidence probe emits a valid record or validated no-op result.
  - `skill-usage verify` passes for the generated invocation record.
  - `docs-impact` can classify a controlled fixture diff or report a stable
    no-impact result.
  - `model-cross-check` records provider-boundary metadata without requiring a
    live provider call in default CI.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence`

### Task 2.4: Add reporting regression probes and CI wiring

- **Location**:
  - `tests/runtime-smoke/cases/reporting/run.sh`
  - `core/skills/reporting/`
  - `scripts/ci/all.sh`
  - `DEVELOPMENT.md`
- **Description**: Keep the Plan 03 reporting skills in the runtime smoke
  matrix and wire the stable deterministic runner into CI after expected outputs
  stop changing. Use offline/sample modes where available.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
  - Task 2.3
- **Complexity**: 4
- **Acceptance criteria**:
  - Reporting regression probes pass without network access or are explicitly
    classified as manual/network-only.
  - `scripts/ci/all.sh` runs the deterministic smoke gate after sandbox install
    rehearsal.
  - Full CI passes with the new gate enabled.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic`
  - `bash scripts/ci/all.sh`

## Sprint 3: Product-In-The-Loop Acceptance

**Goal**: Determine whether Codex and Claude can safely run against temporary
runtime homes and add quarantined product smoke tests for representative
skills.

**Demo/Validation**:

- Commands:
  - `bash tests/runtime-smoke/run.sh --mode product --product claude`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex`
- Verify: product smoke either proves a safe invocation path or records a
  `blocked-design` finding with the exact missing runtime contract.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Probe product CLI isolation contracts

- **Location**:
  - `tests/runtime-smoke/product/run.sh`
  - `docs/source/inventory-target-architecture.md`
  - `docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-execution-state.md`
- **Description**: Verify whether current `codex` and `claude` CLIs can run in
  non-interactive mode against temporary runtime homes without reading real
  auth, sessions, or runtime state. Record the exact flags, environment
  variables, and limitations.
- **Dependencies**:
  - Task 2.4
- **Complexity**: 5
- **Acceptance criteria**:
  - Each product has one of: `supported`, `manual-only`, or `blocked-design`.
  - Any unsupported isolation requirement is recorded with exact CLI evidence.
  - No test reads or mutates real runtime homes.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`

### Task 3.2: Add representative product smoke cases

- **Location**:
  - `tests/runtime-smoke/product/prompts/agent-docs.txt`
  - `tests/runtime-smoke/product/expected/product-summary.json`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
- **Description**: Add tiny product-agent prompts for representative skills:
  `agent-docs`, `agent-out`, `canary-check`, `skill-usage`, and `docs-impact`.
  Keep these tests quarantined until they are stable enough for CI.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Product prompts are deterministic enough to classify whether the intended
    skill path was used.
  - Tests are skipped with a clear reason when product isolation is unsupported.
  - No network or credential-dependent prompt is part of default CI.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode product --product claude`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex`

### Task 3.3: Update architecture and Plan 05 unblock rule

- **Location**:
  - `docs/source/inventory-target-architecture.md`
  - `docs/plans/2026-05-20-05-domain-migration/05-domain-migration-execution-state.md`
  - `docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-execution-state.md`
- **Description**: Update architecture docs to reflect the real acceptance
  strength now available, then mark the Plan 05 Sprint 5 continuation rule:
  deterministic acceptance must be green or explicitly skipped for every
  Sprint 1-4 skill before continuing migration.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 3
- **Acceptance criteria**:
  - Architecture no longer claims full execute-and-assert is out of scope if
    the harness has landed.
  - Plan 05 execution state records the Plan 06 acceptance dependency.
  - Any product-in-the-loop gaps are documented as design blockers or manual
    checks.
- **Validation**:
  - `plan-tooling validate --file docs/plans/2026-05-20-05-domain-migration/05-domain-migration-plan.md --format text --explain`
  - `plan-tooling validate --file docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --format text --explain`

## Testing Strategy

- Plan validation:
  - `plan-tooling validate --file docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --format text --explain`
- Grouping:
  - `for n in 1 2 3; do plan-tooling batches --file docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --sprint "$n" --format json; done`
  - `plan-tooling split-prs --file docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --scope sprint --sprint 1 --strategy deterministic --pr-grouping group --pr-group 'Task 1.1=s1-matrix' --pr-group 'Task 1.2=s1-runtime-setup' --pr-group 'Task 1.3=s1-results' --format json`
  - `plan-tooling split-prs --file docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --scope sprint --sprint 2 --strategy deterministic --pr-grouping group --pr-group 'Task 2.1=s2-meta' --pr-group 'Task 2.2=s2-media-browser' --pr-group 'Task 2.3=s2-evidence' --pr-group 'Task 2.4=s2-ci' --format json`
  - `plan-tooling split-prs --file docs/plans/2026-05-22-06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --scope sprint --sprint 3 --strategy deterministic --pr-grouping per-sprint --format json`
- Harness gates:
  - `bash tests/runtime-smoke/run.sh --mode matrix`
  - `bash tests/runtime-smoke/run.sh --mode install`
  - `bash tests/runtime-smoke/run.sh --mode deterministic`
  - `bash scripts/ci/all.sh`
- Optional product gates:
  - `bash tests/runtime-smoke/run.sh --mode product --product claude`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex`

## Runtime Finding Policy

- Fix directly during execution:
  - missing fixture files, broken symlinks, wrong expected outputs, non-portable
    paths, missing executable bits, stale render-golden snapshots, incorrect
    `required_clis`, link-map mistakes, small unclear skill instructions, and
    script bugs that stay within the current architecture.
- Escalate to the user before changing:
  - product runtime isolation is impossible without real home mutation,
    current Codex/Claude activation surfaces are wrong, a whole domain's skill
    pattern is unusable, default CI would require credentials or network, or a
    missing nils-cli primitive needs a new cross-repo release.

## Risks & Gotchas

- Product CLIs may not support isolated runtime homes. Keep deterministic smoke
  as the blocking gate and classify product smoke separately until stable.
- Host-sensitive skills can fail due to permissions rather than repo defects.
  Classify those as `skip-host-capability` only when the skip condition is
  explicit and testable.
- Some skill bodies are judgment/prose surfaces, not pure scripts. Acceptance
  should verify their deterministic command contract and representative product
  behavior, not try to prove every possible agent judgment.
- The harness must not touch real auth, history, sessions, caches, or live
  runtime homes.
- CI expected outputs must not include temp paths, wall-clock timestamps, random
  IDs, or host-specific absolute paths.
- Fixing repo bugs during Plan 06 is allowed, but cross-repo nils-cli behavior
  changes need their own nils-cli issue/PR/release path.

## Rollback Plan

- Remove `tests/runtime-smoke/` and the `scripts/ci/all.sh` gate addition to
  return CI to the previous render/golden/audit/sandbox gate stack.
- Revert any skill-body, manifest, link-map, or docs changes that were made only
  to satisfy invalid harness assumptions.
- Keep valid bug fixes if the harness exposed a real existing defect and the fix
  is independently justified by existing render/audit/sandbox gates.
- If product-in-the-loop tests are flaky, leave deterministic smoke in place and
  remove only the product smoke CI integration.
