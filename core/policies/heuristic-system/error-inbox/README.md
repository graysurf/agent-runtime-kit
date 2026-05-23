# Heuristic System Error Inbox

This folder holds curated summaries of important workflow gaps that were not
fixed in the same turn. It prevents important failures from being lost when
local `out/` evidence is cleaned or unavailable.

This is not a raw log archive. Commit only curated, redacted summaries that a
future agent can triage.

## Case Folder Layout

Each active case is a folder directly under this directory:

- `<slug>/ENTRY.md` — the curated tracker.
- `<slug>/evidence/` — optional redacted artifacts written by
  `heuristic-inbox ingest-evidence`.

Archived cases keep the same folder shape under `archive/YYYY/<slug>/`.

## Entry Criteria

Create an inbox entry when a delivery, release, merge, safety, validation, or
evidence gate produced a gap that was not fixed immediately; when the same
failure class appears more than once; when the user explicitly asks to keep the
issue for later improvement; or when a workaround was used and future agents
need to know the unresolved risk.

Observed CLI, hook, validation, dependency, or workflow friction is important
only when repeated retries, unclear output, docs/behavior mismatch, semantic
workaround, skill-contract relevance, or future-agent reuse value justify
retention. Do not retain a case only because a command returned non-zero.

## Lifecycle

- `open`: gap is known and not yet resolved. Use `Next Action` and linked plan,
  issue, or PR references to express progress.
- `promoted`: fixed and compressed into an operation record, test, script,
  runbook, or skill policy.
- `wontfix`: explicitly accepted risk.

A completed entry remains `promoted` or `wontfix`; archive state is represented
by its location under `archive/YYYY/` plus an optional `Archive` section.

## Entry Template

```markdown
# <Short Gap Title>

## Status

- Status: open | promoted | wontfix
- First observed: YYYY-MM-DD
- Area: <skill/script/runbook/tooling>
- Severity: low | medium | high

## Signal

<What failed, in one concise paragraph.>

## Evidence

- Raw record: `<out/.../skill-usage.record.json>`
- Summary: <short command, PR, log, or artifact summary>

## Impact

<Why this matters for future agents or delivery.>

## Current Workaround

<If any.>

## Promotion Criteria

<What would justify a test, script fix, runbook update, skill policy change, or
operation record.>

## Next Action

<One concrete next step.>

## Archive

- Archived: YYYY-MM-DD
- Reason: <why this completed entry left the active inbox>
- Durable link: `<path-or-url>`
```

## Cleanup Rules

`error-inbox/` is retained evidence, not temporary plan coordination. Prefer
archiving completed cases over deleting them. Use `heuristic-inbox archive`
where possible so verification and redaction guardrails stay in the loop.
