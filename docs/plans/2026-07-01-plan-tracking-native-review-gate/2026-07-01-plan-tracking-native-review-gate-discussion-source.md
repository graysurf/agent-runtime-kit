# Discussion Source: Align deliver-plan-tracking-issue to deliver-pr's native bot code review

## Trigger

Reviewing `sympoies/nils-cli#1000` (delivered through `deliver-plan-tracking-issue`)
showed no native GitHub review event — only a single `dobi-bot` "Delivery review"
issue comment, and an empty `reviews[]` array on the PR. The maintainer asked
whether the `deliver-plan-tracking-issue` flow performs a bot code review, and
whether that behavior matches `deliver-pr`.

## Findings

### The behavioral gap

- `deliver-pr` runs a mandatory pre-merge review gate: `code-review-pre-merge-gate`
  (specialist lenses) → per-lens native `COMMENT` review events via
  `forge-cli pr review --submit-review` (mapped reviewer-bot profiles) → a combined
  native `APPROVE` / `REQUEST_CHANGES` review event (`dobi`) → review-thread sweep
  (`pr review-threads`, `unresolved==0`) + task-list sweep (`pr tasks`,
  `unchecked==0`) → merge. These native events populate the PR's Reviews section.
- `deliver-plan-tracking-issue` instead calls the one-shot `forge-cli pr deliver`
  macro (create → check → ready → **merge** in one call), leaving no window to
  insert the review gate. Its "Review branch" only *records* a review checkpoint,
  and single-author plans were explicitly allowed to use a self-authored delivery
  outcome comment as the evidence. That is why #1000 showed only an issue comment.

### No CLI capability gap

- Repo pin is `v1.20.1`; `forge-cli` floor is `1.17.0`. Every surface `deliver-pr`
  uses — `pr review --submit-review`, `--thread-file`, `pr review-threads`,
  `pr tasks` — is already available. The alignment is a runtime-kit skill change,
  not a nils-cli change.
- `deliver-plan-tracking-issue`'s Contract still declared a stale `forge-cli >=1.11.2`
  floor; `deliver-dispatch-plan` had the same stale floor.

### The dispatch family already solved this

- `review-dispatch-lane-pr` (floor `1.17.0`) already posts native review events with
  the exact building blocks needed: the GitHub `--submit-review` / `--thread-file`
  guard, the per-lens bot-profile resolver, a specialist `COMMENT` post plus a final
  `APPROVE`/`REQUEST_CHANGES` post, `--issue --mirror-issue` breadcrumb, and the
  `tracking run update --review-outcome-comment` + `tracking checkpoint --post review`
  pair. Its Entrypoint block is a proven template to adapt into the tracking family.

### The issue-side review role is designed to reference a PR-side outcome

- The comment taxonomy's `role=review` template already carries
  `Outcome comment: <provider comment URL or retained evidence path>` and a
  `outcome_comment_url` payload field. So the tracking issue's `review` checkpoint
  is meant to *point at* a PR-side review outcome — today that pointer is a
  self-authored comment; after alignment it becomes a real specialist-gate native
  review event URL.

### The audit-ordering tension (and why Shape 1 avoids it)

- `deliver-pr`'s pre-merge linked-issue lifecycle audit (a skill-level step, not a
  mechanical `forge-cli` gate) expects issue-side `review` evidence present before
  merge; but that evidence's source is the gate that runs during delivery.
  `--mirror-issue` only posts a compact breadcrumb, not a full `role=review`
  lifecycle comment. A wholesale delegation to `deliver-pr` (Shape 2) risks this
  ordering deadlock and could require a nils-cli change.
- Having `deliver-plan-tracking-issue` orchestrate the gate itself and keep merge
  control (Shape 1) sidesteps the tension: `forge-cli pr merge` only fails closed on
  `unresolved_review_threads` / `unchecked_task_items` (+ checks), not on the
  lifecycle audit, so the skill posts the issue-side `review` checkpoint before
  merge on its own schedule.

## Decisions (locked with the maintainer)

1. **Architecture: Shape 1** — `deliver-plan-tracking-issue` self-orchestrates the
   gate. Split the one-shot `pr deliver` into `pr deliver --no-merge` →
   `code-review-pre-merge-gate` → `pr review --submit-review` native events →
   thread/task sweeps → issue-side `review` checkpoint → `pr merge`, reusing
   `review-dispatch-lane-pr`'s block as the template. Runtime-kit only.
2. **single-author: always run the full gate** — remove the single-author
   lightweight exception; all tracking PRs run the multi-lens specialist gate and
   post native review events, matching the general PR path.
3. **Scope: also check dispatch-family consistency** — confirm
   `deliver-dispatch-plan` / `review-dispatch-lane-pr` native-review behavior is
   consistent and fix the stale `forge-cli` floor on `deliver-dispatch-plan`.

## Scope

- In scope: `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera` review
  sub-flow rewrite (Shape 1), its Contract floor/prereq/policy updates; the
  `deliver-dispatch-plan` floor bump; three-product render + golden refresh; full
  `scripts/ci/all.sh` + hooks; a testbed live run confirming the native review
  event flows into `close-ready`.
- Out of scope: any nils-cli change; introducing a separate `review-plan-tracking-pr`
  skill (the lightweight family keeps review folded into `deliver`); changing the
  shared `role=review` taxonomy; the dispatch execution/lane skills beyond the floor
  bump.

## Open question carried into execution

- Whether `plan-issue record audit` hard-requires issue-side `review` evidence at
  the pre-merge point or only at closeout. Shape 1 does not depend on the answer,
  but the testbed live run should observe and record it (settles the Shape 2
  viability question for the future).

## Execution

- Recommended plan: docs/plans/2026-07-01-plan-tracking-native-review-gate/2026-07-01-plan-tracking-native-review-gate-plan.md
- Recommended execution state: docs/plans/2026-07-01-plan-tracking-native-review-gate/2026-07-01-plan-tracking-native-review-gate-execution-state.md
