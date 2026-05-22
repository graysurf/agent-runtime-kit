# Extraction Backlog

This file records Plan 05 migration findings where a skill needs nils-cli behavior that does not yet exist as a released binary, subcommand, flag, or stable machine-readable output.

## Current Status

- Sprint 1 through Sprint 4 verification on 2026-05-22 found no missing nils-cli binary surfaces.
- All selected-scope binaries reported `0.16.0`: `agent-docs`, `agent-out`, `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, `semantic-commit`, `image-processing`, `screen-record`, `browser-session`, `canary-check`, `web-evidence`, `test-first-evidence`, `review-evidence`, `skill-usage`, `docs-impact`, and `model-cross-check`.
- Plan 06 Task 2.3 evidence probes on 2026-05-22 exercised the released evidence CLIs with temp artifacts and found no additional missing nils-cli surfaces.
- Sprint 5 verification on 2026-05-22 found no missing `forge-cli` PR/MR create or close surfaces; `forge-cli --version` reported `0.16.0`.

## Entries

| ID | Status | Skill | Missing surface | Evidence | Disposition |
| --- | --- | --- | --- | --- | --- |
| none | n/a | n/a | n/a | Sprint 1-5 CLI version/help and runtime-smoke dry-run checks passed for all selected binaries. | No extraction follow-up needed for the selected scope. |
