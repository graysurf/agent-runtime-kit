# nils-cli Version Alignment Adoption Implementation Handoff

- Status: implemented and delivered (PR #162); this source is recorded
  retrospectively for the tracking issue.
- Date: 2026-05-29
- Source: user-driven session in `graysurf/agent-runtime-kit`. Trigger:
  confirming whether upstream tracker sympoies/nils-cli#462
  (`feat(doctor): version-alignment class for surface-pin gates`) was
  done. It was — the class shipped in sympoies/nils-cli#636 and released
  in nils-cli v0.28.0 — so #462 was closed, and the user asked to land the
  downstream pieces the release unblocked.
- Intended next step: land Steps 2 and 3 of the version-alignment program
  in one PR, then open this tracking issue via `create-plan-tracking-issue`
  and close it out after the PR merges.

## Execution

This document feeds **one** plan executed as two serial sprints in
`graysurf/agent-runtime-kit`.

- Recommended plan: docs/plans/2026-05-29-nils-cli-version-alignment-adoption/2026-05-29-nils-cli-version-alignment-adoption-plan.md
- Recommended execution state: docs/plans/2026-05-29-nils-cli-version-alignment-adoption/2026-05-29-nils-cli-version-alignment-adoption-execution-state.md
- Status: delivered (PR #162); awaiting merge + closeout
- Next-task source: this document

## Background

The original version-alignment program (archived plan
`2026-05-24-nils-cli-version-alignment`) defined three steps:

1. Step 1 — a shell-level Position 2 gate in `scripts/ci/all.sh` that
   compared `agent-runtime --version` against the snapshot pin. Shipped
   earlier; over time it relaxed to floor semantics (a newer host was
   tolerated).
2. Step 2 — an upstream `agent-runtime doctor --class version-alignment`
   class so the same check runs uniformly and blocks on any drift.
   Tracked at sympoies/nils-cli#462; shipped in sympoies/nils-cli#636 /
   v0.28.0.
3. Step 3 — a downstream `meta:nils-cli-bump` skill that drives one
   release-bump PR. Deferred to its own tracker until Step 2 released.

With Step 2 released, this plan adopts the doctor class (collapsing the
Step 1 shell gate to it, and accepting its exact-equality semantics over
the prior floor tolerance) and ships the Step 3 skill.

## Key decisions

- Adopt **exact-equality** drift semantics (host == pin; any deviation
  blocks), over the prior floor tolerance. Rationale: a silent
  `brew upgrade` past the pin is exactly the drift the
  `plan-issue-v2-marker-collapse-drift` incident was about; forcing a
  conscious pin bump on each host advance is the intended guard.
- Build the `meta:nils-cli-bump` skill in the same change rather than a
  separate follow-up, per the user's request.
- Keep the human-readable surface snapshot as the documentation and make
  `docs/source/nils-cli-pin.yaml` the machine-readable gate pin.
