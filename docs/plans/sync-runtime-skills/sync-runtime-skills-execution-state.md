# sync-runtime-skills Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: pending implementation
- Target scope: Sprint 1 ship `scripts/sync-runtime-skills.sh` and doc pointers
- Execution window: Sprint 1
- Current task: Task 1.1 — author the script
- Next task: Task 1.2 — cross-reference in DEVELOPMENT.md and setup.sh help
- Last updated: 2026-05-24
- Branch/commit/PR: feat/sync-runtime-skills (plan bundle); implementation branch pending
- Source document: docs/plans/sync-runtime-skills/sync-runtime-skills-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending
- Predecessor issue: https://github.com/graysurf/agent-runtime-kit/issues/82

## Validation Plan

- `plan-tooling validate --file docs/plans/sync-runtime-skills/sync-runtime-skills-plan.md --format text --explain`
- `bash scripts/sync-runtime-skills.sh` on an aligned host (expect dry-run pass, no writes).
- `bash scripts/sync-runtime-skills.sh --apply` on the same host (expect both `install --apply` and both `doctor --class skill-surface` to succeed).
- Deliberate-failure experiment: perturb a rendered file under `build/claude/`, run `bash scripts/sync-runtime-skills.sh --apply --product claude`, expect non-zero exit; restore the file.
- Pull-refusal experiment: leave an unstaged change in the working tree to force `git pull --ff-only` to abort; expect the script to stop before render with the git error visible.
- `shellcheck scripts/sync-runtime-skills.sh` and `shfmt -d` (expect clean).
- `rumdl check DEVELOPMENT.md` after the Task 1.2 docs edit.
- `agent-runtime audit-drift` (expect clean).
- `bash scripts/ci/all.sh` on the implementation branch (expect green).

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Add `scripts/sync-runtime-skills.sh` | pending | Wraps pull → render → install → doctor → optional `codex debug prompt-input` for both products. Dry-run default; `--apply` writes. |
| 1.2 | pending | Cross-reference the new script in `DEVELOPMENT.md` and `scripts/setup.sh --help` | pending | One-line help-text pointer in setup.sh; short paragraph in DEVELOPMENT.md naming both scripts. |

## Session Log

- 2026-05-24: Created plan bundle (discussion source, plan, initial execution state) from GitHub issue #82's stated desired outcome. Scoped this tracker to the shell script + doc pointers; deferred the `meta:sync-runtime-skills` skill wrapper to a future tracker per source [D1].

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/sync-runtime-skills/sync-runtime-skills-plan.md --format text --explain` | pending | Bundle structural validation. | n/a |
| `bash scripts/sync-runtime-skills.sh` (dry-run) | pending | Default invocation prints planned actions for both products; no writes. | n/a |
| `bash scripts/sync-runtime-skills.sh --apply` | pending | End-to-end run on aligned host. | n/a |
| Deliberate-failure: perturb `build/claude/`, run `--apply --product claude` | pending | Post-install doctor fails; script exits non-zero with remediation line. | n/a |
| Pull-refusal experiment | pending | Script stops before render with git error visible. | n/a |
| `shellcheck scripts/sync-runtime-skills.sh` + `shfmt -d` | pending | Clean. | n/a |
| `rumdl check DEVELOPMENT.md` | pending | No new findings on the new paragraph. | n/a |
| `bash scripts/ci/all.sh` | pending | All positions green on the implementation branch. | n/a |

## Notes

- The predecessor GitHub issue (#82) is preserved in the lifecycle log so the
  rationale behind the tracker is traceable; the new tracking issue is the
  durable surface from this point forward, and #82 closes with a pointer to it.
- Sequencing reuses the same Sprint-1 shape as
  `docs/plans/nils-cli-version-alignment/nils-cli-version-alignment-plan.md`:
  ship a thin script first, document it, validate it under
  `scripts/ci/all.sh`, then revisit whether a skill wrapper buys anything.
- A future `meta:sync-runtime-skills` skill wrapper is intentionally out of
  scope until the script has been exercised against at least one real
  skill-add cycle.
