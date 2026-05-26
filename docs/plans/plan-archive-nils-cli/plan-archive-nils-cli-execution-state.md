# Plan Archive — nils-cli Capabilities Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: pending; tracker about to open
- Target scope: Sprints 1–5 of the plan-archive nils-cli plan bundle
- Execution window: Sprints 1, 2, 3, 4, 5
- Current task: 1.1
- Next task: 1.1 hosts.yaml schema and validator
- Last updated: 2026-05-27
- Branch/commit/PR: pending; tracker to be opened in sympoies/nils-cli
- Source document: docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Validation Plan

- `plan-tooling validate --file docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-plan.md --format text --explain`
- `plan-archive validate-hosts --input fixtures/hosts/personal-only.yaml`
- `plan-archive validate-hosts --input fixtures/hosts/employer-mixed.yaml`
- `plan-archive validate-local --input fixtures/local/defaults.yaml`
- `plan-archive validate-local --input fixtures/local/overrides.yaml`
- `plan-archive validate-local --input /nonexistent/path`
- `plan-archive validate-metadata --input fixtures/metadata/github-pr.yaml`
- `plan-archive validate-metadata --input fixtures/metadata/gitlab-mr.yaml`
- `plan-archive validate-metadata --input fixtures/metadata/orphan-plan.yaml`
- Fixture-driven unit and end-to-end runs for the scrub library, migrate, refresh, and query subcommands as listed in the plan file Sprint 2–5 task Validation sections.
- `sympoies/nils-cli` release pipeline checks for the new `plan-archive` binary.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | hosts.yaml schema and validator | — | — |
| 1.2 | pending | local config schema and validator | — | — |
| 1.3 | pending | metadata.yaml schema and validator | — | — |
| 2.1 | pending | secret scrub pattern set and redaction engine | — | — |
| 2.2 | pending | scrub log emitter | — | — |
| 3.1 | pending | `plan-archive migrate` dry-run mode | — | — |
| 3.2 | pending | `plan-archive migrate` apply mode (transactional) | — | — |
| 4.1 | pending | `plan-archive refresh` forge-cli payload fetch | — | — |
| 4.2 | pending | `plan-archive refresh` snapshot write with scrub | — | — |
| 4.3 | pending | `plan-archive refresh` batch modes | — | — |
| 5.1 | pending | `plan-archive query` single-ref cache read | — | — |
| 5.2 | pending | `plan-archive query` cross-repo and cross-host aggregate | — | — |
| 5.3 | pending | `plan-archive query` archive plan link traversal | — | — |

## Session Log

- 2026-05-27: Created plan bundle (sibling discussion source, plan, initial execution state) from the master design at `docs/plans/plan-archive-system/plan-archive-system-discussion-source.md`. Tracker issue not yet opened.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/plan-archive-nils-cli/plan-archive-nils-cli-plan.md --format text --explain` | pending | Will run as part of the tracker open preflight. | n/a |

## Notes

- The deterministic CLI work itself lands in `sympoies/nils-cli`. This bundle remains in `agent-runtime-kit` to keep the design and sub-plan tree co-located, following the precedent of `docs/plans/nils-cli-version-alignment/`.
- Plan 3 (`plan-archive-runtime-kit`) depends on the tag this plan releases. Plan 2 (archive repository bootstrap) is a one-shot prerequisite recorded in the master discussion source and is not tracked here.
