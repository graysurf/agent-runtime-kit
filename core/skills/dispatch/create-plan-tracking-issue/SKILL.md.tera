---
name: create-plan-tracking-issue
description:
  Create or preview a provider tracking issue for a plan bundle through released plan-issue and plan-tooling primitives.
---

# Create Plan Tracking Issue

## Contract

Prereqs:

- `plan-tooling`, `plan-issue`, and `plan-issue-local` are installed from the
  released nils-cli package and available on `PATH`.
- Run from the target git repository root unless an explicit repository or plan
  path is supplied.
- Existing plan bundles have a valid `Read First` section and a committed
  primary source artifact, URL source, or explicit plan-only waiver.
- Live provider issue creation uses `plan-issue`; local previews and fixture
  rehearsals use `plan-issue-local` or `plan-issue --dry-run`.

Inputs:

- Plan markdown path.
- Optional repository override, title, labels, task owner prefix, branch prefix,
  worktree prefix, PR grouping mode, and task-to-PR group mapping.
- Optional output paths for rendered issue body and task-spec TSV.

Outputs:

- A validated plan issue body and task decomposition table.
- A live provider issue when live mode is selected, or deterministic artifacts
  when `--dry-run` / local mode is selected.
- Source and plan snapshot comments when the workflow is creating an
  issue-backed execution surface.

Failure modes:

- Plan validation fails, the primary source is uncommitted, or grouping metadata
  conflicts with requested PR grouping flags.
- Provider auth or repository resolution fails in live mode.
- The issue body or task-spec artifact cannot be written.

## Entrypoint

Validate the bundle before provider mutation:

```bash
plan-tooling validate --file "$PLAN" --format text --explain
```

Preview local task decomposition without provider writes:

```bash
plan-issue-local build-plan-task-spec \
  --plan "$PLAN" \
  --strategy auto \
  --format json
```

Create or dry-run the plan issue:

```bash
plan-issue start-plan \
  --plan "$PLAN" \
  --repo "$OWNER_REPO" \
  --strategy auto \
  --format json
```

Add `--dry-run --issue-body-out <path> --task-spec-out <path>` before using a
new repository, title, label set, or grouping policy live.

## Workflow

1. Resolve the plan path and run `plan-tooling validate`.
2. Use `plan-issue-local build-plan-task-spec` for local review of ownership,
   branches, worktrees, execution modes, and PR groups.
3. Use `plan-issue start-plan --dry-run` to render the provider issue body.
4. Confirm live prerequisites: provider auth, committed local source/plan files,
   intended repository, title, labels, and grouping behavior.
5. Run `plan-issue start-plan` live only after the rendered body and task-spec
   are acceptable.
6. Record the issue URL, snapshot comment URLs, task-spec path, and any
   grouping overrides in the handoff or execution state.

## Boundary

`plan-tooling` owns plan validation and plan parsing. `plan-issue` /
`plan-issue-local` own task decomposition, provider issue rendering, and live
issue creation. The skill body owns source/plan readiness judgment, provider
selection, and whether to remain in dry-run mode.
