---
name: evidence-prune-source
description: >
  Prune local agent-out skill-usage source records already present in the
  agent-evidence-archive through nils-cli `evidence prune-source`.
---

# Evidence Prune Source

## Contract

Prereqs:

- `evidence` is installed from the released nils-cli package and available on
  `PATH` (`>= 1.12.0`, which ships `evidence prune-source`).
- The source tree is the agent-out projects root. By default the CLI resolves
  `${AGENT_HOME}/out/projects`; override with `--source-out` only for a known
  fixture or non-default runtime tree.
- The archive repository is cloned locally and resolvable from
  `$AGENT_EVIDENCE_ARCHIVE_HOME`, the machine-local config at
  `$XDG_CONFIG_HOME/agent-evidence-archive/config.yaml`, the XDG data-home
  default, or `--archive`.

Inputs:

- Optional scope filters: `--repo <owner__repo-or-repo-name>`.
- Optional `--source-out` and `--archive` path overrides.

Outputs:

- A dry-run JSON report with `scanned`, `prunable`, `kept`, `deleted`,
  `pruned[]`, and `retained[]`.
- On confirmed apply: local agent-out run directories listed in `pruned[]`
  deleted from the source tree. The archive repository is read-only for this
  command.

Failure modes:

- `--archived-only` is missing. Treat this as a hard safety failure; never retry
  without it.
- The source-out root or archive clone is unresolved.
- Source files cannot be read or a delete fails. Surface the exact report/error;
  do not manually `rm` around the CLI.

## Entrypoint

When invoking this skill directly, always run the dry-run first:

```bash
evidence prune-source --archived-only --format json
```

Only after the user explicitly confirms the dry-run report, apply:

```bash
evidence prune-source --archived-only --apply --format json
```

Scope filters compose with both forms, e.g.:

```bash
evidence prune-source \
  --repo graysurf__agent-runtime-kit \
  --archived-only \
  --apply \
  --format json
```

## Workflow

1. Run `evidence prune-source --archived-only --format json` and present
   `scanned`, `prunable`, `kept`, and the `pruned[]` / `retained[]` reasons.
   A dry-run with `prunable = 0` is a successful no-op.
2. Confirm that every `pruned[]` row is expected. The CLI only marks a row
   prunable when the raw `skill-usage.record.json` digest exists in the archive
   `catalog.json`; `retained[]` rows remain in agent-out.
3. For direct use of this skill, stop and require explicit user confirmation
   before applying. The automatic apply path belongs to
   `heuristic-session-closeout` after its clean migration and clean
   prune-source dry-run checks.
4. On confirmation, rerun the same command with `--apply`. Report `deleted`,
   the pruned source paths, and the retained count. Remind the user that this
   command does not write, delete, commit, or push anything in the archive.
5. On any failure, surface the CLI error code/message and do not delete source
   directories manually.

## Boundary

`evidence prune-source` owns source enumeration, raw record digest calculation,
archive catalog matching, dry-run reporting, and source directory deletion on
`--apply`. The skill owns the dry-run-first review and direct-use confirmation
gate. It does not migrate records, scrub data, write archive files, commit or
push the archive, delete unarchived local records, or bypass the required
`--archived-only` safety scope.

## Related Skills

- `evidence-migrate` — copy-only retention into the archive. Run migration
  before pruning; migrate never deletes source records.
- `heuristic-session-closeout` — triggers the normal session-end durability
  lane: migrate first, then prune already-archived source records when the
  dry-run is clean.
