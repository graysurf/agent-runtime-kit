# tracking skills omit --now: epoch placeholder in live run-state

## Status

- Status: open
- First observed: 2026-05-27
- Area: dispatch/create-plan-tracking-issue
- Severity: medium

## Signal

Skill `dispatch/create-plan-tracking-issue` ended with `pass`. Summary: Opened tracking issue graysurf/agent-runtime-kit#132 (3 lifecycle comments; audit overall_pass:true). Discovered + worked around the run-init epoch-placeholder skill-contract gap; filed #134 (skill fix) and sympoies/nils-cli#588 (default hardening).

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260527-232414-plan-archive-search-layer-tracking/skill-usage/skill-usage.record.json`
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

Land graysurf/agent-runtime-kit#134 (pass --now in tracking skill run init/update); track upstream default-hardening sympoies/nils-cli#588
