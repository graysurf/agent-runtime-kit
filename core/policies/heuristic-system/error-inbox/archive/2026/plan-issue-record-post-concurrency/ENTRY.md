# plan-issue record post concurrency can corrupt lifecycle comments

## Status

- Status: promoted
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

None. Promoted into sympoies/nils-cli#793 after local upstream validation and runtime-kit e2e; release/pin follow-up belongs to nils-cli delivery.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/793`

## Archive

- Archived: 2026-06-06
- Reason: Promoted to nils-cli primitive fix with runtime-kit e2e validation
- Durable link: `https://github.com/sympoies/nils-cli/pull/793`
