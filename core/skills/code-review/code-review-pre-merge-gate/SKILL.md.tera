---
name: code-review-pre-merge-gate
description:
  Run the shared read-only specialist review gate before PR or MR merge decisions.
---

# Code Review Pre-Merge Gate

Use this workflow when a PR or MR is close to merge and needs the shared
delivery specialist review gate without handing provider actions to the
code-review skill itself.

## Contract

Prereqs:

- Run inside the target git repository with `git` available on `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH`.
- The mandatory and risk lenses run through the managed read-only reviewer
  subagents dispatched by the shared specialist gate; record a waiver and
  review inline when subagent dispatch is unavailable.
- The PR/MR base branch or merge-base is known.
- Local validation and provider check evidence are available or explicitly
  marked pending by the owning delivery workflow.
- Keep this workflow read-only: it does not fix code, post PR/MR comments,
  mark reviewables ready, merge, close issues, or clean branches.

Inputs:

- PR/MR identifier or reviewable summary, base ref, head ref, validation
  evidence, and optional linked issue context.
- Optional provider-side review evidence collected read-only by the owning
  delivery workflow: reviews and review threads already posted on the PR/MR
  (typically by bot reviewers). When supplied, classify those findings with
  the same delivery outcome vocabulary as local lens findings.
- Optional forced risk lenses beyond the mandatory minimum:
  `--security`, `--performance`, `--data-migration`, `--api-contract`, or
  `--red-team`.

Outputs:

- Scope JSON from `review-specialists scope` with at least `--testing` and
  `--maintainability` forced.
- Gate result: `pass`, `request-followup`, `blocked`, or `accepted-risk`.
- Concrete findings, accepted tradeoffs, residual risks, and validation gaps.
- A delivery review outcome body suitable for the owning PR/MR delivery
  workflow to post.

Failure modes:

- Base ref is missing, ambiguous, or not the PR/MR target base.
- Required validation/check evidence is absent and no explicit pending status is
  acceptable.
- Concrete specialist findings remain unresolved and are not explicitly
  accepted by the owning delivery workflow.
- Caller tries to use this workflow to merge, close, post provider comments, or
  replace `deliver-pr` or `review-dispatch-lane-pr`.

## Entrypoint

Run the shared gate's mandatory scope detection:

```bash
review-specialists scope \
  --base "$BASE_REF" \
  --testing \
  --maintainability \
  --format json
```

Add risk lenses when warranted:

```bash
review-specialists scope \
  --base "$BASE_REF" \
  --testing \
  --maintainability \
  --security \
  --api-contract \
  --format json
```

## Workflow

1. Resolve reviewable metadata and confirm the base ref is the actual PR/MR
   target branch or merge-base.
2. Follow the shared delivery gate in
   `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`.
3. Run `review-specialists scope --base "$BASE_REF" --testing
   --maintainability --format json`. Do not skip small diffs.
4. Add risk lenses for security, API contract, migration, performance, or
   red-team conditions when the scope warrants them.
5. Review the selected lenses read-only by dispatching the matching managed
   reviewer subagents (`reviewer-testing`, `reviewer-maintainability`, and any
   forced risk lens such as `reviewer-security`, `reviewer-api-contract`, or
   `reviewer-red-team`); collect their JSONL findings and classify each item
   using the shared delivery outcome vocabulary.
6. Treat evidence-backed concrete findings as blocking until repaired, accepted
   by the owner, or converted into an explicit follow-up.
7. Produce a compact gate result and delivery review outcome body. The owning
   delivery skill posts comments, reruns checks, merges, or stops.

## Boundary

`code-review-pre-merge-gate` owns the read-only review gate, reviewer-subagent
dispatch, and the review outcome recommendation. Each dispatched reviewer
subagent owns only its read-only lens. Provider delivery skills own PR/MR
comments, ready transitions, checks, merge/close calls, issue closeout, and
repair execution.

## References

- Delivery specialist review gate:
  `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`
- Delivery review outcome comment:
  `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`
- Delivery review outcome schema:
  `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`
- PR/MR delivery workflow:
  `skills/pr/deliver-pr/SKILL.md`
- Dispatch PR review workflow:
  `skills/dispatch/review-dispatch-lane-pr/SKILL.md`
