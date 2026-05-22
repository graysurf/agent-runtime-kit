# Plan 06 Execution State: Runtime Skill Acceptance Harness

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: complete
- Target scope: Sprint 3 Task 3.3
- Execution window: Sprint 3 Task 3.3 architecture and Plan 05 unblock rule
- Current task: Task 3.3 complete pending PR merge
- Next task: Plan 06 closeout and return to Plan 05 Task 5.1 after merge
- Last updated: 2026-05-22 16:37 CST
- Branch/commit/PR: docs/plan-06-acceptance-unblock; pending
- Source document: docs/plans/06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/28

## Validation Plan

- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode install`
- `bash tests/runtime-smoke/run.sh --mode install --format json`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain media`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain reporting`
- `bash tests/runtime-smoke/run.sh --mode deterministic`
- `bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only`
- `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only`
- `bash tests/runtime-smoke/run.sh --mode product --product claude`
- `bash tests/runtime-smoke/run.sh --mode product --product codex`
- `bash tests/runtime-smoke/run.sh --mode product --format json`
- `diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary.json`
- `bash scripts/ci/all.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Define acceptance matrix contract | PR #29 merged `c428829` | Matrix covers all 19 current skill ids and validates required fields/dispositions. |
| 1.2 | done | Add isolated fixture workspace and temp runtime setup | PR #29 merged `c428829` | Temp Codex/Claude `live_home` and `state_home`; installed skill pins match expected lists; doctor `block=0`. |
| 1.3 | done | Add result summary and artifact policy | PR #29 merged `c428829` | Stable summary format documented in `DEVELOPMENT.md`; run logs stay in temp/artifact dirs. |
| 2.1 | done | Add meta skill probes | PR #30 merged `f344f60` | Added command-level probes for `agent-docs`, `agent-out`, `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, and `semantic-commit`. |
| 2.2 | done | Add media and browser probes | PR #31 merged `933944e` | Added command-level probes for `image-processing`, `screen-record`, `browser-session`, and `canary-check`. |
| 2.3 | done | Add evidence probes | PR #32 merged `b4f69a8` | Added command-level probes for `web-evidence`, `test-first-evidence`, `review-evidence`, `skill-usage`, `docs-impact`, and `model-cross-check`. |
| 2.4 | done | Add reporting regression probes and CI wiring | PR #33 merged `2ebba25` | Added reporting regression probes for `daily-brief`, `project-retro`, and `topic-radar`; wired deterministic smoke into CI. |
| 3.1 | done | Probe product CLI isolation contracts | PR #34 merged `751ae8e` | Codex and Claude isolated invocation contracts are supported; prompt smoke remains manual-only when isolated provider/auth is absent. |
| 3.2 | done | Add representative product smoke cases | PR #35 merged `c17ca44` | Added representative prompt cases for `agent-docs`, `agent-out`, `canary-check`, `skill-usage`, and `docs-impact`; default prompt execution is skipped unless isolated provider/auth is explicitly enabled. |
| 3.3 | done | Update architecture and Plan 05 unblock rule | `bash scripts/ci/all.sh` pass | Architecture now reflects deterministic CI strength and quarantined/manual product prompt cases; Plan 05 records the deterministic continuation gate for Sprint 5+. |

## Session Log

- 2026-05-22 14:43 CST: Initialized Sprint 1 execution from issue #28 source and plan snapshots.
- 2026-05-22 14:54 CST: Implemented Sprint 1 runtime smoke foundation and validated targeted harness modes plus `bash scripts/ci/all.sh`.
- 2026-05-22 14:59 CST: Opened ready PR https://github.com/graysurf/agent-runtime-kit/pull/29 for Sprint 1 review/checks.
- 2026-05-22 15:13 CST: Merged Sprint 1 PR #29 at `c428829` and started Sprint 2 Task 2.1 from updated `main`.
- 2026-05-22 15:19 CST: Implemented meta deterministic probes for six meta skills and validated targeted/runtime smoke gates plus `bash scripts/ci/all.sh`.
- 2026-05-22 15:22 CST: Opened ready PR https://github.com/graysurf/agent-runtime-kit/pull/30 for Task 2.1 review/checks.
- 2026-05-22 15:29 CST: Merged Task 2.1 PR #30 at `f344f60` and started Sprint 2 Task 2.2 from updated `main`.
- 2026-05-22 15:38 CST: Implemented media/browser deterministic probes; local host `screen-record --preflight` passed, so the media run recorded a pass instead of a host-capability skip.
- 2026-05-22 15:40 CST: Merged Task 2.2 PR #31 at `933944e` and started Sprint 2 Task 2.3 from updated `main`.
- 2026-05-22 15:45 CST: Implemented evidence deterministic probes using temp artifacts and loopback-only web evidence; no nils-cli surface blockers found.
- 2026-05-22 15:48 CST: Merged Task 2.3 PR #32 at `b4f69a8` and started Sprint 2 Task 2.4 from updated `main`.
- 2026-05-22 15:53 CST: Implemented reporting regression probes and wired deterministic smoke into `scripts/ci/all.sh` position 7.
- 2026-05-22 15:59 CST: Merged Task 2.4 PR #33 at `2ebba25` and started Sprint 3 Task 3.1 from updated `main`.
- 2026-05-22 16:01 CST: Implemented product CLI isolation probes for Codex and Claude with temp runtime homes only.
- 2026-05-22 16:05 CST: Validated Task 3.1 product probes, runtime-smoke regressions, and full `bash scripts/ci/all.sh`.
- 2026-05-22 16:08 CST: Fixed runtime-smoke nonzero-mode dispatch so failing product/deterministic modes still emit the stable result summary before exiting.
- 2026-05-22 16:15 CST: Merged Task 3.1 PR #34 at `751ae8e`; issue #28 dashboard repaired with current state.
- 2026-05-22 16:24 CST: Implemented Task 3.2 product prompt cases and default manual-only skip summary.
- 2026-05-22 16:32 CST: Merged Task 3.2 PR #35 at `c17ca44` and started Sprint 3 Task 3.3 from updated `main`.
- 2026-05-22 16:34 CST: Updated the architecture source and Plan 05 execution state with the Plan 06 deterministic acceptance dependency.
- 2026-05-22 16:37 CST: Validated Task 3.3 with Plan 05/06 plan validation, deterministic runtime smoke, quarantined product smoke, and full `bash scripts/ci/all.sh`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --format text --explain` | pass | Plan 05 bundle validation passed after adding the Plan 06 continuation dependency to its execution state. | n/a |
| `plan-tooling validate --file docs/plans/06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md --format text --explain` | pass | Plan 06 bundle validation passed after Task 3.3 state updates. | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix has 19 unique skill ids matching Codex and Claude sandbox pins. | n/a |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 19 skills each; doctor summaries reported `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install --format json` | pass | Machine-readable summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary.json` | pass | Deterministic JSON summary matches committed expected output. | `/tmp/runtime-smoke-install-summary.json` |
| `bash scripts/ci/all.sh` | pass | Full repo gate positions 1-7 passed, including deterministic runtime skill smoke. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pass | Six meta probes passed inside temp fixture workspace. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Default deterministic mode currently runs all 19 matrix skills across meta, media, browser, evidence, and reporting. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta --format json` | pass | JSON summary emitted 6 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain media` | pass | `image-processing` validated the committed SVG fixture; `screen-record --preflight` passed on this host. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser` | pass | `browser-session` verified local evidence; `canary-check` recorded pass and expected-nonzero canaries. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain media --format json` | pass | JSON summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser --format json` | pass | JSON summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence` | pass | Six evidence probes passed with temp artifacts; `web-evidence` used local loopback HTTP only. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain evidence --format json` | pass | JSON summary emitted 6 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain reporting` | pass | Three reporting probes passed with offline sample/repo-local modes. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain reporting --format json` | pass | JSON summary emitted 3 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode product --product claude --probe-only` | pass | Claude supports temp `CLAUDE_CONFIG_DIR` plus `--bare --no-session-persistence`; prompt path is manual-only without isolated API key/auth. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --product codex --probe-only` | pass | Codex supports temp `CODEX_HOME` plus `exec --ignore-user-config --ephemeral`; prompt path is manual-only without isolated provider/auth. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --probe-only` | pass | Both product isolation probes passed; summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --probe-only --format json` | pass | JSON product probe summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode product --product claude` | pass | Claude temp product home installed 19 skills; five prompt cases recorded `skip-host-capability` until isolated provider/auth execution is explicitly enabled. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --product codex` | pass | Codex temp product home installed 19 skills; five prompt cases recorded `skip-host-capability` until isolated provider/auth execution is explicitly enabled. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --format json` | pass | JSON product summary emitted 4 pass, 0 fail, 10 skip, 0 blocked. | `/tmp/runtime-smoke-product-summary.json` |
| `diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary.json` | pass | Default product JSON summary matches committed expected output. | `/tmp/runtime-smoke-product-summary.json` |

## Notes

- Small fix applied during validation: added the required `Source document` and
  `Direct source-doc execution waiver` fields to this execution-state file
  after `plan-tooling validate` rejected the initial ledger.
- Small fix applied during Task 2.2: updated the `image-processing`
  `svg-validate` skill example to use an SVG output path because the released
  CLI rejects a `.json` output path while emitting JSON to stdout when `--json`
  is set.
- Task 2.3 found no missing nils-cli evidence surfaces. `web-evidence` is kept
  offline by serving a temp fixture through `127.0.0.1`.
- Task 2.4 promotes deterministic smoke to required CI. Product-in-the-loop
  smoke remains outside default CI until Sprint 3 proves an isolated invocation
  contract.
- Task 3.1 proves isolated product invocation contracts for both Codex and
  Claude. Neither probe requires or touches real product homes; missing
  provider/auth is classified as manual-only prompt smoke rather than
  `blocked-design`.
- Small fix applied during Task 3.1: runtime-smoke now preserves the result
  summary when a sub-mode returns nonzero, so future product prompt cases can
  report `blocked-design` evidence instead of exiting before summary output.
- Task 3.2 keeps product prompt execution quarantined. Default product mode
  installs temp product homes and records representative prompt cases as
  `skip-host-capability` unless `RUNTIME_SMOKE_PRODUCT_EXECUTE=1` is set with
  isolated provider/auth state.
- Task 3.3 records the Plan 05 Sprint 5+ continuation rule: deterministic
  runtime smoke must stay green for migrated Sprint 1-4 skills, while product
  smoke remains manual/quarantined unless isolated provider/auth execution is
  supplied.
