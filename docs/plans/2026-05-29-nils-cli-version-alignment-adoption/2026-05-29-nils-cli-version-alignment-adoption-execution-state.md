# nils-cli Version Alignment Adoption Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: implementation complete and delivered as PR #162 (CI green);
  tracking issue opened retrospectively; closeout pending.
- Target scope: Sprint 1 (adopt the version-alignment doctor-class pin
  gate) and Sprint 2 (add the `meta:nils-cli-bump` skill), both landed in
  one `graysurf/agent-runtime-kit` PR.
- Execution window: single session 2026-05-29 (serial; Sprint 2 builds on
  the Sprint 1 pin manifest).
- Current task: closeout (await merge of PR #162, then `record close`).
- Next task: merge PR #162 and run `plan-tracking-issue-closeout`.
- Last updated: 2026-05-29
- Branch/commit/PR: `feat/nils-cli-version-alignment-adoption`; commit
  `0de4a94`; PR <https://github.com/graysurf/agent-runtime-kit/pull/162>.
- Source document: docs/plans/2026-05-29-nils-cli-version-alignment-adoption/2026-05-29-nils-cli-version-alignment-adoption-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: tbd (to be opened by `create-plan-tracking-issue`
  against `graysurf/agent-runtime-kit`)
- Source snapshot: pending — posted by `create-plan-tracking-issue` at
  issue open
- Plan snapshot: pending — posted by `create-plan-tracking-issue` at issue
  open
- Initial state snapshot: pending — posted by `create-plan-tracking-issue`
  at issue open

## Validation Plan

- `plan-tooling validate --file docs/plans/2026-05-29-nils-cli-version-alignment-adoption/2026-05-29-nils-cli-version-alignment-adoption-plan.md --format text --explain` green.
- `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml --format text` reports block=0 on the v0.28.0 host; a drifted pin blocks (exit 2).
- `bash scripts/ci/skill-governance-audit.sh` reports repo OK skills=64.
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` reaches 24/24 including `meta.nils-cli-bump`.
- `bash scripts/ci/all.sh` positions 1-13 OK locally and the PR's
  `scripts/ci/all.sh` provider check is green.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add the machine-readable pin manifest | graysurf/agent-runtime-kit#162 (commit 0de4a94) | `docs/source/nils-cli-pin.yaml`; doctor class returns block=0 on v0.28.0 host. |
| 1.2 | done | Collapse Position 2 to the doctor class | graysurf/agent-runtime-kit#162 (commit 0de4a94) | `scripts/ci/all.sh` +29/-87; exact-equality drift semantics; shellcheck + shfmt clean. |
| 1.3 | done | Refresh surface snapshot and DEVELOPMENT.md | graysurf/agent-runtime-kit#162 (commit 0de4a94) | snapshot v0.25.8 -> v0.28.0; new nils-build-info / nils-markdown rows; rumdl + audit-drift clean. |
| 2.1 | done | Author the skill body and wire manifests | graysurf/agent-runtime-kit#162 (commit 0de4a94) | `core/skills/meta/nils-cli-bump/SKILL.md.tera`; skills.yaml + plugins.yaml; body-shape audit OK. |
| 2.2 | done | Render surfaces and acceptance coverage | graysurf/agent-runtime-kit#162 (commit 0de4a94) | both goldens, both sandbox lists, codex link-map, acceptance-matrix row + meta probe; smoke 24/24. |
| 2.3 | done | Full CI gate and PR delivery | graysurf/agent-runtime-kit#162; ci/all.sh 1-13 OK; provider CI pass (53s) | semantic-commit signed; forge-cli pr create draft. |

## Session Log

- 2026-05-29: Closed upstream tracker sympoies/nils-cli#462 after
  confirming the `version-alignment` doctor class shipped in
  sympoies/nils-cli#636 / v0.28.0. Implemented both downstream pieces in
  one worktree off `origin/main`: adopted the doctor class as the
  Position 2 pin gate (Sprint 1) and added the `meta:nils-cli-bump` skill
  (Sprint 2). Verified the full gate locally (positions 1-13 OK),
  committed signed via `semantic-commit`, opened draft PR #162, and
  confirmed the provider `scripts/ci/all.sh` check is green. This plan
  bundle was authored retrospectively to give the delivered work a durable
  tracking record before closeout.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file <plan>` | pass | No issues after scaffold + fill. | n/a |
| `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml` | pass | 6 checks, block=0 on v0.28.0 host. | n/a |
| `bash scripts/ci/skill-governance-audit.sh` | pass | repo OK skills=64 plugins=10 lifecycle=4. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pass | 24/24 incl. `meta.nils-cli-bump`. | n/a |
| `bash scripts/ci/all.sh` | pass | positions 1-13 OK. | n/a |
| `gh pr checks 162` | pass | `scripts/ci/all.sh` pass (53s). | <https://github.com/graysurf/agent-runtime-kit/pull/162> |

## Notes

- The exact-equality gate is a deliberate strictening from the prior
  floor gate (which tolerated a newer host). It reddens CI on any future
  host advance until a pin bump lands — which is the drift it is meant to
  catch and exactly what the `meta:nils-cli-bump` skill remediates.
- The pin manifest's `required_clis[]` floors track the documented
  surface-introduction versions in `docs/source/nils-cli-surface.md`, not
  the current pin, so they remain meaningful under a partial release.
- SUPPORT_MATRIX.md was intentionally untouched: it is generated from
  `manifests/surfaces.yaml` and tracks product surfaces, not CI gates.
- This bundle and tracking issue live in `graysurf/agent-runtime-kit`
  alongside the delivery PR.
