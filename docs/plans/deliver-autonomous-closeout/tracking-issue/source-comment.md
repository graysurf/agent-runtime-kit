<!-- plan-tracking-issue:snapshot:v1 kind=source -->

## Source Snapshot

- Path: `docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-discussion-source.md`
- Commit: `bd296d5698346c272496facd246130d397fcdcd0`

- Snapshot mode: local committed Markdown

<details>
<summary>Source snapshot</summary>

# Deliver-* Skills Autonomous Closeout Discussion Source

- Status: ready for plan execution
- Date: 2026-05-23
- Source: in-session inventory of the four `deliver-*` skills in
  `core/skills/dispatch/` and `core/skills/pr/`, plus the user
  question "現在 /deliver-plan-tracking-issue 有做
  /plan-tracking-issue-closeout 的工作嗎" and the follow-up direction
  to redesign the deliver series as self-contained "implement → land →
  close" workflows.
- Intended next step: execute a follow-up plan inside
  agent-runtime-kit that lets every `deliver-*` skill drive its
  matching `*-closeout` (or `close-*`) skill in the same invocation
  when closeout-readiness is satisfied, instead of stopping at
  closeout-ready and handing off to a second skill invocation.

## Execution

- Recommended plan: docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-plan.md
- Recommended execution state: docs/plans/deliver-autonomous-closeout/deliver-autonomous-closeout-execution-state.md

## Purpose

The four `deliver-*` skills currently ship two different self-completion
contracts:

- The two **PR-level** deliveries (`deliver-github-pr`,
  `deliver-gitlab-mr`) already run end-to-end against the PR/MR
  itself: create → wait checks → specialist review → outcome comment →
  `forge-cli pr merge`. They are autonomous up to the merge boundary.
- The two **issue-level** deliveries (`deliver-plan-tracking-issue`,
  `deliver-dispatch-plan`) deliberately stop at "closeout-ready" and
  delegate the actual closeout (closeout-gate, closeout comment,
  dashboard repair, `forge-cli issue close`) to a second skill
  invocation (`plan-tracking-issue-closeout` or
  `dispatch-plan-closeout`).

The asymmetry is intentional today — `plan-issue record` owns
closeout-gate evaluation, and the issue-level deliver skills wanted a
clean handoff boundary. But the user-facing cost is real: every
"deliver this plan" workflow ends with a second prompt to run the
closeout skill, even when nothing about the run is ambiguous. The PR
deliveries also leave a parallel gap: they can land an MR/PR that
references a tracking or dispatch issue, but they refuse to let the
provider auto-close that issue on merge, so the surrounding issue
lifecycle still needs a manual closeout invocation.

The user direction is to make the deliver series self-contained: a
single `deliver-*` invocation should carry implementation through
final issue / PR closure when the readiness gates pass, and only stop
short when a gate fails or a documented exception applies.

## Confirmed Facts

- [F1] `core/skills/dispatch/deliver-plan-tracking-issue/SKILL.md.tera`
  Step 11 ("Close through `plan-tracking-issue-closeout` after
  completion approval") explicitly delegates closeout to a second
  skill. Step 10 ("verify the latest lightweight state is
  closeout-ready") is a readiness check, not a closeout action.
- [F2] `core/skills/dispatch/deliver-dispatch-plan/SKILL.md.tera`
  Step 12 ("Close through `dispatch-plan-closeout` after final
  approval") delegates dispatch-version closeout the same way.
- [F3] `core/skills/pr/deliver-github-pr/SKILL.md.tera` Step 9 runs
  `forge-cli pr merge "$PR_NUMBER" --method squash` directly. The
  workflow lists "An MR/PR would close a plan-tracking or dispatch
  issue before [closeout skill] cleared the gate" as a failure mode
  (lines 56-58) — issue auto-close is intentionally blocked.
- [F4] `core/skills/pr/deliver-gitlab-mr/SKILL.md.tera` mirrors the
  GitHub variant: end-to-end MR merge, gated against auto-closing a
  plan-tracking or dispatch issue without prior closeout-gate pass.
- [F5] The matching closeout skills already encapsulate the closeout
  logic deliver-* would need to call: `plan-tracking-issue-closeout`
  for tracking issues (closeout-gate, closeout comment, dashboard
  repair, `forge-cli issue close --reason completed`),
  `dispatch-plan-closeout` for dispatch runtimes, and `close-github-pr`
  / `close-gitlab-mr` for non-merge PR/MR closures.
- [F6] `plan-issue record closeout-gate --profile {tracking,dispatch}`
  is the single deterministic CLI entrypoint for closeout readiness
  evaluation; both closeout skills wrap it.
- [F7] `forge-cli` already exposes `issue close --reason completed`
  and `pr close` atoms. No new provider atom is required to land
  autonomous closeout.
- [F8] The existing skill boundary rule ("`plan-issue record` owns
  closeout-gate evidence, `forge-cli` owns provider lifecycle") does
  not require closeout to live in a separate skill — only that the
  rendering and gate evaluation stay in `plan-issue record`. A
  deliver-* skill is free to invoke the same CLI commands the
  closeout skill invokes, provided ownership stays with the CLI.
- [U1] The user stated "我想把這系列設計為自主完成並關 issue/PR" — the
  intended end state is a deliver-series that, when closeout gates
  pass, autonomously closes the issue and/or PR without requiring a
  second skill invocation.

## Decisions

1. Add an explicit closeout chaining step to each `deliver-*` skill
   instead of replacing or merging the matching `*-closeout` /
   `close-*` skill.
2. Keep the boundary contract: deliver-* skills call the same
   `plan-issue record closeout-gate` and `forge-cli issue close` /
   `forge-cli pr close` commands the closeout skills wrap. The
   closeout skill bodies remain the canonical reference for the
   sequence; deliver-* embeds the same sequence inline so a single
   invocation can complete it.
3. Closeout chaining is **conditional**: it runs only when the
   gate passes with the evidence deliver-* already collected. If
   the gate fails, deliver-* stops with an explicit unblock message
   and recommends the matching closeout skill for a follow-up pass,
   matching today's behavior.
4. Provide an explicit opt-out flag (e.g. `--no-closeout`) so users
   who want the previous "stop at closeout-ready" behavior can keep
   it without bypassing the rest of deliver-*.
5. PR-level deliveries (`deliver-github-pr`, `deliver-gitlab-mr`)
   gain the same chained closeout for the linked issue (if any),
   while keeping the existing block on PR-body `Closes #N`
   auto-close. The chaining happens after merge, through
   `plan-tracking-issue-closeout` / `dispatch-plan-closeout` invoked
   inline, so the boundary contract on issue closure stays
   `forge-cli`-owned.
6. The closeout skills (`plan-tracking-issue-closeout`,
   `dispatch-plan-closeout`, `close-github-pr`, `close-gitlab-mr`)
   remain published, callable, and unchanged in behavior. They are
   the recovery surface for failed chained closeouts and for
   manually closing issues / PRs outside a deliver-* invocation.

## Open Questions

- Should the chained closeout run before or after the final
  `forge-cli pr merge` for PR-level deliveries? Running it after
  merge avoids racing against the merge commit reaching `main`;
  running it before merge keeps the failure mode "PR merged but
  closeout skipped" off the table. Default decision pending Sprint 2.
- Does the dispatch profile need any new metadata in the closeout
  comment to distinguish "closed via chained deliver" from "closed
  via standalone closeout skill"? Default: no — the closeout comment
  records skill identity through `plan-issue record render-comment
  --profile dispatch`, and the deliver-* skill body is already
  visible through session/validation comment authorship.
- Should `--no-closeout` be a per-skill flag or a shared deliver-*
  contract flag? Lean toward shared — keeps the interface symmetric
  across the four skills.

## Out Of Scope

- Renaming or deprecating `plan-tracking-issue-closeout`,
  `dispatch-plan-closeout`, `close-github-pr`, or `close-gitlab-mr`.
- Touching the closeout-gate evaluation logic itself (lives in
  `plan-issue record closeout-gate`, owned by `nils-cli`).
- Changing the `forge-cli` PR / issue lifecycle atoms.
- Reworking the lifecycle comment marker contract (the
  `<!-- tracking-issue-closeout:v1 -->` marker stays exactly as is).


</details>
