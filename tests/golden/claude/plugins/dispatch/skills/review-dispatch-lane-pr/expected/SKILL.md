---
name: review-dispatch-lane-pr
description: >
  Review one dispatch lane PR with retained evidence, post provider review comments, and update the shared dispatch issue with the review decision.
---

# Review Dispatch Lane PR

## Contract

Prereqs:

- Profile: `dispatch`.
- CLI floors: `plan-issue >=1.0.13`, `forge-cli >=1.13.0`,
  `review-evidence`.
- Issue precondition: the shared dispatch issue exists and the lane PR
  has been created by `execute-dispatch-lane` /
  `create-dispatch-lane-pr`.
- PR precondition: the PR exists, targets the correct base, and
  reports passing required checks (or the reviewer has explicit
  override authority).
- Run state precondition: `tracking status --profile dispatch
  --expect-visible` is clean before recording review status.
- Shared family rules from the Plan Issue Skill Family
  spec apply (see the Shared Family Rules section in
  core/skills/dispatch/plan-issue-spec/).

Inputs:

- `OWNER_REPO`, `ISSUE` (shared dispatch issue), `RUN_STATE`.
- `LANE_PR` reference and `PR_NUMBER`.
- Reviewer decision (`approve` / `request-changes` /
  `comments-only`), `REVIEW_LENSES` array, finding dispositions, and the
  retained-evidence path produced by `review-evidence`.

Outputs:

- `tracking checkpoint --profile dispatch --live --post review` for the
  lane scope (with `--repair-dashboard` when the dashboard is stale).
  `--live` is the default posting hop so the review evidence writes to
  the provider instead of a dry-run envelope.
- Dispatch lane `state` / `session` update through `tracking
  checkpoint --live --post state,session` when the review outcome flips
  the lane back to implementation.
- `forge-cli pr review` posts provider-visible review outcome metadata and
  mirrors a compact progress breadcrumb to the shared dispatch issue. Set a
  reviewer bot profile only for single mapped specialist lenses; set
  `FORGE_BOT_PROFILE=dobi` for combined or unknown-lens owner summaries.
  It does not mutate native provider approval or request-changes state.
- `review-evidence` produces a retained findings artifact path or
  URL.

Failure modes:

- Forbidden lifecycle roles for this skill: `record open`,
  `record close`, lane implementation posts beyond review-driven
  state flips. Direct posts abort with `forbidden-role-for-skill`.
- Controller refusal codes propagated: `run-state-stale`,
  `RECORD_BLOCKED`,
  `visible-completeness-failed`.
- Provider payload privacy failures such as `local_path_present`: rewrite
  useful evidence paths to `$HOME/...` and omit remote-useless local artifact
  paths before retrying.
- Visible-completeness lint codes relevant here:
  `review-missing-decision`, `review-missing-disposition`,
  `state-missing-task-ledger`.
- Scope-leak: implementing fixes inside this skill; merging the PR;
  posting raw `gh pr review` / `glab mr approve` for recorded review
  evidence; skipping retained `review-evidence` when findings exist.

## Entrypoint

```bash
plan-issue --format json tracking status \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" --expect-visible

review-evidence --plan "$PLAN" --pr "$LANE_PR" --format json \
  >"$REVIEW_EVIDENCE"

REVIEW_LENS_ARGS=()
for lens in "${REVIEW_LENSES[@]}"; do
  REVIEW_LENS_ARGS+=(--review-lens "$lens")
done

FORGE_LENS_ARGS=()
for lens in "${REVIEW_LENSES[@]}"; do
  FORGE_LENS_ARGS+=(--lens "$lens")
done

plan-issue --format json tracking run update \
  --run-state "$RUN_STATE" --review-decision "$DECISION" \
  "${REVIEW_LENS_ARGS[@]}" \
  --review-outcome-comment "$REVIEW_EVIDENCE" \
  --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

plan-issue --format json tracking checkpoint \
  --provider-repo "$OWNER_REPO" --issue "$ISSUE" \
  --profile dispatch --run-state "$RUN_STATE" \
  --live \
  --post review --repair-dashboard

unset REVIEW_BOT_PROFILE
if [ -n "${REVIEW_LENSES[0]:-}" ] && [ -z "${REVIEW_LENSES[1]:-}" ]; then
  case "${REVIEW_LENSES[0]}" in
    red-team) REVIEW_BOT_PROFILE=review-red-team ;;
    testing) REVIEW_BOT_PROFILE=review-testing-bot ;;
    maintainability) REVIEW_BOT_PROFILE=review-maintainability ;;
    performance) REVIEW_BOT_PROFILE=review-performance ;;
  esac
fi

if [ -n "${REVIEW_BOT_PROFILE:-}" ]; then
  FORGE_BOT_PROFILE="$REVIEW_BOT_PROFILE" \
    forge-cli pr review "$PR_NUMBER" \
      --repo "$OWNER_REPO" \
      --decision "$DECISION" \
      --comment-file "$REVIEW_COMMENT_FILE" \
      "${FORGE_LENS_ARGS[@]}" \
      --issue "$ISSUE" \
      --mirror-issue \
      --format json
else
  FORGE_BOT_PROFILE=dobi forge-cli pr review "$PR_NUMBER" \
    --repo "$OWNER_REPO" \
    --decision "$DECISION" \
    --comment-file "$REVIEW_COMMENT_FILE" \
    "${FORGE_LENS_ARGS[@]}" \
    --issue "$ISSUE" \
    --mirror-issue \
    --format json
fi
```

## Workflow

1. **Preflight** — `tracking status --profile dispatch --expect-visible`;
   refuse to record review state on `run-state-stale` or
   `RECORD_BLOCKED`.
2. **Review judgement** — apply review lenses; produce
   `$REVIEW_EVIDENCE` through `review-evidence`. Findings get
   dispositions before approval.
3. **Run state update** — `tracking run update --review-decision` plus
   review lenses and retained outcome evidence. Repeat `--review-lens`
   for every applied lens and pass `--review-findings-file
   "$REVIEW_FINDINGS_JSON"` when findings exist.
4. **Review checkpoint** — `tracking checkpoint --live --post review
   --repair-dashboard`. If findings flip the lane back to
   implementation, also post `state,session` for the lane scope.
5. **Provider review outcome** — `forge-cli pr review` records the
   decision as provider-visible outcome metadata and mirrors the review URL to
   the shared issue. The parent workflow, not the reviewer subagent, owns
   provider writes. Map `red-team`, `testing`, `maintainability`, and
   `performance` to their reviewer bot profiles only when exactly one lens is
   present; set `FORGE_BOT_PROFILE=dobi` for combined or unknown-lens owner
   summaries so `dobi-bot` posts it.
6. **Read-back** — confirm the dispatch dashboard reflects the lane
   review status and the lane PR carries the review comment.
7. **Stop** on any Failure mode code; do not implement fixes unless
   the user explicitly switches the lane from review to
   implementation.

## Boundary

Owns:

- The review judgement (decision, lenses, finding dispositions).
- The decision to flip the lane back to implementation when findings
  block approval.

Does not own:

- Implementing fixes — that is `execute-dispatch-lane` after the
  redirection.
- Closing the dispatch issue — that is `dispatch-plan-closeout`.
- Merging the PR — `forge-cli` and the active PR delivery skills.
- Retained findings format — that is `review-evidence`.

Cross-references:

- Upstream: `execute-dispatch-lane` produces the lane PR.
- Downstream: back to `execute-dispatch-lane` on
  `request-changes`; otherwise on to `dispatch-plan-closeout` once
  all lanes are clean.
- Family rules: Plan Issue Skill Family, Shared Family
  Rules section (under core/skills/dispatch/plan-issue-spec/).
