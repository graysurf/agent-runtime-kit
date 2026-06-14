# Skill Usage Evidence Durability And Query Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: complete; tracking issue closed
- Target scope: make skill-usage evidence durable and queryable through closeout
  surfacing, a producer nils-cli version stamp, evidence query primitives, and a
  scrubbed evidence archive store, then re-review the skill-usage and
  heuristic-system contract.
- Execution window: Sprint 1 design freeze and tracker baseline -> Sprint 2
  closeout surfacing -> Sprint 3 producer version and query primitives ->
  Sprint 4 archive store and migrate path -> Sprint 5 re-review, delivery, and
  closeout.
- Current task: complete (all sprints 1-5 delivered).
- Next task: none; tracker closed.
- Last updated: 2026-06-14
- Branch/commit/PR: graysurf/agent-runtime-kit#365 merged (https://github.com/graysurf/agent-runtime-kit/pull/365)
- Source document: docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md
- Plan document: docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/352>

## Validation Plan

- Bundle:
  - Run `plan-tooling validate --file <plan-file> --format text --explain`.
- Tracker open:
  - Dry-run `plan-issue record open` against the tracker bundle.
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- Runtime-kit batches:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `bash scripts/ci/skill-governance-audit.sh`
  - domain-specific deterministic smoke commands named in the plan.
- Upstream nils-cli:
  - nils-cli test / clippy gates (referenced) and
    `agent-runtime doctor --class version-alignment` after the version-pin bump.
- Final validation:
  - `bash scripts/ci/all.sh`
  - `bash tests/hooks/run.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Create the plan bundle and open the tracker | Bundle authored and committed on docs/skill-usage-evidence-archive; plan-tooling validate passed; tracking issue #352 opened with source/plan/state evidence.; Tracker #352 opened with source/plan/state; read-back audit clean (audit-352.json); run-state initialized. | Audit clean; run-state initialized (run 20260614T112407Z). |
| 1.2 | done | Freeze the evidence-record design decisions | Design-decisions doc pre-drafted at docs/plans/2026-06-14-skill-usage-evidence-archive/2026-06-14-skill-usage-evidence-archive-design-decisions.md; all 8 decisions locked.; Design-decisions doc frozen and accepted; all 8 decisions + rollup record shape locked. | Accepted on entering execution; gates Sprints 3-5. |
| 2.1 | done | Surface session skill-usage records in closeout | Closeout SKILL surfaces session skill-usage records + flags non-pass for promotion; codex/claude goldens regenerated; deterministic meta smoke pass; commit 10b71d5. | Kit-only; uses existing agent-out data. |
| 3.1 | done | Stamp the producer nils-cli version on the record | Producer block on skill-usage.record.v1 (sympoies/nils-cli#844, v1.4.0); kit pin #357. | Upstream nils-cli PR + kit version-pin bump. |
| 3.2 | done | Add evidence query primitives | evidence query primitives (nils-evidence): migrate/discover/query/search/catalog/validate-* (sympoies/nils-cli#848, v1.5.0); kit pin #362. | Mirror plan-archive query/catalog/search. |
| 4.1 | done | Stand up the evidence archive store | agent-evidence-archive store seeded and pushed (graysurf/agent-evidence-archive): hosts.yaml + catalog.json + evidence/ tree. | Per Sprint 1 storage decision. |
| 4.2 | done | Build the scrubbed migrate path | evidence-migrate skill + EVIDENCE_ARCHIVE policy (#364); migrate --host + blocked skip-report (sympoies/nils-cli#853, v1.6.0); kit pin #363. | Dry-run-first; scrub-log review; no raw commit. |
| 5.1 | done | Re-review the skill-usage and heuristic-system contract | Lifecycle reconciliation across HEURISTIC_SYSTEM, AGENT_HOME, skill-usage, closeout, reminder catalog (#365). | One coherent lifecycle. |
| 5.2 | done | Deliver close-ready evidence and close the tracker | Close-ready ready=true; #352 checkpointed (state/session/validation/review); tracker closed. | Full CI + close-ready gate. |

## Session Log

- 2026-06-14: User reviewed `/skill-usage`, identified that records are
  write-easy but read-poor, confirmed all three improvements (closeout
  surfacing, producer version + query, durable archive), chose L2, and invoked
  `create-plan-tracking-issue`. Bundle authoring started on
  `docs/skill-usage-evidence-archive`.
- 2026-06-14: All 8 Sprint 1 design decisions locked (rollup-per-run grain;
  explicit `evidence migrate` as sole writer; `agent-evidence-archive` sibling
  repo with XDG config/data split and zero-config default; additive `producer`
  version field; skill/outcome/repo/time query shapes; declared readable-schema
  query layer; reused scrub redaction; nils-cli upstream coordination via
  version-pin). Design-decisions doc pre-drafted.
- 2026-06-14: Tracker open #352 was blocked for ~1h by a poisoned `gh` HTTP
  cache entry carrying a stale `X-Ratelimit-Remaining: 0` header (cli/cli#8321),
  which made `gh issue list --label` (the record-open dedup) refuse requests
  while REST and the live rate limit stayed healthy. Clearing the one cached
  file under `~/.cache/gh` unblocked it immediately and the tracker opened.
- 2026-06-14: Resumed under the whole-plan directive. Confirmed run-state was
  never initialized (lives under `$XDG_STATE_HOME/plan-issue`, not AGENT_HOME);
  ran `tracking run init`. Implemented Sprint 2 closeout surfacing (read-only
  enumeration of the session's skill-usage records + non-pass flagging +
  `--from-skill-usage` promotion seeding), regenerated codex/claude goldens,
  and committed 10b71d5. Delivering as a `--kind docs` PR (skill prose + plan
  docs are test-first exempt; render + smoke are the substitute validation).

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file .../2026-06-14-skill-usage-evidence-archive-plan.md --format text` | pass | Plan bundle valid (exit 0). | local |
| `agent-runtime render --product codex --update-golden` / `--product claude --update-golden` | pass | Closeout goldens regenerated; diff scoped to the closeout skill. | local |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pass | All meta probes pass, including `meta.heuristic-session-closeout`. | local |
