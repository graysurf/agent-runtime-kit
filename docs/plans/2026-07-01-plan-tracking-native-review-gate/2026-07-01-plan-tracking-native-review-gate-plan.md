# Plan: Align deliver-plan-tracking-issue to deliver-pr's native bot code review

## Overview

`deliver-plan-tracking-issue` delivers a tracking-linked PR through the one-shot
`forge-cli pr deliver` macro, which merges in a single call and leaves no window
for a review gate. As a result its "Review branch" only records a lightweight
review checkpoint (single-author plans could use a self-authored delivery comment
as evidence), so delivered PRs carry no native GitHub review event — unlike
`deliver-pr`, which runs `code-review-pre-merge-gate` and posts native
`COMMENT` + `APPROVE`/`REQUEST_CHANGES` review events plus thread/task sweeps.

This plan aligns the tracking deliver skill to `deliver-pr`'s review mechanism
using **Shape 1**: the skill self-orchestrates the gate and keeps merge control,
splitting `pr deliver` into `--no-merge` → gate → native review events →
thread/task sweeps → issue-side `review` checkpoint → `pr merge`. The proven
template is `review-dispatch-lane-pr`, which already posts native events. No
nils-cli change is required (the pinned `forge-cli 1.20.1` already exposes every
surface). The single-author lightweight review exception is removed. A dispatch
family consistency pass fixes the stale `forge-cli` floor on
`deliver-dispatch-plan`.

## Read First
- Primary source: `docs/plans/2026-07-01-plan-tracking-native-review-gate/2026-07-01-plan-tracking-native-review-gate-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Reference template: `core/skills/dispatch/review-dispatch-lane-pr/SKILL.md.tera` (native-review Entrypoint block)
- Reference contract: `core/skills/pr/deliver-pr/SKILL.md.tera`, `core/skills/code-review/code-review-pre-merge-gate/SKILL.md.tera`, `core/skills/code-review/code-review-specialists/references/REVIEW_OUTCOME_POSTING_CONTRACT.md`
- Open questions carried into execution: whether `plan-issue record audit` hard-requires issue-side `review` evidence pre-merge or only at closeout (Shape 1 does not depend on the answer; the testbed run should record it)

## Scope
- In scope: the `deliver-plan-tracking-issue` review sub-flow rewrite (Shape 1) and its Contract updates; the `deliver-dispatch-plan` floor bump; three-product render + golden refresh; full `scripts/ci/all.sh` + `tests/hooks/run.sh`; a testbed live run.
- Out of scope: any nils-cli change; a separate `review-plan-tracking-pr` skill; changing the shared `role=review` taxonomy; dispatch execution/lane skills beyond the floor bump; historical cleanup passes.

## Assumptions
1. Pinned `forge-cli` (`v1.20.1`) exposes `pr review --submit-review`, `--thread-file`, `pr review-threads`, and `pr tasks`; no coupled nils-cli change is needed.
2. `review-dispatch-lane-pr`'s native-review Entrypoint block is a faithful, adaptable template for the tracking `--profile tracking` context.
3. The host toolchain can be brought on-pin (`agent-runtime` == `v1.20.1`) before the final `scripts/ci/all.sh` version-alignment gate; a local off-pin binary is used only for coupled development, not final validation.
4. A tracking testbed (e.g. `graysurf/plan-tracking-testbed`) is available for the live review-event round trip.

## Sprint 1: Align the tracking deliver review gate
**Goal**: `deliver-plan-tracking-issue` runs the specialist gate and posts native review events before merge, with the issue-side `review` checkpoint sourced from the real outcome.
**Demo/Validation**:
- Command(s): `agent-runtime render --product claude`; `git diff` on the rendered skill; `bash scripts/ci/all.sh` positions 1 + 6
- Verify: the rendered `deliver-plan-tracking-issue` SKILL.md contains the `--submit-review` native-event flow and thread/task sweeps; governance + golden gates pass

### Task 1.1: Update the Contract (floor, prereqs, references, policy)
- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- **Description**: Bump `forge-cli >=1.11.2` → `>=1.17.0`; add `review-specialists` to prereqs; reference `code-review-pre-merge-gate` and `REVIEW_OUTCOME_POSTING_CONTRACT.md`; remove the single-author lightweight-review exception in the Review branch so the full gate is always run.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Contract floor matches the repo pin surface; no single-author self-review exception remains; description stays within the governance char limit
- **Validation**:
  - `bash scripts/ci/skill-governance-audit.sh` (position 1)

### Task 1.2: Rewrite the Entrypoint + Workflow PR/Review steps to Shape 1
- **Location**:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
- **Description**: Replace the one-shot `forge-cli pr deliver` with the Shape 1 sequence — `pr deliver --no-merge` → `code-review-pre-merge-gate` → `forge-cli pr review --submit-review` (per-lens native `COMMENT` with mapped bot profiles + combined `APPROVE`/`REQUEST_CHANGES` as `dobi`, `--thread-file` for actionable findings, `--issue --mirror-issue`) → `pr review-threads` + `pr tasks` sweeps → `tracking run update --review-outcome-comment <native review URL>` → `tracking checkpoint --post state,review` → `forge-cli pr merge`. Adapt `review-dispatch-lane-pr`'s Entrypoint block to `--profile tracking`; keep the skill concise by referencing shared contracts rather than duplicating their bodies. Preserve the existing ready-for-close / close-ready / no-close handoff steps.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 5
- **Acceptance criteria**:
  - Entrypoint and Workflow describe the split delivery with native review events and both sweeps; the issue-side `review` checkpoint is posted before merge; closeout still routes to `plan-tracking-issue-closeout`
- **Validation**:
  - Manual read-through against `review-dispatch-lane-pr` + `deliver-pr`; canonical H2 section shape intact (position 1)

### Task 1.3: Render three products + refresh goldens
- **Location**:
  - `build/codex/plugins/dispatch/skills/deliver-plan-tracking-issue/SKILL.md`
  - `build/claude/plugins/dispatch/skills/deliver-plan-tracking-issue/SKILL.md`
  - `build/hermes/plugins/dispatch/skills/deliver-plan-tracking-issue/SKILL.md`
  - `tests/golden/codex/plugins/dispatch/skills/deliver-plan-tracking-issue/expected/SKILL.md`
  - `tests/golden/claude/plugins/dispatch/skills/deliver-plan-tracking-issue/expected/SKILL.md`
  - `tests/golden/hermes/plugins/dispatch/skills/deliver-plan-tracking-issue/expected/SKILL.md`
- **Description**: Re-render the affected skill into all three product trees and refresh goldens. The source has no `product ==` conditionals, so all three variants are identical.
- **Dependencies**:
  - Task 1.2
- **Acceptance criteria**:
  - `git diff --exit-code -- tests/golden/` is clean after `--update-golden`
- **Validation**:
  - `agent-runtime render --product {codex,claude,hermes} --update-golden`; `git diff --exit-code -- tests/golden/`

## Sprint 2: Dispatch-family consistency + full validation
**Goal**: The dispatch family stays floor-consistent and the whole change passes the declared gate, with the native-review round trip proven live.
**Demo/Validation**:
- Command(s): `bash scripts/ci/all.sh && bash tests/hooks/run.sh`; a testbed `deliver-plan-tracking-issue` run
- Verify: full gate green on-pin; the delivered testbed PR carries a native `APPROVE` review event whose URL is recorded in the tracking `review` checkpoint and accepted by `close-ready`

### Task 2.1: Bump the deliver-dispatch-plan forge-cli floor
- **Location**:
  - `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  - `build/codex/plugins/dispatch/skills/deliver-dispatch-plan/SKILL.md`
  - `build/claude/plugins/dispatch/skills/deliver-dispatch-plan/SKILL.md`
  - `build/hermes/plugins/dispatch/skills/deliver-dispatch-plan/SKILL.md`
  - `tests/golden/codex/plugins/dispatch/skills/deliver-dispatch-plan/expected/SKILL.md`
  - `tests/golden/claude/plugins/dispatch/skills/deliver-dispatch-plan/expected/SKILL.md`
  - `tests/golden/hermes/plugins/dispatch/skills/deliver-dispatch-plan/expected/SKILL.md`
- **Description**: Bump `forge-cli >=1.11.2` → `>=1.17.0` for consistency with `review-dispatch-lane-pr` and the repo pin. Behavior is unchanged (it delegates review to `review-dispatch-lane-pr`). Re-render + refresh goldens.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - Floor matches the pin surface; golden diff clean after re-render
- **Validation**:
  - `agent-runtime render --product {codex,claude,hermes} --update-golden`; `git diff --exit-code -- tests/golden/`

### Task 2.2: Full declared validation
- **Location**:
  - repo-wide
- **Description**: Bring the host on-pin (`agent-runtime` == `v1.20.1`) if needed, then run the repository's declared validation.
- **Dependencies**:
  - Task 1.3, Task 2.1
- **Acceptance criteria**:
  - `bash scripts/ci/all.sh` (all positions, incl. version-alignment at position 2) and `bash tests/hooks/run.sh` are green
- **Validation**:
  - `bash scripts/ci/all.sh && bash tests/hooks/run.sh`

### Task 2.3: Testbed live review-event round trip
- **Location**:
  - `graysurf/plan-tracking-testbed` (or an equivalent tracking testbed)
- **Description**: Deliver a trivial tracking-linked PR through the aligned skill against the testbed. Confirm the PR carries native specialist `COMMENT` events and a combined native `APPROVE`/`REQUEST_CHANGES` event, that the native review URL is recorded via `tracking run update --review-outcome-comment`, and that `tracking close-ready` accepts it. Observe and record whether `record audit` required issue-side `review` evidence pre-merge (settles the Shape 2 viability question).
- **Dependencies**:
  - Task 2.2
- **Acceptance criteria**:
  - A testbed PR shows native review events in its Reviews section; `close-ready` returns `ready: true` with the native review URL as review evidence; the `record audit` ordering observation is recorded in the execution-state Validation Log
- **Validation**:
  - Live testbed `deliver-plan-tracking-issue` run; provider read-back of `reviews[]` and the tracking `review` checkpoint

## Testing Strategy
- Governance/shape: `scripts/ci/skill-governance-audit.sh` (H2 sections, description limit).
- Render regression: `agent-runtime render --product {codex,claude,hermes} --update-golden` + `git diff --exit-code -- tests/golden/`.
- Full gate: `scripts/ci/all.sh` (incl. version-alignment, drift, product-leak) + `tests/hooks/run.sh`.
- E2E/manual: testbed live delivery proving the native review event round trip into `close-ready`.

## Risks & gotchas
- Host toolchain is off-pin at authoring time (`plan-tooling 1.20.3` vs pin `v1.20.1`); the position-2 version-alignment gate blocks on any deviation, so the host must be brought on-pin before final `scripts/ci/all.sh` (see DEVELOPMENT.md).
- Keeping the skill concise: reference the shared review contracts instead of duplicating `deliver-pr` / `review-dispatch-lane-pr` bodies, or the lightweight family's skill bloats and forks logic.
- Do not let the review sub-flow reintroduce a `forge-cli pr merge` that races the issue-side `review` checkpoint — the checkpoint must be posted before merge.
- Golden files are generated; never hand-edit them — always re-render with `--update-golden`.

## Rollback plan
- The change is confined to two `.tera` sources plus their rendered targets/goldens. Reverting the branch restores the one-shot `pr deliver` behavior and the prior floors; no provider state or nils-cli surface is affected.
