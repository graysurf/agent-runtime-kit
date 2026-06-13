# Codex Review Subagents Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: Sprint 1 complete; Sprint 2.1 gated on the nils-cli agents-render primitive
- Target scope: make repo-managed code review run through reviewer subagents in
  both Codex and Claude Code, while preserving main-agent ownership of review
  synthesis and delivery decisions.
- Execution window: Sprint 1 tracker and surface baseline -> Sprint 2
  quick-reviewer vertical slice -> Sprint 3 specialist reviewer fan-out ->
  Sprint 4 product probes and delivery integration -> Sprint 5 validation,
  delivery, and closeout.
- Current task: Task 2.1 (gated on the nils-cli agents-render primitive).
- Next task: Task 2.2.
- Last updated: 2026-06-13T18:31:15Z
- Branch/commit/PR: branch `docs/codex-review-subagents`; no PR yet.
- Source document: docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-discussion-source.md
- Plan document: docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/330>

## Validation Plan

- Plan bundle:
  - `plan-tooling validate --file docs/plans/2026-06-13-codex-review-subagents/codex-review-subagents-plan.md --format text --explain`
- Tracker open:
  - Dry-run `plan-issue record open --profile tracking`.
  - Live `plan-issue record open --profile tracking` after dry-run shape is
    verified.
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- Runtime-kit implementation:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `agent-runtime render --target support-matrix`
  - `agent-runtime audit-drift`
  - `bash scripts/ci/sandbox-install-rehearsal.sh`
  - `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review`
  - `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
  - `bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only`
- Final validation:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Create the plan bundle and open the tracker | Tracker #330 open with visible source/plan/state records. | Bundle authoring started in managed worktree `docs/codex-review-subagents`. |
| 1.2 | done | Baseline reviewer-agent surface requirements | Baseline recorded: Codex ~/.codex/agents TOML + Claude ~/.claude/agents MD discovery confirmed vs official docs; Path A selected; nils-cli agents-render primitive recorded as Sprint 2.1 blocker; validations pass. | Path A: canonical agents source rendered by nils-cli into both products. |
| 2.1 | pending | Add managed reviewer-agent source and render/install scaffolding | pending | Starts with quick-reviewer vertical slice. |
| 2.2 | pending | Route quick-pass review through the quick reviewer | pending | Requires explicit waiver/blocker if reviewer subagent dispatch is unavailable. |
| 3.1 | pending | Add specialist reviewer agent definitions | pending | Reuse existing specialist prompts and JSONL contract. |
| 3.2 | pending | Route specialist review through selected reviewer subagents | pending | Main agent validates and merges returned JSONL findings. |
| 4.1 | pending | Add product-safe reviewer-agent discovery probes | pending | Prefer isolated runtime homes and probe-only product checks. |
| 4.2 | pending | Reconcile delivery review callers | pending | Keep provider mutation in delivery skills. |
| 5.1 | pending | Run full project validation | pending | Full CI and hook validation after implementation. |
| 5.2 | pending | Deliver PRs and close the tracker | pending | Closeout and archive only after close-ready passes. |

## Session Log

- 2026-06-13T17:36:03Z: User requested using a managed worktree to run
  `create-plan-tracking-issue` for the Codex/Claude Code review-subagent goal.
  Worktree `docs/codex-review-subagents` was created from `origin/main`.
- 2026-06-13T18:31:15Z: Task 1.2 baseline complete. Confirmed `agent-runtime
  render` has no agent-definition render path (RenderTarget is Product or
  SupportMatrix; the product loop iterates skills only) and the install link
  map is data-driven (no nils-cli change needed to install agent files).
  Selected Path A: one canonical reviewer-agent source rendered by nils-cli
  into Codex TOML (`~/.codex/agents`) and Claude Markdown (`~/.claude/agents`).
  Recorded blocker: an agents render primitive must ship in `sympoies/nils-cli`
  and be floor-bumped before Sprint 2.1 render goldens can exist. Codex
  live-discovery in codex-cli 0.139.0 stays an open probe.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-runtime render --target support-matrix` | pass | surfaces=17 rows=34; SUPPORT_MATRIX renders clean. | n/a |
| `bash scripts/ci/validate-surfaces-manifest.sh` | pass | surfaces.yaml schema/shape valid. | n/a |
