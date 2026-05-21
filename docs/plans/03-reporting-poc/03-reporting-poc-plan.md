# Plan: Phase 2 — Reporting Domain POC

## Overview

End-to-end Phase 2 POC for the `reporting` domain. Migrate three skills
(`daily-brief`, `project-retro`, `topic-radar`) from current claude-kit
and agent-kit sources into the new portable `core/` layout, fill in
product adapter metadata for Codex and Claude, fill in the four
relevant manifests, pin render-golden snapshots, and pin drift fixtures
covering the four POC drift classes. No live runtime home is mutated by
this plan — apply lands in Plan 04.

The plan ships in **two sprints** (revised down from four on
2026-05-21 after a v0.13.0 reality check against the originally
planned validation gates):

1. **Sprint 1 — Canonical bodies + adapters + manifests.** Combines
   the original Sprint 1 (skill bodies) and Sprint 2 (manifests +
   adapter metadata) into a single PR. Required because the
   `agent-runtime render` body shipped in v0.13.0 has no
   `--domain` / `--skill` filter and renders strictly off
   `manifests/skills.yaml`. Sprint 1's byte-exact acceptance against
   the source-doc rendered examples cannot be verified until manifest
   entries are also in place. Splitting them into two PRs would leave
   the first PR unverifiable.
2. **Sprint 2 — Render goldens, drift fixtures, audit-drift verify.**
   The original Sprint 3 unchanged in intent. Validation commands are
   re-aligned to v0.13.0 (no `--check` / `--format` / `--fixture`;
   the same artifacts are produced through `render` whole-product +
   `git diff --exit-code` and `audit-drift --source-root`).

The original Sprint 4 (deterministic dry-run install snapshots) is
**deferred to Plan 04**. Source doc lines 1610–1628 (the "Dry-run
install output" example) describe the intended shape, but Plan 02
explicitly listed `install` body as out-of-scope ("later phases"),
and v0.13.0's `agent-runtime install` is still a stub with no
`--product` / `--dry-run` flags. Plan 04 Sprint 1 lands the install
body and Plan 04 Sprint 5 pins `tests/sandbox/<product>/expected-skills.txt`
through the same `--dry-run` surface — that is the right home for
the snapshots Plan 03 originally tried to pin.

Both surviving sprints validate against the source doc's "Simulated
Reporting POC" contract (lines 1505–1643), minus the install dry-run
example (lines 1610–1628) which moves to Plan 04.

## Read First

- Primary source: docs/plans/03-reporting-poc/03-reporting-poc-discussion-source.md
- Source type: discussion-to-implementation-doc
- Open questions carried into execution:
  - ~~Domain-mapping decision for `topic-radar`~~ — **Resolved
    2026-05-21 (reviewer: terry)**: adopt the source doc canonical
    example at `docs/source/inventory-target-architecture.md`
    L555–566 verbatim — declare both
    `products.codex.path_override: skills/tools/market-research/topic-radar`
    and
    `products.claude.path_override: plugins/reporting/skills/topic-radar`
    on `reporting.topic-radar` so existing invocation paths on both
    products keep resolving and drift audit pins the override
    explicitly on both sides. Domain unification deferred to Plan 05.
  - ~~Whether to capture the rendered `topic-radar.sh` script as-is
    or migrate it to a nils-cli binary~~ — **Resolved 2026-05-21
    (reviewer: terry)**: ship as-is in Plan 03; do not extract to a
    nils-cli binary yet. `topic-radar` is still actively gaining
    features and its usage shape is not stable, so early extraction
    would lock an interface that would need to be re-cut shortly.
    Backlog entry stays open for revisit after the skill stabilises.
  - ~~CLI surface alignment between v0.13.0 and Plan 03 validation
    gates~~ — **Resolved 2026-05-21 (reviewer: terry)**: rev Plan 03
    validation gates to the actual v0.13.0 `agent-runtime` surface
    (no `--check` / `--domain` / `--skill` / `--format` /
    `--fixture`); merge Sprint 1 + Sprint 2 because render byte-exact
    requires manifests; move Sprint 4 (install dry-run snapshots) to
    Plan 04. Plan 01 cleanup PR landed alongside this rev to pin
    `runtime-roots.yaml` versions and remove the residual
    `$AGENT_HOME` literal in `core/policies/cli-tools.md` so
    audit-drift baseline exits 0.

## Scope

- In scope:
  - Canonical portable bodies for the three reporting skills under
    `core/skills/reporting/`, including the migrated `topic-radar.sh`
    script.
  - Codex and Claude adapter metadata under
    `targets/<product>/plugins/reporting/`.
  - Reporting entries in `manifests/skills.yaml`,
    `manifests/plugins.yaml`,
    `manifests/product-capabilities.yaml`, and the root-map block in
    `manifests/runtime-roots.yaml` (Plan 01 cleanup PR pinned the
    version-floor fields; Sprint 1 Task 1.9 only adds the root-map
    structure and verifies the pins are still current).
  - Render-golden snapshots committed under
    `tests/golden/<product>/reporting/` for every reporting skill.
  - Drift fixtures under `tests/drift/<scenario>/` for the four POC
    drift classes (source-manifest, rendered-target diff,
    `$AGENT_HOME` leak, docs-home).
- Out of scope:
  - Any write under a live runtime home (`$HOME/.codex/`,
    `$HOME/.claude/`, or any `CLAUDE_KIT_STATE_HOME` path). Apply mode
    is Plan 04.
  - Migration of any other domain. Plan 05 covers the remaining seven
    domains.
  - The remaining drift classes (`missing` / `stale` / `extra` /
    `intentional-difference` / `unsafe`). Plan 04 Sprint 4 lands the
    full `audit-drift` body and the allowlist mechanism.
  - Rewriting `topic-radar.sh` as a nils-cli binary. Deferred to the
    extraction backlog.
  - Sandbox install rehearsal (test layer 6). Lands with the installer
    body in Plan 04 per the source doc.
  - Deterministic dry-run install snapshots under
    `tests/install/<product>/expected.txt`. Deferred to Plan 04
    Sprint 5 because `agent-runtime install --dry-run` does not exist
    in v0.13.0 (Plan 02 listed install body as out-of-scope, "later
    phases"). Plan 04 Sprint 1 lands the install body; Plan 04
    Sprint 5 pins `tests/sandbox/<product>/expected-skills.txt`
    through the same surface.

## Assumptions

1. Plan 02 has shipped `agent-runtime render` and the minimal
   `agent-runtime audit-drift` body (source-manifest /
   rendered-target diff / `$AGENT_HOME` leak / docs-home classes)
   through the `sympoies/homebrew-tap` `v0.13.0` release. Required
   CLIs floors in Plan 03 manifests pin against that release.
2. Plan 01 has landed the five `manifests/*.yaml` source files with
   `schema_version: 1` and the matching JSON schemas under
   `core/docs/schemas/`. Plan 03 fills in the reporting slice; it
   does not edit the schema.
3. Plan 01 has landed the drift allowlist seed at top-level
   `drift-audit.allow.yaml` and the baseline `.gitignore`. Plan 03
   does not introduce sensitive fixtures.
4. The current Claude plugin
   (`$HOME/.config/claude/plugins/reporting/skills/daily-brief/`,
   `$HOME/.config/claude/plugins/reporting/skills/project-retro/`) and
   the current agent-kit copy
   (`$HOME/.config/agent-kit/skills/workflows/reporting/daily-brief/`,
   `$HOME/.config/agent-kit/skills/workflows/reporting/project-retro/`,
   `$HOME/.config/agent-kit/skills/tools/market-research/topic-radar/`)
   are the legacy reads-only source of content for the rewrite.
5. `manifests/runtime-roots.yaml` carries concrete version pins
   (`codex 0.130.0`, `claude 2.1.145`, `effective_from 2026-06-03`)
   landed by the Plan 01 cleanup PR. Sprint 1 Task 1.9 verifies the
   pins are still appropriate and only adds the structural root-map
   block per the source-doc example shape.
6. The `min_version_effective_from` runway is 14 days after the Phase
   2 PR merge date (`2026-06-03`), giving existing hosts a soft
   landing before the floor starts blocking.
7. `agent-runtime` v0.13.0 is on PATH via brew (`agent-runtime
   --version` reports `0.13.0`). The Tera helpers `script` /
   `skill_ref` / `state_out` / `cli_ref` and the cache-keyed writer
   are functional per Plan 02 Sprint 1 shipping. The `state_out`
   runtime mode emits `agent-out path-for ...` and is what reporting
   skills target (literal mode reserved for Plan 04).

## Sprint 1: Canonical reporting skill bodies, adapters, and manifest fill

**Goal**: Land portable canonical bodies for the three reporting
skills under `core/skills/reporting/` (plus the migrated
`topic-radar.sh` script), the Codex and Claude adapter metadata under
`targets/<product>/plugins/reporting/`, and the reporting entries in
all four manifests so `agent-runtime render --product <p>` renders the
domain into `build/<product>/plugins/reporting/skills/<skill>/`
byte-stable. No `$AGENT_HOME` reference survives. No `<TBD>`
`required_clis` value survives — every floor pins to `">=0.13.0"`
or higher.

**Demo/Validation**:

- Command(s):
  - `grep -RnE '\$AGENT_HOME|/\.agents/' core/skills/reporting/`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `jq . targets/codex/plugins/reporting/.codex-plugin/plugin.json`
  - `jq . targets/claude/plugins/reporting/.claude-plugin/plugin.json`
  - `yq '.skills[] | select(.id | startswith("reporting"))' manifests/skills.yaml`
  - `yq '.plugins[] | select(.id == "reporting")' manifests/plugins.yaml`
  - `agent-runtime audit-drift`
- Verify: grep returns zero matches; both `render --product` runs
  produce the reporting skill tree under `build/<product>/`; rendered
  Codex and Claude snippets for `daily-brief` match the source-doc
  rendered examples (lines 1577–1603) byte-exact under
  `build/<product>/plugins/reporting/skills/daily-brief/SKILL.md`;
  both adapter `plugin.json` files parse as valid JSON; all four
  manifests carry reporting entries with concrete `required_clis`
  floors; `audit-drift` exits 0.

**PR grouping intent**: `group`
**Execution Profile**: `parallel-x2`

### Task 1.1: Write portable `daily-brief/SKILL.md`

- **Location**:
  - `core/skills/reporting/daily-brief/SKILL.md`
- **Description**: Read the current bodies at
  `$HOME/.config/claude/plugins/reporting/skills/daily-brief/SKILL.md`
  and
  `$HOME/.config/agent-kit/skills/workflows/reporting/daily-brief/SKILL.md`
  to recover intent. Rewrite a single canonical body that uses the
  Tera helpers for every product-path reference. Use
  `{{ skill_ref("reporting.topic-radar") }}` for the source-collection
  cross-reference, `{{ script("reporting/topic-radar/scripts/topic-radar.sh") }}`
  for the helper invocation, and
  `{{ state_out("projects", topic="daily-brief") }}` for temporary
  output. Match the portable source example in the source doc lines
  1563–1575.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - File exists and contains the three Tera helper invocations above.
  - File contains zero `$AGENT_HOME` references.
  - File contains zero `/.agents/` legacy-path references.
  - After Sprint 1 manifest tasks land, the rendered Codex snippet
    under
    `build/codex/plugins/reporting/skills/daily-brief/SKILL.md`
    matches the source-doc Codex example (lines 1579–1589) byte-exact.
  - After Sprint 1 manifest tasks land, the rendered Claude snippet
    under
    `build/claude/plugins/reporting/skills/daily-brief/SKILL.md`
    matches the source-doc Claude example (lines 1593–1603)
    byte-exact.
- **Validation**:
  - `grep -nE '\$AGENT_HOME|/\.agents/' core/skills/reporting/daily-brief/SKILL.md`
  - After Task 1.6 lands: `agent-runtime render --product codex && diff <(cat build/codex/plugins/reporting/skills/daily-brief/SKILL.md) <expected snippet>`
  - After Task 1.6 lands: `agent-runtime render --product claude && diff <(cat build/claude/plugins/reporting/skills/daily-brief/SKILL.md) <expected snippet>`

### Task 1.2: Write portable `project-retro/SKILL.md`

- **Location**:
  - `core/skills/reporting/project-retro/SKILL.md`
- **Description**: Read
  `$HOME/.config/claude/plugins/reporting/skills/project-retro/SKILL.md`
  and
  `$HOME/.config/agent-kit/skills/workflows/reporting/project-retro/SKILL.md`
  for intent. Rewrite into a portable canonical body. Use the Tera
  helpers wherever a product runtime path appears today; pipe any
  temporary output through `{{ state_out("projects", topic="project-retro") }}`.
  Keep the body product-agnostic per the Portable Skill References
  contract in the source doc lines 680–717.
- **Dependencies**:
  - none
- **Complexity**: 5
- **Acceptance criteria**:
  - File exists and uses `{{ state_out(...) }}` for every temporary
    output reference.
  - File contains zero `$AGENT_HOME` references.
  - File contains zero `/.agents/` legacy-path references.
  - After Sprint 1 manifest tasks land, the rendered Codex output
    references `$CODEX_HOME` paths only.
  - After Sprint 1 manifest tasks land, the rendered Claude output
    references `${CLAUDE_PLUGIN_ROOT}` or `$HOME/.claude` paths only.
- **Validation**:
  - `grep -nE '\$AGENT_HOME|/\.agents/' core/skills/reporting/project-retro/SKILL.md`
  - After Task 1.6 lands: `agent-runtime render --product codex && grep -nE '\$AGENT_HOME|/\.agents/' build/codex/plugins/reporting/skills/project-retro/SKILL.md`
  - After Task 1.6 lands: `agent-runtime render --product claude && grep -nE '\$AGENT_HOME|/\.agents/' build/claude/plugins/reporting/skills/project-retro/SKILL.md`

### Task 1.3: Write portable `topic-radar/SKILL.md` and migrate `topic-radar.sh`

- **Location**:
  - `core/skills/reporting/topic-radar/SKILL.md`
  - `core/skills/reporting/topic-radar/scripts/topic-radar.sh`
- **Description**: Read
  `$HOME/.config/agent-kit/skills/tools/market-research/topic-radar/SKILL.md`
  and the existing
  `$HOME/.config/agent-kit/skills/tools/market-research/topic-radar/scripts/topic-radar.sh`.
  Move the script under the new canonical path as-is (no nils-cli
  extraction; deferred to backlog). Rewrite the SKILL body so script
  invocation goes through
  `{{ script("reporting/topic-radar/scripts/topic-radar.sh") }}` and
  the temporary output uses `{{ state_out("tools", tool="topic-radar") }}`.
- **Dependencies**:
  - none
- **Complexity**: 6
- **Acceptance criteria**:
  - `core/skills/reporting/topic-radar/SKILL.md` contains the two
    Tera helpers above.
  - `core/skills/reporting/topic-radar/scripts/topic-radar.sh` exists
    and is executable.
  - The script contains zero `$AGENT_HOME` references.
  - After Sprint 1 manifest tasks land, the rendered Codex output
    references
    `$CODEX_HOME/plugins/reporting/skills/topic-radar/scripts/topic-radar.sh`.
  - After Sprint 1 manifest tasks land, the rendered Claude output
    references `${CLAUDE_PLUGIN_ROOT}/scripts/topic-radar.sh`.
- **Validation**:
  - `grep -nE '\$AGENT_HOME|/\.agents/' core/skills/reporting/topic-radar/`
  - `test -x core/skills/reporting/topic-radar/scripts/topic-radar.sh`
  - After Task 1.6 lands: `agent-runtime render --product codex && grep -nE 'topic-radar\.sh' build/codex/plugins/reporting/skills/topic-radar/SKILL.md`
  - After Task 1.6 lands: `agent-runtime render --product claude && grep -nE 'topic-radar\.sh' build/claude/plugins/reporting/skills/topic-radar/SKILL.md`

### Task 1.4: Write Codex adapter metadata

- **Location**:
  - `targets/codex/plugins/reporting/.codex-plugin/plugin.json`
- **Description**: Author `.codex-plugin/plugin.json` for the
  reporting plugin. Per Resolved Decision #10 (source doc lines
  442–498), this file is local-source-organisation only — Codex never
  reads it. It validates against the local schema in
  `core/docs/schemas/codex-plugin.schema.json` and is referenced by
  the audit-drift `source-manifest` class. Include `name`,
  `version: "0.1.0"`, `description`, `author.name: "graysurf"`, and a
  `skills` array enumerating `daily-brief`, `project-retro`,
  `topic-radar`.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 1.3
- **Complexity**: 3
- **Acceptance criteria**:
  - File parses as valid JSON.
  - File validates against `core/docs/schemas/codex-plugin.schema.json`.
  - File enumerates exactly three skills matching the canonical IDs
    in Sprint 1.
  - No upstream Codex registry comparison is attempted (drift audit
    must not flag a "missing marketplace entry").
- **Validation**:
  - `jq . targets/codex/plugins/reporting/.codex-plugin/plugin.json`
  - `agent-runtime render --product codex`

### Task 1.5: Write Claude adapter metadata

- **Location**:
  - `targets/claude/plugins/reporting/.claude-plugin/plugin.json`
- **Description**: Author `.claude-plugin/plugin.json` against the
  upstream Claude plugin schema. Carry the existing top-level shape
  from `$HOME/.config/claude/plugins/reporting/.claude-plugin/plugin.json`
  (`name: "reporting"`, `version: "0.1.0"`, `description`,
  `author.name: "graysurf"`, `homepage`) but update the description
  to reflect the migration ownership (now graysurf/agent-runtime-kit).
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 1.3
- **Complexity**: 2
- **Acceptance criteria**:
  - File parses as valid JSON.
  - File validates against the local mirror of the upstream Claude
    plugin schema in `core/docs/schemas/claude-plugin.schema.json`.
  - `homepage` field points at
    `https://github.com/graysurf/agent-runtime-kit`.
  - `version` matches the Codex adapter `version` value (both
    `0.1.0`).
- **Validation**:
  - `jq . targets/claude/plugins/reporting/.claude-plugin/plugin.json`
  - `agent-runtime render --product claude`

### Task 1.6: Fill `manifests/skills.yaml` with reporting entries

- **Location**:
  - `manifests/skills.yaml`
- **Description**: Append three skill entries (`reporting.daily-brief`,
  `reporting.project-retro`, `reporting.topic-radar`) using the
  example slice in the source doc lines 1520–1554 as the shape.
  Pin every `required_clis` value to a concrete `">=0.13.0"` range
  against the v0.13.0 nils-cli release. Set `state_out_mode: runtime`
  on all three. For `reporting.topic-radar`, set
  `products.codex.path_override: skills/tools/market-research/topic-radar`
  and
  `products.claude.path_override: plugins/reporting/skills/topic-radar`
  per the resolved open question (2026-05-21, Option A — source doc
  canonical L555–566) so legacy invocation paths on both products
  keep resolving.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 1.3
- **Complexity**: 5
- **Acceptance criteria**:
  - Three reporting entries present under `skills:`.
  - Every `required_clis` value is a concrete semver range; no
    placeholder strings remain in the file.
  - `reporting.topic-radar` carries both
    `products.codex.path_override` and `products.claude.path_override`
    pointing at the legacy invocation paths on each product,
    matching source doc canonical L555–566 verbatim.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.skills[] | select(.id | startswith("reporting")) | .required_clis' manifests/skills.yaml`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 1.7: Fill `manifests/plugins.yaml` with the reporting plugin entry

- **Location**:
  - `manifests/plugins.yaml`
- **Description**: Append a single `reporting` plugin entry that
  enumerates the three contained skills, declares product manifests
  (`targets/codex/plugins/reporting/.codex-plugin/plugin.json` and
  `targets/claude/plugins/reporting/.claude-plugin/plugin.json`), and
  carries the install policy. Default policy: install on both Codex
  and Claude; no inter-plugin dependencies.
- **Dependencies**:
  - Task 1.4
  - Task 1.5
  - Task 1.6
- **Complexity**: 3
- **Acceptance criteria**:
  - Entry exists under `plugins:` with `id: reporting`.
  - `contained_skills` enumerates the three canonical IDs.
  - `product_manifests.codex` and `product_manifests.claude` point at
    the two adapter `plugin.json` paths from Tasks 1.4 and 1.5.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.plugins[] | select(.id == "reporting")' manifests/plugins.yaml`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 1.8: Fill `manifests/product-capabilities.yaml`

- **Location**:
  - `manifests/product-capabilities.yaml`
- **Description**: Land the per-product capability shape per the
  `## Manifest Layer` discussion (source doc lines 511–514). For
  Codex: nested skill support, no plugin marketplace, hooks via
  managed-block in `config.toml`, activation via `AGENTS.md` symlink.
  For Claude: nested skill support, plugin marketplace via upstream
  schema, hooks via `settings.json`, activation via plugin install.
  Include the explicit field-level diff between
  `.codex-plugin/plugin.json` and `.claude-plugin/plugin.json` so
  drift audit can reason about intentional differences.
- **Dependencies**:
  - Task 1.4
  - Task 1.5
- **Complexity**: 4
- **Acceptance criteria**:
  - Top-level keys `products.codex` and `products.claude` are present
    and non-empty.
  - Each product carries `nested_skill_support`,
    `plugin_manifest_schema`, `hooks_model`, `config_activation`,
    `runtime_state_boundary` fields.
  - A `plugin_manifest_diff` block enumerates the field-level
    differences between the two adapter `plugin.json` files.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.products.codex' manifests/product-capabilities.yaml`
  - `yq '.products.claude' manifests/product-capabilities.yaml`
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`

### Task 1.9: Verify `manifests/runtime-roots.yaml` root-map block

- **Location**:
  - `manifests/runtime-roots.yaml`
- **Description**: The Plan 01 cleanup PR (merged 2026-05-21) already
  pinned the per-product version-floor values
  (`min_version` / `recommended_version` / `min_version_effective_from`)
  per the source doc example block (lines 1221–1244). This task
  verifies the structure (every required field of the source-doc
  example is present), reconfirms the pinned values are still
  appropriate (a stale snapshot would trigger an `audit-drift` warn
  next time the development host updates Codex/Claude), and adds any
  missing optional fields the source-doc example uses. If the source
  doc shape now diverges from the file, prefer the source-doc shape
  and re-pin to current host versions.
- **Dependencies**:
  - none
- **Complexity**: 2
- **Acceptance criteria**:
  - `products.codex.min_version` is `"0.130.0"` or current host
    pin (re-snapshot if stale).
  - `products.claude.min_version` is `"2.1.145"` or current host
    pin.
  - Both products carry
    `min_version_effective_from: "2026-06-03"`.
  - Both products carry the `version_probe`, `state_home`,
    `docs_home`, `live_home`, `plugin_root` (or
    `plugin_root_env`) fields from the source-doc example.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.products.codex.min_version, .products.claude.min_version' manifests/runtime-roots.yaml`
  - `yq '.products.codex.min_version_effective_from, .products.claude.min_version_effective_from' manifests/runtime-roots.yaml`
  - `agent-runtime audit-drift`

## Sprint 2: Render goldens, drift fixtures, end-to-end audit

**Goal**: Lock the rendered output for both products with golden
snapshots, exercise the four POC drift classes through pinned
fixtures, and confirm `audit-drift` exits 0 on the clean POC.

**Demo/Validation**:

- Command(s):
  - `agent-runtime render --product codex --update-golden`
  - `agent-runtime render --product claude --update-golden`
  - `git diff --exit-code tests/golden/codex/plugins/reporting/ tests/golden/claude/plugins/reporting/`
  - `agent-runtime audit-drift`
  - `agent-runtime audit-drift --source-root tests/drift/source-manifest-missing/`
  - `agent-runtime audit-drift --source-root tests/drift/rendered-target-diff/`
  - `agent-runtime audit-drift --source-root tests/drift/agent-home-leak/`
  - `agent-runtime audit-drift --source-root tests/drift/docs-home-mismatch/`
- Verify: golden snapshots committed and stable; clean tree exits 0;
  each drift fixture pins both the expected report text and the
  expected exit code by running a sub-`audit-drift` against the
  fixture's own `--source-root` (a self-contained mini source root
  under `tests/drift/<scenario>/`).

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Generate and commit render-golden snapshots

- **Location**:
  - `tests/golden/codex/plugins/reporting/daily-brief/expected/SKILL.md`
  - `tests/golden/codex/plugins/reporting/project-retro/expected/SKILL.md`
  - `tests/golden/codex/plugins/reporting/topic-radar/expected/SKILL.md`
  - `tests/golden/codex/plugins/reporting/topic-radar/expected/scripts/topic-radar.sh`
  - `tests/golden/claude/plugins/reporting/daily-brief/expected/SKILL.md`
  - `tests/golden/claude/plugins/reporting/project-retro/expected/SKILL.md`
  - `tests/golden/claude/plugins/reporting/topic-radar/expected/SKILL.md`
  - `tests/golden/claude/plugins/reporting/topic-radar/expected/scripts/topic-radar.sh`
- **Description**: Run `agent-runtime render --product codex
  --update-golden` followed by `agent-runtime render --product claude
  --update-golden` to produce the byte-exact target snapshots, review
  the diff per Test Layer 2 in the source doc (lines 1423–1428), then
  commit only the reporting subdirectories. The render binary writes
  the full product tree, but Sprint 2 only commits the reporting
  domain pieces (other domains land via Plan 05). Validate the
  `daily-brief` Codex and Claude snapshots match the source-doc
  rendered examples (lines 1577–1603) byte-exact.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 1.3
  - Task 1.4
  - Task 1.5
  - Task 1.6
  - Task 1.7
  - Task 1.8
  - Task 1.9
- **Complexity**: 4
- **Acceptance criteria**:
  - Six expected/ directories exist and are non-empty (3 skills × 2
    products).
  - `agent-runtime render --product codex && agent-runtime render
    --product claude` produces zero diff against the committed
    snapshots in `tests/golden/<product>/plugins/reporting/`.
  - The `daily-brief` Codex snapshot contains
    `$CODEX_HOME/plugins/reporting/skills/topic-radar/scripts/topic-radar.sh`.
  - The `daily-brief` Claude snapshot contains
    `${CLAUDE_PLUGIN_ROOT}/scripts/topic-radar.sh`.
  - No snapshot contains a `$AGENT_HOME` reference.
- **Validation**:
  - `agent-runtime render --product codex`
  - `agent-runtime render --product claude`
  - `git diff --exit-code tests/golden/codex/plugins/reporting/ tests/golden/claude/plugins/reporting/`
  - `grep -RnE '\$AGENT_HOME' tests/golden/codex/plugins/reporting/ tests/golden/claude/plugins/reporting/`

### Task 2.2: Add drift fixtures for the four POC drift classes

- **Location**:
  - `tests/drift/source-manifest-missing/` (self-contained source root + `expected.txt` + `expected.exit`)
  - `tests/drift/rendered-target-diff/` (same shape)
  - `tests/drift/agent-home-leak/` (same shape)
  - `tests/drift/docs-home-mismatch/` (same shape)
- **Description**: For each drift class, build a synthetic mini
  source root under the fixture directory (with its own `core/`,
  `manifests/`, `targets/`, and `build/` subtrees as needed) and pin
  both the expected text report (`expected.txt`) and the expected
  exit code (`expected.exit`). v0.13.0's `agent-runtime audit-drift`
  accepts `--source-root <path>`, so each fixture runs as a
  stand-alone audit instead of through a non-existent
  `--fixture` flag. Classes:
  - `source-manifest-missing`: a manifest references a skill source
    path that does not exist under `core/skills/` of the fixture.
  - `rendered-target-diff`: the rendered `build/` output differs from
    the source-rendered tree.
  - `agent-home-leak`: a rendered file contains `$AGENT_HOME`.
  - `docs-home-mismatch`: a rendered docs reference uses the wrong
    product's `docs_home` (e.g. Claude render points at
    `$CODEX_HOME`).
- **Dependencies**:
  - Task 2.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Each fixture directory contains a self-contained source root
    (`core/` + `manifests/` + `targets/` + `build/` as needed for the
    class), an `expected.txt` report, and an `expected.exit` code
    file.
  - Each fixture, when passed to `agent-runtime audit-drift
    --source-root tests/drift/<scenario>/`, produces a report that
    diffs cleanly against `expected.txt`.
  - The exit code from each fixture run matches the value in
    `expected.exit`.
  - The `agent-home-leak` fixture exits with `2` (block).
  - The clean POC tree (no fixture override, no `--source-root`)
    still exits `0`.
- **Validation**:
  - `diff -u tests/drift/source-manifest-missing/expected.txt <(agent-runtime audit-drift --source-root tests/drift/source-manifest-missing/)`
  - `diff -u tests/drift/rendered-target-diff/expected.txt <(agent-runtime audit-drift --source-root tests/drift/rendered-target-diff/)`
  - `diff -u tests/drift/agent-home-leak/expected.txt <(agent-runtime audit-drift --source-root tests/drift/agent-home-leak/)`
  - `diff -u tests/drift/docs-home-mismatch/expected.txt <(agent-runtime audit-drift --source-root tests/drift/docs-home-mismatch/)`
  - `agent-runtime audit-drift`

### Task 2.3: Confirm clean POC audit-drift exits 0

- **Location**:
  - `tests/audit-drift/clean-poc-expected.txt`
- **Description**: Run `agent-runtime audit-drift` against the clean
  POC tree (no fixture override) and capture stdout. Confirm every
  check listed in the source-doc drift-audit example (lines
  1632–1642) returns `ok` or `skip`, with `skip` only acceptable on
  the `live-install` line per the dry-run-mode rule. v0.13.0 emits
  text output by default — there is no `--format` flag in this
  release, and Plan 03 does not pin a JSON shape.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
- **Complexity**: 2
- **Acceptance criteria**:
  - `agent-runtime audit-drift` exits 0 on the clean tree.
  - Captured output contains `ok` (or `clean`-equivalent text) lines
    for `source-manifest`, both `codex-render` rows, both
    `claude-render` rows, `codex-docs-home`, `claude-docs-home`,
    `codex-state-home`, `claude-state-home`.
  - Output contains at most one `skip` row on `live-install`
    (Plan 04 introduces the live-install check; in v0.13.0 the row
    may be absent — either shape is acceptable here).
- **Validation**:
  - `agent-runtime audit-drift`
  - `echo $?`

## Testing Strategy

- Unit: none added in this plan. Render and audit-drift bodies are
  unit-covered in `sympoies/nils-cli` (Plan 02).
- Schema (Test Layer 1): `agent-runtime render --product <p>` runs
  against every manifest edited in Sprint 1; the binary rejects
  malformed manifests and surface placeholders, so a successful
  render after Sprint 1 is the schema gate.
- Render golden (Test Layer 2): Sprint 2 Task 2.1 commits the
  six (skill, product) expected snapshots. CI gate fails on any
  diff from `agent-runtime render --product codex` or
  `agent-runtime render --product claude`.
- Install dry-run (Test Layer 4): **moved to Plan 04 Sprint 5**.
  `agent-runtime install --dry-run` does not exist in v0.13.0; the
  shape pinned by `tests/install/<product>/expected.txt` is owned by
  Plan 04 alongside the install body that produces it.
- Drift fixtures (Test Layer 5): Sprint 2 Task 2.2 commits four
  fixtures (one per POC drift class). CI gate fails when an expected
  report or exit code drifts. Fixtures are mini source roots invoked
  through `audit-drift --source-root <path>` because v0.13.0 has no
  `--fixture` flag.
- Manual: review the rendered Codex and Claude snippets for
  `daily-brief` byte-against the source-doc examples (lines
  1577–1603) before merging Sprint 1.
- Sandbox install rehearsal (Test Layer 6) is intentionally deferred
  to Plan 04 per the source doc.

## Risks & gotchas

- v0.13.0 `agent-runtime render` renders the entire product tree;
  there is no `--domain` / `--skill` filter. CI gates that pin
  per-domain artifacts MUST commit only the relevant subdirectories
  of the build (e.g. only `tests/golden/<product>/plugins/reporting/`)
  even though `--update-golden` rewrites the full
  `tests/golden/<product>/` subtree. Use `git diff` / `git add` to
  scope to the reporting paths.
- v0.13.0 `agent-runtime audit-drift` has no `--format` flag; output
  is text by default. Sprint 2 acceptance pins text-shape stability;
  any future JSON-format work is a Plan 04+ enhancement.
- v0.13.0 `agent-runtime audit-drift` has no `--fixture` flag.
  Drift fixtures invoke the binary with `--source-root <fixture-dir>`
  against self-contained mini source roots; each fixture must carry
  its own `core/` + `manifests/` + `targets/` + `build/` tree as
  needed for the class under test.
- The current claude-kit `reporting` plugin already ships under
  `$HOME/.config/claude/plugins/reporting/`. The migration must not
  overwrite that live tree — Plan 03 only writes into the
  `agent-runtime-kit` source repo. Apply mode (Plan 04) is the only
  path that touches live homes.
- `path_override` for `reporting.topic-radar` is the only legacy
  mapping in this domain. The open question was resolved on
  2026-05-21 (Option A — source doc canonical L555–566 with both
  `codex` and `claude` overrides). If a later decision unifies the
  domain (e.g. Plan 05 cross-domain sweep) every render snapshot in
  Sprint 2 must be regenerated. Treat any post-lock change as a
  Sprint 1 gate before unfreezing goldens.
- `min_version` for Codex and Claude is pinned to the planning host's
  installed versions (`0.130.0` / `2.1.145`) via the Plan 01 cleanup
  PR. A host running an older product will see `audit-drift` warn
  (and, after `2026-06-03`, block) on `version_probe`. Plan 03 does
  not bump per Resolved Decision #7 ceremony — the next bump lands
  in a separate audited PR.
- The Tera helpers `{{ skill_ref(...) }}`, `{{ script(...) }}`, and
  `{{ state_out(...) }}` only render correctly with v0.13.0 of
  nils-cli on PATH via the tap. CI must enforce the formula floor
  before Sprint 1 lands.
- The Plan 02 `state_out` runtime-mode helper emits
  `agent-out path-for --domain <d> [--topic <t>] [--repo <r>]`, but
  the source-doc canonical example (lines 1577–1589) shows
  `agent-out path-for projects --repo "$REPO_SLUG" --topic
  daily-brief --ensure` — a positional `<domain>` argument plus
  `--ensure`. Verify byte-exact output during Sprint 1 Task 1.1
  acceptance; if the helper does not emit the source-doc shape,
  treat the divergence as either a Plan 02 follow-up
  (`state_out` shape fix in nils-cli) or a source-doc rev — discuss
  with reviewer before unfreezing goldens.
- Drift fixture `agent-home-leak` is the canary for the
  `$AGENT_HOME` rejection rule. A regression that lets `$AGENT_HOME`
  through must fail this fixture, not the clean POC audit. Keep both
  in CI.
- `runtime-roots.yaml` carries a date field
  (`min_version_effective_from`). When time passes, the floor
  semantics change from warn to block. Document this in the bump
  PR template so the change is never silent.

## Rollback plan

- Sprint 1 rollback: delete `core/skills/reporting/`, revert the
  reporting entries in all four manifests, delete
  `targets/codex/plugins/reporting/` and `targets/claude/plugins/reporting/`,
  and revert the Sprint 1 commit. No live home is affected.
  `manifests/runtime-roots.yaml` version pins land via the Plan 01
  cleanup PR and survive Sprint 1 rollback. Sprint 2 cannot run
  until Sprint 1 lands again.
- Sprint 2 rollback: delete the relevant `tests/golden/` and
  `tests/drift/` directories and revert. CI gates added in Plan 02
  start failing the moment the snapshots are missing; that is the
  intended signal that the rollback is incomplete.
