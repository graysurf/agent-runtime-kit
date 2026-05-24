# Provider-bound issue and PR bodies can leak machine-local paths

## Status

- Status: open
- First observed: 2026-05-24
- Area: provider-bound issue/PR/MR payload privacy
- Severity: medium
- Related incident: graysurf/agent-runtime-kit#84 latest state comment
  originally exposed a personal home path before manual redaction.

## Signal

Repo hooks and portable-path scans cover tracked files and direct tool writes,
but provider mutations can still publish already-rendered body files, summary
files, dashboards, or state comments after those gates have passed. The #84
tracking issue state comment exposed a local state artifact path in GitHub,
then was manually redacted to `$HOME/...`. A live read-back after redaction
reported `body_has_path=false`, `comment_path_count=0`, and
`comments_with_home=3`.

The unresolved system gap is the missing last-mile check on the exact payload
sent to GitHub or GitLab. Future `forge-cli` issue/PR comments,
`plan-issue record open|post|repair-dashboard` calls, or GitLab MR comments can
still publish personal path fragments if the rendered payload includes them.

## Evidence

- Raw record: none; #84 live tracker exercise surfaced this gap.
- Live GitHub read-back after manual redaction: #84 body had no personal path,
  comments with personal paths were `0`, and comments containing `$HOME` were
  `3`.
- Related active case: `plan-issue-v0-17-7-payload-fence-leak` covers the
  v0.17.7 visible payload-fence rendering regression. It does not cover
  provider-bound local-path privacy checks.
- Existing repository-side guards are insufficient for this class because the
  unsafe string may be introduced into a transient body file or generated
  summary and then sent directly to a remote provider.

## Impact

Public GitHub or GitLab timelines can retain personal usernames, machine-local
project layout, local state-home locations, or other workstation-specific
evidence paths even when repository files are clean. Manual patching after
publish reduces the visible damage, but it leaves a public audit window and
does not scale across issue bodies, comments, PR/MR comments, dashboard repair,
or GitLab parity paths.

## Current Workaround

Before posting a provider-bound issue, PR, MR, or tracker comment, scan the
final body file after all templating and rendering. Replace home-relative paths
with `$HOME/...` when the path is useful evidence, and omit local-only artifact
paths when a remote reader cannot use them.

For tracker work, audit the live provider payload after posting and patch any
missed local path immediately, then re-run the `plan-issue record audit`
read-back.

## Scope To Decide

- Primary enforcement location: prefer nils-cli because `forge-cli` and
  `plan-issue record` own the final provider mutation. Runtime-kit skills and
  hooks should still provide guidance and smoke coverage.
- Behavior: prefer fail-closed for arbitrary absolute home paths in live
  provider mutations. Allow an explicit redaction mode only where replacing a
  home prefix with `$HOME` preserves useful evidence.
- Coverage: include GitHub issue bodies/comments, GitHub PR comments, GitLab
  issue/MR comments, `plan-issue` dashboard repair, and any `--body-file`,
  `--summary-file`, or rendered-state path that posts to a remote provider.
- Exceptions: define a narrow allowlist for intentionally portable examples.
  Do not let archival docs or local `out/` evidence paths bypass the final
  provider-payload gate.

## Promotion Criteria

Promote this entry when all of the following are true:

- nils-cli has a provider-payload privacy gate before live GitHub/GitLab
  mutations, with tests for body-file, summary-file, dashboard, and rendered
  comment surfaces.
- The gate emits actionable JSON/text diagnostics naming the unsafe field or
  payload source, without echoing the personal path in retained evidence.
- Runtime-kit skills and smoke fixtures cover the #84 leak class for
  `create-plan-tracking-issue` plus at least one `forge-cli` comment flow.
- Skill guidance says provider-visible surfaces should use `$HOME` for useful
  home-relative evidence and should omit local-only artifacts when they are not
  useful to remote readers.

## Prevention Rule

Any workflow that posts a body or comment to a remote provider must scan the
exact payload after templating/rendering and before the API call. A clean source
file, plan bundle, or repository diff is not enough; the privacy gate belongs
on the final provider-bound payload.

## Next Action

Open a nils-cli follow-up scope for the provider-payload privacy gate, starting
with `forge-cli` and `plan-issue record` surfaces that accept body files,
summary files, dashboards, or rendered tracker comments.
