# project-release-workflow rerun can wait for CI on an unpushed release bump

## Status

- Status: promoted
- First observed: 2026-05-31
- Area: project-release-workflow release retry
- Severity: medium

## Signal

During `sympoies/nils-alfredworkflow` release `v1.3.2`, the project-local
`.agents/scripts/release.sh` created the version-bump commit, then `git push`
was rejected because `origin/main` advanced. After rebasing the release bump,
the script would not push the already-synced commit on retry because
`version sync targets` were already up to date; without a manual push, the next
step would wait for CI on a local-only SHA until timeout.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-05-31)
- Summary: release attempt output showed `HEAD -> main (fetch first)` rejection
  after `chore(release): bump version to 1.3.2`; rerun output showed
  `version sync targets: already up to date` before CI wait. Manual recovery
  pushed rebased commit `47e06fe` to `main`, then reran the dispatcher to push
  tag `v1.3.2` and verify the release page.

## Impact

Release retries after remote drift can hang or time out even though the correct
release bump commit exists locally. The failure is easy to misread as a slow CI
run unless the agent notices that the release commit was never pushed.

## Current Workaround

None. Resolved by `project-release-workflow.sh` pushing an already-synced
`HEAD` when it is ahead of the configured upstream before waiting for CI or
pushing the release tag.

## Promotion Criteria

Promote after `project-release-workflow.sh` detects this retry state and either
pushes `HEAD` when it is ahead of upstream and versions are already synced, or
fails before CI wait with a clear recovery message. Add script coverage for a
push-rejected retry path.

## Next Action

None. Fixed in
`https://github.com/sympoies/nils-alfredworkflow/commit/038890d48348078c7fd7ff7f58fb0e16ad357f86`.

Lifecycle link: `https://github.com/sympoies/nils-alfredworkflow/commit/038890d48348078c7fd7ff7f58fb0e16ad357f86`

## Archive

- Archived: 2026-06-06
- Reason: Completed entry archived out of the active error inbox.
- Durable link: `https://github.com/sympoies/nils-alfredworkflow/commit/038890d48348078c7fd7ff7f58fb0e16ad357f86`
