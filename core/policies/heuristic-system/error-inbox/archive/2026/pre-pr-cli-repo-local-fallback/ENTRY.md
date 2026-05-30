# pre-pr CLI missing on PATH; meta/pre-pr requires repo-local script

## Status

- Status: promoted
- First observed: 2026-05-25
- Area: meta/pre-pr skill; runtime-kit dispatcher policy
- Severity: medium

## Signal

`meta/pre-pr` SKILL is a dispatcher that delegates to a repo-local
`.agents/scripts/pre-pr.sh`. There is no `pre-pr` binary on PATH and no
fallback gate. Bare or freshly-bootstrapped repositories
(no `.agents/scripts/pre-pr.sh`) cannot run the pre-PR validation gate at all.
The skill description says it "dispatches to a repository-owned" script, but
provides neither a built-in default nor a clear error when the script is
missing — agents discover the gap only when they try to invoke it before
opening a PR / MR.

## Evidence

- Raw record: not captured at first occurrence.
- Repro:

  ```sh
  which pre-pr           # → pre-pr not found
  ls .agents/scripts/pre-pr.sh   # → No such file in a sandbox / bare repo
  # Invoking the SKILL in such a repo dispatches to a missing script.
  ```

- Affected sandbox: `terrylin/agent-runtime-testing` (Phase P4 of the GitLab
  skill-validation sweep, sympoies/nils-cli#506 P1-2 / F-6).
- Source: sympoies/nils-cli#506 P1-2 (F-6); originally surfaced in
  `terrylin/agent-runtime-testing:docs/plans/gitlab-skill-validation/
  gitlab-skill-validation-discussion-source.md` Findings table F-6.

## Impact

- Bare repos (typical for new sandboxes, ad-hoc plan-tracker repos, and any
  consumer that has not adopted `.agents/scripts/pre-pr.sh`) cannot run the
  pre-PR gate, so the merge-readiness check enforced by home `AGENT_HOME.md`
  silently degrades to "no gate".
- Agents either skip the gate (violating policy) or hand-roll an ad-hoc
  validation, both of which lose the contract the skill is supposed to
  guarantee.
- The failure mode is silent — no clear "no pre-pr script in this repo, please
  bootstrap or run X" message.

## Current Workaround

In sandbox / bare repos, run an explicit subset of the validation commands the
host project would normally chain (e.g. `cargo test`, `markdownlint-audit.sh
--strict`, project-specific lints) and record the skipped pre-PR gate in the
PR / MR body or the relevant `discussion-source` Findings table so reviewers
know the gate was substituted.

## Promotion Criteria

Promote when **any one** of the following lands:

- (a) `meta/pre-pr` provides a documented default fallback (e.g. run the
  repo's `Cargo.toml` / `package.json` test target, or a minimal lint set)
  when `.agents/scripts/pre-pr.sh` is absent;
- (b) the skill emits a structured, actionable error ("no
  `.agents/scripts/pre-pr.sh` in repo X — bootstrap with Y or skip with Z")
  instead of failing silently;
- (c) the runtime-kit ships a `pre-pr` CLI on PATH that can run a default
  set of checks even in bare repos.

Closing this entry requires linking the upstream PR / commit that implements
(a), (b), or (c).

## Next Action

None. Resolved by graysurf/agent-runtime-kit#118: `meta/pre-pr` now gives a clear stop message and `setup-project` adoption path when the project-local script is missing.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/pull/118`

## Archive

- Archived: 2026-05-30
- Reason: Resolved by actionable missing-script guidance in the pre-pr skill (agent-runtime-kit#118).
- Durable link: `https://github.com/graysurf/agent-runtime-kit/pull/118`
