# Skill Usage Evidence Durability And Query - Discussion Source

- Status: accepted for L2 execution.
- Date: 2026-06-14 UTC.
- Source repo: `graysurf/agent-runtime-kit`
- Source request: The user asked to review what `/skill-usage` currently does
  and whether it retains records, then questioned whether the evidence is
  actually useful given that producing records is easy but there is no
  consumption or query path. The agreed goal is to make the evidence useful at
  critical moments, the way the kit can already query `heuristic-inbox` and
  GitHub / GitLab issues and PRs.

## User Decision

The review established that `skill-usage` is two parts: a reminder hook
(`UserPromptSubmit`) over a 35-skill catalog, and a `skill-usage` CLI that writes
a verified `skill-usage.record.v1` envelope. The records are ephemeral runtime
evidence under the `agent-out` tree; the heuristic-system gatekeeper rejects raw
records from commit; and the only programmatic consumer is
`heuristic-inbox new --from-skill-usage`. There is no list / search / aggregate
surface, so the evidence is write-easy and read-poor.

The user confirmed they want all three improvements, to be built completely:

1. Closeout auto-surfacing of session skill-usage records (do not lose records
   worth promoting).
2. A query layer plus a producer nils-cli version stamp so records are
   unambiguous and searchable across nils-cli versions.
3. A durable storage convention, possibly a separate archive repo, so the
   evidence persists and can be queried at critical moments.

The user framed this as "completing the feature" and stated that after the
infrastructure is built they want to re-review the definitions of skill-usage
and the heuristic-system and how they interact, to record and continuously
improve workflow learning. The user chose the L2 path and explicitly invoked
`create-plan-tracking-issue`.

## Execution

- Recommended plan:
  docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md
- Recommended execution state:
  docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-execution-state.md
- Status: accepted for L2 execution.
- Next-task source: this document.

## Background

The closest existing precedent is `agent-plan-archive` plus the released
`plan-archive` CLI, which already implements "separate durable store, queried by
a CLI, unused day to day, available at critical moments" for plans. Its surface
(`migrate` / `discover` / `query` / `catalog` with `--grep` / `--area` /
`--refs-to` / `--deep`, `search` full-text, `refresh` with a reviewed scrub log,
and `validate-*`) is the template to mirror for evidence rather than reinvent.

The recommended sequencing is dependency-ordered, not all-at-once:

- Closeout surfacing first, because it is kit-only, uses existing data, delivers
  most of the "never lose a record worth promoting" value, and reveals whether
  operators actually reach back across sessions before a whole store is built.
- The producer nils-cli version stamp next, because archived records must carry
  their producing version or later cross-version queries stay ambiguous.
- The archive store and query CLI last, when the real query shapes are known and
  can drive the catalog schema instead of being guessed.

## Key Decisions Carried Into Sprint 1

These are deliberately left open for the Sprint 1 design freeze, with the agent's
current recommendation noted:

- Durable grain: raw audit log vs rollup-per-run vs curated-only. Recommendation:
  rollup-per-run index records, with raw detail linked, matching the
  `plan-archive` `_index/` snapshot model.
- Storage target: DECIDED. A new sibling archive repo mirroring
  `agent-plan-archive`, with a two-level config/data split. The clone path
  resolves as `--archive` flag > `$AGENT_EVIDENCE_ARCHIVE_HOME` env > the
  machine-local config's `archive_clone_path` (config at
  `$XDG_CONFIG_HOME/agent-evidence-archive/config.yaml`) > a documented default
  under XDG data (`${XDG_DATA_HOME:-$HOME/.local/share}/agent-evidence-archive`).
  Rejected: placing the git data repo itself under `$XDG_CONFIG_HOME`
  (config-as-data, diverges from `agent-plan-archive` whose clone lives under a
  normal project checkout); extending `agent-plan-archive`; a heuristic-system
  section. The improvement over `agent-plan-archive` is a documented zero-config
  default location rather than a required manual clone placement.
- Producer version field: an additive `producer` block on the record envelope.
- Query shapes: by skill, outcome, repo, and time, at minimum.
- Redaction: reuse `plan-archive refresh` scrub-log review and
  `heuristic-inbox ingest-evidence` redaction; never commit raw records.

## Scope

In scope:

- Closeout surfacing of session skill-usage records.
- Producer nils-cli version stamp and the matching kit version-pin bump.
- Evidence query primitives with declared readable schema versions.
- A durable evidence archive store and a scrubbed, dry-run-first migrate path.
- A re-review reconciling skill-usage and heuristic-system definitions and
  interaction.

Out of scope:

- Backfilling historical pre-stamp records.
- Unrelated nils-cli contract changes.
- Reminder-catalog scope changes beyond what the Sprint 5 re-review justifies.
- Runtime-home installation changes beyond the version-pin bump.
- Private machine-local skills.

## Desired Outcome

After execution, a skill-usage record produced during a high-impact workflow can
be surfaced at closeout, carries the producing nils-cli version, can be rolled up
and scrubbed into a durable archive, and can be queried by skill, outcome, repo,
and time at a critical moment. The skill-usage and heuristic-system definitions
describe one coherent produce-curate-archive-query lifecycle, so recording
important skill usage finally serves a consumption purpose instead of being a
write-only ritual.
