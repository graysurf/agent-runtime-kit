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
   runtime delivery behavior.
4. Inspect the changed code, nearby call sites, tests, and validation evidence
   needed to judge the actual change. Do not broaden into unrelated cleanup.
5. Report only source-grounded findings. Include path and line anchors when
   available; otherwise anchor to a command, diff hunk, or supplied evidence.
6. Mark uncertain concerns as residual risk, not findings.
7. If the review uncovers high-risk scope or insufficient confidence, stop with
   an `escalate` result and name the next workflow:
   `code-review-focused-lens`, `code-review-specialists`, or
   `code-review-pre-merge-gate`.

## Boundary

`code-review-quick-pass` owns lightweight review judgment and escalation
rationale. It does not own specialist orchestration, provider comments, PR/MR
merge decisions, evidence record structure, or product-code repairs.

## References

- Specialist review workflow:
  `skills/code-review/code-review-specialists/SKILL.md`
- Focused lens workflow:
  `skills/code-review/code-review-focused-lens/SKILL.md`
- Pre-merge gate workflow:
  `skills/code-review/code-review-pre-merge-gate/SKILL.md`
- Review evidence tool:
  `skills/evidence/review-evidence/SKILL.md`
