# Skill Decision-Minimal Review - Discussion Source

- Status: accepted for L2 execution.
- Date: 2026-06-05 UTC.
- Source repo: `graysurf/agent-runtime-kit`
- Source request: The user asked to apply the plan issue skill simplification
  experience to a repo-wide review of agent-runtime-kit skills, with the goal
  of removing redundant wording while preserving valuable operator guidance.

## User Decision

The user first asked whether the plan issue skill cleanup pattern can guide a
broader review of the agent-runtime-kit skill catalog. The recommended approach
was a staged "decision-minimal" review: keep action-critical text and remove
duplicated narrative, grouped by domain rather than rewritten all at once.

The user then chose the heavier path: "就 L2 來個全盤整理吧" and explicitly
invoked `create-plan-tracking-issue`.

## Execution

- Recommended plan:
  docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-plan.md
- Recommended execution state:
  docs/plans/2026-06-05-skill-decision-minimal-review/2026-06-05-skill-decision-minimal-review-execution-state.md
- Status: accepted for L2 execution.
- Next-task source: this document.

## Background

The immediately preceding implementation simplified the plan issue family of
skills into a decision-minimal shape and merged as:

- PR: https://github.com/graysurf/agent-runtime-kit/pull/286
- Merge SHA: `a296e24b1640cb5c159d418a738569065a782c9e`

That pass proved a useful editing rule: keep the text that changes an agent's
decision, and remove repeated explanations that do not change what the agent
should do next.

## Decision-Minimal Rubric

Keep text when it carries one of these roles:

- Hard prerequisite: required CLI floor, provider auth, clean tree, branch/base,
  required docs, validation contract, or committed bundle state.
- Irreversible operation: provider mutation, merge, issue close, archive,
  install/apply, runtime-home mutation, or destructive cleanup.
- Provider difference: GitHub/GitLab behavior, labels, PR/MR refs, checks,
  reviewability, or provider API limits.
- Failure stop condition: exact blocker code, stale state, missing evidence,
  visible-lint failure, forbidden role, or no-safe-retry condition.
- Ownership boundary: what the skill owns, must not own, and which skill takes
  over at the handoff.
- Canonical entrypoint: the shortest command sequence that proves the workflow
  shape without duplicating every possible option.
- Validation: the checks that make the skill's edited surface trustworthy.

Remove or rehome text when it is:

- Repeated across several sibling skills and can live in a shared domain spec.
- Historical explanation that no longer changes current operator decisions.
- A restatement of CLI help without an additional workflow constraint.
- A long example that can be reduced to one canonical command plus a branch
  note.
- A cross-reference list that repeats the same family map in every skill.
- A narrative description of optional work that can become a named branch such
  as "dashboard stale branch" or "provider-label branch".

## Scope

In scope:

- All repo-managed source skills under `core/skills/**/SKILL.md.tera`.
- Rendered Codex and Claude skill outputs and goldens when source changes.
- `manifests/skills.yaml` only when descriptions, floors, or acceptance data
  drift from the edited skill source.
- Domain-local shared specs when repeated rules should be extracted or pointed
  at instead of duplicated.
- Small README or routing-doc updates only when needed to make the edited
  structure discoverable.

Out of scope:

- Changing nils-cli command behavior or JSON contracts.
- Changing plugin discovery semantics, hook behavior, or runtime installation
  logic unless an edited skill exposes real drift.
- Private machine-local skills outside this repo.
- A parallel dispatch plan. This is a serial L2 cleanup unless scope later
  requires independent implementation lanes.
- Rewriting policy documents unrelated to skill operation.

## Desired Outcome

After execution, the managed skill catalog should be shorter, easier to scan,
and less repetitive while preserving the exact safety gates that prevent wrong
provider mutations, skipped validation, or ambiguous handoffs.

The done state is not "fewest lines possible"; it is "fewest lines that still
preserve correct agent decisions."
