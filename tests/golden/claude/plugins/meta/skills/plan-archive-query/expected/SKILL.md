---
name: plan-archive-query
description:
  Read and refresh the agent-plan-archive work-history cache through the nils-cli `plan-archive query` and `plan-archive refresh` commands before opening a new plan or diagnosing a suspected recurring problem; hold any refresh commit until the scrub log is reviewed.
---

# Plan Archive Query

## Contract

Prereqs:

- `plan-archive` is installed from the released nils-cli package and
  available on `PATH`.
- `forge-cli` is installed and authenticated for refresh; the archive
  system delegates all provider access to it.
- The archive clone path is resolvable from the machine-local config
  at `$XDG_CONFIG_HOME/agent-plan-archive/config.yaml` (or passed with
  `--archive`). The skill never hardcodes the clone path.

Inputs:

- For reads: a single ref URL (`--ref`), aggregate filters
  (`--host` / `--org` / `--repo` / `--since`), or an archived-plan
  link (`--plan` / `--refs-from`).
- For discovery: grep over `<archive-root>/catalog.json` when the
  exact issue, PR, MR, or plan ref is unknown.
- For refresh: a single ref (`--ref`) or a repo batch
  (`--repo` [`--since`]).

Outputs:

- Query JSON with each record's latest snapshot path and `fetched_at`
  (surfaced by default, never behind a verbose flag).
- Refresh JSON listing the written snapshots, any `.scrub.log`
  siblings, and a `requires_review` flag.

Failure modes:

- An unparseable ref, an unknown host, a missing archive clone, or a
  metadata file with no refs.
- A refresh whose payload triggered redactions: the snapshot is
  written but the commit must be held until the `.scrub.log` is
  reviewed.

## Entrypoint

Read the cache (default):

```bash
plan-archive query --ref <issue-or-pr-or-mr-url> --format json
plan-archive query --host <fqdn> [--org <o>] [--repo <r>] [--since <YYYY-MM-DD>] --format json
plan-archive query --plan <archive-plan-path> --format json
```

Refresh a snapshot (writes + scrubs, never commits):

```bash
plan-archive refresh --ref <url> --format json
plan-archive refresh --repo <host/org/repo> [--since <YYYY-MM-DD>] --format json
```

## Workflow

1. Default to reading the cache; only refresh when the user asks for
   fresh data or a ref is known to be stale.
2. Consult the archive only before opening a new plan or when
   diagnosing a suspected recurring / previously resolved problem; do
   not turn lookup into an every-task step.
3. For reads, present each record's `fetched_at` so the user can judge
   staleness.
4. For a refresh, run the command, then inspect the JSON
   `requires_review` flag. If any snapshot emitted a `.scrub.log`,
   stop and have the user review the log before committing the
   snapshot. Never commit a redacted snapshot without that review.
5. After review, commit the new `_index/` snapshots through the
   standard commit flow. Snapshots are append-only — never overwrite
   or delete an existing one.

## Boundary

`plan-archive query` owns cache reads, cross-repo aggregation, and
plan↔ref link traversal. `plan-archive refresh` owns the forge-cli
payload fetch, the scrubbing pass, and the append-only snapshot
writes. The skill body owns the read-vs-refresh decision, surfacing
`fetched_at`, and enforcing the scrub-log review gate before any
refresh commit. It relies on the CLI for every provider payload
instead of calling `forge-cli` for the same data.

## Related Skills

- `plan-archive-discover` — read-only scanner over a working repo's
  plan folders. Use it when the question is "which of my local plan
  folders are ready to archive?" rather than "what was the outcome
  of past plan X?".
- `plan-archive-migrate` — destructive single-folder archival path.
  After query confirms a plan's archive target is clear, discover
  selects the candidate and migrate applies it.
