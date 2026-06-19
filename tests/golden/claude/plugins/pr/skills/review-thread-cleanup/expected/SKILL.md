---
name: review-thread-cleanup
description:
  Drive a PR/MR review-thread sweep to convergence — discover unresolved
  threads, triage each against the shared convergence policy, then resolve,
  reply, or defer through `forge-cli pr review-threads`.
---

# Review Thread Cleanup

## Contract

Prereqs:

- `forge-cli >=1.9.1` is installed from the released nils-cli package and on
  `PATH`. It exposes the `pr review-threads` group: `list` (provider-aware
  read) plus the GitHub-only `resolve` and `reply` write subcommands.
- The triage and stopping discipline is governed by
  `core/policies/review-thread-convergence.md`. This skill owns the
  orchestration; that policy owns the per-finding judgment and the
  convergence/stopping rule. Read it before dispositioning anything.
- The target PR/MR number is known. For the write surfaces, the provider is
  GitHub (`resolve` / `reply` return `provider_unsupported` on GitLab / Local
  in v1; on GitLab, converge threads through the provider UI or `glab` until
  `forge-cli` abstracts them).
- When a board or external discovery source feeds the candidate PR set, that
  set is already resolved (for example a `symphony-board review-candidates`
  sweep). This skill does not own candidate discovery.

Inputs:

- Provider: `github` or `gitlab` (let `forge-cli` detect from the remote, or
  pass `--provider`). The read surface is provider-aware; the write surfaces are
  GitHub-only in v1.
- PR/MR number, and — for a write action — the thread node id (`PRRT_…`) from
  the `list` envelope.
- A disposition per thread chosen from the convergence policy's triage table
  (`fix` / `stale` / `follow_up` / `accepted`), plus any reply note.

Outputs:

- The unresolved-thread set from `forge-cli pr review-threads list`, with each
  thread classified per the convergence policy.
- For each thread: a recorded repair, a reply-and-resolve, a follow-up ref, or a
  recorded `accepted` rationale — never a silent skip.
- A convergence outcome: `data.unresolved == 0`, or an explicit, recorded stop
  with the residual threads dispositioned as `follow_up` / `accepted`.

Failure modes:

- A thread is left unresolved with no disposition; `forge-cli pr merge` then
  fails closed on `unresolved_review_threads` (by design).
- `accepted` is used to silence an unverified finding without a recorded
  rationale — the policy forbids this.
- A `major` / high-risk finding is resolved without escalation — the policy
  always escalates these.
- `resolve` / `reply` is attempted on GitLab / Local and returns
  `provider_unsupported`; converge those threads through the provider surface
  instead.
- The installed `forge-cli` is older than the manifest floor (no
  `review-threads` subcommand group). Upgrade nils-cli first.

## Entrypoint

`forge-cli` detects the provider from the remote; pass `--provider "$PROVIDER"`
to pin it. Discover the unresolved threads first:

```bash
forge-cli --provider "$PROVIDER" --format json pr review-threads list "$PR_NUMBER"
```

`data.unresolved == 0` is the convergence target. Each `data.threads[]` entry
carries the thread `id` (`PRRT_…`), `path`, the normalized `resolved` /
`outdated` booleans (not GitHub's raw `isResolved` / `isOutdated`), and the
first comment — the inputs the convergence policy triages on.

For each thread that triage says to close on GitHub, reply-and-resolve in one
call (the `--note` reply is posted before the thread is resolved), or resolve
without a reply, or reply without resolving:

```bash
# Reply, then resolve (idempotent): the documented disposition for fix / stale.
forge-cli --provider github --format json \
  pr review-threads resolve "$PR_NUMBER" --thread "$THREAD_ID" \
  --note "Addressed in <commit>; <one-line rationale>."

# Resolve without a reply (when the reply is redundant).
forge-cli --provider github --format json \
  pr review-threads resolve "$PR_NUMBER" --thread "$THREAD_ID"

# Reply without resolving (e.g. to ask a question or record a follow-up ref).
forge-cli --provider github --format json \
  pr review-threads reply "$PR_NUMBER" --thread "$THREAD_ID" \
  --body "Tracked in <issue/PR ref>; deferring per convergence policy."
```

## Workflow

1. Read `core/policies/review-thread-convergence.md`. It is the judgment
   contract: the per-finding triage table, the convergence/stopping rule, and
   the concentrate-vs-converge guidance.
2. Run `pr review-threads list "$PR_NUMBER"` and enumerate every
   `resolved == false` thread (the envelope's normalized field; `data.unresolved`
   is the same count). If `data.unresolved == 0`, there is nothing to sweep — stop.
3. Triage each unresolved thread against the policy table: `fix` (repair the
   code), `stale` (already addressed / outdated), `follow_up` (defer with a
   ref), or `accepted` (won't-do with a recorded rationale). Always escalate
   `major` / high-risk findings to the user rather than self-dispositioning.
4. Apply each disposition through the Entrypoint surfaces: reply-and-resolve for
   `fix` / `stale`, `reply` + a follow-up ref for `follow_up`, and a recorded
   rationale (replied, then resolved) for `accepted`. Never resolve a thread
   without a disposition the policy permits.
5. Re-run `pr review-threads list` and confirm convergence. Stop when
   `data.unresolved == 0`, or record an explicit stop with the residual threads
   dispositioned as `follow_up` / `accepted` per the policy's stopping rule.
6. When retaining a `skill-usage` envelope for a real sweep, keep it compact but
   diagnosable. Record or link: provider, repo, PR/MR number, `forge-cli`
   version, initial and final `data.unresolved` counts, and for each unresolved
   thread the `id`, `path`, `outdated`, disposition (`fix` / `stale` /
   `follow_up` / `accepted`), and rationale or follow-up ref. Link typed child
   evidence for large list outputs; do not paste raw provider payloads into the
   envelope.
7. Hand the converged PR/MR back to the delivery / close surface
   (`pr:deliver-pr` / `pr:close-pr`), whose `pr merge` gate confirms
   `unresolved_review_threads == 0` mechanically.

## Boundary

`forge-cli` owns the provider mechanics — listing threads and the GitHub
`resolve` / `reply` mutations. `core/policies/review-thread-convergence.md` owns
the judgment: which disposition each finding gets, when to concentrate versus
converge, and when to stop. This skill orchestrates the two into a sweep; it
does not reimplement the GraphQL mutations and does not own candidate discovery.
A board-backed consumer (e.g. `symphony-board`'s `project-review-cleanup`
adapter) supplies the candidate PR set and calls this skill per PR. If a future
need wants structured cross-PR sweep state, extract that into released
`nils-cli` first and call it from here.

Shared rules: `core/skills/pr/pr-lifecycle/README.md`.
