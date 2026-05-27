---
name: plan-archive-query
description:
  Read and refresh the agent-plan-archive work-history cache through the nils-cli `plan-archive query` and `plan-archive refresh` commands, holding any refresh commit until the scrub log is reviewed.
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
2. For reads, present each record's `fetched_at` so the user can judge
   staleness.
3. For a refresh, run the command, then inspect the JSON
   `requires_review` flag. If any snapshot emitted a `.scrub.log`,
   stop and have the user review the log before committing the
   snapshot. Never commit a redacted snapshot without that review.
4. After review, commit the new `_index/` snapshots through the
   standard commit flow. Snapshots are append-only — never overwrite
   or delete an existing one.

## Boundary

`plan-archive query` owns cache reads, cross-repo aggregation, and
plan↔ref link traversal; `plan-archive refresh` owns the forge-cli
fetch, secret scrubbing, and append-only snapshot writes. The skill
body owns the read-vs-refresh decision, surfacing `fetched_at`, and
enforcing the scrub-log review gate before any refresh commit. It
never instructs the user to call `forge-cli` directly for a payload
the CLI already fetches.
