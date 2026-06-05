# Bootstrap Hardening Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: planning - bundle is being prepared for a provider-backed tracking
  issue and child implementation issues.
- Target scope: harden first-time and clean-reinstall bootstrap across
  `agent-runtime-kit`, `zsh-kit`, and `nils-cli`.
- Execution window: Step 1 tracker and child issues -> Step 2 known script
  fixes -> Step 3 nils-cli diagnostics and unified bootstrap skeleton ->
  Step 4 runtime-kit integration and closeout.
- Current task: Task 1.1 - create the plan tracker and child issues.
- Next task: Task 2.1 - render before install in first-time runtime-kit setup.
- Last updated: 2026-06-05T00:00:00Z
- Branch/commit/PR: pending.
- Source document: docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-discussion-source.md
- Plan document: docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md
- Direct source-doc execution waiver: not applicable.
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/278>
- Source snapshot: pending.
- Plan snapshot: pending.
- Initial state snapshot: pending.

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
| 1.1 | in-progress | Create the plan tracker and child issues | pending | Bundle created locally; provider issues pending. |
| 2.1 | pending | Render before install in first-time runtime-kit setup | pending | Child issue pending. |
| 2.2 | pending | Include home prompt and docs wiring in setup verification | pending | Child issue pending. |
| 2.3 | pending | Harden zsh-kit install-tools wrapper | pending | Child issue pending. |
| 3.1 | pending | Improve missing render output errors | pending | Child issue pending. |
| 3.2 | pending | Design unified host bootstrap command | pending | Child issue pending. |
| 3.3 | pending | Add final report and resume checkpoint state | pending | Child issue pending. |
| 4.1 | pending | Route legacy setup flow through the hardened path | pending | Child issue pending. |

## Session Log

- 2026-06-05: Clean reinstall completed and exposed bootstrap ordering,
  home-prompt/docs wiring, and zsh-kit installer PATH issues.
- 2026-06-05: Discussion capture promoted into this L2 plan bundle so a
  provider-backed tracking issue can be opened.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/2026-06-05-bootstrap-hardening/bootstrap-hardening-plan.md --format text --explain` | pending | Not run yet. | n/a |
| `agent-docs audit --target all --strict` | pending | Not run yet after bundle promotion. | n/a |
