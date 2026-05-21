# Plan: Phase 2 — Reporting Domain POC

## Overview

End-to-end Phase 2 POC for the `reporting` domain. Migrate three skills
(`daily-brief`, `project-retro`, `topic-radar`) from current claude-kit
and agent-kit sources into the new portable `core/` layout, fill in
product adapter metadata for Codex and Claude, fill in the four
relevant manifests, pin render-golden snapshots, pin drift fixtures
covering the four POC drift classes, and pin deterministic dry-run
install plans for both products. No live runtime home is mutated by
this plan — apply lands in Plan 04.

The work runs in four sprints so each milestone is independently
demonstrable against the source doc's "Simulated Reporting POC"
contract (lines 1505–1643).

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
    `manifests/runtime-roots.yaml`.
  - Render-golden snapshots committed under
    `tests/golden/<product>/reporting/` for every reporting skill.
  - Drift fixtures under `tests/drift/<scenario>/` for the four POC
    drift classes (source-manifest, rendered-target diff,
    `$AGENT_HOME` leak, docs-home).
  - Deterministic dry-run install snapshots under
    `tests/install/<product>/expected.txt` for Codex and Claude.
- Out of scope:
  - Any write under a live runtime home (`$HOME/.codex/`,
    `$HOME/.claude/`, or any `CLAUDE_KIT_STATE_HOME` path). Apply mode
    is Plan 04.
  - Migration of any other domain. Plan 05 covers the remaining seven
    domains.
  - The remaining drift classes (`missing` / `stale` / `extra` /
    `intentional-difference` / `unsafe`). Plan 05 lands the full
    `audit-drift` body.
  - Rewriting `topic-radar.sh` as a nils-cli binary. Deferred to the
    extraction backlog.
  - Sandbox install rehearsal (test layer 6). Lands with the installer
    body in Plan 04 per the source doc.

## Assumptions

1. Plan 02 has shipped `agent-runtime render` and the minimal
   `agent-runtime audit-drift` body (source-manifest /
   rendered-target diff / `$AGENT_HOME` leak / docs-home classes)
   through the `sympoies/homebrew-tap` `0.1.0` release. Required CLIs
   floors in Plan 03 manifests pin against that release.
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
5. The development host's product versions on the planning date
   (`codex-cli 0.130.0`, `2.1.145 (Claude Code)`) are accepted as the
   baseline pinned into `manifests/runtime-roots.yaml`.
6. The `min_version_effective_from` runway is 14 days after the Phase
   2 PR merge date (`2026-06-03`), giving existing hosts a soft
   landing before the floor starts blocking.

## Sprint 1: Canonical reporting skill bodies

**Goal**: Land portable canonical bodies for the three reporting
skills under `core/skills/reporting/`, plus the migrated
`topic-radar.sh` script. Bodies use the Tera helpers
`{{ skill_ref(...) }}`, `{{ script(...) }}`, and
`{{ state_out(...) }}`. No `$AGENT_HOME` reference survives.

**Demo/Validation**:

- Command(s):
  - `grep -RnE '\$AGENT_HOME|/\.agents/' core/skills/reporting/`
  - `agent-runtime render --product codex --domain reporting`
  - `agent-runtime render --product claude --domain reporting`
- Verify: grep returns zero matches; rendered Codex and Claude snippets
  for `daily-brief` match the source-doc rendered examples (lines
  1577–1603) byte-exact under `build/`.

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
  - Rendered Codex snippet matches the source-doc Codex example
    (lines 1579–1589) byte-exact.
  - Rendered Claude snippet matches the source-doc Claude example
    (lines 1593–1603) byte-exact.
- **Validation**:
  - `grep -nE '\$AGENT_HOME|/\.agents/' core/skills/reporting/daily-brief/SKILL.md`
  - `agent-runtime render --product codex --domain reporting --skill daily-brief`
  - `agent-runtime render --product claude --domain reporting --skill daily-brief`

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
  - Rendered Codex output references `$CODEX_HOME` paths only.
  - Rendered Claude output references `${CLAUDE_PLUGIN_ROOT}` or
    `$HOME/.claude` paths only.
- **Validation**:
  - `grep -nE '\$AGENT_HOME|/\.agents/' core/skills/reporting/project-retro/SKILL.md`
  - `agent-runtime render --product codex --domain reporting --skill project-retro`
  - `agent-runtime render --product claude --domain reporting --skill project-retro`

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
  - Rendered Codex output references
    `$CODEX_HOME/plugins/reporting/skills/topic-radar/scripts/topic-radar.sh`.
  - Rendered Claude output references
    `${CLAUDE_PLUGIN_ROOT}/scripts/topic-radar.sh`.
- **Validation**:
  - `grep -nE '\$AGENT_HOME|/\.agents/' core/skills/reporting/topic-radar/`
  - `test -x core/skills/reporting/topic-radar/scripts/topic-radar.sh`
  - `agent-runtime render --product codex --domain reporting --skill topic-radar`
  - `agent-runtime render --product claude --domain reporting --skill topic-radar`

## Sprint 2: Product adapter metadata and manifest fill

**Goal**: Land Codex and Claude adapter metadata files for the
reporting plugin, then fill in the four manifests with concrete
reporting entries. No `<TBD>` `required_clis` values are permitted —
every floor pins to `>=0.1.0` or higher against the Phase 1.5 nils-cli
release.

**Demo/Validation**:

- Command(s):
  - `agent-runtime render --check`
  - `jq . targets/codex/plugins/reporting/.codex-plugin/plugin.json`
  - `jq . targets/claude/plugins/reporting/.claude-plugin/plugin.json`
  - `yq '.skills[] | select(.id | startswith("reporting"))' manifests/skills.yaml`
- Verify: render `--check` exits 0; all four manifests carry
  reporting entries with concrete `required_clis` floors; both
  adapter `plugin.json` files parse as valid JSON.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 2.1: Write Codex adapter metadata

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
  - `agent-runtime render --check --product codex --domain reporting`

### Task 2.2: Write Claude adapter metadata

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
  - `agent-runtime render --check --product claude --domain reporting`

### Task 2.3: Fill `manifests/skills.yaml` with reporting entries

- **Location**:
  - `manifests/skills.yaml`
- **Description**: Append three skill entries (`reporting.daily-brief`,
  `reporting.project-retro`, `reporting.topic-radar`) using the
  example slice in the source doc lines 1520–1554 as the shape.
  Replace every `<TBD: pin during Phase 1>` placeholder with a
  concrete `">=0.1.0"` value pinned against the Phase 1.5 nils-cli
  release. Set `state_out_mode: runtime` on all three. For
  `reporting.topic-radar`, set
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
    `<TBD>` strings remain in the file.
  - `reporting.topic-radar` carries both
    `products.codex.path_override` and `products.claude.path_override`
    pointing at the legacy invocation paths on each product,
    matching source doc canonical L555–566 verbatim.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.skills[] | select(.id | startswith("reporting")) | .required_clis' manifests/skills.yaml`
  - `agent-runtime render --check`

### Task 2.4: Fill `manifests/plugins.yaml` with the reporting plugin entry

- **Location**:
  - `manifests/plugins.yaml`
- **Description**: Append a single `reporting` plugin entry that
  enumerates the three contained skills, declares product manifests
  (`targets/codex/plugins/reporting/.codex-plugin/plugin.json` and
  `targets/claude/plugins/reporting/.claude-plugin/plugin.json`), and
  carries the install policy. Default policy: install on both Codex
  and Claude; no inter-plugin dependencies.
- **Dependencies**:
  - Task 2.1
  - Task 2.2
  - Task 2.3
- **Complexity**: 3
- **Acceptance criteria**:
  - Entry exists under `plugins:` with `id: reporting`.
  - `contained_skills` enumerates the three canonical IDs.
  - `product_manifests.codex` and `product_manifests.claude` point at
    the two adapter `plugin.json` paths from Tasks 2.1 and 2.2.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.plugins[] | select(.id == "reporting")' manifests/plugins.yaml`
  - `agent-runtime render --check`

### Task 2.5: Fill `manifests/product-capabilities.yaml`

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
  - Task 2.1
  - Task 2.2
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
  - `agent-runtime render --check`

### Task 2.6: Fill `manifests/runtime-roots.yaml` with the root-map block

- **Location**:
  - `manifests/runtime-roots.yaml`
- **Description**: Land the per-product root map verbatim from the
  source-doc example block (lines 1221–1244), with concrete versions
  pinned from the development host on the planning date: Codex
  `min_version: "0.130.0"`, `recommended_version: "0.130.0"`; Claude
  `min_version: "2.1.145"`, `recommended_version: "2.1.145"`. Set
  `min_version_effective_from: "2026-06-03"` on both products (14
  days after Phase 2 PR merge target). Preserve every other field
  shape from the source doc example.
- **Dependencies**:
  - none
- **Complexity**: 4
- **Acceptance criteria**:
  - `products.codex.min_version` is `"0.130.0"`.
  - `products.claude.min_version` is `"2.1.145"`.
  - Both products carry
    `min_version_effective_from: "2026-06-03"`.
  - Both products carry the `version_probe`, `state_home`,
    `docs_home`, `live_home`, `plugin_root` (or
    `plugin_root_env`) fields from the source-doc example.
  - `schema_version: 1` is preserved at the file top.
- **Validation**:
  - `yq '.products.codex.min_version, .products.claude.min_version' manifests/runtime-roots.yaml`
  - `yq '.products.codex.min_version_effective_from, .products.claude.min_version_effective_from' manifests/runtime-roots.yaml`
  - `agent-runtime render --check`

## Sprint 3: Render goldens, drift fixtures, end-to-end render

**Goal**: Lock the rendered output for both products with golden
snapshots, exercise the four POC drift classes through pinned
fixtures, and confirm `audit-drift` exits 0 on the clean POC.

**Demo/Validation**:

- Command(s):
  - `agent-runtime render --update-golden --domain reporting`
  - `git diff --exit-code tests/golden/`
  - `agent-runtime audit-drift --format text`
  - `agent-runtime audit-drift --fixture tests/drift/source-manifest-missing/`
  - `agent-runtime audit-drift --fixture tests/drift/rendered-target-diff/`
  - `agent-runtime audit-drift --fixture tests/drift/agent-home-leak/`
  - `agent-runtime audit-drift --fixture tests/drift/docs-home-mismatch/`
- Verify: golden snapshots committed and stable; clean tree exits 0;
  each drift fixture pins both the expected report text and the
  expected exit code.

**PR grouping intent**: `group`
**Execution Profile**: `serial`

### Task 3.1: Generate and commit render-golden snapshots

- **Location**:
  - `tests/golden/codex/reporting/daily-brief/expected/SKILL.md`
  - `tests/golden/codex/reporting/project-retro/expected/SKILL.md`
  - `tests/golden/codex/reporting/topic-radar/expected/SKILL.md`
  - `tests/golden/codex/reporting/topic-radar/expected/scripts/topic-radar.sh`
  - `tests/golden/claude/reporting/daily-brief/expected/SKILL.md`
  - `tests/golden/claude/reporting/project-retro/expected/SKILL.md`
  - `tests/golden/claude/reporting/topic-radar/expected/SKILL.md`
  - `tests/golden/claude/reporting/topic-radar/expected/scripts/topic-radar.sh`
- **Description**: Run `agent-runtime render --update-golden --domain
  reporting` to produce the byte-exact target snapshots, review the
  diff per Test Layer 2 in the source doc (lines 1423–1428), then
  commit. Snapshots cover every (skill, product) pair. Validate the
  `daily-brief` Codex and Claude snapshots match the source-doc
  rendered examples (lines 1577–1603) byte-exact.
- **Dependencies**:
  - Task 1.1
  - Task 1.2
  - Task 1.3
  - Task 2.1
  - Task 2.2
  - Task 2.3
  - Task 2.6
- **Complexity**: 4
- **Acceptance criteria**:
  - Six expected/ directories exist and are non-empty.
  - `agent-runtime render --domain reporting` produces zero diff
    against the committed snapshots.
  - The `daily-brief` Codex snapshot contains
    `$CODEX_HOME/plugins/reporting/skills/topic-radar/scripts/topic-radar.sh`.
  - The `daily-brief` Claude snapshot contains
    `${CLAUDE_PLUGIN_ROOT}/scripts/topic-radar.sh`.
  - No snapshot contains a `$AGENT_HOME` reference.
- **Validation**:
  - `agent-runtime render --domain reporting`
  - `git diff --exit-code tests/golden/`
  - `grep -RnE '\$AGENT_HOME' tests/golden/codex/reporting/ tests/golden/claude/reporting/`

### Task 3.2: Add drift fixtures for the four POC drift classes

- **Location**:
  - `tests/drift/source-manifest-missing/expected.txt`
  - `tests/drift/source-manifest-missing/expected.exit`
  - `tests/drift/rendered-target-diff/expected.txt`
  - `tests/drift/rendered-target-diff/expected.exit`
  - `tests/drift/agent-home-leak/expected.txt`
  - `tests/drift/agent-home-leak/expected.exit`
  - `tests/drift/docs-home-mismatch/expected.txt`
  - `tests/drift/docs-home-mismatch/expected.exit`
- **Description**: For each drift class, build a synthetic input tree
  under the fixture directory and pin both the expected text report
  (`expected.txt`) and the expected exit code (`expected.exit`).
  Classes:
  - `source-manifest-missing`: a manifest references a skill source
    path that does not exist under `core/skills/`.
  - `rendered-target-diff`: the rendered `build/` output differs from
    a committed golden snapshot.
  - `agent-home-leak`: a rendered file contains `$AGENT_HOME`.
  - `docs-home-mismatch`: a rendered docs reference uses the wrong
    product's `docs_home` (e.g. Claude render points at
    `$CODEX_HOME`).
- **Dependencies**:
  - Task 3.1
- **Complexity**: 6
- **Acceptance criteria**:
  - Each fixture directory contains an `input/` tree, an
    `expected.txt` report, and an `expected.exit` code file.
  - Each fixture, when passed to `agent-runtime audit-drift
    --fixture`, produces a report that diffs cleanly against
    `expected.txt`.
  - The exit code from each fixture run matches the value in
    `expected.exit`.
  - The `agent-home-leak` fixture exits with `2` (block).
  - The clean POC tree (no fixture override) exits `0`.
- **Validation**:
  - `agent-runtime audit-drift --fixture tests/drift/source-manifest-missing/`
  - `agent-runtime audit-drift --fixture tests/drift/rendered-target-diff/`
  - `agent-runtime audit-drift --fixture tests/drift/agent-home-leak/`
  - `agent-runtime audit-drift --fixture tests/drift/docs-home-mismatch/`
  - `agent-runtime audit-drift --format text`

### Task 3.3: Confirm clean POC audit-drift exits 0

- **Location**:
  - `tests/audit-drift/clean-poc-expected.txt`
  - `manifests/skills.yaml`
  - `manifests/plugins.yaml`
  - `manifests/runtime-roots.yaml`
- **Description**: Run `agent-runtime audit-drift --format text`
  against the clean POC tree (no fixture override) and capture the
  output. Confirm every check listed in the source-doc drift-audit
  example (lines 1632–1642) returns `ok` or `skip`, with `skip` only
  acceptable on the `live-install` line per the dry-run-mode rule.
- **Dependencies**:
  - Task 3.1
  - Task 3.2
- **Complexity**: 2
- **Acceptance criteria**:
  - `agent-runtime audit-drift --format text` exits 0 on the clean
    tree.
  - Output contains `ok` for `source-manifest`, both `codex-render`
    rows, both `claude-render` rows, `codex-docs-home`,
    `claude-docs-home`, `codex-state-home`, `claude-state-home`.
  - Output contains exactly one `skip` row on `live-install`.
- **Validation**:
  - `agent-runtime audit-drift --format text`
  - `echo $?`

## Sprint 4: Dry-run install snapshots

**Goal**: Pin deterministic `agent-runtime install --dry-run` plan
output for both products. Confirm the install scope touches only the
narrow surfaces documented in the source doc (Codex `AGENTS.md` and
the managed `config.toml` block; Claude `settings.json` and the link
map). No live-home mutation in this sprint — apply mode is Plan 04.

**Demo/Validation**:

- Command(s):
  - `agent-runtime install --product codex --dry-run`
  - `agent-runtime install --product claude --dry-run`
  - `diff -u tests/install/codex/expected.txt <(agent-runtime install --product codex --dry-run)`
  - `diff -u tests/install/claude/expected.txt <(agent-runtime install --product claude --dry-run)`
- Verify: both dry-run plans produce zero diff against the pinned
  snapshots; neither plan touches `auth.json`, `.credentials*`, any
  `**/sessions/`, `**/history/`, or `**/cache/` path.

**PR grouping intent**: `group`
**Execution Profile**: `parallel-x2`

### Task 4.1: Pin Codex dry-run install snapshot

- **Location**:
  - `tests/install/codex/expected.txt`
- **Description**: Capture `agent-runtime install --product codex
  --dry-run` output against the clean POC tree and commit it as the
  expected snapshot. Format the snapshot to match the
  source-doc "Dry-run install output" example shape (lines
  1612–1628), with the Codex stanza covering `source` path,
  `render_to` path, `docs_home=$CODEX_HOME`,
  `state_home=${CODEX_AGENT_STATE_HOME:-...}`, and the live target
  candidate `$CODEX_HOME/plugins/reporting`.
- **Dependencies**:
  - Task 3.1
  - Task 3.3
- **Complexity**: 3
- **Acceptance criteria**:
  - `tests/install/codex/expected.txt` exists and is committed.
  - The snapshot opens with `DRY render product=codex domain=reporting`.
  - The snapshot includes the exact `docs_home=$CODEX_HOME` line.
  - The snapshot includes the exact
    `state_home=${CODEX_AGENT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/codex}`
    line.
  - The snapshot ends with the
    `No live files changed. Re-run with --apply after drift audit passes.`
    sentinel.
  - The snapshot contains zero references to `auth.json`,
    `.credentials`, `sessions/`, `history/`, or `cache/`.
- **Validation**:
  - `diff -u tests/install/codex/expected.txt <(agent-runtime install --product codex --dry-run)`
  - `grep -nE 'auth\.json|\.credentials|sessions/|history/|cache/' tests/install/codex/expected.txt`

### Task 4.2: Pin Claude dry-run install snapshot

- **Location**:
  - `tests/install/claude/expected.txt`
- **Description**: Capture `agent-runtime install --product claude
  --dry-run` output against the clean POC tree and commit it as the
  expected snapshot. Format to match the source-doc shape (lines
  1620–1628) for the Claude stanza: `source` path, `render_to` path,
  `docs_home=$HOME/.claude`,
  `state_home=${CLAUDE_KIT_STATE_HOME:-...}`, and the live target
  candidate `$HOME/.claude/plugins/reporting`.
- **Dependencies**:
  - Task 3.1
  - Task 3.3
- **Complexity**: 3
- **Acceptance criteria**:
  - `tests/install/claude/expected.txt` exists and is committed.
  - The snapshot opens with `DRY render product=claude domain=reporting`.
  - The snapshot includes the exact `docs_home=$HOME/.claude` line.
  - The snapshot includes the exact
    `state_home=${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude}`
    line.
  - The snapshot ends with the
    `No live files changed. Re-run with --apply after drift audit passes.`
    sentinel.
  - The snapshot contains zero references to `auth.json`,
    `.credentials`, `sessions/`, `history/`, or `cache/`.
- **Validation**:
  - `diff -u tests/install/claude/expected.txt <(agent-runtime install --product claude --dry-run)`
  - `grep -nE 'auth\.json|\.credentials|sessions/|history/|cache/' tests/install/claude/expected.txt`

## Testing Strategy

- Unit: none added in this plan. Render and audit-drift bodies are
  unit-covered in `sympoies/nils-cli` (Plan 02).
- Schema (Test Layer 1): `agent-runtime render --check` runs against
  every manifest edited in Sprint 2; CI gate enforces non-zero
  duplicate canonical IDs and dangling source paths.
- Render golden (Test Layer 2): Sprint 3 Task 3.1 commits the
  six (skill, product) expected snapshots. CI gate fails on any
  diff from `agent-runtime render --domain reporting`.
- Install dry-run (Test Layer 4): Sprint 4 Tasks 4.1 and 4.2 pin
  `tests/install/<product>/expected.txt`. CI gate fails on any diff.
- Drift fixtures (Test Layer 5): Sprint 3 Task 3.2 commits four
  fixtures (one per POC drift class). CI gate fails when an expected
  report or exit code drifts.
- Manual: review the rendered Codex and Claude snippets for
  `daily-brief` byte-against the source-doc examples (lines
  1577–1603) before merging Sprint 1.
- Sandbox install rehearsal (Test Layer 6) is intentionally deferred
  to Plan 04 per the source doc.

## Risks & gotchas

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
  Sprint 3 must be regenerated. Treat any post-lock change as a
  Sprint 2 gate before unfreezing goldens.
- `min_version` for Codex and Claude is pinned to the planning host's
  installed versions. A host running an older product will see
  `audit-drift` warn (and, after `2026-06-03`, block) on
  `version_probe`. Plan 03 does not bump per Resolved Decision #7
  ceremony — the next bump lands in a separate audited PR.
- The Tera helpers `{{ skill_ref(...) }}`, `{{ script(...) }}`, and
  `{{ state_out(...) }}` only render correctly once Plan 02's
  `0.1.0` nils-cli release is on PATH via the tap. CI must enforce
  the formula floor before Sprint 1 lands.
- Drift fixture `agent-home-leak` is the canary for the
  `$AGENT_HOME` rejection rule. A regression that lets `$AGENT_HOME`
  through must fail this fixture, not the clean POC audit. Keep both
  in CI.
- `runtime-roots.yaml` carries a date field
  (`min_version_effective_from`). When time passes, the floor
  semantics change from warn to block. Document this in the bump
  PR template so the change is never silent.

## Rollback plan

- Sprint 1 rollback: delete `core/skills/reporting/` and revert the
  Sprint 1 commit. No live home is affected. Subsequent sprints
  cannot run until Sprint 1 lands again.
- Sprint 2 rollback (per task): each `.codex-plugin/plugin.json`,
  `.claude-plugin/plugin.json`, and manifest fill is its own commit.
  Reverting one leaves the others intact. `manifests/runtime-roots.yaml`
  revert restores the prior baseline floors; Plan 02 schema validation
  is unaffected because the file shape stays valid.
- Sprint 3 rollback: delete the relevant `tests/golden/` and
  `tests/drift/` directories and revert. CI gates added in Plan 02
  start failing the moment the snapshots are missing; that is the
  intended signal that the rollback is incomplete.
- Sprint 4 rollback: delete `tests/install/<product>/expected.txt` and
  revert. No live home is affected. The dry-run snapshots are
  byte-deterministic, so re-pinning is mechanical.
