# Plan: Phase 1 — Skeleton, Manifests, CLI Stubs

## Overview

Land the Phase 1 foundation for the agent-runtime-kit migration. The
end-state is a tracked source-of-truth bundle in this repo (skeleton
directories, baseline `.gitignore`, drift allowlist seed, Bump Ceremony
PR template), the five `manifests/*.yaml` source files at
`schema_version: 1` with empty content lists, a stubbed `agent-runtime`
binary opened inside `sympoies/nils-cli` and shipped as part of the
`v0.12.0` coupled-workspace release through `sympoies/homebrew-tap`, and a host bootstrap skeleton plus a
frozen nils-cli surface snapshot under `docs/source/`.

This plan deliberately ships no render, install, or drift-audit body.
Plan 02 (`02-nils-cli-render-and-drift-audit`) implements
`agent-runtime render` + `agent-runtime audit-drift` against the
manifest schemas pinned in Sprint 2 here, and bumps the formula in
`sympoies/homebrew-tap` once a `0.1.0` release ships. Plans 03–05
depend transitively on this scaffolding.

Sprint 3 is explicitly cross-repo. Tasks in that sprint name the owning
repo (`sympoies/nils-cli`, `sympoies/homebrew-tap`, or this repo) in
their Description so reviewers do not assume in-tree work.

## Read First

- Primary source: docs/plans/01-skeleton-and-schema/01-skeleton-and-schema-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - Final pin values for `required_clis` — this plan only declares the
    literal `<TBD: pin during Phase 1>` placeholder per Manifest Layer
    rules; concrete `">=X.Y.Z"` values are a Plan 02 / Plan 03 gate
    once nils-cli `0.1.0` ships through the tap.
  - Whether `core/policies/cli-tools.md` carries every formula listed
    in the legacy `$HOME/.config/agent-kit/CLI_TOOLS.md` or only the
    current `core` profile. Default for this plan: import the full
    catalog and let the `core` / `recommended` / `full` profile split
    happen in `manifests/cli-tools.yaml`. Revisitable in Plan 04.

## Scope

- In scope:
  - Top-level skeleton directories: `core/`, `targets/codex/`,
    `targets/claude/`, `manifests/`, `build/` (gitignored), `scripts/`,
    `tests/golden/`, `tests/drift/`, `tests/hooks/`, `tests/install/`,
    `tests/sandbox/`, `tests/projects/`.
  - Top-level `.gitignore` matching the baseline list in the source
    architecture doc.
  - Tracked `drift-audit.allow.yaml` seed (`schema_version: 1`, empty
    `unsafe_allow: []`).
  - Bump Ceremony PR template at
    `.github/PULL_REQUEST_TEMPLATE/min-version-bump.md`.
  - JSON Schema documents for each manifest under
    `core/docs/schemas/`.
  - The five manifest YAML source files under `manifests/` with
    `schema_version: 1` and minimal valid content (empty skill /
    plugin lists; only `cli-tools.yaml` and `product-capabilities.yaml`
    carry concrete content per the architecture doc examples).
  - `core/policies/cli-tools.md` migrated from
    `$HOME/.config/agent-kit/CLI_TOOLS.md` when present, otherwise a
    schema-mirroring placeholder.
  - Cross-repo stub crate at
    `sympoies/nils-cli/crates/agent-runtime-cli/` with the eight
    subcommands enumerated by Resolved Decision #2 (`render`, `install`,
    `uninstall`, `doctor`, `audit-drift`, `gc-backups`,
    `restore-backups`, `purge-state`), each printing
    `agent-runtime <subcommand>: not implemented` and exiting 1.
    `--version` returns `0.12.0`.
  - Cross-repo formula bump in `sympoies/homebrew-tap` so
    `brew install sympoies/tap/nils-cli` resolves the stub release.
  - `scripts/setup.sh` skeleton (OS detect via `brew --prefix`, profile
    parsing, brew tap + install, clone-on-missing, stubbed
    `agent-runtime install` calls).
  - `docs/source/nils-cli-surface.md` snapshot of the current
    `~/Project/sympoies/nils-cli/crates/` listing and
    `git describe --tags`.
- Out of scope:
  - `agent-runtime render`, `agent-runtime audit-drift`, or
    `agent-runtime install` subcommand bodies. (Plan 02 / Plan 04.)
  - Any concrete entry under `skills:` or `plugins:` in the YAML
    manifests. (Plan 03.)
  - Render-golden CI gate hookup, drift-audit CI gate. (Plan 02.)
  - Migration of any skill body from `agent-kit` or `claude-kit`.
    (Plan 03 onward.)
  - Bumping `required_clis` from `<TBD: pin during Phase 1>` to a
    concrete semver range. (Plan 02.)
  - Anything under `build/` (gitignored; never committed).

## Assumptions

1. The current architecture doc at
   `docs/source/inventory-target-architecture.md` is treated as
   frozen for the life of this plan. Any architectural change requires
   amending the source doc first, then re-running this plan.
2. `$HOME/.config/agent-kit/CLI_TOOLS.md` exists on the development
   host (verified during planning); migration in Sprint 2 reads from
   that path. If missing, Task 2.6 falls back to writing a
   schema-mirroring placeholder and logs a follow-up in the open
   questions block.
3. The development host has `~/Project/sympoies/nils-cli/` cloned with
   write access; Sprint 3's snapshot work and stub crate work both run
   against that clone.
4. `sympoies/homebrew-tap` exists with at least one formula
   (`nils-cli.rb`); Sprint 3 bumps the version pin rather than
   bootstrapping a new tap.
5. `plan-tooling` is on PATH (verified by running
   `plan-tooling spec | head` during planning) so the validation gate
   below is executable.
6. No live `~/.codex` or `~/.claude` mutation happens in this plan.
   The stub binary exits 1 on every subcommand, which is enough to
   verify the install ladder but not enough to disturb production
   homes.

## Sprint 1: Repo skeleton and baseline files

**Goal**: Land the directory tree, the baseline `.gitignore`, the
drift-allowlist seed, and the Bump Ceremony PR template so every
subsequent sprint has a stable place to write files.

**Demo/Validation**:

- Command(s):
  - `ls -d core targets/codex targets/claude manifests scripts tests/golden tests/drift tests/hooks tests/install tests/sandbox tests/projects`
  - `grep -F 'build/' .gitignore && grep -F '.private/' .gitignore`
  - `grep -F 'schema_version: 1' drift-audit.allow.yaml`
  - `test -f .github/PULL_REQUEST_TEMPLATE/min-version-bump.md`
- Verify: every listed directory exists; `.gitignore` includes every
  entry from the architecture doc's baseline list; the drift allowlist
  carries `schema_version: 1` and an empty `unsafe_allow: []`; the PR
  template enumerates the four sections required by Resolved
  Decision #7.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 1.1: Create top-level skeleton directories

- **Location**:
  - `core/.gitkeep`
  - `targets/codex/.gitkeep`
  - `targets/claude/.gitkeep`
  - `manifests/.gitkeep`
  - `scripts/.gitkeep`
  - `tests/golden/.gitkeep`
  - `tests/drift/.gitkeep`
  - `tests/hooks/.gitkeep`
  - `tests/install/.gitkeep`
  - `tests/sandbox/.gitkeep`
  - `tests/projects/.gitkeep`
- **Description**: Create the directory tree the rest of the plan
  writes into. Each directory gets a `.gitkeep` file so git tracks the
  empty structure. `build/` is NOT created here — it is generated by
  `agent-runtime render` in Plan 02 and is already covered by the
  `.gitignore` entry written in Task 1.2.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - All eleven directories exist relative to the repo root.
  - Each directory contains a `.gitkeep` file.
  - `git status` shows the new directories as untracked / staged.
- **Validation**:
  - `ls -d core targets/codex targets/claude manifests scripts tests/golden tests/drift tests/hooks tests/install tests/sandbox tests/projects`
  - `find core targets manifests scripts tests -type f -name .gitkeep | wc -l`

### Task 1.2: Write top-level `.gitignore`

- **Location**:
  - `.gitignore`
- **Description**: Write the baseline `.gitignore` enumerated in
  `docs/source/inventory-target-architecture.md` §Secrets And Sensitive
  Data → Baseline `.gitignore`. The exact entries to land are
  `build/`, `*.local.*`, `.env`, `.env.*`, `secrets/`,
  `secrets.*.yaml`, `auth.json`, `.credentials*`, `**/sessions/`,
  `**/history/`, `**/cache/`, and `.private/`. Preserve the order as
  written in the source doc. No additional entries — repo-specific
  additions are out of scope for this plan.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 1
- **Acceptance criteria**:
  - `.gitignore` contains every entry from the baseline list.
  - Order matches the source doc.
  - File ends with a newline.
- **Validation**:
  - `grep -Fxq 'build/' .gitignore`
  - `grep -Fxq '.private/' .gitignore`
  - `grep -Fxq '**/sessions/' .gitignore`
  - `wc -l .gitignore`

### Task 1.3: Seed `drift-audit.allow.yaml`

- **Location**:
  - `drift-audit.allow.yaml`
- **Description**: Write the tracked drift-audit allowlist seed the
  Drift Detection composite-score model in the architecture doc
  expects. The seed carries `schema_version: 1` and `unsafe_allow: []`
  (empty list). Real entries land in later plans when concrete drift
  findings need to be demoted. Add a short top-of-file comment naming
  the demote-by-one-tier semantics and pointing at the §Drift
  Detection section.
- **Dependencies**:
  - none
- **Complexity**: 1
- **Acceptance criteria**:
  - File parses as YAML.
  - `schema_version` equals `1`.
  - `unsafe_allow` is an empty list.
  - File header comment links back to the source architecture doc.
- **Validation**:
  - `python3 -c "import yaml; d=yaml.safe_load(open('drift-audit.allow.yaml')); assert d['schema_version']==1 and d['unsafe_allow']==[], d"`

### Task 1.4: Write Bump Ceremony PR template

- **Location**:
  - `.github/PULL_REQUEST_TEMPLATE/min-version-bump.md`
- **Description**: Write the PR template referenced by Resolved
  Decision #7. The template MUST contain four sections — Impacted
  Environments, Tested Version Combinations, Rollback Path, Team
  Notice Timestamp — each as an H2 heading with a short prose
  explanation and a checklist of items the author must fill in.
  Include a header note that this template is reminder-shaped, not a
  required CI check, matching the source doc wording.
- **Dependencies**:
  - Task 1.1
- **Complexity**: 2
- **Acceptance criteria**:
  - File exists at `.github/PULL_REQUEST_TEMPLATE/min-version-bump.md`.
  - Contains the four required H2 sections.
  - References Resolved Decision #7 or the architecture doc by title.
  - Mentions the 24–48 h advance notice from the source doc.
- **Validation**:
  - `grep -E '^## Impacted Environments' .github/PULL_REQUEST_TEMPLATE/min-version-bump.md`
  - `grep -E '^## Tested Version Combinations' .github/PULL_REQUEST_TEMPLATE/min-version-bump.md`
  - `grep -E '^## Rollback Path' .github/PULL_REQUEST_TEMPLATE/min-version-bump.md`
  - `grep -E '^## Team Notice Timestamp' .github/PULL_REQUEST_TEMPLATE/min-version-bump.md`

## Sprint 2: Manifest schemas and source files

**Goal**: Write the five manifest source YAML files and their JSON
schema documents so Plan 02's `agent-runtime render` body has a stable
contract to validate against. No skill or plugin entries are populated
here — Plan 03 owns that. Manifest schema validator + render-golden CI
gate hookup are explicitly deferred to Plan 02.

**Demo/Validation**:

- Command(s):
  - `ls manifests/skills.yaml manifests/plugins.yaml manifests/product-capabilities.yaml manifests/runtime-roots.yaml manifests/cli-tools.yaml`
  - `ls core/docs/schemas/skills.schema.json core/docs/schemas/plugins.schema.json core/docs/schemas/product-capabilities.schema.json core/docs/schemas/runtime-roots.schema.json core/docs/schemas/cli-tools.schema.json`
  - `python3 -c 'import json,glob; [json.load(open(p)) for p in glob.glob("core/docs/schemas/*.json")]'`
  - `python3 -c 'import yaml,glob; [yaml.safe_load(open(p)) for p in sorted(glob.glob("manifests/*.yaml"))]'`
- Verify: every YAML file parses, every JSON schema file parses, every
  YAML file carries `schema_version: 1`, and no schema file lists a
  field that the YAML examples do not declare.

**PR grouping intent**: group
**Execution Profile**: parallel-x2

### Task 2.1: Write `skills.yaml` schema and source file

- **Location**:
  - `core/docs/schemas/skills.schema.json`
  - `manifests/skills.yaml`
- **Description**: Write a JSON Schema document describing the
  `skills.yaml` shape from §Manifest Layer (top-level
  `schema_version: <int>` and a `skills:` list whose entries carry
  `id`, `domain`, `source`, `products`, `required_clis`,
  `state_out_mode`, optional `aliases`, optional `divergent`, and
  optional per-product `path_override`). Then write
  `manifests/skills.yaml` with `schema_version: 1` and an empty
  `skills: []` list. Add a top-of-file comment noting that real skill
  entries land in Plan 03 and that any literal `<TBD: pin during
  Phase 1>` in a `required_clis` field is a Phase 1 gate failure when
  Plan 02 enables the validator.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - JSON schema parses as JSON and declares `schema_version` required.
  - YAML file parses and `schema_version` equals `1`.
  - YAML `skills` key exists and resolves to an empty list.
  - Header comment names Plan 03 and the `<TBD>` rule.
- **Validation**:
  - `python3 -c "import json; json.load(open('core/docs/schemas/skills.schema.json'))"`
  - `python3 -c "import yaml; d=yaml.safe_load(open('manifests/skills.yaml')); assert d['schema_version']==1 and d['skills']==[], d"`

### Task 2.2: Write `plugins.yaml` schema and source file

- **Location**:
  - `core/docs/schemas/plugins.schema.json`
  - `manifests/plugins.yaml`
- **Description**: Write the JSON Schema for `plugins.yaml` reflecting
  §Manifest Layer (`schema_version`, `plugins:` list with `id`,
  `domain`, `contained_skills`, `product_manifests`, `dependencies`,
  `install_policy`). Write `manifests/plugins.yaml` with
  `schema_version: 1` and an empty `plugins: []`. Add the same
  header comment style as Task 2.1 referencing Plan 03.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - JSON schema parses and declares `plugins` as an array.
  - YAML parses; `schema_version` equals `1`; `plugins` is empty.
  - Header comment names Plan 03.
- **Validation**:
  - `python3 -c "import json; json.load(open('core/docs/schemas/plugins.schema.json'))"`
  - `python3 -c "import yaml; d=yaml.safe_load(open('manifests/plugins.yaml')); assert d['schema_version']==1 and d['plugins']==[], d"`

### Task 2.3: Write `product-capabilities.yaml` schema and source file

- **Location**:
  - `core/docs/schemas/product-capabilities.schema.json`
  - `manifests/product-capabilities.yaml`
- **Description**: Write the JSON Schema for
  `product-capabilities.yaml` describing the per-product capability
  matrix from §Manifest Layer (nested skill support, plugin manifest
  schema, hooks model, config activation, runtime state boundaries,
  and the field-level diff between `.codex-plugin/plugin.json` and
  `.claude-plugin/plugin.json`). Write `manifests/product-capabilities.yaml`
  with `schema_version: 1` and a `products:` block populated with the
  two known products (`codex` and `claude`) carrying their current
  capability flags as documented in the architecture doc. This file
  is NOT empty — the capability matrix is settled architecture, not
  Plan 03 work.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - JSON schema parses and declares `products` as an object with
    `codex` and `claude` sub-keys.
  - YAML parses; `schema_version` equals `1`; `products` includes
    `codex` and `claude` entries.
  - Capability values match the architecture doc (no invention).
- **Validation**:
  - `python3 -c "import json; json.load(open('core/docs/schemas/product-capabilities.schema.json'))"`
  - `python3 -c "import yaml; d=yaml.safe_load(open('manifests/product-capabilities.yaml')); assert d['schema_version']==1 and set(d['products'].keys())>={'codex','claude'}, d"`

### Task 2.4: Write `runtime-roots.yaml` schema and source file

- **Location**:
  - `core/docs/schemas/runtime-roots.schema.json`
  - `manifests/runtime-roots.yaml`
- **Description**: Write the JSON Schema for `runtime-roots.yaml`
  reflecting §Runtime Root Model and Resolved Decision #7
  (`schema_version`, per-product `command_root`, `config_path`,
  `state_home`, `min_version`, `recommended_version`,
  `min_version_effective_from`, `version_probe`). Write
  `manifests/runtime-roots.yaml` with `schema_version: 1` and both
  `codex` and `claude` entries populated using the values from the
  architecture doc. Leave `min_version` / `recommended_version` /
  `min_version_effective_from` as the literal placeholder string
  `<TBD: pin during Phase 1>` per the architecture doc wording — Plan
  02 pins concrete values once a development host snapshot is taken.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - JSON schema parses; declares `schema_version` and per-product
    fields.
  - YAML parses; `schema_version` equals `1`.
  - Both `codex` and `claude` blocks present.
  - Version pin fields carry the `<TBD: pin during Phase 1>`
    placeholder verbatim.
- **Validation**:
  - `python3 -c "import json; json.load(open('core/docs/schemas/runtime-roots.schema.json'))"`
  - `python3 -c "import yaml; d=yaml.safe_load(open('manifests/runtime-roots.yaml')); assert d['schema_version']==1 and 'codex' in d['products'] and 'claude' in d['products'], d"`
  - `grep -F 'pin during Phase 1' manifests/runtime-roots.yaml`

### Task 2.5: Write `cli-tools.yaml` schema and source file

- **Location**:
  - `core/docs/schemas/cli-tools.schema.json`
  - `manifests/cli-tools.yaml`
- **Description**: Write the JSON Schema for `cli-tools.yaml` matching
  the example in §Manifest Layer (`schema_version`, `profiles` map of
  profile name → list of formula keys, `formulas` map keyed by formula
  name with `brew`, `command`, `linux_only_alternative`, `categories`).
  Write `manifests/cli-tools.yaml` with `schema_version: 1` and the
  three profile keys (`core`, `recommended`, `full`) populated from
  the architecture doc example (`core: [ripgrep, fd, fzf, jq, yq, gh,
  bat]`, etc.). The `formulas:` section MUST carry an entry for every
  formula referenced from any profile. Use the catalog migrated in
  Task 2.6 as the source.
- **Dependencies**:
  - Task 2.6
- **Complexity**: 5
- **Acceptance criteria**:
  - JSON schema parses.
  - YAML parses; `schema_version` equals `1`.
  - `profiles.core` includes at minimum `ripgrep`, `fd`, `fzf`, `jq`,
    `yq`, `gh`, `bat`.
  - Every formula listed in any profile has a matching entry in
    `formulas:` with at least `brew` and `command` fields.
- **Validation**:
  - `python3 -c "import json; json.load(open('core/docs/schemas/cli-tools.schema.json'))"`
  - `python3 -c "import yaml; d=yaml.safe_load(open('manifests/cli-tools.yaml')); assert d['schema_version']==1 and {'ripgrep','fd','fzf','jq','yq','gh','bat'}<=set(d['profiles']['core']), d"`
  - `python3 -c "import yaml; d=yaml.safe_load(open('manifests/cli-tools.yaml')); names=set(); [names.update(v) for v in d['profiles'].values()]; missing=names-set(d['formulas']); assert not missing, missing"`

### Task 2.6: Migrate `CLI_TOOLS.md` to `core/policies/cli-tools.md`

- **Location**:
  - `core/policies/cli-tools.md`
- **Description**: Read `$HOME/.config/agent-kit/CLI_TOOLS.md` (the
  legacy agent-kit catalog). Copy its content into
  `core/policies/cli-tools.md`, then add a top-of-file header naming
  the migration source, the date, and the fact that
  `manifests/cli-tools.yaml` is the machine-readable derivative. The
  prose is the narrative companion to the YAML — keep formula
  descriptions and rationale; drop any legacy agent-kit-specific
  install instructions. If the source file is missing on the host,
  fall back to writing a placeholder doc that mirrors the YAML schema
  (one section per profile, one row per formula with the fields from
  the schema) and log the gap in the execution-state Blockers block.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `core/policies/cli-tools.md` exists.
  - First three lines name the source path and migration date.
  - Document references `manifests/cli-tools.yaml` as the machine
    derivative.
  - Either content was migrated from the legacy file or the
    placeholder fallback was used with a Blocker entry filed.
- **Validation**:
  - `test -f core/policies/cli-tools.md`
  - `grep -F 'manifests/cli-tools.yaml' core/policies/cli-tools.md`
  - `head -3 core/policies/cli-tools.md`

## Sprint 3: nils-cli stub crate and dev tap release

**Goal**: Open the `agent-runtime-cli` crate inside `sympoies/nils-cli`
with subcommand stubs, register it in the workspace, cut a `0.12.0`
release, and bump the formula in `sympoies/homebrew-tap` so
`brew install sympoies/tap/nils-cli` produces a working stub binary
that exits 1 on every subcommand except `--version`. This sprint
touches three repos; each task names the owning repo.

**Demo/Validation**:

- Command(s):
  - `cd ~/Project/sympoies/nils-cli && cargo build -p agent-runtime-cli`
  - `cd ~/Project/sympoies/nils-cli && cargo run -p agent-runtime-cli -- --version`
  - `cd ~/Project/sympoies/nils-cli && cargo run -p agent-runtime-cli -- render; echo exit=$?`
  - `brew update && brew install sympoies/tap/nils-cli && agent-runtime --version`
- Verify: `agent-runtime --version` prints `0.12.0`; every other
  subcommand prints `agent-runtime <subcommand>: not implemented` to
  stderr and exits 1; `brew install` resolves the formula.

**PR grouping intent**: per-sprint
**Execution Profile**: serial

### Task 3.1: Open `agent-runtime-cli` crate stub in nils-cli

- **Location**:
  - `docs/plans/01-skeleton-and-schema/`
- **Description**: Cross-repo task in `sympoies/nils-cli`. Inside
  `~/Project/sympoies/nils-cli/`, copy `crates/cli-template/` to a new
  `crates/agent-runtime-cli/`; rename the binary in `Cargo.toml` to
  `agent-runtime`; set the crate version to `0.12.0` (matching the
  workspace at the Task 3.3 release tag); replace the
  template's main entry point with a clap-derive parser that exposes
  the eight subcommands from Resolved Decision #2 (`render`, `install`,
  `uninstall`, `doctor`, `audit-drift`, `gc-backups`,
  `restore-backups`, `purge-state`). Each subcommand handler prints
  `agent-runtime <subcommand>: not implemented` to stderr and returns
  a non-zero `ExitCode`. `--version` returns `0.12.0` and exits 0.
  No flags are wired beyond `--version` and `--help`. Record the
  cross-repo commit SHA in the execution-state ledger Notes column for
  this task. No file under the agent-runtime-kit repo is modified by
  this task — Location points at the bundle directory so plan-tooling
  has a tracked path; the actual changes land outside this repo.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - `cargo build -p agent-runtime-cli` succeeds in nils-cli workspace.
  - `agent-runtime --version` prints `0.12.0`.
  - Each of the eight subcommands prints
    `agent-runtime <subcommand>: not implemented` to stderr and exits 1.
  - The crate is added to the workspace `members` list.
  - Cross-repo commit SHA recorded in execution-state ledger.
- **Validation**:
  - `cd ~/Project/sympoies/nils-cli && cargo build -p agent-runtime-cli`
  - `cd ~/Project/sympoies/nils-cli && cargo run -p agent-runtime-cli -- --version`
  - `cd ~/Project/sympoies/nils-cli && for sub in render install uninstall doctor audit-drift gc-backups restore-backups purge-state; do cargo run -q -p agent-runtime-cli -- "$sub" 2>&1 | grep -q "not implemented" || { echo "fail: $sub"; exit 1; }; done`

### Task 3.2: Register `agent-runtime-cli` in workspace Cargo.toml

- **Location**:
  - `docs/plans/01-skeleton-and-schema/`
- **Description**: Cross-repo task in `sympoies/nils-cli`. Edit
  `~/Project/sympoies/nils-cli/Cargo.toml` to add
  `"crates/agent-runtime-cli"` to the workspace `members` array and
  add any shared dependency entries the crate needs (clap, anyhow) to
  `workspace.dependencies` if they are not already present. Verify
  `cargo metadata` returns the new crate. Record the commit SHA in
  the execution-state ledger Notes column. No file in this repo is
  modified.
- **Dependencies**:
  - Task 3.1
- **Complexity**: 2
- **Acceptance criteria**:
  - `cargo metadata --format-version 1 | jq -r '.packages[].name'` in
    nils-cli lists `agent-runtime-cli`.
  - Workspace builds end-to-end with the new crate.
  - Cross-repo commit SHA recorded in execution-state ledger.
- **Validation**:
  - `cd ~/Project/sympoies/nils-cli && cargo metadata --format-version 1 | jq -r '.packages[].name' | grep -Fx agent-runtime-cli`
  - `cd ~/Project/sympoies/nils-cli && cargo build --workspace`

### Task 3.3: Cut `v0.12.0` nils-cli release (workspace bump)

- **Location**:
  - `docs/plans/01-skeleton-and-schema/`
- **Description**: Cross-repo task in `sympoies/nils-cli`. nils-cli
  uses a coupled-workspace release convention (`chore(release): bump
  cli versions to X.Y.Z`) — every crate shares the same `version`
  value. Bump every workspace crate from `0.11.0` (and the new
  `agent-runtime-cli` stub from its placeholder `0.0.1-dev`) to
  `0.12.0` in one commit. Regenerate `Cargo.lock` with `cargo build
  --workspace --locked`. Tag the commit as `v0.12.0`, push the tag,
  and publish the release artifacts the homebrew-tap formula consumes
  (tarball + SHA256). Use the existing nils-cli release flow
  (`/release` skill or the equivalent `scripts/release.sh`) — this
  task does not invent a new release pipeline. Record the release
  URL, tag SHA, and tarball SHA256 in the execution-state ledger
  Notes column. No file under this repo is modified.
- **Dependencies**:
  - Task 3.2
- **Complexity**: 5
- **Acceptance criteria**:
  - `git -C ~/Project/sympoies/nils-cli describe --tags` returns
    `v0.12.0` (or a `v0.12.0`-rooted suffix).
  - Release artifact (tarball) published and reachable.
  - SHA256 of the tarball recorded in the execution-state ledger.
- **Validation**:
  - `git -C ~/Project/sympoies/nils-cli describe --tags | grep -F v0.12.0`
  - `git -C ~/Project/sympoies/nils-cli ls-remote --tags origin | grep -F refs/tags/v0.12.0`

### Task 3.4: Bump formula in `sympoies/homebrew-tap`

- **Location**:
  - `docs/plans/01-skeleton-and-schema/`
- **Description**: Cross-repo task in `sympoies/homebrew-tap`. Update
  `Formula/nils-cli.rb` so the `url` and `sha256` point at the
  `v0.12.0` artifact from Task 3.3, and bump the formula version
  pin to `0.12.0`. Run `brew audit --strict --new
  sympoies/tap/nils-cli` locally and fix any warnings before merging.
  Verify a clean install path with
  `brew uninstall nils-cli && brew install sympoies/tap/nils-cli` on
  the development host. Record the homebrew-tap commit SHA in the
  execution-state ledger Notes column. No file in this repo is
  modified by this task.
- **Dependencies**:
  - Task 3.3
- **Complexity**: 4
- **Acceptance criteria**:
  - `brew install sympoies/tap/nils-cli` installs without errors.
  - `agent-runtime --version` (on PATH) returns `0.12.0`.
  - Every subcommand stub exits 1 with the expected stderr line.
  - homebrew-tap commit SHA recorded in execution-state ledger.
- **Validation**:
  - `brew update && brew reinstall sympoies/tap/nils-cli && agent-runtime --version | grep -F 0.12.0`
  - `agent-runtime render 2>&1 | grep -F 'not implemented'`

## Sprint 4: Host bootstrap skeleton and docs snapshot

**Goal**: Ship the `scripts/setup.sh` skeleton (parsing only — the
`agent-runtime install` calls are deliberately stubbed) and the frozen
`docs/source/nils-cli-surface.md` snapshot manifest authors will pin
`required_clis` against. Neither artifact mutates a live product home.

**Demo/Validation**:

- Command(s):
  - `bash -n scripts/setup.sh`
  - `scripts/setup.sh --help`
  - `scripts/setup.sh --profile core --dry-run`
  - `head docs/source/nils-cli-surface.md`
- Verify: setup script parses, prints a help banner naming
  `--profile core|recommended|full` and `--skip-homebrew-install`, and
  `--dry-run` exits 0 without invoking brew or `agent-runtime install`;
  the snapshot doc lists every crate currently in
  `~/Project/sympoies/nils-cli/crates/` and the active git tag.

**PR grouping intent**: group
**Execution Profile**: serial

### Task 4.1: Write `scripts/setup.sh` skeleton

- **Location**:
  - `scripts/setup.sh`
- **Description**: Write the host bootstrap skeleton matching the
  Brew-First Bootstrap section of the architecture doc. The script
  detects the OS via `brew --prefix`, parses `--profile core` /
  `--profile recommended` / `--profile full`, accepts
  `--skip-homebrew-install` and `--dry-run`, performs
  `brew tap sympoies/tap`, and either invokes `brew install nils-cli`
  or echoes the command (when `--dry-run`). The `agent-runtime install
  --product claude` and `agent-runtime install --product codex`
  invocations near the end are STUBBED: replaced with an
  `echo "[stub] agent-runtime install ..."` block plus a
  `# defer to Plan 04` comment marking the deferred work. The clone-on-missing block for
  agent-runtime-kit is real (uses `git clone` against
  `$HOME/.config/agent-runtime-kit`) but is guarded behind `--dry-run`.
  Make the script `chmod +x` and ensure it passes `bash -n`.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - `bash -n scripts/setup.sh` exits 0.
  - `scripts/setup.sh --help` prints a banner listing all three
    profile values and `--skip-homebrew-install` / `--dry-run`.
  - `scripts/setup.sh --profile core --dry-run` exits 0 and does NOT
    invoke brew or `agent-runtime install` (verified by stubbed
    output).
  - The `agent-runtime install` block carries a `# defer to Plan 04`
    comment.
  - File is executable (`-rwxr-xr-x`).
- **Validation**:
  - `bash -n scripts/setup.sh`
  - `scripts/setup.sh --help | grep -E 'profile.*core|recommended|full'`
  - `scripts/setup.sh --profile core --dry-run 2>&1 | grep -F '[stub] agent-runtime install'`
  - `test -x scripts/setup.sh`

### Task 4.2: Freeze nils-cli surface snapshot in `docs/source/`

- **Location**:
  - `docs/source/nils-cli-surface.md`
- **Description**: Snapshot the current nils-cli binary surface that
  manifest authors will pin `required_clis` against. Run
  `ls ~/Project/sympoies/nils-cli/crates/` to enumerate every crate
  (one row per crate); run
  `git -C ~/Project/sympoies/nils-cli describe --tags` to capture the
  active version; write the result as a markdown table with columns
  `crate`, `binary` (best-effort: same as crate unless the crate name
  ends in `-core` / `-support`), `notes`. Add a top-of-file header
  naming the snapshot date, the source command, the active
  `git describe` output, and a sentence stating that this file is the
  pin source for `required_clis` placeholders and gets refreshed at
  each nils-cli minor release.
- **Dependencies**:
  - Task 3.3
- **Complexity**: 3
- **Acceptance criteria**:
  - File exists at `docs/source/nils-cli-surface.md`.
  - Header records snapshot date and `git describe` output.
  - Markdown table lists every entry currently in
    `~/Project/sympoies/nils-cli/crates/`.
  - File names `required_clis` as the consumer.
- **Validation**:
  - `test -f docs/source/nils-cli-surface.md`
  - `grep -F 'required_clis' docs/source/nils-cli-surface.md`
  - `grep -F 'git describe' docs/source/nils-cli-surface.md`
  - `python3 -c "import re,sys; t=open('docs/source/nils-cli-surface.md').read(); rows=re.findall(r'^\|[^|]+\|', t, re.M); assert len(rows) >= 10, len(rows)"`

## Testing Strategy

- Unit: none in this plan. The stub crate has no logic to unit-test
  beyond clap parsing, which clap-derive covers itself.
- Integration: stub binary smoke tests in Sprint 3 (each subcommand
  exits 1 with the expected stderr line); manifest YAML / JSON Schema
  parse checks in Sprint 2; `bash -n scripts/setup.sh` and
  `--dry-run` exit 0 in Sprint 4.
- Cross-repo verification: after Sprint 3 lands, run `brew install
  sympoies/tap/nils-cli` on the development host and confirm
  `agent-runtime --version` returns `0.12.0` and every subcommand
  stub exits 1 with the expected stderr line.
- Plan bundle: `plan-tooling validate --file
  docs/plans/01-skeleton-and-schema/01-skeleton-and-schema-plan.md
  --format text --explain` must exit 0 before any sprint starts.

## Risks & gotchas

- **Cross-repo Sprint 3 ordering**: the formula bump in
  `sympoies/homebrew-tap` MUST follow the `v0.12.0` release in
  `sympoies/nils-cli`. Bumping the formula before the tarball exists
  breaks `brew install` for every other developer pulling the tap.
  The Task 3.3 → Task 3.4 dependency makes this explicit; do not
  parallelise it.
- **`<TBD: pin during Phase 1>` placeholder discipline**: the
  architecture doc treats any surviving literal `<TBD>` in a tracked
  manifest as a Phase 1 gate failure. This plan intentionally writes
  the placeholder because the schema validator does not exist yet —
  Plan 02 lands the validator and pins concrete values. Reviewers
  must accept the placeholder for the duration of this plan.
- **Legacy `$HOME/.config/agent-kit/CLI_TOOLS.md` portability**: the
  source file lives on the development host, not in this repo. Task
  2.6 reads it once and copies the content. If a future host does not
  have the file, the fallback placeholder path triggers and a Blocker
  entry is filed in the execution-state ledger; this plan does not
  bundle the legacy file as a tracked artifact.
- **`agent-runtime-cli` namespace collision**: the architecture doc
  also references the binary as just `agent-runtime`. The Cargo
  package name is `agent-runtime-cli` (crate) and the binary name is
  `agent-runtime`. Task 3.1's `Cargo.toml` MUST set
  `[[bin]] name = "agent-runtime"` so brew users get the expected
  binary on PATH.
- **`scripts/setup.sh` portability**: the script must run on macOS
  (system bash 3.2) and Linux (bash 4+). Avoid associative arrays,
  `mapfile`, and `${var,,}` lowercasing. Use `tr` and POSIX-compatible
  conditionals.
- **Stub binary smoke test on TTY**: the smoke loop in Task 3.1's
  validation uses `cargo run -q` which writes to a TTY when
  attached. The `grep -q "not implemented"` reads stderr regardless,
  so this is safe — but reviewers should not assume the binary is
  rendering nothing on stdout.

## Rollback plan

- Sprint 1 rollback: `git revert` the skeleton commit. No external
  side effects; nothing has been published.
- Sprint 2 rollback: `git revert` the manifest commits. The five YAML
  files and their JSON schemas are tracked source-of-truth, so the
  revert is clean. No external consumer exists yet (Plan 02 has not
  landed).
- Sprint 3 rollback: this is the riskiest sprint because three repos
  are touched.
  - homebrew-tap (Task 3.4): revert the formula bump commit; existing
    installs continue to point at whichever release the formula
    previously named (`v0.11.0` at planning time). `brew upgrade
    nils-cli` will downgrade to the previous version.
  - nils-cli (Tasks 3.1–3.3): revert the release-tag commit; do NOT
    delete the tag itself (the homebrew formula still references it
    if the tap revert lands later). Optionally yank the tag once the
    formula has been re-pointed.
  - This repo: no commits made by Sprint 3. No revert needed here.
- Sprint 4 rollback: `git revert` the setup-script + snapshot commit.
  `scripts/setup.sh` has no external effects when `--dry-run` is the
  only path exercised; the snapshot doc is informational. No external
  consumer breaks.
- If the entire plan needs to be rolled back, revert in reverse sprint
  order (4 → 3 → 2 → 1) so the homebrew-tap revert happens after the
  nils-cli release revert, matching the install ladder direction.
