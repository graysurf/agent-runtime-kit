# Workaround & Repro — tracking run init `--now` omission

## Environment

- `nils-plan-issue-cli` / `forge-cli` 0.25.2
- Discovered while running `dispatch:create-plan-tracking-issue` →
  opened tracker graysurf/agent-runtime-kit#132.

## Repro

Run `tracking run init` (or `run update`) without `--now`:

    plan-issue tracking run init \
      --provider-repo graysurf/agent-runtime-kit --issue 132 \
      --bundle <bundle> --execution-state-file <state> --branch <branch>

Result — live `run-state.json` gets placeholder values:

- `created_at` / `updated_at` = `1970-01-01T00:00:00Z`
- `run_id` = `00000000000000-issue-132`
- `events.jsonl` `run_started` at epoch

## Root cause

Intentional, documented placeholder in nils-cli (not a regression):
`crates/plan-issue-cli/src/execute.rs:2440` `default_now()` returns
`"1970-01-01T00:00:00Z"` ("deterministic placeholder when no `--now` is
supplied. Tests can pass `--now` for stable values"); `default_run_id()`
(`:2428`) falls back to `"00000000-000000"`. `run_tracking_run_init` (`:1720`)
and `run update` (`:1798`) use `args.now.clone().unwrap_or_else(default_now)`.
The runtime-kit tracking skill contracts omit `--now`, so the placeholder leaks
into live run-state.

## Impact

A 1970 `created_at` can make `execute-plan-tracking-issue`'s reconcile/staleness
logic treat the run as perpetually stale vs. provider comment timestamps.

## Workaround (applied)

Pass an explicit current timestamp:

    plan-issue tracking run init ... --now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

This produces a real `run_id` (e.g. `20260527T154038Z-issue-132`) and correct
`created_at` / `updated_at`. The stale epoch-zero run dir was removed so only the
corrected run-state remains.

## Durable fix tracking

- Skill fix: graysurf/agent-runtime-kit#134 — make tracking skill bodies pass
  `--now` to `tracking run init` / `run update`.
- Upstream hardening: sympoies/nils-cli#588 — flip `default_now()` /
  `default_run_id` to `Utc::now()` for non-test paths (tests already pass
  `--now`).

## Promotion criteria

Promote/resolve once #134 lands (skill bodies pass `--now`, rendered surfaces +
goldens refreshed) and the nils-cli default-hardening decision in #588 is
recorded.
