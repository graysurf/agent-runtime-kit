# Skill Lifecycle Management Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-24
- Source: user request to evaluate adding skill add/remove management for this
  repo, plus local inspection of the legacy `agent-kit` skill-management tree
  and current `agent-runtime-kit` source/render contracts.
- Intended next step: feed this document into `create-plan-tracking-issue`
  before implementation. This is a source artifact, not an implementation plan.

## Execution

- Recommended plan: docs/plans/skill-lifecycle-management/skill-lifecycle-management-plan.md
- Recommended execution state: docs/plans/skill-lifecycle-management/skill-lifecycle-management-execution-state.md

## Purpose

`agent-runtime-kit` needs a first-class workflow for adding, validating, and
removing repo-owned skills because one skill lifecycle change now touches more
than a `SKILL.md` folder. A correct change can involve `core/skills/`,
`manifests/skills.yaml`, `manifests/plugins.yaml`, product render paths,
golden snapshots, sandbox expected skill lists, runtime-smoke coverage, and
skill-usage reminder metadata.

The legacy `agent-kit` skill-management family is useful prior art, but it
assumes the retired `skills/...` tree, `$AGENT_HOME` command paths, `.agents`
project-skill layout, and root `README.md` skill catalog. It should not be
ported verbatim.

## Current Judgment

Add this capability, but make it `agent-runtime-kit` native:

- Keep agent-facing orchestration as narrow skills, not one broad umbrella.
- Put repo-owned skill lifecycle surfaces in the existing `meta` domain unless
  implementation shows that a separate `skill-management` plugin is warranted.
- Treat deterministic mutation and validation as either released nils-cli
  behavior or thin repo scripts that call released nils-cli. Do not recreate a
  large Bash/Python mutation layer inside skill bodies.
- Exclude project-local `.agents/skills` scaffolding from v1. The retired
  `.agents` alias and project-overlay behavior need a separate design pass.

## Confirmed Facts

- [U1] The user asked to evaluate adding the legacy
  `/Users/terry/Project/graysurf/agent-kit/skills/tools/skill-management`
  capability into this repo for managing this repo's skills.
- [A1] Local inspection found the legacy tree contains `create-skill`,
  `create-project-skill`, `remove-skill`, `skill-governance`, and a grouping
  `README.md`.
- [A2] Local inspection of this checkout found no migrated
  `skill-management`, `create-skill`, `create-project-skill`,
  `remove-skill`, or `skill-governance` skill directories. Only
  `core/hooks/shared/skill-usage-reminder.skills.json` retains exact-only
  reminder metadata for `create-skill`, `create-project-skill`, and
  `remove-skill`.
- [F1] `DEVELOPMENT.md` defines this repo as the content source of truth for
  skills, plugin metadata, hooks, render templates, manifests, policies, and
  tests; it also states the repo does not ship a local CLI binary.
- [F2] `DEVELOPMENT.md` says durable runtime behavior, JSON contracts, exit-code
  contracts, parsers, and shared capability binaries belong in nils-cli, while
  repo scripts are Bash glue and skill-local helpers are acceptable only when
  owned by one skill.
- [F3] `docs/source/inventory-target-architecture.md` says writing or editing
  skill bodies and manifests belongs in `agent-runtime-kit`, while deterministic
  CLI behavior belongs in `sympoies/nils-cli`.
- [F4] The current canonical skill source path is
  `core/skills/<domain>/<skill>/`, with product-specific activation handled by
  `targets/<product>/` and manifest entries in `manifests/`.
- [F5] The manifest layer requires `skills.yaml` entries to declare canonical
  `<domain>.<skill>` IDs, source paths, supported products, render paths, and
  `required_clis`; `plugins.yaml` records domain plugin grouping and contained
  skills.
- [F6] The validation stack includes manifest schema validation, render-golden
  checks, drift fixtures, sandbox install rehearsal, runtime-smoke, project
  overlay smoke, and hook tests.
- [F7] The legacy `agent-kit` `create-skill` contract only accepts
  `skills/...` paths, writes `SKILL.md` plus `scripts/` and `tests/`, updates
  a root skill catalog, and invokes legacy governance scripts through
  `$AGENT_HOME/skills/tools/skill-management/...`.
- [F8] The legacy `agent-kit` `remove-skill` contract only accepts
  `skills/...` paths, deletes matching script specs, removes Markdown
  references, and fails on remaining references.

## Decisions

- [D1] Implement this as a lifecycle family, not a copied folder:
  `create-skill`, `remove-skill`, and `skill-governance` are the natural v1
  surfaces.
- [D2] Use `meta` as the default domain:
  `core/skills/meta/create-skill`,
  `core/skills/meta/remove-skill`, and
  `core/skills/meta/skill-governance`.
- [D3] Defer `create-project-skill`. The legacy behavior targets
  `.agents/skills`, while this repo has moved away from `$HOME/.agents` as a
  live indirection. A project-overlay skill should be designed separately.
- [D4] `create-skill` should scaffold the full runtime-kit shape, not just a
  folder:
  `core/skills/<domain>/<skill>/SKILL.md.tera`, optional skill-owned support
  folders, `manifests/skills.yaml`, `manifests/plugins.yaml` when needed,
  product target metadata when a new domain/plugin appears, golden fixtures,
  sandbox expected-skill pins, and runtime-smoke matrix/case entries when the
  skill has executable behavior.
- [D5] `remove-skill` must be dry-run-first and must not rewrite archival
  `docs/plans/**` history by default. It should purge active source,
  manifest, target, test, golden, sandbox, hook/reminder, and maintained docs
  references, then fail if active references remain.
- [D6] `skill-governance` should validate the lifecycle contract:
  source folder shape, Tera skill body presence, manifest/source consistency,
  plugin containment, product render paths, `required_clis` pins, reminder
  metadata, golden/sandbox/runtime-smoke coverage, and absence of legacy
  `$AGENT_HOME` / `skills/...` assumptions.
- [D7] If lifecycle mutation requires structured YAML edits, reference
  scanning, stable machine output, or non-trivial parsing, the deterministic
  primitive belongs in nils-cli. The repo skill should call that primitive
  and own judgment, sequencing, and review guidance.
- [D8] The old `skill-usage-reminder.skills.json` entries for
  `create-skill` and `remove-skill` remain useful. `skill-governance` should
  get reminder metadata only if it becomes an agent-invoked workflow rather
  than a passive CI validator.

## Scope

- Add or plan repo-native skill lifecycle surfaces for this repo's managed
  runtime skills.
- Define how a new skill is added to canonical source, manifests, product
  render surfaces, tests, and runtime acceptance.
- Define how a skill is removed without leaving active references or deleting
  historical coordination records.
- Define the governance checks that make lifecycle changes reviewable.
- Preserve the old `agent-kit` behavior only as historical reference.

## Non-Scope

- Directly copying the legacy `skills/tools/skill-management` tree.
- Project-local `.agents/skills` scaffolding.
- Reintroducing `$HOME/.agents` as a live skill-discovery indirection.
- Creating compatibility shims for removed skills unless a specific product
  surface requires an intentional alias.
- Rewriting nils-cli or adding a new released primitive inside this repo.
- Updating broad docs indexes for this source document; discoverability comes
  from the future plan's `Read First` section.

## Implementation Boundaries

- Skill prose owns: when to use the lifecycle workflow, judgment about scope,
  `required_clis`, product support, acceptance coverage, and when to stop for
  user approval.
- Repo scripts may own: Bash glue for local validation or invoking released
  nils-cli commands, provided they stay Bash 3.2 compatible and do not become
  a second runtime implementation.
- nils-cli owns: any stable parser, YAML mutation engine, reference graph,
  JSON output contract, dry-run/apply planner, or exit-code contract for
  lifecycle mutations.
- `agent-runtime-kit` owns: skill bodies, templates, manifests, targets,
  golden snapshots, sandbox expectations, runtime-smoke fixtures, and docs.

## Requirements

### `create-skill`

- Accept canonical source inputs: `--id <domain.skill>`,
  `--domain <domain>`, `--skill <skill>`, `--products codex,claude|...`,
  `--required-cli <name>=<semver-range>` repeatable, and optional
  `--description`.
- Create `core/skills/<domain>/<skill>/SKILL.md.tera` with the current
  contract shape and no legacy `$AGENT_HOME` references.
- Add a `manifests/skills.yaml` entry with concrete `required_clis` values
  or an explicit empty map when the skill is prose-only.
- Add the skill to `manifests/plugins.yaml` for an existing domain, or create
  the product plugin metadata path when a new domain is intentionally added.
- Prepare render/golden/sandbox/runtime-smoke follow-up changes or fail with a
  clear list of missing acceptance artifacts.
- Leave staging and commit to the caller.

### `remove-skill`

- Default to `--dry-run`; require `--apply` or equivalent explicit approval for
  file mutation.
- Remove source, manifest entries, plugin containment, product render
  metadata, golden snapshots, sandbox expected-skill pins, runtime-smoke cases,
  hook/reminder metadata, and maintained docs references for the target skill.
- Do not modify `docs/plans/**` by default. Historical plan references are
  evidence unless the caller explicitly asks for cleanup.
- Fail if active references remain outside allowed historical/retained-record
  areas.

### `skill-governance`

- Validate source folder anatomy for `core/skills/**`.
- Validate `SKILL.md.tera` front matter, H1, and required contract sections.
- Validate every source skill is represented in `manifests/skills.yaml`, and
  every manifest source path exists.
- Validate every skill ID appears in exactly one plugin's `contained_skills`.
- Validate product render paths and path overrides are consistent with
  `targets/<product>/` conventions.
- Validate `required_clis` floors against `docs/source/nils-cli-surface.md`
  and reject placeholders.
- Validate acceptance artifacts are updated when the skill surface changes.

## Acceptance Criteria

- A future plan can execute from this document without rediscovering the old
  `agent-kit` assumptions.
- Adding one sample low-risk prose skill through the new workflow produces a
  complete source/manifest/render/golden/sandbox delta and passes targeted
  validation.
- Removing one sample fixture skill through dry-run reports every active file
  that would change, and apply mode leaves no active references.
- The full repo gate remains green after real lifecycle changes.
- The final implementation does not introduce `$AGENT_HOME` or top-level
  `skills/...` as maintained runtime-kit assumptions.

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `plan-tooling validate --format text --explain`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --product codex --update-golden`
- `agent-runtime render --product claude --update-golden`
- `agent-runtime audit-drift`
- `agent-runtime doctor --class skill-surface --product codex`
- `bash scripts/ci/sandbox-install-rehearsal.sh`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash tests/hooks/run.sh`
- `bash scripts/ci/all.sh`

## Risks And Guardrails

- Risk: copying the legacy tools preserves the wrong path model. Guardrail:
  all maintained paths must use `core/skills`, `manifests`, `targets`, and
  rendered product outputs.
- Risk: a create/remove helper becomes an unreleased local CLI surface.
  Guardrail: promote stable parsing/mutation contracts to nils-cli and pin
  any consumed binary in `required_clis`.
- Risk: removal deletes useful historical records. Guardrail: exclude
  `docs/plans/**` unless the caller explicitly asks for cleanup.
- Risk: the workflow expands the visible skill surface too much. Guardrail:
  keep v1 to three exact lifecycle surfaces and do not add an umbrella skill.
- Risk: "skill exists" is overclaimed after render/golden only. Guardrail:
  require sandbox/runtime-smoke acceptance for discoverability-sensitive
  changes.

## Retention Intent

This document is coordination material. Keep it under `docs/plans/` while the
lifecycle-management plan is active. After execution completes, either delete
it through durable artifact cleanup or promote the stable lifecycle policy into
`docs/source/` or `core/docs/` if maintainers need it outside plan context.

## Open Questions

- Should the deterministic primitive be added as a new nils-cli command
  (`agent-runtime skill ...`) or as separate `skill-lifecycle` binaries?
  Default: decide during plan generation after checking nils-cli surface
  conventions.
- Should `skill-governance` be a user-invoked skill, a CI-only validator, or
  both? Default: make it a skill only if agents should invoke it during
  lifecycle work.
- Should `create-project-skill` return later as a project-overlay workflow?
  Default: defer until project-local overlay semantics are stable.
- Should lifecycle helpers allow new plugin domains automatically? Default:
  require explicit `--new-domain` or user approval because it changes both
  product surfaces.

## Read First References

- `DEVELOPMENT.md`
- `docs/source/docs-placement-retention-policy-v1.md`
- `docs/source/inventory-target-architecture.md`
- `manifests/skills.yaml`
- `manifests/plugins.yaml`
- `core/docs/schemas/skills.schema.json`
- `core/docs/schemas/plugins.schema.json`
- Legacy reference:
  `/Users/terry/Project/graysurf/agent-kit/skills/tools/skill-management`

## Recommended Next Artifact

Create a lightweight plan-tracking issue from this source document, then
implement in small slices: governance checks first, create workflow second,
remove workflow third, and nils-cli extraction whenever a stable mutation
contract is required.
