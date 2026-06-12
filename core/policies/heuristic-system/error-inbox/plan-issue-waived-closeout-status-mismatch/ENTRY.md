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
- Upstream finding filed: graysurf/plan-tracking-testbed#65 (2026-06-12).

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

Track graysurf/plan-tracking-testbed#65 (filed 2026-06-12): unify the
close-ready / record close terminal-status contract (either record close
accepts waived terminal tasks, or close-ready rejects them) and align the
`ledger-update` status enum with whatever the gates accept. Promote once the
fix lands.
