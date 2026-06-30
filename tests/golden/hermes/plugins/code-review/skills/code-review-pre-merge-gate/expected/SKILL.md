---
name: code-review-pre-merge-gate
description: >
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
  subagents whenever the active host exposes subagent dispatch. Use
  `delegate_task` when it is available to dispatch the matching reviewers;
  inline review is only the fallback when dispatch is unavailable or blocked,
  and the fallback must be stated.
- The PR/MR base branch or merge-base is known.
- Local validation and provider check evidence are available or explicitly
  marked pending by the owning delivery workflow.
- Keep this workflow read-only: it does not fix code, mark reviewables ready,
  merge, close issues, or clean branches. When it runs under an owning delivery
  workflow with provider write access, the owning parent may post compact
  specialist review comments through `forge-cli pr review`; reviewer
  subagents never post directly. Specialist comments use `comments-only`; final
  delivery decisions belong to the owning workflow.
  When a specialist reports actionable findings and the provider is GitHub, the
  owning workflow should attach `--thread-file` to the first specialist post so
  each finding becomes a resolvable review thread. No-finding and informational
  reports omit it.

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
- Specialist review comment recommendations for the owning delivery workflow to
  post as each reviewer lens returns and after any focused follow-up rerun.

Failure modes:

- Base ref is missing, ambiguous, or not the PR/MR target base.
- Required validation/check evidence is absent and no explicit pending status is
  acceptable.
- Concrete specialist findings remain unresolved and are not explicitly
  accepted by the owning delivery workflow.
- Caller tries to use this workflow to merge, close, let reviewer subagents post
  provider comments, or replace `deliver-pr` or `review-dispatch-lane-pr`.

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

Posting order is non-negotiable. When the owning delivery workflow has provider
write access, it posts each lens's specialist review comment the moment that
lens returns — before any repair or commit, never batched after fixing — because
a finding is work-progress and evidence, not a closing summary. See
`skills/code-review/code-review-specialists/references/REVIEW_OUTCOME_POSTING_CONTRACT.md`.

1. Resolve reviewable metadata and confirm the base ref is the actual PR/MR
   target branch or merge-base.
2. Follow the shared delivery gate in
   `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`.
3. Run `review-specialists scope --base "$BASE_REF" --testing
   --maintainability --format json`. Do not skip small diffs.
4. Add risk lenses for security, API contract, migration, performance, or
   red-team conditions when the scope warrants them. Include red-team when
   `diff_lines > 200`, any first-wave specialist produces a `critical` finding,
   the reviewable changes safety/security-sensitive behavior, or the caller
   forced `--red-team`.
5. Review the first-wave lenses read-only by dispatching the matching managed
   reviewer subagents (`reviewer-testing`, `reviewer-maintainability`, and any
   forced risk lens such as `reviewer-security`, `reviewer-api-contract`, or
   `reviewer-performance`); collect their JSONL findings, validate and merge them,
   and classify each item using the shared delivery outcome vocabulary. Use `delegate_task` when it is available; if dispatch is
   unavailable or blocked, state the fallback reason and review the lenses inline.
   When an owning delivery workflow has provider write access, have it post one
   compact specialist review comment for each returned lens before repair work
   starts. For actionable findings on GitHub, have it attach a
   `REVIEW_THREAD_FILE` to that first specialist post so the finding opens as a
   provider-resolvable review thread; clean reviews and follow-up pass summaries
   stay summary-only. The parent uses the bot-profile selection from
   `REVIEW_OUTCOME_POSTING_CONTRACT.md`: reviewer bot for mapped lenses and
   `FORGE_BOT_PROFILE=dobi` for unmapped specialist lenses. The reviewer subagent
   stays read-only.
6. Dispatch `reviewer-red-team` only after the first-wave lenses, and only when
   the scope warrants it. If dispatch is unavailable or blocked, state the
   fallback reason and run the same red-team lens inline from
   `references/specialists/red-team.md`. Hand it the merged first-wave findings so
   it can probe cross-cutting failure modes, then validate its JSONL and merge the
   combined first-wave plus red-team JSONL before folding it into the result.
   When red-team returns, have the owning delivery workflow post the red-team
   specialist review comment before any red-team repair loop starts.
7. Classify every meaningful first-wave and red-team item using the shared
   delivery outcome vocabulary.
8. Treat evidence-backed concrete findings as blocking until repaired, accepted
   by the owner, or converted into an explicit follow-up.
9. After repairs, rerun focused validation and affected lenses; have the owning
   delivery workflow post a follow-up specialist review comment with the same
   bot-profile selection for each rerun.
10. Produce a compact gate result and final delivery review outcome body. The
    owning delivery skill posts the final combined outcome, reruns checks,
    merges, or stops.

## Boundary

`code-review-pre-merge-gate` owns the read-only review gate,
reviewer-subagent dispatch, fallback justification, and the review outcome
recommendation. Each dispatched reviewer subagent owns only its read-only lens.
Provider delivery skills own PR/MR comments, ready transitions, checks,
merge/close calls, issue closeout, and repair execution. This gate may
recommend specialist review comments, but the provider write remains in the
owning delivery workflow and final dispositions stay in the combined delivery
outcome.

## References

- Delivery specialist review gate:
  `skills/code-review/code-review-specialists/references/DELIVERY_SPECIALIST_REVIEW_GATE.md`
- Delivery review outcome comment:
  `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`
- Specialist review comment:
  `skills/code-review/code-review-specialists/references/SPECIALIST_REVIEW_COMMENT.md`
- Review outcome posting contract:
  `skills/code-review/code-review-specialists/references/REVIEW_OUTCOME_POSTING_CONTRACT.md`
- Delivery review outcome schema:
  `skills/code-review/code-review-specialists/references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`
- PR/MR delivery workflow:
  `skills/pr/deliver-pr/SKILL.md`
- Dispatch PR review workflow:
  `skills/dispatch/review-dispatch-lane-pr/SKILL.md`
