# plan-issue close-ready accepts waived tasks but record close rejects them

## Status

- Status: open
- First observed: 2026-06-08
- Area: plan-issue tracking closeout gates
- Severity: medium

## Signal

Workflow gap captured from an ingested evidence file. See the Evidence section for the redacted source.

## Evidence

- Raw record: `evidence/plan-issue-waived-closeout-mismatch.md`
- Summary: redacted evidence ingested at creation time; raw logs and secrets were stripped before commit.

## Impact

Future agents may repeat this workflow gap unless the retained entry is triaged,
routed, and later promoted into a durable fix, runbook, test, script, or skill
policy.

## Current Workaround

Apply the safest manual workaround for the affected workflow until the durable
fix lands, and avoid copying raw logs or secrets into this entry.

## Promotion Criteria

Promote after the durable fix or accepted-risk decision is implemented,
validated, and linked from this entry.

## Next Action

File or fix a nils-cli plan-issue gate consistency issue: either record close should accept waived terminal tasks, close-ready should reject them, or ledger-update should expose deferred if that is the intended closeout status.
