# Heuristic System Maintenance Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-25
- Source: user request in the current Codex thread to create a
  `heuristic-system-maintenance` workflow that lets agents proactively handle
  recorded Heuristic System issues, report results, and recommend next steps.
- Intended next step: use this document as the source artifact for an
  issue-backed implementation plan.

## Execution

- Recommended plan: docs/plans/2026-05-25-heuristic-system-maintenance/heuristic-system-maintenance-plan.md
- Recommended execution state: docs/plans/2026-05-25-heuristic-system-maintenance/heuristic-system-maintenance-execution-state.md

## Purpose

`heuristic-inbox` owns deterministic case mechanics: list, verify, create,
status update, evidence ingestion, and archive. `heuristic-session-closeout`
owns end-of-session retention judgment after the current goal is done. The
missing workflow is a bounded maintenance pass over already-retained Heuristic
System cases.

The target skill, `heuristic-system-maintenance`, should let an agent review the
active Heuristic System backlog, identify cases that can be handled now, execute
narrow fixes when safe, update retained records, and report what remains. It
should make progress on recorded issues without turning every inbox entry into a
large autonomous implementation.

## Confirmed Facts

- [U1] The requested artifact is a `discussion-to-implementation-doc` for a new
  `heuristic-system-maintenance` workflow.
- [U2] The user wants agents to proactively process already-recorded Heuristic
  System problems, report what was handled, and recommend next steps.
- [F1] `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` defines the shared
  retained-record root as `core/policies/heuristic-system/`, separates runtime
  evidence from curated inbox cases and operation records, and warns that the
  goal is not to record everything.
- [F2] `build/codex/plugins/meta/skills/heuristic-inbox/SKILL.md` defines
  `heuristic-inbox` as the CLI-backed case mechanic for listing, verifying,
  creating, status-updating, evidence-ingesting, and archiving retained cases.
- [F3] `build/codex/plugins/meta/skills/heuristic-session-closeout/SKILL.md`
  reviews available session evidence for Heuristic System updates after a
  session goal is achieved, but explicitly does not continue implementation,
  research, PR delivery, or issue lifecycle work.
- [F4] `core/policies/heuristic-system/error-inbox/README.md` says active inbox
  entries are retained summaries of important workflow gaps, not raw logs, and
  completed entries should be archived rather than deleted.
- [A1] `heuristic-inbox list --inbox-dir
  core/policies/heuristic-system/error-inbox --format json` currently reports
  six active open cases:
  `deliver-closeout-cli-surface-drift`,
  `plan-issue-record-post-concurrency`,
  `plan-issue-v3-surface-drift`, `pre-pr-cli-repo-local-fallback`,
  `provider-body-local-path-redaction-gap`, and
  `semantic-commit-body-uppercase-rule`.

## Decisions

- [D1] Add a new public skill named `heuristic-system-maintenance`.
- [D2] Keep `heuristic-inbox` narrow and deterministic. The new skill should
  orchestrate maintenance judgment, not reimplement case-folder mechanics.
- [D3] Keep `heuristic-session-closeout` focused on session closeout. Do not
  broaden it into backlog maintenance.
- [D4] The maintenance skill may proactively execute only bounded work:
  verification, classification, evidence-link repair, docs-only guidance
  updates, narrow skill-body fixes, archival of completed cases, and issue/plan
  routing for larger cases.
- [D5] Broad product, CLI, provider, or cross-repo fixes must become explicit
  plans or issues unless the user has already authorized that execution scope.
- [D6] Every maintenance pass that performs writes, validation, provider calls,
  or durable artifact creation should write a `skill-usage.record.v1`
  envelope.

## Scope

In scope:

- Create `core/skills/meta/heuristic-system-maintenance/SKILL.md.tera`.
- Add the skill to manifests, source indexes, rendered Codex and Claude
  outputs, golden fixtures, and runtime smoke expectations.
- Define a maintenance workflow that:
  - resolves `core/policies/heuristic-system/` explicitly,
  - lists active `error-inbox/` cases,
  - verifies every candidate case with `heuristic-inbox verify --strict`,
  - classifies candidates by actionability,
  - executes only safe bounded actions,
  - records changed-case verification,
  - updates or archives retained records through `heuristic-inbox`,
  - reports handled, skipped, blocked, and recommended next actions.
- Add a deterministic report shape suitable for final replies and retained
  evidence.
- Add tests or smoke coverage that proves the skill can operate on a fixture
  inbox without mutating real provider state.
- Preserve existing Heuristic System separation between runtime evidence,
  curated inbox cases, and operation records.

Out of scope:

- Auto-fixing every open inbox case.
- Mutating provider issues, PRs, MRs, or external repos unless a specific case
  is explicitly classified and authorized through the relevant workflow.
- Writing raw logs, raw `skill-usage.record.json` contents, secrets, or
  unredacted local paths into retained cases.
- Replacing `heuristic-inbox` CLI validation or case lifecycle commands.
- Replacing `heuristic-session-closeout` for end-of-session retained-record
  review.
- Spawning subagents by default.

## Maintenance Classification

The skill should classify each active case into exactly one current action:

| Class | Meaning | Allowed next action |
| --- | --- | --- |
| `archive-ready` | Case is already `promoted` or `wontfix`, strict-valid, and has no remaining next action. | Run `heuristic-inbox archive`, verify, report archive path. |
| `quick-fix` | A narrow repo-local docs, skill text, test, fixture, or case-body fix can be completed in the same maintenance pass. | Apply the fix, validate, update or promote the case. |
| `evidence-update` | The case needs better pointers, redacted evidence, or next-action clarification, but not product code changes. | Use `heuristic-inbox ingest-evidence` or edit via the CLI-supported path where available, then verify. |
| `needs-plan` | The fix is broader than a maintenance pass or spans repos, providers, release sequencing, or product behavior. | Produce or recommend a plan/issue source; do not implement directly. |
| `blocked` | Required evidence, authority, environment, or dependency is missing. | Report the blocker and the minimum unblocking action. |
| `wontfix-candidate` | The risk appears accepted or obsolete, but no explicit retained decision exists. | Recommend `wontfix`; do not set it without enough evidence or user approval. |

## Current Backlog Reading

Initial maintenance should treat the current active inbox as acceptance data:

| Case | Current read | Suggested maintenance action |
| --- | --- | --- |
| `plan-issue-v3-surface-drift` | High-severity runtime-kit and nils-cli surface alignment already has a plan bundle link. | `needs-plan`; continue through the linked implementation plan, not a quick maintenance pass. |
| `plan-issue-record-post-concurrency` | Needs a decision between a nils-cli concurrency lock and explicit runtime-kit serialization guidance. | `needs-plan` or `evidence-update`; first pass should clarify owner and open/attach upstream follow-up. |
| `provider-body-local-path-redaction-gap` | Provider-bound privacy gate spans nils-cli provider mutation surfaces. | `needs-plan`; recommend nils-cli provider-payload gate plan. |
| `pre-pr-cli-repo-local-fallback` | Narrower skill/CLI contract gap with clear options. | `quick-fix` candidate if scoped to clearer error text or runtime-kit skill guidance; broader CLI default remains `needs-plan`. |
| `semantic-commit-body-uppercase-rule` | Documentation or validator-relaxation gap with explicit acceptance options. | `quick-fix` candidate for docs guidance; validator relaxation belongs in nils-cli plan/issue. |
| `deliver-closeout-cli-surface-drift` | Fixed once, waiting for future evidence before promotion. | `blocked` for now unless a new deliver-* / closeout edit supplies prevention-rule evidence. |

## Requirements

- The skill must resolve the shared Heuristic System root explicitly from
  `AGENT_RUNTIME_HEURISTIC_SYSTEM_ROOT` or the active `agent-runtime-kit`
  checkout. It must not depend on caller cwd for retained-record mutation.
- The skill must run `agent-docs` preflight before repository writes.
- The skill must list active cases before proposing work.
- The skill must verify each touched case before and after changes.
- The skill must classify every reviewed active case, even when no action is
  taken.
- The skill must stop before broad implementation unless the case is classified
  as `quick-fix` and the fix is repo-local, bounded, and reversible.
- The skill must use `heuristic-inbox` for case lifecycle mechanics whenever
  the CLI supports the operation.
- The skill must use `skill-usage` for any maintenance pass that mutates files,
  calls provider APIs, runs validation, or creates durable evidence.
- The skill must produce a concise report with:
  - cases reviewed,
  - cases changed,
  - validation run,
  - skipped or blocked cases,
  - recommended next actions,
  - retained record paths and commit status when applicable.
- The skill must not commit unrelated worktree changes.

## Acceptance Criteria

- A rendered `heuristic-system-maintenance` skill appears for both Codex and
  Claude from shared source.
- The skill body describes the classification model above and the boundary
  between `quick-fix`, `needs-plan`, and `blocked`.
- Runtime smoke or fixture coverage proves that a maintenance pass can list,
  verify, classify, and report active fixture cases without mutating live
  provider state.
- Tests cover at least:
  - no active cases,
  - one `archive-ready` case,
  - one `quick-fix` case,
  - one `needs-plan` case,
  - existing dirty worktree boundary.
- The first real run against the current active inbox reports all six current
  cases and either handles a narrow case or recommends concrete next steps for
  each.
- Any retained-record edits pass `heuristic-inbox verify --strict`.
- Rendered Codex and Claude outputs and golden snapshots are updated.
- `agent-runtime doctor --class skill-surface` passes for both products after
  render/install.

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `heuristic-inbox list --inbox-dir
  core/policies/heuristic-system/error-inbox --format json`
- `heuristic-inbox verify
  core/policies/heuristic-system/error-inbox/<changed-case> --strict
  --format json`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `agent-runtime doctor --product codex --class skill-surface --format json`
- `agent-runtime doctor --product claude --class skill-surface --format json`
- `bash scripts/ci/skill-governance-audit.sh --check-counts`
- `bash scripts/ci/all.sh`

## Risks And Guardrails

- Risk: the skill becomes a broad autonomous fixer.
  Guardrail: only `quick-fix` cases may be executed immediately; all broader
  cases become plan/issue recommendations.
- Risk: active inbox entries become a noisy task queue.
  Guardrail: every reviewed case gets a classification and no-op reason; the
  final report should favor next actions over bulk rewriting.
- Risk: retained evidence leaks local paths.
  Guardrail: ingest only redacted evidence and verify strict redaction before
  commit.
- Risk: maintenance commits mix unrelated changes.
  Guardrail: stage only owned `core/policies/heuristic-system/**` and direct
  skill implementation files for the current pass.
- Risk: the skill duplicates `heuristic-session-closeout`.
  Guardrail: use this skill for backlog maintenance; use closeout only after a
  session goal has already completed.

## Recommended Next Artifact

Create
`docs/plans/2026-05-25-heuristic-system-maintenance/heuristic-system-maintenance-plan.md`
from this source document, then implement the new skill through the normal
runtime-kit skill lifecycle. The first execution pass should be conservative:
prove list/verify/classify/report behavior before allowing repo-local
`quick-fix` mutations.

## Retention Intent

This document is a coordination source for the future implementation plan. It
is cleanup-eligible after the plan is delivered unless the maintenance workflow
design is promoted into canonical Heuristic System policy or skill
documentation.

## Open Questions

- Should the first version be read-only by default, requiring an explicit
  `--apply` or user approval before any `quick-fix` mutation?
- Should the skill open upstream issues itself when a case is classified as
  `needs-plan`, or should it only recommend the issue text for the user or a
  separate issue-follow-up workflow?
- Should the first implementation expose a machine-readable report artifact, or
  is the final response plus `skill-usage` envelope enough?

## Read First References

- `core/policies/heuristic-system/HEURISTIC_SYSTEM.md`
- `core/policies/heuristic-system/error-inbox/README.md`
- `core/policies/heuristic-system/operation-records/README.md`
- `build/codex/plugins/meta/skills/heuristic-inbox/SKILL.md`
- `build/codex/plugins/meta/skills/heuristic-session-closeout/SKILL.md`
- `docs/source/docs-placement-retention-policy-v1.md`
