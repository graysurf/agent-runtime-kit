---
name: code-review-specialists
description:
  Decompose risky or broad diffs into read-only specialist review passes and merge normalized findings.
---

# Code Review Specialists

Use this workflow to review broad or risky diffs through focused, read-only
specialist lenses before a reviewer makes a decision.

## Contract

Prereqs:

- Run inside the target git repository with `git` available on `PATH`.
- `review-specialists` is installed from the released nils-cli package and
  available on `PATH`.
- Know the base ref for the diff under review, or explicitly choose one before
  running scope detection.
- Keep this workflow read-only: it does not auto-fix code, merge, close PRs/MRs,
  open/close issues, or post live provider comments.
- On hosts that spawn subagents without an explicit per-run request (e.g. Claude
  Code, or any host where the user invoked a delegation mode or explicitly asked),
  dispatch the managed read-only `reviewer-<lens>` subagents for the selected
  lenses by default. On hosts that only spawn subagents on explicit request (e.g.
  Codex), run the lenses inline by default — the expected path for that host, not
  a waiver — and dispatch subagents only when the user explicitly opts in. Either
  way the parent agent owns lens selection, dispatch, validation, and merge, and
  records a waiver only when an intended dispatch genuinely fails.
- Use `review-dispatch-lane-pr` for PR decision actions and `review-evidence` only
  when findings need a retained evidence record.

Inputs:

- Diff base ref, optional review target summary, and optional validation
  evidence to inspect.
- Optional forced specialist flags: `--testing`, `--security`,
  `--performance`, `--data-migration`, `--api-contract`, `--maintainability`,
  `--red-team`, or `--all-specialists`.
- Optional specialist JSONL finding files for deterministic validation, merge,
  rendering, and bundle synthesis.
- Optional confidence display threshold for merged findings.

Outputs:

- Scope JSON from `review-specialists scope` describing changed files, diff
  size, stack signals, test framework signals, and suggested specialists.
- Read-only specialist findings with concrete file or evidence anchors.
- A final specialist review report using
  `references/SPECIALIST_REVIEW_REPORT_TEMPLATE.md`.
- Optional `review-evidence` records when retained workflow evidence is needed.
- No source edits, PR/MR comments, merge decisions, or close decisions from this
  workflow.

Failure modes:

- Base ref is missing or does not resolve in the target repository.
- Diff is too small or low-risk for specialist review and no specialist was
  forced.
- Specialist output is malformed JSONL, lacks required fields, uses unsupported
  severity values, or omits evidence anchors.
- Findings lack enough confidence or evidence to support a concrete issue; mark
  them as residual risk instead of presenting them as verified findings.
- Caller tries to use this workflow as a substitute for `review-dispatch-lane-pr`,
  `review-evidence`, browser-session checks, CI repair automation, or
  implementation work.

## Entrypoint

Use the released CLI directly:

```bash
review-specialists scope --base "$BASE_REF" --format json
review-specialists validate --input findings.jsonl --format json
review-specialists merge --input findings.jsonl --summary-out specialist-review.md --format json
review-specialists render --profile report --input merged-findings.json --out specialist-review.md
review-specialists bundle --input findings.jsonl --out-dir "$REVIEW_OUT" --profile report --format json
```

## When To Use

- The user explicitly asks for specialist code review.
- A PR/MR or diff is large, risky, security-sensitive, migration-heavy,
  API-contract heavy, or broader than normal reviewer confidence.
- Normal tests are not enough to reason about cross-cutting risk.
- An issue or plan PR review needs supplemental specialist findings before the
  `review-dispatch-lane-pr` decision path.

Do not use it for tiny diffs, ordinary implementation work, pure formatting or
doc-only changes unless requested, CI repair loops, or browser-facing checks
owned by browser-session workflows.
Use `code-review-quick-pass` for lightweight review, `code-review-focused-lens`
for one explicitly requested lens, `code-review-pre-merge-gate` for delivery
gate review, and `code-review-follow-up` when re-checking previous findings
after fixes.

## Workflow

1. Establish the review target and base ref. For a PR/MR, use the actual
   PR/MR base or merge-base rather than a moving `origin/main` guess.
2. Run deterministic scope detection:

   ```bash
   review-specialists scope --base "$BASE_REF" --format json
   ```

3. If `diff_lines < 50`, skip specialist review unless the user forced a
   specialist or all specialists.
4. Select specialists:
   - Always consider `testing` and `maintainability` for larger diffs.
   - Consider `security` for auth changes or backend changes over 100 diff
     lines.
   - Consider `performance` for backend or frontend runtime changes.
   - Consider `data-migration` for migration, schema, or data transform changes.
   - Consider `api-contract` for route, controller, API schema, OpenAPI,
     GraphQL, or protocol changes.
5. Select the matching managed reviewer subagents for the chosen lenses
   (`reviewer-testing`, `reviewer-maintainability`, `reviewer-security`,
   `reviewer-performance`, `reviewer-data-migration`, `reviewer-api-contract`),
   installed at `~/.codex/agents/reviewer-<lens>.toml` and
   `~/.claude/agents/reviewer-<lens>.md`.
6. Dispatch the selected read-only reviewer subagents one per lens, handing each
   the base ref and scope; each inspects read-only and returns JSONL findings for
   its lens. This is the default on hosts that spawn subagents without an explicit
   per-run request (e.g. Claude Code). On hosts that only spawn subagents on
   explicit request (e.g. Codex), or when an intended dispatch fails, run the
   lenses inline (reading the prompt from `references/specialists/`); inline is
   the expected path for explicit-only hosts and needs no waiver, but record a
   waiver when an intended dispatch genuinely fails. You stay the parent: you own
   base-ref selection, lens selection, dispatch, and the validation/merge steps
   below.
7. Collect each subagent's JSONL findings (or the inline equivalent) following
   `references/SPECIALIST_REVIEW_CONTRACT.md`. Treat malformed JSONL, missing
   required fields, unsupported severities, or absent evidence anchors as a
   workflow failure or residual risk for that lens — never promote it to a
   verified finding. Mark unverifiable claims as residual risk, not findings.
8. Validate and merge findings:

   ```bash
   review-specialists validate --input findings.jsonl --validate-paths --format json
   review-specialists merge --input findings.jsonl --summary-out specialist-review.md --format json
   ```

9. Run red-team only after the selected specialists when `diff_lines > 200`, any
   selected specialist produced a `critical` finding, or the reviewer forced it.
   On hosts that spawn subagents without an explicit per-run request, dispatch
   `reviewer-red-team`; on explicit-only hosts such as Codex, run the same
   red-team lens inline from `references/specialists/red-team.md` unless the
   user explicitly opted into subagents. Hand it the merged first-wave findings
   so it can probe cross-cutting failure modes. Pass the red-team JSONL through
   `review-specialists validate`, then append it to the first-wave JSONL and run
   `review-specialists merge` again over the combined input so duplicate
   fingerprints, confirming specialists, and confidence ordering are resolved in
   the final report.
10. Use the report template for the final synthesis. The recommended next step
    may route to `review-dispatch-lane-pr`, a normal implementation workflow, or a
    retained `review-evidence` record, but this workflow does not execute that
    decision.

## Boundary

`code-review-specialists` owns scope detection, specialist selection,
reviewer-subagent dispatch, validation and merge of the returned findings, and
the merged report. Each `reviewer-<lens>` subagent owns only its read-only lens.
This workflow does not fix code, post PR or MR review comments, mark a draft
reviewable ready, merge, close issues, or execute the recommended next step —
those belong to the owning PR / MR delivery skills, `review-dispatch-lane-pr`,
or `review-evidence`.

## References

- Reviewer subagent sources:
  `core/agents/code-review/reviewer-<lens>/AGENT.md.tera`
- Specialist review contract:
  `references/SPECIALIST_REVIEW_CONTRACT.md`
- Quick pass workflow:
  `skills/code-review/code-review-quick-pass/SKILL.md`
- Focused lens workflow:
  `skills/code-review/code-review-focused-lens/SKILL.md`
- Pre-merge gate workflow:
  `skills/code-review/code-review-pre-merge-gate/SKILL.md`
- Follow-up workflow:
  `skills/code-review/code-review-follow-up/SKILL.md`
- Report template:
  `references/SPECIALIST_REVIEW_REPORT_TEMPLATE.md`
- Specialist prompts:
  `references/specialists/`
- Delivery specialist review gate:
  `references/DELIVERY_SPECIALIST_REVIEW_GATE.md`
- Delivery review outcome comment:
  `references/DELIVERY_REVIEW_OUTCOME_COMMENT.md`
- Delivery review outcome schema:
  `references/DELIVERY_REVIEW_OUTCOME_SCHEMA.md`
- PR decision workflow:
  `skills/dispatch/review-dispatch-lane-pr/SKILL.md`
- Review evidence tool:
  `skills/evidence/review-evidence/SKILL.md`
