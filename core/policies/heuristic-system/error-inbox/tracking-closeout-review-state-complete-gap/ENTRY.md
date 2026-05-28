# deliver-plan-tracking-issue does not post review / state=complete that closeout requires

## Status

- Status: open
- First observed: 2026-05-28
- Area: dispatch:tracking lifecycle (`deliver-plan-tracking-issue` →
  `plan-tracking-issue-closeout` handoff)
- Severity: medium

## Signal

`plan-issue tracking close-ready --profile tracking --expect-visible` refuses
to mark a tracking issue close-ready unless **both** of these lifecycle
comments are present on the issue:

- `role=review` (`review-missing` blocker)
- `role=state` with payload `status=complete` (`state_complete-missing`
  blocker — distinct from an `in-progress` state checkpoint posted during
  delivery)

`deliver-plan-tracking-issue`'s standard handoff posts `state` (with
`status=in-progress`) and `validation` lifecycle comments after merge, but
does not post `review` or a final `state=complete`. The next skill,
`plan-tracking-issue-closeout`, then refuses to run preflight until those two
posts exist — and its own skill body forbids posting `state` / `session` /
`validation` / `review` "during the closeout window" (`forbidden-role-for-skill`).

For single-author tracking plans (no separate reviewer), there is no skill
that naturally owns posting the prerequisite `review` and `state=complete`
comments. The driver agent has to step outside both skills, hand-call
`plan-issue record post --kind review` and `record post --kind state`
(status=complete), refresh the dashboard, then re-run close-ready.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-05-28, session that
  closed `graysurf/agent-runtime-kit#135`).
- Concrete instance: closing issue #135 after merging PRs
  `graysurf/agent-runtime-kit#141` and `#142`. First `tracking close-ready
  --expect-visible` returned `ready=false` with blockers
  `[{code: "review-missing"}, {code: "state_complete-missing"}]`. Mitigated
  by manually posting `record post --kind review` (single-author approval)
  and `record post --kind state` with `status=complete`, then re-running
  the gate, which then returned `ready=true`.
- Closeout comment that ultimately landed:
  `<https://github.com/graysurf/agent-runtime-kit/issues/135#issuecomment-4560851379>`.
- Skill bodies involved:
  - `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  - `core/skills/dispatch/plan-tracking-issue-closeout/SKILL.md.tera`
    (Failure modes lists `forbidden-role-for-skill` for state/review posts
    during the closeout window).

## Impact

- Every single-author tracking-plan closeout hits this gap. The agent has
  to leave the closeout skill, post two record comments, refresh the
  dashboard, then resume — friction every time, and easy to mis-classify as
  "patching around a blocker" given closeout's "stop on any blocker, never
  patch around it" instruction.
- Multi-author flows still need a `state=complete` post; the `review` post
  is usually covered by an explicit reviewer action upstream, but the
  state-complete prerequisite is documented nowhere in the deliver skill
  body.
- The two skill bodies disagree about lifecycle role ownership for the
  closeout window: deliver's handoff omits the prerequisites, closeout
  refuses to post them. The cross-reference between the two skills should
  cover this hole explicitly.

## Current Workaround

Before invoking `plan-tracking-issue-closeout`, post the missing prerequisite
evidence:

```bash
plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --kind review \
  --profile tracking \
  --payload-file review-payload.json   # decision: approve | request-changes | comments-only

plan-issue --repo "$OWNER_REPO" --format json record post \
  --issue "$ISSUE" \
  --kind state \
  --profile tracking \
  --payload-file state-complete-payload.json   # status: complete + all tasks done

plan-issue --repo "$OWNER_REPO" --format json record repair-dashboard \
  --issue "$ISSUE"

# Now `plan-tracking-issue-closeout` preflight can pass.
```

For single-author plans, a brief `decision: approve` + author-link review
payload is enough; the closeout gate only requires the comment to be
present and well-formed, not externally authored.

## Promotion Criteria

Promote when either:

1. `deliver-plan-tracking-issue`'s skill body explicitly owns posting the
   final `state=complete` (and, for single-author plans, the `review`
   approval) as part of its close-ready handoff, or
2. `plan-tracking-issue-closeout`'s preflight is documented to accept
   these prerequisite posts as in-scope (and its "forbidden-role" rule is
   scoped to *post-closeout* writes), or
3. A new shared "close-ready handoff" sub-skill is introduced that owns
   the prerequisite posts and is called by both deliver and closeout.

In all three cases, update the cross-reference between the two skill
bodies so the lifecycle role ownership is unambiguous.

## Prevention Rule

When two sibling skills sit on either side of a preflight gate, the
upstream skill's "done" state must be a superset of the downstream skill's
"start" requirements — otherwise every operator has to bridge the gap by
hand and the downstream's `forbidden-role` rules become self-contradictory.

## Next Action

Decide ownership between (a) extending deliver-plan-tracking-issue to
post review + state=complete as part of its close-ready handoff, or
(b) loosening closeout's forbidden-role rule to explicitly allow the
prerequisite posts inside its own preflight. Whichever path wins,
update both skill bodies' cross-references at the same time.
