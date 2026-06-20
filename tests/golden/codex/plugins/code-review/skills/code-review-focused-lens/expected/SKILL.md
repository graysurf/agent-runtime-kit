---
name: code-review-focused-lens
description: >
  Run one or more explicitly requested specialist review lenses without invoking the full specialist bundle.
---

# Code Review Focused Lens

Use this workflow when the reviewer or user asks for a specific review angle,
such as security, testing, performance, data migration, API contract, or
maintainability, and the rest of the full specialist bundle is not needed.

## Contract

Prereqs:

- Run inside the target git repository with `git` available on `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH`.
- Know the base ref for the diff under review.
- The requested lens or lenses are explicit before review begins.
- Keep this workflow read-only: it does not fix code, post PR/MR comments,
  merge, close issues, or write provider state.

Inputs:

- Diff base ref and one or more forced specialist flags:
  `--testing`, `--security`, `--performance`, `--data-migration`,
  `--api-contract`, `--maintainability`, or `--red-team`.
- Optional review target summary, validation evidence, and existing findings to
  cross-check.

Outputs:

- Scope JSON from `review-specialists scope` with the requested forced lenses.
- Lens-specific findings with concrete file or evidence anchors.
- A compact lens report that separates verified findings from residual risk.
- Optional merged specialist JSON/report when the caller needs deterministic
  validation or retained evidence.

Failure modes:

- No lens is specified, or the requested lens is not supported.
- Base ref is missing or does not resolve in the target repository.
- The requested lens reveals broader risk that requires `code-review-specialists`
  or `code-review-pre-merge-gate`.
- Findings lack enough evidence to support a concrete issue; mark them as
  residual risk instead.

## Entrypoint

Run scope detection with explicit forced lenses:

```bash
review-specialists scope \
  --base "$BASE_REF" \
  --testing \
  --api-contract \
  --format json
```

Validate and merge JSONL findings when a machine-checkable report is needed:

```bash
review-specialists validate --input focused-findings.jsonl --validate-paths --format json
review-specialists merge --input focused-findings.jsonl --summary-out focused-review.md --format json
```

## Workflow

1. Confirm the exact requested lens set. Do not silently broaden into all
   specialists.
2. Establish the review target and base ref. For a PR/MR, use the actual
   PR/MR base or merge-base.
3. Run `review-specialists scope` with the forced lens flags.
4. Read only the relevant prompt files under
   `skills/code-review/code-review-specialists/references/specialists/`.
5. Review the diff, nearby definitions, tests, and supplied validation evidence
   from the requested angle.
6. Write findings using the specialist review contract when JSONL output is
   needed. Otherwise provide a compact human report with the same evidence
   discipline.
7. Escalate to `code-review-specialists` when multiple lenses become necessary
   or to `code-review-pre-merge-gate` when the review is a delivery-blocking
   merge gate.

## Boundary

`code-review-focused-lens` owns narrow, user-selected review lenses. It does not
own broad specialist selection, delivery gate policy, provider comments, merge
decisions, evidence record structure, or code repairs.

## References

- Specialist finding contract:
  `skills/code-review/code-review-specialists/references/SPECIALIST_REVIEW_CONTRACT.md`
- Specialist prompts:
  `skills/code-review/code-review-specialists/references/specialists/`
- Full specialist review workflow:
  `skills/code-review/code-review-specialists/SKILL.md`
- Pre-merge gate workflow:
  `skills/code-review/code-review-pre-merge-gate/SKILL.md`
