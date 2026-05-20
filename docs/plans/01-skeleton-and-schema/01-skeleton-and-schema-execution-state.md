# Plan 01 — Skeleton, Manifests, CLI Stubs Execution State

## Current State

- Status: not started
- Target scope: whole plan
- Execution window: undecided
- Staged execution confirmation: not applicable
- Current task: Task 1.1
- Next task: Task 1.1
- Last updated: 2026-05-20
- Branch/commit: not started
- Source document: docs/plans/01-skeleton-and-schema/01-skeleton-and-schema-plan.md
- Direct source-doc execution waiver: not applicable

## Task Ledger

| ID       | Status  | Task                                                          | Evidence | Notes                                                                                  |
| -------- | ------- | ------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| Task 1.1 | pending | Create top-level skeleton directories                         | n/a      | gates every later sprint                                                               |
| Task 1.2 | pending | Write top-level `.gitignore`                                  | n/a      | depends on 1.1                                                                         |
| Task 1.3 | pending | Seed `drift-audit.allow.yaml`                                 | n/a      | tracked allowlist seed; `schema_version: 1`                                            |
| Task 1.4 | pending | Write Bump Ceremony PR template                               | n/a      | implements Resolved Decision #7                                                        |
| Task 2.1 | pending | Write `skills.yaml` schema and source file                    | n/a      | empty `skills: []`; Plan 03 populates                                                  |
| Task 2.2 | pending | Write `plugins.yaml` schema and source file                   | n/a      | empty `plugins: []`; Plan 03 populates                                                 |
| Task 2.3 | pending | Write `product-capabilities.yaml` schema and source file      | n/a      | settled architecture; codex + claude entries                                           |
| Task 2.4 | pending | Write `runtime-roots.yaml` schema and source file             | n/a      | version pin fields carry `<TBD: pin during Phase 1>`                                   |
| Task 2.5 | pending | Write `cli-tools.yaml` schema and source file                 | n/a      | depends on 2.6 for formula catalog                                                     |
| Task 2.6 | pending | Migrate `CLI_TOOLS.md` to `core/policies/cli-tools.md`        | n/a      | reads `$HOME/.config/agent-kit/CLI_TOOLS.md`; placeholder fallback files a Blocker     |
| Task 3.1 | pending | Open `agent-runtime-cli` crate stub in nils-cli               | n/a      | cross-repo: `sympoies/nils-cli`; record commit SHA here                                |
| Task 3.2 | pending | Register `agent-runtime-cli` in workspace Cargo.toml          | n/a      | cross-repo: `sympoies/nils-cli`; record commit SHA here                                |
| Task 3.3 | pending | Cut `0.0.1-dev` nils-cli release                              | n/a      | cross-repo: `sympoies/nils-cli`; record tag, release URL, tarball SHA256 here          |
| Task 3.4 | pending | Bump formula in `sympoies/homebrew-tap`                       | n/a      | cross-repo: `sympoies/homebrew-tap`; record commit SHA here                            |
| Task 4.1 | pending | Write `scripts/setup.sh` skeleton                             | n/a      | `agent-runtime install` calls stubbed until Plan 04                                    |
| Task 4.2 | pending | Freeze nils-cli surface snapshot in `docs/source/`            | n/a      | depends on 3.3; pin source for `required_clis`                                         |

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/01-skeleton-and-schema/01-skeleton-and-schema-plan.md --format text --explain` | pending | run before first commit | n/a |
| `python3 -c 'import yaml,glob; [yaml.safe_load(open(p)) for p in sorted(glob.glob("manifests/*.yaml"))]'` | pending | Sprint 2 — every YAML parses | n/a |
| `python3 -c 'import json,glob; [json.load(open(p)) for p in glob.glob("core/docs/schemas/*.json")]'` | pending | Sprint 2 — every JSON schema parses | n/a |
| `grep -F 'schema_version: 1' manifests/skills.yaml manifests/plugins.yaml manifests/product-capabilities.yaml manifests/runtime-roots.yaml manifests/cli-tools.yaml` | pending | Sprint 2 — `schema_version: 1` rule | n/a |
| `cd ~/Project/sympoies/nils-cli && cargo build -p agent-runtime-cli` | pending | Sprint 3 — stub crate builds | n/a |
| `cd ~/Project/sympoies/nils-cli && for sub in render install uninstall doctor audit-drift gc-backups restore-backups purge-state; do cargo run -q -p agent-runtime-cli -- "$sub" 2>&1 \| grep -q "not implemented" \|\| { echo "fail: $sub"; exit 1; }; done` | pending | Sprint 3 — every subcommand stub exits 1 | n/a |
| `brew update && brew reinstall sympoies/tap/nils-cli && agent-runtime --version \| grep -F 0.0.1-dev` | pending | Sprint 3 — install ladder reachable | n/a |
| `bash -n scripts/setup.sh && scripts/setup.sh --profile core --dry-run` | pending | Sprint 4 — bootstrap script parses + dry-run | n/a |
| `test -f docs/source/nils-cli-surface.md && grep -F 'required_clis' docs/source/nils-cli-surface.md` | pending | Sprint 4 — surface snapshot present | n/a |

## Blockers

- none

## Session Log

(none yet)
