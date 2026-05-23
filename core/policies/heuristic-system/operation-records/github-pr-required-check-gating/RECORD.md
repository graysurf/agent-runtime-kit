# GitHub PR Required Check Gating Operation Record

## Status

- Date: 2026-05-18
- Status: implemented and validated
- System area: GitHub PR delivery workflows
- Migrated from: legacy agent-kit retained operation record
- Durable fix paths:
  - `skills/workflows/pr/github/_shared/lib/github-pr-checks.bash`
  - `skills/workflows/pr/github/deliver-github-pr/scripts/deliver-github-pr.sh`
  - `skills/workflows/pr/github/close-github-pr/scripts/close-github-pr.sh`

## Signal

A real `deliver-github-pr` run for `nils-cli` PR #370 completed successfully
only after manually working around the legacy agent-kit delivery scripts. The
scripts treated an optional skipped `coverage_badge` job as a hard failure even
though required checks were sufficient to merge.

## Evidence

Retained local evidence:

- `<workspace>/out/.../skill-usage.record.json`

Relevant evidence summary:

- `deliver-github-pr wait-checks --pr 370` returned failure while required
  checks were still converging and no required check had failed.
- `deliver-github-pr close --pr 370` rejected the PR after required checks had
  passed because the optional `coverage_badge` job was skipped.
- Manual `gh pr ready` and `gh pr merge` succeeded after required checks were
  verified.

## Diagnosis

The delivery scripts used one all-checks classifier for both required and
optional GitHub check runs. That made optional skipped jobs indistinguishable
from skipped required checks.

The same logic existed in both `deliver-github-pr` and `close-github-pr`, so a
partial fix in only one workflow would still leave delivery blocked.

## Promotion Decision

This was promoted as a Heuristic System operation case because it was:

- observed during a real high-impact workflow;
- reproducible with a local `gh` stub and focused tests;
- narrow enough to fix safely;
- valuable as proof that retained evidence can become tests, scripts, skill
  policy, and an operation record.

Not every promoted inbox entry needs an operation record. This one qualifies
because the retained signal affected a broad delivery workflow, produced
shared script behavior, and is useful as audit evidence for the Heuristic
System loop.

## Durable Fix

- Added focused regression tests for required checks passing while optional
  `coverage_badge` is skipped.
- Extended the `gh` test stub to simulate `gh pr checks --required`.
- Added live-message fallback coverage for `no required checks reported`, which
  GitHub emits when a branch has checks but no branch-protection-required
  checks.
- Moved GitHub PR check classification into a shared helper.
- Updated both PR delivery scripts to gate on required checks first and fall
  back to existing all-checks behavior when no required checks are configured.
- Updated GitHub PR workflow skill docs to state the required-vs-optional
  check policy.
- Added this operation record and root Heuristic System guidance for future
  retained-evidence promotion.

## Validation

Current validation:

- Focused GitHub PR delivery and close tests: pass.
- Markdown/docs checks: pass.
- Stale skill scripts audit: pass.
- Entrypoint ownership check: pass.
- Full legacy agent-kit gate: pass, including 731 pytest tests.

The full gate ran in the normal shell after `agent-doc-init` test isolation was
fixed to clear ambient resolver variables before each test injects explicit
values.

## Retention

- Raw skill usage records remain in `out/` and are not committed as normal repo
  artifacts.
- The temporary execution source was removed after this operation record and
  regression tests retained the useful lesson.
- This operation record remains as durable proof that the Heuristic System loop
  operated on a real workflow failure.
