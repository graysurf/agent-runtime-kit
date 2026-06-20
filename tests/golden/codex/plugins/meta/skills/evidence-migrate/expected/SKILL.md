---
name: evidence-migrate
description: >
  Migrate skill-usage evidence from the ephemeral agent-out runtime tree into
  the agent-evidence-archive repository through the nils-cli `evidence
  migrate` command; dry-run first, applies only on explicit confirmation.
---

# Evidence Migrate

## Contract

Prereqs:

- `evidence` is installed from the released nils-cli package and
  available on `PATH` (`>= 1.8.0`, the floor that hardens cwd/origin and slug
  identity matching, home-relativizes an absolute skill path so a rollup's
  `id`, directory name, and `skill` field never leak the machine home, and
  carries the unclassified-host block — the gamania-safety guarantee — the
  `--host` vouch, the `working_repo_roots` identity rescue, purge apply safety,
  and skip-and-report blocked-record handling).
- `semantic-commit` is installed from the released nils-cli package and
  available on `PATH` (`>= 0.25.0`; the apply path commits the archive through
  it).
- The archive repository is cloned locally and its path is resolvable
  from `$AGENT_EVIDENCE_ARCHIVE_HOME`, the machine-local config at
  `$XDG_CONFIG_HOME/agent-evidence-archive/config.yaml`, or the XDG
  data-home default (`${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive`),
  or passed with `--archive`. The skill never hardcodes the clone path.
- The archive declares its known hosts in `config/hosts.yaml`; a record
  can only be archived to a host present in that file.

Inputs:

- Optional scope filters: `--repo <owner__repo>`, `--skill <substring>`,
  `--since`/`--until <YYYY-MM-DD>`, `--promotion-only`.
- Optional `--source-out`, `--archive`, and `--hosts` path overrides.
- Optional `--host <fqdn>` to vouch for the host of slug-only records
  under a multi-host archive (see Workflow step 4).

Outputs:

- A dry-run JSON report: counts (`scanned` / `eligible` / `skipped`),
  the prepared records (archive target id + path, files that would be
  written, per-record scrub summary, source path, warnings), the
  `already_archived` digests skipped as duplicates, and the `blocked`
  list (records whose repo identity could not be resolved, or whose
  resolved host is absent from `config/hosts.yaml`, with a reason) for
  the user to review.
- On confirmed apply: the archive rollup + `metadata.yaml` + scrubbed
  linked-evidence + scrub-log files written under the archive, a
  regenerated `catalog.json`, and one archive commit. The CLI commits
  AND pushes the archive repository as part of its transaction. The
  agent-out source tree is left intact — migration is copy-only and
  idempotent (re-runs dedup by digest). Source deletion is a separate
  `evidence-prune-source` cleanup step, never part of migration; there is no
  working-repo push to perform.

Failure modes:

- The agent-out source root or the archive clone is unresolved, or the
  archive `config/hosts.yaml` is missing or invalid.
- On `--apply`, the archive working tree is dirty under `evidence/` or
  `catalog.json` (apply refuses rather than commit unrelated changes).
- A `git` or `semantic-commit` subprocess fails after staging; the
  archive push is the last step, so a failure leaves the archive
  un-pushed and the agent-out source untouched.
- Unresolvable, unclassified-host, or unreadable records are NOT a
  failure: they are reported in `blocked` and skipped, and the rest of
  the batch still migrates. An all-blocked run is a successful no-op.

## Entrypoint

When invoking this skill directly, always run the dry-run first (it is the
default — no flag needed) and show its JSON to the user:

```bash
evidence migrate --format json
```

Only after the user explicitly confirms the dry-run report, apply:

```bash
evidence migrate --apply --format json
```

Scope filters and the host vouch compose with both forms, e.g.:

```bash
evidence migrate --repo graysurf__agent-runtime-kit --host github.com --apply --format json
```

## Workflow

1. Run `evidence migrate --format json` (dry-run) and present the
   counts, the prepared archive targets, the per-record scrub summary
   (`patterns_triggered` + `total_matches`), the `already_archived`
   duplicates, and the `blocked` list to the user.
2. For direct use of this skill, stop and require explicit user confirmation
   before applying. Never auto-apply from this skill; the only automatic apply
   path is `heuristic-session-closeout` step 8 after its clean-dry-run checks.
3. Review the scrub summary with the user before applying: the command
   redacts matched secrets in place and writes a scrub log alongside
   each record, but the operator should still recognize what was
   redacted. Do not bypass or disable scrubbing.
4. Resolve `blocked` records deliberately. There are two common host
   cases:
   - If repo identity cannot be derived — most often a slug-only
     agent-out directory under a multi-host `config/hosts.yaml`, where
     the host is ambiguous — do not guess. For records the user
     recognizes, re-run with `--host <fqdn>` (a host present in
     `config/hosts.yaml`) to vouch for the host; leave records the user
     cannot vouch for blocked.
   - If repo identity resolves to a concrete host but that host is
     absent from archive `config/hosts.yaml`, do not treat it as
     generic ambiguity and do not silently vouch around it. Ask the
     operator to add/classify the host in `config/hosts.yaml` with the
     correct class before re-running migration.
   An all-blocked dry-run with no recognizable records is a valid stop.
5. On confirmation, run the same command with `--apply`. Report the
   archive commit, the number archived vs. skipped, the still-`blocked`
   records, and the scrub-log paths. Remind the user that the CLI has
   already pushed the archive and that the agent-out source is left in
   place by migration (copy-only; no working-repo push is needed). Use
   `evidence-prune-source` only after archive retention is confirmed.
6. On any failure, surface the error code and message; do not retry a
   step that may have partially written. The archive push is the final
   transaction step, so a mid-apply failure leaves the archive
   un-pushed and recoverable.

## Boundary

`evidence migrate` owns source enumeration, repo-identity resolution and
host classification, the digest dedup, the secret scrub, the
`metadata.yaml` payload, file staging, catalog regeneration, and the
`git` / `semantic-commit` / push transaction on the archive. The skill
body owns manual migration: presenting the dry-run for review, gating the
apply on explicit user confirmation, reviewing the scrub summary, and deciding
when to vouch for a host with `--host`. It does not duplicate
CLI logic, call `git` directly, or delete anything from the source tree.
Source cleanup is delegated to the `evidence-prune-source` skill and
`evidence prune-source --archived-only`.

## Related Skills

- `heuristic-session-closeout` — enumerates the session's skill-usage
  records and flags non-pass outcomes for promotion, then **drives this
  skill's CLI as its retention step**: it runs the `evidence migrate`
  dry-run and auto-applies a clean result (surfacing a risky one instead),
  then runs `evidence-prune-source` to clean already-archived local source
  records. So at session end retention is usually hands-off; invoke this skill
  directly only for out-of-closeout drains or to re-review a dry-run the
  closeout surfaced rather than applied.
- `evidence-prune-source` — the source-cleanup counterpart to this copy-only
  migration. It deletes local agent-out run directories only when their raw
  record digest already exists in the archive catalog.
- The read-only archive surfaces — `evidence discover` (scan archivable
  candidates), `evidence query` / `evidence search` / `evidence catalog`
  (read past archived rollups) — are documented in the
  `evidence-archive` policy (`core/policies/evidence-archive/EVIDENCE_ARCHIVE.md`).
  They share the same archive clone and host classification but are
  read-only, so they are driven directly from the CLI rather than
  through a gated skill.
