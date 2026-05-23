# Plan: nils-cli Version Alignment — Step 1 (CI Gate)

## Overview

Land a minimal CI gate in `scripts/ci/all.sh` that compares the host's
`agent-runtime --version` against the pinned tag in
`docs/source/nils-cli-surface.md`. This closes the silent-drift gap that
exists today between PR review of the snapshot doc and what nils-cli
version the CI host actually exercises.

This plan is intentionally scoped to Step 1 of the three-step landing
sequence recorded in the discussion source. Steps 2 (upstream
`agent-runtime doctor --class version-alignment`) and Step 3
(`meta:nils-cli-bump` skill) remain out of scope here and will be opened
as separate trackers after Step 1 lands and exercises against at least
one real bump.

## Read First

- Primary source: docs/plans/nils-cli-version-alignment/nils-cli-version-alignment-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - [Q1] Exact position in `scripts/ci/all.sh` (default in this plan:
    after Position 1 plan-tooling validate, before Position 2 render —
    so downstream gates do not exercise an unaligned binary).
  - [Q2] Whether "host newer than pin" is `warn` or `block` (default in
    this plan: `block`, matching the strictness the snapshot doc
    enforces today through PR review).
  - [Q3] Whether the upstream doctor class should also subsume
    `required_clis` floor probing (deferred until Step 2 plan).

## Scope

- In scope:
  - Add a new banner position in `scripts/ci/all.sh` that reads the
    pinned tag from `docs/source/nils-cli-surface.md` and compares it
    to `agent-runtime --version`. Default placement: between Position 1
    and Position 2.
  - Document the parse regex inline in the gate banner so a contributor
    can reproduce it without reading the script.
  - On mismatch, emit a clear remediation banner with both versions,
    the parse used, and the `brew upgrade sympoies/tap/nils-cli` /
    "refresh the snapshot doc" hint.
  - Update `DEVELOPMENT.md` Position list to include the new gate.
  - Update `SUPPORT_MATRIX.md` "When this matrix needs an update"
    section so the gate's existence is discoverable from the matrix's
    refresh checklist.
- Out of scope:
  - Probing per-binary `required_clis` floors (deferred to Step 2).
  - Implementing the `agent-runtime doctor --class version-alignment`
    upstream class (Step 2, separate plan + upstream nils-cli issue).
  - Writing the `meta:nils-cli-bump` skill (Step 3, separate plan).
  - Auto-bumping the snapshot doc or `required_clis` floors.
  - Adding nils-cli binaries to `manifests/cli-tools.yaml` (would
    contradict its documented exclusion).

## Assumptions

1. `docs/source/nils-cli-surface.md` line 8's `Active git describe
   --tags output:` prefix remains the stable parse anchor for at least
   the next nils-cli minor cycle.
2. `agent-runtime --version` output format remains stable across the
   nils-cli `0.17.x` series (output today: `agent-runtime 0.17.6`).
3. macOS bash 3.2 + `grep` + `sed` is sufficient; no Python or
   nils-cli-side code needed at this step.
4. The gate is deterministic given a fixed `docs/source/nils-cli-surface.md`
   and a fixed `agent-runtime` binary on `PATH`.

## Sprint 1: Add Version-Alignment CI Gate

**Goal**: Ship the shell gate, prove it fails closed on mismatch and
passes on match, and surface its existence in DEVELOPMENT.md +
SUPPORT_MATRIX.md.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Add version-alignment gate to scripts/ci/all.sh

- **Location**:
  - `scripts/ci/all.sh`
- **Description**: Insert a new banner position between the existing
  Position 1 (`plan-tooling validate`) and Position 2
  (`agent-runtime render --product codex`). The gate reads the pinned
  tag from `docs/source/nils-cli-surface.md` by matching lines that
  start with `- Active git describe --tags output:` and extracting the
  backtick-wrapped tag. It then calls `agent-runtime --version`, parses
  the version string, and exits non-zero on mismatch. On failure, the
  gate prints both versions, the matched source line, and a two-line
  remediation block. Renumber the downstream positions accordingly,
  including the comment block headers and the `SHAPE_EXPECTED_MIN_CHECKS`
  reference. Stay inside the file's documented bash 3.2 compatibility
  rules (no associative arrays, no `mapfile`, no `${var,,}`).
- **Dependencies**:
  - none
- **Complexity**: 3
- **Acceptance criteria**:
  - New banner runs after Position 1 and before render gates.
  - On a host whose `agent-runtime --version` matches the pin, the
    gate prints both values and continues; whole CI stack stays green.
  - On a deliberate mismatch (edit pin in a worktree or downgrade
    binary), the gate exits non-zero with both versions visible and
    the remediation banner present.
  - Existing position numbers in banners and comment headers are
    updated consistently throughout the file.
- **Validation**:
  - `bash scripts/ci/all.sh` (expect pass on aligned host).
  - Worktree experiment: `git stash -u && sed -i.bak 's/v0\\.17\\.6/v0.17.99/' docs/source/nils-cli-surface.md && bash scripts/ci/all.sh; echo "exit=$?"; git checkout -- docs/source/nils-cli-surface.md` (expect non-zero exit and remediation banner).

### Task 1.2: Document the new gate in DEVELOPMENT.md and SUPPORT_MATRIX.md

- **Location**:
  - `DEVELOPMENT.md`
  - `SUPPORT_MATRIX.md`
- **Description**: In `DEVELOPMENT.md`, add the new gate position to
  the CI gate position list (currently described around lines
  157-178). In `SUPPORT_MATRIX.md`, add a bullet to the "When this
  matrix needs an update" section noting that the version-alignment
  gate now enforces the surface pin matching the installed binary, so
  out-of-date snapshot docs surface as a CI failure rather than a PR
  review miss.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `DEVELOPMENT.md` lists the new gate with its expected
    pass/fail behaviour.
  - `SUPPORT_MATRIX.md` cross-references the new gate so a future
    contributor reading the refresh checklist knows the gate exists.
  - No other docs (`README.md`, `AGENT_HOME.md`, plan source) drift
    out of sync; cross-references stay accurate.
- **Validation**:
  - `rumdl check DEVELOPMENT.md SUPPORT_MATRIX.md`
  - `agent-runtime audit-drift` (expect clean — these are tracked
    docs, no drift class should trip).

## Issue Closeout Gate

The tracking issue is complete when:

- Task 1.1 and Task 1.2 are landed on `main`.
- The deliberate-mismatch validation experiment in Task 1.1 has been
  run and its output (or a redacted snippet showing the remediation
  banner) is posted as a comment on the issue.
- Full `bash scripts/ci/all.sh` runs green on `main`.
- The issue dashboard links to current validation evidence and the
  state comment shows `validation=passed`, `approval=approved`.

Steps 2 and 3 from the discussion source are explicitly **not**
required for this tracker to close. Each opens its own tracker when
its preconditions are met (Step 2: a real nils-cli bump cycle has
exercised this gate at least once; Step 3: the upstream doctor class
is released).

## Future Work (Out Of Scope For This Tracker)

- **Step 2**: Promote the alignment check to
  `agent-runtime doctor --class version-alignment` upstream in
  `sympoies/nils-cli`. Replace the shell gate in the same PR that
  wires the doctor class in.
- **Step 3**: Land `meta:nils-cli-bump` as a repo-local skill that
  orchestrates `gh release view` + `gh api compare` + agent judgement
  to propose patches across the four artifacts the snapshot doc
  governs (surface doc, README pin row, SUPPORT_MATRIX cells,
  per-skill `required_clis` floors).

Both are tracked in the discussion source as [D4] sequencing.
