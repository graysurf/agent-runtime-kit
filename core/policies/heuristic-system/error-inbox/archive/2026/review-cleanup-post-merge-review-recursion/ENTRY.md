# project-review-cleanup of post-merge bot reviews recurses; needs a convergence discipline

## Status

- Status: promoted
- First observed: 2026-06-16
- Area: review-cleanup
- Severity: low
- Cluster: async-bot-review-fix-loop
- Durable link: `core/policies/review-thread-convergence.md`

## Signal

During a `/project-review-cleanup` sweep, fixing post-merge bot (Codex) review
threads on already-merged PRs itself drew a FRESH post-merge review on each fix
PR, recursing across generations. In one session this reached 4 generations on a
single code path (the `nils-evidence` migrate cwd/slug identity matcher) before
converging on a uniform rule.

## Evidence

- Raw record: not captured as a `skill-usage` rollup — `project-review-cleanup`
  is a project-local skill that does not emit one. Manual diagnosis; the session
  artifacts (scans, dispositions, per-PR bodies/evidence) live under
  `$HOME/.local/state/agent-runtime-kit/out/projects/sympoies__symphony-board/20260616-000618-review-cleanup/`.
- Recursion chain (this session): `nils-cli` #877 → #878 → #879 → #880 (each
  fix's normalization / `local__` special-case drew a new edge-case thread until
  a single uniform rule in #880 converged); `agent-runtime-kit` #396 → #398 →
  #401; `symphony-board` #222 → #225 → #226.
- Related but distinct: error-inbox `deliver-pr merges past unresolved
  asynchronous bot review threads` (that case is about merging BEFORE a review
  lands; this is about fix PRs SPAWNING new reviews).

Ingested evidence files (under `evidence/`):

- `evidence/recursion-chain.md` — the per-repo PR recursion chain and the
  convergence discipline applied, redacted to PR refs.

## Impact

An agent that mechanically "fix each new thread" can loop indefinitely on
principled-but-imperfect code — especially an inherently-ambiguous heuristic
where no special-case is fully sound — or stop prematurely and leave a genuine
bug unfixed. Neither `project-review-cleanup` nor `deliver-pr` documents how to
decide when the sweep is done.

## Current Workaround

Apply a three-part convergence discipline:
1. When threads cluster on one mechanism, replace per-case special-casing with a
   single terminal/uniform rule instead of patching each edge (the `local__`
   slug saga only converged once #880 dropped all special cases).
2. Stopping rule: fix genuinely-new bugs, but resolve pure review-preference
   nitpicks on principled code as `accepted` with a recorded rationale rather
   than spawning another fix PR (and another review).
3. For an inherently-ambiguous key (e.g. a placeholder value indistinguishable
   from real data), pick the conservative/safe branch UNIFORMLY and document the
   tradeoff, rather than chasing heuristics review will keep poking.

## Promotion Criteria

Promote once the convergence discipline is written into a review-cleanup-type
skill (e.g. `project-review-cleanup` and/or a shared note), so a future agent
applies it without rediscovering it.

## Next Action

None. Promoted into the shared, provider-agnostic
`core/policies/review-thread-convergence.md` policy (per-finding triage, the
convergence/stopping rule, concentrate-vs-converge, and guard rails),
registered as an optional `project-dev` home-scoped doc in `AGENT_DOCS.toml`
and referenced from the symphony-board `project-review-cleanup` skill. A future
shared review-thread-cleanup skill (tracked as the T3 extraction program) will
embed the same policy and add a forge-cli thread-resolve write surface.

## Archive

- Archived: 2026-06-16
- Reason: Completed entry archived out of the active error inbox.
