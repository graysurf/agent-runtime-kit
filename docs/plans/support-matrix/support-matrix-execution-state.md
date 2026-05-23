# Execution State: SUPPORT_MATRIX.md Design And Delivery

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: Sprint 1 done in this PR; Sprint 2 + Sprint 3 already
  shipped before Sprint 1 was executed (the plan bundle and the
  live tracking issue landed first via PR #62 and issue #64);
  Sprint 3.3 follow-up (recording the issue URL back in this file)
  is bundled into this Sprint 1 PR.
- Target scope: ship a root-level `SUPPORT_MATRIX.md` as the unified
  human-readable view over `harness-shape-{claude,codex}.md`, with
  manifests staying as the source of truth.
- Current task: Sprint 1 complete; matrix landed, cross-links wired,
  drift-audit clean.
- Next task: open the nils-cli candidate roundup (out of band; not a
  task in this plan).
- Last updated: 2026-05-23
- Branch: feat/support-matrix-sprint-1
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/64
  - Source comment: https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525059491
  - Plan comment: https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525059569
  - State comment: https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525059622
- Sprint 2 PR: https://github.com/graysurf/agent-runtime-kit/pull/62
  (substantive merge). PR #63 is an empty squash artifact from a
  `forge-cli pr deliver` debug rerun and contains no file changes
  versus the #62 merge.
- Source document: docs/plans/support-matrix/support-matrix-discussion-source.md
- Plan document: docs/plans/support-matrix/support-matrix-plan.md
- Direct source-doc execution waiver: user requested that the plan
  bundle plus dry-run tracking-issue artifacts ship together so the
  next session can pick up implementation directly; live tracking
  issue is created only after the PR lands on `main`.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | completed | Pin the row schema | `SUPPORT_MATRIX.md` Schema section + State legend + Product version pins | Column set: surface / product / state / mechanism / source_artifact / min_product / min_nils_cli / ci_acceptance / live_acceptance / source_manifest. |
| 1.2 | completed | Populate Codex rows | 17 codex rows in `SUPPORT_MATRIX.md` matrix | Matches `grep -c '^### [0-9]\+\.' docs/source/harness-shape-codex.md` = 17. |
| 1.3 | completed | Populate Claude rows | 17 claude rows in `SUPPORT_MATRIX.md` matrix | Matrix uses the unified primitive set from `harness-shape-codex.md` (17). `harness-shape-claude.md` enumerates 14 directly; the extra 3 rows on the Claude side are codex-only surfaces (15 `$CODEX_HOME/skills`, 16 `config.toml` managed block, 17 prompt-mode delegation policy) marked `not-applicable`. Plan Task 1.3 description called for this; the literal validation grep against `harness-shape-claude.md` undercounts and is a known plan correction for a follow-up PR. |
| 1.4 | completed | Cross-link from inventory + shape docs | `docs/source/inventory-target-architecture.md` Purpose-section pointer + a revisions-section entry; `docs/source/harness-shape-{codex,claude}.md` Status-line pointer | 3 files touched. `inventory-target-architecture.md` has two hunks (pointer paragraph + a standard revisions entry, both small); the shape docs have one hunk each. Plan Task 1.4 acceptance asked for one hunk per file — the revisions entry is a deliberate slight overrun because that doc's convention is to log every editorial pass in the revisions section. |
| 1.5 | completed | Drift audit accommodation | `agent-runtime audit-drift` exit 0; no `SUPPORT_MATRIX.md` finding | No `drift-audit.allow.yaml` entry needed — recorded here per the acceptance bullet. 150 pre-existing findings are unrelated (extra/warn for legacy Codex install-map roots; intentional-difference/info for documented plugin manifest divergences). |
| 2.1 | completed | Render tracking issue artifacts (dry-run) | `docs/plans/support-matrix/tracking-issue/` (dashboard + source/plan/state comments) | Shipped in PR #62. |
| 2.2 | completed | Multi-lens specialist review | `${CODEX_AGENT_STATE_HOME or default}/out/projects/graysurf__agent-runtime-kit/20260523-181745-support-matrix-review/` (findings.jsonl + specialist-review.md + bundle/) | 8 findings, lenses: maintainability + testing + red-team. |
| 2.3 | completed | Apply review fixes | PR #62 commit 2 (`docs(plans): fold specialist review fixes into support-matrix bundle`) | All 8 findings folded; tracking-issue plan + source comments re-rendered. |
| 2.4 | completed | Commit via semantic-commit | PR #62 two commits via `semantic-commit commit --auto-fix` | Hook-gated lefthook `pre-commit` and `pre-push` ran clean. |
| 2.5 | completed | PR deliver to main | PR #62 https://github.com/graysurf/agent-runtime-kit/pull/62 | Merge commit 91071fa on `main`. PR #63 (62be580) is an empty squash artifact from a debug rerun. |
| 3.1 | completed | Re-render dashboard with post-merge SHA | `/tmp/support-matrix-rerender/` | Diff vs committed artifacts was the expected single Commit-field hunk. |
| 3.2 | completed | forge-cli issue create + comments | Issue #64, 3 lifecycle comments, dashboard edit | `plan-issue record audit --profile tracking` returned `status=ok`, `missing_required=[]`, 3 markers recognised. |
| 3.3 | completed | Record issue URL in execution state | this file (`Tracking issue:` block at the top + the URLs in 3.1/3.2 Evidence cells) | Bundled into this Sprint 1 PR instead of a stand-alone follow-up. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/support-matrix/support-matrix-plan.md --format text --explain` | passed | Ran in Sprint 2 worktree; exit 0. |
| `agent-runtime audit-drift` | passed | Sprint 1 worktree; exit 0, 150 pre-existing findings, no `SUPPORT_MATRIX.md` finding. |
| `bash scripts/ci/all.sh` | deferred | Skipped locally per user choice; GitHub CI on the Sprint 1 PR is authoritative. |
| `plan-issue record audit --profile tracking ...` | passed | Sprint 3.2 against issue #64 body + comments JSON: `status=ok`, `missing_required=[]`, 3 markers (compat family) recognised. |
| `forge-cli issue view 64 --format json` | passed | Sprint 3.2 confirmed issue creation + label `plan` + 3 lifecycle comments. |

## Closeout Gate

- Close condition: PR with the plan bundle, `SUPPORT_MATRIX.md`,
  dry-run tracking-issue artifacts, cross-link edits, and any
  drift-audit allowlist entry merges to `main`. Live GitHub tracking
  issue exists (Sprint 3) and its URL plus lifecycle comment URLs are
  recorded here through a follow-up PR.
- Reopen triggers: a new harness primitive lands in either shape doc
  without a corresponding `SUPPORT_MATRIX.md` row;
  `manifests/runtime-roots.yaml` bumps a `min_version` /
  `min_version_effective_from` without a matrix refresh; the nils-cli
  surface snapshot moves past `v0.17.6` and the matrix still cites
  the old pin.

## Postscript: nils-cli v0.17.6 follow-through

- The `gh issue list` invocation used during the live Sprint 3.2 run
  was a workaround for the absent `forge-cli issue list` subcommand at
  the time of execution. The subcommand shipped in nils-cli `v0.17.6`
  (sympoies/nils-cli PR #450), so the plan's recorded preflight and
  validation commands now match the available binary surface without
  needing a workaround.
- The `forge-cli pr deliver` "ok=false, BackendError, but the PR is
  actually merged" trap that produced the empty PR #63 squash artifact
  during the live Sprint 2 delivery was fixed in nils-cli `v0.17.6`
  (sympoies/nils-cli PR #451). Future deliveries under v0.17.6 will
  re-fetch PR state on `BackendError` and accept `state=merged` as
  success, so the failure shape that produced #63 is no longer
  reachable through the deliver chain.
