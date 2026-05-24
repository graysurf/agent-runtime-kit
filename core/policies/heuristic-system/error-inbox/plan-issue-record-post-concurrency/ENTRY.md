# plan-issue record post concurrency can corrupt lifecycle comments

## Status

- Status: open
- First observed: 2026-05-24
- Area: plan-issue
- Severity: medium

## Signal

Skill `plan-issue-record-post` ended with `worked_around`. Summary: Concurrent record-post corruption was worked around by serializing lifecycle posts; heuristic inbox should track whether plan-issue needs a primitive fix or skill policy guard.

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260525-004211-plan-issue-v3-closeout/record-post-concurrency-skill-usage/skill-usage.record.json`
- Summary: linked `skill-usage.record.v1` envelope; raw runtime details remain in the evidence location.

## Impact

Future agents may repeat this workflow gap unless the retained entry is triaged,
routed, and later promoted into a durable fix, runbook, test, script, or skill
policy.

## Current Workaround

Use the linked raw record for details, apply the safest manual workaround for
the affected workflow, and avoid copying raw logs or secrets into this entry.

## Promotion Criteria

Promote after the durable fix or accepted-risk decision is implemented,
validated, and linked from this entry.

## Next Action

Confirm whether nils-cli plan-issue record post needs a concurrency lock or whether runtime-kit skills should explicitly serialize lifecycle post calls; upstream issue search found no open match for 'plan-issue record post parallel'.
