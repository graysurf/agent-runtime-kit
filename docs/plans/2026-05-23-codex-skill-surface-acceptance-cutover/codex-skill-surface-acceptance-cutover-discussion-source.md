# Codex Skill Surface Acceptance Cutover Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-23
- Source: nils-cli issue #446 / PR #447 / release `v0.17.5`, the existing
  Codex skill discovery cutover source and plan, current agent-runtime-kit
  manifests/link map, and local `agent-runtime 0.17.5` command evidence.
- Intended next step: create an implementation plan from this document, then
  execute it in agent-runtime-kit.

## Execution

- Recommended plan: docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-plan.md
- Recommended execution state: docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-execution-state.md

## Purpose

This document updates the Codex skill-discovery cutover context after nils-cli
shipped a released `agent-runtime doctor --class skill-surface` diagnostic.
The next agent-runtime-kit step should consume that released primitive, make the
shape check part of the deterministic local gate, refresh the nils-cli surface
snapshot and CLI floors where needed, then run the live Codex Desktop acceptance
that proves skills load without the `$HOME/.agents` compatibility alias.

This is not a new implementation plan. It is the read-first source document for
the next plan so implementation can start without re-litigating the release
boundary or the shape-versus-live-acceptance distinction.

## Confirmed Facts

- [U1] The requested next artifact is a `discussion-to-implementation-doc`
  saved in agent-runtime-kit so the following implementation step can start
  directly.
- [A1] nils-cli released `v0.17.5` on 2026-05-23. The release contains PR #447,
  "Add Codex skill surface doctor", merged as
  `a260510984922da60945aa9f48d432f4feb9d09c`.
- [A2] The Homebrew tap released `nils-cli-v0.17.5` on 2026-05-23 and the local
  Homebrew install now reports `nils-cli 0.17.5`,
  `agent-runtime 0.17.5`, `forge-cli 0.17.5`, and
  `nils-plan-issue-cli 0.17.5`.
- [A3] Running
  `agent-runtime doctor --class skill-surface --product codex --format json`
  with `--source-root /Users/terry/Project/graysurf/agent-runtime-kit`
  against current agent-runtime-kit exits 0 and reports `checks=65`,
  `ok=65`, `warn=0`, `block=0`, with 65 skill-surface items and no findings.
- [A4] The same diagnostic reports the acceptance boundary:
  shape validation only; live Codex Desktop discovery still requires
  `codex debug prompt-input` in a fresh session.
- [F1] `DEVELOPMENT.md` defines the coupled nils-cli release boundary:
  after a stable nils-cli change lands, cut the release, bump the tap, upgrade
  local Homebrew, refresh `docs/source/nils-cli-surface.md`, bump affected
  `required_clis` floors in manifests, and rerun `bash scripts/ci/all.sh`.
- [F2] `docs/source/nils-cli-surface.md` is stale for this work: it currently
  records snapshot date 2026-05-22 and active `git describe --tags` output
  `v0.17.1`.
- [F3] `targets/codex/link-map.yaml` now contains directory-symlink entries
  under `skills/<domain>/<skill>` for required Codex skills, including
  `meta.semantic-commit`, conversation skills, and dispatch plan-tracking
  skills.
- [F4] `tests/sandbox/codex/expected-skills.txt` includes the required
  acceptance skills:
  `conversation.discussion-to-implementation-doc`,
  `conversation.handoff-session-prompt`, `dispatch.execute-plan-tracking-issue`,
  `dispatch.deliver-plan-tracking-issue`, and `meta.semantic-commit`.
- [F5] `manifests/skills.yaml` includes runtime-kit source entries for
  `conversation.discussion-to-implementation-doc` and
  `conversation.handoff-session-prompt`; they no longer need to be treated as
  missing migration work.
- [F6] Existing `docs/plans/2026-05-22-codex-skill-discovery-cutover/` documents the
  broader cutover problem: `$HOME/.agents` is a temporary compatibility alias,
  render/golden/install rehearsal is not live Codex Desktop acceptance, and
  alias removal must wait for fresh-session proof.

## Decisions

1. Treat nils-cli `v0.17.5` as the released minimum for the new shape
   diagnostic.
2. Add the shape diagnostic to agent-runtime-kit deterministic validation before
   claiming Codex skill discovery readiness.
3. Do not treat the shape diagnostic as live acceptance. It is a preflight that
   prevents known-bad `SKILL.md` file-symlink shapes and confirms the current
   source/link-map surface is plausibly Codex-discoverable.
4. Keep the live acceptance gate separate and explicit:
   a fresh Codex Desktop session with `$HOME/.agents` absent or safely disabled
   must prove skill visibility with `codex debug prompt-input`.
5. Do not remove or permanently repoint `$HOME/.agents` in the deterministic
   shape-check implementation. Alias removal belongs after live acceptance
   passes with rollback proven.

## Scope

In scope for the next implementation plan:

- Refresh `docs/source/nils-cli-surface.md` to `v0.17.5`.
- Decide and apply any `required_clis` floor bumps needed for skills or plugins
  that depend on `agent-runtime`, `plan-issue`, `forge-cli`, or related
  workflow primitives.
- Add `agent-runtime doctor --class skill-surface --product codex` to the
  documented and scripted validation stack, most likely in `scripts/ci/all.sh`
  after Codex render and before live/install acceptance claims.
- Capture a JSON or text summary that reports item count, zero warnings, zero
  blocks, and the acceptance-boundary text.
- Update the existing Codex skill-discovery cutover plan or create a successor
  plan that uses the `v0.17.5` shape diagnostic as the Sprint 1 preflight.
- Run live Codex Desktop acceptance in a reversible window and record the
  result before alias removal.

Out of scope for the next implementation plan:

- Changing nils-cli code. The needed primitive is already released in `v0.17.5`.
- Recreating the doctor classification in shell, Python, or agent-runtime-kit
  scripts.
- Treating `.codex-plugin/plugin.json` as a Codex runtime loader unless live
  evidence proves it.
- Mutating Codex auth, sessions, history, logs, caches, or secrets.
- Permanent `$HOME/.agents` removal before live acceptance and rollback are
  documented.

## Implementation Boundaries

- Use the released Homebrew `agent-runtime 0.17.5` for the repo gate. A local
  nils-cli debug build may be used only for investigation, not as the final
  contract.
- The shape check reads the agent-runtime-kit source root and link map; it must
  not inspect or mutate real `$HOME/.codex`.
- The live acceptance step must be dry-run/reversible around `$HOME/.agents`.
  Rename or disable the alias only inside a clearly bounded test window and
  restore it on failure.
- Keep `agent-runtime-kit` as the source of truth. Do not silently fall back to
  legacy `agent-kit` skill bodies or ambient `AGENT_HOME` paths as proof of the
  target model.

## Requirements

1. `docs/source/nils-cli-surface.md` reflects nils-cli `v0.17.5`, including the
   new `agent-runtime doctor --class skill-surface` capability.
2. Manifest `required_clis` floors are either bumped where needed or explicitly
   left unchanged with rationale.
3. `scripts/ci/all.sh` or an equivalent documented gate runs the Codex
   skill-surface shape diagnostic.
4. The gate fails on any `codex.active-skill.file-symlink` warning or doctor
   `block > 0`.
5. The gate preserves the acceptance-boundary message so maintainers do not
   confuse shape validation with live Codex Desktop discovery.
6. Live acceptance proves required skills are visible without `$HOME/.agents`:
   `semantic-commit`, `execute-plan-tracking-issue`,
   `deliver-plan-tracking-issue`, `discussion-to-implementation-doc`, and
   `handoff-session-prompt`.
7. Rollback steps restore the pre-cutover compatibility alias and are verified
   before any permanent alias removal.

## Acceptance Criteria

- `agent-runtime --version` reports `0.17.5` or newer before the gate runs.
- `agent-runtime doctor --class skill-surface --product codex --format json`
  against the repo reports 65 items, 0 findings, 0 warnings, and exit 0, or the
  plan updates the expected count with a documented reason.
- `bash scripts/ci/all.sh` passes with the new shape-check position included.
- `docs/source/nils-cli-surface.md` no longer references `v0.17.1` as the active
  surface snapshot.
- The live Codex Desktop acceptance record includes `codex debug prompt-input`
  evidence from a fresh session with `$HOME/.agents` absent or disabled inside a
  reversible window.
- The issue/plan record states whether `$HOME/.agents` remains temporarily in
  place or was removed after acceptance and rollback verification.

## Validation Plan

Deterministic validation:

- Startup preflight:
  `agent-docs --docs-home "$HOME/.config/agent-kit" resolve`
  with `--context startup --strict --format checklist`
- Project-dev preflight:
  `agent-docs --docs-home "$HOME/.config/agent-kit" resolve`
  with `--context project-dev --strict --format checklist`
- `agent-runtime --version`
- `agent-runtime doctor --class skill-surface --product codex --format json`
- `agent-runtime render --product codex`
- `agent-runtime audit-drift`
- `bash tests/runtime-smoke/run.sh --mode install --product codex`
- `bash scripts/ci/all.sh`

Live acceptance:

- Confirm rollback commands for `$HOME/.agents` before mutation.
- Disable or rename `$HOME/.agents` inside a reversible window.
- Start a fresh Codex Desktop session.
- Capture `codex debug prompt-input` evidence showing the required skills are
  visible from the runtime-kit-owned `$HOME/.codex` surface.
- Restore `$HOME/.agents -> $HOME/.config/agent-kit` if acceptance fails or if
  the plan decides to defer permanent removal.

## Risks And Guardrails

- The shape diagnostic is intentionally conservative and source-root based. A
  pass is necessary but not sufficient for live Desktop skill discovery.
- Current shape output includes both legacy `plugins/<domain>/skills` recursive
  file entries and the newer `skills/<domain>/<skill>` directory entries. The
  live acceptance step must prove which surface Codex actually uses.
- Required skills are now present in runtime-kit, but visible skill loading can
  still fail if Codex Desktop ignores the expected `$HOME/.codex/skills` tree or
  caches an older surface.
- Do not update broad docs indexes for this coordination document; discover it
  through the future plan's `Read First` section.

## Open Questions

- Should the new shape check be a permanent `scripts/ci/all.sh` position or a
  targeted pre-live-acceptance command documented in `DEVELOPMENT.md`?
- Should `required_clis` floors be bumped globally to `>=0.17.5` for all
  workflow skills, or only for surfaces whose validation depends on the new
  `agent-runtime` doctor class?
- What exact `codex debug prompt-input` output is the stable pass/fail signal
  for skill availability in a fresh Desktop session?
- If live acceptance passes, should `$HOME/.agents` be removed immediately or
  kept through one additional observation window?

## Read First References

- `DEVELOPMENT.md`
- `docs/source/docs-placement-retention-policy-v1.md`
- `docs/source/nils-cli-surface.md`
- `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-discussion-source.md`
- `docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md`
- `targets/codex/link-map.yaml`
- `manifests/skills.yaml`
- `tests/sandbox/codex/expected-skills.txt`
- `scripts/ci/all.sh`
- `https://github.com/sympoies/nils-cli/releases/tag/v0.17.5`
- `https://github.com/sympoies/homebrew-tap/releases/tag/nils-cli-v0.17.5`

## Recommended Next Artifact

Create
`docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/codex-skill-surface-acceptance-cutover-plan.md`
with this document as the primary `Read First` source. The plan should either
supersede or explicitly update the existing
`docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md`
so there is only one active implementation lane for alias removal.

## Retention Intent

Coordination source. Keep while the cutover plan is active. After completion,
promote only the durable rules into `DEVELOPMENT.md`,
`docs/source/inventory-target-architecture.md`, or
`docs/source/nils-cli-surface.md`; otherwise this document can remain as plan
history.
