# CI Watchers Must Key On The Exact Pushed Commit Operation Record

## Status

- Date: 2026-06-12
- Status: compression record over resolved cases (cluster rule)
- System area: release / delivery scripts that push then watch CI
- Durable fix paths:
  - `sympoies/nils-cli`
    `.agents/skills/project-deliver-dependabot-bump-pr/scripts/project-deliver-dependabot-bump-pr.sh`
    (PR #817)
  - `sympoies/nils-alfredworkflow` `.agents/scripts/release.sh`
    (case `project-release-rerun-misses-pushed-bump`)
  - `agent-runtime-kit` `.agents/scripts/release.sh`
    (case `runtime-kit-release-stale-publish-run`)

## Signal

Three independently diagnosed failures share one root cause: a CI-run watcher
selected its target using a name-based or freshly-read provider state instead
of the exact commit SHA the workflow had just produced.

- `project-release-rerun-misses-pushed-bump` (archived): a release rerun was
  about to wait for CI on a local-only SHA that had never been pushed —
  name-level state ("version sync targets up to date") masked the missing push.
- `runtime-kit-release-stale-publish-run` (archived): after deleting and
  recreating a GitHub Release/tag at a newer commit, run selection by tag name
  picked the previous failed `publish-image` run instead of the run for the
  current tag SHA.
- `project-deliver-dependabot-bump-pr` stale-head race (fixed same-session,
  sympoies/nils-cli#817, 2026-06-12): immediately after `git push`, `gh pr
  view` still reported the pre-push `headRefOid` (provider read-after-write
  lag); the watcher keyed on that stale OID selected the previous head's
  already-failed run and aborted delivery. Reproduced 3/3 on PRs #811–#813.

## Evidence

- Archived sibling case (2026 archive tree): the alfredworkflow release rerun
  that nearly waited for CI on an unpushed version bump.
- Archived sibling case (2026 archive tree): the runtime-kit release that
  selected a stale publish-image run after recreating the same tag.
- Fixed in-session with failing-test evidence: sympoies/nils-cli#817
  (<https://github.com/sympoies/nils-cli/pull/817>), reproduced live on
  PRs #811–#813 before the fix.

## Diagnosis

The shared anti-pattern is trusting an indirection (branch tip, tag name, PR
head read back from the provider right after a write) to identify "the run for
what I just did". Each indirection has a window where it aliases to the
previous state: unpushed commits, recreated tags, and provider read-after-write
lag. Watching CI through the indirection during that window selects a stale,
usually already-failed run, and the failure mode is convincing — a real
conclusion from a real run, just the wrong one.

## Durable Fix

The individual fixes are landed and linked under Status. The reusable rule for
any script that pushes (or tags) and then watches CI:

1. Capture the exact commit SHA locally at push time (`git rev-parse HEAD`);
   never re-derive it from a provider read made immediately afterward.
2. Verify the push actually happened before any wait loop arms.
3. Poll the provider until its view (PR head, tag target) converges to that
   SHA before trusting summary surfaces like `gh pr checks`; on a bounded
   timeout, proceed but keep run selection keyed to the SHA.
4. Select workflow runs by `headSha == <expected>` (e.g. `gh run list
   --commit <sha>`), never by branch or tag name alone.

## Promotion Decision

Compressed per the Compression Rule: the three source cases are resolved (two
archived, one fixed in-session with a regression test), span three repos and
two script families (release vs PR delivery), and the class keeps reappearing
wherever a new push-then-watch script is written. The cluster rule is the
reusable artifact; the individual fixes are already landed and linked above.

## Validation

- nils-cli #817 carries a `ci-stale-head` regression case in the skill test
  harness (mock returns a stale `pr view` OID; SHA-keyed `run list`), failing
  against the pre-fix script and passing post-fix.
- The two archived cases were validated by their own promoted fixes
  (rerun-push guard; tag-SHA-keyed run selection) before archive.

## Retention

This record retains the cross-repo rule so future push-then-watch scripts can
be written (and reviewed) against it without re-deriving the failure class
from the individual cases.
