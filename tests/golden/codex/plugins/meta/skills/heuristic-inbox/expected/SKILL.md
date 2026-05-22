---
name: heuristic-inbox
description:
  Manage curated heuristic-system inbox cases and operation records through the nils-cli `heuristic-inbox` command.
---

# Heuristic Inbox

## Contract

Prereqs:

- `heuristic-inbox` is installed from the released nils-cli package and available on `PATH`.
- The caller has identified a real heuristic-system case or a skill-usage record to ingest.
- Evidence is redacted before it is written into a durable case folder.

Inputs:

- Inbox or operation-record path.
- Optional skill-usage record path for new case creation.
- Status transition, archival date, evidence file, or verification request.

Outputs:

- Case listing, verification report, new case folder, status update, archived case, or ingested evidence file.

Failure modes:

- Case folder layout is invalid.
- Status transition is unsupported or missing required links.
- Evidence path is unreadable or unsafe to retain.

## Entrypoint

Use the released CLI directly:

```bash
heuristic-inbox list --format json
heuristic-inbox verify heuristic-system/error-inbox/<slug>/ --format json
heuristic-inbox new --from-skill-usage out/.../skill-usage.record.json --slug pipeline-gap
heuristic-inbox set-status heuristic-system/error-inbox/<slug>/ --status promoted --link docs/plans/foo.md
heuristic-inbox archive heuristic-system/error-inbox/<slug>/ --date 2026-05-22
heuristic-inbox ingest-evidence heuristic-system/error-inbox/<slug>/ --from validation.md
```

## Workflow

1. Verify the target case before changing it.
2. Use `new` only for curated findings that need durable follow-up.
3. Use `set-status` with a link when promoting, resolving, or deferring a case.
4. Use `ingest-evidence` for redacted evidence files instead of copying material by hand.
5. Archive only completed cases whose retained evidence and status are coherent.

## Boundary

`heuristic-inbox` owns case-folder mechanics, redaction-aware evidence ingestion, and lifecycle transitions. The workflow owner decides whether a finding deserves a durable case.
