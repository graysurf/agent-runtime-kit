# Codex Review Subagents Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: Sprints 1-4 complete; Sprint 5.1 full validation green; delivering (Task 5.2)
- Target scope: make repo-managed code review run through reviewer subagents in
  both Codex and Claude Code, while preserving main-agent ownership of review
  synthesis and delivery decisions.
- Execution window: Sprint 1 tracker and surface baseline -> Sprint 2
  quick-reviewer vertical slice -> Sprint 3 specialist reviewer fan-out ->
  Sprint 4 product probes and delivery integration -> Sprint 5 validation,
  delivery, and closeout.
- Current task: Task 5.2 (deliver the implementation PR and close the tracker).
- Next task: none (closeout and archive).
- Last updated: 2026-06-13T20:57:50Z
- Branch/commit/PR: implementation branch `feat/codex-review-subagents-impl`
  (rebased onto the pin-bumped `main`; includes the plan bundle); PR delivery in
  progress.
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
| 2.1 | done | Add managed reviewer-agent source and render/install scaffolding | reviewer-quick agent source + manifests/agents.yaml + agents-tree link maps + surfaces row 7 shipped (both products) + harness docs; render goldens and sandbox-install rehearsal expose ~/.codex/agents/reviewer-quick.toml and ~/.claude/agents/reviewer-quick.md. | Starts with quick-reviewer vertical slice. |
| 2.2 | done | Route quick-pass review through the quick reviewer | code-review-quick-pass dispatches the reviewer-quick subagent with parent-owned synthesis and an explicit inline-review waiver fallback; goldens refreshed, runtime-smoke code-review 5/5. | Requires explicit waiver/blocker if reviewer subagent dispatch is unavailable. |
| 3.1 | done | Add specialist reviewer agent definitions | 7 read-only specialist reviewer agents (testing, maintainability, security, performance, api-contract, data-migration, red-team), self-contained JSONL output; audit-drift clean. | Reuse existing specialist prompts and JSONL contract. |
| 3.2 | done | Route specialist review through selected reviewer subagents | code-review-specialists dispatches the matching reviewer-<lens> subagents; malformed/missing output treated as failure or residual risk; review-specialists validate/merge/render retained. | Main agent validates and merges returned JSONL findings. |
| 4.1 | done | Add product-safe reviewer-agent discovery probes | sandbox-install-rehearsal pins installed reviewer agents per product via tests/sandbox/<product>/expected-agents.txt; manual live discovery probe documented in tests/runtime-smoke/README.md. | Prefer isolated runtime homes and probe-only product checks. |
| 4.2 | done | Reconcile delivery review callers | code-review-pre-merge-gate dispatches reviewer subagents for mandatory + risk lenses; delivery callers route through it/specialists; provider actions retained by delivery skills. | Keep provider mutation in delivery skills. |
| 5.1 | done | Run full project validation | scripts/ci/all.sh positions 1-13 OK; tests/hooks/run.sh OK. | Full CI and hook validation after implementation. |
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
- 2026-06-13T20:57:50Z: Sprints 2-4 implemented and Sprint 5.1 validated on the
  rebased `feat/codex-review-subagents-impl` branch. The blocker cleared:
  nils-cli v1.3.0 shipped the optional agents render primitive
  (sympoies/nils-cli#839, release #840) and the agent-runtime-kit pin was bumped
  to v1.3.0 (#338). Added the reviewer-quick agent + `manifests/agents.yaml` +
  `agents-tree` link maps + surfaces row 7 (shipped, both products) + harness
  docs (2.1); routed `code-review-quick-pass` through the reviewer-quick subagent
  with an inline-review waiver fallback (2.2); added seven specialist reviewer
  agents and routed `code-review-specialists` and `code-review-pre-merge-gate`
  through them (3.1, 3.2, 4.2); pinned the installed reviewer agents in the
  sandbox-install rehearsal and documented the manual live-discovery probe (4.1).
  Reworded the security reviewer to clear an audit-drift unsafe `keyword_prefix`
  false positive. Full validation green: `scripts/ci/all.sh` positions 1-13 OK
  and `tests/hooks/run.sh` OK. Test-first evidence recorded (waiver plus passing
  final validation) for the feature PR gate.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-runtime render --target support-matrix` | pass | surfaces=17 rows=34; SUPPORT_MATRIX renders clean. | n/a |
| `bash scripts/ci/validate-surfaces-manifest.sh` | pass | surfaces.yaml schema/shape valid. | n/a |
| `agent-runtime render --product codex/claude --update-golden` + golden diff | pass | reviewer-quick and 7 specialists render to Codex TOML / Claude Markdown; goldens refreshed with no unexpected drift. | tests/golden/{codex,claude}/agents/ |
| `agent-runtime audit-drift` | pass | clean (20 intentional-difference findings); security reviewer reworded to clear the unsafe keyword_prefix false positive. | n/a |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | installs reviewer-quick + 7 specialists into ~/.codex/agents/*.toml and ~/.claude/agents/*.md; matches expected-agents.txt pins. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain code-review` | pass | 5/5 code-review skill probes pass. | n/a |
| `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only` | pass | isolation supported; live prompt smoke manual-only. | n/a |
| `bash scripts/ci/all.sh` | pass | positions 1-13 OK. | n/a |
| `bash tests/hooks/run.sh` | pass | shared hook contract suite OK. | n/a |
