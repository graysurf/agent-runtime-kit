# sync-runtime-skills Refresh Entrypoint Discussion Source

- Status: ready for plan generation
- Date: 2026-05-24
- Source: GitHub issue
  [graysurf/agent-runtime-kit#82](https://github.com/graysurf/agent-runtime-kit/issues/82)
  — "Add sync-runtime-skills refresh entrypoint". The user filed the issue
  after noticing that newly merged skill source changes only reach live
  Codex/Claude sessions when the source checkout is pulled, the per-product
  build is re-rendered, and both runtime homes are reinstalled. Today
  `scripts/setup.sh` is geared toward first-time host bootstrap and there is
  no focused "refresh my runtime skills" entrypoint.
- Intended next step: feed this document into `create-plan-tracking-issue`
  so the work surfaces as a lightweight GitHub-backed tracker, then implement
  the script first and only add a thin skill wrapper if the script becomes
  stable and worth wrapping.

## Execution

- Recommended plan: docs/plans/2026-05-24-sync-runtime-skills/sync-runtime-skills-plan.md
- Recommended execution state: docs/plans/2026-05-24-sync-runtime-skills/sync-runtime-skills-execution-state.md

## Purpose

A skill author who merges a new skill into `main` today has to run a manual
sequence before any live Codex / Claude session picks it up:

1. `git pull --ff-only` inside the active `agent-runtime-kit` checkout.
2. `agent-runtime render --product codex` and
   `agent-runtime render --product claude` to rebuild `build/<product>/`.
3. `agent-runtime install --product codex --apply` and the same for
   `claude` to reconcile `~/.codex` / `~/.claude` from the rendered build.
4. `agent-runtime doctor --product <p> --class skill-surface` per product
   to confirm runtime shape.
5. Optionally `codex debug prompt-input` to confirm live Codex discovery
   for prompt-mode skills.

`scripts/setup.sh` covers superset of this but also installs Homebrew /
nils-cli / the cli-tools profile and walks through profile selection — it
is not a daily-use sync command. The current gap is that "I just added a
skill, please make it visible" has no first-class entrypoint and is easy
to do wrong (skip render, install only one product, forget the doctor
check).

## Confirmed Facts

- [U1] User filed issue #82 asking for a daily-use `sync-runtime-skills`
  entrypoint distinct from `scripts/setup.sh`. The issue text already
  enumerates desired behavior (`git pull --ff-only` unless disabled,
  render both products, install both products, doctor both products, and
  optional codex `prompt-input` verification).
- [U2] User wants the script first and a thin skill wrapper only if the
  script becomes stable and easy to validate. Core install logic must
  stay in shell/CLI so it remains idempotent, testable, and usable
  outside an agent session.
- [U3] User explicitly listed dry-run-first operation and safe defaults
  as requirements in issue #82.
- [F1] `scripts/setup.sh` calls `agent-runtime install --product <p>`
  inside `activate_products` (scripts/setup.sh:342-359) and
  `agent-runtime doctor --product <p>` inside `run_doctor`
  (scripts/setup.sh:362-401), but does **not** invoke
  `agent-runtime render` — it assumes a pre-rendered `build/<product>/`
  is present in the source root.
- [F2] `agent-runtime install` requires explicit `--source-root`,
  `--product`, `--live-home`, `--state-home`, and `--apply` flags;
  `--live-home` rejects relative paths so a refresh script must resolve
  absolute runtime homes before calling the binary.
- [F3] `agent-runtime doctor --class skill-surface` is the dedicated
  doctor class for verifying rendered skill shape against a product's
  runtime home; it exposes the standard `checks / ok / warn / block /
  findings / acceptance_boundary / exit_code` envelope so a refresh
  script can assert `block=0` with the same parser pattern used by
  `scripts/ci/all.sh`.
- [F4] `agent-runtime render` rebuilds `build/<product>/` from `core/`
  and `targets/<product>/`. It does not touch runtime homes.
- [F5] `docs/source/inventory-target-architecture.md` defines the
  source → render → install pipeline. Any "refresh" command must walk
  the same pipeline in order; skipping render means installing a stale
  build tree.
- [F6] The recently-landed conversation prompt-mode skills (PR #81,
  merged 2026-05-24) were verified live with `codex debug prompt-input`
  and `agent-runtime doctor --product claude --class skill-surface`
  after manual install. Issue #82's evidence section confirms both
  probes worked; the user wants those probes to become the default
  verification step of the new entrypoint.
- [I1] Because `setup.sh` does not run `render`, today a contributor who
  edits `core/` and then runs `setup.sh` installs the previous build
  tree silently. A daily-use refresh entrypoint must always render
  before install or skip install entirely; running only `install` after
  a `core/` edit ships stale content to runtime homes.
- [I2] Skill discovery verification differs by product: Codex exposes
  `codex debug prompt-input` for prompt-mode probes, while Claude
  surfaces are best verified via `agent-runtime doctor --product claude
  --class skill-surface`. The script must run both, treating absence
  of `codex` on `PATH` as `skip-with-note`, not as failure.

## Decisions

- [D1] **Script-first, skill-later**: ship `scripts/sync-runtime-skills.sh`
  as the source of truth. Only add a thin `meta:sync-runtime-skills`
  skill wrapper after the script has been exercised against at least
  one real skill-add cycle and the user accepts the workflow.
- [D2] **Default to dry-run**: like `agent-runtime install`, the script
  prints the resolved plan unless `--apply` is passed. `--apply`
  performs writes. Mirrors the existing `setup.sh` `DRY_RUN`
  convention.
- [D3] **Pull is opt-out, not opt-in**: the script runs
  `git pull --ff-only` against the active checkout by default. A
  `--no-pull` flag exists for offline / detached-head workflows. If
  pull fails (non-ff, dirty tree, detached HEAD), the script stops
  before render and surfaces the git error verbatim.
- [D4] **Render runs unconditionally before install**: closes [I1]. No
  `--skip-render` flag in v1; if a future caller needs to bypass
  render, they can call `agent-runtime install` directly.
- [D5] **Verification is the default tail**: after install, the script
  runs `agent-runtime doctor --product <p> --class skill-surface` for
  both products and asserts `block=0`. If `codex` is on `PATH`, it
  also runs `codex debug prompt-input` and prints the output.
- [D6] **Both products in one invocation**: the script handles both
  `codex` and `claude` in a single run. A `--product <p>` flag exists
  for "I only touched the Claude target" workflows but is not
  default.
- [D7] **No new manifest entries in v1**: the script stays in
  `scripts/`, does not need a `manifests/skills.yaml` entry, and is
  not rendered into either product runtime home. If we promote it to
  a skill later (per [D1]), the manifest entry lands then.

## Scope

- A new `scripts/sync-runtime-skills.sh` that:
  - resolves the active checkout via `REPO_HOME_DEFAULT` (same pattern
    as `scripts/setup.sh`);
  - runs `git pull --ff-only` unless `--no-pull` is passed;
  - runs `agent-runtime render --product <p>` for each selected
    product;
  - runs `agent-runtime install --product <p> --apply` for each
    selected product, with `--dry-run` when the script is in default
    dry-run mode;
  - runs `agent-runtime doctor --product <p> --class skill-surface`
    for each selected product;
  - if `command -v codex` succeeds, runs `codex debug prompt-input`
    and prints the result.
- Flags: `--apply`, `--product <codex|claude|both>` (default `both`),
  `--no-pull`, `--no-verify` (skip the doctor + codex probes; for
  fast iteration only), `-h|--help`.
- A short `DEVELOPMENT.md` section pointing skill authors at the new
  entrypoint for "I just merged a skill, refresh my runtime."

## Non-Scope

- A skill wrapper. Defer per [D1].
- Changes to `scripts/setup.sh` beyond a cross-reference comment. The
  bootstrap path keeps its current shape.
- Changes to `agent-runtime install`, `render`, or `doctor` surfaces.
  The new script composes them, it does not modify them.
- Automatic resolution of `--live-home` / `--state-home` from
  arbitrary environments. The script defers to the same
  `product_live_home` / `product_state_home` resolution pattern
  `setup.sh` uses today.
- A CI gate that asserts skill-discovery on every PR. That belongs in
  the existing runtime-smoke / skill-surface doctor / audit-drift
  positions.
- Auto-bumping nils-cli or any third-party CLI version. Out of scope;
  use `sympoies/nils-cli#462` (Step 2 of the version-alignment plan)
  for that workflow.

## Implementation Boundaries

- Script-owned: argument parsing, dry-run gating, pull invocation,
  per-product orchestration, doctor exit-code aggregation, codex
  prompt-input invocation when available.
- Upstream-owned: actual render/install/doctor logic stays in
  `agent-runtime` (nils-cli). The script never reimplements link
  reconciliation or doctor probes.
- Project-owned: a tiny `DEVELOPMENT.md` cross-reference; a single
  pointer from `scripts/setup.sh`'s help text so a new contributor
  can find the daily-use entrypoint from the bootstrap one.
- Agent-owned: nothing in v1. The script must be runnable without
  an agent session.

## Requirements

### Script behaviour

- Lives at `scripts/sync-runtime-skills.sh`, is `chmod +x`, and
  follows the bash 3.2 + `set -euo pipefail` baseline used in
  `scripts/setup.sh`.
- Reuses the same `log` / `err` / `run_cmd` / `print_cmd` helper
  shape as `setup.sh` (copy or factor into a shared helper file
  during execution — execution-side decision).
- `REPO_HOME_DEFAULT` resolves to the script's own
  `git rev-parse --show-toplevel` output by default; an explicit
  `--source-root <path>` flag overrides it.
- Each step prints its banner, the resolved command, and exits
  non-zero on any sub-command failure unless explicitly opted out.
- Default invocation `bash scripts/sync-runtime-skills.sh` runs
  dry-run for both products and reports what would happen without
  mutating anything.
- `bash scripts/sync-runtime-skills.sh --apply` performs writes for
  both products.

### Verification step

- After `--apply`, the script always runs
  `agent-runtime doctor --product <p> --class skill-surface` for
  each installed product unless `--no-verify` is passed.
- If `command -v codex` returns 0, the script also runs
  `codex debug prompt-input` and prints the output. Absence of
  `codex` does **not** fail the run; the script logs
  `codex prompt-input skipped (binary not on PATH)`.
- Doctor failure (non-zero exit, or parsed JSON with `block>0`)
  fails the whole run with a non-zero exit and a clear remediation
  line ("run `agent-runtime doctor --product <p> --class
  skill-surface --format json` for details").

### Documentation

- `DEVELOPMENT.md` gains a short subsection under the existing
  "Refreshing the runtime layer" guidance (or equivalent) that
  cross-references `scripts/sync-runtime-skills.sh` as the daily
  entrypoint and `scripts/setup.sh` as the host bootstrap.
- `scripts/setup.sh --help` output gains a one-line
  "For daily skill refreshes, see `scripts/sync-runtime-skills.sh`"
  pointer (the help text only; no behavioural change).

## Acceptance Criteria

- **Script lands when**:
  - `bash scripts/sync-runtime-skills.sh` (default, no flags)
    prints the planned actions without mutating either runtime
    home and exits 0.
  - `bash scripts/sync-runtime-skills.sh --apply` pulls,
    renders, installs, and verifies both products end-to-end on
    a clean host; both doctor probes report `block=0`.
  - `bash scripts/sync-runtime-skills.sh --apply --product
    claude` only touches the Claude runtime home.
  - `bash scripts/sync-runtime-skills.sh --no-pull` skips
    `git pull` and proceeds against the current checkout.
  - `bash scripts/sync-runtime-skills.sh --apply` exits non-zero
    when `agent-runtime doctor --class skill-surface` would
    fail for either product (verified with a worktree experiment
    that perturbs a rendered target).
- **Documentation lands when**:
  - `DEVELOPMENT.md` cross-reference is present and links to the
    new script;
  - `scripts/setup.sh --help` carries the one-line pointer.
- **Audit gates remain green**: `scripts/ci/all.sh` stays green
  after the script lands. No new `audit-drift` findings; no new
  `runtime-smoke` failures.

## Validation Plan

- Author-side dry-run: `bash scripts/sync-runtime-skills.sh` on a
  clean working tree. Confirm no writes to `~/.codex` / `~/.claude`
  and exit 0.
- Author-side apply: `bash scripts/sync-runtime-skills.sh --apply`
  on the same host. Confirm both `agent-runtime install --apply`
  steps run and both doctor probes report `block=0`. If `codex` is
  available, confirm `codex debug prompt-input` output is printed
  and the run exits 0.
- Deliberate-failure experiment: perturb a rendered target file
  under `build/claude/` in a worktree, run the script with
  `--apply --product claude`, expect the post-install doctor probe
  to fail and the script to exit non-zero with a remediation line;
  restore the file.
- Pull-failure experiment: stash an unrelated change in the working
  tree to force `git pull --ff-only` to refuse; run the script and
  confirm it stops before render with the git error visible.
- Full CI run: `bash scripts/ci/all.sh` on the branch that adds the
  script; expect all positions green.

## Risks And Guardrails

- **Risk**: A future contributor reads only the new script and skips
  `scripts/setup.sh`, missing the cli-tools profile install.
  **Guard**: the new script's help text explicitly states "for
  first-time host setup, run `scripts/setup.sh` first."
- **Risk**: Render runs unconditionally and silently rebuilds
  `build/<product>/` in a way that surprises a contributor mid-edit.
  **Guard**: the dry-run default surfaces the render command before
  any mutation; `--apply` is opt-in.
- **Risk**: `git pull --ff-only` rewrites local commits that the
  contributor has not pushed.
  **Guard**: `--ff-only` refuses non-fast-forward merges; the script
  surfaces the git refusal and stops. `--no-pull` exists for the
  detached-head / offline case.
- **Risk**: Skill wrapper drift — the script grows skill-shaped
  logic that should have gone in a skill instead.
  **Guard**: [D1] sequencing — wrapper lands later if at all; until
  then, agent flow that needs the refresh just calls the script.
- **Risk**: Codex prompt-input probe absent on Claude-only hosts.
  **Guard**: [D5] — absence of `codex` on `PATH` is a `skip-with-note`,
  not a failure.

## Retention Intent

- Coordination artifact. This document and its sibling plan /
  execution-state files are cleanup-eligible after the script and
  the `DEVELOPMENT.md` cross-reference land per
  `docs/source/docs-placement-retention-policy-v1.md`
  (`docs/plans/` row).
- If a skill wrapper materializes later, open a follow-up plan
  bundle for that work rather than re-opening this one.

## Open Questions

- [Q1] Should the script also touch `.private/link-map.overrides.yaml`
  when present? The existing `setup.sh` leaves overlay handling to
  `agent-runtime install`; this script should likely do the same,
  but worth re-checking during execution.
- [Q2] Should `--apply` automatically run
  `agent-runtime audit-drift` as a tail probe, or leave that to
  CI? Argument for: catches manifest drift that survives render.
  Argument against: lengthens the daily loop and overlaps with
  `scripts/ci/all.sh`.
- [Q3] Should a `--product codex,claude` (comma list) form exist
  alongside `--product both`? Useful for future product additions;
  not needed today.
- [Q4] Should the script log a one-line summary at the end
  ("synced skills for codex+claude; doctor=ok; codex prompt-input
  verified") for easy grep, or stay minimal? Lean toward a single
  summary line.

## Read First References

- `scripts/setup.sh` — established helper shape (`log`, `err`,
  `run_cmd`, `print_cmd`, `DRY_RUN` gating); the new script reuses
  the same structure.
- `docs/source/inventory-target-architecture.md` — source → render
  → install pipeline that the new entrypoint walks end-to-end.
- `manifests/runtime-roots.yaml` — canonical resolution of
  `live_home` / `state_home` per product; the script must defer to
  this instead of hard-coding paths.
- `docs/plans/2026-05-24-nils-cli-version-alignment/nils-cli-version-alignment-plan.md`
  — sibling tracker that lands `bash scripts/ci/all.sh` Position 2;
  this script will be exercised under the same CI gate.
- `docs/source/nils-cli-surface.md` — current `agent-runtime`
  surface; informs the install / doctor flags the script invokes.
- Issue [#82](https://github.com/graysurf/agent-runtime-kit/issues/82)
  — original user-filed request; the verbatim "Desired Outcome"
  section anchors this plan's scope.

## Recommended Next Artifact

- `create-plan-tracking-issue` against this bundle → produces a
  lightweight GitHub-backed tracker keyed off this source plus
  the sibling `-plan.md` and `-execution-state.md` files. The
  tracker closes when the script and the `DEVELOPMENT.md`
  cross-reference land on `main` and the script passes the
  author-side validation experiments above.
