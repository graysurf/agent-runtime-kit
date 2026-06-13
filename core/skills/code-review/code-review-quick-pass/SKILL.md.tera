---
name: code-review-quick-pass
description:
  Run a lightweight read-only review for small or ordinary diffs before escalating to specialist review.
---

# Code Review Quick Pass

Use this workflow for ordinary changes where a full specialist review would add
more ceremony than signal. The output is a compact reviewer judgment with clear
findings, residual risks, and escalation rationale when needed.

## Contract

Prereqs:

- Run inside the target git repository with `git` available on `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH`.
- Know the base ref for the diff under review, or explicitly choose one before
  running scope detection.
- Keep this workflow read-only: it does not fix code, post PR/MR comments,
  merge, close issues, or write provider state.
- Run the review through the managed read-only `reviewer-quick` subagent by
  default; the parent agent dispatches it and synthesizes its findings, and
  records an explicit waiver or blocker when subagent dispatch is unavailable.
- Escalate to `code-review-specialists` or `code-review-pre-merge-gate` when the
  diff is broad, high-risk, security-sensitive, migration-heavy, or delivery
  blocking.

Inputs:

- Diff base ref, optional review target summary, and optional validation
  evidence to inspect.
- Optional focus notes from the user, such as "review test coverage" or
  "check docs-only safety".

Outputs:

- A concise review result: `pass`, `findings`, `escalate`, or `blocked`.
- Concrete findings with file, line, diff, command, or evidence anchors.
- Residual risks and skipped areas when the quick pass intentionally does not
  run specialist lenses.
- Optional `review-evidence` record only when the caller needs retained review
  evidence.

Failure modes:

- Base ref is missing or does not resolve in the target repository.
- Scope detection shows a broad or risky diff that should not stay in quick
  review.
- Findings are too weakly evidenced to support action; report them as residual
  risk instead of verified findings.
- Caller tries to use this workflow as a pre-merge delivery gate, specialist
  review, CI repair loop, or implementation workflow.

## Entrypoint

Use git and the deterministic scope helper to size the review:

```bash
git diff --stat "$BASE_REF"...HEAD
review-specialists scope --base "$BASE_REF" --format json
```

When retained evidence is required, record the final reviewer judgment through
`review-evidence` after the quick pass is complete.

## Workflow

1. Establish the review target and base ref. For a PR/MR, use the actual
   PR/MR base or merge-base rather than a moving `origin/main` guess.
2. Run `review-specialists scope --base "$BASE_REF" --format json`.
3. Keep the quick pass only when the diff is small or routine and does not
   touch security, data migration, API contracts, concurrency, release, or
   runtime delivery behavior. Escalate before reviewing when scope is broad.
4. Dispatch the managed read-only `reviewer-quick` subagent on the sized diff
   (installed at `~/.codex/agents/reviewer-quick.toml` for Codex and
   `~/.claude/agents/reviewer-quick.md` for Claude). Hand it the base ref and
   any focus notes; it inspects read-only and returns a compact verdict with
   source-grounded findings and residual risks. You stay the parent: you own
   base-ref selection, synthesis of the returned findings, the escalation
   decision, and every provider / merge action.
5. Fallback — if reviewer-subagent dispatch is unavailable (the agent is not
   installed, or the host cannot spawn subagents), record an explicit waiver
   or blocker naming the reason, then run the same read-only review inline. Do
   not silently skip the reviewer path.
6. Synthesize the subagent's (or inline) result: report only source-grounded
   findings with path and line anchors; otherwise anchor to a command, diff
   hunk, or supplied evidence. Mark uncertain concerns as residual risk, not
   findings.
7. If the review uncovers high-risk scope or insufficient confidence, stop with
   an `escalate` result and name the next workflow:
   `code-review-focused-lens`, `code-review-specialists`, or
   `code-review-pre-merge-gate`.

## Boundary

`code-review-quick-pass` owns lightweight review judgment, reviewer-subagent
dispatch, synthesis of the returned findings, and escalation rationale. The
`reviewer-quick` subagent owns only the read-only inspection lens. This workflow
does not own specialist orchestration, provider comments, PR/MR merge decisions,
evidence record structure, or product-code repairs.

## References

- Quick reviewer subagent source:
  `core/agents/code-review/reviewer-quick/AGENT.md.tera`
- Specialist review workflow:
  `skills/code-review/code-review-specialists/SKILL.md`
- Focused lens workflow:
  `skills/code-review/code-review-focused-lens/SKILL.md`
- Pre-merge gate workflow:
  `skills/code-review/code-review-pre-merge-gate/SKILL.md`
- Review evidence tool:
  `skills/evidence/review-evidence/SKILL.md`
