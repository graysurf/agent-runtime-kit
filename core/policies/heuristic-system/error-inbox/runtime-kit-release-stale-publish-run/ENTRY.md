# runtime-kit release script selects stale publish-image runs after same-tag recreation

## Status

- Status: open
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

Update scripts/release.sh to select the publish-image run matching the current release tag commit SHA or createdAfter time, and add coverage for same-tag recreation after failed publish-image runs.
