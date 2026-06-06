# runtime-kit release script selects stale publish-image runs after same-tag recreation

## Status

- Status: promoted
- First observed: 2026-06-04
- Area: runtime-kit release script; publish-image workflow discovery
- Severity: medium

## Signal

During the runtime-kit `v2026.06.04` release, the first `publish-image` run
failed in the zsh fixture smoke. After deleting and recreating the same GitHub
Release / tag at a newer commit, `.agents/scripts/release.sh --execute
--version v2026.06.04` created the release but selected the previous failed
`publish-image` run for the same tag instead of the newly triggered run for the
current tag SHA.

## Evidence

- Raw record: not captured (manual diagnosis during release recovery, 2026-06-04).
- Summary: `release.sh --execute --version v2026.06.04` reported the old failed
  run IDs `26905540959`, `26906254982`, and `26906618433` after same-tag
  recreation, while `gh run list --workflow publish-image.yml` showed newer
  in-progress release runs for newer head SHAs. Manual recovery was to select
  and watch the latest run matching the current tag commit SHA, ending with
  successful run `26907034618` for head SHA `08189352`.

## Impact

Release automation can falsely report a failed release after it successfully
creates a replacement release and starts the correct workflow. Agents may then
delete/recreate tags repeatedly or stop even though a valid in-progress run
exists. The failure is especially likely during same-day CalVer retry flows that
reuse one tag after a smoke-test repair.

## Current Workaround

After same-tag release recreation, inspect `gh run list --workflow
publish-image.yml --json databaseId,status,conclusion,headSha,createdAt,event`
and choose the newest release run whose `headSha` matches `git rev-parse
origin/main` / the current tag SHA. Watch that run directly with `gh run watch
<run-id> --exit-status`, then run `release.sh --verify-only --version <tag>` to
verify the published manifests.

## Promotion Criteria

Promote after `scripts/release.sh` filters candidate `publish-image` runs by
current tag commit SHA, release creation time, or both, and has coverage for
same-tag recreation after failed `publish-image` runs.

## Next Action

None. Fixed on main by commit 45fd65a, which filters publish-image release
runs by the release target SHA and adds an offline stale-run smoke test.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/commit/45fd65a336f1a0778183e8a1c94989eddcace74e`

## Archive

- Archived: 2026-06-06
- Reason: Fixed on main by commit 45fd65a with release-run SHA filtering and
  stale-run smoke coverage.
- Durable link: `https://github.com/graysurf/agent-runtime-kit/commit/45fd65a336f1a0778183e8a1c94989eddcace74e`
