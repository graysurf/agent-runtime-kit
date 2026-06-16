# Review Thread Cleanup Extraction Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: open; tracker being created (T3 not yet started, gated by Go/No-Go).
- Target scope: extract a shared `review-thread-cleanup` skill + forge-cli
  thread-resolve write surface, reducing `project-review-cleanup` to a
  board-discovery adapter.
- Execution window: Go/No-Go -> Sprint 1 nils-cli write surface -> Sprint 2
  runtime-kit shared skill -> Sprint 3 symphony-board adapter -> Sprint 4
  integration and closeout.
- Current task: Go/No-Go gate (Task 0).
- Next task: Task 1.1 (only if Go/No-Go confirms a second consumer or
  standalone merit).
- Last updated: 2026-06-16
- Branch/commit/PR: tracker bundle on chore/review-thread-cleanup-extraction-tracker
- Source document: docs/plans/2026-06-16-review-thread-cleanup-extraction/2026-06-16-review-thread-cleanup-extraction-plan.md
- Plan document: docs/plans/2026-06-16-review-thread-cleanup-extraction/2026-06-16-review-thread-cleanup-extraction-plan.md
- Direct source-doc execution waiver: not applicable
- Prior phase (out of scope, merged): graysurf/agent-runtime-kit#407,
  sympoies/symphony-board#229
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/408>

## Validation Plan

- Bundle:
  - `plan-tooling validate --file <plan-file> --format text --explain`.
- Tracker open:
  - Dry-run `plan-issue record open --profile tracking`.
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- Sprint 1 (nils-cli): failing-test evidence first (global test-first gate);
  nils-cli test suite; release + tap/brew + agent-runtime-kit pin bump.
- Sprint 2 (agent-runtime-kit): `agent-runtime render --product codex|claude`,
  `bash scripts/ci/skill-governance-audit.sh`, `bash scripts/ci/all.sh`,
  `bash tests/hooks/run.sh`.
- Sprint 3 (symphony-board): `pnpm run typecheck`, `pnpm test`, review-cleanup
  script tests.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 0 | pending | Go/No-Go: confirm a real second consumer or standalone forge-cli write-surface merit | — | Hold T3 if neither holds; Phase 0 already closed the inbox gap. |
| 1.1 | pending | Design forge-cli thread-resolve/reply write surface (GitHub first, fail-closed, allowlist) + failing-test evidence | — | Sprint 1. |
| 1.2 | pending | Implement + test in nils-cli; deliver PR | — | Sprint 1. |
| 1.3 | pending | Release nils-cli; tap/brew; bump agent-runtime-kit version pin | — | Sprint 1; `nils-cli-bump`. |
| 2.1 | pending | Scaffold shared review-thread-cleanup skill via create-skill; embed policy + wrap read/write surfaces | — | Sprint 2. |
| 2.2 | pending | Render Codex/Claude, acceptance coverage, skill governance, scripts/ci/all.sh | — | Sprint 2. |
| 3.1 | pending | Refactor project-review-cleanup into board-discovery adapter; drop duplicated GraphQL mutation | — | Sprint 3. |
| 3.2 | pending | Validate symphony-board; deliver PR | — | Sprint 3. |
| 4.1 | pending | End-to-end cross-repo sweep smoke through the shared skill | — | Sprint 4. |
| 4.2 | pending | Close tracker; evaluate async-bot-review-fix-loop operation record | — | Sprint 4. |
