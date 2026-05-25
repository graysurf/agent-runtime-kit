# Project Runtime Setup Implementation Handoff

- Status: ready for plan generation
- Date: 2026-05-26
- Source: user discussion about repo script dispatcher discoverability,
  project-local `pre-pr` adoption, and a setup workflow for new repositories;
  local inspection of current `agent-runtime-kit` dispatcher skills, project
  lifecycle skill, validation policy, and heuristic-system records.
- Intended next step: feed this document into a focused implementation plan for
  trimming low-value dispatcher skills and adding a project setup workflow. This
  is a source artifact, not an implementation plan.
- Source type: discussion-to-implementation-doc

## Execution

- Recommended plan: docs/plans/project-runtime-setup/project-runtime-setup-plan.md
- Recommended execution state: docs/plans/project-runtime-setup/project-runtime-setup-execution-state.md
- Recommended first implementation task: remove `bench` and `demo` from the
  global managed dispatcher skill surface and update every manifest, fixture,
  smoke, golden, and docs reference that treats them as installed managed
  skills.

## Purpose

The current repo script dispatcher model exposes several global managed skills
whose only behavior is to find and run a project-owned
`.agents/scripts/<name>.sh` script. That pattern is useful for high-value,
policy-sensitive entrypoints such as `pre-pr`, `release`, `deploy`, and
project-local bootstrap. It is less useful for rarely used convenience
entrypoints such as `bench` and `demo`, which add skill-list noise and are easy
to forget.

The target direction is to make the retained dispatcher surface smaller and more
actionable, while adding an explicit project setup workflow that helps a new or
unadopted repository create the project-local `.agents/` conventions needed by
the retained skills.

## Confirmed Facts

- [U1] The user frequently forgets that the repo script dispatcher skills exist,
  so the current surface is not discoverable enough in practice.
- [U2] The user does not expect to use `bench` and `demo` often and wants to
  evaluate removing those two managed skills.
- [U3] The user wants `pre-pr` to be considered for stronger project-repo
  adoption instead of remaining an easy-to-miss optional convention.
- [U4] The user wants a setup-oriented skill family so a repository that has not
  installed project-local agent conventions can be guided into creating the
  required scripts and skills.
- [F1] `docs/plans/<slug>/` is the documented location for coordination plan
  bundles, and plan source filenames should use
  `<slug>-discussion-source.md` when possible. See
  `docs/source/docs-placement-retention-policy-v1.md:23-34` and
  `docs/source/docs-placement-retention-policy-v1.md:65-70`.
- [F2] The current managed skill manifest includes `meta.bench`,
  `meta.bootstrap`, `meta.demo`, `meta.deploy`, `meta.pre-pr`, and
  `meta.release`, each rendered for Codex and Claude and depending on
  `agent-run >=0.20.0` for dispatcher execution. See
  `manifests/skills.yaml:87-113`, `manifests/skills.yaml:130-155`, and
  `manifests/skills.yaml:254-280`.
- [F3] The project-local extensibility contract currently lists six dispatcher
  skills: `bench`, `demo`, `deploy`, `pre-pr`, `release`, and `bootstrap`.
  It requires the runtime kit to dispatch to
  `<target-repo>/.agents/scripts/<name>.sh`, while each consuming repo owns the
  implementation. Missing scripts report "no project-local implementation"
  rather than guessing. See
  `docs/source/inventory-target-architecture.md:874-892`.
- [F4] Each dispatcher skill body is intentionally thin. For example,
  `bootstrap` dispatches to `.agents/scripts/bootstrap.sh`; `pre-pr` dispatches
  to `.agents/scripts/pre-pr.sh`; `release` dispatches to
  `.agents/scripts/release.sh`; and each uses
  `agent-run exec --cwd "$repo_root" --` for project environment handling. See
  `core/skills/meta/bootstrap/SKILL.md.tera:1-67`,
  `core/skills/meta/pre-pr/SKILL.md.tera:1-68`, and
  `core/skills/meta/release/SKILL.md.tera:1-68`.
- [F5] The current project-local smoke gate validates all six dispatcher script
  names and verifies wired and missing-script overlay reports. See
  `DEVELOPMENT.md:283-287` and
  `tests/projects/project-local-smoke/run.sh:19-43`.
- [F6] There is an open heuristic-system entry for the `pre-pr` gap: bare or
  freshly bootstrapped repos without `.agents/scripts/pre-pr.sh` cannot run the
  pre-PR validation gate, and agents can silently degrade to skipped or ad-hoc
  validation. See
  `core/policies/heuristic-system/error-inbox/pre-pr-cli-repo-local-fallback/ENTRY.md:12-19`
  and
  `core/policies/heuristic-system/error-inbox/pre-pr-cli-repo-local-fallback/ENTRY.md:38-48`.
- [F7] `create-project-skill` already owns project-local skill scaffolding and
  can create optional `.agents/scripts/<command>.sh` wrappers; it creates
  `.agents/scripts/pre-pr.sh` only when explicitly requested with
  `--with-pre-pr-stub`. See
  `core/skills/meta/create-project-skill/SKILL.md.tera:84-112`.
- [F8] `bootstrap` is already a dispatcher for a repository-owned
  `.agents/scripts/bootstrap.sh`, not a workflow for adopting agent-runtime
  conventions in a new repository. See
  `core/skills/meta/bootstrap/SKILL.md.tera:1-20`.

## Decisions

- [D1] Remove `bench` and `demo` from the global managed skill surface.
  Repositories may still keep project-owned `.agents/scripts/bench.sh` or
  `.agents/scripts/demo.sh` if they are useful locally, but runtime-kit should no
  longer install managed `bench` and `demo` dispatcher skills by default.
- [D2] Keep `bootstrap`, `deploy`, `pre-pr`, and `release` as managed dispatcher
  skills because they represent setup, deployment, validation, and release
  boundaries where guessing a generic command is unsafe.
- [D3] Treat `.agents/scripts/pre-pr.sh` as required for repositories that have
  adopted the project runtime setup. Do not require it for arbitrary external
  checkouts that have not opted into the convention.
- [D4] Missing `pre-pr` in an adopted repo should be a blocking setup or doctor
  finding. Missing `pre-pr` in an unadopted repo should produce a clear
  actionable message pointing to the setup workflow.
- [D5] Do not add a generic fallback validation stack to the `pre-pr` skill.
  The project repo owns its validation gate; runtime-kit should scaffold or
  prompt for that gate instead of inventing one.
- [D6] Add a new setup-oriented managed workflow with the working skill name
  `setup-project`. Its job is to guide a target repository into adopting
  project-local agent conventions.
- [D7] Do not reuse the existing `bootstrap` name for the setup workflow.
  `bootstrap` remains the dispatcher to `.agents/scripts/bootstrap.sh`;
  `setup-project` handles repo adoption.
- [D8] Make setup dry-run-first. The setup workflow should inspect the target
  repo, propose files and validation commands, and require explicit apply before
  writing.
- [D9] The setup workflow may call or reuse `create-project-skill` for
  project-local skills and wrappers, but it should not make project-local skill
  creation mandatory.
- [D10] Setup must not generate a successful no-op `pre-pr.sh`. If it cannot
  infer or confirm a validation command, it should create no file or create a
  clearly failing TODO stub only with explicit user approval.

## Scope

- Remove managed `bench` and `demo` sources, manifest entries, plugin entries,
  rendered outputs, golden snapshots, sandbox expected skill entries, runtime
  smoke acceptance entries, project-local smoke references, and docs that list
  them as globally installed dispatcher skills.
- Keep any historical plan records intact; update active source-of-truth docs
  and current fixtures only.
- Add a `setup-project` managed skill under the meta domain, with rendered Codex
  and Claude surfaces.
- Add setup workflow guidance for target repositories that have no `.agents/`
  directory, a partial `.agents/scripts/` directory, or existing project-local
  `.agents/skills/`.
- Add validation or doctor behavior that can classify a target repo as adopted
  and fail closed when adopted repos are missing executable
  `.agents/scripts/pre-pr.sh`.
- Update `pre-pr` missing-script guidance so agents stop with an actionable
  setup path instead of hand-rolling validation.

## Non-Scope

- Do not remove the project-owned convention that a repository may define
  `.agents/scripts/bench.sh` or `.agents/scripts/demo.sh` for its own use.
- Do not change real benchmark, demo, deployment, release, or validation logic
  inside consuming repositories.
- Do not make `.agents/scripts/pre-pr.sh` mandatory for every arbitrary
  checkout the agent visits.
- Do not rename the existing `bootstrap` dispatcher.
- Do not make host/global runtime installation part of `setup-project`.
  First-time host bootstrap remains owned by `scripts/setup.sh` and the released
  runtime install path.
- Do not add broad docs indexes for this source document unless the later plan
  promotes the outcome to long-lived architecture docs.

## Implementation Boundaries

- Global managed skills are runtime-kit-owned and must update manifests,
  render outputs, goldens, sandbox expected lists, runtime-smoke matrix entries,
  and docs together.
- Project-owned scripts under `.agents/scripts/` remain consuming-repo-owned.
  Runtime-kit should scaffold, dispatch, or diagnose them, but should not embed
  repo-specific validation or release behavior in managed skill bodies.
- `setup-project` should run from or target a git worktree and clearly report
  the repo root it is about to inspect or mutate.
- `setup-project` should refuse destructive overwrites unless the user
  explicitly approves replacement.
- If setup behavior needs stable dry-run/apply JSON, reusable reference graphs,
  or semver-sensitive machine-readable output, extract that primitive to
  `nils-cli`, release it, and call it from the skill.
- Keep generated shell compatible with macOS system Bash 3.2 unless the target
  repo explicitly chooses a narrower host contract.

## Requirements

- `bench` and `demo` no longer appear in the managed skill list for Codex or
  Claude after render/install.
- Existing retained dispatcher skills still route through
  `agent-run exec --cwd "$repo_root" -- ./.agents/scripts/<name>.sh "$@"`.
- `setup-project --dry-run` reports the current adoption state of a target repo:
  missing `.agents/`, missing `.agents/scripts/`, missing or non-executable
  `pre-pr.sh`, existing `bootstrap.sh`, existing `release.sh`, existing
  `deploy.sh`, and existing project-local `.agents/skills/`.
- `setup-project --apply` can create the required directory structure and an
  executable `pre-pr.sh` from an explicit or confirmed validation command.
- The setup workflow can optionally scaffold `bootstrap.sh`, `release.sh`,
  `deploy.sh`, and project-local skill wrappers when requested.
- The setup workflow distinguishes between unadopted repos and adopted repos
  with incomplete required files.
- Adopted repo diagnostics fail closed when executable `pre-pr.sh` is missing.
- Missing-script messages for `pre-pr` name the target repo and the setup path.

## Acceptance Criteria

- Rendered Codex and Claude managed skill lists exclude `bench` and `demo`.
- `agent-runtime doctor --class skill-surface --product codex` and the matching
  Claude shape checks pass after expected-count updates.
- Runtime smoke and project-local smoke no longer expect managed `bench` and
  `demo`, while still covering retained dispatcher behavior.
- A fixture for an unadopted repo shows `setup-project --dry-run` recommendations
  without mutation.
- A fixture for an adopted repo missing `pre-pr.sh` reports a blocking finding.
- A fixture for an adopted repo with executable `pre-pr.sh` passes the project
  setup diagnostic.
- `pre-pr` invoked in a repo missing `.agents/scripts/pre-pr.sh` exits with an
  actionable setup message.
- Existing `create-project-skill` behavior remains compatible, including
  explicit `--with-pre-pr-stub` behavior.

## Validation Plan

- `agent-docs resolve --context startup --strict --format checklist`
- `agent-docs resolve --context project-dev --strict --format checklist`
- `agent-runtime render --product codex`
- `agent-runtime render --product claude`
- `agent-runtime render --target support-matrix`
- `git diff --exit-code -- tests/golden/` after intentional golden updates are
  reviewed and committed.
- `bash scripts/ci/skill-governance-audit.sh`
- `bash tests/runtime-smoke/run.sh --mode matrix`
- `bash tests/runtime-smoke/run.sh --mode deterministic --domain meta`
- `bash tests/projects/project-local-smoke/run.sh`
- `bash scripts/ci/all.sh` before delivery.

## Risks And Guardrails

- Removing `bench` and `demo` changes live skill discovery. The implementation
  must update both deterministic expected lists and live-surface acceptance notes
  so the change is intentional, not mistaken for drift.
- Making `pre-pr` required too broadly would break ad-hoc external checkouts.
  The requirement must be scoped to adopted repos.
- A setup workflow that writes placeholder gates can create false confidence.
  Generated `pre-pr.sh` must either run a confirmed command or fail clearly.
- `setup-project` can become a second project-skill lifecycle workflow if it
  starts owning `.agents/skills/` details directly. It should delegate to or
  reuse `create-project-skill` for project-local skill scaffolding.
- Host runtime setup and project repo setup must stay separate. A repo setup
  workflow should not install Homebrew, mutate global runtime homes, or rewrite
  user shell profiles.

## Retention Intent

This document is coordination source material for a focused implementation plan.
It is cleanup-eligible after execution closes unless the final design is
promoted into `docs/source/inventory-target-architecture.md`,
`DEVELOPMENT.md`, or another canonical runtime policy document.

## Read-First References

- `docs/source/docs-placement-retention-policy-v1.md`
- `docs/source/inventory-target-architecture.md`
- `core/skills/meta/bootstrap/SKILL.md.tera`
- `core/skills/meta/pre-pr/SKILL.md.tera`
- `core/skills/meta/release/SKILL.md.tera`
- `core/skills/meta/create-project-skill/SKILL.md.tera`
- `core/policies/heuristic-system/error-inbox/pre-pr-cli-repo-local-fallback/ENTRY.md`
- `DEVELOPMENT.md`
- `tests/projects/project-local-smoke/run.sh`

## Recommended Next Artifact

Create `docs/plans/project-runtime-setup/project-runtime-setup-plan.md` with
sequenced work for surface removal, setup workflow design, adopted-repo
diagnostics, validation fixtures, render/golden updates, and final live skill
refresh.
