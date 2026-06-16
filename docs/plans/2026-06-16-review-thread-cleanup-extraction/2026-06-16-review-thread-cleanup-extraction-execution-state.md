# Review Thread Cleanup Extraction Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: complete (2026-06-16). All sprints delivered; tracker closed. Go/No-Go
  = GO (2026-06-16). Decision B locked: discovery became a `symphony-board
  review-candidates` CLI subcommand; `forge-cli` gained only the resolve/reply
  write surface.
- Target scope: extract a shared `review-thread-cleanup` skill + forge-cli
  thread-resolve write surface; promote board discovery into a board CLI
  subcommand; reduce `project-review-cleanup` to a thin adapter.
- Execution window: Go/No-Go (done) -> two independent lanes (Sprint 1 nils-cli
  write surface; Sprint 3.1 board review-candidates CLI) -> Sprint 2 runtime-kit
  shared skill -> Sprint 3.2 adapter -> Sprint 4 integration and closeout.
- Current task: none — closeout. Sprint 3.2 (board-discovery adapter) and
  Sprint 4.1 (cross-repo sweep smoke) are done; the tracker is being closed.
- Next task: none. Follow-up retention (the `async-bot-review-fix-loop`
  operation record and the completion-parity-audit-strict inbox lesson) is
  handled through `$heuristic-session-closeout`, not this tracker.
- Last updated: 2026-06-16
- Branch/commit/PR: tracker bundle on
  chore/review-thread-cleanup-extraction-tracker. Delivered: nils-cli
  resolve/reply write surface (`sympoies/nils-cli#883`, `#885`) released as
  `v1.9.1`; agent-runtime-kit pin bump (graysurf/agent-runtime-kit#411); shared
  `pr.review-thread-cleanup` skill (graysurf/agent-runtime-kit#412); board
  `review-candidates` CLI (`sympoies/symphony-board#230`); board-discovery
  adapter (`sympoies/symphony-board#231`).
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
| 1.1 | done | Design forge-cli thread-resolve/reply write surface (GitHub first, fail-closed, allowlist) + failing-test evidence | `pr review-threads resolve/reply` design + failing test in `sympoies/nils-cli#883`. | Reply-then-resolve, idempotent; `provider_unsupported` on GitLab/Local. |
| 1.2 | done | Implement + test in nils-cli; deliver PR | `sympoies/nils-cli#883` (impl); `#885` (completion-parity fix for the subcommand shape). | Bare `pr review-threads <id>` retired in favor of `list`/`resolve`/`reply`. |
| 1.3 | done | Release nils-cli; tap/brew; bump agent-runtime-kit version pin | Released `v1.9.1`; pin bump graysurf/agent-runtime-kit#411 (version-alignment + version-baseline green). | v1.9.0 tagged but unpublished (parity gap); superseded by v1.9.1. |
| 2.1 | done | Scaffold shared review-thread-cleanup skill via create-skill; embed policy + wrap read/write surfaces | `core/skills/pr/review-thread-cleanup/SKILL.md.tera` + manifests in graysurf/agent-runtime-kit#412. | Binds `review-thread-convergence.md` as the judgment contract. |
| 2.2 | done | Render Codex/Claude, acceptance coverage, skill governance, scripts/ci/all.sh | runtime-smoke pr 5/5; governance OK (skills=64); sandbox OK; hooks 58 ok; `scripts/ci/all.sh` 1-14 OK; test-first evidence recorded (graysurf/agent-runtime-kit#412). | — |
| 3.1 | done | Add `symphony-board review-candidates --json` CLI subcommand (decision B); test-first | `sympoies/symphony-board#230`. | Board owns discovery; `forge-cli` gains no board knowledge. |
| 3.2 | done | Reduce project-review-cleanup to adapter on shared skill; drop discovery + GraphQL | `sympoies/symphony-board#231` (deleted review-cleanup.mjs + wrapper + test; SKILL rewritten as discovery adapter). | typecheck + 248 tests green; discovery coverage in review-candidates.test.ts. |
| 4.1 | done | End-to-end cross-repo sweep smoke through the shared skill | Read-only smoke: `review-candidates` surfaced cross-repo candidates (symphony-board#206, agent-runtime-kit#349); `forge-cli pr review-threads list` verified each (live unresolved=0). Evidence under agent-out (t3-sprint4-smoke). | Resolve/reply mutations covered by the #412 acceptance probe + nils-cli tests, not run on live threads. |
| 4.2 | done | Close tracker; evaluate async-bot-review-fix-loop operation record | Tracker closed; operation record + completion-parity-audit-strict lesson routed to `$heuristic-session-closeout`. | Both inbox siblings already carry Cluster `async-bot-review-fix-loop`. |
