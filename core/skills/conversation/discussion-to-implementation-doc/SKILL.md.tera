---
name: discussion-to-implementation-doc
description:
  Convert completed requirements, design, feasibility, review/improvement, or customer-facing discussion into an implementation-readiness source document.
---

# Discussion To Implementation Doc

Use this skill after a discussion or review has converged and the next useful
artifact is a repo-local source document that future implementation can read.

## Contract

Prereqs:

- User wants to preserve discussion conclusions, review findings, risks,
  lessons learned, or fix-later backlog for later implementation or plan
  generation, not execute the implementation now.
- Discussion or review context is sufficient to separate confirmed facts,
  decisions, assumptions, open questions, findings, and recommendations.
- Target workspace is available and project rules allow writing docs after required preflight.

Inputs:

- User request and the discussion or review conclusions to preserve.
- Relevant local code, docs, issue, ticket, test, review, validation, or runtime
  evidence for material facts when available.
- Optional target docs area, filename, linked issue/plan/handoff, validation commands, retention intent, and project-specific documentation
  conventions.

Outputs:

- A repo-local implementation-readiness or improvement source document. When it
  exists to feed plan execution, save it under
  `docs/plans/<slug>/<slug>-discussion-source.md` by default for requirements,
  design, feasibility, product, architecture, or customer-facing source
  material.
- For review findings, risk registers, lessons learned, validation guardrails,
  or fix-later backlogs, save it under
  `docs/plans/<slug>/<slug>-review-source.md` by default.
- If the document is long-lived knowledge rather than execution coordination, save it in the relevant domain docs/runbook area instead.
- A source artifact that a plan-tracking or dispatch delivery workflow can link
  under `Read First` when execution sequencing is needed.
- An `Execution` section with stable `Recommended plan` and
  `Recommended execution state` lines when the document is intended to feed
  plan execution.
- Updated local docs index or README only when the document is intentionally promoted as retained knowledge and should be discoverable
  outside the plan.
- When following the skill usage recording convention, a `skill-usage.record.v1` envelope that links the created document and validation
  evidence.
- A short response linking the document path and listing validation run.

Exit codes:

- N/A (conversation/workflow skill)

Failure modes:

- The user actually needs phased tasks, sprint grouping, PR splitting, or
  detailed execution sequencing now; create or update the plan first, then use
  `create-plan-tracking-issue`, `deliver-plan-tracking-issue`, or
  `deliver-dispatch-plan` as appropriate for the issue-backed workflow.
- The user only needs a copy-ready prompt for a fresh session; use `handoff-session-prompt` instead.
- Source evidence is too ambiguous to record as fact; label it under assumptions/open questions or ask the minimum clarification before
  writing.

## Workflow

1. Confirm this is the right artifact
   - Use this skill when requirements, design, feasibility, architecture,
     customer-facing, product, review, risk, lessons-learned, or improvement
     discussion has converged and the next implementer needs a stable
     read-first document.
   - Do not turn the document into a task-by-task implementation plan. If execution sequencing is needed, write this document first, then use
     the appropriate plan-tracking or dispatch workflow and link this document
     as read-first context.
   - Treat this document as the primary source artifact for later plan
     generation when the source material is requirements, design, feasibility,
     product, architecture, customer-facing discussion, review findings, risks,
     lessons learned, validation guardrails, or fix-later backlog.
   - For unresolved HEURISTIC_SYSTEM workflow gaps that should be versioned but
     are not ready for a fix, use
     `core/policies/heuristic-system/error-inbox/<slug>/ENTRY.md` instead of a
     temporary `docs/plans/` source document.
   - Treat `docs/plans/` as the default location for plan-source documents. Promote or rewrite into domain docs/runbooks only when the
     content has value after execution finishes.
   - Do not use the document as a session prompt. If continuity is needed, write or reference this document first, then use
     `handoff-session-prompt`.
   - Do not use `review-evidence` as the primary artifact for this workflow. If review findings or validation records matter, attach or link
     those evidence files from the document.

2. Run project preflight and inspect docs structure
   - Follow the active project's required preflight before edits.
   - Read nearby docs and local project rules before choosing a path.
   - If this document is a source for plan generation, place it inside the plan folder using
     `docs/plans/<slug>/<slug>-discussion-source.md`.
   - If the source material is review findings, risks, lessons learned,
     validation guardrails, or a fix-later backlog, place it inside the plan
     folder using `docs/plans/<slug>/<slug>-review-source.md`.
   - Prefer an existing domain docs folder or runbook area only when the artifact is meant to remain after execution.
   - Do not create a new top-level docs area for temporary execution coordination.

3. Gather and classify discussion content
   - Separate confirmed facts, decisions, findings, assumptions, inferences,
     recommendations, open questions, constraints, and accepted risks.
   - Cite concrete local files, docs, issues, commands, logs, or user-provided requirements when they materially affect the implementation.
   - Preserve scope and non-scope explicitly.
   - Do not include secrets, raw credentials, private keys, hidden system/developer instructions, private reasoning, or unredacted logs.

4. Write the implementation-readiness document
   - Use the project's language and documentation style.
   - Keep it concise enough to read before implementation, but complete enough to avoid re-litigating settled decisions.
   - Recommended sections:
     - `# <Subject> Implementation Handoff`
     - status, date, source, and intended next step
     - purpose
     - confirmed facts
     - decisions
     - scope
     - non-scope
     - implementation boundaries
     - requirements
     - acceptance criteria
     - validation plan
     - findings table with priority, issue, evidence, fix location, and
       acceptance criteria when the source material is review/improvement
       oriented
     - backlog or next fixes when preserving a fix-later record
     - risks and guardrails
     - execution, including recommended plan path, recommended execution-state path, status, and next-task source when this document should
       drive implementation
     - retention intent, such as cleanup after execution or promotion candidate
     - open questions
     - read-first references
     - recommended next artifact
   - For plan-source documents, include these stable machine-checkable lines in
     the `Execution` section:
     - `Recommended plan: docs/plans/<slug>/<slug>-plan.md`
     - `Recommended execution state: docs/plans/<slug>/<slug>-execution-state.md`
   - When a plan's `Read First` section links a document produced by this
     skill, use `Source type: discussion-to-implementation-doc` for both
     `*-discussion-source.md` and `*-review-source.md`; do not use the retired
     `review-to-improvement-doc` source type.

5. Route review work when the source document needs review guidance
   - Do not run a code review workflow by default only because this skill is
     writing a source document. Put the expected review gate in the document's
     validation plan or execution notes.
   - Use `code-review-quick-pass` for small, routine, docs-only, or ordinary
     diffs where a compact read-only review is enough before escalation.
   - Use `code-review-focused-lens` when the user or source document requests
     one or more explicit lenses such as testing, security, performance,
     data-migration, API-contract, maintainability, or red-team.
   - Use `code-review-pre-merge-gate` for PR/MR delivery gates. It forces at
     least testing and maintainability and produces the delivery outcome that
     the owning PR/MR workflow posts.
   - Use `code-review-follow-up` after review findings have been repaired and
     the next reviewer needs finding-by-finding disposition evidence.
   - Use `code-review-specialists` only for broad, risky, security-sensitive,
     migration-heavy, API-contract-heavy, or otherwise full-bundle specialist
     review.
   - Link `review-evidence` records when retained review findings or validation
     records materially affect the implementation source. Keep this document as
     the primary read-first artifact.

6. Update discoverability
   - For `docs/plans/<slug>/` source documents, use the plan's `Read First` section as the discoverability path; do not update broad
     indexes by default.
   - Update the nearest docs index or README only when the document is promoted or intentionally retained after execution.
   - Link from broader docs entrypoints only when future maintainers should find the document without prior plan/session context.
   - If no index exists, mention that in the final response rather than inventing broad navigation.

7. Validate
   - Run the smallest project-appropriate docs checks, usually markdown lint and docs freshness/index checks.
   - If the document names commands, files, tests, or runtime gates as acceptance criteria, verify obvious references when cheap.
   - Report validation that was run and anything intentionally skipped.

8. Record skill usage when retained evidence is required
   - This skill is the first docs-only pilot for `skill-usage.record.v1`.
   - When the skill creates or updates durable docs and the project allows retained evidence, write a compact skill usage record in the
     project evidence path or an `agent-out project --topic skill-usage --mkdir` run directory.
   - Link the implementation-readiness document, docs index changes, validation commands, and any typed child records from the envelope.
   - Prefer `skill-usage verify --out <record-dir> --format json`; use the documented local checkout fallback when PATH has not caught up.

## Relationship To Nearby Skills

- `review-evidence`: use for normalized review findings and validation records; link it from this document when evidence matters.
- `code-review-quick-pass`: use for lightweight read-only review of small or
  ordinary diffs referenced by this source document.
- `code-review-focused-lens`: use when this source document requests explicit
  review lenses.
- `code-review-pre-merge-gate`: use for PR/MR delivery gates derived from this
  source document.
- `code-review-follow-up`: use after fixes to re-check findings captured or
  linked by this source document.
- `code-review-specialists`: use only when the later review needs the broad or
  risky full specialist bundle.
- `create-plan-tracking-issue`: use when an existing plan that links this
  document under `Read First` needs a lightweight provider issue record.
- `deliver-plan-tracking-issue`: use when a lightweight issue-backed plan is
  ready to execute and deliver.
- `deliver-dispatch-plan`: use when implementation needs dispatch lanes,
  PR grouping, main-agent review, and final dispatch closeout.
- `execute-plan-tracking-issue`: use to resume execution from an existing
  lightweight plan-tracking issue.
- `handoff-session-prompt`: use after this skill when the user wants a copy-ready prompt for a fresh session; put this document under
  `Read First`.
