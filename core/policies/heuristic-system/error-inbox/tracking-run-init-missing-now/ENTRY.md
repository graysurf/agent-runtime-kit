# tracking skills omit --now: epoch placeholder in live run-state

## Status

- Status: open
- First observed: 2026-05-27
- Host-side fix landed: 2026-05-27 (sympoies/nils-cli#589)
- Area: dispatch/create-plan-tracking-issue
- Severity: low

## Signal

Skill `dispatch/create-plan-tracking-issue` ended with `pass`. Summary: Opened tracking issue graysurf/agent-runtime-kit#132 (3 lifecycle comments; audit overall_pass:true). Discovered + worked around the run-init epoch-placeholder skill-contract gap; filed #134 (skill fix) and sympoies/nils-cli#588 (default hardening).

## Evidence

- Raw record: `<workspace>/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260527-232414-plan-archive-search-layer-tracking/skill-usage/skill-usage.record.json`
- Summary: linked `skill-usage.record.v1` envelope; raw runtime details remain in the evidence location.
- Host-side resolution (2026-05-27): sympoies/nils-cli#589 merged (squash `b92c57d`). `plan-issue tracking run init`/`run update` now default `created_at`/`updated_at` and the derived `run_id` to `Utc::now()` (RFC3339 `Z`) when `--now` is omitted, replacing the `1970-01-01T00:00:00Z` epoch placeholder; `--now` stays the deterministic override. Closed sympoies/nils-cli#588.

## Impact

Future agents may repeat this workflow gap unless the retained entry is triaged,
routed, and later promoted into a durable fix, runbook, test, script, or skill
policy.

Update (2026-05-27): the dangerous outcome — a `1970` `created_at` poisoning
downstream staleness/reconcile logic — can no longer arise from omitting
`--now`, because the host CLI now defaults to wall-clock UTC (nils-cli#589).
The residual gap is cosmetic: runtime-kit tracking skills should still pass
`--now` for deterministic parity, but omitting it is no longer unsafe.

## Current Workaround

Use the linked raw record for details, apply the safest manual workaround for
the affected workflow, and avoid copying raw logs or secrets into this entry.

## Promotion Criteria

Promote after the durable fix or accepted-risk decision is implemented,
validated, and linked from this entry.

## Next Action

Land graysurf/agent-runtime-kit#134 (pass `--now` in the tracking skill run init/update examples for deterministic parity). Upstream default-hardening is done — sympoies/nils-cli#588 closed via nils-cli#589 — so the remaining work is skill-side only and no longer safety-critical.
