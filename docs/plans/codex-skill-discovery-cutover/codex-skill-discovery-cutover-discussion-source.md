# Codex Skill Discovery Cutover Discussion Source

- Status: open, implementation planning requested
- Date: 2026-05-22
- Source: user handoff for the post-Plan 05 compatibility alias problem, local
  repository policy and architecture docs, Plan 05 execution state, current
  Codex target manifests, and GitHub issue #26 live state.
- Scope: design the Codex skills usage and skill discovery cutover away from
  `$HOME/.agents` and toward the `agent-runtime-kit` installed/linked Codex
  runtime surface under `$HOME/.codex`.
- Intended next step: write the implementation plan only after this source
  document is reviewed.

## Execution

- Recommended plan: docs/plans/codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md
- Recommended execution state: docs/plans/codex-skill-discovery-cutover/codex-skill-discovery-cutover-execution-state.md

## Purpose

Plan 05 moved Codex home policy ownership to `agent-runtime-kit`, but the live
cutover had to restore `$HOME/.agents` as a temporary compatibility alias
because a new Codex Desktop session could not see the original `agent-kit`
skills without it. This document captures the narrower follow-up design problem:
Codex should use skills from the `agent-runtime-kit` source installed or linked
into `$HOME/.codex`, without depending on `$HOME/.agents`.

The goal is not to implement the cutover now. The goal is to give a future plan
enough facts, decisions, boundaries, and acceptance criteria to retire the alias
without breaking new Codex sessions.

## Current Facts

- [U1] The intended long-term direction is that Codex should not rely on
  `$HOME/.agents`.
- [U2] The desired model is that `agent-runtime-kit` owns the source and Codex
  uses skills through the installed/linked runtime surface under
  `$HOME/.codex`.
- [U3] This follow-up covers only Codex skills usage and skill discovery.
- [U4] The immediate deliverable is a discussion source for later planning, not
  implementation.
- [F1] `CODEX_AGENTS.md` documents `$HOME/.agents` as a compatibility alias
  only and says new runtime-kit paths must not route through it.
- [F2] `docs/source/inventory-target-architecture.md` says Codex's working
  activation surfaces are `$CODEX_HOME/AGENTS.md`, the managed hook block in
  `$CODEX_HOME/config.toml`, and files those surfaces reference. It also says
  Codex has no `.codex-plugin/plugin.json` loader or Claude-style
  plugin-scoped skill discovery.
- [F3] `manifests/product-capabilities.yaml` records the current local contract:
  nested Codex skills are addressed by `$CODEX_HOME`-relative paths referenced
  from `AGENTS.md` or hook scripts, and `.codex-plugin/plugin.json` is not
  loaded by Codex at runtime.
- [F4] `manifests/runtime-roots.yaml` records Codex `live_home` and
  `docs_home` as `$CODEX_HOME`, with `plugin_root` under `$CODEX_HOME/plugins`.
- [F5] `targets/codex/link-map.yaml` currently maps rendered skill files into
  `$CODEX_HOME/plugins/<domain>/skills/...` during install.
- [F6] `tests/sandbox/codex/expected-skills.txt` currently pins 39 migrated
  Codex skills.
- [F7] The current migrated Codex set includes `meta.semantic-commit`,
  `dispatch.execute-from-tracking-issue`, and
  `dispatch.deliver-tracking-issue`, but does not include
  `discussion-to-implementation-doc` or `handoff-session-prompt`.
- [F8] `docs/plans/05-domain-migration/05-domain-migration-plan.md` Task 9.3
  explicitly allowed keeping `$HOME/.agents` as a temporary compatibility alias
  when Codex Desktop skill discovery still needed the legacy `agent-kit`
  checkout.
- [F9] `docs/plans/05-domain-migration/05-domain-migration-execution-state.md`
  records the concrete repair: `$HOME/.codex/AGENTS.md` points directly to
  `agent-runtime-kit/CODEX_AGENTS.md`; shell and Codex hook config no longer
  reference `.agents`; `$HOME/.agents -> $HOME/.config/agent-kit` was restored
  as a compatibility alias; launchctl app environment points
  `AGENT_HOME`, `AGENT_DOCS_HOME`, and `PLAN_ISSUE_HOME` to
  `$HOME/.config/agent-kit`; and 61 original `agent-kit` `SKILL.md` files were
  reachable through the alias.
- [F10] `tests/runtime-smoke/expected/install-summary.json` records that the
  current runtime install smoke can install 39 Codex skills into a temporary
  Codex live home and pass doctor with `block=0`.
- [A1] GitHub issue #26, "Plan 05: Phase 4 Domain Migration Sweep", is closed
  as of 2026-05-22 and its final comments record Plan 05 completion plus the
  compatibility alias repair.

## Inferences And Assumptions

- [I1] Current install smoke proves the rendered skill files can be installed
  into a temporary Codex home. It does not prove that Codex Desktop, in a new
  real app session, discovers and exposes those skills without `$HOME/.agents`.
- [I2] The missing mechanism is a discovery/activation contract, not merely a
  file-copy contract. A future plan must identify what Codex Desktop actually
  indexes or receives at session startup.
- [I3] The final migration likely needs a live Codex Desktop verification gate
  because the observed blocker happened only in a new Desktop session.
- [I4] If `discussion-to-implementation-doc` and `handoff-session-prompt` remain
  part of the required acceptance set, the cutover cannot remove `.agents`
  until those skills are available through the runtime-kit-owned Codex surface.

## Decisions

1. Treat `$HOME/.agents` as a temporary compatibility alias, not a source of
   truth and not a permanent Codex discovery root.
2. Keep the source of truth in `agent-runtime-kit`: `core/skills/**`,
   `manifests/skills.yaml`, Codex target metadata, and the install/link map.
3. Treat `$HOME/.codex` as the Codex runtime surface to be installed or linked
   from the source repo.
4. Do not remove `$HOME/.agents` until a fresh Codex Desktop session can see and
   use the required skill acceptance set without the alias.
5. Do not rely on `.codex-plugin/plugin.json` as a Codex runtime loader. It can
   remain local metadata for audit and parity, but the actual activation path
   must be one Codex really reads.

## Scope

In scope:

- Discover and document the exact Codex Desktop skill discovery mechanism used
  by local sessions.
- Decide which `$HOME/.codex` surface should carry runtime-kit skills:
  `$HOME/.codex/plugins/<domain>/skills`, `$HOME/.codex/skills`, generated
  `AGENTS.md` references, a Codex-supported plugin/cache surface, or another
  verified Codex-native path.
- Ensure required skills are sourced from `agent-runtime-kit` and installed or
  linked into the chosen Codex runtime surface.
- Define a live-session acceptance gate that proves a new Codex Desktop session
  sees the required skills without `$HOME/.agents`.
- Define a reversible cutover and rollback procedure for removing or disabling
  the compatibility alias.
- Update tests or docs only where needed to make the skill discovery contract
  explicit and repeatable.

Out of scope:

- Implementing the cutover in this task.
- Removing `$HOME/.agents` in this task.
- Mutating real `$HOME/.codex` skill/runtime state in this task.
- Hook migration, Claude migration, Plan 05 cleanup, legacy repository archive
  cleanup, or product prompt smoke work except where it directly constrains
  Codex skill discovery.
- Changing Codex auth, sessions, history, logs, caches, or secrets.

## Implementation Boundaries

- Live runtime mutation must be dry-run-first and reversible.
- Any live-home experiment must distinguish the three surfaces:
  - source repo: `agent-runtime-kit`
  - Codex runtime home: `$HOME/.codex`
  - temporary compatibility alias: `$HOME/.agents`
- The plan must not use ambient `AGENT_HOME` or `AGENT_DOCS_HOME` as proof of
  the target model. Acceptance must pass without a `.agents` dependency.
- If the future implementation needs nils-cli changes to install or inspect a
  Codex discovery surface, that work belongs in `sympoies/nils-cli` first, then
  this repo consumes the released CLI.
- If a required skill is not yet migrated into `agent-runtime-kit`, the plan
  must call that out explicitly instead of treating legacy `agent-kit` as a
  hidden runtime dependency.

## Requirements

1. Codex Desktop skill discovery is documented from live evidence or from a
   directly inspectable local/runtime source.
2. The selected runtime surface is under `$HOME/.codex` and is populated from
   `agent-runtime-kit`, not from `$HOME/.agents`.
3. The required acceptance set is explicit. Minimum set:
   - `semantic-commit`
   - `execute-from-tracking-issue`
   - `deliver-tracking-issue`
   - `discussion-to-implementation-doc`
   - `handoff-session-prompt`
4. The plan identifies any required skill that is missing from the current
   `agent-runtime-kit` manifest and defines how it will become available before
   alias removal.
5. `agent-docs` preflight can run using the chosen non-`.agents` docs/runtime
   surface.
6. Rollback restores the pre-cutover compatibility behavior without data loss:
   `$HOME/.agents -> $HOME/.config/agent-kit`, launchctl environment restored if
   needed, and Codex Desktop restarted or relaunched when required.

## Acceptance Criteria

- A fresh Codex Desktop session, started with `$HOME/.agents` absent or safely
  disabled in a reversible test window, can see and use every required skill in
  the acceptance set from the runtime-kit-owned `$HOME/.codex` surface.
- `agent-docs` startup and project-dev preflights pass without using
  `$HOME/.agents` as `--docs-home` or via ambient environment.
- `rg` checks over shell startup files and `$HOME/.codex/config.toml` show no
  canonical dependency on `$HOME/.agents`.
- Runtime install or drift checks show the selected Codex skill surface is
  populated from `agent-runtime-kit` and matches the manifest.
- The final implementation records rollback steps and proves rollback before
  permanently removing the alias.

## Validation Plan For The Future Plan

- Static checks:
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist`
  - `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist`
  - `plan-tooling validate --format text --explain`
  - `agent-runtime render --product codex`
  - `agent-runtime audit-drift`
  - `bash tests/runtime-smoke/run.sh --mode install --product codex`
- Discovery checks:
  - Inspect or instrument the chosen Codex discovery root before alias removal.
  - Verify the required acceptance skills exist in the installed `$HOME/.codex`
    surface.
  - Start a new Codex Desktop session with the compatibility alias disabled in a
    reversible window and capture whether the required skills are available.
- Rollback check:
  - Restore `$HOME/.agents -> $HOME/.config/agent-kit`.
  - Reopen a new Codex Desktop session and verify the old compatibility path
    still exposes the required skills if the new path fails.

## Risks And Guardrails

- Codex Desktop may use a private or app-mediated skill discovery path that is
  not fully represented by the Codex CLI or the repository install smoke.
- Current architecture docs say Codex has no plugin loader, while the local
  install map still installs skills under `$HOME/.codex/plugins/...`. The
  future plan must prove that this path is actually referenced or indexed.
- The current 39 migrated skills do not cover all required acceptance skills.
  Removing `.agents` before closing that gap would regress workflows that still
  depend on original `agent-kit` skills.
- Do not use a passing render, golden, dry-run, or temp-home install result as
  proof that a new Codex Desktop session can discover skills.
- Do not hide fallback behavior behind launchctl `AGENT_HOME` or
  `AGENT_DOCS_HOME`; those variables currently point at the legacy
  `$HOME/.config/agent-kit` checkout and are part of the compatibility state.

## Open Questions

- What exact runtime path, cache, config, or app-provided registry does Codex
  Desktop use for local skill discovery?
- Should `agent-runtime-kit` install skills directly into
  `$HOME/.codex/skills`, plugin directories under `$HOME/.codex/plugins`, a
  generated `AGENTS.md` skill index, or another Codex-supported surface?
- Does Codex Desktop discover nested `plugins/<domain>/skills/<skill>/SKILL.md`
  files automatically, or only when the home prompt or another loaded file
  references those paths?
- What is the smallest live-session test that proves Codex can see required
  skills without `$HOME/.agents`?
- Should `discussion-to-implementation-doc` and `handoff-session-prompt` be
  migrated into `agent-runtime-kit` before alias removal, or should the
  acceptance set be narrowed to already-migrated skills?

## Read First References

- `AGENTS.md`
- `DEVELOPMENT.md`
- `CODEX_AGENTS.md`
- `docs/source/docs-placement-retention-policy-v1.md`
- `docs/source/inventory-target-architecture.md`
- `docs/plans/05-domain-migration/05-domain-migration-plan.md`
- `docs/plans/05-domain-migration/05-domain-migration-execution-state.md`
- `manifests/product-capabilities.yaml`
- `manifests/runtime-roots.yaml`
- `targets/codex/link-map.yaml`
- `tests/sandbox/codex/expected-skills.txt`
- `tests/runtime-smoke/expected/install-summary.json`
- `https://github.com/graysurf/agent-runtime-kit/issues/26`

## Recommended Next Artifact

Create
`docs/plans/codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md`
from this source document. The plan should start with discovery evidence, then
choose the Codex runtime surface, then add tests or install behavior, and only
then schedule a reversible live alias-removal gate.

## Retention Intent

This document is coordination material for a focused cutover plan. After the
cutover is complete, promote any durable discovery contract into
`docs/source/inventory-target-architecture.md` or a narrower Codex target doc,
then clean up this plan bundle when no longer useful.
