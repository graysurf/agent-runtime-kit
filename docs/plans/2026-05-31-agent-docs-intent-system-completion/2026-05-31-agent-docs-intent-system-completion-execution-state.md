# agent-docs Intent System Completion Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress - Step 1 requested by the user; plan bundle is being
  prepared for L2 tracking issue creation.
- Target scope: cross-repo completion of `graysurf/agent-runtime-kit#217`
  using Option C. nils-cli owns the declared-intent guard primitive and
  release; runtime-kit owns hook/catalog consumer changes, pin bump, and
  closeout.
- Execution window: Step 1 tracking record -> Step 2 nils-cli design spike ->
  Step 3 nils-cli implementation PR -> Step 4 nils-cli release and tap update
  -> Step 5 runtime-kit consumer PR -> Step 6 runtime-kit pin bump and
  closeout.
- Current task: Task 1.1 - create the plan bundle, validate it, dry-run the
  tracker open, and open the provider tracking issue if the preview matches.
- Next task: Task 2.1 - specify the nils-cli declared-intent guard contract.
- Last updated: 2026-05-31
- Branch/commit/PR: `feat/agent-docs-intent-completion`; no PR yet.
- Source document: docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md
- Plan document: docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: pending
- Source snapshot: pending - posted by `create-plan-tracking-issue` at issue
  open
- Plan snapshot: pending - posted by `create-plan-tracking-issue` at issue
  open
- Initial state snapshot: pending - posted by `create-plan-tracking-issue` at
  issue open

## Validation Plan

- Plan bundle:
  - `plan-tooling validate --file docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md --format text --explain`
- Tracker open:
  - `plan-issue --repo graysurf/agent-runtime-kit --format json --dry-run record open --profile tracking --bundle docs/plans/2026-05-31-agent-docs-intent-system-completion --title "agent-docs intent system completion" ...`
  - `plan-issue record audit --profile tracking --expect-visible` against the
    opened issue.
- nils-cli:
  - `cargo test -p agent-docs`
  - broader nils-cli validation required by that repo.
- runtime-kit:
  - `bash tests/hooks/run.sh`
  - `bash scripts/ci/all.sh`
  - targeted `agent-docs` commands proving the new declared-intent guard.
- Closeout:
  - plan-tracking close-ready and closeout checks after runtime-kit PR merge.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | in-progress | Create the plan bundle and open the tracker | tbd | Freeze #217 and Option C into source/plan/state, validate, dry-run, live open, and initialize run state. |
| 2.1 | pending | Specify the declared-intent guard contract | tbd | Decide nils-cli flag name, semantics, exit code, and JSON/text behavior. |
| 3.1 | pending | Implement the nils-cli declared-intent guard | tbd | Add tests for mistyped intent failure and declared intent success. |
| 4.1 | pending | Release nils-cli and update the Homebrew tap | tbd | Cut release, update tap, upgrade local host, verify versions. |
| 5.1 | pending | Make finish-line validation intent-aware | tbd | Enforce every declared validation contract, not only `project-dev`. |
| 5.2 | pending | Make required-doc cue truncation explicit | tbd | Add visible overflow marker for required-doc lists above the display cap. |
| 5.3 | pending | Reclassify `cli-tools.md` as optional for `task-tools` | tbd | Keep `external-facts.md` required; keep `cli-tools.md` auditable and optional. |
| 5.4 | pending | Integrate the new nils-cli primitive in runtime-kit | tbd | Use fail-closed declared-intent checks where runtime-kit explicitly requests intents. |
| 6.1 | pending | Bump runtime-kit nils-cli pin and deliver | tbd | Use standard bump flow, run full validation, merge PR, and close the tracker. |

## Session Log

- 2026-05-31: User selected Option C and asked to execute the six-step sequence
  in order, starting with Step 1. Plan bundle creation started in
  `graysurf/agent-runtime-kit`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md --format text --explain` | pass | Plan bundle validates with 0 errors. | n/a |
| `plan-issue record open --dry-run` | pass | Preview renders issue dashboard plus source, plan, and state lifecycle comments with the intended labels. | n/a |
| `plan-issue record audit --expect-visible` | pending | To run after live issue open. | n/a |

## Notes

- The runtime-kit checkout and nils-cli checkout were clean on `main` before
  Step 1 started.
- `plan-issue` and `plan-tooling` were available at v0.31.5 before bundle
  creation.
- The runtime-kit tracker should use GitHub labels:
  `type::improvement`, `area::hooks`, `state::needs-triage`,
  `workflow::plan`, and `workflow::tracking`.
