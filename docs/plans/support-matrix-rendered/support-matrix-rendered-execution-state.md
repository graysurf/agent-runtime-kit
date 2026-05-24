# Execution State: SUPPORT_MATRIX Rendered + Acceptance-In-Manifest

<!-- execute-from-tracking-issue:state:v1 -->
## Execution State

- Status: local implementation ready on `feat/support-matrix-rendered-sprint-1`
- Target scope: render `SUPPORT_MATRIX.md` from manifests (Gap A)
  and lift the `ci_acceptance` / `live_acceptance` columns into
  typed manifest fields with at least 2 entries promoted to
  executable (Gap C). Gap B (new doctor class) and Gap D (sandbox
  post-install doctor pass) remain deferred to separate later plans.
- Current task: validation complete with local nils-cli binaries.
- Next task: open/deliver the stacked PR after the nils-cli support
  branch is available to the target environment, or keep using the
  local debug binary for review.
- Last updated: 2026-05-25
- Branch: feat/support-matrix-rendered-sprint-1
- Source document:
  docs/plans/support-matrix-rendered/support-matrix-rendered-discussion-source.md
- Plan document:
  docs/plans/support-matrix-rendered/support-matrix-rendered-plan.md
- Plan-bundle PR (merged):
  <https://github.com/graysurf/agent-runtime-kit/pull/68>
  (merge commit `f8d8a6b15645d3197a754fa09ccdde55391d4ec3`).
- Live tracking issue:
  <https://github.com/graysurf/agent-runtime-kit/issues/69>
  - Original compat-v1 source comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4525581127>
  - Original compat-v1 plan comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4525581207>
  - Original compat-v1 state comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4525581261>
  - V2 source comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4529537599>
  - V2 plan comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4529537662>
  - V2 state bootstrap comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4529537710>
  - V2 validation pass comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4529577771>
  - V2 current state comment:
    <https://github.com/graysurf/agent-runtime-kit/issues/69#issuecomment-4529578237>
- Upstream nils-cli tracking issue:
  <https://github.com/sympoies/nils-cli/issues/486>
  - Branch:
    <https://github.com/sympoies/nils-cli/tree/feat/support-matrix-render-target>
  - Local implementation commit: `6cdaddb`
- Closed predecessor plan (cite-only, do not reopen):
  docs/plans/support-matrix/ — tracking issue
  <https://github.com/graysurf/agent-runtime-kit/issues/64>
  (closeout comment
  <https://github.com/graysurf/agent-runtime-kit/issues/64#issuecomment-4525489698>).
- Direct source-doc execution waiver: user requested that the plan
  bundle plus dry-run tracking-issue artifacts ship together so the
  next session can pick up Sprint 1 implementation directly; live
  tracking issue was created only after the bundle PR landed on
  `main`.
- Execution adjustment, 2026-05-25: live verification showed this
  repository does not contain the `agent-runtime` Rust source and
  installed `agent-runtime 0.21.0` had no `render --target` flag.
  Durable renderer behavior therefore belongs in `sympoies/nils-cli`.
  Issue #486 added `agent-runtime render --target support-matrix`,
  `--update-golden`, and `plan-issue record attach`; this branch
  uses that local debug binary for final runtime-kit validation.
- Issue-record compatibility note, 2026-05-25: issue #69 was opened
  with compat-v1 source/plan/state comments. `plan-issue 0.21.0`
  `record audit` recognized zero lifecycle comments. The local #486
  binary attached v2 source/plan/state comments. After the final
  state and validation posts, read-back audit recognized 4 current
  lifecycle comments, latest state `in-progress`, latest validation
  `pass`, and `missing_required: []`.
- Perturbation adjustment, 2026-05-25: the original Task 2.6
  perturbations against `harness-shape-codex.md`,
  `runtime-roots.yaml`, and `docs/source/nils-cli-surface.md`
  returned clean after re-render because those files are no longer
  canonical inputs for the shared support matrix. The effective
  enforcement is now: `manifests/surfaces.yaml` is canonical,
  `agent-runtime render --target support-matrix --update-golden`
  refreshes `tests/golden/shared/SUPPORT_MATRIX.md`, and
  `git diff --exit-code -- tests/golden/` catches manifest/render
  drift. Evidence is under
  `/Users/terry/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260525-013050-support-matrix-issue69/perturbations-rerender/`.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Pin surface registry location | `manifests/surfaces.yaml`. | New file chosen over extending `product-capabilities.yaml` to keep one schema per manifest and avoid mixing capability facts with matrix row inventory. |
| 1.2 | done | Add surface registry + acceptance schema | `core/docs/schemas/surfaces.schema.json`; `scripts/ci/validate-surfaces-manifest.sh`; `tests/surfaces/invalid-acceptance.yaml`. | Acceptance entries are typed with `kind`, exactly one of `command` or `note`, and exit-status-only `success` for executable commands. |
| 1.3 | done | Populate registry rows | `manifests/surfaces.yaml` carries 17 surfaces with `codex` and `claude` product entries. | Renderer emits 34 rows. |
| 1.4 | done | Pin `success` predicate semantics | `surfaces.schema.json` only accepts `success.exit_status` as a non-negative integer. | Regex/stdout/JSON-path predicates remain deferred to a future doctor/support-matrix class if needed. |
| 1.5 | done | Resolve Claude-side asymmetry encoding | `manifests/surfaces.yaml` uses explicit per-product `state` entries. | Preserves the visible 17 codex + 17 claude matrix shape. |
| 2.1 | done | Pin cross-product render mode | nils-cli issue #486 and this file record `--target support-matrix`. | Smallest additive CLI surface; root Markdown is not parsed as input. |
| 2.2 | done | Implement renderer | Local binary rendered `build/shared/SUPPORT_MATRIX.md`; root diff is empty. | Implemented in nils-cli branch `feat/support-matrix-render-target`, commit `6cdaddb`. |
| 2.3 | done | Wire renderer into `scripts/ci/all.sh` | `scripts/ci/all.sh` positions 5, 6, and 8; `DEVELOPMENT.md`. | Requires the #486 local binary until the nils-cli support branch is released or otherwise available. |
| 2.4 | done | Golden fixture for rendered matrix | `tests/golden/shared/SUPPORT_MATRIX.md`. | `agent-runtime render --target support-matrix --update-golden` refreshes it. |
| 2.5 | done | Cross-link update and root-file header | `SUPPORT_MATRIX.md`; `docs/source/inventory-target-architecture.md`. | Root and generated shared output are byte-equal. |
| 2.6 | waived | Perturbation test for reopen-trigger automation | `perturbations-rerender/*.{audit,exit}.txt`. | Original source-doc perturbation assumptions were disproven; canonical manifest/golden diff is the active enforcement path. |
| 3.1 | done | Pick at least 2 executable acceptance rows | `home-prompt.codex.live`; `project-prompt.codex.ci`. | Covers one `kind=live` command and one `kind=ci` command. |
| 3.2 | done | CI lane that executes the promoted entries | `bash scripts/ci/validate-surfaces-manifest.sh --execute-acceptance`; `scripts/ci/all.sh` position 8. | Local full CI executed 2 commands successfully. |
| 3.3 | done | Schema-validation negative test | `tests/surfaces/invalid-acceptance.yaml`. | Validator rejects the fixture with the exact command/note exclusivity violation. |
| 4.1 | done | Render tracking-issue artifacts (dry-run) | PR #68 includes `docs/plans/support-matrix-rendered/tracking-issue/`. | Compat-v1 artifacts were used for the initial #69 comments. |
| 4.2 | done | Multi-lens specialist review of plan bundle | PR #68 body records two specialist-review passes, 18 findings folded. | Plan-bundle review complete before merge. |
| 4.3 | done | Apply review fixes | PR #68 body records all review findings folded. | No known blocking plan-bundle findings remain. |
| 4.4 | done | Commit via semantic-commit | PR #68 merge commit `f8d8a6b15645d3197a754fa09ccdde55391d4ec3`. | Plan bundle landed on `main`. |
| 4.5 | done | PR deliver to main | PR #68 merged 2026-05-23. | Live issue creation followed in Sprint 5. |
| 5.1 | done | Re-render dashboard with post-merge SHA | Issue #69 source/plan/state comments point at commit `f8d8a6b15645d3197a754fa09ccdde55391d4ec3`. | Initial comments were compat-v1; v2 comments are now attached too. |
| 5.2 | done | forge-cli issue create + comments | Issue #69 opened with source, plan, and state comments. | V2 lifecycle repair performed with local #486 binary. |
| 5.3 | done | Record issue URL in execution state | PR #70 merged commit `d01df8777f12eaf8e151e3083a4228839cb05586`. | `main` records issue #69 and its initial comment URLs. |

## Validation

| Command | Status | Summary |
| --- | --- | --- |
| `plan-tooling validate --file docs/plans/support-matrix-rendered/support-matrix-rendered-plan.md --format json --explain` | pass | Plan bundle validates. |
| `jq empty core/docs/schemas/surfaces.schema.json` | pass | JSON schema parses. |
| `bash scripts/ci/validate-surfaces-manifest.sh` | pass | Manifest shape validates: 17 surfaces, 34 product rows. |
| `bash scripts/ci/validate-surfaces-manifest.sh --execute-acceptance` | pass | Executed 2 promoted acceptance commands. |
| `if bash scripts/ci/validate-surfaces-manifest.sh tests/surfaces/invalid-acceptance.yaml; then exit 1; else test $? -ne 0; fi` | pass | Negative fixture fails validation with `exactly one of command/note is required`. |
| `agent-runtime render --target support-matrix` | pass | Local #486 binary rendered `build/shared/SUPPORT_MATRIX.md` with `surfaces=17 rows=34`. |
| `diff -u build/shared/SUPPORT_MATRIX.md SUPPORT_MATRIX.md` | pass | Root support matrix is byte-equal to generated output. |
| `agent-runtime audit-drift` | pass | Clean with 20 intentional-difference info findings. |
| `PATH=<nils-cli #486 target/debug> bash scripts/ci/all.sh` | pass | Positions 1-13 OK, including support-matrix render, golden refresh, manifest validation, and executable acceptance. |
| `plan-issue record audit --profile tracking` before v2 attach | fail | Recognized 0 comments because #69 only had compat-v1 lifecycle markers. |
| `plan-issue record attach --issue 69 --bundle docs/plans/support-matrix-rendered` | pass | Posted v2 source/plan/state comments to #69. |
| `plan-issue record audit --profile tracking` after v2 attach | pass | `recognized_count: 3`; `missing_required: []`. |
| `plan-issue record audit --profile tracking` after final state/validation posts | pass | `recognized_count: 4`; latest state `in-progress`; latest validation `pass`; `missing_required: []`. |
| Task 2.6 original perturbations | waived | Original source-doc perturbations returned clean; canonical manifest/golden diff replaces this as the active reopen trigger. |

## Closeout Gate

- Close condition: branch implementation is ready locally, but issue
  closeout should wait until the agent-runtime-kit PR is delivered and
  the nils-cli renderer / attach support from issue #486 is available
  to the normal target environment.
- Reopen triggers:
  - A new support-matrix surface is added without a matching row in
    `manifests/surfaces.yaml`.
  - The surface registry schema adds a new required field that
    pre-existing rows do not satisfy.
  - `tests/golden/shared/SUPPORT_MATRIX.md` drifts from the renderer
    output for any reason other than an intentional manifest update.
  - A new acceptance entry is added with neither `command` nor `note`,
    or with both, or with a `success` predicate violating the locked
    exit-status-only shape.
