# plan-issue close-ready accepts waived tasks but record close rejects them

## Status

- Status: promoted
- First observed: 2026-06-08
- Area: plan-issue tracking closeout gates
- Severity: medium

## Signal

Workflow gap captured from an ingested evidence file. See the Evidence section for the redacted source.

## Evidence

- Raw record: `evidence/plan-issue-waived-closeout-mismatch.md`
- Summary: redacted evidence ingested at creation time; raw logs and secrets were stripped before commit.
- Upstream finding filed: graysurf/plan-tracking-testbed#65 (2026-06-12).
- Fixed upstream in sympoies/nils-cli#825 (merge
  `93d1dcd03149ca3b1e650c4ff2b4f58323081f5c`), released in nils-cli
  `v1.1.0`, and consumed by agent-runtime-kit#321 / runtime-kit
  `v2026.06.13`.

## Impact

Future agents may repeat this workflow gap unless the retained entry is triaged,
routed, and later promoted into a durable fix, runbook, test, script, or skill
policy.

## Current Workaround

No workaround is needed on plan-issue >= 1.1.0. On older hosts, avoid leaving
`waived` task rows at closeout or convert them to a status accepted by both
gates before `record close`.

## Promotion Criteria

Met by sympoies/nils-cli#825: `record close`, `tracking close-ready`, and
`plan-tooling ledger-update` now share the terminal status contract, with
regression coverage and a closed upstream tracker
(graysurf/plan-tracking-testbed#65).

## Next Action

None; fixed by sympoies/nils-cli#825, released in nils-cli `v1.1.0`, and
consumed by agent-runtime-kit#321 / runtime-kit `v2026.06.13`.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/825`

## Archive

- Archived: 2026-06-13
- Reason: Fixed in nils-cli v1.1.0 and consumed by agent-runtime-kit v2026.06.13
- Durable link: `https://github.com/sympoies/nils-cli/pull/825`
