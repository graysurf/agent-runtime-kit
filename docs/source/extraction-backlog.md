# Extraction Backlog

This file records migration findings where a skill needs nils-cli behavior that
does not yet exist as a released binary, subcommand, flag, or stable
machine-readable output.

## Current Status

- Sprint 1 through Sprint 4 verification on 2026-05-22 found no missing
  nils-cli binary surfaces.
- All selected-scope binaries reported `0.16.0`: `agent-docs`, `agent-out`,
  `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, `semantic-commit`,
  `image-processing`, `screen-record`, `browser-session`, `canary-check`,
  `web-evidence`, `test-first-evidence`, `review-evidence`, `skill-usage`,
  `docs-impact`, and `model-cross-check`.
- Plan 06 Task 2.3 evidence probes on 2026-05-22 exercised the released
  evidence CLIs with temp artifacts and found no additional missing nils-cli
  surfaces.
- Sprint 5 verification on 2026-05-22 found no missing `forge-cli` PR/MR
  create or close surfaces in dry-run smoke; `forge-cli --version` reported
  `0.16.0`.
- Sprint 5 live PR delivery on 2026-05-22 found a GitHub checks compatibility
  gap in `forge-cli 0.16.0` with `gh 2.92.0`: `forge-cli pr checks` and
  `forge-cli pr wait-checks` requested an unsupported `conclusion` JSON field.
- The upstream field-set gap was fixed in `sympoies/nils-cli` PR #440 and
  released as `nils-cli` `0.17.0`; live Sprint 6 smoke then exposed a
  pending-check stdout handling bug, fixed in `nils-cli` `0.17.1`. Local
  `forge-cli --version` reported `forge-cli 0.17.1` on 2026-05-22.

## Entries

### P5-S5-G1

- Status: closed
- Skills: `pr.close-github-pr`, `pr.deliver-github-pr`
- Missing surface: `forge-cli pr checks` / `forge-cli pr wait-checks` needed a
  GitHub backend compatible with `gh 2.92.0` check JSON fields and
  pending-check nonzero stdout.
- Evidence: original failure was `forge-cli pr wait-checks ... --format json`
  returning `Unknown JSON field: "conclusion"`. Live scratch smoke later showed
  `gh pr checks` can return machine-readable pending-check stdout with a
  non-zero status. Fix evidence: `sympoies/nils-cli` issue #439 closed, PR #440
  merged, `nils-cli` `v0.17.1` released, and local `forge-cli --version`
  reported `forge-cli 0.17.1`.
- Disposition: closed by upstream `forge-cli >=0.17.1`; PR-domain manifest
  floors now require the fixed release.

### P6-DISPATCH-SESSION-GATE

- Status: open
- Skills: `dispatch.deliver-plan-tracking-issue`,
  `dispatch.plan-tracking-issue-closeout`, `dispatch.dispatch-plan-closeout`,
  `pr.deliver-github-pr`, and `pr.deliver-gitlab-mr`
- Missing surface: `plan-issue record close` should block tracking/dispatch
  closeout when no latest `role=session` lifecycle comment exists, reporting
  stable blocked code `session-missing`. A future pre-merge readiness surface
  should also report missing session without requiring the linked PR/MR to
  already be merged.
- Evidence: runtime-kit issue #120 reproduced the gap from issue #117: final
  state, validation, review, and closeout existed, but the dashboard still
  showed `Latest session: pending`. Local nils-cli branch
  `fix/plan-issue-session-closeout` adds `session-missing` enforcement and a
  deterministic missing-session fixture.
- Disposition: keep runtime-kit skill guidance and smoke coverage explicit now,
  but do not raise `plan-issue` semver floors until the nils-cli session gate
  is released.
