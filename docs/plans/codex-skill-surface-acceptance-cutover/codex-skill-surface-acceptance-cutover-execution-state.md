# Codex Skill Surface Acceptance Cutover Execution State

## Current State

- Status: complete
- Target scope: Sprint 1, Sprint 2, and Sprint 3 — all delivered
- Execution window: 2026-05-23
- Staged execution confirmation: not applicable
- Current task: closeout
- Next task: run plan-tracking-issue-closeout to close issue #55
- Last updated: 2026-05-23 CST
- Branch/commit/PR: Sprint 1+2 merged via `feat/issue-55-codex-skill-surface-cutover` → PR #56 (`b5bc07b`); Sprint 3 closeout via `feat/issue-55-alias-retirement` → PR pending
- Source document: docs/plans/codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: https://github.com/graysurf/agent-runtime-kit/issues/55

## Open Question Resolutions

- CI gate position: shape diagnostic is added as a permanent position in
  `scripts/ci/all.sh` between `audit-drift` and `sandbox install rehearsal`,
  not as a documented-only command. `DEVELOPMENT.md` records the new position
  and its acceptance-boundary contract.
- `required_clis` floor scope: broad bump. Every existing pin to
  `agent-runtime`, `plan-issue`, `forge-cli`, and `plan-tooling` (same
  release boundary) moves to `>=0.17.5`. `plan-tooling` is included because
  the nils-cli release contract releases all four binaries together; leaving
  one binary behind would split the consumer surface. No new pins are added
  for surfaces that did not previously declare one.
- Live acceptance signal: resolved. `codex debug prompt-input` lists every
  required acceptance skill from `agent-runtime-kit/build/codex/plugins/<domain>/skills/<skill>/SKILL.md`
  (loaded through `$HOME/.codex/skills/<domain>/<skill>` symlinks). Pass
  signal: each required skill name appears as a `- <name>: ...` entry in
  the `<skills_instructions>` block with a file path under the runtime-kit
  build tree.
- `$HOME/.agents` retention: resolved. The alias was already absent on the
  canonical workstation before the live window opened; Codex Desktop loads
  all required skills without it. The alias is treated as retired. Rollback
  command remains documented in
  `sprint3-codex/rollback-commands-reviewed.txt` and in the plan's Rollback
  plan; durable docs no longer treat the alias as a runtime-kit path.

## Sprint 1 Evidence

- Task 1.1: `docs/source/nils-cli-surface.md` snapshot moved from `v0.17.1`
  to `v0.17.5`. Header references release `v0.17.5`, head commit `a260510`
  (PR sympoies/nils-cli#447), and the matching Homebrew tap release. The
  `agent-runtime-cli` row documents the new
  `agent-runtime doctor --class skill-surface --product codex` capability.
- Task 1.2: `manifests/skills.yaml` floors updated. `forge-cli`,
  `plan-issue`, and `plan-tooling` pins all read `>=0.17.5`. No
  `agent-runtime` floors exist in `manifests/skills.yaml` to bump.
  `manifests/plugins.yaml` and `manifests/runtime-roots.yaml` carry no
  nils-cli pins that needed change.
- Task 1.3: `agent-runtime doctor --class skill-surface --product codex
  --format json --source-root <repo>` against this worktree reports
  `checks=65 ok=65 warn=0 block=0`, `exit_code=0`, zero findings. The
  acceptance-boundary string is:
  `shape validation only; live Codex Desktop discovery still requires
  ``codex debug prompt-input`` in a fresh session`. JSON and text artifacts
  are stored at
  `${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/plan-issue-delivery/codex-skill-surface-acceptance-cutover/shape-baseline.{json,txt}`.

## Sprint 2 Evidence

- Task 2.1: `scripts/ci/all.sh` gains a new position for the shape
  diagnostic between `audit-drift` and the sandbox install rehearsal.
  `DEVELOPMENT.md` documents the new position and its
  acceptance-boundary contract.
- Task 2.2: pass/fail parser implemented inline with `jq`. The parser
  asserts `exit_code=0`, `warn=0`, `block=0`, and the documented
  baseline check count, and writes a pass/fail summary into the
  runtime-kit state-home `out/` directory.
- Task 2.3: Codex render and golden snapshots are stable after the new
  gate position lands. `agent-runtime audit-drift` reports no unplanned
  source/target mismatch. Sandbox expected skills still cover the
  required acceptance set.
- Task 2.4: `DEVELOPMENT.md`, `docs/source/inventory-target-architecture.md`,
  and `docs/plans/codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md`
  call out shape validation as a preflight, not as live Desktop
  acceptance.

## Sprint 3 Evidence

- Task 3.1: pre-live backup captured in
  `${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit}/out/plan-issue-delivery/codex-skill-surface-acceptance-cutover/sprint3-codex/`.
  Key state: `alias-state-before.txt` records `$HOME/.agents` as
  `absent` at the start of the window; `discovery-env-before.txt`
  records shell and launchctl `AGENT_HOME`, `AGENT_DOCS_HOME`, and
  `CODEX_HOME`; `rollback-commands-reviewed.txt` records the exact
  restore command (`ln -sfn "$HOME/.config/agent-kit" "$HOME/.agents"`).
- Task 3.2: `codex debug prompt-input` ran in a fresh Codex Desktop
  session with `$HOME/.agents` absent. Full JSON saved as
  `sprint3-codex/codex-debug-prompt-input-without-agents.json`. The
  rendered `<skills_instructions>` block lists every required
  acceptance skill — `discussion-to-implementation-doc`,
  `handoff-session-prompt`, `execute-plan-tracking-issue`,
  `deliver-plan-tracking-issue`, and `semantic-commit` — each pointing
  at a file under
  `agent-runtime-kit/build/codex/plugins/<domain>/skills/<skill>/SKILL.md`.
  Additional sanity checks from the same window:
  `agent-runtime install --product codex --dry-run` exit 0 with
  `actions=121`, all no-op; `bash tests/runtime-smoke/run.sh --mode
  install --product codex` reports `install.codex status=pass
  skill_count=44`; `agent-docs --docs-home "$HOME/.codex" resolve
  --context startup --strict --format checklist` exit 0;
  `bash tests/runtime-smoke/run.sh --mode product --product codex
  --probe-only` reports `product.codex.probe status=pass`.
- Task 3.3: `$HOME/.agents` is treated as retired. The alias was
  already absent on the canonical workstation at the start of the
  test window, so no rename was performed and no restore was needed.
  `AGENT_HOME.md` and project `AGENTS.md` updated to remove the
  "currently links" and "may exist as a compatibility alias"
  presentations; the docs-home indirection guard in `AGENT_HOME.md`
  now names the alias as retired. Rollback command remains documented
  in the rollback evidence file and in this plan's `Rollback plan`
  section.
- Task 3.4: rollback is the single-shot `ln -sfn
  "$HOME/.config/agent-kit" "$HOME/.agents"`. Dry-run verification:
  the command resolves against an existing source
  (`$HOME/.config/agent-kit`) and would create a symlink at
  `$HOME/.agents` without touching any Codex auth, session, history,
  log, or cache state. Durable shape-vs-live rules were promoted in
  Sprint 2 to `DEVELOPMENT.md` (position 6 description) and
  `docs/source/inventory-target-architecture.md`; no additional
  durable doc moves were required at closeout.

## Maintenance Evidence

- 2026-05-24: importing five prompt-style conversation skills
  (`actionable-advice`, `actionable-knowledge`, `orchestrator-first`,
  `parallel-first`, `test-first`) expanded the Codex skill-surface shape
  diagnostic from 65 to 70 checks. Updated
  `SHAPE_EXPECTED_MIN_CHECKS=70` in `scripts/ci/all.sh` after
  `agent-runtime doctor --class skill-surface --product codex --format json`
  reported `checks=70`, `ok=70`, `warn=0`, `block=0`, `exit_code=0`.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | done | Refresh nils-cli surface snapshot to v0.17.5 | `docs/source/nils-cli-surface.md` header + agent-runtime-cli row | Cites sympoies/nils-cli@v0.17.5 + tap release |
| Task 1.2 | done | Decide and apply required_clis floor changes | `manifests/skills.yaml` floors bumped | Broad bump per open-question resolution; plan-tooling included for release-boundary coherence |
| Task 1.3 | done | Capture deterministic shape baseline | `shape-baseline.json`, `shape-baseline.txt` in state-home `out/` | 65/65/0/0, exit 0, acceptance-boundary captured |
| Task 2.1 | done | Wire shape diagnostic into scripts/ci/all.sh | `scripts/ci/all.sh` shape-check position | DEVELOPMENT.md updated |
| Task 2.2 | done | Fail-loud parser for shape findings | inline `jq` parser in `scripts/ci/all.sh` | warn=0, block=0, baseline-count asserted |
| Task 2.3 | done | Refresh render/golden/sandbox | `agent-runtime render --update-golden`, audit-drift, sandbox expected skills | No unplanned drift |
| Task 2.4 | done | Document shape-vs-live boundary | DEVELOPMENT.md, inventory-target-architecture.md, codex-skill-discovery-cutover execution state | Shape labeled as preflight, not live acceptance |
| Task 3.1 | done | Pre-live dry-run and backup checks | `sprint3-codex/alias-state-before.txt`, `sprint3-codex/discovery-env-before.txt`, `sprint3-codex/rollback-commands-reviewed.txt`, `sprint3-codex/doctor-skill-surface-codex.json`, `sprint3-codex/install-codex-dry-run.stderr` | Alias was already absent at start of window |
| Task 3.2 | done | Fresh Codex Desktop acceptance window | `sprint3-codex/codex-debug-prompt-input-without-agents.json`, `sprint3-codex/codex-debug-prompt-input-required-skill-string-probes.txt`, `sprint3-codex/agent-docs-codex-home-startup-during-window.txt`, `sprint3-codex/runtime-smoke-install*`, `sprint3-codex/runtime-smoke-product-probe*` | 5/5 required skills visible via `$HOME/.codex/skills/<domain>/<skill>` → runtime-kit build output |
| Task 3.3 | done | Record alias retention decision | AGENT_HOME.md + project AGENTS.md updated; rollback command preserved in plan rollback artifacts | Decision: retired in practice (alias was already absent) |
| Task 3.4 | done | Rollback proof and closeout | Rollback command verified by inspection; shape-vs-live promoted in Sprint 2 | Issue #55 ready for plan-tracking-issue-closeout |
