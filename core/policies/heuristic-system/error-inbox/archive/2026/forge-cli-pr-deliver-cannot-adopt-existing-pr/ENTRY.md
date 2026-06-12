# forge-cli pr deliver cannot adopt an existing draft PR for the branch

## Status

- Status: promoted
- First observed: 2026-06-12
- Area: forge-cli pr lifecycle
- Severity: medium

## Signal

On nils-cli v1.0.17, after `forge-cli pr create` had already opened draft
sympoies/nils-cli#817 from the current branch with a body that passes the
Summary / Test plan gate, a follow-up `forge-cli pr deliver --kind bug
--title <same title>` (no `--body`, intending to finish the open PR) failed
with `body_missing_sections` after only `auth_status` and `repo_view` steps.
The deliver macro validates its own create-step inputs before checking whether
an open PR already exists for the head branch, so a PR created separately can
never be finished by `pr deliver` — the macro is create-only in practice,
though its help ("open draft → CI green → ready → merge") reads as resumable.

## Evidence

- Raw record: not captured (manual diagnosis during a live delivery session,
  2026-06-12; the failing envelope is summarized below).
- Deliver envelope (2026-06-12, redacted): `ok=false`, steps
  `auth_status` ok → `repo_view` ok → error
  `body_missing_sections: body is missing required sections: '## Summary' and
  '## Test plan'`, with `data.pr.number=0` — no PR lookup for the head branch
  was attempted before the body gate fired.
- The PR was then delivered manually via the lifecycle surfaces:
  `forge-cli pr wait-checks 817` → `pr ready 817` → `pr merge 817 --method
  squash` (merged: <https://github.com/sympoies/nils-cli/pull/817>).
- Untested open question: whether re-running `pr deliver` with a compliant
  `--body-file` on a branch with an open PR would adopt it or attempt (and
  fail?) to create a duplicate. (Resolved by the fix: on adoption the
  `--title` / `--body` inputs are ignored by design — the existing PR keeps
  its own provider-validated title and body.)
- Upstream finding filed: graysurf/plan-tracking-testbed#62 (2026-06-12).
- Fix landed 2026-06-12 (promotion criteria option (a) in full):
  <https://github.com/sympoies/nils-cli/pull/823> merged to `main` (squash
  `954dd12`) — `pr deliver` now looks up open PRs for the resolved head
  branch between `repo_view` and create, adopts one when found (`adopt` step
  with the PR's `pr.view` payload replaces `create`; the PR's actual body is
  re-fetched via `pr view` and re-gated), and failure envelopes name the
  adopted PR instead of `data.pr.number=0`. Regression tests cover the
  create-then-deliver sequence (`pr_deliver_adopts_existing_open_pr_for_head_branch`,
  `pr_deliver_adopt_revalidates_existing_pr_body_and_fails_closed`). Finding
  graysurf/plan-tracking-testbed#62 closed. Ships in the first release after
  v1.0.17; the workaround below still applies to installed `<=1.0.17` hosts.

## Impact

Any split workflow that opens a draft early (create → iterate → deliver) hits a
dead-end command at the deliver step and must know to fall back to the three
individual lifecycle surfaces. Costs one failed invocation plus diagnosis time
per occurrence, and invites agents to "fix" it by re-passing `--body`, whose
behavior against an existing open PR is unverified.

## Current Workaround

For a branch that already has an open PR, skip `pr deliver` and drive the
lifecycle directly: `forge-cli pr wait-checks <n>` → `forge-cli pr ready <n>`
→ `forge-cli pr merge <n> --method squash`.

## Promotion Criteria

Promote once `forge-cli pr deliver` either (a) detects an existing open PR for
the head branch and adopts it — skipping the create step and running its body
gates against the PR's actual body — or (b) fails fast with a precise
`pr_already_exists`-class error that names the open PR and points at
`wait-checks` / `ready` / `merge`, validated by a regression test covering the
create-then-deliver sequence.

## Next Action

None. Fixed upstream by sympoies/nils-cli#823 (merged 2026-06-12) with
regression tests; finding graysurf/plan-tracking-testbed#62 closed. The
manual-lifecycle workaround remains relevant only for hosts pinned to
nils-cli <=1.0.17 until the next release ships.

## Archive

- Archived: 2026-06-12
- Reason: Completed entry archived out of the active error inbox.
- Durable link: `https://github.com/sympoies/nils-cli/pull/823`
