# Skill Lifecycle Management Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: implementation complete; local validation/review passed; PR merge pending
- Target scope: Sprint 1-4 skill lifecycle management surface
- Execution window: Sprint 1-4
- Current task: merge PR #85 and close tracking issue #84
- Next task: post final state/closeout after PR merge
- Last updated: 2026-05-24
- Branch/commit/PR: feat/skill-lifecycle-management / b564ed9 / PR #85
- Source document: docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/84
- Source snapshot: https://github.com/graysurf/agent-runtime-kit/issues/84#issuecomment-4527937190
- Plan snapshot: https://github.com/graysurf/agent-runtime-kit/issues/84#issuecomment-4527937281
- Initial state snapshot: https://github.com/graysurf/agent-runtime-kit/issues/84#issuecomment-4527937384
- Delivery PR: https://github.com/graysurf/agent-runtime-kit/pull/85
- Session snapshot: https://github.com/graysurf/agent-runtime-kit/issues/84#issuecomment-4528027511
- Validation snapshot: https://github.com/graysurf/agent-runtime-kit/issues/84#issuecomment-4528027585
- Review snapshot: https://github.com/graysurf/agent-runtime-kit/issues/84#issuecomment-4528027621
- Predecessor issue: none

## Validation Plan

- `plan-tooling validate --file docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md --format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `agent-runtime audit-drift`
- `agent-runtime doctor --class skill-surface --product codex`
- `agent-runtime doctor --class skill-surface --product claude`
- `bash scripts/ci/sandbox-install-rehearsal.sh`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash tests/hooks/run.sh`
- `bash scripts/ci/all.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Add skill lifecycle governance audit | `bash scripts/ci/skill-governance-audit.sh` passed | Governance is a repo/CI tool, not a user-facing skill. |
| 1.2 | done | Add governance validation coverage | `bash scripts/ci/skill-governance-audit.sh --fixture create`; `--fixture remove`; `bash scripts/ci/all.sh` passed | Source/manifest/plugin/Codex link-map/reminder/acceptance/sandbox consistency checks. |
| 2.1 | done | Add `create-skill` workflow surface | render/golden/sandbox/runtime-smoke passed | Runtime-kit native source, manifest, plugin, product, golden, sandbox, and smoke shape. |
| 2.2 | done | Prove `create-skill` with a sample low-risk skill | create fixture accepted by governance audit | Fixture low-risk prose skill proves complete source/manifest/plugin/matrix/sandbox delta. |
| 3.1 | done | Add `remove-skill` workflow surface | render/golden/sandbox/runtime-smoke passed | Dry-run-first active-reference cleanup; keep `docs/plans/**` history by default. |
| 3.2 | done | Prove `remove-skill` against a fixture | remove fixture accepted by governance audit | Dry-run classes cover active delta and retained historical docs. |
| 4.1 | done | Update stable docs for lifecycle policy | `DEVELOPMENT.md`, `SUPPORT_MATRIX.md`, and `docs/source/inventory-target-architecture.md` updated | Durable maintainer-facing policy promoted out of tracker. |
| 4.2 | done | Resolve nils-cli extraction boundary | `docs/source/nils-cli-surface.md` rolled to v0.18.0; no new extraction needed | Stable mutation/reference graph remains deferred to a future nils-cli primitive if needed. |

## Session Log

- 2026-05-24: Created initial plan bundle from the skill lifecycle management
  discussion source. Scoped the tracker to governance, create, remove, and
  extraction-boundary decisions; deferred `create-project-skill`.
- 2026-05-24: Opened tracking issue #84 with `plan-issue` v0.18.0. Dry-run
  and live provider audit confirmed source, plan, and state comments use hidden
  payload carriers without visible payload fences, and the state comment keeps
  the execution-state Markdown.
- 2026-05-24: Adjusted design after review: `skill-governance` is a repo/CI
  validation tool called by lifecycle skills and `scripts/ci/all.sh`, not a
  user-facing skill.
- 2026-05-24: Implemented `meta.create-skill` and `meta.remove-skill`; added
  `scripts/ci/skill-governance-audit.sh`; wired governance into full CI;
  refreshed Codex/Claude render golden output, Codex local skill link-map,
  sandbox expected lists, runtime-smoke matrix/cases, and stable docs.
- 2026-05-24: Verified nils-cli v0.18.0 live (`agent-runtime`,
  `plan-issue`, and `plan-tooling` all report 0.18.0) and refreshed
  `docs/source/nils-cli-surface.md`. The v0.17.7 payload-fence leak entry is
  promoted and archived under
  `core/policies/heuristic-system/error-inbox/archive/2026/plan-issue-v0-17-7-payload-fence-leak/`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md --format text --explain` | passed | Bundle structural validation passed. | local output |
| `plan-issue record open --dry-run --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/skill-lifecycle-management` | passed | Preview source/plan/state comments had `visible_fence=false` and `hidden_payload=true`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-171249-skill-lifecycle-management-tracker/record-open-dry-run.json` |
| `plan-issue record open --format json --repo graysurf/agent-runtime-kit --bundle docs/plans/skill-lifecycle-management` | passed | Created tracking issue #84 with source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-171249-skill-lifecycle-management-tracker/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file .../issue-84-body.md --comments-json .../issue-84.json --format json` | passed | GitHub read-back audit returned `missing_required:[]`, `unsupported_markers:[]`, `recognized_count:3`. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260524-171249-skill-lifecycle-management-tracker/issue-84-audit.json` |
| `bash scripts/ci/skill-governance-audit.sh` | passed | Repo governance audit returned `skills=51 plugins=10 lifecycle=2`. | local output |
| `bash scripts/ci/skill-governance-audit.sh --fixture create` | passed | Create fixture completeness accepted for `fixture.sample-prose`. | local output |
| `bash scripts/ci/skill-governance-audit.sh --fixture remove` | passed | Remove fixture dry-run classes accepted with retained history. | local output |
| `agent-runtime render --product codex` | passed | Codex render produced 51 skills. | local output |
| `agent-runtime render --product claude` | passed | Claude render produced 51 skills. | local output |
| `agent-runtime render --product codex --update-golden` | passed | Codex golden snapshots refreshed. | local output |
| `agent-runtime render --product claude --update-golden` | passed | Claude golden snapshots refreshed. | local output |
| `agent-runtime audit-drift` | passed | Rendered outputs and manifests stayed aligned; only documented plugin manifest differences reported. | `bash scripts/ci/all.sh` position 6 |
| `agent-runtime doctor --class skill-surface --product codex` | passed | Codex skill-surface shape passed: `checks=72 ok=72 warn=0 block=0`. | local output |
| `agent-runtime doctor --class skill-surface --product claude` | passed | Claude skill-surface shape passed: `checks=24 ok=24 warn=0 block=0`. | local output |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | passed | Sandbox expected skill pins matched installed Codex/Claude surfaces. | local output |
| `bash tests/runtime-smoke/run.sh --mode install` | passed | Runtime-smoke install mode returned `install.codex` and `install.claude` pass with `skill_count=51`. | local output |
| `bash tests/runtime-smoke/run.sh --mode product --format json` | passed | Product mode install/probe summary matched the updated 51-skill expectation; prompt execution remained manual-only. | local output |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | passed | Meta domain runtime smoke returned `total=14 pass=14`. | local output |
| `bash tests/projects/project-local-smoke/run.sh` | passed | Project-local smoke remained compatible. | `bash scripts/ci/all.sh` position 10 |
| `bash tests/hooks/run.sh` | passed | Hook and reminder metadata checks passed 9 tests. | `bash scripts/ci/all.sh` position 11 |
| `bash scripts/ci/all.sh` | passed | Full local gate ran positions 1-11 successfully. | local output |

## Notes

- The initial tracker uses the existing `meta` domain by default. A new plugin
  domain requires explicit approval because it changes both product surfaces.
- Historical references under `docs/plans/**` are retained by removal workflows
  unless the caller explicitly asks for cleanup.
- Stable mutation, YAML parsing, reference graphs, or JSON contracts belong in
  released `nils-cli`; repo-local scripts should remain Bash glue.
