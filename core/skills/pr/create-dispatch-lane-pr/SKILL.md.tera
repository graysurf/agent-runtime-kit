---
name: create-dispatch-lane-pr
description:
  Create a dispatch-lane pull / merge request with `forge-cli pr create` after a plan issue assigns the lane (GitHub PR or GitLab MR; provider auto-detected from the cwd remote or `--repo`).
---

# Create Dispatch Lane PR / MR

## Contract

Prereqs:

- `forge-cli` and `plan-issue >=0.22.0` are installed from the released
  nils-cli package and available on `PATH`. (`plan-issue >=0.22.0` ships the
  GitLab provider abstraction; earlier versions are GitHub-only.)
- A plan issue or dispatch record identifies the lane, source branch, base
  plan branch, task scope, and required validation.
- Dispatch-plan lanes must target `PLAN_BRANCH`, not the repository default
  branch.
- Provider authentication succeeds for the target host when running live
  mode: `gh auth status` for GitHub, `glab auth status` for GitLab.
- The lane branch has been pushed and has an upstream tracking branch.

Inputs:

- Dispatch lane id, task id, source branch, base plan branch, title, and body
  file.
- Validation evidence or an explicit not-run reason for the lane.
- Required body sections: `## Summary`, `## Scope`, `## Testing`,
  `## Test plan`, and `## Issue`.
- Required labels: one `type::`, one primary `area::`, one `size::`, and
  `workflow::dispatch`. Optional reviewers.

Outputs:

- A draft PR (GitHub) or MR (GitLab) for the dispatch lane.
- Provider command evidence in `--dry-run` mode.
- PR / MR URL recorded back to the owning plan issue or dispatch record.

Failure modes:

- The dispatch record is missing branch, base, task, or validation data.
- The PR / MR body is missing required `forge-cli` sections such as
  `## Summary` and `## Test plan`, or dispatch sections `## Scope`,
  `## Testing`, and `## Issue`, or still contains placeholders.
- The PR / MR base is not the dispatched `PLAN_BRANCH`.
- Provider auth, branch upstream checks, labels, or reviewers fail.

## Entrypoint

Use the released CLI directly. `forge-cli` auto-detects the provider from the
cwd's git remote (or honors an explicit `--provider {github|gitlab}` / `--repo
<slug>` override), so the same invocation creates a GitHub PR or a GitLab MR
depending on where the lane branch lives.

```bash
forge-cli pr create \
  --kind feature \
  --base "$PLAN_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE" \
  --label type::feature \
  --label area::skills \
  --label size::s \
  --label workflow::dispatch \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels
```

For an audited preview:

```bash
forge-cli --dry-run --format json pr create \
  --kind feature \
  --base "$PLAN_BRANCH" \
  --title "$PR_TITLE" \
  --body-file "$PR_BODY_FILE" \
  --label type::feature \
  --label area::skills \
  --label size::s \
  --label workflow::dispatch \
  --label-catalog manifests/forge-labels.yaml \
  --strict-labels
```

Post the issue-visible dispatch handoff comment with the shared record owner:

```bash
plan-issue --repo "$REPO" --format json record post \
  --issue "$PLAN_ISSUE" \
  --profile dispatch \
  --kind session \
  --payload-file "$DISPATCH_SESSION_PAYLOAD" \
  --summary-file "$DISPATCH_SESSION_FILE"
```

## Workflow

1. Read the owning dispatch record and confirm the lane scope, source branch,
   base plan branch, and validation expectations.
2. Inspect `git status --short --branch`, then push the lane branch and confirm
   upstream tracking.
3. Render a PR / MR body with `## Summary`, `## Scope`, `## Testing`,
   `## Test plan`, and `## Issue`; include the lane id, task ids, validation,
   issue link, and handoff notes.
4. Select taxonomy labels before provider mutation. Every dispatch lane needs
   `type::`, one primary `area::`, `size::`, and `workflow::dispatch`. Use
   `state::do-not-merge` when a lane is blocked from merging.
5. If `manifests/forge-labels.yaml` exists, run `forge-cli label ensure
   --catalog manifests/forge-labels.yaml --repo "$REPO" --format json` before
   the first live lane PR / MR in that repo. Use `label audit` when mutation
   is not allowed.
6. Run the `forge-cli --dry-run` form when the lane needs command-shape
   evidence before mutation.
7. Confirm the requested base equals the assigned `PLAN_BRANCH`.
8. Run `forge-cli pr create ...` to create the draft lane PR (GitHub) or MR
   (GitLab). Add `--provider github` / `--provider gitlab` only when the cwd
   remote does not match the intended target.
9. Write the PR / MR URL back to the owning issue timeline by posting a
   dispatch `session` comment with `plan-issue record post --profile dispatch`.
   Use `plan-issue link-pr` only for pre-record compatibility issues that
   already use a `Task Decomposition` body.

## Boundary

`forge-cli` owns the PR / MR creation call (GitHub via `gh`, GitLab via
`glab`). `plan-issue record` owns the dispatch issue timeline update — on
GitLab, `plan-issue >=0.22.0` routes every lifecycle method through
`forge-cli`'s provider-neutral surface (sympoies/nils-cli#499 / #503 / #505).
The dispatch workflow owns lane selection, validation interpretation, and
reviewer or subagent handoff policy.
