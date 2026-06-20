# Execution State: Codex plugin/marketplace adoption

## Execution State

- Source document: docs/plans/2026-06-20-codex-plugin-marketplace-adoption/2026-06-20-codex-plugin-marketplace-adoption-plan.md
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/435>
- Current sprint: Sprint 1 (not started)
- Status: not-started
- Branch: chore/codex-plugin-marketplace-adoption
- Last updated: 2026-06-20

## Task Ledger

| ID | Title | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | Confirm and record the Resolved Decision #10 reversal | pending | — | decision gate; blocks the capability flip |
| 1.2 | Align the Codex plugin.json render to the current loader schema | pending | — | may be coupled nils-cli render |
| 1.3 | Add core/docs/schemas/codex-plugin.schema.json | pending | — | currently referenced-but-missing |
| 2.1 | Render a Codex marketplace.json | pending | — | path choice: .agents/plugins vs legacy .claude-plugin |
| 2.2 | Add a Codex activation branch to sync-runtime-surfaces.sh | pending | — | mirror the Claude block |
| 2.3 | Wire the Codex marketplace into the link-map / install plan | pending | — | analogous to claude-kit.marketplace |
| 3.1 | Flip the Codex capability flags | pending | — | marketplace_concept + loaded_at_runtime; remove PR #434 NOTEs |
| 3.2 | Promote matrix + harness-shape from pending to shipped | pending | — | re-render matrix + golden |
| 3.3 | Add acceptance coverage for the Codex plugin/marketplace surface | pending | — | sandbox + runtime-smoke + live prompt-input |

## Validation Log

- (none yet)

## Session Notes

- 2026-06-20: bundle authored from the PR #434 follow-up; spike confirmed codex-cli 0.141.0 has the full plugin/marketplace surface. Awaiting Task 1.1 decision before any capability flip.
