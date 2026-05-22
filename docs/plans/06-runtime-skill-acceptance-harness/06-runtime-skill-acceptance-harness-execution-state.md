# Plan 06 Execution State: Runtime Skill Acceptance Harness

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: in-progress
- Target scope: Sprint 2 Task 2.2
- Execution window: Sprint 2 Task 2.2 media and browser probes
- Current task: Task 2.2 validation checkpoint
- Next task: Task 2.3 add evidence probes
- Last updated: 2026-05-22 15:38 CST
- Branch/commit/PR: feat/runtime-smoke-media-browser; pending
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
- `bash tests/runtime-smoke/run.sh --mode deterministic`
- `bash scripts/ci/all.sh`

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Define acceptance matrix contract | PR #29 merged `c428829` | Matrix covers all 19 current skill ids and validates required fields/dispositions. |
| 1.2 | done | Add isolated fixture workspace and temp runtime setup | PR #29 merged `c428829` | Temp Codex/Claude `live_home` and `state_home`; installed skill pins match expected lists; doctor `block=0`. |
| 1.3 | done | Add result summary and artifact policy | PR #29 merged `c428829` | Stable summary format documented in `DEVELOPMENT.md`; run logs stay in temp/artifact dirs. |
| 2.1 | done | Add meta skill probes | PR #30 merged `f344f60` | Added command-level probes for `agent-docs`, `agent-out`, `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, and `semantic-commit`. |
| 2.2 | done | Add media and browser probes | `bash tests/runtime-smoke/run.sh --mode deterministic --domain media` pass; `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser` pass | Added command-level probes for `image-processing`, `screen-record`, `browser-session`, and `canary-check`. |
| 2.3 | pending | Add evidence probes | Not started | Future sprint. |
| 2.4 | pending | Add reporting regression probes and CI wiring | Not started | Future sprint. |
| 3.1 | pending | Probe product CLI isolation contracts | Not started | Future sprint. |
| 3.2 | pending | Add representative product smoke cases | Not started | Future sprint. |
| 3.3 | pending | Update architecture and Plan 05 unblock rule | Not started | Future sprint. |

## Session Log

- 2026-05-22 14:43 CST: Initialized Sprint 1 execution from issue #28 source and plan snapshots.
- 2026-05-22 14:54 CST: Implemented Sprint 1 runtime smoke foundation and validated targeted harness modes plus `bash scripts/ci/all.sh`.
- 2026-05-22 14:59 CST: Opened ready PR https://github.com/graysurf/agent-runtime-kit/pull/29 for Sprint 1 review/checks.
- 2026-05-22 15:13 CST: Merged Sprint 1 PR #29 at `c428829` and started Sprint 2 Task 2.1 from updated `main`.
- 2026-05-22 15:19 CST: Implemented meta deterministic probes for six meta skills and validated targeted/runtime smoke gates plus `bash scripts/ci/all.sh`.
- 2026-05-22 15:22 CST: Opened ready PR https://github.com/graysurf/agent-runtime-kit/pull/30 for Task 2.1 review/checks.
- 2026-05-22 15:29 CST: Merged Task 2.1 PR #30 at `f344f60` and started Sprint 2 Task 2.2 from updated `main`.
- 2026-05-22 15:38 CST: Implemented media/browser deterministic probes; local host `screen-record --preflight` passed, so the media run recorded a pass instead of a host-capability skip.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix has 19 unique skill ids matching Codex and Claude sandbox pins. | n/a |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 19 skills each; doctor summaries reported `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install --format json` | pass | Machine-readable summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary.json` | pass | Deterministic JSON summary matches committed expected output. | `/tmp/runtime-smoke-install-summary.json` |
| `bash scripts/ci/all.sh` | pass | Full repo gate positions 1-6 passed after adding the required execution-state `Source document` pointer. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pass | Six meta probes passed inside temp fixture workspace. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Default deterministic mode currently runs meta, media, and browser probes. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta --format json` | pass | JSON summary emitted 6 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain media` | pass | `image-processing` validated the committed SVG fixture; `screen-record --preflight` passed on this host. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser` | pass | `browser-session` verified local evidence; `canary-check` recorded pass and expected-nonzero canaries. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain media --format json` | pass | JSON summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain browser --format json` | pass | JSON summary emitted 2 pass, 0 fail, 0 skip, 0 blocked. | n/a |

## Notes

- Small fix applied during validation: added the required `Source document` and
  `Direct source-doc execution waiver` fields to this execution-state file
  after `plan-tooling validate` rejected the initial ledger.
- Small fix applied during Task 2.2: updated the `image-processing`
  `svg-validate` skill example to use an SVG output path because the released
  CLI rejects a `.json` output path while emitting JSON to stdout when `--json`
  is set.
