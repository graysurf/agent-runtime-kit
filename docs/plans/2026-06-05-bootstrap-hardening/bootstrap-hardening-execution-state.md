# Bootstrap Hardening Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: ready - tracker and child implementation issues are open; the next
  execution skill can start Task 2.1.
- Target scope: harden first-time and clean-reinstall bootstrap across
  `agent-runtime-kit`, `zsh-kit`, and `nils-cli`.
- Execution window: Step 1 tracker and child issues -> Step 2 known script
  fixes -> Step 3 nils-cli diagnostics and unified bootstrap skeleton ->
  Step 4 runtime-kit integration and closeout.
- Current task: Task 2.1 - render before install in first-time runtime-kit
  setup.
- Next task: Task 2.2 - include home prompt and docs wiring in setup
  verification.
- Last updated: 2026-06-05T04:12:00Z
- Branch/commit/PR: plan branch
  https://github.com/graysurf/agent-runtime-kit/tree/plan/bootstrap-hardening
- Source document: docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-discussion-source.md
- Plan document: docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md
- Direct source-doc execution waiver: not applicable.
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/278>
- Source snapshot: https://github.com/graysurf/agent-runtime-kit/issues/278#issuecomment-4627998855
- Plan snapshot: https://github.com/graysurf/agent-runtime-kit/issues/278#issuecomment-4627998969
- Initial state snapshot: https://github.com/graysurf/agent-runtime-kit/issues/278#issuecomment-4627999070

## Validation Plan

- `plan-tooling validate --file docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md --format text --explain`
- `plan-issue record audit --profile tracking --expect-visible` against the
  opened issue.
- `agent-docs audit --target all --strict`
- `agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product codex --class skill-surface --format json`
- `agent-runtime doctor --source-root "$HOME/.config/agent-runtime-kit" --product claude --class skill-surface --format json`
- zsh-kit install-tools PATH regression once the zsh-kit issue is implemented.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Create the plan tracker and child issues | https://github.com/graysurf/agent-runtime-kit/issues/278 | Tracker opened, source/plan/state snapshots posted, run state initialized, audit passed, and child issues opened. |
| 2.1 | ready | Render before install in first-time runtime-kit setup | https://github.com/graysurf/agent-runtime-kit/issues/279 | Next executable task. |
| 2.2 | ready | Include home prompt and docs wiring in setup verification | https://github.com/graysurf/agent-runtime-kit/issues/280 | Depends on Task 2.1. |
| 2.3 | ready | Harden zsh-kit install-tools wrapper | https://github.com/graysurf/zsh-kit/issues/79 | Can run independently in zsh-kit. |
| 3.1 | ready | Improve missing render output errors | https://github.com/sympoies/nils-cli/issues/776 | Depends on Task 2.1 evidence. |
| 3.2 | ready | Design unified host bootstrap command | https://github.com/sympoies/nils-cli/issues/777 | Depends on known script fixes and diagnostics. |
| 3.3 | ready | Add final report and resume checkpoint state | https://github.com/sympoies/nils-cli/issues/778 | Depends on Task 3.2. |
| 4.1 | ready | Route legacy setup flow through the hardened path | https://github.com/graysurf/agent-runtime-kit/issues/281 | Depends on Task 3.2 and Task 3.3. |

## Session Log

- 2026-06-05: Clean reinstall completed and exposed bootstrap ordering,
  home-prompt/docs wiring, and zsh-kit installer PATH issues.
- 2026-06-05: Discussion capture promoted into this L2 plan bundle so a
  provider-backed tracking issue can be opened.
- 2026-06-05: Tracking issue #278 opened; run state initialized; child issues
  opened in runtime-kit, zsh-kit, and nils-cli.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md --format text --explain` | pass | Plan bundle validates with 0 errors. | n/a |
| `agent-docs audit --target all --strict` | pass | Docs audit passed with `problems: 0`. | n/a |
| `plan-issue record audit --profile tracking --expect-visible` | pass | Opened #278 has source, plan, and state lifecycle comments visible. | n/a |
