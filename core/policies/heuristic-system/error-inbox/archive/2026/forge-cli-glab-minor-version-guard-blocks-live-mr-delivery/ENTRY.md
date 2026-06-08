# forge-cli glab minor-version guard blocks live GitLab MR delivery

## Status

- Status: promoted
- First observed: 2026-06-08
- Area: forge-cli
- Severity: medium

## Signal

During a live GitLab deploy MR on 2026-06-08, `forge-cli pr create` succeeded
for a ready MR, and `forge-cli pr merge --dry-run` produced the expected
backend plan:

```text
glab mr merge 65 --remove-source-branch
```

But the live delivery path could not run `forge-cli pr checks 65` or
`forge-cli pr merge 65 --method merge`. Both failed before reaching GitLab:

```text
code=glab_version_unsupported
glab 1.100.x is not supported by this forge-cli build (pinned to 1.99.x)
```

GitLab API readbacks showed the MR was mergeable and the MR pipeline was
`success`. The agent had to merge through the GitLab API as a controlled
fallback.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-06-08)
- Repository: `gim/manifest/livekit-agents-deploy` on self-hosted GitLab.
- MR: `!65`, source `chore/deploy-test-full-flow-agent-9001`, target `main`.
- Pipeline: `313863`, SHA `4eae5cc5e61eee22e269035e5c5055d47c34dd98`, status
  `success`.
- Merge result: merge commit `5a99384f021c87f679ed46d38ab843c126acc39e`.
- Fallback used: GitLab API `PUT /projects/1936/merge_requests/65/merge` with
  source-branch removal after verifying `detailed_merge_status=mergeable`.

## Impact

Any GitLab MR delivery that depends on `forge-cli pr checks`,
`forge-cli pr wait-checks`, or live `forge-cli pr merge` can block solely
because the installed `glab` minor differs from the pinned parser range. The
same session showed the dry-run plan was valid, so agents can mistake dry-run
success for delivery readiness and only hit the blocker at the merge step.

## Current Workaround

Before using a fallback, verify all of:

- MR state is open and not draft.
- `detailed_merge_status=mergeable`.
- The head pipeline for the MR SHA is `success`.
- The source branch and target branch are the intended ones.

Then merge with the provider API or temporarily align the installed `glab`
minor to the `forge-cli` supported range. Do not copy raw Argo logs or provider
payloads into retained records; they can contain secrets.

## Promotion Criteria

Promote after one of:

- `forge-cli` supports a GitLab checks/merge path that does not require a
  single pinned `glab` minor for live operations.
- `forge-cli` exposes a clearer structured remediation that agents can follow
  before opening or merging GitLab MRs.
- Runtime surfaces pin or validate the supported `glab` version before GitLab
  MR delivery starts.

## Next Action

None. sympoies/nils-cli#798 implemented API-backed numeric GitLab MR checks/wait and merge while narrowing the glab version guard to the branch-only text fallback.

Lifecycle link: `https://github.com/sympoies/nils-cli/pull/798`

## Archive

- Archived: 2026-06-08
- Reason: Promoted after PR #798 implemented API-backed GitLab MR checks/wait and merge, narrowing the glab version guard to the branch-only text fallback.
- Durable link: `https://github.com/sympoies/nils-cli/pull/798`
