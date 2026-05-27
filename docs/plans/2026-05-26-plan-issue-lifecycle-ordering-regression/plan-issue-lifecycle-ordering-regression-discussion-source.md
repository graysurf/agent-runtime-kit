# Plan Issue Lifecycle Ordering Regression Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-26
- Source: user review of tracking issue lifecycle behavior, live comparison of
  issue #28 and issue #117, and local inspection of current delivery skills and
  `plan-issue` CLI surfaces.
- Intended next step: create a focused implementation plan that restores the
  old plan issue timeline quality in the current v2 lifecycle system and adds
  nils-cli support where workflow text alone is too easy to bypass.
- Source type: discussion-to-implementation-doc

## Execution

- Recommended plan:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md
- Recommended execution state:
  docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-execution-state.md
- Recommended first implementation task: add a failing fixture that models
  issue #117's missing `session` lifecycle record and proves the closeout gate
  no longer accepts a dashboard with `Latest session: pending`.

## Purpose

The older plan issue workflow produced a useful issue timeline: source and plan
snapshots were followed by repeated execution state, session, and validation
comments, and final closeout happened only after the issue had a readable final
session log. The newer v2 lifecycle surface improved marker structure and
visible validation/review/closeout rendering, but it currently allows important
plan-tracking issue updates to be delayed until after PR merge, and it can close
an issue while the dashboard still reports `Latest session: pending`.

The target is to preserve the old user-facing effect with the new v2 record
format: issue-visible progress before merge, explicit session records, final
expanded state, validation/review evidence, and closeout only after lifecycle
readiness and linked PR verification pass.

## Confirmed Facts

- [U1] The user pointed to issue #28 as the reference effect for useful plan
  issue comment ordering.
- [U2] The user wants the updated workflow to include the earlier answer's
  sequencing rule: PR merge may happen before linked issue closeout, but major
  plan lifecycle state must not be deferred until after merge.
- [U3] The user asked to plan nils-cli improvements when CLI support can make
  this harder to skip.
- [A1] Live issue #28 contains source and plan snapshots followed by many
  `execute-from-tracking-issue:*:v1` comments. Examples include state
  comments, session comments, validation comments, PR merge checkpoint
  comments, a final `## Session Log`, and then a tracking issue closeout
  comment.
- [A2] Live issue #28's final session log was posted before closeout:
  <https://github.com/graysurf/agent-runtime-kit/issues/28#issuecomment-4517097356>.
- [A3] Live issue #117 contains v2 source, plan, initial state, final state,
  validation, review, and closeout comments, but no `role=session` lifecycle
  comment.
- [A4] Live issue #117's final dashboard still says `Latest session: pending`
  even though the issue is closed:
  <https://github.com/graysurf/agent-runtime-kit/issues/117>.
- [A5] Live issue #117 did receive a final state comment with a visible
  `## Session Log` section inside the execution-state markdown, but that is not
  the same as a v2 `role=session` lifecycle record:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536305734>.
- [F1] `deliver-plan-tracking-issue` declares state, session, validation, and
  review comments as outputs and says the final state comment must show an
  expanded Task Ledger before closeout.
  See `build/codex/plugins/dispatch/skills/deliver-plan-tracking-issue/SKILL.md`.
- [F2] `deliver-plan-tracking-issue`'s example "Post issue-visible lifecycle
  updates" block includes state, validation, and review posts, but omits an
  explicit `--kind session` post even though the workflow text requires one.
- [F3] `deliver-plan-tracking-issue` says merge should happen only after checks,
  pre-merge review, review evidence, lifecycle audit, and issue-backed
  completion gates pass.
- [F4] `deliver-github-pr` says linked tracking or dispatch issue closeout runs
  after merge when the PR body references the issue with `Refs #<issue>`.
- [F5] `deliver-github-pr` does not require a pre-merge plan-tracking readiness
  check before merging a PR that references a plan-tracking issue.
- [F6] `plan-issue record close --help` exposes strict closeout, linked PR,
  approval, bundle, label, fixture, and non-required-check override options, but
  no option or documented default that requires a latest `session` record.
- [F7] `plan-issue record audit --help` audits lifecycle markers from body and
  comments, but does not expose an operator-facing readiness mode that blocks on
  missing session evidence, final expanded state, or stale dashboard session
  links before merge.

## Findings

| Priority | Issue | Evidence | Fix location | Acceptance criteria |
| --- | --- | --- | --- | --- |
| P1 | v2 closeout can succeed without a session lifecycle record. | #117 is closed with `Latest session: pending`; #28 has final session before closeout. | `nils-cli` `plan-issue record close`; runtime-kit closeout skills and fixtures. | `record close` rejects tracking/dispatch records with no latest valid `role=session` comment unless an explicit documented waiver is provided. |
| P1 | PR-level delivery can bypass plan-tracking pre-merge readiness. | `deliver-github-pr` runs linked issue closeout after merge but does not require a pre-merge lifecycle readiness check. | `core/skills/pr/deliver-github-pr/SKILL.md.tera`; GitLab parity skill. | When a PR references a plan-tracking or dispatch issue, merge is blocked until `plan-issue` reports state/session/validation/review readiness, except when `--no-closeout` or an explicit bypass policy is used. |
| P1 | `deliver-plan-tracking-issue` requires session in prose but omits it from the entrypoint command block. | Skill outputs and workflow say state/session/validation/review; entrypoint examples post only state/validation/review. | `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`; rendered goldens. | Entrypoint includes a canonical `plan-issue record post --kind session` command with payload and visible summary. |
| P2 | `record audit` is marker-oriented, not closeout-readiness-oriented. | Current help audits body/comments but exposes no readiness profile for pre-merge checks. | `nils-cli` `plan-issue record audit` or new subcommand. | A command can report machine-readable readiness for `pre-merge`, `pre-closeout`, and `closeout`, including missing session and stale dashboard links. |
| P2 | The final dashboard can retain stale `Latest session: pending`. | #117 final dashboard says pending after close. | `nils-cli` dashboard repair / closeout renderer. | Final dashboard after closeout never reports pending lifecycle links for records that were required by the profile. |

## Decisions

- [D1] Treat issue #28 as the behavior reference for the current repair: the
  new v2 lifecycle system should preserve a readable append-only progress
  sequence, not merely pass hidden payload checks.
- [D2] Keep the rule that linked issue closeout runs after PR merge, because
  closeout needs to verify merged PR status, merge SHA, and checks.
- [D3] Move plan lifecycle readiness before merge. State/session/validation and
  review records should be issue-visible before a PR tied to a plan-tracking
  issue is merged.
- [D4] Treat the #117 behavior as a workflow regression and gate gap. It is not
  just operator preference: current skills and nils-cli gates allowed a closed
  issue with no session lifecycle record.
- [D5] Fix both runtime-kit skill instructions and nils-cli enforcement. Skill
  prose alone is not enough because `deliver-github-pr` can be invoked directly
  for an issue-backed plan PR.
- [D6] The closeout gate should require `session` by default for tracking and
  dispatch records. Any exception must be explicit, visible, and auditable.
- [D7] `deliver-github-pr` and `deliver-gitlab-mr` should either route linked
  plan issues to the plan/dispatch delivery workflow or run a pre-merge
  readiness command before `forge-cli pr merge`.
- [D8] The plan should include GitHub and GitLab parity for PR/MR delivery
  skills, while live provider validation can start on GitHub.

## Scope

- Add failing deterministic fixtures that reproduce the #117 lifecycle gap.
- Update `deliver-plan-tracking-issue` and related rendered goldens so session
  posting is a first-class command, not only prose.
- Update `deliver-github-pr` and `deliver-gitlab-mr` so linked plan-tracking or
  dispatch issues cannot merge before lifecycle readiness is visible.
- Add or consume nils-cli support for lifecycle readiness and required session
  enforcement.
- Update closeout skills and runtime smoke coverage to reject stale dashboards
  with `Latest session: pending`.
- Preserve the v2 marker format and visible evidence improvements already
  landed in `plan-issue >=0.22.3`.

## Non-Scope

- Do not revert to the old v1 marker names such as
  `execute-from-tracking-issue:session:v1`.
- Do not require session comments for arbitrary non-plan issues.
- Do not use GitHub auto-close keywords for plan-tracking or dispatch issues.
- Do not make the PR-level `deliver-github-pr` skill own implementation task
  planning; it should detect linked issue-backed records and enforce or route
  lifecycle readiness.
- Do not close #117 again; it is evidence for the regression, not the target
  record to repair in this plan.

## Implementation Boundaries

- Runtime-kit skills own workflow sequencing, user-facing instructions, and
  rendered skill examples.
- nils-cli `plan-issue` owns lifecycle marker parsing, readiness audits,
  closeout gates, dashboard repair, and provider issue mutation.
- `forge-cli` owns PR/MR creation, checks, ready, merge, comment, and provider
  label mutation.
- The PR/MR delivery skills should not synthesize lifecycle payloads from
  private reasoning. They should use explicit payload files, execution-state
  files, visible summaries, and provider read-back.
- Dashboard body remains mutable; append-only lifecycle comments remain the
  durable source of truth.

## Requirements

- A v2 tracking or dispatch record cannot close with `Latest session: pending`
  unless a documented session waiver exists.
- `plan-issue record close` blocks when the latest required lifecycle records
  are missing, malformed, invisible, or stale.
- A pre-merge readiness command or mode exists and can be used before the PR is
  merged, without requiring the linked PR to already be merged.
- `deliver-plan-tracking-issue` posts state, session, validation, and review
  lifecycle comments before merge, then posts closeout after merge.
- `deliver-github-pr` and `deliver-gitlab-mr` detect linked plan records and
  either run the readiness gate or route to the plan/dispatch delivery skill.
- The final state comment before closeout uses expanded Task Ledger display and
  has no `<details>` wrapper around the rows.
- The final dashboard links latest state, session, validation, review, and
  closeout records when those records are required by the profile.

## Nils-CLI Improvement Candidates

- Add `plan-issue record ready` or `plan-issue record audit --readiness
  <pre-merge|pre-closeout|closeout>` with JSON output.
- Make readiness classify missing `session`, missing final expanded state,
  missing validation/review, stale dashboard links, hidden-only visible
  evidence, unresolved task rows, and linked PR state separately.
- Add `record close` default enforcement for latest valid `session` on tracking
  and dispatch profiles, with an explicit waiver flag if a session is truly not
  applicable.
- Add dashboard repair logic that refuses or flags final dashboards containing
  `Latest session: pending` when the profile requires session evidence.
- Add fixture helpers that model issue #28-like ordering and #117-like missing
  session ordering so runtime-kit can consume released behavior instead of
  hand-rolling checks in every skill.

## Acceptance Criteria

- Deterministic fixtures show #117-like lifecycle comments failing closeout
  because the session record is missing.
- Deterministic fixtures show #28-like ordering passing readiness and closeout
  under the v2 marker format.
- `deliver-plan-tracking-issue` rendered Codex and Claude skills contain a
  canonical `record post --kind session` entrypoint.
- PR/MR delivery skills mention and enforce pre-merge plan lifecycle readiness
  when the PR/MR references a plan-tracking or dispatch issue.
- `plan-issue record close --dry-run` fails on missing required session and
  reports a stable blocked code.
- `plan-issue record close --dry-run` passes when state, session, validation,
  review, approval, and linked merged PR evidence are present.
- Final dashboard repair links the latest session record instead of leaving
  `Latest session: pending`.

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `agent-docs resolve --context task-tools --strict --format checklist`
- `plan-issue record close` deterministic fixture for missing session failure.
- `plan-issue record close` deterministic fixture for complete v2 lifecycle
  success.
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `bash scripts/ci/all.sh`
- Live GitHub rehearsal on a tracking issue before closing the implementation
  tracker.

## Risks And Guardrails

- Making session required without a waiver may break older open plan records.
  The implementation should scope enforcement to v2 closeout and provide clear
  migration or waiver behavior.
- A readiness command that duplicates closeout too closely can become confusing.
  It should have explicit phases: pre-merge validates lifecycle evidence without
  requiring merged PRs; closeout validates merged PRs and final approval.
- PR-level delivery skills should avoid becoming full plan executors. They
  should detect linked plan records and enforce or route the right workflow.
- GitLab parity should be designed with the same lifecycle contract even if the
  first live validation happens on GitHub.

## Retention Intent

This document is a plan-source artifact for a focused workflow repair. It is
cleanup-eligible after execution closes unless the final decisions are promoted
into runtime-kit skill contracts or nils-cli surface documentation.

## Read-First References

- <https://github.com/graysurf/agent-runtime-kit/issues/28>
- <https://github.com/graysurf/agent-runtime-kit/issues/117>
- `build/codex/plugins/dispatch/skills/deliver-plan-tracking-issue/SKILL.md`
- `build/codex/plugins/pr/skills/deliver-github-pr/SKILL.md`
- `build/codex/plugins/dispatch/skills/plan-tracking-issue-closeout/SKILL.md`
- `docs/source/nils-cli-surface.md`

## Recommended Next Artifact

Create
`docs/plans/2026-05-26-plan-issue-lifecycle-ordering-regression/plan-issue-lifecycle-ordering-regression-plan.md`
with a nils-cli-first gate fix, runtime-kit skill contract updates, deterministic
fixtures, rendered goldens, and one live GitHub tracking issue rehearsal.
