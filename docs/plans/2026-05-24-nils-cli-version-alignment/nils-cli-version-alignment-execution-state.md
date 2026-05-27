# nils-cli Version Alignment Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: complete; closeout pending
- Target scope: Sprint 1 add version-alignment CI gate
- Execution window: Sprint 1
- Current task: complete
- Next task: archive `plan-issue-v2-marker-collapse-drift` inbox case; open tracker for retrospective record and close
- Last updated: 2026-05-24
- Branch/commit/PR: feat/version-alignment-gate; plan commit b179aa9; v2 migration PR #76 (commit 8581f12); CI gate PR #78 (commit 5ebde19)
- Source document: docs/plans/2026-05-24-nils-cli-version-alignment/nils-cli-version-alignment-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending
- Plan snapshot: pending
- Initial state snapshot: pending

## Validation Plan

- `plan-tooling validate --file docs/plans/2026-05-24-nils-cli-version-alignment/nils-cli-version-alignment-plan.md --format text --explain`
- `bash scripts/ci/all.sh` on an aligned host (expect pass on all 11 positions including the new Position 2).
- Deliberate-mismatch experiment: perturb the pin in `docs/source/nils-cli-surface.md` in a worktree, rerun `bash scripts/ci/all.sh`, expect non-zero exit on Position 2 with both versions visible and the remediation banner present, then restore the file.
- `rumdl check DEVELOPMENT.md SUPPORT_MATRIX.md` after the docs updates in Task 1.2.
- `agent-runtime audit-drift` after the docs updates (expect clean).

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add version-alignment gate to `scripts/ci/all.sh` | PR #78 commit 5ebde19 | Landed as new Position 2 between `plan-tooling validate` and the render positions. Renumbered Positions 2-10 to 3-11 and bumped the final `positions 1-N OK` banner. |
| 1.2 | done | Document new gate in `DEVELOPMENT.md` and `SUPPORT_MATRIX.md` | PR #78 commit 5ebde19 | Gate list bumped to positions 1-11; `SUPPORT_MATRIX.md` refresh checklist cross-references the new gate so a stale snapshot pin is now loud. |

## Session Log

- 2026-05-24: Created plan bundle (discussion source, plan, initial execution state) from the converged Claude session on automating the post-bump alignment check. Scoped this tracker to Step 1 only; Steps 2 and 3 remain documented in the discussion source as future trackers.
- 2026-05-24: Discovered live v0.17.6 → v0.17.7 silent drift while invoking `dispatch:create-plan-tracking-issue` (the very skill this work was meant to protect). Filed inbox case `plan-issue-v2-marker-collapse-drift`. Pushed the plan bundle with `--no-verify` per explicit user authorization while pre-push was failing.
- 2026-05-24: Landed PR #76 `fix(plan-issue): migrate to v2 markers for nils-cli v0.17.7` — removed retired `--marker-family` flag from 13 SKILL bodies + references, rewrote runtime-smoke fixtures to v2 markers, bumped record envelope greps from v1 to v2, refreshed 28 golden snapshots, bumped surface pin from v0.17.6 to v0.17.7. All 44 deterministic runtime-smoke probes returned to passing.
- 2026-05-24: Landed PR #78 `feat(ci): add nils-cli surface pin alignment gate as Position 2` — the Step 1 deliverable from this plan. CI now has 11 positions and fails closed with a remediation banner when host `agent-runtime --version` does not match `docs/source/nils-cli-surface.md`. Verified both pass and fail paths with a deliberate-mismatch worktree experiment.
- 2026-05-24: Filed upstream tracker for Step 2 at sympoies/nils-cli#462 (`feat(doctor): version-alignment class for surface-pin gates`). Body records the v0.17.7 silent-drift incident, the Step 1 shell prototype, a strawman YAML/JSON pin manifest contract, and the Step 3 `meta:nils-cli-bump` consumer plan as context. No work to do here until that issue ships a doctor class release.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-24-nils-cli-version-alignment/nils-cli-version-alignment-plan.md --format text --explain` | pass | Plan bundle validates after adding plan and execution-state files. | n/a |
| `bash scripts/ci/all.sh` (PR #78 head) | pass | All 11 positions green; Position 2 reports `nils-cli surface pin: v0.17.7   host: v0.17.7   aligned`. | n/a |
| `bash scripts/ci/all.sh` with perturbed pin (`v0.17.7` → `v0.17.99`) | pass | Position 2 exits non-zero with remediation banner naming both versions and the parsed line. Restored after experiment. | n/a |
| `rumdl check DEVELOPMENT.md SUPPORT_MATRIX.md` | pass | Only pre-existing MD013 line-length warnings on lines this PR did not author. | n/a |
| `agent-runtime audit-drift` | pass | Clean (20 findings, all `intentional-difference/info`). | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | 44/44 probes pass on host nils-cli v0.17.7 after the PR #76 v2 migration. | n/a |
| `shellcheck scripts/ci/all.sh` + `shfmt` (pre-commit hook) | pass | SC2016 single-quote info suppressed with documented `disable=SC2016` directives (literal backticks intended). | n/a |

## Notes

- The Position 2 placement question raised in the plan's `[Q1]` resolved to the default: between Position 1 (`plan-tooling validate`) and the render positions. Putting the gate early ensures downstream gates do not exercise an unaligned binary.
- The mismatch direction observed in this work was host-newer-than-pin (v0.17.7 host vs v0.17.6 snapshot), inverted from the discussion source `[I1]` prediction (host-older-than-pin). The same gate covers both directions.
- Steps 2 (upstream `agent-runtime doctor --class version-alignment`) and Step 3 (`meta:nils-cli-bump` skill) remain out of scope. Open separate trackers when their preconditions land — Step 2 after this gate has exercised against at least one real bump, Step 3 after the upstream doctor class is released.
- Inbox case `plan-issue-v2-marker-collapse-drift` met 3 of 4 Promotion Criteria via PR #76; the fourth (this CI gate) lands with PR #78. Archive the case in the same PR sweep that opens the tracking issue.
