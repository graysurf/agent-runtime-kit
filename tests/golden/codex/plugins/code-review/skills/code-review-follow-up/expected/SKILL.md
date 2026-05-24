---
name: code-review-follow-up
description:
  Re-check previous review findings after fixes and classify each item as resolved, unresolved, accepted, or residual risk.
---

# Code Review Follow-Up

Use this workflow after a review produced findings and the author has made
repairs or supplied new validation evidence. The goal is to verify disposition,
not to start a fresh broad review.

## Contract

Prereqs:

- Run inside the target git repository with `git` available on `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH`.
- The previous review findings, report, PR comment, or review-evidence record
  are available.
- Know the base ref for the current diff and the fix commit range when
  available.
- Keep this workflow read-only: it does not fix code, post PR/MR comments,
  merge, close issues, or write provider state.

Inputs:

- Previous findings or report, current base ref, optional fix summary, and
  validation evidence.
- Optional affected specialist lenses to rerun.
- Optional accepted-risk rationale from the owning reviewer or delivery
  workflow.

Outputs:

- Finding-by-finding disposition: `resolved`, `unresolved`, `accepted-risk`,
  `not-reproducible`, or `residual-risk`.
- Evidence anchors for each disposition.
- Focused validation or specialist rerun notes for affected areas.
- Optional `review-evidence` update when retained evidence is needed.

Failure modes:

- Previous findings are unavailable or cannot be mapped to current files.
- The fix range is unclear and the current diff is too broad to attribute
  disposition safely.
- New concrete findings appear outside the follow-up scope; escalate to
  `code-review-quick-pass`, `code-review-focused-lens`, or
  `code-review-specialists`.
- Accepted-risk rationale is missing for an unresolved concrete finding.

## Entrypoint

Start by sizing the current diff and validating any JSONL findings that will be
reused:

```bash
review-specialists scope --base "$BASE_REF" --format json
review-specialists validate --input previous-findings.jsonl --validate-paths --format json
```

Rerun only affected lenses when needed:

```bash
review-specialists scope \
  --base "$BASE_REF" \
  --testing \
  --maintainability \
  --format json
```

## Workflow

1. Load the previous review findings and identify the exact items that require
   follow-up.
2. Establish the current base ref and, when available, the fix commit range.
3. Map each previous finding to current paths, lines, tests, commands, or
   evidence artifacts.
4. Inspect only the changed areas needed to verify disposition. Do not broaden
   into a new review unless a new concrete risk appears.
5. Rerun affected specialist lenses or focused validation when the original
   finding depended on that lens.
6. Classify each item as `resolved`, `unresolved`, `accepted-risk`,
   `not-reproducible`, or `residual-risk` with concrete evidence.
7. If retained evidence is required, record the final disposition through
   `review-evidence`. The caller still owns whether unresolved items block
   delivery.

## Boundary

`code-review-follow-up` owns review-finding disposition after repairs. It does
not own implementation fixes, broad new review, provider comments, merge
decisions, issue closeout, or the durable evidence schema.

## References

- Specialist review workflow:
  `skills/code-review/code-review-specialists/SKILL.md`
- Quick pass workflow:
  `skills/code-review/code-review-quick-pass/SKILL.md`
- Focused lens workflow:
  `skills/code-review/code-review-focused-lens/SKILL.md`
- Review evidence tool:
  `skills/evidence/review-evidence/SKILL.md`
