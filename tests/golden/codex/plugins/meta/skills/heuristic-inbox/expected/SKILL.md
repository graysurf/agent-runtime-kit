---
name: heuristic-inbox
description:
  Manage curated heuristic-system inbox cases and operation records through the nils-cli `heuristic-inbox` command.
---

# Heuristic Inbox

## Contract

Prereqs:

- `heuristic-inbox` is installed from the released nils-cli package and available on `PATH`.
- For runtime-kit shared records, resolve the canonical root before mutating:
  `core/policies/heuristic-system/` in the active `agent-runtime-kit` checkout,
  or `AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT` when a workflow exports it.
- The caller has identified a real heuristic-system case or a skill-usage record to ingest.
- Evidence is redacted before it is written into a durable case folder.

Inputs:

- Shared heuristic-system root, inbox directory, or operation-record path.
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
root="${AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT:-$PWD/core/policies/heuristic-system}"
heuristic-inbox list --inbox-dir "$root/error-inbox" --include-archived --format json
heuristic-inbox verify "$root/error-inbox/<slug>" --strict --format json
heuristic-inbox verify "$root/operation-records/<slug>" --strict --format json
heuristic-inbox new --from-skill-usage out/.../skill-usage.record.json --slug pipeline-gap --out-dir "$root/error-inbox"
heuristic-inbox set-status "$root/error-inbox/<slug>" --status promoted --link docs/plans/foo.md
heuristic-inbox archive "$root/error-inbox/<slug>" --date 2026-05-22
heuristic-inbox ingest-evidence "$root/error-inbox/<slug>" --from validation.md
```

## Workflow

1. Resolve the shared root explicitly. Do not rely on cwd when the case should be shared across Codex and Claude.
2. Verify the target case before changing it.
3. Use `new` only for curated findings that need durable follow-up.
4. Use `set-status` with a link when promoting, resolving, or deferring a case.
5. Use `ingest-evidence` for redacted evidence files instead of copying material by hand.
6. Archive only completed cases whose retained evidence and status are coherent.

## Boundary

`heuristic-inbox` owns case-folder mechanics, redaction-aware evidence ingestion, and lifecycle transitions. The workflow owner decides whether a finding deserves a durable case and which shared root to pass to the CLI.
