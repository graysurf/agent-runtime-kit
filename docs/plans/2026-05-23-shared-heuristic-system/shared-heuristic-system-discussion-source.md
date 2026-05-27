# Shared Heuristic System Implementation Handoff

- Status: open, implementation planning requested
- Date: 2026-05-23
- Source: user direction in the current Codex thread, live Codex and Claude
  runtime checks, the existing `agent-runtime-kit` target architecture, and the
  legacy `agent-kit` Heuristic System policy.
- Scope: make one shared heuristic-system improvement record root and one
  `heuristic-inbox` workflow contract usable from both Codex and Claude.
- Intended next step: write and execute the implementation plan from this
  source document.

## Execution

- Recommended plan: docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-plan.md
- Recommended execution state: docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-execution-state.md

## Purpose

`agent-runtime-kit` exists partly to stop maintaining separate Codex and Claude
workflow systems. The Heuristic System is a core example: workflow friction,
skill-contract mismatches, and durable improvement records should not split
between `agent-kit`, `claude-kit`, `$HOME/.codex`, and `$HOME/.claude`.

The target is one shared Heuristic System root owned by `agent-runtime-kit`.
Both products should invoke the same rendered `heuristic-inbox` skill and the
same released `heuristic-inbox` CLI behavior, so curated improvement records
land in the same repository-owned location. Product runtime homes may still
hold transient evidence, caches, logs, and raw skill-usage output, but retained
improvement records should converge into the shared root.

## Confirmed Facts

- [U1] The user wants this discussion preserved as one implementation-readiness
  document before planning.
- [U2] The implementation goal is "one heuristic-inbox" that both Claude and
  Codex use for improvement tracking in the same location.
- [U3] Sharing the improvement record location is one of the main reasons for
  building `agent-runtime-kit`.
- [F1] `agent-runtime-kit` currently renders `meta.heuristic-inbox` and
  `evidence.skill-usage` for both Codex and Claude from shared source under
  `core/skills/`.
- [F2] `targets/codex/link-map.yaml` exposes
  `build/codex/plugins/meta/skills/heuristic-inbox` under
  `$CODEX_HOME/skills/meta/heuristic-inbox`.
- [F3] `agent-runtime install --product claude --dry-run` currently reports
  no changes for the Claude runtime surface, including
  `$HOME/.claude/plugins/meta/skills/heuristic-inbox`.
- [F4] Codex and Claude both install shared hooks from
  `core/hooks/shared/`, and both product hook configurations include the
  advisory `skill-usage-reminder.py` hook.
- [F5] The released `heuristic-inbox` CLI exists in nils-cli `0.17.4` and
  supports case listing, verification, creation from skill-usage records,
  status updates, evidence ingestion, and archival transitions.
- [F6] The released `skill-usage` CLI exists in nils-cli `0.17.4` and owns the
  deterministic invocation record envelope.
- [F7] The current `docs/source/inventory-target-architecture.md` already
  names a future `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` policy
  location, but it also describes active inbox entries as per-product
  `state_home` data.
- [F8] `agent-runtime-kit` currently has `core/policies/cli-tools.md`, but no
  tracked `core/policies/heuristic-system/` tree and no tracked
  `HEURISTIC_SYSTEM.md`.
- [F9] The legacy `agent-kit` tree still contains the active Heuristic System
  framework document, skill-usage recording runbook, archived inbox record, and
  operation record.
- [F10] The legacy `claude-kit` tree still contains a separate
  `HEURISTIC_SYSTEM.md`, `heuristic-system/` tree, and old
  `heuristic-error-inbox` skill surface.
- [A1] Live Codex doctor for this checkout reports `block=0`, with
  `heuristic-inbox` and `skill-usage` available at `0.17.4`.
- [A2] Live Claude doctor for this checkout reports `block=0`, with
  `heuristic-inbox` and `skill-usage` available at `0.17.4`.
- [A3] `heuristic-inbox list` against the old agent-kit inbox finds the
  archived `deliver-gitlab-mr-skipped-pipeline-and-cleanup` record; the
  runtime-kit shared root does not exist yet.

## Decisions

1. Use the current public skill name `heuristic-inbox`. Do not restore the old
   public `heuristic-error-inbox` name.
2. Create one canonical shared Heuristic System root in `agent-runtime-kit`.
   Recommended root:
   `core/policies/heuristic-system/`.
3. Treat `core/policies/heuristic-system/error-inbox/` as the shared curated
   improvement inbox for both Codex and Claude.
4. Treat `core/policies/heuristic-system/operation-records/` as the shared
   retained operation-record root.
5. Keep raw runtime evidence and ordinary `skill-usage.record.json` output out
   of tracked policy records by default. Only curated, redacted, retained
   records belong in the shared root.
6. Update the existing target architecture. The current per-product
   `state_home/heuristic-system/error-inbox/` placement no longer matches the
   desired shared-record goal.
7. Keep `skill-usage-reminder.py` advisory only. It should point agents toward
   the shared policy and record root, but it must not auto-create or mutate
   heuristic records.
8. Put deterministic path resolution in nils-cli where practical, not in
   duplicated skill prose.

## Scope

In scope:

- Move or copy the reusable Heuristic System framework from legacy `agent-kit`
  into `agent-runtime-kit`.
- Move or copy the reusable skill-usage recording policy into the new shared
  Heuristic System policy area or an adjacent canonical runtime-kit policy
  location.
- Move or copy retained curated records from legacy `agent-kit` and
  `claude-kit`, deduplicate them, and verify them through `heuristic-inbox`.
- Update `docs/source/inventory-target-architecture.md` so Heuristic System
  placement reflects one shared improvement root.
- Update `core/skills/meta/heuristic-inbox/SKILL.md.tera` so both rendered
  products use the same canonical root and lifecycle language.
- Update `core/skills/evidence/skill-usage/SKILL.md.tera` so unresolved
  skill-bound friction routes to the shared Heuristic System root when it is
  curated for retention.
- Update `core/hooks/shared/skill-usage-reminder.py` and its catalog if needed
  so reminders reference the shared root and current skill names.
- Add nils-cli support if the current `heuristic-inbox` flags are too
  cwd-dependent. Preferred shape: a `--system-root <dir>` flag and
  `AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT` environment fallback that resolve
  `error-inbox/` and `operation-records/` under one root.
- Update render golden files, runtime smoke cases, product prompt cases, and
  install/doctor/audit checks so both products prove the same root contract.
- Install and verify the updated Codex and Claude runtime surfaces through
  `agent-runtime render`, `agent-runtime install --dry-run`, `--apply`, and
  `agent-runtime doctor`.

Out of scope:

- Auto-writing heuristic records from hooks.
- Treating every command failure, typo, retry, or raw stderr as a retained
  Heuristic System case.
- Storing secrets, unredacted logs, private keys, credentials, or large raw
  runtime evidence in the shared root.
- Splitting retained improvement records by product after this migration.
- Reintroducing `$HOME/.agents` as the canonical runtime-kit path.
- Replacing the `skill-usage` envelope with heuristic-inbox records.
- Removing all legacy files before the new shared root is installed and
  verified.

## Implementation Boundaries

The shared Heuristic System should keep three layers separate:

1. Runtime evidence:
   - Written by tools such as `skill-usage`, `review-evidence`,
     `test-first-evidence`, `browser-session`, or `agent-out`.
   - May live under project output directories or product state homes.
   - Not automatically committed or copied into the shared heuristic root.
2. Curated improvement inbox:
   - Written through `heuristic-inbox`.
   - Contains compact `ENTRY.md` case folders and redacted evidence excerpts.
   - Shared by Codex and Claude under the same runtime-kit root.
3. Stable policy and retained operation records:
   - Tracked under `core/policies/heuristic-system/`.
   - Used by both products and by future implementation plans.
   - Updated only when a lesson should outlive one workflow.

## Requirements

1. A fresh Codex session and a fresh Claude session must discover the same
   `heuristic-inbox` workflow contract after render/install.
2. Both products must resolve the canonical Heuristic System root to the same
   absolute directory in this checkout.
3. Creating a curated inbox case from either product must write under the same
   shared root.
4. Listing, verifying, status-updating, evidence-ingesting, and archiving a
   case must work against that shared root without relying on the caller's cwd.
5. Existing retained records from legacy `agent-kit` and `claude-kit` must be
   either migrated, explicitly superseded, or intentionally left behind with a
   documented reason.
6. The old `heuristic-error-inbox` naming should be treated as a legacy alias or
   migration source only; new rendered runtime-kit output should use
   `heuristic-inbox`.
7. `agent-docs` context resolution should stop depending on the old
   `agent-kit/HEURISTIC_SYSTEM.md` once the policy catalog is moved into
   `agent-runtime-kit`.
8. Tests should protect against accidental per-product divergence of the
   heuristic root.
9. The shared-root contract must be visible in the skill body, architecture
   docs, and validation fixtures.

## Acceptance Criteria

1. `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` exists and is the
   product-independent framework document.
2. The shared root contains `error-inbox/`, `operation-records/`, and README or
   policy guidance that matches current `heuristic-inbox` CLI behavior.
3. Migrated retained cases pass `heuristic-inbox verify --strict`.
4. `heuristic-inbox list --system-root <shared-root> --include-archived`
   reports migrated retained records from the same location for both products,
   or the implementation documents the equivalent command if the final CLI flag
   differs.
5. Codex render and install are clean:
   - `agent-runtime render --product codex`
   - `agent-runtime install --product codex ... --dry-run`
   - `agent-runtime install --product codex ... --apply`
   - `agent-runtime doctor --product codex ...`
6. Claude render and install are clean:
   - `agent-runtime render --product claude`
   - `agent-runtime install --product claude ... --dry-run`
   - `agent-runtime install --product claude ... --apply`
   - `agent-runtime doctor --product claude ...`
7. `agent-runtime audit-drift` remains clean except documented intentional
   product differences.
8. Runtime smoke or product prompt smoke proves both products expose
   `heuristic-inbox` and `skill-usage`.
9. No new retained record writes to legacy
   `$HOME/.config/agent-kit/heuristic-system` or
   `$HOME/.config/claude/heuristic-system` during the runtime-kit workflow.
10. Documentation clearly explains that raw skill-usage records are evidence,
    while `heuristic-inbox` cases are curated improvement trackers.

## Validation Plan

- `heuristic-inbox --version`
- `skill-usage --version`
- `heuristic-inbox verify <migrated-case> --strict --format json`
- `heuristic-inbox list --system-root <shared-root> --include-archived --format json`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime install --product codex --dry-run`
- `agent-runtime install --product claude --dry-run`
- `agent-runtime doctor --product codex`
- `agent-runtime doctor --product claude`
- `agent-runtime audit-drift`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence`
- `bash tests/hooks/run.sh`
- `plan-tooling validate --format text --explain`

## Risks And Guardrails

- The existing architecture text says active inbox entries are per-product
  state. The implementation must update that design instead of quietly
  contradicting it in skill prose.
- A shared tracked inbox can become noisy if agents retain ordinary command
  friction. Preserve the old triage threshold: retain only important,
  unresolved, repeated, skill-contract relevant, or reusable lessons.
- Cwd-dependent CLI defaults are unsafe for a two-product shared root. Prefer
  explicit root resolution in nils-cli and rendered skill guidance.
- Migrating legacy records can accidentally preserve stale or product-specific
  paths. New or updated entries should pass strict verification and should not
  contain absolute local home paths in retained prose.
- Hook reminders are useful for prompting judgment, but they must not mutate
  records automatically.
- Do not claim the migration is complete just because both products can run
  the `heuristic-inbox` binary. Completion requires shared-root writes and
  validation from both product surfaces.

## Retention Intent

This document is a plan-source artifact. It should remain in
`docs/plans/2026-05-23-shared-heuristic-system/` until the plan is implemented and closed.
After execution, promote the stable root-placement and lifecycle guidance into
`docs/source/inventory-target-architecture.md`,
`core/policies/heuristic-system/`, or another maintained policy entrypoint, then
classify this source document as cleanup-eligible coordination material.

## Open Questions

- Should `docs/source/docs-placement-retention-policy-v1.md` add an explicit
  note that `core/policies/heuristic-system/` is the retained-record exception
  for shared Heuristic System cases and operation records?
- Should `heuristic-inbox --system-root` be added in nils-cli, or should the
  runtime-kit skill pass existing `--inbox-dir` and `--out-dir` flags
  everywhere? The former is less error-prone.
- Should legacy `heuristic-error-inbox` remain as a compatibility alias in
  any product cache, or is documentation-only migration enough?
- Should archived legacy Claude placeholder records be migrated when they only
  contain `.gitkeep` files?
- Should `agent-runtime doctor` gain an explicit shared heuristic-system root
  check, or should this stay in smoke tests?

## Read First References

- `docs/source/inventory-target-architecture.md`
- `docs/source/docs-placement-retention-policy-v1.md`
- `core/skills/meta/heuristic-inbox/SKILL.md.tera`
- `core/skills/evidence/skill-usage/SKILL.md.tera`
- `core/hooks/shared/skill-usage-reminder.py`
- `manifests/skills.yaml`
- `targets/codex/link-map.yaml`
- `targets/claude/link-map.yaml`
- `$HOME/.config/agent-kit/HEURISTIC_SYSTEM.md`
- `$HOME/.config/agent-kit/docs/runbooks/skills/SKILL_USAGE_RECORDING_V1.md`
- `$HOME/.config/agent-kit/heuristic-system/`
- `$HOME/.config/claude/heuristic-system/`

## Recommended Next Artifact

Use this document as the `Read First` source for:

- `docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-plan.md`
- `docs/plans/2026-05-23-shared-heuristic-system/shared-heuristic-system-execution-state.md`
