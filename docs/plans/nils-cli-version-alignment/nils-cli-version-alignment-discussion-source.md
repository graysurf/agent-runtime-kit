# nils-cli Version Alignment Discussion Source

- Status: ready for plan generation
- Date: 2026-05-24
- Source: user discussion in the Claude session that asked whether the repo
  has a confirmation/diff mechanism after a `nils-cli` bump. The discussion
  surveyed the current pin/manifest layout, identified four gaps in active
  enforcement, and converged on a three-layer split between upstream
  `nils-cli`, the repo CI gate stack, and a new repo-local skill.
- Intended next step: feed this document into `create-plan` (or
  `create-plan-tracking-issue` if delivered as a lightweight tracker) so the
  three landing steps below execute in order, with the minimal CI gate
  shipping first.

## Execution

- Recommended plan: docs/plans/nils-cli-version-alignment/nils-cli-version-alignment-plan.md
- Recommended execution state: docs/plans/nils-cli-version-alignment/nils-cli-version-alignment-execution-state.md

## Purpose

When `sympoies/nils-cli` cuts a new minor (the cadence today is roughly
1–2 releases per month), the repo today relies on PR review to keep four
artifacts in lock-step:

1. `docs/source/nils-cli-surface.md` snapshot (version pin + crate→binary
   table + per-crate Notes).
2. `README.md` Version baseline row.
3. `SUPPORT_MATRIX.md` per-row `min_nils_cli` cells.
4. `manifests/skills.yaml` / `manifests/plugins.yaml` `required_clis`
   floors — bumped selectively when an upstream change actually affects
   a declared binary surface.

CI gates exercise the *installed* nils-cli binaries (render, audit-drift,
doctor, sandbox install rehearsal), so any host-level version mismatch is
invisible until a contributor runs the wrong binary against the wrong
snapshot doc. This document records the converged design for closing that
gap with two artifacts: a deterministic alignment gate that lives upstream
in nils-cli, and a repo-local bump skill that orchestrates the
agent-judgment portion of every release uptake.

## Confirmed Facts

- [U1] User asked whether the repo has any automated confirmation /
  alignment check after a `nils-cli` bump. Existing answer is "no
  automated check; PR review only."
- [U2] User wants automation, but accepts that an agent must read the
  upstream commit / release notes range to decide which `required_clis`
  floors deserve a bump.
- [U3] User wants the work split between CI (mechanical) and a skill
  (agent-assisted), and asked for an evaluation before implementation.
- [U4] User requested a phased landing: minimal CI gate first, then
  promote shared mechanical pieces upstream, then write the skill last.
- [F1] `docs/source/nils-cli-surface.md:8` pins the surface to
  `v0.17.6` with snapshot date `2026-05-23`; the doc itself states
  "refresh this snapshot at every nils-cli minor release."
- [F2] `README.md:19` carries the surface pin row; `SUPPORT_MATRIX.md`
  contains both `min_nils_cli` cells and a "When this matrix needs an
  update" checklist (`SUPPORT_MATRIX.md:167-168`) that explicitly names
  rolling past the current pin as a refresh trigger. None of these
  cross-references are enforced.
- [F3] `manifests/skills.yaml` declares per-skill `required_clis`
  semver floors (e.g. `agent-out: ">=0.13.0"`, `agent-docs: ">=0.16.0"`)
  and the file header states the audit-drift gate "rejects any
  surviving placeholder" — but placeholder rejection is not the same
  as floor-vs-installed comparison.
- [F4] `scripts/ci/all.sh` runs `agent-runtime`, `plan-tooling`, and
  `python3` against whatever is on `PATH`; positions 5 (`audit-drift`),
  6 (`doctor --class skill-surface --product codex`), and 7 (sandbox
  install rehearsal) all execute the installed surface but never
  compare its version string against the snapshot doc.
- [F5] `manifests/cli-tools.yaml:12-14` documents the boundary
  explicitly: "Nils-cli binaries (agent-out, agent-docs,
  semantic-commit, plan-tooling, git-cli, etc.) are NOT listed here.
  They ship as part of the `nils-cli` Homebrew formula and are pinned
  in `docs/source/nils-cli-surface.md`." `agent-runtime doctor` today
  probes third-party brew formulas from this manifest only.
- [F6] `DEVELOPMENT.md:71-90` states the upstream boundary: "Durable
  runtime behavior belongs in `sympoies/nils-cli` … any stable parser,
  exit-code contract, cross-product behavior, or shared capability
  belongs upstream in nils-cli."
- [F7] `forge-cli` v0.17.6 added `forge-cli issue list` with state /
  label / author / assignee / limit filters (per
  `docs/source/nils-cli-surface.md` notes column). This is the
  canonical primitive a future skill should call when paginating PR /
  issue ranges in a bump window.
- [F8] Existing plan bundles under `docs/plans/<slug>/` use the
  three-file pattern `<slug>-discussion-source.md` →
  `<slug>-plan.md` → `<slug>-execution-state.md`
  (e.g. `docs/plans/support-matrix/`).
- [I1] Because CI runs against the host's `agent-runtime` binary, a
  contributor on an outdated brew install can produce a green CI run
  that still asserts the old surface — the failure mode is silent
  drift, not loud regression.
- [I2] The skill cadence (1–2 invocations per month) is high enough to
  justify automation, but low enough that "agent proposes patch, human
  reviews" beats "auto-bump-and-merge."

## Decisions

- [D1] **Three-layer split**:
  - Upstream `nils-cli` owns the deterministic alignment check as a new
    `agent-runtime doctor` class (working name: `version-alignment`).
    Stable exit codes and machine-parseable output live there per
    [F6].
  - The repo's `scripts/ci/all.sh` adds a position that calls the new
    doctor class and asserts `block=0`.
  - A new repo-local skill orchestrates the bump workflow that mixes
    mechanical evidence-gathering with agent judgement.
- [D2] **Skill name and domain**: `meta:nils-cli-bump`, sitting beside
  `meta:agent-docs`, `meta:semantic-commit`, and `meta:heuristic-inbox`
  in `core/skills/meta/`.
- [D3] **Skill output is a proposal, not a decision**: The agent step
  that reads the release notes and commit range MUST tag every
  candidate `required_clis` bump with `[A#]` source citations (per
  `AGENT_HOME.md` "Evidence & Traceability") and MUST NOT write the
  manifest change directly. The user accepts/rejects each candidate
  before commit.
- [D4] **Landing order is strictly sequential**:
  1. Minimal CI gate in `scripts/ci/all.sh` that reads the pin from
     `docs/source/nils-cli-surface.md` and compares it to
     `agent-runtime --version`. ~30 lines of shell. Closes [I1]
     immediately.
  2. After 1–2 real bumps exercise the gate, promote the mechanical
     parts upstream as `agent-runtime doctor --class version-alignment`
     and replace the shell gate with a call to the doctor class.
  3. Write `meta:nils-cli-bump` last, only after the doctor class is
     released and the boundary between mechanical and judgement work
     is clear.
- [D5] **Manifest counts vs. binaries**: The skill diffs the upstream
  `crates/` directory only when a local `nils-cli` checkout is
  available (per `DEVELOPMENT.md` "Coupled nils-cli Work" pattern).
  Absent a checkout, the skill explicitly states "crate add/remove
  not checked" instead of silently skipping.
- [D6] **No reinventing semver**: Floor comparisons reuse whatever the
  upstream doctor class exposes; the repo-side skill never implements
  its own semver parser.

## Scope

- A minimal CI gate in `scripts/ci/all.sh` (new position, after
  position 7 sandbox install rehearsal, before position 8
  runtime-smoke) that:
  - reads the pin string from `docs/source/nils-cli-surface.md` line 8
    (single grep / sed pattern; documented in the gate banner);
  - calls `agent-runtime --version` and compares;
  - prints the pinned and detected versions on success, exits non-zero
    with a diff banner on mismatch.
- An upstream proposal record (filed as an issue in
  `sympoies/nils-cli`) that defines the `agent-runtime doctor --class
  version-alignment` shape: probes `agent-runtime --version`, parses
  `docs/source/nils-cli-surface.md` pin, parses every `required_clis`
  floor in `manifests/skills.yaml` / `manifests/plugins.yaml`,
  reports `ok / warn / block / findings` matching the existing
  skill-surface doctor envelope.
- A `meta:nils-cli-bump` skill scaffold under
  `core/skills/meta/nils-cli-bump/` whose `SKILL.md` documents the
  bump workflow (sections detailed in [Requirements](#requirements)).

## Non-Scope

- Auto-merging bump PRs.
- Renaming or migrating the existing `nils-cli-surface.md` schema.
- Adding `nils-cli` binaries to `manifests/cli-tools.yaml` (would
  contradict [F5]).
- Implementing semver math in repo-local shell or Python (would
  contradict [D6]).
- Subsuming `agent-docs` or `forge-cli` workflows; the new skill
  composes them, it does not duplicate them.
- Detecting *behavioural* regressions in nils-cli releases — that
  remains the job of the existing render / audit-drift / doctor /
  sandbox-install-rehearsal / runtime-smoke gates.

## Implementation Boundaries

- Upstream-owned: parsing surface doc pin, probing binary versions,
  comparing semver, emitting JSON envelope. Belongs in
  `sympoies/nils-cli` per [F6].
- Repo-owned: CI gate banner text and exit handling
  (`scripts/ci/all.sh`); skill prose, prompt scaffolding, output
  templates (`core/skills/meta/nils-cli-bump/`); manifest entry in
  `manifests/skills.yaml`.
- Agent-owned (inside the skill): reading `gh release view` output and
  `gh api compare` page, summarising which crates / binaries changed,
  proposing `required_clis` floor candidates with `[A#]` citations.
- Human-owned: accepting / rejecting each candidate, deciding whether
  a release is suitable for uptake at all, authoring the surface-doc
  Notes column copy.

## Requirements

### CI gate (Step 1)

- Lives in `scripts/ci/all.sh` as a new banner position. Reuses the
  `banner` helper and the `require_bin` pattern already in the file.
- Reads the pinned tag from a stable line in
  `docs/source/nils-cli-surface.md` (defined as the `Active git
  describe --tags output:` line, currently line 8 [F1]) using a
  `grep` / `sed` pipeline. The exact regex is documented in the gate
  banner so a reader can reproduce the parse.
- On mismatch, prints both the pinned and the detected version, the
  parse used, and a one-line remediation (`brew upgrade
  sympoies/tap/nils-cli` or "refresh the snapshot doc and re-run CI").
- Does not call any new binary. Stays inside `bash 3.2 + grep + sed`
  per the file's macOS compatibility note.

### Upstream doctor class (Step 2)

- New class name: `version-alignment`.
- Probes:
  - `agent-runtime --version` vs `docs/source/nils-cli-surface.md` pin.
  - For each `required_clis` entry in `manifests/skills.yaml` and
    `manifests/plugins.yaml`, the binary's `--version` vs the
    declared floor; report `ok / warn / block` per binary.
- Output envelope matches `agent-runtime doctor --class skill-surface`
  shape (`checks`, `ok`, `warn`, `block`, `findings`,
  `acceptance_boundary`, `exit_code`) so the CI gate can reuse the
  existing python3 parser pattern at `scripts/ci/all.sh` Position 6.
- Replaces the Step-1 shell gate when released; the shell gate is
  removed in the same PR that wires the doctor class call in.

### `meta:nils-cli-bump` skill (Step 3)

- Inputs: `--from <tag>` (defaults to current pin in surface doc),
  `--to <tag>` (defaults to `latest` resolved via
  `gh release view --json tagName`).
- Workflow sections in `SKILL.md`:
  1. Gather upstream evidence with `gh release view` and
     `gh api repos/sympoies/nils-cli/compare/<from>...<to>`. Use
     `forge-cli issue list` [F7] when issue cross-links are needed.
  2. If a local nils-cli checkout exists (`$HOME/Project/sympoies/nils-cli`
     per `DEVELOPMENT.md`), list `crates/` and diff against the
     surface doc table. Otherwise, log the limitation per [D5].
  3. Agent judgement: for each PR in the range, decide whether the
     change affects a binary declared in this repo's `required_clis`.
     Output a structured table of candidate floor bumps with `[A#]`
     citations. **Do not write manifests in this step.**
  4. Produce a patch proposal block covering the four artifacts
     listed in [Purpose](#purpose) plus any candidate `required_clis`
     changes the user accepts.
  5. Validate via the doctor class from Step 2 and `scripts/ci/all.sh`.
  6. Hand off to `meta:semantic-commit`.
- Manifest entry under `manifests/skills.yaml` with appropriate
  `required_clis` floors (at minimum: `agent-runtime`, `forge-cli`,
  `agent-docs`).

## Acceptance Criteria

- **Step 1 lands when**: `scripts/ci/all.sh` fails locally when the
  host's `agent-runtime --version` does not match the surface doc
  pin; passes when they match; the banner cites the parse used.
  Existing CI positions remain green.
- **Step 2 lands when**: `sympoies/nils-cli` ships `agent-runtime
  doctor --class version-alignment` in a tagged release, this repo's
  `docs/source/nils-cli-surface.md` snapshot pin is bumped to that
  release, and `scripts/ci/all.sh` calls the doctor class with the
  same `block=0` assertion shape as Position 6.
- **Step 3 lands when**: `core/skills/meta/nils-cli-bump/SKILL.md` is
  rendered into both Codex and Claude builds, the skill produces a
  patch proposal artifact for at least one real bump exercise, and
  `manifests/skills.yaml` carries the corresponding entry with
  required CLI floors.
- For every step, golden tests under `tests/golden/` and the
  audit-drift gate remain green; no new placeholder appears in
  `required_clis`.

## Validation Plan

- Step 1:
  - Run `scripts/ci/all.sh` on a host where `agent-runtime --version`
    matches the surface doc — expect pass.
  - Temporarily edit the surface doc pin string in a worktree —
    expect non-zero exit and a clear remediation banner.
- Step 2:
  - Before release: run the upstream doctor class against this repo
    from a coupled debug build per `DEVELOPMENT.md:86-127`. Assert
    `block=0` when manifests and host match.
  - After release: brew-install the new nils-cli tag, refresh the
    surface doc, re-run `scripts/ci/all.sh`.
- Step 3:
  - Live exercise: run the skill against the next real
    `v0.17.6 → v0.17.7` (or current next) bump. Confirm the proposal
    artifact lists every changed binary that this repo's
    `required_clis` declares; confirm zero false-positive floor bumps
    after human review.
  - Recorded evidence: `agent-out project --topic nils-cli-bump
    --mkdir`, link the proposal artifact + validation commands from
    a `skill-usage.record.v1` envelope.

## Risks And Guardrails

- **Risk**: Agent reads commit titles and misclassifies a refactor as
  a breaking change, recommending an unnecessary floor bump.
  **Guard**: [D3] — candidates only, never direct manifest writes;
  every candidate carries `[A#]` source links the human can verify.
- **Risk**: `gh api compare` truncates when the range covers many
  commits.
  **Guard**: Skill uses pagination and falls back to
  `forge-cli issue list` [F7] for filterable enumeration; documents
  the fallback in `SKILL.md`.
- **Risk**: Local nils-cli checkout absent → skill cannot diff crate
  list.
  **Guard**: [D5] — explicit limitation note in the proposal artifact,
  not silent skip.
- **Risk**: Mechanical alignment logic ends up duplicated between
  shell gate (Step 1) and upstream doctor class (Step 2).
  **Guard**: [D4] sequencing — Step 2 PR removes the Step-1 shell
  gate in the same change; no parallel maintenance window.
- **Risk**: Snapshot doc pin string moves to a different line and
  the Step-1 grep silently parses the wrong field.
  **Guard**: Gate parses by leading prefix string (`Active git
  describe --tags output:`) rather than by line number, and prints
  the matched line so a typo / move is obvious in CI output.
- **Risk**: Auto-uptake to a buggy nils-cli release.
  **Guard**: Out of scope [Non-Scope]; the skill always produces a
  PR proposal, never auto-merges.

## Retention Intent

- Coordination artifact. This document and its sibling plan /
  execution-state files are cleanup-eligible after Step 3 lands per
  `docs/source/docs-placement-retention-policy-v1.md` (`docs/plans/`
  row).
- If Step 3 yields reusable workflow guidance that does not belong in
  the skill's own `SKILL.md`, promote that subset into
  `core/policies/` (e.g. a `nils-cli-bump-protocol.md`) before
  cleanup.

## Open Questions

- [Q1] Should Step 1's shell gate live before or after Position 7
  (sandbox install rehearsal)? Argument for **before**: a version
  mismatch makes downstream gates ambiguous. Argument for **after**:
  keeps the cheap render/golden/audit-drift block intact before any
  alignment-specific check.
- [Q2] When Step 2 lands the doctor class, should `required_clis`
  drift produce `warn` or `block` for "host newer than floor"? The
  skill-surface doctor pattern treats both deviations as `block`; the
  user may prefer `warn` here so a contributor can move ahead of the
  declared floor without editing manifests just to keep CI green.
- [Q3] Whether the Step-3 skill should also emit a draft PR body
  (title, summary, changelog-style bullets) or stop at the patch
  proposal. The first cut is "stop at proposal," but
  `pr:deliver-github-pr` integration is a plausible follow-up.
- [Q4] Whether `meta:nils-cli-bump` should also accept `--dry-run`
  default-on, parallel to other meta skills.

## Read First References

- `docs/source/nils-cli-surface.md` — current surface pin and crate
  table; the artifact most-bumped in this workflow.
- `README.md` Version baseline table — surface row updated by the
  skill.
- `SUPPORT_MATRIX.md` "When this matrix needs an update" section —
  authoritative checklist that this work automates.
- `DEVELOPMENT.md` "Coupled nils-cli Work" section
  (`DEVELOPMENT.md:86-127`) — established pattern for working against
  an unreleased nils-cli build; the skill builds on top of it.
- `manifests/skills.yaml` header comment — current `required_clis`
  schema rules and placeholder rejection guarantee.
- `scripts/ci/all.sh` Position 6 — reference shape for the
  python3-parsed doctor envelope that Step 2 should match.
- `docs/plans/support-matrix/support-matrix-discussion-source.md` —
  sibling plan-source document used as the structural template for
  this file.

## Recommended Next Artifact

- `create-plan` against this document → produces
  `nils-cli-version-alignment-plan.md` plus the matching
  execution-state file, with one phase per step in [D4] and
  acceptance criteria mirrored from [Acceptance Criteria].
- Alternative: `create-plan-tracking-issue` if delivery should
  surface in a lightweight GitHub-backed tracker rather than a full
  plan bundle; the same execution / acceptance lines map cleanly to
  lifecycle comments.
