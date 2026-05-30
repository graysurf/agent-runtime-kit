# agent-docs Redesign — Kit-Side Adoption Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: in-progress — Sprints 1-2 delivered (host on nils-cli v0.30.0, pin
  aligned, catalog + surface prose adopted); Sprint 3-4 hooks/gates remain.
- Target scope: kit-scoped rollout in `graysurf/agent-runtime-kit`. The
  `agent-docs` engine redesign is an upstream dependency in
  `sympoies/nils-cli` (separate PR/release/tap), not edited here. Sprint 1
  (global-cue migration) is engine-independent; Sprints 2-4 are gated on the
  nils-cli release plus a `required_clis` bump.
- Execution window: Sprint 1 (independent) → nils-cli release gate →
  Sprint 2 (catalog + command-surface adoption) → Sprint 3 (Claude
  enforcement hooks) → Sprint 4 (Codex finish-line enforcement + delivery),
  serial.
- Current task: Sprint 3 (Claude enforcement hooks).
- Next task: Task 3.1 — replace the keyword reminder in
  `user-prompt-agent-docs.sh` with language-agnostic `preflight --intent`
  injection.
- Last updated: 2026-05-30
- Branch/commit/PR: `feat/agent-docs-redesign` (isolated worktree off
  `origin/main`; PR target `graysurf/agent-runtime-kit` main).
- Source document: docs/plans/2026-05-30-agent-docs-redesign/2026-05-30-agent-docs-redesign-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: graysurf/agent-runtime-kit#181
- Source snapshot: pending — posted by `create-plan-tracking-issue` at issue
  open
- Plan snapshot: pending — posted by `create-plan-tracking-issue` at issue
  open
- Initial state snapshot: pending — posted by `create-plan-tracking-issue`
  at issue open

## Validation Plan

- Sprint 1 (cue migration):
  - `rumdl check AGENT_HOME.md`; `readlink ~/.claude/CLAUDE.md` and
    `readlink ~/.codex/AGENTS.md` both resolve to `AGENT_HOME.md`.
  - `rg` for the removed pointer paths returns no active references.
- Sprint 2 (catalog + command-surface adoption):
  - `agent-docs audit` green against the new kit default catalog.
  - `agent-docs preflight` / `audit` against a docs-only fixture confirms
    `project-dev` auto-skips with no opt-out.
  - `rg` finds no retired commands in tracked prose; render-golden for the
    `agent-docs` skill passes; `rumdl check` on touched Markdown.
- Sprint 3 (Claude enforcement hooks):
  - `bash tests/hooks/run.sh`: a non-English prompt still triggers the
    awareness cue; the Stop gate blocks a code-editing stop without
    validation, releases on validation or waiver, and does not block
    docs-only stops; the healthcheck surfaces a broken symlink.
- Sprint 4 (Codex enforcement + delivery):
  - Codex hook test plus a manual Codex acceptance run confirms the no-skip
    gate.
  - `bash scripts/ci/all.sh` and `bash tests/hooks/run.sh` are green;
    `rumdl check` on touched Markdown.
- Cross-cutting: every executed task populates its `Evidence` cell; waived
  tasks are marked `waived` with a reason. The closeout comment is preceded
  by a final `tracking run update --note "<closing summary>"` event.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | done | Inline the global cues into `AGENT_HOME.md` | Sprint 1 on feat/agent-docs-redesign: cues inlined into AGENT_HOME.md (Session Closeout + new Plan Archive block); two startup/global entries removed from AGENT_DOCS.toml; pointer docs retired. Validated: rumdl AGENT_HOME.md clean, both home symlinks resolve to AGENT_HOME.md, catalog resolves (startup 2/2, project-dev 5/5). | `agent-runtime-kit`. Engine-independent. Heuristic summary into `## Session Closeout`; new `## Plan Archive` block. |
| 1.2 | done | Remove startup catalog entries; retire pointer files | Sprint 1 on feat/agent-docs-redesign: cues inlined into AGENT_HOME.md (Session Closeout + new Plan Archive block); two startup/global entries removed from AGENT_DOCS.toml; pointer docs retired. Validated: rumdl AGENT_HOME.md clean, both home symlinks resolve to AGENT_HOME.md, catalog resolves (startup 2/2, project-dev 5/5). | `agent-runtime-kit`. Depends on 1.1 (move first, then delete). Keep `HEURISTIC_SYSTEM.md`. |
| 2.1 | done | Bump `required_clis`; author kit default catalog | Delivered in PR #184 (1be879a) on kit main: pinned nils-cli v0.30.0 (pin.yaml + skills.yaml floor + surface.md), authored kit catalog (DEVELOPMENT.md project-dev + when code-marker predicate + project-dev [[validation]] contract). Validated: agent-docs audit + preflight --intent project-dev (docs present/valid, contract emitted), version-alignment doctor 6/6 ok, scripts/ci/all.sh positions 1-13 OK. | `agent-runtime-kit`. Depends on nils-cli engine release. Data-driven catalog; no hardcoded builtins. |
| 2.2 | done | Make `project-dev` `when`-conditional; confirm pure-docs auto-skip | Delivered in PR #184 (1be879a): DEVELOPMENT.md required via when="path-exists:Cargo.toml // package.json // src/** // scripts/ci/all.sh"; preflight against the kit (has scripts/ci/all.sh) requires it, a docs-only checkout auto-skips with no opt-out. Verified by agent-docs preflight --intent project-dev (when_satisfied=true). | `agent-runtime-kit`. Depends on 2.1. `path-exists` predicate; docs-only fixture needs no opt-out. |
| 2.3 | done | Rewrite preflight prose; retire `startup` per-task | Preflight prose rewritten to the audit/preflight surface with the startup per-task step retired: AGENT_HOME.md Required Preflight, DEVELOPMENT.md, README.md, docs-placement-retention-policy-v1.md, inventory-target-architecture.md, and the agent-docs SKILL (PR #184) plus heuristic-session-closeout SKILL (goldens refreshed). The hook command rework (user-prompt + healthcheck) is delivered under tasks 3.1/3.3. | `agent-runtime-kit`. Depends on 2.1. `AGENT_HOME.md`, `DEVELOPMENT.md`, `agent-docs` SKILL tera, hooks. |
| 3.1 | pending | Replace keyword reminder with language-agnostic injection | tbd | `agent-runtime-kit`. Depends on nils-cli release (`preflight --intent`). No keyword gating. |
| 3.2 | pending | Claude finish-line Stop-hook validation gate | tbd | `agent-runtime-kit`. Depends on 3.1. Block stop on unrun validation; waiver releases; define "evidence ran" marker. |
| 3.3 | pending | Rework SessionStart healthcheck around `audit` | tbd | `agent-runtime-kit`. Depends on nils-cli release (`audit`). Wiring + content checks. |
| 4.1 | pending | Codex non-bypassable finish-line gate ([D12]) | tbd | `agent-runtime-kit`. Depends on 3.2. Stop-equivalent or commit/delivery choke point; no skippable path. |
| 4.2 | pending | Full validation, commit, and delivery | tbd | `agent-runtime-kit`. Depends on 4.1. `scripts/ci/all.sh` + `tests/hooks/run.sh`; `semantic-commit`; `forge-cli pr deliver`. |

## Session Log

- 2026-05-30: Authored this bundle (discussion-source + plan +
  execution-state) from the agent-docs review/redesign session. Conclusion:
  agent-docs stops being an agent per-task preflight; always-on global cues
  move onto the harness auto-load path (`AGENT_HOME.md`), the engine becomes
  data-driven (upstream in `sympoies/nils-cli`), and enforcement moves to the
  finish line (a Stop/delivery gate that blocks a turn when code was edited
  but the declared validation never ran). Codex finish-line enforcement is a
  committed deliverable, mechanism-flexible but never silently skippable
  ([D12]). Tracker is kit-scoped: Sprint 1 is engine-independent; Sprints 2-4
  gate on the nils-cli release. No implementation started; this state is
  prepared so `create-plan-tracking-issue` can open the tracker with a
  populated task ledger.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `plan-tooling validate --file <plan>` | pending | To run before issue open. | n/a |
| `rumdl check <bundle>` | pending | To run before issue open. | n/a |

## Notes

- Kit-scoped tracker: all edits land in `graysurf/agent-runtime-kit`. The
  `agent-docs` engine redesign (data-driven catalog, `when`, content
  validation, collapsed command surface, symlink-derived docs-home, `init`)
  is delivered in `sympoies/nils-cli` and consumed here via a `required_clis`
  bump; it is referenced under Read First, not edited by this tracker.
- Sprint 1 has no engine dependency and can land first. Sprints 2-4 are
  blocked until the nils-cli release ships and is tapped.
- The load-bearing change is the finish-line gate (Sprint 3 Claude, Sprint 4
  Codex): it targets the real pain (agents finishing without running the
  validation in `DEVELOPMENT.md`), which start-time presence checks never
  addressed. It proves the validation ran, not that it passed — sufficient
  for the skip pain.
- Global-cue migration is ordered move-first-then-delete ([D9]): inline into
  `AGENT_HOME.md` and verify auto-load before removing the `AGENT_DOCS.toml`
  entries and pointer files.
