# Plan 01 — Skeleton, Manifests, CLI Stubs (Source)

- Status: open, ready for implementation planning
- Date: 2026-05-20
- Source: `docs/source/inventory-target-architecture.md` (frozen inventory +
  target architecture for agent-runtime-kit), specifically the Phase 1 +
  Phase 1.5 sections and the Next Session Checklist items 1–9.
- Scope: foundation pass before any render / install / drift body lands.
  The end-state of this plan is a tracked source-of-truth bundle (skeleton
  directories, baseline `.gitignore`, drift allowlist seed, PR template),
  the five `manifests/*.yaml` source files at `schema_version: 1`, a
  stubbed `agent-runtime` binary cut as `0.12.0` through
  `sympoies/homebrew-tap`, and a host bootstrap skeleton + frozen
  nils-cli surface snapshot in `docs/source/`.

## Execution

- Recommended plan:
  docs/plans/2026-05-20-01-skeleton-and-schema/01-skeleton-and-schema-plan.md
- Recommended execution state:
  docs/plans/2026-05-20-01-skeleton-and-schema/01-skeleton-and-schema-execution-state.md

## Purpose

Phase 1 of the multi-repo agent runtime kit migration. This plan does
NOT migrate any skill bodies, does NOT render any product target, and
does NOT implement install/render/drift logic. Its job is to freeze the
contract surface so Plan 02 (`02-nils-cli-render-and-drift-audit`) can
implement `agent-runtime render` and `agent-runtime audit-drift` against
stable inputs.

The work is intentionally split into four sprints so each can be
demonstrated independently:

1. Repo skeleton, baseline files, drift allowlist, PR template.
2. Manifest JSON schema docs + the five YAML source files (no skill or
   plugin entries yet — those land in Plan 03).
3. `nils-cli/crates/agent-runtime-cli/` opened as a stub crate, all
   subcommands return "not implemented" with exit 1, and a
   `0.12.0` release bumped through `sympoies/homebrew-tap`.
4. `scripts/setup.sh` skeleton (with `agent-runtime install` calls
   stubbed out) plus `docs/source/nils-cli-surface.md` snapshot.

## Current Judgment

- Sprint 3 is cross-repo. It touches `sympoies/nils-cli`,
  `sympoies/homebrew-tap`, and `graysurf/agent-runtime-kit`. The plan
  body marks each task with the owning repo so reviewers do not assume
  it is in-tree work.
- Sprint 2 produces only YAML/JSON source files. Schema validation
  (`agent-runtime render --check`) and render-golden CI gates are
  deferred to Plan 02; if Sprint 2 ships before Plan 02 the manifests
  are checked by `yamllint` + JSON Schema review only.
- The stub release in Sprint 3 is the gate for Plan 02's formula bump
  path. Without it, Plan 02 has nowhere to publish the first real
  binary.

## Source References

- `docs/source/inventory-target-architecture.md`
  - `## Manifest Layer` (around lines 493–580) — schema requirements,
    `schema_version: 1` rule, the five manifests.
  - `## CLI Boundary: nils-cli Owns The CLI Surface` (around lines
    828–988) — nils-cli ownership, `required_clis` contract,
    `<TBD: pin during Phase 1>` placeholder rule.
  - `## Install Channels` → Tap Layout + Brew-First Bootstrap (around
    lines 989–1025) — Homebrew bootstrap, `0.12.0` release context.
  - `## Secrets And Sensitive Data` → Baseline `.gitignore` (around
    lines 1283–1300).
  - Resolved Decision #2 (no standalone CLI, subcommand enumeration).
  - Resolved Decision #7 (Bump Ceremony PR template).
  - `## Migration Phases` → Phase 1 (around lines 1647–1664) and
    Phase 1.5 (around lines 1672–1694).
  - `## Next Session Checklist` items 1–9 (around lines 1904–1934).

## Findings

| Priority | ID | Issue | Evidence | Fix Location | Acceptance |
| --- | --- | --- | --- | --- | --- |
| high | F1 | Repo has no manifest schemas; downstream renders cannot start until source-of-truth YAML files exist with `schema_version: 1`. | `docs/source/inventory-target-architecture.md` §Manifest Layer | `manifests/*.yaml`, `core/docs/schemas/*.json` | Five YAML files plus matching JSON schema docs all carry `schema_version: 1`. |
| high | F2 | No CLI surface to invoke. Phase 1.5's `agent-runtime render` cannot land before the binary exists and is shipped through brew. | Resolved Decision #2; `Install Channels` §Tap Layout | `nils-cli/crates/agent-runtime-cli/`, `sympoies/homebrew-tap` | `brew install sympoies/tap/nils-cli` produces an `agent-runtime` binary that lists every subcommand and exits 1 on each. |
| medium | F3 | Baseline `.gitignore` and drift allowlist seed not present; the first commit of generated build output would otherwise leak. | §Secrets And Sensitive Data Baseline `.gitignore` | `.gitignore`, `drift-audit.allow.yaml` | `.gitignore` matches the doc verbatim; allowlist is tracked, `schema_version: 1`, empty `unsafe_allow`. |
| medium | F4 | Bump-ceremony PR template referenced by Resolved Decision #7 does not exist; the first product-version bump would have nothing to link. | Resolved Decision #7 | `.github/PULL_REQUEST_TEMPLATE/min-version-bump.md` | Template carries the four required sections (impacted environments, tested combinations, rollback, team notice timestamp). |
| medium | F5 | `core/policies/cli-tools.md` is the migration target for `$HOME/.config/agent-kit/CLI_TOOLS.md`. Without it, `manifests/cli-tools.yaml` has no narrative companion. | Next Session Checklist item 7 | `core/policies/cli-tools.md` | File exists; either migrated content or schema-mirroring placeholder. |
| medium | F6 | `docs/source/nils-cli-surface.md` is referenced as the snapshot manifest authors pin `required_clis` against. Until it exists, every `required_clis` floor is unverifiable. | Next Session Checklist item 3 | `docs/source/nils-cli-surface.md` | Captures current `crates/` listing + `git describe --tags`. |
| low | F7 | `scripts/setup.sh` is referenced by Phase 3 but no skeleton exists, so the bootstrap path cannot be reviewed end-to-end yet. | Brew-First Bootstrap; Next Session Checklist item 8 | `scripts/setup.sh` | Skeleton parses `--profile` + `--skip-homebrew-install`; calls into `agent-runtime install` are stubbed until Plan 04. |

## Ownership Boundary

- agent-runtime-kit (this repo): repo skeleton, baseline files, manifest
  YAML + JSON schema docs, policy doc, PR template, setup script,
  nils-cli surface snapshot.
- nils-cli (`sympoies/nils-cli`): new `crates/agent-runtime-cli/` stub
  crate, workspace registration, version `0.12.0`.
- homebrew-tap (`sympoies/homebrew-tap`): formula bump so
  `brew install sympoies/tap/nils-cli` resolves to the stub.

## Cross-Plan Context

- Plan 02 (`02-nils-cli-render-and-drift-audit`) implements the body of
  `agent-runtime render` + `agent-runtime audit-drift` against the
  manifest schemas pinned in Sprint 2 of this plan. It also bumps
  `required_clis` floors against the `0.1.0` release; this plan only
  emits the `<TBD: pin during Phase 1>` placeholder.
- Plan 03 (skill manifest population) writes the first concrete entries
  into `manifests/skills.yaml` / `manifests/plugins.yaml`. Sprint 2 here
  intentionally leaves the `skills:` and `plugins:` lists empty.
- Plans 04–05 (installer, domain migration) consume the
  `scripts/setup.sh` skeleton from Sprint 4 and the `agent-runtime install`
  subcommand body once it lands in nils-cli.

## Retention Intent

- This source doc is execution coordination — delete after Plan 01
  completes and Plan 02's source doc references the same architecture
  doc directly.
- The frozen `docs/source/nils-cli-surface.md` snapshot is durable;
  refreshed on each nils-cli release.
- The five `manifests/*.yaml` files and their JSON schema docs are
  durable source-of-truth files maintained for the life of the repo.

## Open Questions

- Final pin values for `required_clis` — this plan only declares the
  `<TBD: pin during Phase 1>` placeholder per `Manifest Layer` rules;
  the actual `">=X.Y.Z"` values are a Plan 02 gate once the `0.1.0`
  nils-cli release ships.
- Whether `core/policies/cli-tools.md` carries every formula listed in
  the legacy `$HOME/.config/agent-kit/CLI_TOOLS.md` or only the current
  `core` profile. Default for this plan: import the full catalog,
  profile-tag entries in `manifests/cli-tools.yaml`; the `core` /
  `recommended` / `full` split is editorial and revisitable in Plan 04.

## Do Not Do

- Do not implement `agent-runtime render`, `audit-drift`, or `install`
  bodies. Those are Plan 02 / Plan 04 work.
- Do not populate `manifests/skills.yaml` or `manifests/plugins.yaml`
  with any real skill or plugin entries. Plan 03 owns that.
- Do not render any Codex or Claude target. No file under `build/`
  should be committed.
- Do not mutate live `~/.codex` or `~/.claude`. The stub binary exits 1
  on every subcommand by design.
- Do not bump `required_clis` to a concrete version range. The literal
  placeholder is intentional and is the Phase 1 contract.

## Validation Gate

- `plan-tooling validate --file docs/plans/2026-05-20-01-skeleton-and-schema/01-skeleton-and-schema-plan.md --format text --explain`
- `yamllint manifests/`
- `python3 -c 'import json,glob; [json.load(open(p)) for p in glob.glob("core/docs/schemas/*.json")]'`
- `bash -n scripts/setup.sh`
- `grep -F 'schema_version: 1' manifests/skills.yaml manifests/plugins.yaml manifests/product-capabilities.yaml manifests/runtime-roots.yaml manifests/cli-tools.yaml`
- Cross-repo (Sprint 3): `brew install sympoies/tap/nils-cli && agent-runtime --version && agent-runtime render; echo $?`
  (last command must print exit 1.)
