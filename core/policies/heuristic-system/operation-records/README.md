# Heuristic System Operation Records

An operation record is the **cross-case compression rule**: one durable rule
distilled from two or more resolved cases that share a root cause, plus proof
that the retained evidence became durable system behavior (tests, scripts,
runbooks, primitives, or skill policy).

This is the narrow tip of the promotion ladder, not a per-case artifact. A
single resolved case is already captured by its archived inbox `ENTRY.md` plus
whatever it promoted into; a single-case record only duplicates that. Reserve a
record for what those cannot hold: a reusable rule a future agent applies when
writing *new* similar code, plus audit proof the loop operated across a broader
surface. See `HEURISTIC_SYSTEM.md` for the full triage and the Compression Rule.

## Record Folder Layout

Each record is a folder:

- `<slug>/RECORD.md` — durable operation summary.
- `<slug>/evidence/` — optional redacted artifacts written through
  `heuristic-inbox ingest-evidence`.

Verify records before committing or reporting them complete:

```bash
heuristic-inbox verify core/policies/heuristic-system/operation-records/<slug> --strict --format json
```

## Lifecycle

Operation records are born resolved (the fix already landed), so they do not use
the inbox `open → promoted` lifecycle. The `## Status` block tracks whether the
rule is still load-bearing:

- `Status: active | superseded | retired`.
- Optional `Cluster: <kebab-slug>` — the shared root-cause class, matching the
  `Cluster:` field on the inbox entries this record compresses. The closeout
  cluster sweep groups on it.
- Optional `Enforced-by: <gate/CLI>` — a CI gate, hook, or released CLI behavior
  that now mechanically upholds the rule.
- Optional `Superseded-by: <path-or-record>` — the gate, CLI, or broader
  re-compressed record that replaced this one.

A record becomes a `superseded` / `retired` archive candidate when its rule is
mechanically enforced, its governed surface is retired, or it is absorbed into a
broader record. Archive retired records under
`operation-records/archive/YYYY/<slug>/`, mirroring the inbox archive; archiving
preserves the record as audit history and never deletes it. Use
`heuristic-inbox archive` against the operation-record path, passing the
operation-records directory explicitly when needed so the destination stays in
the operation-records archive:

```bash
heuristic-inbox set-status core/policies/heuristic-system/operation-records/<slug> --status superseded --link <successor>
heuristic-inbox archive core/policies/heuristic-system/operation-records/<slug> --inbox-dir core/policies/heuristic-system/operation-records --date YYYY-MM-DD
heuristic-inbox verify core/policies/heuristic-system/operation-records/archive/YYYY/<slug> --strict --format json
```
