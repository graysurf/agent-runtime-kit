# Test-First Discipline Redesign Implementation Handoff

- **Status**: decided — L2 coupled, gate-first; the nils-cli gate is the first
  deliverable
- **Date**: 2026-06-14
- **Source**: In-session design discussion re-examining how `agent-runtime-kit`
  enforces test-first discipline, comparing the current pieces against
  `obra/superpowers`' TDD model, plus a `meta:remove-skill` dry-run reference
  audit of the `conversation.test-first` mode skill.
- **Intended next step**: execute as one L2 coupled effort, gate-first — build
  the option-(b) gate in `sympoies/nils-cli`, cut a release and bump the pin,
  then land the repo-local consume (enrich + remove + `guided-feature-build`) in
  one `agent-runtime-kit` PR.

## Purpose

Make test-first discipline *actually land* rather than leak at every seam. Today
the discipline is spread across four loosely-coupled surfaces — an always-on
policy, an opt-in mode skill, a deterministic evidence CLI, and an optional PR
body field — and none of them composes into one enforced path. This document
captures the agreed redesign: delete the redundant mode skill, consolidate its
role into the evidence skill, and add one mechanically-enforced delivery gate
keyed on the existing type label.

The user accepts that waivers are legitimate (docs-only / config-only / no-test-
harness changes). The goal is **not** a no-escape Iron Law; it is a verifiable,
waiver-aware floor.

## Confirmed Facts

- `AGENT_HOME.md` "Work Mode" already states the policy: for testable production
  behavior changes, prefer failing-test evidence before editing production code;
  when not practical, state an explicit waiver and substitute validation. This
  is the canonical *whether* and is judgment-enforced. [F1]
- `core/skills/conversation/test-first/` is a prompt-only **mode skill**. Its
  RULES (`references/prompts/test-first.md`) largely duplicate the `AGENT_HOME.md`
  policy, it is purely opt-in (fires only when explicitly invoked), and its
  prompt **never invokes `test-first-evidence`** — it narrates evidence fields
  (`command` / `exit code` / `test name` / `summary`, lines 30-34) that map
  exactly onto `test-first-evidence record-failing` but tells the agent to
  "capture" them as prose. The mode and the evidence CLI are two disconnected
  halves of one flow. [F2]
- `core/skills/evidence/test-first-evidence/` wraps a deterministic, verifiable
  CLI: `init` → `record-failing` → `record-waiver` → `record-final` → `verify`.
  Waiver is a first-class record. This is the strongest of the four surfaces and
  is currently underused (nothing requires it). [F3]
- `create-pr` / `deliver-pr` expose an optional `--test-first-file` section to
  `agent-runtime pr-body render`. The minimum required PR body sections are
  `## Summary` + `## Test plan` (per `git-delivery.md`); the Test-First section
  is optional and unverified, so without a backing evidence record it is
  post-hoc prose. [F4]
- The `type::` label taxonomy already encodes the behavior-change distinction,
  using the same exemption set the commit-body gate uses: `type::feature` /
  `type::fix` ≈ behavior change; `type::docs` / `chore` / `style` / `build` ≈
  exempt. No new "behavior-change classifier" is needed. [F5]
- Mechanical enforcement can only assert that *verified evidence exists*, not
  literal temporal "test first". The closest proxy is the evidence record's
  internal structure (a captured failing run preceding a passing final), which
  `test-first-evidence verify` can check. [I1]

### `meta:remove-skill` dry-run audit of `conversation.test-first`

The skill ID appears exactly once in `manifests/skills.yaml:500`. Active
references that the removal must update (all mechanical, no deep code coupling):

- Source dir: `core/skills/conversation/test-first/` (`SKILL.md.tera` +
  `references/prompts/test-first.md`).
- Manifest entry: `manifests/skills.yaml:500-509`.
- Plugin containment: `manifests/plugins.yaml:82`.
- Codex target: `targets/codex/link-map.yaml:280-283`.
- Golden snapshots: `tests/golden/claude/plugins/conversation/skills/test-first/`
  and `tests/golden/codex/.../test-first/`.
- Sandbox skill lists: `tests/sandbox/codex/expected-skills.txt:14`,
  `tests/sandbox/claude/expected-skills.txt:14`.
- Runtime-smoke: `tests/runtime-smoke/acceptance-matrix.yaml:485-488`,
  `tests/runtime-smoke/cases/conversation/run.sh:63`.
- Maintained docs: `core/skills/README.md:78` (Work modes row).

Must be retained (historical, do not mutate): the heuristic-system archive entry
`core/policies/heuristic-system/error-inbox/archive/2026/commit-content-gates-miss-structured-args/ENTRY.md:23,28`.

Not references to the mode skill (must stay): everything matching
`test-first-evidence` (the CLI, including `tests/runtime-smoke/cases/evidence/run.sh`
artifact filenames) and `--test-first-file` / pr-body usage.

Cross-dependency: the `guided-feature-build` skill (merged in PR #328) references
the test-first **mode** in its Phase 5 and Boundary; removal must update those in
the same change. [F6]

## Decisions

1. **Delete the `conversation.test-first` mode skill.** It is redundant with the
   always-on `AGENT_HOME.md` policy, disconnected from the evidence CLI, and
   opt-in so it rarely fires.
2. **Consolidate its role into `test-first-evidence`** (one skill that both
   guides and records):
   - Absorb the trigger: extend the `test-first-evidence` `description` so it
     also fires on "test-first implementation mode" / "require failing-test
     evidence before production code" requests — preserving the deleted skill's
     entry point under a different name.
   - Absorb the "how": move the judgment from `test-first.md` (classify the
     change; failing test before production edit; do not weaken/overfit; scope
     the change to green; final validation report) into the
     `test-first-evidence` workflow.
3. **Add one PR-delivery gate keyed on the `type::` label.** For `type::feature`
   / `type::fix`, `--test-first-file` must be backed by a `test-first-evidence
   verify`-passing record **or** carry an explicit `waiver:` line; otherwise the
   delivery is blocked. `type::docs` / `chore` / `style` / `build` are exempt.
   **Enforcement point: option (b)** — the gate is built into the released
   `forge-cli pr create` / `agent-runtime pr-body` surface in `sympoies/nils-cli`,
   not a repo-local hook, so it ships through a nils-cli release.
4. **Keep waivers first-class.** Confirmed reasonable by the user; the gate is a
   verifiable floor, not a no-escape Iron Law.
5. **Keep the `AGENT_HOME.md` policy** as the judgment baseline (the canonical
   *whether*); enrich, do not replace it.
6. **Leave `parallel-first` / `orchestrator-first` as prompt-only modes.** They
   are genuine sticky-thread delegation strategies with no policy or CLI
   backing; only `test-first` is the odd member that earns consolidation.
7. **Enforcement target is "verified evidence exists", not temporal ordering.**
   The record's failing-then-final structure is the accepted proxy.
8. **Gate-first, one coupled effort.** Build the nils-cli gate, release it, and
   bump the pin first; then land the repo-local consume — enrich
   `test-first-evidence`, remove the mode skill, update `guided-feature-build` —
   in one `agent-runtime-kit` PR. Within that repo-local PR, the enrich
   precedes/accompanies the removal (never bare-delete).

## Scope

- Remove `conversation.test-first` via `meta:remove-skill` (governed sequence;
  retain historical records).
- Enrich `core/skills/evidence/test-first-evidence/SKILL.md.tera` (description
  trigger + workflow guidance).
- Add the PR-delivery test-first gate (see Implementation Boundaries for the
  repo-local vs nils-cli split).
- Update `guided-feature-build` Phase 5 + Boundary to reference the policy /
  evidence skill instead of the removed mode.
- Document the gate + waiver mechanics in `core/policies/git-delivery.md`.

## Non-Scope

- No change to `parallel-first` / `orchestrator-first`.
- No no-waiver Iron Law and no edit-time (pre-write) interception.
- No finish-line "default-on evidence per code session" gate in this change (see
  Risks for why it is deferred, not adopted).
- No change to the `AGENT_HOME.md` policy intent; at most a one-line note that a
  delivery gate now backs it.

## Implementation Boundaries

- Skill bodies, manifests, golden, sandbox, runtime-smoke, `README.md`,
  `git-delivery.md`, and `guided-feature-build` edits are repo-local.
- **Enforcement point: option (b), decided.** The gate is built into the released
  `forge-cli pr create` / `agent-runtime pr-body` surface in `sympoies/nils-cli`,
  not a repo-local hook. It therefore ships through the coupled nils-cli release
  boundary (implement → release → tap → `brew upgrade` → pin bump) before the
  repo-local consume can land. The rejected alternative was (a) a
  `core/hooks/shared/` PreToolUse hook reading labels + calling
  `test-first-evidence verify`.
- If `test-first-evidence` needs new label-aware or behavior-classification
  capability, that is upstream `nils-cli` work; declare the consumed binary
  floor in `manifests/` afterward.
- Do not author a bespoke confidence rubric or a second behavior-change
  classifier; reuse the `type::` label.

## Requirements

- R1: `conversation.test-first` removed through `meta:remove-skill`; historical
  records retained.
- R2: `test-first-evidence` triggers on test-first-mode-style requests (absorbed
  entry point).
- R3: `test-first-evidence` workflow carries the classify → failing-first →
  scope-to-green → final-validation guidance.
- R4: A `type::feature` / `type::fix` PR with neither a verified
  `test-first-evidence` record nor an explicit waiver in `--test-first-file` is
  blocked; `type::docs` / `chore` / `style` / `build` PRs are unaffected.
- R5: `guided-feature-build` no longer names the removed mode.
- R6: `git-delivery.md` documents the gate and waiver mechanics.

## Acceptance Criteria

- A1: `rg 'conversation\.test-first'` over `core manifests targets tests
  docs/source` returns only the retained historical archive entry.
- A2: A "do this test-first" style request resolves to `test-first-evidence`.
- A3: A simulated `type::feature` PR with no evidence and no waiver is blocked by
  the gate; a `type::docs` PR is not.
- A4: `bash scripts/ci/all.sh && bash tests/hooks/run.sh` passes, including a new
  hook test covering the gate's block and waiver paths.
- A5: `guided-feature-build` contains no reference to the removed mode skill.

## Validation Plan

- Run the `meta:remove-skill` governed sequence
  (`skill-governance-audit.sh --update-counts`, render `--update-golden`,
  sandbox rehearsal, runtime-smoke `--domain conversation`).
- Add a `tests/hooks/` case for the gate (block path + waiver path) if the gate
  lands as a shared hook.
- Run `bash scripts/ci/all.sh && bash tests/hooks/run.sh` (the declared
  `project-dev` validation).
- Spot-check that `test-first-evidence` triggers on a test-first request and that
  a feature PR without evidence is blocked while a docs PR is not.

## Risks And Guardrails

- **Bare-delete regression**: removing the mode without the enrich/gate would
  zero out the discipline. Guardrail: Decision 8 sequencing (enrich → gate →
  remove in one coordinated change).
- **Gate false-negatives via mislabeling**: a behavior change mislabeled
  `type::chore` escapes the gate. Residual risk accepted; mitigated because the
  gate keys on the same labels reviewers already scrutinize, and the label is
  validated by `forge-cli --strict-labels`.
- **"First" not provable mechanically**: enforce verified-evidence-exists via the
  record's failing-then-final structure; documented limitation (Decision 7).
- **nils-cli coupling**: if the gate needs new released CLI behavior, it is
  upstream work and must follow the coupled-nils-cli release boundary before the
  pin moves.

## Execution

- Status: not started; ready for tier decision.
- Next-task source: this document.
- Recommended next workflow: L2 coupled, gate-first.
  - Sprint 1 (`sympoies/nils-cli`): implement the option-(b) gate in `forge-cli
    pr create` / `agent-runtime pr-body`, land the PR, cut a release, bump the
    tap, and bump the pin in this repo via `meta:nils-cli-bump`.
  - Sprint 2 (`agent-runtime-kit`, one PR): enrich `test-first-evidence`, remove
    `conversation.test-first` via `meta:remove-skill`, update
    `guided-feature-build`, and document the gate in `git-delivery.md`.
  - This capture is the coordination source for both sprints. A single
    plan-tooling bundle is a poor fit because its `Location` validation expects
    repo-relative paths that exist in this repo, and Sprint 1 lives in nils-cli;
    if a formal tracker is wanted, scope the bundle to Sprint 2 and link the
    nils-cli PR as the dependency.
  (No `Recommended plan` / `Recommended execution state` lines: this remains a
  `docs/discussions/` capture, not a plan-tooling bundle.)

## Retention Intent

Coordination material; cleanup-eligible once the redesign ships or is abandoned.
Promote to canon (likely a section in `git-delivery.md`) only if the gate design
becomes authoritative reference beyond this one change.

## Read-First References

- `[F1]` `AGENT_HOME.md` — "Work Mode" test-first policy line.
- `[F2]` `core/skills/conversation/test-first/SKILL.md.tera` +
  `references/prompts/test-first.md` (the mode being removed).
- `[F3]` `core/skills/evidence/test-first-evidence/SKILL.md.tera` (the
  deterministic evidence CLI/skill).
- `[F4]` `core/skills/pr/create-pr/SKILL.md.tera` (`--test-first-file`) and
  `core/policies/git-delivery.md` (PR body minimum sections).
- `[F5]` `core/policies/forge-label-taxonomy.md` + `manifests/forge-labels.yaml`
  (`type::` taxonomy and trivial-exemption set).
- `[F6]` `core/skills/conversation/guided-feature-build/SKILL.md.tera`
  (Phase 5 + Boundary; merged in PR #328).
- `core/policies/work-tier-levels.md` (tier classification for the execution).

## Recommended Next Artifact

A work-tier decision. If L2: a `docs/plans/<YYYY-MM-DD>-<slug>/` bundle promoted
from this capture, then `create-plan-tracking-issue`. If a single coordinated PR
suffices: `meta:remove-skill` for `conversation.test-first` plus the
`test-first-evidence` enrichment and the PR-delivery gate, all behind one PR.
