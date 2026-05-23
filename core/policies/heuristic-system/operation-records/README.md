# Heuristic System Operation Records

Operation records are compressed proof that retained workflow evidence became
durable system behavior: tests, scripts, runbooks, primitives, or skill policy.

Use an operation record when the signal is repeated, cross-skill, audit-worthy,
or useful as proof that the Heuristic System loop operated on a real workflow
failure. Do not create one for every promoted inbox entry.

## Record Folder Layout

Each record is a folder:

- `<slug>/RECORD.md` — durable operation summary.
- `<slug>/evidence/` — optional redacted artifacts written through
  `heuristic-inbox ingest-evidence`.

Verify records before committing or reporting them complete:

```bash
heuristic-inbox verify core/policies/heuristic-system/operation-records/<slug> --strict --format json
```
