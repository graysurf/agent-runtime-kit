# agent-docs Intent System Completion Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress - Step 3 nils-cli implementation PR is merged; Step 4
  nils-cli release is next.
- Target scope: cross-repo completion of `graysurf/agent-runtime-kit#217`
  using Option C. nils-cli owns the declared-intent guard primitive and
  release; runtime-kit owns hook/catalog consumer changes, pin bump, and
  closeout.
- Execution window: Step 1 tracking record -> Step 2 nils-cli design spike ->
  Step 3 nils-cli implementation PR -> Step 4 nils-cli release and tap update
  -> Step 5 runtime-kit consumer PR -> Step 6 runtime-kit pin bump and
  closeout.
- Current task: Task 4.1 - release nils-cli and update the Homebrew tap.
- Next task: Task 5.1 - make runtime-kit finish-line validation intent-aware.
- Last updated: 2026-05-31T12:03:12Z
- Branch/commit/PR: `feat/agent-docs-intent-completion`; nils-cli PR
  https://github.com/sympoies/nils-cli/pull/719 merged as
  `ae51cec1831188082162bec56d3b966c6faa5295`.
- Source document: docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md
- Plan document: docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/219
- Source snapshot: https://github.com/graysurf/agent-runtime-kit/issues/219#issuecomment-4586543489
- Plan snapshot: https://github.com/graysurf/agent-runtime-kit/issues/219#issuecomment-4586543533
- Initial state snapshot: https://github.com/graysurf/agent-runtime-kit/issues/219#issuecomment-4586543589
- Step 2 design decision: https://github.com/graysurf/agent-runtime-kit/issues/219#issuecomment-4586571787
- Step 3 nils-cli implementation PR: https://github.com/sympoies/nils-cli/pull/719

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
| 1.1 | done | Create the plan bundle and open the tracker | https://github.com/graysurf/agent-runtime-kit/issues/219 | Tracker opened, source/plan/state snapshots posted, run state initialized, audit passed, and #217 linked back. |
| 2.1 | done | Specify the declared-intent guard contract | https://github.com/graysurf/agent-runtime-kit/issues/219; https://github.com/graysurf/agent-runtime-kit/issues/219#issuecomment-4586571787 | Contract specified: add opt-in `agent-docs preflight --require-declared-intent`; default unknown-intent behavior stays compatible; guarded unknown intents exit 65 with structured text/JSON errors. |
| 3.1 | done | Implement the nils-cli declared-intent guard | sympoies/nils-cli branch feat/agent-docs-declared-intent; https://github.com/sympoies/nils-cli/pull/719 | Implemented `agent-docs preflight --require-declared-intent`; PR #719 passed local-fast and GitHub CI, then squash-merged as ae51cec1831188082162bec56d3b966c6faa5295. |
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
- 2026-05-31: Task 1.1 completed. Tracking issue #219 is open with source,
  plan, and state lifecycle records; #217 links forward to #219.
- 2026-05-31: Task 2.1 completed. nils-cli design decision is to add
  `agent-docs preflight --require-declared-intent` as an opt-in fail-closed
  guard, preserving default unknown-intent compatibility and returning exit 65
  with a structured JSON/text error only when the guard is requested.
- 2026-05-31: Task 3.1 completed. nils-cli PR #719 implemented the selected
  guard, passed local-fast plus GitHub `test`, `test_macos`, `coverage`, and
  CodeQL checks, and squash-merged as
  `ae51cec1831188082162bec56d3b966c6faa5295`.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md --format text --explain` | pass | Plan bundle validates with 0 errors. | n/a |
| `plan-issue record open --dry-run` | pass | Preview renders issue dashboard plus source, plan, and state lifecycle comments with the intended labels. | n/a |
| `plan-issue record audit --expect-visible` | pass | Opened #219 has source, plan, and state lifecycle comments visible with no required markers missing. | `/Users/terry/.local/state/agent-runtime-kit/out/projects/graysurf__agent-runtime-kit/20260531-192920-agent-docs-intent-system-completion/issue-219-audit.json` |
| `cargo run -q -p nils-agent-docs -- preflight --intent no-such-intent` | pass | Current default text behavior exits 0 and resolves no documents / no validation contract. | n/a |
| `cargo run -q -p nils-agent-docs -- preflight --intent no-such-intent --format json` | pass | Current default JSON behavior exits 0 with `documents=[]` and `validation.declared=false`. | n/a |
| `cargo run -q -p nils-agent-docs -- list --format json` | pass | Current applicable intents include `project-dev` and `task-tools`. | n/a |
| `cargo test -p nils-agent-docs preflight_unknown_intent_resolves_empty -- --nocapture` | pass | Existing compatibility test confirms unknown intents succeed by default today. | n/a |
| `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast` | pass | nils-cli local-fast gate passed for PR #719. | https://github.com/sympoies/nils-cli/pull/719 |
| `forge-cli pr wait-checks 719 --required-only false` | pass | GitHub checks passed, including `test`, `test_macos`, `coverage`, CodeQL, and report jobs. | https://github.com/sympoies/nils-cli/pull/719 |
| `code-review-pre-merge-gate` | pass | Delivery review found no blocking issues across testing, maintainability, api-contract, security, performance, and red-team lenses. | `/Users/terry/.local/state/agent-runtime-kit/out/projects/sympoies__nils-cli/20260531-195500-agent-docs-declared-intent-delivery/review-outcome.md` |
| `agent-run exec --cwd /Users/terry/Project/graysurf/agent-runtime-kit -- bash scripts/ci/all.sh` | pass | runtime-kit CI positions 1-13 passed after the Step 3 state update. | n/a |
| `agent-run exec --cwd /Users/terry/Project/graysurf/agent-runtime-kit -- bash tests/hooks/run.sh` | pass | 28 shared hook tests passed. | n/a |

## Notes

- The runtime-kit checkout and nils-cli checkout were clean on `main` before
  Step 1 started.
- `plan-issue` and `plan-tooling` were available at v0.31.5 before bundle
  creation.
- The runtime-kit tracker should use GitHub labels:
  `type::improvement`, `area::hooks`, `state::needs-triage`,
  `workflow::plan`, and `workflow::tracking`.
