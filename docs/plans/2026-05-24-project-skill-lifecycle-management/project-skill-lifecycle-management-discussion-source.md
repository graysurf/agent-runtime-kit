# Project Skill Lifecycle Management Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-24
- Source: user request to add `create-project-skill` and
  `remove-project-skill`, follow-up discussion after the repo-owned
  `create-skill` / `remove-skill` workflow landed, and local inspection of
  `nils-cli` project-local skills.
- Intended next step: feed this document into a plan for implementing
  project-local skill lifecycle workflows. This is a source artifact, not an
  implementation plan.

## Execution

- Recommended plan: docs/plans/2026-05-24-project-skill-lifecycle-management/project-skill-lifecycle-management-plan.md
- Recommended execution state: docs/plans/2026-05-24-project-skill-lifecycle-management/project-skill-lifecycle-management-execution-state.md

## Purpose

`agent-runtime-kit` now has repo-managed lifecycle workflows for adding and
removing runtime-kit skills. Those workflows intentionally do not cover
project-level skills because the path model, validation surface, and product
activation behavior are different.

The next useful capability is a separate project-local lifecycle pair:
`create-project-skill` and `remove-project-skill`. These workflows should help
agents scaffold and remove skills that belong to the current consuming project,
using the `.agents/skills/<skill>/` convention already present in `nils-cli`,
without mutating runtime-kit manifests, product render output, or global skill
surfaces.

## Confirmed Facts

- [U1] The user asked to implement `create-project-skill` and
  `remove-project-skill`, starting with a `discussion-to-implementation-doc`
  artifact.
- [F1] The current `create-skill` contract is explicitly scoped to repo-owned
  managed skills and says the request is not a project-local overlay. It writes
  `core/skills/<domain>/<skill>/SKILL.md.tera`, manifest entries, rendered
  output, golden snapshots, sandbox expected skills, runtime-smoke coverage,
  and reminder metadata when appropriate.
- [F2] The current `remove-skill` contract is also repo-managed. It requires a
  target in `manifests/skills.yaml`, performs a dry-run reference inventory,
  removes runtime-kit source/manifest/render/test surfaces after approval, and
  validates no active references remain.
- [F3] The prior lifecycle plan deferred `create-project-skill` because
  project-local `.agents/skills` scaffolding needed a separate design pass.
- [F4] The governance audit currently fails if `create-project-skill` appears
  in exact-only reminder metadata, because that workflow was intentionally
  deferred in the repo-managed lifecycle phase.
- [F5] `DEVELOPMENT.md` identifies `tests/projects/` as stable
  project-local overlay smoke fixtures and includes
  `bash tests/projects/project-local-smoke/run.sh` as position 10 in the full
  CI gate.
- [F6] The current project-local smoke fixture covers `.agents/scripts` shims
  for `bench`, `bootstrap`, `demo`, `deploy`, `pre-pr`, and `release`; it does
  not yet cover `.agents/skills`.
- [F7] `agent-runtime doctor --check-project` currently inspects a consuming
  repo's `.agents/scripts/` project-local overlays and the nils-cli probe list
  is limited to `bench`, `bootstrap`, `demo`, `deploy`, `pre-pr`, and
  `release`.
- [F8] `nils-cli` has real project-local skills under
  `.agents/skills/<skill>/SKILL.md`, with optional skill-owned `scripts/`,
  `tests/`, and `references/` directories.
- [F9] `nils-cli` documents a multi-CLI mirror pattern: Codex/opencode discover
  work through `.agents/skills/`, while Claude Code can reach the same logic
  through thin command wrappers.
- [F10] This repo already ships a Claude target helper,
  `targets/claude/scripts/create-claude-project-skill.sh`, that scaffolds
  `.agents/skills/<name>/` and bridges Claude discovery through
  `.claude/skills -> ../.agents/skills`. A `--link-only` mode wires up only
  the bridge for repos whose `.agents/skills/` already exists.

## Decisions

- [D1] Add project-level lifecycle as a separate pair:
  `create-project-skill` and `remove-project-skill`. Do not broaden the
  existing repo-managed `create-skill` / `remove-skill` semantics.
- [D2] Treat `.agents/skills/<skill>/SKILL.md` as the canonical project-skill
  source path. Optional skill-owned support folders may include `scripts/`,
  `tests/`, `references/`, `fixtures/`, or `bin/` when needed.
- [D3] Do not mutate `manifests/skills.yaml`, `manifests/plugins.yaml`,
  `targets/`, `build/`, `tests/golden/`, or sandbox expected skill lists for
  project-local skills.
- [D4] Support optional Claude exposure through `.claude/skills ->
  ../.agents/skills` and optional slash-command wrappers through
  `.agents/scripts/<command>.sh` only when requested or when the project's
  existing local convention requires it.
- [D5] Keep removal dry-run-first. `remove-project-skill` should inventory
  active references and present the planned delta before mutation unless the
  active plan already grants apply approval.
- [D6] Preserve historical `docs/plans/**` references by default. Only clean
  durable history when explicitly requested.
- [D7] Extend validation around project-local skill shape before adding
  reminder metadata. A project-local lifecycle workflow should not advertise
  itself as accepted until fixture coverage proves both create and remove
  paths.
- [D8] If project-skill creation/removal needs stable machine-readable plans,
  reference graphs, JSON contracts, or reusable mutation logic, extract that
  deterministic behavior to `nils-cli` and have runtime-kit skills call the
  released command.

## Scope

- Add a `create-project-skill` workflow that scaffolds a project-owned skill in
  a consuming repository.
- Add a `remove-project-skill` workflow that safely removes a project-owned
  skill and any approved project-local command wrapper.
- Define the project-skill file layout, naming rules, collision checks,
  optional support folders, and validation expectations.
- Add runtime-kit acceptance coverage using a fixture under `tests/projects/`
  that models `.agents/skills`.
- Decide whether `agent-runtime doctor --check-project` should learn a
  project-skill check or whether this remains skill-level validation.

## Non-Scope

- Changing the repo-managed `create-skill` / `remove-skill` contract.
- Reintroducing `$HOME/.agents` as a live global indirection.
- Adding project-local skills to runtime-kit product manifests or render
  output.
- Creating a broad project plugin registry for arbitrary repositories.
- Rewriting existing `nils-cli` project skills unless they are used as
  fixtures or reference examples.
- Implementing plan/task sequencing in this source document.

## Implementation Boundaries

- `create-project-skill` runs from the target project root, not necessarily
  from the `agent-runtime-kit` source root.
- The workflow should resolve the target project root through `git rev-parse
  --show-toplevel` when possible and fail with an actionable message outside a
  project.
- The minimum project skill artifact is:

  ```text
  .agents/skills/<skill-name>/SKILL.md
  ```

- Optional artifacts are created only when requested or implied by the skill's
  workflow:

  ```text
  .agents/skills/<skill-name>/scripts/
  .agents/skills/<skill-name>/tests/
  .agents/skills/<skill-name>/references/
  .agents/skills/<skill-name>/fixtures/
  .agents/skills/<skill-name>/bin/
  .claude/skills -> ../.agents/skills
  .agents/scripts/<command>.sh
  ```

- Skill names should be lowercase, hyphenated, filesystem-safe, and unique
  under `.agents/skills/`.
- `SKILL.md` should use the same basic contract shape as existing skills:
  front matter, H1, Contract, Entrypoint or Scripts, Workflow, and Boundary.
- The Claude bridge, when present, should either expose `.agents/skills`
  through `.claude/skills -> ../.agents/skills` or use a thin wrapper that
  delegates to the skill-owned script or another canonical project command. The
  bridge must not duplicate the skill's implementation logic.
- Project-local validation should prefer project-owned checks when available;
  otherwise it should run focused structural checks, shell syntax checks for
  generated scripts, and reference inventory checks.

## Requirements

- `create-project-skill` requires:
  - target project root
  - skill name
  - description
  - intended consumer surface: Codex/opencode `.agents/skills`, optional Claude
    `.claude/skills` bridge, optional `.agents/scripts` wrapper, or both
  - optional script/test/reference folders
  - explicit approval before overwriting or replacing any existing path
- `remove-project-skill` requires:
  - target project root
  - skill name
  - dry-run inventory before mutation
  - explicit approval for deleting support folders and command wrappers
  - clear retention rule for docs/history references
- Both workflows should fail on ambiguous names, missing project roots,
  collisions with existing project files, unsupported path traversal, or
  remaining active references after apply.
- Both workflows should avoid global runtime homes and must not read or write
  credentials, auth files, session state, caches, or unrelated local runtime
  state.

## Acceptance Criteria

- `create-project-skill` can create a fixture project skill under
  `.agents/skills/example-project-skill/SKILL.md` with optional `scripts/` and
  `tests/` and passes focused validation.
- When a Claude bridge is requested, the workflow creates or verifies
  `.claude/skills -> ../.agents/skills`; when a command wrapper is requested,
  it creates an executable `.agents/scripts/<command>.sh` wrapper that
  dispatches to the canonical project-skill script.
- `remove-project-skill` dry-run reports the target skill directory, optional
  wrapper, active references, and retained historical references separately.
- `remove-project-skill` apply removes only approved active paths and fails if
  active references remain outside the allowed historical set.
- Project-local smoke coverage includes `.agents/skills` shape checks in
  addition to the existing `.agents/scripts` shim checks.
- Reminder metadata for `create-project-skill` and `remove-project-skill` is
  added only after the workflow surfaces and acceptance coverage exist.
- Full validation for the implementation passes `bash scripts/ci/all.sh`.

## Validation Plan

- Run the mandatory preflight before implementation:
  - `agent-docs resolve --context startup --strict --format checklist`
  - `agent-docs resolve --context skill-dev --strict --format checklist`
- Add or extend fixture coverage under `tests/projects/`.
- Run focused checks while developing:
  - `bash tests/projects/project-local-smoke/run.sh`
  - targeted runtime-smoke cases for the `meta` domain if workflow skills are
    added there
  - `bash scripts/ci/skill-governance-audit.sh`
- Run render and golden checks if runtime-kit skills are added:
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
- Run the full gate before delivery:
  - `bash scripts/ci/all.sh`

## Risks And Guardrails

- Project-local skills are intentionally project-owned. Guard against
  accidentally treating them as managed runtime-kit skills.
- The `.agents` path is still useful as a project-local convention, but it
  must not revive `$HOME/.agents` as a global discovery alias.
- Claude and Codex discovery are not identical. Keep the `.claude/skills`
  bridge and command wrappers explicit instead of assuming both products
  discover the same files.
- Avoid broad reference deletion. Historical plan records should stay intact
  unless the user explicitly requests archival cleanup.
- Do not add reminder metadata before the workflow is actually implemented and
  validated; otherwise agents may invoke a non-existent or partial workflow.

## Open Questions

- Should project-skill validation live entirely in the workflow skill, or
  should `agent-runtime doctor --check-project` grow `.agents/skills` probes?
- Should `create-project-skill` support a structured dry-run/apply mode in v1,
  or is a checklist-oriented workflow enough for the first implementation?
- Should Claude bridge creation be opt-in by default, or should it be inferred
  when the project already has `.claude/skills` or `.agents/scripts/`
  dispatcher conventions?
- Should project-skill naming allow product or repo prefixes, such as
  `nils-cli-*`, or should the workflow only require generic lowercase
  hyphenated names?

## Read-First References

- `core/skills/meta/create-skill/SKILL.md.tera`
- `core/skills/meta/remove-skill/SKILL.md.tera`
- `docs/plans/2026-05-24-skill-lifecycle-management/skill-lifecycle-management-discussion-source.md`
- `docs/plans/2026-05-24-skill-lifecycle-management/skill-lifecycle-management-plan.md`
- `tests/projects/project-local-smoke/README.md`
- `tests/projects/project-local-smoke/run.sh`
- `/Users/terry/Project/sympoies/nils-cli/.agents/skills/`
- `/Users/terry/Project/sympoies/nils-cli/crates/agent-runtime-cli/src/doctor/project.rs`

## Recommended Next Artifact

Create `docs/plans/2026-05-24-project-skill-lifecycle-management/project-skill-lifecycle-management-plan.md`
from this source document, then implement the workflow as a focused follow-up
to the repo-managed skill lifecycle work.
