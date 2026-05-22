# Extraction Backlog

This file records Plan 05 migration findings where a skill needs nils-cli behavior that does not yet exist as a released binary, subcommand, flag, or stable machine-readable output.

## Current Status

- Sprint 1 through Sprint 4 verification on 2026-05-22 found no missing nils-cli binary surfaces.
- All selected-scope binaries reported `0.16.0`: `agent-docs`, `agent-out`, `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, `semantic-commit`, `image-processing`, `screen-record`, `browser-session`, `canary-check`, `web-evidence`, `test-first-evidence`, `review-evidence`, `skill-usage`, `docs-impact`, and `model-cross-check`.
- Plan 06 Task 2.3 evidence probes on 2026-05-22 exercised the released evidence CLIs with temp artifacts and found no additional missing nils-cli surfaces.
- Sprint 5 verification on 2026-05-22 found no missing `forge-cli` PR/MR
  create or close surfaces in dry-run smoke; `forge-cli --version` reported
  `0.16.0`.
- Sprint 5 live PR delivery on 2026-05-22 found a GitHub checks compatibility
  gap in `forge-cli 0.16.0` with `gh 2.92.0`: `forge-cli pr checks` and
  `forge-cli pr wait-checks` requested an unsupported `conclusion` JSON field.

## Entries

| ID | Status | Skill | Missing surface | Evidence | Disposition |
| --- | --- | --- | --- | --- | --- |
| P5-S5-G1 | open | `pr.close-github-pr`, `pr.deliver-github-pr` | `forge-cli pr checks` / `forge-cli pr wait-checks` need a GitHub backend compatible with `gh 2.92.0` check JSON fields. | `forge-cli pr wait-checks 37 --provider github --repo graysurf/agent-runtime-kit --format json` failed with `Unknown JSON field: "conclusion"`; `forge-cli pr deliver --dry-run` also renders the unsupported field in its `wait_checks` plan step; `gh` reported available fields `bucket`, `completedAt`, `description`, `event`, `link`, `name`, `startedAt`, `state`, and `workflow`. | Fix in nils-cli/`forge-cli`; until released, live PR operations may use provider-native `gh pr checks` as an operator fallback while runtime skill bodies remain delegated to `forge-cli`. |
