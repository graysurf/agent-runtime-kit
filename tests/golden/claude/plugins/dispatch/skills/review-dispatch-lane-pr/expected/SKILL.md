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
  `comments-only`), `REVIEW_LENSES` array, finding dispositions, final
  `REVIEW_COMMENT_FILE`, optional `SPECIALIST_REVIEW_COMMENT_FILE` for one
  specialist-lens progress report, and the retained-evidence path produced by
  `review-evidence`.

Outputs:

- `tracking checkpoint --profile dispatch --live --post review` for the
  lane scope (with `--repair-dashboard` when the dashboard is stale).
  `--live` is the default posting hop so the review evidence writes to
  the provider instead of a dry-run envelope.
- Dispatch lane `state` / `session` update through `tracking
  checkpoint --live --post state,session` when the review outcome flips
  the lane back to implementation.
- `forge-cli pr review` posts provider-visible review activity and mirrors a
  compact progress breadcrumb to the shared dispatch issue. On GitHub, pass
  `--submit-review` so each post is a native review event (`#pullrequestreview-`):
  specialist progress reports use a reviewer bot profile for single mapped
  specialist lenses, `dobi` for unmapped specialist lenses, and
  `--decision comments-only` (a `COMMENT` review event); final lane review
  outcomes set `FORGE_BOT_PROFILE=dobi` with the decision mapped to an `APPROVE`
  / `REQUEST_CHANGES` review event. On GitLab it posts an outcome note and does
  not mutate native approval state.
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

# Native review events (#pullrequestreview-) are GitHub-only; detect the lane's
# provider once and guard --submit-review so GitLab lanes keep the note form
# (an empty array on any non-github / undetected provider is the safe fallback).
SUBMIT_REVIEW=()
if [ "$(forge-cli repo view --repo "$OWNER_REPO" --format json 2>/dev/null \
      | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["provider"])' 2>/dev/null)" = github ]; then
  SUBMIT_REVIEW=(--submit-review)
fi

unset REVIEW_BOT_PROFILE
if [ -n "${REVIEW_LENSES[0]:-}" ] && [ -z "${REVIEW_LENSES[1]:-}" ]; then
  case "${REVIEW_LENSES[0]}" in
    red-team) REVIEW_BOT_PROFILE=review-red-team ;;
    testing) REVIEW_BOT_PROFILE=review-testing-bot ;;
    maintainability) REVIEW_BOT_PROFILE=review-maintainability ;;
    performance) REVIEW_BOT_PROFILE=review-performance ;;
    security) REVIEW_BOT_PROFILE=review-security ;;
    api-contract) REVIEW_BOT_PROFILE=review-api-contract ;;
    data-migration) REVIEW_BOT_PROFILE=review-data-migration ;;
    *) REVIEW_BOT_PROFILE=dobi ;;
  esac
fi

if [ -n "${REVIEW_BOT_PROFILE:-}" ] && [ -n "${SPECIALIST_REVIEW_COMMENT_FILE:-}" ]; then
  FORGE_BOT_PROFILE="$REVIEW_BOT_PROFILE" \
    forge-cli pr review "$PR_NUMBER" \
      --repo "$OWNER_REPO" \
      --decision comments-only \
      "${SUBMIT_REVIEW[@]}" \
      --comment-file "$SPECIALIST_REVIEW_COMMENT_FILE" \
      "${FORGE_LENS_ARGS[@]}" \
      --issue "$ISSUE" \
      --mirror-issue \
      --format json
fi

FORGE_BOT_PROFILE=dobi forge-cli pr review "$PR_NUMBER" \
  --repo "$OWNER_REPO" \
  --decision "$DECISION" \
  "${SUBMIT_REVIEW[@]}" \
  --comment-file "$REVIEW_COMMENT_FILE" \
  "${FORGE_LENS_ARGS[@]}" \
  --issue "$ISSUE" \
  --mirror-issue \
  --format json
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
5. **Provider review activity** — the parent workflow, not the reviewer
   subagent, owns provider writes. When exactly one specialist lens is present
   and `SPECIALIST_REVIEW_COMMENT_FILE` is available, post that specialist
   progress report with the mapped reviewer bot profile or `dobi` for unmapped
   lenses, and `--decision comments-only`. Then post the final lane review
   outcome with `FORGE_BOT_PROFILE=dobi`; this is the only dispatch post that
   carries approve/request-changes outcome metadata.
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
