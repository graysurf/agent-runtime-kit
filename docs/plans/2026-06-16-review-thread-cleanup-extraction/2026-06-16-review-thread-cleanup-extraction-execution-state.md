# Review Thread Cleanup Extraction Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress; Go/No-Go = GO (2026-06-16). Decision B locked: discovery
  becomes a `symphony-board review-candidates` CLI subcommand; `forge-cli` gains
  only the resolve/reply write surface.
- Target scope: extract a shared `review-thread-cleanup` skill + forge-cli
  thread-resolve write surface; promote board discovery into a board CLI
  subcommand; reduce `project-review-cleanup` to a thin adapter.
- Execution window: Go/No-Go (done) -> two independent lanes (Sprint 1 nils-cli
  write surface; Sprint 3.1 board review-candidates CLI) -> Sprint 2 runtime-kit
  shared skill -> Sprint 3.2 adapter -> Sprint 4 integration and closeout.
- Current task: kicking off execution; choose the first lane (Sprint 1.1 or
  Sprint 3.1 — both independent of each other).
- Next task: Sprint 1.1 (forge-cli write-surface design) and/or Sprint 3.1
  (board review-candidates CLI).
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
| 0.1 | done | Go/No-Go: proceed? | GO (2026-06-16); user elected to proceed, standalone-merit; decision B locked. | Phase 0 already closed the inbox gap; this is forward-looking architecture. |
| 1.1 | pending | Design forge-cli thread-resolve/reply write surface (GitHub first, fail-closed, allowlist) + failing-test evidence | — | Sprint 1; independent lane. |
| 1.2 | pending | Implement + test in nils-cli; deliver PR | — | Sprint 1. |
| 1.3 | pending | Release nils-cli; tap/brew; bump agent-runtime-kit version pin | — | Sprint 1; `nils-cli-bump`. |
| 2.1 | pending | Scaffold shared review-thread-cleanup skill via create-skill; embed policy + wrap read/write surfaces | — | Sprint 2; needs 1.3. |
| 2.2 | pending | Render Codex/Claude, acceptance coverage, skill governance, scripts/ci/all.sh | — | Sprint 2. |
| 3.1 | pending | Add `symphony-board review-candidates --json` CLI subcommand (decision B); test-first | — | Sprint 3; independent lane, can start now. |
| 3.2 | pending | Reduce project-review-cleanup to adapter on shared skill; drop discovery + GraphQL | — | Sprint 3; needs 2.2 + 3.1. |
| 4.1 | pending | End-to-end cross-repo sweep smoke through the shared skill | — | Sprint 4. |
| 4.2 | pending | Close tracker; evaluate async-bot-review-fix-loop operation record | — | Sprint 4. |
