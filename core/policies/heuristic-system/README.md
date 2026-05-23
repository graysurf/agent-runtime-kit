# Heuristic System Records

This directory is the shared retained-record root for the agent-runtime-kit
Heuristic System. It is product-independent: Codex and Claude should use the
same root when a workflow gap deserves a curated retained case.

See `HEURISTIC_SYSTEM.md` for activation triggers, triage rules, the promotion
ladder, and the compression rule.

## Subdirectories

- `error-inbox/` — active and archived workflow-gap trackers. Each active case
  is a folder `<slug>/` containing `ENTRY.md` and an optional `evidence/`
  subfolder for redacted artifacts. Completed cases keep the same folder shape
  under `error-inbox/archive/YYYY/<slug>/`.
- `operation-records/` — compressed proof that retained evidence became durable
  system behavior. Each record is a folder `<slug>/` containing `RECORD.md`
  plus optional redacted evidence.

Both subdirectories link or summarize raw evidence from its project location.
Do not copy raw runtime evidence, secrets, credentials, or terminal dumps into
committed records.

Use the public `heuristic-inbox` skill and nils-cli primitive for list, verify,
new, set-status, ingest-evidence, and archive operations. Prefer explicit paths:

```bash
root="$PWD/core/policies/heuristic-system"
heuristic-inbox list --inbox-dir "$root/error-inbox" --include-archived --format json
```
