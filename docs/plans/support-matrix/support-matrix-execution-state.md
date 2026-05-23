# Execution State: SUPPORT_MATRIX.md Design And Delivery

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: planning landed; implementation pending
- Target scope: ship a root-level `SUPPORT_MATRIX.md` as the unified
  human-readable view over `harness-shape-{claude,codex}.md`, with
  manifests staying as the source of truth; render dry-run tracking
  issue artifacts and deliver everything to `main` in one PR; open
  the live GitHub tracking issue from the merged plan in a Sprint 3
  follow-up.
- Current task: Sprint 1 Task 1.1 — pin the row schema in
  `SUPPORT_MATRIX.md`.
- Next task: Sprint 1 Task 1.2 — populate Codex rows.
- Last updated: 2026-05-23
- Branch: feat/support-matrix
- Source document: docs/plans/support-matrix/support-matrix-discussion-source.md
- Plan document: docs/plans/support-matrix/support-matrix-plan.md
- Direct source-doc execution waiver: user requested that the plan
  bundle plus dry-run tracking-issue artifacts ship together so the
  next session can pick up implementation directly; live tracking
  issue is created only after the PR lands on `main`.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Pin the row schema | | Long-format normalized; column set fixed in Sprint 1 acceptance. |
| 1.2 | pending | Populate Codex rows | | Walks `harness-shape-codex.md`; Claude-only primitives → `not-applicable`. |
| 1.3 | pending | Populate Claude rows | | Walks `harness-shape-claude.md`; Codex-only primitives → `not-applicable`. |
| 1.4 | pending | Cross-link from inventory + shape docs | | One-line pointer per touched doc. |
| 1.5 | pending | Drift audit accommodation | | Allowlist entry only if `audit-drift` flags the new file. |
| 2.1 | pending | Render tracking issue artifacts (dry-run) | | Output under `docs/plans/support-matrix/tracking-issue/`. |
| 2.2 | pending | Multi-lens specialist review | | Evidence in `<state_home>/out/projects/<repo>/<run-id>-support-matrix-review/`. |
| 2.3 | pending | Apply review fixes | | Re-validate + re-render after material edits. |
| 2.4 | pending | Commit via semantic-commit | | Hook-gated; never bypass. |
| 2.5 | pending | PR deliver to main | | `pr:deliver-github-pr`; user confirms title/body before open. |
| 3.1 | pending | Re-render dashboard with post-merge SHA | | Sprint 3 starts only after Sprint 2 PR merges. |
| 3.2 | pending | forge-cli issue create + comments | | Live mutation; user confirms before execution. |
| 3.3 | pending | Record issue URL in execution state | | Small follow-up PR; updates this file. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/support-matrix/support-matrix-plan.md --format text --explain` | pending | Required before Sprint 2 commit. |
| `agent-runtime audit-drift` | pending | Required before Sprint 2 commit; allowlist acceptable per Task 1.5. |
| `bash scripts/ci/all.sh` | pending | Required before PR open. |
| `plan-issue record audit --profile tracking ...` | pending | Run during 2.1 and 3.1. |
| `forge-cli issue view <number> --format json` | pending | Run after 3.2. |

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
  surface snapshot moves past `v0.17.5` and the matrix still cites
  the old pin.
