# Execution State: SUPPORT_MATRIX Rendered + Acceptance-In-Manifest

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: planning landed; implementation pending
- Target scope: render `SUPPORT_MATRIX.md` from manifests (Gap A)
  and lift the `ci_acceptance` / `live_acceptance` columns into
  typed manifest fields with ≥2 entries promoted to executable
  (Gap C). Gap B (new doctor class) and Gap D (sandbox post-install
  doctor pass) are deferred to separate later plans.
- Current task: Sprint 1 Task 1.1 — pin surface registry location.
- Next task: Sprint 1 Task 1.2 — add surface registry + acceptance
  schema.
- Last updated: 2026-05-23
- Branch: feat/support-matrix-rendered-live-issue
- Source document:
  docs/plans/support-matrix-rendered/support-matrix-rendered-discussion-source.md
- Plan document:
  docs/plans/support-matrix-rendered/support-matrix-rendered-plan.md
- Plan-bundle PR (merged):
  <https://github.com/graysurf/agent-runtime-kit/pull/68>
  (merge commit `f8d8a6b15645d3197a754fa09ccdde55391d4ec3`).
- Live tracking issue:
  <https://github.com/graysurf/agent-runtime-kit/issues/69>
  - Source comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4525581127>
  - Plan comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4525581207>
  - State comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4525581261>
- Closed predecessor plan (cite-only, do not reopen):
  docs/plans/support-matrix/ — tracking issue
  <https://github.com/graysurf/agent-runtime-kit/issues/64>
  (closeout comment
  <https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525489698>).
- Direct source-doc execution waiver: user requested that the plan
  bundle plus dry-run tracking-issue artifacts ship together so the
  next session can pick up Sprint 1 implementation directly; live
  tracking issue is created only after the bundle PR lands on
  `main`.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Pin surface registry location | | Choose new `manifests/surfaces.yaml` vs extend `manifests/product-capabilities.yaml`. |
| 1.2 | pending | Add surface registry + acceptance schema | | New or extended JSON Schema under `core/docs/schemas/`. Must be additive. |
| 1.3 | pending | Populate registry rows | | 17 codex + 17 claude rows reproducible from manifest data. |
| 1.4 | pending | Pin `success` predicate semantics | | Resolves the discussion-source Open Question. |
| 1.5 | pending | Resolve Claude-side asymmetry encoding | | `applicable_products: [codex]` vs explicit per-product `state`. |
| 2.1 | pending | Pin cross-product render mode | | Choose (a)-(d); reject any (e) that parses markdown. |
| 2.2 | pending | Implement renderer | | Byte-equal to root (modulo locked header). |
| 2.3 | pending | Wire renderer into `scripts/ci/all.sh` | | Fold into gates 2/3 or add new gate before gate 5. |
| 2.4 | pending | Golden fixture for rendered matrix | | Under `tests/golden/`. |
| 2.5 | pending | Cross-link update and root-file header | | Adds `<!-- generated ... -->` to root file; updates inventory doc. |
| 2.6 | pending | Perturbation test for reopen-trigger automation | | Three perturbations, three audit-drift findings, worktree clean. |
| 3.1 | pending | Pick ≥2 executable acceptance rows | | Cover `kind=ci` and `kind=live` at least once. |
| 3.2 | pending | CI lane that executes the promoted entries | | Failures blocking. |
| 3.3 | pending | Schema-validation negative test | | Fixture under `tests/`. |
| 4.1 | pending | Render tracking-issue artifacts (dry-run) | | Output under `docs/plans/support-matrix-rendered/tracking-issue/`. |
| 4.2 | pending | Multi-lens specialist review of plan bundle | | Evidence in `<state_home>/out/projects/<repo>/<run-id>-support-matrix-rendered-review/`. |
| 4.3 | pending | Apply review fixes | | Re-validate + re-render after material edits. |
| 4.4 | pending | Commit via semantic-commit | | Hook-gated; never bypass. |
| 4.5 | pending | PR deliver to main | | `pr:deliver-github-pr`; user confirms title/body before open. |
| 5.1 | pending | Re-render dashboard with post-merge SHA | | Sprint 5 starts only after Sprint 4 PR merges. |
| 5.2 | pending | forge-cli issue create + comments | | Live mutation; user confirms before execution. |
| 5.3 | pending | Record issue URL in execution state | | Small follow-up PR. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/support-matrix-rendered/support-matrix-rendered-plan.md --format text --explain` | pending | Required before Sprint 4 commit. |
| `agent-runtime audit-drift` | pending | Required before Sprint 4 commit; allowlist forbidden per Decisions. |
| `bash scripts/ci/all.sh` | pending | Required before PR open. |
| `plan-issue record audit --profile tracking ...` | pending | Run during 4.1 and 5.1. |
| `agent-runtime audit-drift` (post-perturbation) | pending | Run during Sprint 2.6. |
| `forge-cli issue view <number> --format json` | pending | Run after 5.2. |

## Closeout Gate

- Close condition: bundle PR merges to `main`; Sprint 1-3
  implementation PRs all merge attached to the live tracking
  issue; live GitHub tracking issue created via Sprint 5 with the
  post-merge SHA, lifecycle comments + dashboard wired, and
  `dispatch:plan-tracking-issue-closeout` run after Sprint 1-3
  done.
- Reopen triggers (forward-looking, replace those of the closed
  plan once Gap A lands):
  - A new harness primitive lands in either shape doc without a
    matching surface registry row.
  - The surface registry schema adds a new required field that
    pre-existing rows do not satisfy.
  - The renderer's golden fixture drifts from the rendered output
    for any reason other than an intentional manifest update.
  - A new acceptance entry is added with neither `command` nor
    `note`, or with both, or with a `success` predicate violating
    the locked shape.
