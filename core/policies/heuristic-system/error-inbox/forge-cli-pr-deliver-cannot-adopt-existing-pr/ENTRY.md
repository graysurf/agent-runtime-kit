# forge-cli pr deliver cannot adopt an existing draft PR for the branch

## Status

- Status: open
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
  fail?) to create a duplicate.

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

File the upstream finding against nils-cli (forge-cli) via
`report-plan-issue-finding`, proposing adopt-or-precise-error behavior for
`pr deliver` on branches with an existing open PR, and link the issue here.
