# Execution State: Codex / Claude runtime divergence

## Execution State

- Source document: docs/plans/2026-06-20-codex-claude-runtime-divergence/2026-06-20-codex-claude-runtime-divergence-plan.md
- Tracking issue: <https://github.com/graysurf/agent-runtime-kit/issues/438>
- Current sprint: Sprint 4 (complete)
- Status: complete; tracking issue closed
- Branch: `feat/codex-claude-runtime-divergence`
- Last updated: 2026-06-20
- Branch/commit/PR: graysurf/agent-runtime-kit#442 merged (https://github.com/graysurf/agent-runtime-kit/pull/442)

## Task Ledger

| ID | Title | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1.1 | R1 — per-product home-prompt render target | done | sympoies/nils-cli#918; `agent-runtime render --target home-prompt` released in v1.12.1 | upstream render view supports neutral / Codex / Claude home prompt output |
| 1.2 | C1 — `product` field on catalog parser/model | done | sympoies/nils-cli#918; release v1.12.1 | upstream catalog accepts validated product scope on documents and validations |
| 1.3 | C1 — `preflight --product` + resolver filter + preflight.v2 | done | sympoies/nils-cli#918; `agent-docs preflight --intent project-dev --product codex --format json` reports `agent-docs.preflight.v2` | unset remains include-all; Codex / Claude filters match |
| 1.4 | Upstream acceptance (goldens/schema/tests) | done | sympoies/nils-cli#918 merged; v1.12.1 release checks passed | release carried upstream tests and goldens |
| 2.1 | Land + release nils-cli + tap + brew upgrade | done | sympoies/nils-cli#919; release `v1.12.1`; Homebrew tap workflow succeeded; local `agent-runtime --version` and `agent-docs --version` report 1.12.1 | Mac host upgraded after `brew update` + `brew upgrade sympoies/tap/nils-cli` |
| 2.2 | Pin bump + required_clis floors | done | `docs/source/nils-cli-pin.yaml`; `agent-runtime doctor --class version-alignment --pin docs/source/nils-cli-pin.yaml --format text` block=0 | `agent-docs` and `agent-runtime` floors raised to 1.12.1 |
| 3.1 | Render per-product `AGENT_HOME` + retarget `setup.sh` | done | `AGENT_HOME.md`; `scripts/setup.sh`; `tests/runtime-smoke/cases/meta/run.sh`; `bash scripts/ci/all.sh` positions 3, 6, 11 passed | setup now renders home prompts and rewires prior managed raw symlinks to product render outputs |
| 3.2 | Remove Codex-only prose from shared body + Claude render | done | `tests/golden/codex/AGENT_HOME.md`; `tests/golden/claude/AGENT_HOME.md`; `bash scripts/ci/product-leak-audit.sh` passed | Codex render contains Code Review Delegation; Claude render omits it |
| 3.3 | SUPPORT_MATRIX golden + audit-drift + harness-shape | done | `tests/golden/shared/SUPPORT_MATRIX.md`; `docs/source/harness-shape-codex.md`; `docs/source/harness-shape-claude.md`; `agent-runtime audit-drift` clean | rows 1 and 17 now describe rendered home prompt mechanics |
| 4.1 | Hook `--product` forwarding + validation parity | done | `core/hooks/shared/user-prompt-agent-docs.sh`; `core/hooks/shared/hook_common.py`; `bash tests/hooks/run.sh` passed | cache key now includes product; cue and finish-line gate both capability-probe and forward `--product` |
| 4.2 | `product=codex` catalog doc (parity backstop) | done | `AGENT_DOCS.toml`; `core/policies/code-review-delegation-codex.md`; Codex preflight includes the doc; Claude preflight omits it; `agent-docs audit --target all --strict` passed | registered as project-scoped product document so linked worktree validation resolves the new file |
| 4.3 | Broad-sentinel leakage lint (post-#436 scope) | done | `scripts/ci/product-leak-audit.sh`; `scripts/ci/product-leak-allow.yaml`; self-test and normal scan passed | scans rendered homes, rendered plugins / agents, and loaded target plugin / marketplace artifacts |
| 4.4 | Full acceptance + runtime-smoke | done | `bash scripts/ci/all.sh` positions 1-15 OK; `bash tests/hooks/run.sh` OK; `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` OK | review found and fixed one clean-checkout CI-ordering issue before final validation |

## Validation Log

- 2026-06-20: bundle authored from the `docs/discussions` evaluation capture and graduated to this L2 bundle. #436 drift folded in.
- 2026-06-20: upstream nils-cli R1/C1 delivered via sympoies/nils-cli#918, released as `v1.12.1` via sympoies/nils-cli#919, and consumed by this repo with the pin moved to `v1.12.1`.
- 2026-06-20: runtime-kit validation passed: `agent-docs audit --target all --strict`; Codex and Claude product preflights; `bash scripts/ci/all.sh` from a clean generated-home state; `bash tests/hooks/run.sh`; `bash scripts/ci/product-leak-audit.sh --self-test`; `bash scripts/ci/product-leak-audit.sh`.
- 2026-06-20: pre-merge review gate ran with testing, maintainability, api-contract, and red-team lenses. Finding: `scripts/ci/all.sh` depended on pre-existing generated home prompt files. Disposition: fixed-now by rendering neutral / Codex / Claude home prompts inside position 3 and the golden refresh in position 6; clean-start full gate passed afterward.

## Session Notes

- 2026-06-20: graduated from `docs/discussions/2026-06-20-codex-claude-runtime-divergence.md` to this bundle after the four decisions (D1 per-product render home, D2 broad-sentinel lint, D3 preflight v2, D4 build C1 now) were resolved.
- 2026-06-20: #436 (`f10e12b`, Codex plugin/marketplace adoption) analyzed for drift. Key facts for the executor: the home prompt is still a raw symlink wired by `scripts/setup.sh` (R1 owns the cutover, surfaces rows 1 + 17); agent-docs / `AGENT_DOCS.toml` / the hooks are untouched by #436 (C1 is greenfield there); the leakage lint must enumerate the post-#436 gated Codex plugin/marketplace artifacts because `config_activation` is stale; and #436 forced no pin bump, so this plan's bump is owned here.
- 2026-06-20: gate-first sequencing — ship R1 + C1 in `sympoies/nils-cli`, release and pin-bump, then consume in this repo (home cutover, then hook wiring + lint + acceptance). Reuse #436's `--product` + feature-gate and capability-flag conventions.
