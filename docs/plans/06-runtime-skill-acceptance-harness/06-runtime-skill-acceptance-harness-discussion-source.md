# Runtime Skill Acceptance Harness Discussion Source

- Status: open, implementation planning requested
- Date: 2026-05-22
- Source: user direction on Plan 06 acceptance needs, current repository
  validation state, Plan 05 Sprint 1-4 delivery state, and the existing
  architecture testing contract.
- Scope: define and implement an actual runtime acceptance harness before
  continuing Plan 05 Sprint 5+ migration work.

## Execution

- Recommended plan: docs/plans/06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-plan.md
- Recommended execution state: docs/plans/06-runtime-skill-acceptance-harness/06-runtime-skill-acceptance-harness-execution-state.md

## Purpose

Plan 05 has moved the first four migration sprints into
`agent-runtime-kit`: meta, media, browser, and evidence skill surfaces now
render, install, and pass drift checks. That is necessary, but it is not enough
to prove the skills are actually usable by an agent in an isolated workspace.

This plan creates the missing acceptance layer. It should prove that a fresh
runtime home can be built in a temporary folder, an isolated fixture workspace
can be entered, selected skills can be invoked through their intended runtime
surface or deterministic command path, and the resulting files, exit codes,
and outputs match an explicit checklist.

## Current Facts

- [U1] The requested execution policy is: when acceptance testing finds small
  repo bugs, fix them directly so the tests can pass; only stop for user
  confirmation when the test exposes a major design problem.
- [U2] The user wants to pause continued Plan 05 migration until the acceptance
  method is defined and the currently migrated skills have feedback.
- [F1] `DEVELOPMENT.md` currently lists render, golden output, plan validation,
  drift audit, and sandbox install rehearsal as the useful local gates.
- [F2] `scripts/ci/sandbox-install-rehearsal.sh` currently uses
  `agent-runtime install --dry-run` output as the skill-list source because the
  product CLIs do not expose a stable `--home <dir> --list-skills` contract.
- [F3] `docs/source/inventory-target-architecture.md` records that full
  execute-and-assert testing was not previously on the roadmap.
- [F4] The project-local and sandbox install fixture surfaces were still
  placeholders at this point, so no committed fixture workspace existed for
  runtime skill acceptance.
- [A1] A manual smoke probe on 2026-05-22 showed that
  `agent-runtime install --apply` can populate temporary Claude and Codex homes
  with the 19 currently migrated skills, and `agent-runtime doctor` reports no
  blocking findings for those temporary homes.

## Decisions

1. Create a new Plan 06 instead of continuing Plan 05 Sprint 5 immediately.
2. Treat Plan 06 as an acceptance harness plan, not another migration plan.
3. The first implementation should be deterministic and CI-friendly:
   `agent-runtime install --apply`, fixture workspaces, command-level probes,
   explicit expected outputs, and machine-readable result summaries.
4. Product-in-the-loop tests are required as a design goal but should be
   introduced behind a capability check. If Codex or Claude cannot run against
   a temporary home safely, record the gap and keep deterministic smoke as the
   blocking gate until a stable product invocation contract exists.
5. During Plan 06 execution, small repo defects discovered by the harness are in
   scope to fix immediately. Major design breaks require a user decision before
   changing the architecture.

## Scope

- In scope:
  - Add a committed acceptance test structure under `tests/runtime-smoke/`.
  - Add fixture workspaces that let an agent or deterministic runner execute
    representative tasks without touching real runtime homes.
  - Add temporary `live_home` and `state_home` setup for both Codex and Claude.
  - Add a runtime smoke runner that can install, inspect, execute probes, and
    emit a result summary.
  - Create an explicit acceptance matrix for the 16 Plan 05 Sprint 1-4 skills
    plus the three already-migrated reporting skills as regression coverage.
  - Wire stable deterministic acceptance into `scripts/ci/all.sh` only after
    expected outputs are stable.
  - Use test feedback to fix small path, render, manifest, docs, or harness bugs
    directly in this repo.
  - Record any nils-cli or product CLI capability gap as an extraction or
    blocker rather than hiding it in skill prose.
- Out of scope:
  - Continuing Plan 05 Sprint 5+ migration before the acceptance harness has a
    passing baseline.
  - Mutating the user's real `$HOME/.codex`, `$HOME/.claude`, auth, sessions,
    history, or caches.
  - Requiring network access for the default CI acceptance gate.
  - Mocking every external dependency of every skill.
  - Adding new nils-cli binary behavior in this repo; cross-binary changes
    belong in `sympoies/nils-cli`.

## Runtime Acceptance Model

The harness has three layers:

1. Install layer:
   - Create a temp root.
   - Create product-specific `live_home` and `state_home` paths.
   - Run `agent-runtime install --source-root "$REPO_ROOT" --product <product>
     --live-home "$tmp/<product>-home" --state-home "$tmp/state/<product>"
     --apply`.
   - Run `agent-runtime doctor` against the same temp paths.
   - Assert installed skill files exist and point at the expected rendered
     source.
2. Deterministic skill smoke layer:
   - Enter a committed fixture workspace.
   - Run safe command-level probes derived from the skill body and
     `required_clis`.
   - Assert exit code, output files, JSON shape, and absence of writes outside
     the declared temp output directory.
3. Product-in-the-loop layer:
   - If the product CLI can safely run with a temporary runtime home, ask the
     product agent to perform tiny acceptance tasks that should trigger the
     installed skill.
   - Capture output and classify whether the product used the intended skill
     surface.
   - Keep this layer optional or quarantined until it is stable enough for CI.

## Acceptance Checklist

The first acceptance matrix must cover these skill groups:

| Domain | Skills | Minimum acceptance |
| --- | --- | --- |
| meta | `agent-docs`, `agent-out`, `agent-scope-lock`, `heuristic-inbox`, `repo-retro`, `semantic-commit` | command probes run in fixture workspace, write only under temp output paths, and produce expected records or dry-run output |
| media | `image-processing`, `screen-record` | safe sample input or capability probe succeeds; host-permission-sensitive checks degrade with a clear skip status |
| browser | `browser-session`, `canary-check` | deterministic session/canary records can be created and verified without network access |
| evidence | `web-evidence`, `test-first-evidence`, `review-evidence`, `skill-usage`, `docs-impact`, `model-cross-check` | record/init/verify flows produce valid JSON or documented no-op results in fixture workspace |
| reporting regression | `daily-brief`, `project-retro`, `topic-radar` | existing rendered helper smoke remains callable in sample/offline mode where supported |

Each case should record:

- product (`codex`, `claude`, or `shared-cli`)
- skill id
- fixture workspace path
- setup command
- invocation command or product-agent prompt
- expected exit code
- expected files or JSON keys
- cleanup behavior
- disposition: `pass`, `fail`, `skip-host-capability`, or `blocked-design`

## Error Handling Policy

- Fix-now:
  - broken paths, missing fixture files, unstable expected output, missing
    execute bit, stale golden snapshots, bad manifest path, missing sandbox
    expected pin, unclear but local skill wording, and CI wiring mistakes.
- Fix-now if contained:
  - small changes to rendered skill bodies, plugin metadata, link maps,
    `required_clis`, or repo scripts when the existing architecture remains
    valid.
- Escalate before changing:
  - Codex or Claude cannot be isolated without touching real runtime homes.
  - Runtime activation requires a different product surface than the current
    architecture declares.
  - A skill needs deterministic behavior that no released nils-cli binary
    supports.
  - Passing the harness would require network, credentials, or non-hermetic
    product state in default CI.
  - The acceptance matrix shows that the migrated skill body pattern itself is
    wrong for a whole domain.

## Required Outputs

- `tests/runtime-smoke/` fixture and runner structure.
- A committed acceptance matrix, preferably
  `tests/runtime-smoke/acceptance-matrix.yaml`.
- A CI-friendly runner, preferably `tests/runtime-smoke/run.sh`, compatible with
  macOS system Bash and Linux.
- Stable expected outputs under `tests/runtime-smoke/expected/` or equivalent.
- Documentation in `DEVELOPMENT.md` explaining how to run the acceptance gate.
- Optional result artifacts in `agent-out` when running manually.
- Issue/execution evidence showing which skills passed, skipped, failed, or
  exposed design blockers.

## Validation Gate

- `bash tests/runtime-smoke/run.sh --mode deterministic`
- `bash tests/runtime-smoke/run.sh --mode install`
- `bash scripts/ci/all.sh`
- Optional/quarantined:
  - `bash tests/runtime-smoke/run.sh --mode product --product codex`
  - `bash tests/runtime-smoke/run.sh --mode product --product claude`

## Retention Intent

This plan bundle is execution coordination and can be cleaned up after Plan 06
is complete and the acceptance harness is promoted into normal development
docs. The harness itself should remain durable as a repository gate.

## Open Questions

- Whether product-in-the-loop smoke can be made stable enough for CI on the
  current Codex and Claude CLI versions. Default: deterministic smoke is
  blocking; product smoke starts as manual/quarantined.
- Whether failed cases should write detailed artifacts under `agent-out` only or
  also maintain committed example reports. Default: runtime reports go to
  `agent-out`; committed fixtures hold expected outputs only.
- Whether Plan 05 Sprint 5 should require all Sprint 1-4 skills to pass or only
  a representative subset. Default: all Sprint 1-4 skills need at least
  deterministic pass or explicit documented host-capability skip.
