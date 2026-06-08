# Evidence: forge-cli GitLab MR delivery guard fixed

Date: 2026-06-08

During sympoies/nils-cli issue #797 delivery, PR #798 implemented the retained
`forge-cli` GitLab MR delivery fix:

- Numeric GitLab MR checks and wait-checks use structured GitLab API pipeline
  job data when project context is available.
- GitLab MR merge uses the GitLab merge API after existing draft, base branch,
  method, clean-state, and required-check gates.
- The `glab_version_unsupported` path is narrowed to the branch-only text
  parser fallback instead of blocking API-backed numeric MR delivery.

Durable links:

- Tracking issue: https://github.com/sympoies/nils-cli/issues/797
- Merged PR: https://github.com/sympoies/nils-cli/pull/798
- Merge SHA: 4c3ad686393f2787c7b9734669e93e4c819a6f9d

Validation evidence:

- `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` passed before
  PR delivery.
- Closed issue audit found source, plan, state, session, validation, review,
  and closeout visible and lint-clean.

Runtime evidence pointer:

- `$HOME/.local/state/agent-runtime-kit/out/projects/sympoies__nils-cli/20260608-173644-skill-usage/skill-usage.record.json`
