# Plan: Review Thread Cleanup Extraction

## Overview

Extract a shared, provider-agnostic `review-thread-cleanup` capability out of
the `symphony-board` `project-review-cleanup` skill: a runtime-kit skill that
owns generic review-thread discovery + the convergence/triage policy, backed by
a new `forge-cli` thread-resolve write surface, with `project-review-cleanup`
reduced to a thin board-discovery adapter.

This is an L2/L3 plan because it spans three repositories
(`sympoies/nils-cli` -> `graysurf/agent-runtime-kit` -> `sympoies/symphony-board`)
and includes one nils-cli release plus a version-pin bump, and needs a state
ledger to prevent scope drift across that surface.

Phase 0 of the larger effort (promoting the convergence discipline into shared
policy) already landed and is out of scope here:

- graysurf/agent-runtime-kit#407 (merged) — `core/policies/review-thread-convergence.md`.
- sympoies/symphony-board#229 (merged) — skill references the policy.

## Read First

- Primary source:
  `docs/plans/2026-06-16-review-thread-cleanup-extraction/2026-06-16-review-thread-cleanup-extraction-discussion-source.md`
- Source type: discussion-to-implementation-doc
- Shared policy (Phase 0 outcome): `core/policies/review-thread-convergence.md`
- Existing generic mechanics: `forge-cli pr review-threads`,
  `forge-cli pr merge` (`unresolved_review_threads` gate).
- Project-local skill to refactor:
  `sympoies/symphony-board` `.agents/skills/project-review-cleanup/`.
- Decisions locked (2026-06-16):
  - Go/No-Go = GO. The user elected to proceed; treat as standalone-merit GO.
  - Sprint 3 discovery = decision B: a first-class `symphony-board`
    `review-candidates` CLI subcommand owns discovery (not `forge-cli`, not the
    bespoke `review-cleanup.mjs`). `forge-cli` gains only the resolve/reply
    write surface and never learns about the board.
- Open questions carried into execution:
  - Whether to ship T3-b (forge-cli write surface) or fall back to T3-a
    (disposition-file handoff with apply staying in the adapter).

## Scope

In scope:

- `forge-cli pr review-threads` (or a sibling) grows a provider-aware
  resolve/reply write surface, fail-closed, honoring an allowlist.
- A new runtime-kit shared `review-thread-cleanup` skill embedding the
  convergence/triage policy and wrapping the read + write forge-cli surfaces.
- Refactor `project-review-cleanup` into a board-discovery adapter that feeds
  the shared skill and drops its duplicated GraphQL mutation.

Out of scope:

- The Phase 0 policy and inbox archival (already merged).
- GitLab thread resolution beyond what `forge-cli` already abstracts, except as
  a follow-up once the GitHub write surface ships.
- Any change to the board contract, store, or which-repos-to-sync data domain.

## Assumptions

1. T3-b (forge-cli write surface) is the target shape; T3-a (disposition-file
   handoff, apply stays in the adapter) is the documented de-scope lever.
2. The nils-cli release + agent-runtime-kit pin-bump ceremony from the
   `nils-cli-bump` / release skills applies for Sprint 1.
3. GitHub is the provider for this tracking issue, so both `workflow::plan` and
   `workflow::tracking` labels apply.
4. The shared skill is created through `create-skill` (source + manifests +
   render Codex/Claude + acceptance + governance), not hand-authored.

## Sprint 0: Go/No-Go

**Goal**: Confirm T3 is still warranted before any implementation.

### Task 0.1: Confirm second consumer or standalone merit

- **Location**:
  - `docs/plans/2026-06-16-review-thread-cleanup-extraction/`
- **Description**: Re-confirm a real second consumer of the discovery mechanics
  beyond `symphony-board`, or that the forge-cli write surface stands on its own
  merit. Phase 0 already closed the inbox gap, so this gate decides whether T3
  proceeds at all.
- **Dependencies**:
  - none
- **Acceptance criteria**:
  - A recorded go/no-go decision with its rationale in the execution state.
  - If no-go, the plan is held and remaining tasks stay pending.
- **Validation**:
  - Decision and rationale captured in the execution-state task ledger.

## Sprint 1: forge-cli thread-resolve write surface (nils-cli)

**Goal**: A released `forge-cli` surface can resolve and reply to a review
thread, provider-aware and fail-closed.

### Task 1.1: Design the resolve/reply surface

- **Location**:
  - `sympoies/nils-cli` (forge-cli crate)
- **Description**: Define the subcommand shape, allowlist/safety semantics, and
  GitHub-first provider behavior for resolving and replying to review threads;
  capture failing-test evidence per the global test-first gate.
- **Dependencies**:
  - Task 0.1
- **Acceptance criteria**:
  - A written surface design (argv, safety/allowlist rules, provider matrix).
  - A failing test demonstrating the missing write behavior.
- **Validation**:
  - `test-first-evidence` record with the failing test captured first.

### Task 1.2: Implement and deliver in nils-cli

- **Location**:
  - `sympoies/nils-cli` (forge-cli crate)
- **Description**: Implement and test the resolve/reply surface in nils-cli and
  deliver the PR.
- **Dependencies**:
  - Task 1.1
- **Acceptance criteria**:
  - The new surface resolves/replies safely and fails closed on unsafe threads.
  - PR delivered with green CI.
- **Validation**:
  - nils-cli crate tests for the new surface; `gh pr checks` green.

### Task 1.3: Release and bump the pin

- **Location**:
  - `sympoies/nils-cli`, `sympoies/homebrew-tap`, `graysurf/agent-runtime-kit`
- **Description**: Release nils-cli, update the tap/brew, and bump the
  agent-runtime-kit version pin via `nils-cli-bump`.
- **Dependencies**:
  - Task 1.2
- **Acceptance criteria**:
  - New nils-cli release is installed and the version-pin gate passes.
- **Validation**:
  - `agent-runtime doctor --class version-alignment`; `bash scripts/ci/all.sh`.

## Sprint 2: shared review-thread-cleanup skill (agent-runtime-kit)

**Goal**: A runtime-kit shared skill owns generic discovery + the policy.

### Task 2.1: Scaffold the shared skill

- **Location**:
  - `core/skills/`
- **Description**: Scaffold a shared `review-thread-cleanup` skill via
  `create-skill`; embed the `review-thread-convergence.md` policy and wrap
  `pr review-threads` (read) plus the new write surface.
- **Dependencies**:
  - Task 1.3
- **Acceptance criteria**:
  - Skill source exists with manifests and renders for Codex and Claude.
  - The skill references the convergence policy as its judgment contract.
- **Validation**:
  - `agent-runtime render --product codex|claude`;
    `bash scripts/ci/skill-governance-audit.sh`.

### Task 2.2: Cover and gate

- **Location**:
  - `graysurf/agent-runtime-kit`
- **Description**: Add acceptance coverage for the shared skill and pass the
  full kit gate stack.
- **Dependencies**:
  - Task 2.1
- **Acceptance criteria**:
  - Acceptance coverage exists and passes; full CI is green.
- **Validation**:
  - `bash scripts/ci/all.sh`; `bash tests/hooks/run.sh`.

## Sprint 3: board review-candidates CLI (symphony-board)

**Goal**: Promote discovery into a first-class `symphony-board` CLI subcommand
(decision B) and retire the bespoke `review-cleanup.mjs` discovery path.
`forge-cli` stays provider-agnostic and never learns about the board; discovery
is owned by the board, which owns the data.

Sprint 3 splits into an independent lane (Task 3.1, depends only on the board's
own store/contract) and an integration lane (Task 3.2, depends on Sprint 2).
Task 3.1 has no dependency on Sprints 1-2 and can start immediately.

### Task 3.1: Add the `review-candidates` CLI subcommand

- **Location**:
  - `sympoies/symphony-board: src/cli`
- **Description**: Add a `symphony-board review-candidates --json` subcommand
  that computes the candidate set (`open_review_threads`, `late_review`,
  `review_on_closed_pr`) from the board's own canonical store/contract — the
  logic currently in `review-cleanup.mjs` `buildCandidates` — and emits
  `{ source_id, repo, pr, reasons, openThreads, ... }[]`. Capture failing-test
  evidence first per the global test-first gate. This lane is independent of
  Sprints 1-2.
- **Dependencies**:
  - Task 0.1
- **Acceptance criteria**:
  - `review-candidates --json` reproduces the candidate set today's
    `buildCandidates` produces, from the board store/contract.
  - The board, not `forge-cli`, owns this command; `forge-cli` gains no board
    knowledge.
- **Validation**:
  - `pnpm run typecheck`; `pnpm test` (incl. a candidate-set test);
    `test-first-evidence` record.

### Task 3.2: Reduce project-review-cleanup to an adapter on the shared skill

- **Location**:
  - `sympoies/symphony-board: .agents/skills/project-review-cleanup`
- **Description**: Point the shared `review-thread-cleanup` skill at
  `review-candidates` for board discovery, drop the duplicated discovery and
  resolve/reply GraphQL from `review-cleanup.mjs`, and deliver the PR.
- **Dependencies**:
  - Task 2.2
  - Task 3.1
- **Acceptance criteria**:
  - `review-cleanup.mjs` no longer carries discovery or resolve/reply GraphQL.
  - The shared skill drives a board sweep via `review-candidates` + the
    forge-cli read/write surfaces.
- **Validation**:
  - `pnpm run typecheck`; `pnpm test`; `gh pr checks` green.

## Sprint 4: Integration and closeout

### Task 4.1: Cross-repo sweep smoke

- **Location**:
  - `graysurf/agent-runtime-kit`, `sympoies/symphony-board`
- **Description**: End-to-end smoke of a real sweep through the shared skill
  across at least two repos; confirm the convergence policy is applied from one
  source.
- **Dependencies**:
  - Task 3.2
- **Acceptance criteria**:
  - A sweep runs through the shared skill and applies the convergence policy.
- **Validation**:
  - Manual smoke run captured with redacted evidence.

### Task 4.2: Close and evaluate compression

- **Location**:
  - `core/policies/heuristic-system/`
- **Description**: Close the tracker; if a second resolved sibling exists,
  evaluate an `async-bot-review-fix-loop` operation record.
- **Dependencies**:
  - Task 4.1
- **Acceptance criteria**:
  - Tracker closed; operation-record decision recorded.
- **Validation**:
  - `heuristic-inbox verify --strict` on any new/updated record.
