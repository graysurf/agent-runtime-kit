# skill-usage concurrent write evidence

## Context

- Repository: sympoies/symphony-board
- Workflow: deliver-pr for PR #106
- Date: 2026-06-08 UTC

## Observation

Two `skill-usage record-validation` commands were sent in one parallel tool call
against the same `--out` directory. Both command calls returned success, but a
subsequent `skill-usage show` failed with:

```text
invalid-json: failed to parse .../skill-usage.record.json: trailing characters at line 130 column 2
```

This strengthens the existing concurrency case: same-record parallel writes can
corrupt the JSON file, not only drop or duplicate validation entries.

## Handling

- Stopped using the corrupted record.
- Created a replacement `skill-usage` record in a new directory.
- Rewrote validation and failure entries serially.
- Verified the replacement record with `skill-usage verify --format json`.

## Evidence Pointers

- Corrupted record: `<workspace>/.local/state/agent-runtime-kit/out/projects/sympoies__symphony-board/20260609-005708-skill-usage/skill-usage.record.json`
- Replacement verified record: `<workspace>/.local/state/agent-runtime-kit/out/projects/sympoies__symphony-board/20260609-010632-skill-usage/skill-usage.record.json`
