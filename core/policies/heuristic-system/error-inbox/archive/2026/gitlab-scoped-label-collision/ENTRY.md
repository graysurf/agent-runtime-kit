# GitLab scoped labels collapse two workflow:: labels to one, silently

## Status

- Status: promoted
- First observed: 2026-05-31
- Area: plan-tracking skills + forge-cli labels
- Severity: medium
- CLI versions: plan-issue / plan-tooling / forge-cli 0.31.3
- Source tracking issue: graysurf/plan-tracking-testbed#58
- Source PR (fixture-side mitigation): graysurf/agent-runtime-kit#210
- Source PR (skill guidance): graysurf/agent-runtime-kit#212

## Signal

GitLab scoped labels (`key::value`) are mutually exclusive per scope: applying a
second label in the same scope silently removes the first. The
`create-plan-tracking-issue` / `deliver-plan-tracking-issue` SKILL entrypoints
and the `test-plan-tracking` fixtures recommend two labels in the `workflow::`
scope (`workflow::plan` plus `workflow::tracking` or `workflow::dispatch`). On
GitHub both survive (it treats `::` as plain names); on GitLab the second
application drops the first, and neither `forge-cli` nor `glab` warns.

Surfaced during the rollout's GitLab real-e2e (Task 3.2,
`sympoies/nils-cli#696`): `record open` was told to apply `workflow::plan` and
`workflow::tracking`, the issue kept only `workflow::tracking`, and the driver's
`run.sh assert create` failed with `label missing: workflow::plan`.

## Evidence

- Raw record: not captured (diagnosed live during Task 3.2, 2026-05-31).
- Repro: on a GitLab project, `plan-issue record open --label workflow::plan
  --label workflow::tracking ...` (run from the GitLab checkout); then
  `forge-cli issue view <n> --format json` shows only `workflow::tracking`.
- Target: `terrylin/plan-tracking-testbed-gitlab` on `gitlab.gamania.com`.
- Upstream finding with full repro + fix candidate:
  `graysurf/plan-tracking-testbed#58`.

## Impact

Blocks the GitLab plan-tracking flow at the create gate, silently — the
operator only sees a downstream "label missing" assert, not the dropped label.
Recurs for any skill/fixture/caller that applies more than one label in a
single GitLab scope. GitHub is unaffected, so it is invisible until a real
GitLab run.

## Current Workaround

Carry at most one label per GitLab scope: keep the lifecycle value
(`workflow::tracking` / `workflow::dispatch`) and drop `workflow::plan`. The
`test-plan-tracking` fixtures were fixed this way in
`graysurf/agent-runtime-kit#210`; the SKILL-body recommendation was fixed in
`graysurf/agent-runtime-kit#212` with provider-aware GitLab label guidance.

## Promotion Criteria

Promote when the `create-plan-tracking-issue` / `deliver-plan-tracking-issue`
SKILL entrypoints stop recommending two same-scope `workflow::` labels (and/or
`forge-cli` warns when applying multiple same-scope scoped labels on GitLab),
validated by a green GitLab `assert create`.

## Next Action

None. Source issue graysurf/plan-tracking-testbed#58 closed on 2026-05-31
after graysurf/agent-runtime-kit#212 updated the skill entrypoints with
provider-aware GitLab label guidance; the optional forge-cli warning remains
deferred.

Lifecycle link: `https://github.com/graysurf/plan-tracking-testbed/issues/58`

## Archive

- Archived: 2026-06-06
- Reason: Source issue #58 closed after provider-aware GitLab label guidance
  landed in skill entrypoints.
- Durable link: `https://github.com/graysurf/plan-tracking-testbed/issues/58`
