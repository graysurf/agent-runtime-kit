# Codex Skill Surface Acceptance Cutover Execution State

## Current State

- Status: in-progress
- Target scope: Sprint 1 and Sprint 2 (delivered together in one PR); Sprint 3 deferred to a live Codex Desktop window
- Execution window: 2026-05-23
- Staged execution confirmation: not applicable
- Current task: Sprint 2 (shape gate wiring)
- Next task: open delivery PR after specialist review pass
- Last updated: 2026-05-23 CST
- Branch/commit/PR: `feat/issue-55-codex-skill-surface-cutover`; PR pending
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
- Live acceptance signal: deferred. Sprint 3 still owns the exact
  `codex debug prompt-input` pass/fail signal.
- `$HOME/.agents` retention: deferred. Sprint 3 still owns the alias
  retire/observe/defer decision.

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
| Task 3.1 | deferred | Pre-live dry-run and backup checks | — | Deferred to live acceptance window |
| Task 3.2 | deferred | Fresh Codex Desktop acceptance window | — | Requires fresh Codex Desktop session and `codex debug prompt-input` |
| Task 3.3 | deferred | Record alias retention decision | — | Pending Task 3.2 outcome |
| Task 3.4 | deferred | Rollback proof and closeout | — | Pending Task 3.3 outcome |

## Sprint 3 Handoff

Sprint 3 is intentionally deferred from this delivery. Resuming work
requires:

1. Run `agent-runtime doctor --class skill-surface --product codex` from
   the deterministic gate to confirm the shape preflight still passes.
2. Record current `$HOME/.agents` target and any discovery-relevant
   launch environment.
3. Open a reversible test window, disable or rename `$HOME/.agents`,
   start a fresh Codex Desktop session, and capture
   `codex debug prompt-input` evidence for the required skills:
   `conversation.discussion-to-implementation-doc`,
   `conversation.handoff-session-prompt`,
   `dispatch.execute-plan-tracking-issue`,
   `dispatch.deliver-plan-tracking-issue`, `meta.semantic-commit`.
4. Record the alias retention decision and rollback evidence before
   permanently retiring `$HOME/.agents`.

The `execute-plan-tracking-issue` skill can resume from this state
when the live window is open.
