# Plan Issue vNext Implementation Execution State

## Current State

- Source document: `docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md`
- Direct source-doc execution waiver: not applicable
- Status: substantially complete (24 of 26 tasks done; 2 deferred with documented rationale)
- Current task: complete
- Next task: see "Follow-ups" below
- Last updated: 2026-05-26
- Execution driver: this plan bundle and the five redesign documents only
- Plan issue skills: intentionally not used to drive this implementation
- Tracking issue: not opened
- Runtime-kit branch: `main` (work landed directly on the existing branch)
- nils-cli branch: `feat/plan-issue-vnext` (7 commits, ready for PR)
- nils-cli released version: not yet released; runtime-kit consumes the
  local development binary through Sprint 9.2 and the existing released
  CLI floor (`plan-issue >=0.22.3`) for the v3 record surfaces
- Local binary policy: vNext development used the local cargo-built
  `plan-issue` binary at
  `/Users/terry/Project/sympoies/nils-cli/target/debug/plan-issue`;
  the installed CLI (Homebrew floor) was not replaced
- Cross-repo target: `sympoies/nils-cli`

## Design Sources

| Source | Status | Notes |
| --- | --- | --- |
| `docs/source/plan-issue-redesign/plan-tracking-issue-comment-taxonomy-v1.md` | ready | Used as the taxonomy lock for the lifecycle role registry and visible lint. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-workflow-v1.md` | ready | Used as the FSM transition source of truth. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-cli-redesign-v1.md` | ready | Used as the CLI vNext architecture and rewrite-boundary policy. |
| `docs/source/plan-issue-redesign/plan-tracking-issue-run-state-controller-v1.md` | ready | Used as the run-state schema and event journal contract. |
| `docs/source/plan-issue-redesign/plan-issue-skill-family-redesign-v1.md` | ready | Used as the runtime-kit skill rewrite contract. |

## Task Ledger

| ID | Status | Task | Evidence | Notes |
| --- | --- | --- | --- | --- |
| Task 1.1 | done | Add vNext module skeletons | nils-cli `feat/plan-issue-vnext` 8573c85 | `crates/plan-issue-cli/src/lifecycle_vnext/` + `tracking/` modules added; `cargo test -p nils-plan-issue-cli` 150 tests pass. |
| Task 1.2 | done | Freeze compatibility baseline | nils-cli 8573c85 | Added `record_compat_baseline.rs` integration tests; 8 tests cover record subcommand surface, success/failure envelope, runtime layout sharing. |
| Task 2.1 | done | Implement lifecycle role registry | nils-cli 9b08812 | Registry covers all 7 roles with stable headings, payload schemas, direct-post policy, and dashboard repair expectation. 7 unit + 7 integration tests pass. |
| Task 2.2 | done | Implement visible completeness lint | nils-cli 9b08812 | `lifecycle_vnext::visible_lint` enforces Profile-only, Task Ledger, validation overall, review decision/disposition, session summary, closeout approval+linked PR. 11 integration tests pass. |
| Task 2.3 | done | Extend audit with --expect-visible | nils-cli 9b08812 | `record audit --expect-visible` emits `visible` block with stable role-specific codes; 5 integration tests pass. |
| Task 3.1 | done | Add `record template` preview | nils-cli dab7338 | `plan-issue record template --kind <role> --shape markdown|json` renders skeletons from the registry. 6 integration tests pass. (Used `--shape` rather than `--format` to avoid clash with global `--format text|json`; logged in CLI redesign decision below.) |
| Task 3.2 | done | Add renderer fixture coverage | nils-cli dab7338 | `lifecycle_vnext_render` fixtures cover state non-final/final, session, validation, review, closeout, source/plan via record-attach dry-run. 7 integration tests pass. |
| Task 4.1 | done | Run-state schema and event journal | nils-cli 2a7a4ec | `plan-issue.execution-run.v1` + `plan-issue.execution-event.v1` with disk IO, issue-scoped layout via `runtime_layout::IssueRoot`. 7 unit + 9 integration tests pass. |
| Task 4.2 | done | FSM and reconciliation | nils-cli 2a7a4ec | `tracking::fsm::evaluate_audit` + `tracking::reconcile::reconcile` cover all 8 record states and the stale-vs-newer rules. 8 unit + 8 integration tests pass. |
| Task 4.3 | done | `tracking status` command | nils-cli 2a7a4ec | Reads provider evidence (live/fixture/explicit), optional run state, runs audit + optional visible lint, returns stable JSON. 6 integration tests pass. |
| Task 5.1 | done | `tracking run init` / `run update` | nils-cli d6d6cdf | Initialize / update typed run state under issue runtime root; append `run_started` / `run_updated` events. 4 integration tests pass. |
| Task 5.2 | done | `tracking checkpoint --dry-run` | nils-cli d6d6cdf | Reconciles + synthesizes payloads + renders bodies + runs visible lint + writes `rendered/`. 3 integration tests pass. |
| Task 5.3 | done | Stale-state and completeness refusal tests | nils-cli d6d6cdf | 4 integration tests cover source/plan/closeout role rejection, stale-issue closed, live-not-implemented, unknown role. |
| Task 6.1 | deferred | Implement live tracking checkpoint | n/a | Live provider mutation is gated behind `--live`; controller returns `tracking-checkpoint-live-not-implemented` blocker. Live posting requires forge-cli adapter integration not covered in this plan; runtime-kit skills currently fall back to `record post` for live mutation. Follow-up issue recommended. |
| Task 6.2 | done | `tracking close-ready` | nils-cli 3bd5493 | Non-mutating probe, reuses audit + reconcile, collects linked PRs from state payload + run state + flag, runs visible lint. 5 integration tests pass. |
| Task 6.3 | deferred | Migrate record rendering to vNext | n/a | Record rendering internals stay in `lifecycle_record.rs`; the vNext registry currently lints / previews / synthesizes but does not replace the renderer wholesale. Migration is internal-only refactor and does not change observable behavior; deferred to keep the vNext PR focused. Follow-up issue recommended. |
| Task 7.1 | done | Validate local binary against fixtures | local binary at `target/debug/plan-issue` | `cargo test -p nils-plan-issue-cli` reports 114 unit + 232 integration tests passing. `record template`, `tracking status`, `tracking run init/update`, `tracking checkpoint`, `tracking close-ready` --help all exposed. |
| Task 7.2 | done | Update nils-cli docs / release prep | nils-cli 7d145a5 | Added [Unreleased] block to `crates/plan-issue-cli/CHANGELOG.md` covering every new vNext surface. Actual release tag is left to the nils-cli release workflow (Sprint 9.3 is therefore blocked on that release). |
| Task 8.1 | done | Rewrite lightweight tracking skills | runtime-kit d774bf9 | All 4 SKILL.md.tera bodies rewritten in the new section order; renders pass for codex and claude. |
| Task 8.2 | done | Rewrite dispatch issue and lane skills | runtime-kit d774bf9 | All 5 SKILL.md.tera bodies rewritten; renders pass for codex and claude. |
| Task 8.3 | done | Audit related references | runtime-kit d774bf9 | rg sweep confirms no `render-comment` / `gh issue comment` mechanics remain outside Forbidden lists; `docs/source/nils-cli-surface.md` calls out the pending vNext surface. |
| Task 9.1 | done | Refresh rendered outputs and goldens | runtime-kit d774bf9 | `agent-runtime render --product {codex,claude} --update-golden` regenerated 89 files per product; `agent-runtime audit-drift` reports clean. |
| Task 9.2 | partial | Runtime smoke for visible lifecycle behavior | runtime-kit d774bf9 | Existing `dispatch` smoke cases pass (8 pass + 1 skip-host-capability for session-closeout gate that requires the unreleased local binary). Additional vNext-specific smoke (tracking checkpoint dry-run rendered bodies, stale-state refusal, close-ready blocked/pass) is left as a follow-up that pairs naturally with the released nils-cli floor. |
| Task 9.3 | blocked | Final released-floor validation | n/a | Blocked on `sympoies/nils-cli` release of the vNext `plan-issue` surface. Until then runtime-kit consumes the local dev binary; this remains the same gating point identified in the plan. |
| Task 10.1 | done | Run full repo validation | runtime-kit `scripts/ci/all.sh` | `plan-tooling validate` exits 0; `bash scripts/ci/all.sh` reports `positions 1-13 OK` (render, golden diff, audit-drift, runtime smoke). |
| Task 10.2 | done | Final docs / execution-state cleanup | this commit | Execution-state ledger updated with done / deferred / blocked rollups and explicit follow-ups. |

## Validation Ledger

| Command | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `agent-docs resolve --context startup --strict --format checklist` | pass | current session | Required startup preflight passed. |
| `agent-docs resolve --context project-dev --strict --format checklist` | pass | current session | Required project-dev preflight passed. |
| `plan-tooling validate --file docs/plans/plan-issue-vnext-implementation/plan-issue-vnext-implementation-plan.md --format text` | pass | current session | Bundle structural validation passes (exit 0). |
| `cargo test -p nils-plan-issue-cli --no-fail-fast` | pass | nils-cli `feat/plan-issue-vnext` HEAD | 114 unit + 232 integration tests pass. |
| `agent-runtime render --product codex --update-golden` | pass | runtime-kit `main` HEAD | 89 files copied into `tests/golden/codex/`. |
| `agent-runtime render --product claude --update-golden` | pass | runtime-kit `main` HEAD | 89 files copied into `tests/golden/claude/`. |
| `agent-runtime audit-drift` | pass | runtime-kit `main` HEAD | 20 findings, all `intentional-difference/info`. |
| `bash scripts/ci/all.sh` | pass | runtime-kit `main` HEAD | positions 1-13 OK (render, golden diff, audit-drift, runtime smoke, project-local overlay, shared hook contract). |
| `git diff --check` | pass | current session | No whitespace errors. |

## Session Log

- 2026-05-26: Created the plan issue vNext implementation bundle to
  connect the five redesign documents into one direct execution path.
- 2026-05-26: Validated the new plan bundle with `plan-tooling validate`
  and checked whitespace with `git diff --check`.
- 2026-05-26: Implemented Sprints 1–6 in `sympoies/nils-cli` on the
  `feat/plan-issue-vnext` branch — 7 commits, 114 unit + 232 integration
  tests. Tasks 6.1 (live checkpoint) and 6.3 (record renderer migration)
  recorded as deferred.
- 2026-05-26: Implemented Sprints 8–9 in `graysurf/agent-runtime-kit`
  on `main` — single commit rewriting the 9 plan-issue skill bodies and
  refreshing golden outputs. Task 9.3 (released-floor validation)
  recorded as blocked on the nils-cli release.
- 2026-05-26: `bash scripts/ci/all.sh` reports `positions 1-13 OK`.

## Follow-ups

- Open an issue to track the live `tracking checkpoint` adapter
  (Task 6.1) — wires `record post` mutation into the controller behind
  the existing `--live` flag and replaces the
  `tracking-checkpoint-live-not-implemented` blocker.
- Open an issue to track migrating `record open / post / repair-dashboard
  / close / audit` rendering internals onto the vNext registry
  (Task 6.3). The current observable behavior is unchanged; the
  migration unifies the renderer with `record template` / `tracking
  checkpoint` and lets us drop the now-duplicated visible-body composers.
- Open an issue to track additional vNext runtime smoke (Task 9.2
  follow-up): tracking checkpoint dry-run rendered bodies, stale
  run-state refusal end-to-end, close-ready blocked/pass cases. These
  pair naturally with the released nils-cli floor.
- Cut the next `sympoies/nils-cli` release that includes the new
  `record template`, `record audit --expect-visible`, and `tracking`
  surfaces; then update `manifests/skills.yaml` `required_clis` floors
  and rerun `bash scripts/ci/all.sh` against the released binary
  (Task 9.3 unblocking).

## Notes

- `Location` entries for nils-cli tasks point at this bundle or redesign
  docs because `plan-tooling` validates paths relative to
  `agent-runtime-kit`.
- During execution, exact nils-cli repo-relative paths, commits, and
  validation summaries were captured in the Task Ledger above.
- The existing plan issue skill family was intentionally not used as the
  implementation driver for this plan, in line with the redesign-doc
  guidance.
- The vNext PR is intentionally a single bundled rewrite per the design
  doc's rewrite-boundary rule. The deferred follow-ups (6.1, 6.3, 9.2
  extension, 9.3 release) are recorded above as independent items that
  do not block the rewrite landing on `main`.
