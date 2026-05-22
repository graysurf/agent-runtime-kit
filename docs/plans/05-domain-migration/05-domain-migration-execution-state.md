# Phase 4 Domain Migration Sweep Execution State

## Current State

- Status: complete
- Target scope: Sprint 1 through Sprint 9
- Execution window: Sprint 8 overlay gates and Sprint 9 legacy archive/cutover
- Staged execution confirmation: not applicable
- Current task: Plan 05 implementation complete; issue closeout pending
- Next task: Run tracking issue closeout for issue #26
- Last updated: 2026-05-22 23:08 CST
- Branch/commit/PR: main; merge commit `b402fc2660831940f8f695e7f4d549e72fb520e8`; PR #40 merged
- Source document: docs/plans/05-domain-migration/05-domain-migration-plan.md
- Direct source-doc execution waiver: not applicable

## Plan 06 Acceptance Dependency

Plan 05 Sprint 5+ must not resume until the Plan 06 runtime skill acceptance
harness is in place and deterministic acceptance is green for every Sprint 1-4
migrated skill, or the affected case has an explicit `skip-host-capability`
classification. The required continuation checks are:

- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic`
- `bash scripts/ci/all.sh`

Product-in-the-loop smoke is a quarantined/manual evidence lane, not a required
Sprint 5 blocker. Product prompt execution remains skipped by default unless an
operator supplies isolated provider/auth state; any `blocked-design` product
result must be recorded before migration proceeds past the affected surface.

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | done | Re-verify Plan 03 reporting POC | `bash scripts/ci/all.sh` pass | Baseline reporting POC/full gate passed before meta edits |
| Task 1.2 | done | Migrate policy and state meta skills | `core/skills/meta/{agent-docs,agent-out,agent-scope-lock}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 1.3 | done | Migrate workflow meta skills | `core/skills/meta/{heuristic-inbox,repo-retro,semantic-commit}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 1.4 | done | Wire meta manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/` | Shared meta integration rendered for Codex and Claude |
| Task 2.1 | done | Migrate media skill sources | `core/skills/media/{image-processing,screen-record}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 2.2 | done | Migrate browser skill sources | `core/skills/browser/{browser-session,canary-check}/SKILL.md.tera` | Bodies invoke released nils-cli primitives only |
| Task 2.3 | done | Wire media/browser manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/` | Media and browser plugins render/install dry-run cleanly |
| Task 3.1 | done | Migrate web and test-first evidence sources | `core/skills/evidence/{web-evidence,test-first-evidence}/SKILL.md.tera` | Evidence capture lane A invokes released nils-cli primitives only |
| Task 3.2 | done | Migrate review and skill-usage evidence sources | `core/skills/evidence/{review-evidence,skill-usage}/SKILL.md.tera` | Evidence capture lane B invokes released nils-cli primitives only |
| Task 3.3 | done | Wire evidence capture manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/` | Evidence capture plugin integration rendered for both products |
| Task 4.1 | done | Migrate docs-impact source | `core/skills/evidence/docs-impact/SKILL.md.tera` | Body invokes `docs-impact` and separates CLI classification from judgment |
| Task 4.2 | done | Migrate model-cross-check source | `core/skills/evidence/model-cross-check/SKILL.md.tera` | Body records provider-boundary notes and invokes `model-cross-check` |
| Task 4.3 | done | Finalize evidence domain integration | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/`, `docs/source/extraction-backlog.md` | Complete evidence domain gate passed; no extraction blocker found |
| Task 5.1 | done | Migrate PR/MR create skills | `core/skills/pr/{create-github-pr,create-gitlab-mr,create-dispatch-lane-pr}/SKILL.md.tera` | Create bodies invoke released `forge-cli pr create` surfaces only. |
| Task 5.2 | done | Migrate PR/MR close skills and wire create/close integration | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/`, runtime-smoke `pr` probes | Create/close PR plugin integration rendered for both products; `forge-cli` dry-run smoke passed. |
| Task 6.1 | done | Migrate delivery skill sources | `core/skills/pr/{deliver-github-pr,deliver-gitlab-mr}/SKILL.md.tera` | Delivery bodies invoke released `forge-cli pr deliver` surfaces only. |
| Task 6.2 | done | Add delivery lifecycle smoke harness | `tests/smoke/deliver-lifecycle.sh` | Harness dry-run, target guards, repeatable scratch branch setup, and live scratch PR delivery passed. |
| Task 6.3 | done | Wire delivery manifests, golden snapshots, and PR domain gate | manifests, plugin manifests, sandbox pins, `tests/golden/`, runtime-smoke `pr` probes | Integration and deterministic dry-run pass; `P5-S5-G1` closed by nils-cli `v0.17.1`, and live Sprint 6 smoke passed against `graysurf/agent-runtime-kit-smoke`. |
| Task 7.1 | done | Migrate issue lifecycle dispatch sources | `core/skills/dispatch/{plan-tracking-issue,issue-lifecycle,tracking-issue-closeout}/SKILL.md.tera` | Bodies invoke released `plan-tooling`, `plan-issue`, and `plan-issue-local` surfaces only. |
| Task 7.2 | done | Migrate execution and dispatch orchestration sources | `core/skills/dispatch/{execute-from-tracking-issue,deliver-tracking-issue,dispatch-pr-review,dispatch-subagent-pr}/SKILL.md.tera` | Bodies invoke released `forge-cli`, `plan-issue`, and `review-evidence` surfaces only. |
| Task 7.3 | done | Wire dispatch manifests, adapters, and golden snapshots | manifests, link maps, plugin manifests, sandbox pins, `tests/golden/`, runtime-smoke `dispatch` probes | Dispatch plugin integration rendered for both products; deterministic dispatch smoke passed. |
| Task 8.1 | done | Audit private overlay effective config | `agent-runtime install --product claude --dry-run`; `agent-runtime install --product codex --dry-run`; `agent-runtime audit-drift` pass | No `.private` overlay files present; dry-run install resolved 39 skills / 49 actions per product without mutating real homes |
| Task 8.2 | done | Verify project-local overlay smoke gate | `bash tests/projects/project-local-smoke/run.sh`; `agent-runtime doctor --check-project` through fixture; `bash scripts/ci/all.sh` pass | Added six project-local shim sources and fixture scripts for `bench`, `bootstrap`, `demo`, `deploy`, `pre-pr`, and `release` |
| Task 9.1 | done | Prepare legacy repository archive markers | `graysurf/agent-kit` `11559d656ab64b409d33f6321bc9b65a42b59169`; `graysurf/claude-kit` `194a1ec239b67eb3fa4b47a7baea13e2ab561965` | Root `MOVED.md` committed and pushed in both legacy repos |
| Task 9.2 | done | Archive legacy repositories on GitHub | `gh api -X PATCH repos/graysurf/{agent-kit,claude-kit} -F archived=true`; `gh repo view ... isArchived=true` | Both repos archived, not deleted |
| Task 9.3 | done | Retire canonical local legacy pointers and migrate Claude state | `$HOME/.codex/AGENTS.md -> $HOME/Project/graysurf/agent-runtime-kit/CODEX_AGENTS.md`; zsh env and Codex hooks no longer reference `.agents`; `$HOME/.agents -> $HOME/.config/agent-kit` retained only as a compatibility alias; Claude state migrated to `$HOME/.local/state/agent-runtime-kit/claude` | Added runtime-kit-owned `CODEX_AGENTS.md` so the home prompt remains distinct from project-local `AGENTS.md`, while preserving Codex Desktop access to the original agent-kit skills during cutover |

## Validation

| Command | Status | Summary | Artifact |
| --- | --- | --- | --- |
| `plan-tooling validate --file docs/plans/05-domain-migration/05-domain-migration-plan.md --format text --explain` | pass | Plan bundle validation passed through `bash scripts/ci/all.sh` | n/a |
| `for n in 1 2 3 4 5 6 7 8 9; do plan-tooling batches --file docs/plans/05-domain-migration/05-domain-migration-plan.md --sprint "$n" --format json; done` | pass | Sprint DAG/sizing check passed for every sprint | `agent-out` run dir `issue-26-sprint-4` |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 1 --strategy deterministic --pr-grouping group --pr-group 'Task 1.1=s1-reporting-guard' --pr-group 'Task 1.2=s1-meta-policy-state' --pr-group 'Task 1.3=s1-meta-workflow' --pr-group 'Task 1.4=s1-meta-integration' --format json` | pass | Sprint 1 dependency-layer PR split returned expected records | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 2 --strategy deterministic --pr-grouping group --pr-group 'Task 2.1=s2-media-source' --pr-group 'Task 2.2=s2-browser-source' --pr-group 'Task 2.3=s2-media-browser-integration' --format json` | pass | Sprint 2 dependency-layer PR split returned expected records | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 3 --strategy deterministic --pr-grouping group --pr-group 'Task 3.1=s3-web-test-evidence' --pr-group 'Task 3.2=s3-review-usage-evidence' --pr-group 'Task 3.3=s3-evidence-capture-integration' --format json` | pass | Sprint 3 dependency-layer PR split returned expected records | n/a |
| `plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint 7 --strategy deterministic --pr-grouping group --pr-group 'Task 7.1=s7-issue-lifecycle' --pr-group 'Task 7.2=s7-execution-orchestration' --pr-group 'Task 7.3=s7-dispatch-integration' --format json` | pass | Sprint 7 dependency-layer PR split returned Task 7.1, 7.2, and 7.3 grouped records. | n/a |
| `for n in 4 5 6 8 9; do plan-tooling split-prs --file docs/plans/05-domain-migration/05-domain-migration-plan.md --scope sprint --sprint "$n" --strategy deterministic --pr-grouping per-sprint --format json; done` | partial | Sprint 4 per-sprint split passed for selected scope; Sprints 5, 6, 8, and 9 remain future scope | n/a |
| `agent-runtime render --product codex` | pass | Rendered 26 Codex skills | n/a |
| `agent-runtime render --product claude` | pass | Rendered 26 Claude skills | n/a |
| `agent-runtime render --product codex --update-golden` | pass | Refreshed Codex golden snapshots including PR domain files | `tests/golden/codex/` |
| `agent-runtime render --product claude --update-golden` | pass | Refreshed Claude golden snapshots including PR domain files | `tests/golden/claude/` |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | Dry-run install skill-list diff passed for Claude and Codex | n/a |
| `agent-runtime audit-drift` | pass | Root audit clean; only documented product manifest info differences | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 24 unique skill ids plus quarantined product prompt cases. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Deterministic runtime smoke passed for all 24 migrated skill ids before Sprint 6 edits. | temp run root cleaned |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed before Sprint 6 edits, including 24-skill deterministic runtime smoke. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | pass | Sprint 5 PR domain probes passed for GitHub/GitLab create and close dry-run surfaces. | temp run root cleaned |
| `forge-cli pr wait-checks 37 --provider github --repo graysurf/agent-runtime-kit --format json` | fail | `forge-cli 0.16.0` requested unsupported `gh 2.92.0` JSON field `conclusion`; recorded extraction backlog item `P5-S5-G1`. | n/a |
| `gh pr checks 37 --watch --interval 10 --fail-fast` | pass | Provider-native fallback verified PR #37 remote CI passed. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Runtime skill smoke now covers 24 skills including the Sprint 5 PR domain. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 24 skills each before Sprint 6 edits with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode product --format json` | pass | Product temp-home install summary updated to 24 skills before Sprint 6 edits; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary.json` |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 26 unique skill ids plus quarantined product prompt cases after Sprint 6 edits. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain pr` | pass | PR deterministic smoke now covers create, close, dispatch-lane create, and delivery macro dry-runs. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 26 skills each with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install --format json > /tmp/runtime-smoke-install-summary-s6.json && diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary-s6.json` | pass | Install JSON expected output updated to 26 skills. | `/tmp/runtime-smoke-install-summary-s6.json` |
| `bash tests/runtime-smoke/run.sh --mode product --format json > /tmp/runtime-smoke-product-summary-s6.json && diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary-s6.json` | pass | Product expected output updated to 26 installed skills; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary-s6.json` |
| `if bash tests/smoke/deliver-lifecycle.sh; then exit 1; else test $? -ne 0; fi` | pass | Delivery smoke refuses to run without scratch fork and branch. | n/a |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke` | pass | Safe default delivery smoke produced `forge-cli pr deliver --dry-run` evidence against scratch target metadata. | temp artifact path printed by command |
| `forge-cli --version` | pass | Local released binary reports `forge-cli 0.17.1`. | n/a |
| `gh release view v0.17.1 --repo sympoies/nils-cli --json tagName,url,publishedAt` | pass | Upstream nils-cli `v0.17.1` release is published and fixes the GitHub pending-check stdout path discovered during live smoke. | https://github.com/sympoies/nils-cli/releases/tag/v0.17.1 |
| `bash tests/smoke/deliver-lifecycle.sh --scratch-fork graysurf/agent-runtime-kit-smoke --scratch-branch agent-runtime-kit-delivery-smoke --execute-live` | pass | Live delivery smoke created and merged scratch PR #4 using released `forge-cli 0.17.1`; scratch CI passed and merge commit is `45c6cb44b40a65fb1ee05145713921afcbf5ba4a`. | `/var/folders/3d/s2d3jvyn0g758lsd_2t79h1w0000gn/T//agent-runtime-kit-deliver-lifecycle.6KUs4y` |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed after Sprint 6 unblock, including deterministic runtime smoke `total=26 pass=26`. | n/a |
| `bash -n tests/runtime-smoke/run.sh tests/runtime-smoke/cases/dispatch/run.sh` | pass | Runtime-smoke dispatcher and dispatch case syntax passed. | n/a |
| `shellcheck tests/runtime-smoke/run.sh tests/runtime-smoke/cases/dispatch/run.sh` | pass | Shell lint passed for Sprint 7 runtime-smoke changes. | n/a |
| `shfmt -i 2 -ci -d tests/runtime-smoke/run.sh tests/runtime-smoke/cases/dispatch/run.sh` | pass | Shell formatting diff check passed. | n/a |
| `jq empty targets/codex/plugins/dispatch/.codex-plugin/plugin.json targets/claude/plugins/dispatch/.claude-plugin/plugin.json tests/runtime-smoke/expected/install-summary.json tests/runtime-smoke/product/expected/product-summary.json` | pass | Dispatch plugin manifests and expected JSON summaries parse cleanly. | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 33 unique skill ids across 43 cases after Sprint 7 dispatch additions. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain dispatch` | pass | Dispatch deterministic smoke passed for all seven dispatch skill ids. | temp run root cleaned |
| `agent-runtime render --product codex --update-golden` | pass | Refreshed Codex golden snapshots including dispatch domain files; rendered 33 skills. | `tests/golden/codex/` |
| `agent-runtime render --product claude --update-golden` | pass | Refreshed Claude golden snapshots including dispatch domain files; rendered 33 skills. | `tests/golden/claude/` |
| `bash tests/runtime-smoke/run.sh --mode install` | pass | Codex and Claude temp homes installed 33 skills each with doctor `block=0`. | temp run root cleaned |
| `bash tests/runtime-smoke/run.sh --mode install --format json > /tmp/runtime-smoke-install-summary-s7.json && diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary-s7.json` | pass | Install expected output updated to 33 skills. | `/tmp/runtime-smoke-install-summary-s7.json` |
| `bash tests/runtime-smoke/run.sh --mode product --format json > /tmp/runtime-smoke-product-summary-s7.json && diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary-s7.json` | pass | Product expected output updated to 33 installed skills; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary-s7.json` |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Runtime skill smoke now covers 33 migrated skill ids including the Sprint 7 dispatch domain. | temp run root cleaned |
| `bash scripts/ci/sandbox-install-rehearsal.sh` | pass | Dry-run install skill-list diff passed for Claude and Codex with dispatch pins. | n/a |
| `agent-runtime audit-drift` | pass | Root audit clean; only documented product manifest info differences including dispatch plugin metadata. | n/a |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-7 passed after Sprint 7 edits, including deterministic runtime smoke `total=33 pass=33`. | n/a |
| `gh pr checks 39 --watch --interval 10 --fail-fast` | pass | PR #39 remote `scripts/ci/all.sh` check passed. | https://github.com/graysurf/agent-runtime-kit/actions/runs/26292428029/job/77395930874 |
| `/Users/terry/.config/agent-kit/skills/workflows/code-review/code-review-specialists/scripts/review_specialists.py scope --base origin/main --testing --maintainability` | pass | Specialist review scope selected testing and maintainability; red-team review applied due broad diff; no displayed findings remained. | n/a |
| `gh pr comment 39 --body-file <delivery-review-outcome>` | pass | Posted delivery review outcome comment with merge decision and no blocking findings. | https://github.com/graysurf/agent-runtime-kit/pull/39#issuecomment-4519412557 |
| `/Users/terry/.config/agent-kit/skills/workflows/pr/github/close-github-pr/scripts/close-github-pr.sh --kind feature --pr 39` | pass | PR #39 marked ready, merged, remote branch deleted, local branch cleaned up, and `main` fast-forwarded to merge commit `47ab356327a70e3d1ef1ef1aab4e223c3fa1631f`. | https://github.com/graysurf/agent-runtime-kit/pull/39 |
| `bash -n tests/projects/project-local-smoke/run.sh tests/projects/project-local-smoke/.agents/scripts/*.sh tests/runtime-smoke/cases/meta/run.sh scripts/ci/all.sh` | pass | Sprint 8 shell syntax passed. | n/a |
| `shellcheck tests/projects/project-local-smoke/run.sh tests/projects/project-local-smoke/.agents/scripts/*.sh tests/runtime-smoke/cases/meta/run.sh scripts/ci/all.sh` | pass | Sprint 8 shell lint passed. | n/a |
| `shfmt -i 2 -ci -d tests/projects/project-local-smoke/run.sh tests/projects/project-local-smoke/.agents/scripts/*.sh tests/runtime-smoke/cases/meta/run.sh scripts/ci/all.sh` | pass | Sprint 8 shell format diff check passed. | n/a |
| `jq empty targets/codex/plugins/meta/.codex-plugin/plugin.json targets/claude/plugins/meta/.claude-plugin/plugin.json tests/runtime-smoke/expected/install-summary.json tests/runtime-smoke/product/expected/product-summary.json` | pass | Sprint 8 JSON files parse cleanly. | n/a |
| `bash tests/runtime-smoke/run.sh --mode matrix` | pass | Acceptance matrix covers 39 unique skill ids across 49 cases after project-local shim additions. | n/a |
| `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta` | pass | Meta deterministic smoke passed 12 cases including six project-local shims. | n/a |
| `agent-runtime render --product codex --update-golden` | pass | Codex golden snapshots refreshed; rendered 39 skills. | `tests/golden/codex/` |
| `agent-runtime render --product claude --update-golden` | pass | Claude golden snapshots refreshed; rendered 39 skills. | `tests/golden/claude/` |
| `agent-runtime install --product claude --live-home <temp> --state-home <temp> --dry-run` | pass | Sprint 8 dry-run install resolved 49 actions for Claude without mutating real runtime homes. | `/tmp/plan05-s8-claude-install-dry-run.log` |
| `agent-runtime install --product codex --live-home <temp> --state-home <temp> --dry-run` | pass | Sprint 8 dry-run install resolved 49 actions for Codex without mutating real runtime homes. | `/tmp/plan05-s8-codex-install-dry-run.log` |
| `bash tests/projects/project-local-smoke/run.sh` | pass | Project-local fixture executed all six scripts and verified wired/missing-script doctor reports. | n/a |
| `bash tests/runtime-smoke/run.sh --mode install --format json > /tmp/runtime-smoke-install-summary-s8.json && diff -u tests/runtime-smoke/expected/install-summary.json /tmp/runtime-smoke-install-summary-s8.json` | pass | Install expected output updated to 39 skills. | `/tmp/runtime-smoke-install-summary-s8.json` |
| `bash tests/runtime-smoke/run.sh --mode product --format json > /tmp/runtime-smoke-product-summary-s8.json && diff -u tests/runtime-smoke/product/expected/product-summary.json /tmp/runtime-smoke-product-summary-s8.json` | pass | Product expected output updated to 39 installed skills; prompt cases remain quarantined skips. | `/tmp/runtime-smoke-product-summary-s8.json` |
| `bash tests/runtime-smoke/run.sh --mode deterministic` | pass | Runtime deterministic smoke passed 39 migrated skill ids. | n/a |
| `bash scripts/ci/all.sh` | pass | Full local gate stack positions 1-8 passed, including project-local overlay smoke. | n/a |
| `git -C "$HOME/.config/agent-kit" log -1 --format=%H -- MOVED.md` | pass | Legacy `agent-kit` archive marker commit pushed after rebase. | `11559d656ab64b409d33f6321bc9b65a42b59169` |
| `git -C "$HOME/.config/claude" log -1 --format=%H -- MOVED.md` | pass | Legacy `claude-kit` archive marker commit pushed. | `194a1ec239b67eb3fa4b47a7baea13e2ab561965` |
| `gh api repos/graysurf/agent-kit/contents/MOVED.md --jq '.download_url' \| xargs curl -fsSL \| rg 'graysurf/agent-runtime-kit'` | pass | Remote `agent-kit` marker points to `agent-runtime-kit`. | n/a |
| `gh api repos/graysurf/claude-kit/contents/MOVED.md --jq '.download_url' \| xargs curl -fsSL \| rg 'graysurf/agent-runtime-kit'` | pass | Remote `claude-kit` marker points to `agent-runtime-kit`. | n/a |
| `gh api -X PATCH repos/graysurf/agent-kit -F archived=true` | pass | GitHub returned `archived: true` for `graysurf/agent-kit`. | https://github.com/graysurf/agent-kit |
| `gh api -X PATCH repos/graysurf/claude-kit -F archived=true` | pass | GitHub returned `archived: true` for `graysurf/claude-kit`. | https://github.com/graysurf/claude-kit |
| `gh repo view graysurf/agent-kit --json isArchived,name,url` | pass | Verified `graysurf/agent-kit` remains present and archived. | https://github.com/graysurf/agent-kit |
| `gh repo view graysurf/claude-kit --json isArchived,name,url` | pass | Verified `graysurf/claude-kit` remains present and archived. | https://github.com/graysurf/claude-kit |
| `readlink "$HOME/.codex/AGENTS.md" \| rg '/agent-runtime-kit/CODEX_AGENTS.md$'` | pass | Codex home prompt now points directly at the runtime-kit-owned home policy source. | `$HOME/Project/graysurf/agent-runtime-kit/CODEX_AGENTS.md` |
| `test -f "$(readlink "$HOME/.codex/AGENTS.md")"` | pass | Symlink target exists. | n/a |
| `zsh -lc 'printf "AGENT_HOME=%s\nAGENT_DOCS_HOME=%s\nPLAN_ISSUE_HOME=%s\n" "$AGENT_HOME" "$AGENT_DOCS_HOME" "$PLAN_ISSUE_HOME"'` | pass | Zsh startup now exports all three values to `$HOME/.config/agent-kit`, not `$HOME/.agents`. | n/a |
| `env -u ZDOTDIR zsh -lc 'printf "AGENT_HOME=%s\nAGENT_DOCS_HOME=%s\nPLAN_ISSUE_HOME=%s\n" "$AGENT_HOME" "$AGENT_DOCS_HOME" "$PLAN_ISSUE_HOME"'` | pass | Cold zsh startup without inherited `ZDOTDIR` also exports all three values to `$HOME/.config/agent-kit`. | n/a |
| `! rg -n '/Users/[^/]+/\.agents\|\$HOME/\.agents' "$HOME/.zshenv" "$HOME/.config/zsh/scripts/_internal/paths.exports.zsh" "$HOME/.codex/config.toml"` | pass | No stale `.agents` path remains in the shell env setup or Codex managed hook block. | n/a |
| `rg -o 'command = "[^"]+"' "$HOME/.codex/config.toml" \| sed 's/^command = "//; s/"$//' \| while read -r hook; do case "$hook" in "$HOME/.config/agent-kit/hooks/codex/"*) test -f "$hook";; esac; done` | pass | Codex managed hook command targets all exist after replacing `.agents` with `$HOME/.config/agent-kit`. | n/a |
| `if [ -L "$HOME/.agents" ]; then readlink "$HOME/.agents" \| rg '/\.config/agent-kit$'; else test ! -e "$HOME/.agents"; fi` | pass | `$HOME/.agents` is retained only as a compatibility alias to the active agent-kit docs/skills checkout. | `$HOME/.agents -> $HOME/.config/agent-kit` |
| `agent-docs --docs-home "$HOME/.agents" resolve --context startup --strict --format checklist` | pass | Compatibility alias still resolves the startup docs needed by older Codex sessions. | n/a |
| `find "$HOME/.agents/skills" -maxdepth 4 -name SKILL.md -print \| wc -l` | pass | Original agent-kit skills remain reachable through the compatibility alias. | `61` |
| `launchctl getenv AGENT_HOME; launchctl getenv AGENT_DOCS_HOME; launchctl getenv PLAN_ISSUE_HOME; launchctl getenv CODEX_HOME` | pass | macOS app launch environment now points future Codex app launches at the real docs/skills checkout and Codex home. | `$HOME/.config/agent-kit`; `$HOME/.codex` |
| `rsync -a "$state_root/claude-kit/" "$state_root/agent-runtime-kit/claude/" && diff -qr "$state_root/claude-kit" "$state_root/agent-runtime-kit/claude" && rm -rf "$state_root/claude-kit"` | pass | Migrated 5.5M of Claude state to the runtime-kit namespace and verified it before removing the old tree. | `$HOME/.local/state/agent-runtime-kit/claude` |
| `state_root="${XDG_STATE_HOME:-$HOME/.local/state}"; if [ -d "$state_root/agent-runtime-kit/claude" ]; then test ! -d "$state_root/claude-kit"; else rg -q 'claude-kit state migration no-op' docs/plans/05-domain-migration/05-domain-migration-execution-state.md; fi` | pass | Post-migration state invariant passed. | n/a |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context startup --strict --format checklist` | pass | Home-scope startup preflight still resolves after `.agents` removal. | n/a |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context project-dev --strict --format checklist` | pass | Project-dev preflight still resolves after `.agents` removal. | n/a |
| `agent-docs --docs-home "$HOME/.config/agent-kit" resolve --context task-tools --strict --format checklist` | pass | Task-tools preflight still resolves for issue/PR operations after `.agents` removal. | n/a |
| `gh pr checks 40 --watch --interval 10` | pass | PR #40 remote `scripts/ci/all.sh` check passed. | https://github.com/graysurf/agent-runtime-kit/actions/runs/26295494399/job/77406808933 |
| `gh pr comment 40 --body-file <delivery-review-outcome>` | pass | Posted delivery review outcome comment with compatibility-alias repair and no remaining concrete findings. | https://github.com/graysurf/agent-runtime-kit/pull/40#issuecomment-4519871974 |
| `/Users/terry/.config/agent-kit/skills/workflows/pr/github/close-github-pr/scripts/close-github-pr.sh --kind feature --pr 40` | pass | PR #40 was marked ready, merged, branch-cleaned, and local `main` updated to merge commit `b402fc2660831940f8f695e7f4d549e72fb520e8`. | https://github.com/graysurf/agent-runtime-kit/pull/40 |

## Blockers

- Any missing nils-cli binary or required flag blocks the affected skill body
  and must be logged in `docs/source/extraction-backlog.md`.
- Plan 06 deterministic acceptance is satisfied through Sprint 8 by the current
  `matrix`, `deterministic`, and `scripts/ci/all.sh` validation; rerun the
  same gate before future sprint merges.
- Sprint 6 delivery smoke requires a scratch fork/branch and must not target
  `graysurf/agent-runtime-kit` `main`.
- Sprint 7 dispatch migration is merged in PR #39 at
  `47ab356327a70e3d1ef1ef1aab4e223c3fa1631f`.
- Sprint 8 overlay gates are complete and in branch
  `feat/plan-05-overlay-cutover`, merged through PR #40.
- Sprint 9.1 and 9.2 are complete: both legacy repositories have root
  `MOVED.md` commits and GitHub `archived=true`.
- Sprint 9.3 is complete: Codex home policy now links directly to
  `agent-runtime-kit/CODEX_AGENTS.md`, zsh/Codex hook config no longer references
  `.agents`, `.agents` is retained only as a compatibility alias, and Claude
  state is under `$HOME/.local/state/agent-runtime-kit/claude`.
- No active Plan 05 blockers remain.

## Session Log

- 2026-05-22: Bootstrapped issue-backed execution state for GitHub issue #26 because the issue had source/plan snapshots but no `execute-from-tracking-issue:state:v1` comment.
- 2026-05-22: Completed Sprint 1 through Sprint 4 in branch `feat/issue-26-sprint-4`: added meta, media, browser, and evidence portable skill source bodies; wired manifests, product plugin metadata, link maps, sandbox expected skill pins, and golden snapshots; added `docs/source/extraction-backlog.md` with no selected-scope extraction blockers.
- 2026-05-22: Validation passed: `bash scripts/ci/all.sh`, selected `plan-tooling split-prs` checks, full `plan-tooling batches` sweep, `agent-runtime audit-drift`, and `bash scripts/ci/sandbox-install-rehearsal.sh`.
- 2026-05-22: Recorded Plan 06 acceptance dependency before Sprint 5+ resumes: deterministic runtime smoke is the required gate; product smoke remains manual/quarantined until isolated provider/auth execution is supplied.
- 2026-05-22: Completed Sprint 5 PR create/close migration in branch `feat/plan-05-pr-domain`: added `forge-cli`-backed PR/MR create and close skill sources, PR plugin manifests/link maps, golden snapshots, sandbox pins, and deterministic PR runtime-smoke probes; opened PR #37.
- 2026-05-22: Recorded extraction backlog item `P5-S5-G1` after live `forge-cli pr checks` / `wait-checks` failed against `gh 2.92.0`; used `gh pr checks` as the provider-native fallback for PR #37 CI evidence.
- 2026-05-22: Implemented Sprint 6 delivery macro sources, PR manifest wiring, deterministic delivery dry-run probes, and `tests/smoke/deliver-lifecycle.sh`; live scratch delivery smoke is blocked because `graysurf/agent-runtime-kit-smoke` is unavailable and GitHub live checks still depend on `P5-S5-G1`.
- 2026-05-22: Created and configured scratch repository `graysurf/agent-runtime-kit-smoke`, delivered `sympoies/nils-cli` issue #439, released and installed `nils-cli v0.17.1`, bumped PR-domain `forge-cli` floors to `>=0.17.1`, and passed live Sprint 6 delivery smoke by creating and merging scratch PR #4.
- 2026-05-22: Merged Plan 05 Sprint 6 PR #38 at `b21e22d7594ea817532dbd0ce1530066f6f02a88`; issue #26 dashboard, state, validation, and session comments now mark Sprint 6 complete and Sprint 7 intentionally not started.
- 2026-05-22: Started Sprint 7 dispatch domain migration on `feat/plan-05-dispatch-domain`; Sprint 7 split-prs readiness passed and Task 7.1 is in progress.
- 2026-05-22: Completed Sprint 7 dispatch source migration, manifests, product plugin metadata, link maps, golden snapshots, sandbox pins, and deterministic dispatch runtime smoke; local CI passed with `total=33 pass=33`.
- 2026-05-22: Fixed a small Sprint 7 usage bug before commit: removed unsupported `forge-cli pr create --draft` guidance from `dispatch-subagent-pr` because draft PRs are the default in released `forge-cli 0.17.1`.
- 2026-05-22: Merged Plan 05 Sprint 7 PR #39 at `47ab356327a70e3d1ef1ef1aab4e223c3fa1631f`; issue #26 dashboard, state, validation, and session comments should now mark Sprint 7 complete and Sprint 8 intentionally not started.
- 2026-05-22: Completed Sprint 8 overlay gates in `feat/plan-05-overlay-cutover`: added project-local shim sources for `bench`, `bootstrap`, `demo`, `deploy`, `pre-pr`, and `release`; added `tests/projects/project-local-smoke/`; updated runtime smoke expected counts to 39 skills; local CI positions 1-8 passed.
- 2026-05-22: Completed Sprint 9.1 and 9.2 external archive work: pushed `MOVED.md` to `graysurf/agent-kit` at `11559d656ab64b409d33f6321bc9b65a42b59169`, pushed `MOVED.md` to `graysurf/claude-kit` at `194a1ec239b67eb3fa4b47a7baea13e2ab561965`, and set both GitHub repositories to `archived=true`.
- 2026-05-22: Blocked Sprint 9.3 local cutover before removing `$HOME/.agents`: live Codex startup still resolves `$HOME/.codex/AGENTS.md -> $HOME/.agents/CODEX_AGENTS.md`, and this repo does not yet render or install a replacement AGENTS surface.
- 2026-05-22: Resolved Sprint 9.3 after user confirmed the original
  `CODEX_AGENTS.md` naming design: added runtime-kit-owned `CODEX_AGENTS.md`,
  moved `$HOME/.codex/AGENTS.md` to point directly at it, migrated
  `$HOME/.local/state/claude-kit` to
  `$HOME/.local/state/agent-runtime-kit/claude`, and re-ran `agent-docs`
  startup/project-dev/task-tools preflights successfully.
- 2026-05-22: Finished local shell and Codex hook cutover: updated zsh env
  exports so new shells set `AGENT_HOME`, `AGENT_DOCS_HOME`, and
  `PLAN_ISSUE_HOME` to `$HOME/.config/agent-kit`; updated
  `$HOME/.codex/config.toml` hook commands away from `.agents`; verified no
  stale `.agents` references remain in those machine-local startup/config files.
- 2026-05-22: Repaired Codex Desktop skill discovery during cutover after a new
  Codex session did not see the original `agent-kit` skills: restored
  `$HOME/.agents -> $HOME/.config/agent-kit` as a compatibility alias, set
  `launchctl` app environment for `AGENT_HOME`, `AGENT_DOCS_HOME`,
  `PLAN_ISSUE_HOME`, and `CODEX_HOME`, verified `agent-docs --docs-home
  "$HOME/.agents"` startup preflight, and verified 61 original `agent-kit`
  `SKILL.md` files are reachable through the alias.
- 2026-05-22: Merged Plan 05 Sprint 8/9 PR #40 at
  `b402fc2660831940f8f695e7f4d549e72fb520e8`; issue #26 dashboard, state,
  validation, and closeout comments should now mark Plan 05 complete.
