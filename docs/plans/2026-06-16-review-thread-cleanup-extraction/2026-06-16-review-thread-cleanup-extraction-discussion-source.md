# Review Thread Cleanup Extraction - Discussion Source

- Status: accepted for L2/L3 execution (gated; see Go/No-Go).
- Date: 2026-06-16 UTC.
- Source repo: `graysurf/agent-runtime-kit`
- Source request: The user pointed at the heuristic inbox case
  `review-cleanup-post-merge-review-recursion`, asked whether it needs
  improvement, and — after the assessment — asked to (1) consider pulling the
  `project-review-cleanup` skill out of `symphony-board` into a shared home and
  (2) consider a dedicated method for triaging bot-review findings (edge-case,
  business-logic-irrelevant), including when to concentrate on or skip bot
  reviews.

## Background

During a `/project-review-cleanup` sweep, fixing post-merge bot (Codex) review
threads on already-merged PRs itself drew a fresh post-merge review on each fix
PR, recursing across generations (e.g. nils-cli #877 -> #878 -> #879 -> #880).
The inbox case captured a three-part convergence discipline as the workaround.

## Layered Analysis

The request untangles into three layered concerns:

- C. Per-finding triage — fix / accept / stale / follow-up for one thread (the
  user's idea 2).
- A. Convergence loop — when a multi-generation fix-PR sweep stops (the inbox
  case).
- B. Where the capability lives — project-local vs shared (the user's idea 1).

A is the loop built on C; B is the packaging question.

## Key Feasibility Findings

- The generic mechanics already live in the shared layer:
  `forge-cli pr review-threads` (provider-aware, read) and the
  `forge-cli pr merge` fail-closed `unresolved_review_threads` gate.
- `symphony-board` `project-review-cleanup` only adds board-coupled parts:
  `data/contract.json` discovery, the board "unresolved" lens, the
  `late_review` heuristic, the safe auto-resolve apply flow, and the
  which-repos-to-sync knowledge.
- There is no released forge-cli write surface to resolve/reply to a thread;
  the board skill performs `resolveReviewThread` /
  `addPullRequestReviewThreadReply` via raw `gh api graphql` (GitHub-only).
- Therefore the reusable missing piece is judgment/policy, not mechanics; a
  shared sweep skill that can *apply* resolutions on released surfaces requires
  a new forge-cli write surface (outflow into nils-cli).

## Decision

- Phase 0 (done): promote the convergence + per-finding triage discipline into
  a shared, provider-agnostic policy
  (`core/policies/review-thread-convergence.md`), referenced by the
  `symphony-board` skill; archive the inbox case as `promoted` and tag the
  `async-bot-review-fix-loop` cluster on it and the sibling
  `deliver-pr-merge-misses-bot-review-threads`.
  - graysurf/agent-runtime-kit#407 (merged)
  - sympoies/symphony-board#229 (merged)
- T3 (this plan): extract a shared `review-thread-cleanup` skill that owns the
  generic discovery + the policy, add the forge-cli thread-resolve write
  surface, and reduce `project-review-cleanup` to a board-discovery adapter.

## Open Questions / Go-No-Go

- Phase 0 alone closes the inbox gap. T3 is forward-looking architecture: today
  only `symphony-board` consumes the discovery mechanics, so per the Heuristic
  System Compression Rule the extraction is arguably early. Before Sprint 1,
  re-confirm there is a real second consumer (or that the forge-cli write
  surface is worth shipping on its own merit). If not, hold T3.
- T3-b (forge-cli grows a resolve/reply write surface) is the correct end-state
  and is assumed by this plan. T3-a (shared skill produces a disposition file;
  apply stays in the project adapter via raw provider API) is the de-scope
  lever if the nils-cli release cycle is not worth it.

## Execution

- Recommended plan:
  docs/plans/2026-06-16-review-thread-cleanup-extraction/2026-06-16-review-thread-cleanup-extraction-plan.md
- Recommended execution state:
  docs/plans/2026-06-16-review-thread-cleanup-extraction/2026-06-16-review-thread-cleanup-extraction-execution-state.md
