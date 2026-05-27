# Skill Governance Count Refresh Implementation Source

- Status: ready for plan generation
- Date: 2026-05-25
- Source: user request to turn the skill-count drift fix into a durable
  plan-tracking issue for later implementation.
- Intended next step: open an issue-backed tracking record with
  `plan-issue record open`, then implement through the tracking issue.

## Execution

- Recommended plan: docs/plans/2026-05-25-skill-governance-count-refresh/skill-governance-count-refresh-plan.md
- Recommended execution state: docs/plans/2026-05-25-skill-governance-count-refresh/skill-governance-count-refresh-execution-state.md

## Purpose

Active runtime-kit skill counts currently live in several maintained surfaces:
the skill governance audit output, Codex harness docs, runtime-smoke expected
JSON, sandbox expected skill pins, and lifecycle skill instructions. When a
repo-owned skill is added or removed, these maintained counts can drift unless
the lifecycle explicitly refreshes and checks them.

This work integrates active skill-count refresh into the existing
`scripts/ci/skill-governance-audit.sh` governance surface instead of adding a
separate `scripts/ci/skill-count-refresh.sh` script. Create/remove skill
workflows should run the update mode after lifecycle mutations. Runtime sync
should only run the read-only check because `sync-runtime-skills` mutates live
runtime homes, not source repository files.

## Confirmed Facts

- [U1] The user agreed that `create-skill` and `remove-skill` should update
  active skill counts automatically.
- [U2] The user agreed that `sync-runtime-skills` should participate, but
  should not become the owner of repository source mutation.
- [U3] The user requested that the count refresh be integrated into
  `skill-governance-audit` rather than adding a separate
  `scripts/ci/skill-count-refresh.sh --apply` entrypoint.
- [F1] `scripts/ci/skill-governance-audit.sh` already parses
  `manifests/skills.yaml`, compares it with `core/skills/*/*/SKILL.md.tera`,
  validates plugin containment, sandbox expected skill lists, runtime-smoke
  matrix coverage, and prints a `skills=N` summary.
- [F2] Maintained active count references currently exist in
  `docs/source/harness-shape-codex.md`,
  `tests/runtime-smoke/expected/install-summary.json`, and
  `tests/runtime-smoke/product/expected/product-summary.json`.
- [F3] Historical plan execution records under `docs/plans/**` preserve
  point-in-time evidence and should not be rewritten by a count refresh.
- [F4] `create-skill` already owns source, manifests, product render surfaces,
  sandbox expected skill lists, runtime-smoke coverage, and governance
  validation for repo-owned managed skill additions.
- [F5] `remove-skill` already requires maintained docs that list active skills
  or skill counts to be updated after apply approval.
- [F6] `sync-runtime-skills` is a thin wrapper around
  `scripts/sync-runtime-skills.sh` and must not reimplement or bypass the
  source render/install/doctor sequence.

## Decisions

- [D1] `manifests/skills.yaml`, after the existing source/manifest consistency
  checks pass, is the canonical active skill count for maintained count
  refreshes.
- [D2] `skill-governance-audit.sh` should gain explicit read-only and apply
  count modes, preferably `--check-counts` and `--update-counts`.
- [D3] The default governance audit should fail when maintained active count
  references drift.
- [D4] The update mode should mutate only an explicit whitelist of maintained
  active surfaces. It must fail closed on missing or ambiguous replacements.
- [D5] `docs/plans/**` and archived heuristic records are historical evidence
  and must be excluded from automatic count mutation.
- [D6] `create-skill` and `remove-skill` should call the update mode after the
  source, manifest, sandbox, and runtime-smoke surfaces have been changed.
- [D7] `sync-runtime-skills` should run the read-only count check after pull and
  before render/install, and should never run the update mode.

## Scope

- Extend `scripts/ci/skill-governance-audit.sh` with active skill-count check
  and update behavior.
- Add fixture coverage for stale count detection and whitelist-only update
  behavior.
- Update `create-skill`, `remove-skill`, and `sync-runtime-skills` skill bodies
  and rendered/golden outputs to document the new lifecycle sequence.
- Update `scripts/sync-runtime-skills.sh` to perform only read-only governance
  count checks before runtime refresh.
- Keep existing full CI and lifecycle smoke gates as the final validation
  boundary.

## Non-Scope

- Creating a separate `skill-count-refresh.sh` script.
- Rewriting historical plan bundles, archived heuristic records, or old
  execution evidence.
- Automatically regenerating arbitrary Markdown count mentions outside the
  maintained whitelist.
- Changing the semantic meaning of sandbox expected skill pins or runtime-smoke
  acceptance matrix ownership.
- Mutating local Codex or Claude runtime homes from the count updater.

## Requirements

- `skill-governance-audit.sh --check-counts` reports count drift without
  mutating files.
- `skill-governance-audit.sh --update-counts` updates only the maintained
  active count whitelist and is idempotent.
- Default `skill-governance-audit.sh` fails when the whitelist is stale.
- Count update logic preserves historical `docs/plans/**` records.
- Create/remove lifecycle skill instructions include the update command before
  final governance/render/smoke validation.
- Sync lifecycle instructions and script behavior run only the read-only check.
- Fixture coverage proves both stale detection and update behavior.

## Acceptance Criteria

- Deliberately stale active count fixtures fail in check mode and pass after
  update mode.
- The maintained active count whitelist matches the canonical active skill
  count from `manifests/skills.yaml`.
- `create-skill` and `remove-skill` rendered skill bodies teach the update
  command and still preserve their existing safety boundaries.
- `sync-runtime-skills` rendered skill body and script run count checks without
  source mutation.
- `bash scripts/ci/all.sh` remains green.

## Validation Plan

- `bash scripts/ci/skill-governance-audit.sh --check-counts`
- `bash scripts/ci/skill-governance-audit.sh --update-counts`
- `bash scripts/ci/skill-governance-audit.sh --fixture count-refresh`
- `bash scripts/ci/skill-governance-audit.sh`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `bash scripts/ci/sandbox-install-rehearsal.sh`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash scripts/ci/all.sh`

## Risks And Guardrails

- Updating docs with broad regexes can corrupt historical evidence. Restrict
  mutation to a hardcoded active whitelist and fail if a target pattern is
  missing or matches more than once.
- Reformatting runtime-smoke JSON wholesale can create noisy diffs. Prefer
  targeted updates or preserve the existing stable formatting.
- Running update behavior from `sync-runtime-skills` would surprise callers by
  modifying the source checkout during a runtime-home refresh. Keep sync
  check-only.
- Count checks must not replace the existing sandbox expected skill list and
  matrix validation. They are a drift guard for maintained count references,
  not the primary skill lifecycle contract.

## Open Questions

- none

## Recommended Next Artifact

Use
`docs/plans/2026-05-25-skill-governance-count-refresh/skill-governance-count-refresh-plan.md`
as the execution plan and open a tracking issue with `plan-issue record open`
after the bundle is committed and pushed.
