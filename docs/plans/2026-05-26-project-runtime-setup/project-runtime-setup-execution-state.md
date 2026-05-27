# Project Runtime Setup Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: complete
- Target scope: managed dispatcher surface cleanup plus `setup-project`
  workflow and adopted-repo `pre-pr` diagnostics.
- Execution window: Sprint 1-3
- Current task: none
- Next task: none
- Last updated: 2026-05-26
- Branch/commit/PR: branch `feat/project-runtime-setup`; implementation
  commit `c5c324e`; PR #118 merged as `b9032e5`
- Source document: docs/plans/2026-05-26-project-runtime-setup/project-runtime-setup-plan.md
- Discussion source:
  docs/plans/2026-05-26-project-runtime-setup/project-runtime-setup-discussion-source.md
- Plan document: docs/plans/2026-05-26-project-runtime-setup/project-runtime-setup-plan.md
- Execution state: docs/plans/2026-05-26-project-runtime-setup/project-runtime-setup-execution-state.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/117>
- Source snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536042374>
- Plan snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536042480>
- Initial state snapshot:
  <https://github.com/graysurf/agent-runtime-kit/issues/117#issuecomment-4536042572>

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Remove managed bench and demo skill sources | `manifests/skills.yaml`; `manifests/plugins.yaml`; removed `core/skills/meta/{bench,demo}/` | Active managed sources and manifest/plugin entries removed. |
| 1.2 | done | Refresh render output, goldens, and expected skill lists | `agent-runtime render --product codex --update-golden`; `agent-runtime render --product claude --update-golden`; `skill-governance-audit --update-counts` | Expected skill count is 59; sandbox lists exclude `bench` and `demo` and include `setup-project`. |
| 1.3 | done | Update dispatcher docs and smoke fixtures | `tests/runtime-smoke/cases/meta/run.sh`; `tests/projects/project-local-smoke/run.sh`; docs updates | Retained managed dispatcher set is bootstrap/deploy/pre-pr/release. |
| 2.1 | done | Define setup-project contract and adoption model | `core/skills/meta/setup-project/SKILL.md.tera` | Setup is dry-run-first, repo-local, and separate from host install. |
| 2.2 | done | Add setup-project helper and fixtures | `core/skills/meta/setup-project/scripts/setup-project.sh`; runtime/project smoke probes | Helper covers unadopted, partial, and apply-mode repos without overwrites. |
| 2.3 | done | Render setup-project across products | `tests/golden/{codex,claude}/plugins/meta/skills/setup-project/expected/` | Codex and Claude rendered surfaces include the new skill. |
| 3.1 | deferred | Add or consume adopted-repo doctor diagnostics | n/a | No nils-cli release is bundled in this PR; adopted-repo fail-closed diagnostics are covered by `setup-project` helper probes. |
| 3.2 | done | Update pre-pr missing-script guidance | `core/skills/meta/pre-pr/SKILL.md.tera` | Missing `pre-pr.sh` guidance points to `setup-project` and still forbids fallback validation. |
| 3.3 | done | Final validation and tracker closeout prep | `bash scripts/ci/all.sh`; PR #118 checks; delivery review outcome comment; `bash scripts/sync-runtime-skills.sh --apply`; `agent-runtime audit-drift` | PR #118 passed remote checks, review gate, merge, and post-merge runtime sync. |

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `plan-tooling validate` on this plan with `--format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --target support-matrix`
- `agent-runtime audit-drift`
- `bash scripts/ci/skill-governance-audit.sh`
- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash scripts/ci/all.sh`

## Session Log

- 2026-05-26: Created discussion source from user-approved direction: remove
  `bench`/`demo`, make `pre-pr` required for adopted repos, and add a
  setup-oriented project adoption workflow.
- 2026-05-26: Created initial plan and execution-state bundle for issue-backed
  tracking.
- 2026-05-26: Pushed commit `f2f4040`, opened tracking issue #117 with
  `plan-issue record open`, and read-back audited source, plan, and initial
  state comments.
- 2026-05-26: Removed managed `bench` and `demo`, added `setup-project`,
  refreshed rendered/golden/sandbox count surfaces, updated `pre-pr` guidance,
  and added setup-project adoption probes. `agent-runtime doctor
  --check-project` nils-cli blocking behavior was not changed in this PR.
- 2026-05-26: Committed implementation as `c5c324e`, cleared retired
  `bench`/`demo` live surfaces with audited `agent-runtime uninstall` cleanup
  followed by `bash scripts/sync-runtime-skills.sh --apply --no-pull`, then
  verified clean drift and full CI.
- 2026-05-26: Opened PR #118, fixed the fresh-checkout plan-location failure
  in `2e6af2d`, posted the delivery review outcome, promoted the PR to ready,
  and merged it as `b9032e5`.
- 2026-05-26: Fast-forwarded local `main` to the merge commit and reran
  `bash scripts/sync-runtime-skills.sh --apply`; Codex and Claude runtime
  surfaces synced from merged `main`, and drift audit remained clean.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | passed | Required startup docs present. | n/a |
| `agent-docs resolve --context project-dev --strict --format checklist` | passed | Project development docs and docs placement policy present. | n/a |
| `plan-tooling validate --file docs/plans/2026-05-26-project-runtime-setup/project-runtime-setup-plan.md --format json` | passed | Plan bundle validates with no errors. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/plan-tooling-validate.json` |
| `rumdl check docs/plans/2026-05-26-project-runtime-setup/*.md` | passed | Plan bundle markdown passes. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/rumdl-check.txt` |
| `awk '/[[:blank:]]$/ ...' docs/plans/2026-05-26-project-runtime-setup/*.md` | passed | No trailing whitespace found in the plan bundle. | n/a |
| `bash scripts/ci/all.sh` | passed | Pre-push hook ran positions 1-13 successfully while pushing `f2f4040`. | local pre-push output |
| `forge-cli label ensure --catalog manifests/forge-labels.yaml --repo graysurf/agent-runtime-kit --format json` | passed | Shared taxonomy labels were already present; no actions needed. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/label-ensure.json` |
| `plan-issue record open --dry-run --profile tracking --bundle docs/plans/2026-05-26-project-runtime-setup --format json` | passed | Preview generated source, plan, and state snapshots with selected labels. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/record-open-dry-run.json` |
| `plan-issue record open --profile tracking --bundle docs/plans/2026-05-26-project-runtime-setup --format json` | passed | Opened tracking issue #117 with source, plan, and initial state comments. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/record-open-live.json` |
| `plan-issue record audit --profile tracking --body-file "$ISSUE_BODY" --comments-json "$ISSUE_JSON" --format json` | passed | Read-back audit recognized source, plan, and state comments with no missing required markers. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/issue-117-audit.json` |
| `rg -n "## Execution State\|## Task Ledger\|<details>\|plan-issue-record-payload" issue-117-state-comment.md` | passed | Initial state comment contains visible execution state, visible task ledger, folded details, and hidden payload carrier. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-012651-project-runtime-setup/issue-117-state-comment.md` |
| `bash scripts/ci/skill-governance-audit.sh` | passed | Repo governance accepted 59 active skills, 10 plugins, and refreshed count targets. | local output |
| `bash -n core/skills/meta/setup-project/scripts/setup-project.sh tests/projects/project-local-smoke/run.sh tests/runtime-smoke/cases/meta/run.sh` | passed | Shell syntax passed for the new helper and smoke probes. | local output |
| `shfmt -i 2 -ci -d core/skills/meta/setup-project/scripts/setup-project.sh tests/projects/project-local-smoke/run.sh tests/runtime-smoke/cases/meta/run.sh` | passed | Shell formatting check passed. | local output |
| `shellcheck core/skills/meta/setup-project/scripts/setup-project.sh tests/projects/project-local-smoke/run.sh tests/runtime-smoke/cases/meta/run.sh` | passed | Shell lint passed. | local output |
| `agent-runtime render --product codex --update-golden` | passed | Rendered 59 Codex skills and refreshed goldens. | local output |
| `agent-runtime render --product claude --update-golden` | passed | Rendered 59 Claude skills and refreshed goldens. | local output |
| `agent-runtime render --target support-matrix` | passed | Rendered support matrix with 17 surfaces and 34 rows. | local output |
| `agent-runtime doctor --class skill-surface --product codex` | passed | Codex skill-surface doctor reported checks=80 ok=80 block=0. | local output |
| `agent-runtime doctor --class skill-surface --product claude` | passed | Claude skill-surface doctor reported checks=24 ok=24 block=0. | local output |
| `bash tests/runtime-smoke/run.sh --mode matrix` | passed | Acceptance matrix covered expected skill ids. | local output |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | passed | Meta deterministic smoke passed 18 cases, including `setup-project`. | local output |
| `bash tests/projects/project-local-smoke/run.sh` | passed | Retained dispatcher smoke and setup-project adoption probes passed. | local output |
| `bash tests/runtime-smoke/run.sh --mode install` | passed | Codex and Claude temp installs passed with skill_count=59. | local output |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | passed | Sandbox install rehearsal passed for Claude and Codex. | local output |
| `plan-tooling validate --file docs/plans/2026-05-26-project-runtime-setup/project-runtime-setup-plan.md --format json` | passed | Plan validates with no errors. | local output |
| `rumdl check core/skills/meta/setup-project/SKILL.md.tera ... docs/source/harness-shape-codex.md` | passed | Focused changed-doc markdown check passed. | local output |
| `bash scripts/sync-runtime-skills.sh --apply --no-pull` | passed | Reinstalled 59-skill Codex and Claude surfaces; doctor passed for both products; `codex debug prompt-input` verified `setup-project`. | local output |
| `agent-runtime audit-drift` | passed | Clean with 20 documented intentional-difference findings and no stale `bench`/`demo` extras. | local output |
| `bash scripts/ci/all.sh` | passed | Positions 1-13 passed after live runtime cleanup and sync. | local output |
| `forge-cli pr wait-checks 118 --provider github --repo graysurf/agent-runtime-kit --required-only false --timeout 30m --interval 20s --format json` | passed | Remote GitHub Actions run `26413811001` passed `scripts/ci/all.sh` after the plan-location fix. | provider output |
| delivery review gate for PR #118 | passed | Forced maintainability, red-team, security, and testing lenses found no unresolved concrete findings; outcome comment posted. | `$HOME/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260526-020241-project-runtime-setup-pr/delivery-review-outcome.md` |
| `forge-cli pr merge 118 --provider github --repo graysurf/agent-runtime-kit --method squash --format json` | passed | PR #118 merged to `main` as `b9032e5`; head branch deleted. | provider output |
| `bash scripts/sync-runtime-skills.sh --apply` | passed | Post-merge sync from `main` rendered and installed 59 skills for Codex and Claude; doctor and Codex prompt-input verification passed. | local output |
| `agent-runtime audit-drift --source-root /Users/terry/Project/graysurf/agent-runtime-kit` | passed | Post-merge drift audit is clean with 20 documented intentional-difference findings. | local output |

## Residual Risk

- `setup-project` may need a released nils-cli helper if dry-run/apply behavior
  becomes a stable machine-readable contract rather than a skill-local shell
  helper.
- `agent-runtime doctor --check-project` still comes from the released nils-cli
  surface and was not changed in this PR. The fail-closed adopted-repo behavior
  here is implemented by the `setup-project` helper and smoke probes.
- `scripts/sync-runtime-skills.sh` does not remove retired link-map surfaces on
  its own; this delivery used dry-run-first `agent-runtime uninstall` cleanup
  for the retired paths before rerunning sync. A future nils-cli/runtime
  cleanup primitive would make retired-skill cutovers less manual.
