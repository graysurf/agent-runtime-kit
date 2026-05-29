# Agentmemory Managed Cross-Agent Memory Integration Execution State

<!-- plan-issue-record:v2 role=state profile=tracking -->
## Execution State

- Status: ready-to-start; tracking issue not yet opened.
- Target scope: single-repo rollout in `graysurf/agent-runtime-kit`.
  Sprint 1 isolated validation spike (confirm local embeddings, zero
  external API, `:3111` daemon footprint) → Sprint 2 integration
  source model (resolve [O1]; register agentmemory as a disabled
  managed integration) → Sprint 3 wiring (render capture hooks to
  both products from managed source; daemon launcher with data dir
  under `state_home`; gitignore + drift-allow + version pin) →
  Sprint 4 opt-in rollout (cross-reference the `agent-memory` curated
  store; enable/disable path; CI + delivery).
- Execution window: Sprint 1 → 2 → 3 → 4 (serial). Sprint 1's
  adopt-or-fall-back verdict gates Sprints 2-4; a "fall back" verdict
  waives them.
- Current task: none (tracking issue not yet opened).
- Next task: Task 1.1 — install and run agentmemory in an isolated
  home.
- Last updated: 2026-05-29
- Branch/commit/PR: tbd (Sprint 2-4 PR target:
  `graysurf/agent-runtime-kit` main; suggested branch prefix
  `feat/agentmemory-managed-integration`).
- Source document: docs/plans/2026-05-29-agentmemory-managed-integration/2026-05-29-agentmemory-managed-integration-plan.md
- Direct source-doc execution waiver: not applicable
- Tracking issue: tbd (to be opened by `create-plan-tracking-issue`
  against `graysurf/agent-runtime-kit`)
- Source snapshot: pending — posted by `create-plan-tracking-issue`
  at issue open
- Plan snapshot: pending — posted by `create-plan-tracking-issue` at
  issue open
- Initial state snapshot: pending — posted by
  `create-plan-tracking-issue` at issue open

## Validation Plan

- Sprint 1 (spike):
  - `lsof -iTCP:3111 -sTCP:LISTEN` confirms the local daemon binds
    `127.0.0.1`; directory listing confirms the isolated data dir.
  - Capture + recall succeed with `EMBEDDING_PROVIDER=local` and no
    LLM provider; egress observation shows no API endpoints contacted
    after the one-time embedding-model download.
  - `rumdl check docs/source/agentmemory-integration-spike.md`.
- Sprint 2 (source model):
  - Repo manifest/schema validator (or governance check) passes for
    the new integration registration.
  - `scripts/setup.sh --dry-run` (or render dry-run) shows no
    live-home delta while the integration is disabled.
  - `rumdl check docs/source/agentmemory-integration-design.md`.
- Sprint 3 (wiring):
  - Render + golden check passes; rendered targets carry agentmemory
    hooks only when enabled.
  - Drift audit passes; `git status --porcelain` is clean of
    agentmemory runtime state (SQLite/log/pid/npm artifact).
- Sprint 4 (rollout + delivery):
  - `scripts/setup.sh --dry-run` before/after enable shows the
    expected delta and a clean revert.
  - `bash scripts/ci/all.sh` plus the repo's render/golden + drift
    checks are green.
  - `rumdl check` on every touched Markdown file.
- Cross-cutting: every executed task populates its `execution-state.md`
  `Evidence` cell; waived tasks are marked `waived` with a reason. The
  closeout comment is preceded by a final
  `tracking run update --note "<closing summary>"` event.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | pending | Install and run agentmemory in an isolated home | tbd | `agent-runtime-kit`. Isolated dir under `state_home`; do not touch live `~/.claude` / `~/.codex`. |
| 1.2 | pending | Verify zero external API + capture hook/footprint evidence | tbd | `agent-runtime-kit`. Depends on 1.1. Confirm local embeddings + BM25 recall, enumerate hook set (12 Claude / 6 Codex) and data/artifact paths. |
| 1.3 | pending | Findings doc + adopt-or-fall-back decision gate | tbd | `agent-runtime-kit`. Depends on 1.1, 1.2. `docs/source/agentmemory-integration-spike.md`; "fall back" waives Sprints 2-4. |
| 2.1 | pending | Decide and document the integration model ([O1]) | tbd | `agent-runtime-kit`. Depends on 1.3 adopt verdict. `docs/source/agentmemory-integration-design.md`. |
| 2.2 | pending | Add the integration registration (disabled by default) | tbd | `agent-runtime-kit`. Depends on 2.1. New `integrations` manifest/schema OR hook-fragment+launcher layout; `install_policy: opt-in`. |
| 3.1 | pending | Source + render the capture hook fragments to both products | tbd | `agent-runtime-kit`. Depends on 2.2. Managed source pinned to version; Claude settings.hooks.jsonc + Codex managed block. |
| 3.2 | pending | Daemon launcher + `state_home` data placement ([O2]) | tbd | `agent-runtime-kit`. Depends on 3.1. `:3111` daemon, data dir under `state_home`, `EMBEDDING_PROVIDER=local`. |
| 3.3 | pending | gitignore + drift-allow + version pin | tbd | `agent-runtime-kit`. Depends on 3.1, 3.2. No runtime state tracked; rendered surfaces pass drift. |
| 4.1 | pending | Cross-reference the agent-memory curated store ([D3]) | tbd | `agent-runtime-kit`. Depends on 2.1. Pointer + role-split doc; no curated content copied here. |
| 4.2 | pending | Opt-in enable/disable path + docs | tbd | `agent-runtime-kit`. Depends on 3.3. `scripts/setup.sh` dry-run-first; default disabled; `DEVELOPMENT.md`. |
| 4.3 | pending | CI, commit, and delivery via forge-cli pr deliver | tbd | `agent-runtime-kit`. Depends on 4.1, 4.2. `scripts/ci/all.sh` + drift/render green; `--kind feature`. |

## Session Log

- 2026-05-29: Authored this bundle (discussion-source + plan +
  execution-state) from the cross-agent memory evaluation session.
  Conclusion: agentmemory's mechanism/wiring belongs in
  `agent-runtime-kit` (hooks/install/drift/render are its mandate),
  runtime state stays untracked under `state_home`, curated-markdown
  semantics stay in the separate `agent-memory` repo. Because
  `plugins.yaml` is skill-centric, agentmemory is modeled as a new
  lightweight integration; rollout is opt-in / disabled-by-default,
  dry-run-first, spike-first. Pre-open preflight: `agent-docs resolve
  --context project-dev --strict` → 2/2 present;
  `plan-tooling validate` → see Validation table. No implementation
  started; this state is prepared so `create-plan-tracking-issue`
  can open the tracker with a populated task ledger.

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | 2/2 required docs present. | n/a |
| `plan-tooling validate --file <plan>` | pending | To run before issue open. | n/a |
| `rumdl check <bundle>` | pending | To run before issue open. | n/a |

## Notes

- Single-repo rollout: all four sprints land in
  `graysurf/agent-runtime-kit`. No `sympoies/nils-cli` changes are in
  scope ([O3] deep CLI integration is Future Work).
- Sprint 1 is a genuine decision gate, not a formality: a "fall back"
  verdict ([D7]) stops the rollout and waives Sprints 2-4 with the
  Markdown-only path recorded in Future Work.
- agentmemory runtime data (SQLite store, daemon pid/log, npm install
  artifact, captured transcripts) is never tracked; it points at the
  product `state_home` from `manifests/runtime-roots.yaml` and is
  gitignored — the same treatment plugin install artifacts already
  receive.
- The curated Markdown memory store in `graysurf/agent-memory`
  (`~/.config/agent-memory/`) is out of scope for edits; this rollout
  only cross-references it.
