# Plan: nils-cli Version Alignment Adoption — Pin Gate + Bump Skill

## Overview

Land the two downstream pieces of the nils-cli version-alignment program
that nils-cli `v0.28.0` unblocked: (1) adopt the released
`agent-runtime doctor --class version-alignment` class as this repo's
surface-pin CI gate (Step 2 consumer), replacing the hand-rolled shell +
python floor compare; (2) add the `meta:nils-cli-bump` skill (Step 3) that
drives one release-bump PR. The human-readable surface snapshot and the CI
gate stack are preserved in shape; only the Position 2 mechanism, the pin
source, and the new skill surface change.

## Read First

- Primary source: docs/plans/2026-05-29-nils-cli-version-alignment-adoption/2026-05-29-nils-cli-version-alignment-adoption-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution: none

## Scope

- In scope:
  - New machine-readable pin manifest `docs/source/nils-cli-pin.yaml`.
  - Collapse `scripts/ci/all.sh` Position 2 to the version-alignment
    doctor class (exact-equality drift semantics).
  - Refresh `docs/source/nils-cli-surface.md` v0.25.8 -> v0.28.0 and the
    `DEVELOPMENT.md` Position 2 description.
  - Add the `meta:nils-cli-bump` skill with full surface coverage
    (manifests, product renders + goldens, sandbox lists, link-map,
    runtime-smoke probe).
- Out of scope:
  - Implementing the doctor class itself (upstream, shipped in
    sympoies/nils-cli#636 / v0.28.0; tracker sympoies/nils-cli#462).
  - Any executable bump (running `meta:nils-cli-bump` to bump beyond
    v0.28.0); the skill is the tool, not its first non-trivial run.
  - SUPPORT_MATRIX.md (generated; no consumed product surface changed).

## Assumptions

1. The host `agent-runtime` is on `v0.28.0`, so the exact-equality gate
   passes against the freshly-bumped pin.
2. nils-cli ships every crate in lock-step, so the exact `pinned_tag` is
   the primary gate and `required_clis[]` floors are a partial-release
   guard.
3. The shipped `version-alignment` envelope (`exit 2` on block,
   `version_alignment` report field) is stable for the CI wrapper.

## Sprint 1: Adopt the version-alignment doctor-class pin gate

**Goal**: Position 2 delegates to the released doctor class and blocks on
any host drift from the exact pin; the surface snapshot reads v0.28.0.

**Demo/Validation**:

- Command(s): `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml --format text`; `bash scripts/ci/all.sh`.
- Verify: Position 2 reports aligned (block=0); a drifted pin blocks (exit 2).

### Task 1.1: Add the machine-readable pin manifest

- **Location**:
  - `docs/source/nils-cli-pin.yaml`
- **Description**: Author the pin manifest with `schema_version: 1`,
  `nils_cli.pinned_tag: v0.28.0`, and `required_clis[]` floors tracking the
  documented surface-introduction versions in the snapshot doc.
- **Dependencies**:
  - none
- **Complexity**: 2
- **Acceptance criteria**:
  - `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml` returns block=0 on the v0.28.0 host.
- **Validation**:
  - Run the doctor class against the manifest; expect exit 0.

### Task 1.2: Collapse Position 2 to the doctor class

- **Location**:
  - `scripts/ci/all.sh`
- **Description**: Replace the shell + python floor compare with a thin
  exit-code wrapper around `agent-runtime doctor --class
  version-alignment --pin docs/source/nils-cli-pin.yaml --format text`,
  keeping the remediation banner. Document the deliberate floor ->
  exact semantics change inline.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 3
- **Acceptance criteria**:
  - `bash scripts/ci/all.sh` Position 2 passes on the aligned host;
    `shellcheck` + `shfmt -i 2` clean.
- **Validation**:
  - `bash scripts/ci/all.sh`; `shellcheck scripts/ci/all.sh`.

### Task 1.3: Refresh the surface snapshot and DEVELOPMENT.md

- **Location**:
  - `docs/source/nils-cli-surface.md`
  - `DEVELOPMENT.md`
- **Description**: Bump the snapshot header v0.25.8 -> v0.28.0, add the
  `nils-build-info` and `nils-markdown` crate rows, note the
  version-alignment / build-metadata `agent-runtime` surface, and rewrite
  the Position 2 description for the exact-equality gate.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `rumdl check` clean on both files; `agent-runtime audit-drift` clean.
- **Validation**:
  - `rumdl check docs/source/nils-cli-surface.md DEVELOPMENT.md`.

## Sprint 2: Add the meta:nils-cli-bump skill (Step 3)

**Goal**: A repo-owned skill that drives one release-bump PR using the
doctor class and the GitHub compare API, with full governance + smoke
coverage.

**Demo/Validation**:

- Command(s): `bash scripts/ci/skill-governance-audit.sh`; `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`.
- Verify: repo OK skills=64; meta domain 24/24 incl. `meta.nils-cli-bump`.

### Task 2.1: Author the skill body and wire manifests

- **Location**:
  - `core/skills/meta/nils-cli-bump/SKILL.md.tera`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
- **Description**: Write the SKILL body (Contract / Entrypoint / Workflow
  / Boundary / Related Skills) and add the skill manifest entry
  (`required_clis` agent-runtime >=0.28.0, forge-cli >=0.20.0) plus plugin
  containment.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `skill-governance-audit.sh` body-shape check passes.
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh`.

### Task 2.2: Render surfaces and acceptance coverage

- **Location**:
  - `tests/golden/codex/plugins/meta/skills/nils-cli-bump/expected/SKILL.md`
  - `tests/golden/claude/plugins/meta/skills/nils-cli-bump/expected/SKILL.md`
  - `tests/sandbox/codex/expected-skills.txt`
  - `tests/sandbox/claude/expected-skills.txt`
  - `targets/codex/link-map.yaml`
  - `tests/runtime-smoke/acceptance-matrix.yaml`
  - `tests/runtime-smoke/cases/meta/run.sh`
- **Description**: Render both products with `--update-golden`, add the
  skill to both sandbox expected lists and the codex link-map, and add a
  deterministic runtime-smoke matrix row + probe exercising the
  version-alignment drift and aligned paths.
- **Dependencies**:
  - Task 2.1
- **Complexity**: 4
- **Acceptance criteria**:
  - `skill-governance-audit.sh` repo OK; meta smoke 24/24.
- **Validation**:
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`.

### Task 2.3: Full CI gate and PR delivery

- **Location**:
  - `scripts/ci/all.sh`
- **Description**: Run the full gate, commit via `semantic-commit`
  (signed, no co-author trailer), and deliver one draft PR via
  `forge-cli pr create --kind feature`.
- **Dependencies**:
  - Task 1.2
  - Task 1.3
  - Task 2.2
- **Complexity**: 2
- **Acceptance criteria**:
  - `bash scripts/ci/all.sh` positions 1-13 OK; provider CI green.
- **Validation**:
  - `bash scripts/ci/all.sh`; `gh pr checks` green on the PR.

## Testing Strategy

- Unit: not applicable (no Rust changes in this repo; the doctor class is
  upstream-tested in sympoies/nils-cli).
- Integration: `scripts/ci/all.sh` positions 1-13 (gate, render, golden,
  drift, surfaces, skill-surface shape, sandbox, runtime-smoke, hooks).
- E2E/manual: drift + aligned doctor probes via the new meta runtime-smoke
  case; provider CI on the PR.

## Risks & gotchas

- The exact-equality gate reddens CI on every host advance until a pin
  bump lands — by design; the `meta:nils-cli-bump` skill is the
  remediation path.
- Position 6 golden diff requires the rendered goldens to be staged before
  `scripts/ci/all.sh`.
- Adding a skill bumps the doctor skill-surface check count; Position 9 is
  a floor (`>= SHAPE_EXPECTED_MIN_CHECKS=72`), so no bump needed.

## Rollback plan

- Revert the single delivery commit. The doctor class remains available in
  the host binary; reverting only restores the prior floor gate and removes
  the skill surface (governance audit would then expect skills=63 again).
