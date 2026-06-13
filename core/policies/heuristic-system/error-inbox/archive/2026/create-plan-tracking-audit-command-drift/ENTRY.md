# create-plan-tracking-issue skill uses stale plan-issue record audit command

## Status

- Status: promoted
- First observed: 2026-06-13
- Area: dispatch/create-plan-tracking-issue skill; plan-issue record audit surface
- Severity: medium

## Signal

While running `dispatch:create-plan-tracking-issue` for
`graysurf/agent-runtime-kit#330`, the rendered skill's read-back step told the
agent to run:

```bash
plan-issue --repo graysurf/agent-runtime-kit --format json record audit \
  --profile tracking --issue 330 --expect-visible
```

With the installed `plan-issue 1.1.0`, that invocation exits as a usage error:
`record audit` now requires issue body/comment input via `--comments-json`
(and, for the current provider shape, `--body-file`). The workflow completed
only because the agent deviated to supported read-back commands:
`plan-issue tracking status --expect-visible` for live reconciliation and
`plan-issue record audit --comments-json ... --body-file ...` for lifecycle
evidence audit.

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260614-013603-skill-usage/skill-usage.record.json`
- Summary: linked `skill-usage.record.v1` envelope; raw runtime details remain in the evidence location.
- Resolved by: https://github.com/graysurf/agent-runtime-kit/pull/333

## Impact

Future agents following the skill body literally will stop after opening the
tracking issue, even though the provider evidence is healthy. The stale command
also weakens the value of the skill as the canonical create-tracker runbook:
the source spec and rendered Codex target are out of sync with the current
`plan-issue record audit` CLI contract while repo validation still passes.

## Current Workaround

After `record open`, initialize run state and verify live evidence with:

```bash
plan-issue tracking status --provider-repo <owner/repo> --issue <number> \
  --bundle <bundle> --run-state <run-state.json> --expect-visible --format json
```

If a `record audit` result is also needed, first capture provider issue body
and comments, then run:

```bash
plan-issue record audit --repo <owner/repo> --comments-json <issue.json> \
  --body-file <issue-body.md> --profile tracking --expect-visible --format json
```

## Promotion Criteria

Promote after `core/skills/dispatch/create-plan-tracking-issue/SKILL.md.tera`
is updated to the current read-back surface, rendered Codex / Claude targets are
refreshed, and validation proves the documented command works against
`plan-issue 1.1.0` or its successor.

## Next Action

None. Resolved by PR #333: create-plan-tracking-issue step 6 now captures the
live issue body and comments and passes `--body-file` / `--comments-json` to
`record audit`, the form `plan-issue 1.2.0` requires; the codex and claude
goldens were refreshed and the full `scripts/ci/all.sh` gate (including the
dispatch runtime-smoke probe) is green against the v1.2.0 pin. Not covered: the
identical bare `record audit --profile <p> --expect-visible` form still appears
in `plan-tracking-issue-closeout` (step 6) and `dispatch-plan-closeout`
(step 5); track those as a separate follow-up.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/pull/333`

## Archive

- Archived: 2026-06-13
- Reason: create-plan-tracking-issue read-back aligned to the `plan-issue 1.2.0`
  `record audit` input contract (PR #333); validated green against the v1.2.0
  pin.
- Durable link: `https://github.com/graysurf/agent-runtime-kit/pull/333`
