# Project Skill Create Unification Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-25
- Source: user request to evaluate merging `create-claude-project-skill` into
  `create-project-skill`, follow-up request to write the design details with
  `discussion-to-implementation-doc`, and local inspection of current
  `agent-runtime-kit` skill, target, test, and docs surfaces.
- Intended next step: feed this document into a focused implementation plan for
  unifying project-skill creation behavior. This is a source artifact, not an
  implementation plan.
- Source type: discussion-to-implementation-doc

## Execution

- Recommended plan: docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-plan.md
- Recommended execution state: docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-execution-state.md
- Recommended first implementation task: add a shared deterministic
  `create-project-skill` helper and remove the Claude-only command/script
  surfaces.

## Purpose

Project-local skill creation currently has two overlapping creation surfaces:
the shared `meta:create-project-skill` skill and the Claude-only
`create-claude-project-skill` command/script pair. They both operate on the
same canonical `.agents/skills/<skill>/` project source tree, and the Claude
variant's unique behavior is primarily bridge setup through
`.claude/skills -> ../.agents/skills`.

The target design is one canonical project-skill creation workflow:
`create-project-skill`. It should install Codex and Claude exposure by default
for new repo-local skills, while preserving an explicit Codex-only flag and a
bridge-only mode for repos that already have canonical `.agents/skills`
content. Claude-specific command/script surfaces should be removed instead of
kept as aliases.

## Confirmed Facts

- [U1] The user is evaluating whether `create-claude-project-skill` and
  `create-project-skill` should merge because new repo skills should normally
  be installed for both Codex and Claude, and Claude exposure is just a symlink.
- [U2] The user accepted the merge direction and asked to write the design
  details with `discussion-to-implementation-doc`.
- [F1] `docs/plans/<slug>/` is the documented location for coordination plan
  bundles, and plan source filenames should use `<slug>-discussion-source.md`
  when possible. See `docs/source/docs-placement-retention-policy-v1.md:23-34`
  and `docs/source/docs-placement-retention-policy-v1.md:65-70`.
- [F2] Existing project-skill lifecycle scope already treats
  `.agents/skills/<skill>/SKILL.md` as the canonical project-skill source and
  explicitly avoids mutating runtime-kit manifests, product render output, or
  global skill surfaces for consuming-repo project skills. See
  `docs/plans/2026-05-24-project-skill-lifecycle-management/project-skill-lifecycle-management-discussion-source.md:25-30`
  and
  `docs/plans/2026-05-24-project-skill-lifecycle-management/project-skill-lifecycle-management-discussion-source.md:76-88`.
- [F3] The current shared `create-project-skill` source already describes a
  project-local scaffold under `.agents/skills`, optional skill-owned support
  directories, optional `.claude/skills` bridge setup, optional
  `.agents/scripts/<command>.sh` wrappers, collision refusal, and no mutation
  of runtime-kit render/manifests/global homes. See
  `core/skills/meta/create-project-skill/SKILL.md.tera:1-39` and
  `core/skills/meta/create-project-skill/SKILL.md.tera:95-128`.
- [F4] `meta.create-project-skill` already renders as the same managed skill
  name for Codex and Claude. See `manifests/skills.yaml:214-225`.
- [F5] Codex installs the rendered shared skill through the Codex skill link
  map. See `targets/codex/link-map.yaml:117-121`.
- [F6] Claude installs `targets/claude/scripts` and `targets/claude/commands`
  as product-specific surfaces. See `targets/claude/link-map.yaml:135-143`.
- [F7] The Claude-only command advertises a separate
  `create-claude-project-skill` slash surface that wraps
  `scripts/create-claude-project-skill.sh`, creates `.agents/skills/<name>/`,
  creates `.claude/skills -> ../.agents/skills`, updates `.gitignore`, and
  currently creates `.agents/scripts/pre-pr.sh` when missing. See
  `targets/claude/commands/create-claude-project-skill.md:1-13`,
  `targets/claude/commands/create-claude-project-skill.md:55-83`, and
  `targets/claude/scripts/create-claude-project-skill.sh:1-68`.
- [F8] The Claude-only script already contains useful deterministic behavior:
  kebab-case validation with at least one hyphen, git worktree resolution,
  collision refusal, `SKILL.md` and script stub creation, symlink creation,
  `.gitignore` update, `--link-only`, and summary output. See
  `targets/claude/scripts/create-claude-project-skill.sh:107-130`,
  `targets/claude/scripts/create-claude-project-skill.sh:132-254`,
  `targets/claude/scripts/create-claude-project-skill.sh:256-330`, and
  `targets/claude/scripts/create-claude-project-skill.sh:331-365`.
- [F9] Current acceptance already probes the shared project lifecycle skill and
  governance fixture shape, but it does not yet cover unified default-both,
  Codex-only, bridge-only, or removed-surface behavior. See
  `tests/runtime-smoke/acceptance-matrix.yaml:108-118`,
  `tests/runtime-smoke/cases/meta/run.sh:202-214`, and
  `scripts/ci/skill-governance-audit.sh:518-540`.

## Decisions

- [D1] Use `create-project-skill` as the only canonical workflow name for
  project-local skill creation.
- [D2] Preserve `.agents/skills/<skill>/` as the only canonical project-skill
  source path. Do not introduce a separate `.claude/skills/<skill>/` source
  tree for Claude-only creation.
- [D3] Default new project-skill creation to `--target both`, meaning:
  scaffold the canonical `.agents/skills/<skill>/` source and ensure the
  project-local Claude discovery bridge.
- [D4] Add only these creation modes:
  default `both`, explicit `--codex-only`, and explicit `--bridge-only`.
  `--target both|codex` may be accepted as a canonical long-form spelling, but
  `--target claude` and `--claude-only` are not supported.
- [D5] Define `--bridge-only` as the only Claude-only operation. It verifies or
  creates `.claude/skills -> ../.agents/skills` for an existing canonical
  `.agents/skills` tree and must not create a new skill source.
- [D6] Remove `--link-only` instead of carrying it as a deprecated alias. The
  replacement is the clearer `--bridge-only`.
- [D7] Remove `create-claude-project-skill` command/script surfaces instead of
  keeping aliases. The canonical invocation is
  `create-project-skill`.
- [D8] Make `.agents/scripts/pre-pr.sh` creation opt-in, for example
  `--with-pre-pr-stub`. Creating a repo validation dispatcher is useful, but it
  is not inherent to creating one project-local skill.
- [D9] If implementation needs stable dry-run/apply output or reusable JSON
  mutation contracts, extract that behavior to `nils-cli` first and make the
  skill call the released CLI. A shell helper is acceptable only while the
  behavior remains one-skill, file-shape oriented, and not a shared semver
  contract.

## Scope

- Update the shared `create-project-skill` contract and rendered surfaces to
  define default-both creation, `--codex-only`, `--target both|codex`, and
  bridge-only behavior.
- Add a shared helper owned by `core/skills/meta/create-project-skill/`, with
  product-neutral behavior and macOS Bash 3.2 compatibility if implemented in
  shell.
- Move reusable behavior from the Claude-only helper into the shared helper:
  argument parsing, project root detection, name validation, collision checks,
  skill stub creation, optional script stub creation, Claude bridge handling,
  `.gitignore` handling, and summary output.
- Remove `targets/claude/commands/create-claude-project-skill.md` and
  `targets/claude/scripts/create-claude-project-skill.sh`, plus any target,
  support-matrix, docs, or fixture references that keep the old Claude-only
  surface alive.
- Extend acceptance fixtures and governance checks to cover the new flag matrix
  and removed-surface path.

## Non-Scope

- Do not change the repo-managed `create-skill` or `remove-skill` workflows.
- Do not change `remove-project-skill`, except for any references needed to
  keep create/remove lifecycle docs consistent.
- Do not add project-local skills to `manifests/skills.yaml`,
  `manifests/plugins.yaml`, product render output, sandbox expected skill
  lists, or live global runtime homes for consuming repositories.
- Do not revive `$HOME/.agents` as a global discovery alias.
- Do not make `.agents/scripts/pre-pr.sh` mandatory for project-skill
  creation.
- Do not delete historical plan records as part of this merge.

## Implementation Boundaries

- The shared helper runs from the target consuming repo's git worktree, not
  necessarily from the `agent-runtime-kit` checkout.
- The helper must resolve the target root with
  `git rev-parse --show-toplevel` and fail clearly outside a worktree.
- The helper must refuse path traversal, malformed names, ambiguous target
  flags, and existing target paths unless explicit replacement semantics are
  later designed and approved.
- The helper must not read or write credentials, auth files, session state,
  caches, runtime logs, or unrelated runtime homes.
- The helper should be deterministic enough for fixture tests, but human
  editing of generated `SKILL.md` content remains part of the workflow.
- The `create-project-skill` skill body remains the natural-language workflow
  owner; helper scripts are entrypoints, not replacements for the skill
  contract.

## Target CLI Shape

Canonical helper:

```text
create-project-skill.sh <skill-name> [options]
create-project-skill.sh --bridge-only [options]

Options:
  --description TEXT
  --target both|codex
  --codex-only
  --with-script
  --with-tests
  --with-references
  --with-fixtures
  --with-bin
  --with-wrapper COMMAND
  --with-pre-pr-stub
  --bridge-only
  --dry-run
  --help
```

Flag rules:

- `--target both` is the default.
- `--codex-only` is shorthand for `--target codex`.
- `--target claude` and `--claude-only` are usage errors.
- `--bridge-only` does not scaffold a new skill. It verifies or creates only
  the Claude bridge and `.gitignore` entry for an existing `.agents/skills`
  tree.
- `--with-pre-pr-stub` is independent from `--with-wrapper COMMAND`.

## Output Matrix

| Mode | Canonical source | Claude bridge | Wrapper | pre-pr stub |
| --- | --- | --- | --- | --- |
| default / `--target both` | create `.agents/skills/<skill>/SKILL.md` and requested support folders | create or verify `.claude/skills -> ../.agents/skills` and `.gitignore` | only with `--with-wrapper` | only with `--with-pre-pr-stub` |
| `--codex-only` | create `.agents/skills/<skill>/SKILL.md` and requested support folders | no `.claude` mutation | only with `--with-wrapper` | only with `--with-pre-pr-stub` |
| `--bridge-only` | do not create; verify existing `.agents/skills` source | create or verify `.claude/skills -> ../.agents/skills` and `.gitignore` | optional, but must delegate to existing source | only with `--with-pre-pr-stub` |

## Removal Plan

- Delete the Claude-only slash command file:
  `targets/claude/commands/create-claude-project-skill.md`.
- Delete the Claude-only script:
  `targets/claude/scripts/create-claude-project-skill.sh`.
- Update target/support-matrix docs, fixtures, and tests that mention
  `create-claude-project-skill` or `--link-only`.
- Keep the product-level `targets/claude/commands` and `targets/claude/scripts`
  link-map entries only if other Claude target surfaces still need them.
- Fail fast on old invocations by absence of the old command/script; do not add
  a compatibility wrapper.

## Requirements

- `create-project-skill` must create a project-local skill for both Codex and
  Claude by default.
- The canonical project-local skill source must remain
  `.agents/skills/<skill>/SKILL.md`.
- Claude exposure must be implemented through `.claude/skills ->
  ../.agents/skills` unless a consuming project already has a compatible local
  convention.
- Generated `SKILL.md` must include front matter, H1, Contract, entrypoint or
  scripts section, Workflow, and Boundary placeholders.
- Generated shell scripts must be executable and pass shell syntax checks.
- The helper must reject unsupported flag combinations, such as
  `--target claude`, `--claude-only`, `--link-only`, `--codex-only` with
  `--target both`, or `--bridge-only` with a request to create a new source
  tree.
- The helper must report created, verified, skipped, and refused paths
  separately.
- The helper must support dry-run output before apply if the implementation
  introduces more than simple local file creation, or if fixtures need a stable
  machine-readable plan.

## Acceptance Criteria

- Shared `create-project-skill` source documents default `both`,
  `--codex-only`, `--target both|codex`, and `--bridge-only` behavior.
- Default creation fixture proves that a new skill creates canonical
  `.agents/skills/<skill>/SKILL.md`, requested support folders, and the Claude
  bridge.
- Codex-only fixture proves no `.claude` path is created or changed.
- Claude bridge-only fixture proves the helper can add or verify
  `.claude/skills -> ../.agents/skills` for an existing `.agents/skills` tree
  without creating a duplicate skill.
- Removal fixture or reference audit proves `create-claude-project-skill` and
  `--link-only` are no longer active command/script/test surfaces.
- `.agents/scripts/pre-pr.sh` is not created by default in any fixture.
- `--with-pre-pr-stub` fixture proves the pre-pr stub remains available when
  explicitly requested.
- Governance and runtime-smoke checks cover the unified workflow and fail if
  independent scaffold logic remains in a Claude-only helper.
- Rendered Codex and Claude golden outputs are updated and match the shared
  source.

## Validation Plan

- Preflight:
  - `agent-docs resolve --context startup --strict --format checklist`
  - `agent-docs resolve --context skill-dev --strict --format checklist`
  - `agent-docs resolve --context project-dev --strict --format checklist`
- Focused implementation checks:
  - `bash scripts/ci/skill-governance-audit.sh --fixture create-project`
  - targeted runtime-smoke case for `meta.create-project-skill`
  - shell syntax checks for generated shared scripts
  - reference audit proving old Claude-only command/script surfaces are gone
  - render/golden update and diff review for Codex and Claude products
- Full delivery check:
  - `bash scripts/ci/all.sh`

## Risks And Guardrails

- Claude-only create is the main semantic trap. The accepted design removes it
  entirely. Claude-only work is limited to `--bridge-only` over an existing
  `.agents/skills` tree.
- A default-both workflow mutates `.claude/` for new repo skills. This is
  intended, but it must remain limited to the symlink and `.gitignore` entry.
- The current Claude helper creates `.agents/scripts/pre-pr.sh` by default.
  Keeping that default would couple unrelated repo validation setup to skill
  creation and surprise users.
- Removing the Claude command immediately is an intentional breaking cleanup.
  The implementation must update all repo-managed references in the same
  change so the break is clear and searchable.
- If the helper grows JSON output, stable dry-run/apply planning, reference
  graphs, or behavior consumed by other skills, move the primitive to
  `nils-cli` before treating it as a shared runtime contract.

## Resolved Decisions

- Remove `/create-claude-project-skill` directly. Do not keep a compatibility
  window or alias.
- Remove `--target claude`, `--claude-only`, and `--link-only` directly. The
  only Claude-specific operation is `--bridge-only` for an existing canonical
  `.agents/skills` tree.
- Use plain-text dry-run and summary output in v1. Defer a `nils-cli` JSON
  primitive until another workflow needs a shared machine-readable contract.
- Do not block this merge on `agent-runtime doctor --check-project` bridge
  validation. Track that as a follow-up product diagnostic only if needed.

## Read-First References

- `docs/source/docs-placement-retention-policy-v1.md`
- `docs/plans/2026-05-24-project-skill-lifecycle-management/project-skill-lifecycle-management-discussion-source.md`
- `core/skills/meta/create-project-skill/SKILL.md.tera`
- `targets/claude/commands/create-claude-project-skill.md`
- `targets/claude/scripts/create-claude-project-skill.sh`
- `manifests/skills.yaml`
- `targets/codex/link-map.yaml`
- `targets/claude/link-map.yaml`
- `tests/runtime-smoke/acceptance-matrix.yaml`
- `tests/runtime-smoke/cases/meta/run.sh`
- `scripts/ci/skill-governance-audit.sh`

## Recommended Next Artifact

Create
`docs/plans/2026-05-25-project-skill-create-unification/project-skill-create-unification-plan.md`
from this source document, then implement as a narrow skill lifecycle change
with fixture-backed validation.

## Retention Intent

This document is coordination material under `docs/plans/`. Revisit after
execution: delete it if the final plan and implemented docs supersede it, or
promote only the durable product-target semantics into the owning skill or
source docs.
