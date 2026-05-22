# Agent Runtime Kit Inventory And Target Architecture

Date: 2026-05-20
Status: source document for the first implementation discussion

## Revisions

- 2026-05-20 (initial) — seed inventory + target architecture.
- 2026-05-20 (expansion pass) — expanded Claude surface inventory; added
  schema versioning, cross-product domain mapping, skill naming collision
  policy, cross-OS portability, project-local extensibility, hook
  portability, build/render determinism, managed-block contract, uninstall
  behaviour, backup retention, doctor checks, Secrets And Sensitive Data,
  Testing And Validation, Heuristic System placement; promoted
  decision-blocking items out of Open Questions.
- 2026-05-20 (decisions pass) — template engine fixed as **Jinja2**; CLI
  binary named **`arkit`** (subcommand-style); `agent-runtime-kit`
  **replaces** both `agent-kit` and `claude-kit`; hook model fixed as
  **core logic + product adapter**; `$AGENT_HOME` removed entirely from
  the target architecture — Codex render uses native Codex env vars
  (`$CODEX_HOME`, `$CODEX_AGENT_STATE_HOME`) only.
- 2026-05-20 (nils-cli pass) — `nils-cli`
  (`github.com/sympoies/nils-cli`) recorded as **upstream** capability
  layer; new [CLI Boundary](#cli-boundary-nils-cli-owns-the-cli-surface)
  section defines the ownership split; `required_clis` field added to
  `skills.yaml`; state paths default to runtime allocation via
  `agent-out`; doctor checks coverage of nils-cli binaries against
  per-skill semver floors; Phase 4 migration plan re-keyed by nils-cli
  binary mapping; GitHub Repositories section expanded with the
  dual-repo maintenance workflow and cross-repo discipline rules.
- 2026-05-20 (arkit-drop + install-channels pass) — **arkit removed**;
  orchestration CLI moves into nils-cli as the new
  `crates/agent-runtime-cli/` crate producing the `agent-runtime` binary.
  Template engine switches from **Jinja2 → Tera** (Rust, jinja2-compatible
  syntax). `sympoies/homebrew-tap` added to GitHub Repositories as the
  release-time distribution channel. New
  [Install Channels](#install-channels) section formalises the brew-first
  bootstrap, Linuxbrew compatibility, and fallback ladder (cargo install
  → release tarball → source build). `core/policies/cli-tools.md` and
  `manifests/cli-tools.yaml` added to absorb the agent-kit `CLI_TOOLS.md`
  catalog. agent-runtime-kit is now pure content (no `bin/`); host
  bootstrap lives under `scripts/setup.sh`. Migration phases and
  Next Session Checklist re-sequenced around opening
  `agent-runtime-cli` first.
- 2026-05-20 (B-group decisions) — Resolved Decisions extended to
  **#7 product version floor** (`min_version` + `version_probe` per
  product in `runtime-roots.yaml`; latest-stable pinning, no
  back-compat window) and **#8 skill testing strength** (render golden
  + drift fixtures in Phase 1–2; sandbox install rehearsal added in
  Phase 3 as the new CI gate 6). Open Questions trimmed of resolved
  items (`agent-out --state-home` superseded by arkit-drop;
  product-version minimum now pinned).
- 2026-05-20 (specialist-review fixes pass) — folded in findings from a
  multi-lens design review: collapsed all `graysurf/nils-cli` references
  back to `sympoies/nils-cli` (single canonical repo); rewrote the local
  tap recipe to use a `brew --prefix` Taps symlink instead of the
  non-existent `brew tap --custom-remote`; switched render-golden CI gate
  to `agent-runtime render --update-golden` so the subcommand list stays
  closed; collapsed `gc-backups` to a single dedicated subcommand (no
  install flag form); added `schema_version: 1` to the `runtime-roots.yaml`
  example so it matches the mandatory rule; dropped the fictional umbrella
  `nils-cli --version` probe and described per-binary probing only;
  rebased Claude `state_home` XDG fallback onto `agent-runtime-kit/claude`
  while keeping `CLAUDE_KIT_STATE_HOME` for env-var back-compat (plus a
  migration note); promoted `meta` to Phase 4 position #2 so downstream
  domains migrate against the new `agent-docs` / `semantic-commit` /
  `agent-out` skill bodies; added a callout that `.codex-plugin/plugin.json`
  is an agent-kit-inherited local convention rather than a Codex upstream
  contract; inserted explicit Phase 1.5 covering the nils-cli render /
  audit-drift implementation that must ship before Phase 2 can start.
  Deferred to a future pass: heuristic directory rename, unsafe-drift
  noise control, install-flag de-bloat, em-dash anchor risk,
  `AGENT_RUNTIME_HOST_PROFILE` callout, `.private/` merge semantics, and
  the three red-team threads (render determinism vs Tera context order,
  Codex adapter symmetry over-spec, latest-stable no-back-compat
  developer-pain).
- 2026-05-20 (specialist-review batch 1) — document-only alignment pass:
  collapsed the lingering `<state_home>/heuristic/...` paths back to
  `<state_home>/heuristic-system/...` so state, policy, and skill driver
  directories all share one name (M2); replaced every `">=0.X"`
  placeholder in the `required_clis` examples with
  `"<TBD: pin during Phase 1>"` and added a Manifest Layer note that any
  surviving `<TBD>` is a Phase 1 gate failure (L1); renamed
  `## CLI Boundary — nils-cli Owns The CLI Surface` to `:`-separated form
  to stabilise the GitHub anchor and updated all six cross-references
  (L3); added a Host profile env var callout in Cross-OS / Multi-Machine
  Portability declaring `AGENT_RUNTIME_HOST_PROFILE` as a new design-owned
  variable, its fallback rule, and doctor reporting expectation (L4).
  Still deferred: M4 unsafe-drift scoring, L2 install-flag de-bloat,
  L5 overlay merge semantics, and the three red-team threads.
- 2026-05-20 (specialist-review batch 2) — spec-depth pass:
  rewrote Drift Detection with a composite `unsafe` score
  (path / keyword / entropy at 0.4 each; block ≥ 0.8, warn at single
  signal, suppressed below) plus a tracked `drift-audit.allow.yaml`
  allowlist that demotes findings by exactly one tier (M4); split
  `install --restore-backups` / `--purge-state` into dedicated
  `restore-backups` / `purge-state` subcommands with required scope
  args and confirmation rules, updated the Phase 1 stub list and
  Decision #2 subcommand enumeration (L2); added §Overlay Merge
  Semantics defining per-product deep merge for `.private/runtime-roots.yaml`,
  per-entry replace for `.private/link-map.overrides.yaml`, and
  union/replace rules for `profile.recommended.yaml`, plus the
  contract that `agent-runtime install --dry-run` MUST print the
  post-merge effective config (L5); promoted render-output
  determinism to Resolved Decision #9 with the
  `IndexMap`/`BTreeMap`-only context, no-wall-clock rule (only
  commit-derived `%cI HEAD`), clippy-enforced lints, and the
  cross-process determinism test (Red-team #1). Still deferred:
  Codex reality check (Red-team #2) and `min_version` Bump Ceremony
  (Red-team #3).
- 2026-05-20 (specialist-review consistency sweep) — follow-up after
  batches 1-3: Next Session Checklist item 5 subcommand stub list now
  matches Resolved Decision #2 / Phase 1 (adds `restore-backups`,
  `purge-state`); Open Questions marketplace bullet narrowed to
  Claude-side only with a back-pointer to Decision #10; Doctor Checks
  render-determinism-canary bullet cross-references Decision #9 so
  the canary's relationship to the full guarantee is explicit.
- 2026-05-20 (specialist-review batch 3) — reality + ceremony pass:
  hardened the Codex / Claude adapter asymmetry into a dedicated
  §Codex Activation Surface (Reality Check) subsection enumerating
  what Codex actually loads (`AGENTS.md`, local skills, and the
  `config.toml` managed block) vs. what the directory tree merely organises for authoring
  (`.codex-plugin/plugin.json`, marketplace entries, plugin packaging);
  tagged the Codex-side bullets in §Product Adapter Layer with
  "local convention" / "local-only" markers; updated drift-detection
  bullets to clarify Codex `plugin.json` is validated against the
  local schema only; promoted the reality check to Resolved Decision
  #10 with implications for `audit-drift`, `install`, PR review, and
  Phase 4 scoping (Red-team #2). Layered a Bump Ceremony onto Decision
  #7: added `recommended_version` and `min_version_effective_from`
  fields to `runtime-roots.yaml`, rewrote the Doctor Checks version
  bullet to report `ok` / `recommended-only` / `warn` / `outdated`
  with effective-from gating, introduced `agent-runtime doctor
  --suggest-upgrade` for copy-pasteable upgrade commands, and shipped
  `.github/PULL_REQUEST_TEMPLATE/min-version-bump.md` as a reminder
  template for impacted-environment listing, tested combinations,
  rollback path, and team notice (Red-team #3). All M / L / Red-team
  findings from the original specialist review are now landed; no
  remaining deferred items.
- 2026-05-22 (home policy cutover pass) — clarified that the Codex home-scope
  policy source is the root `CODEX_AGENTS.md` file in this repo, not a rendered
  `AGENTS.md` source and not `$HOME/.agents`; `$CODEX_HOME/AGENTS.md` links
  directly to that file so Codex does not read duplicate `AGENTS.md` files when
  this repo is the active project. Home-scope `agent-docs` still pins its
  checked-out docs home explicitly until those runbooks migrate.
- 2026-05-23 (Codex skill discovery cutover pass) — updated the Codex reality
  check from prompt/config-only activation to the verified local skill root:
  runtime-kit skills are installed as domain-nested symlinked skill folders
  under `$CODEX_HOME/skills/<domain>/<skill>/` for Codex discovery, while
  `$CODEX_HOME/plugins` remains audit/compatibility metadata rather than a
  plugin loader. Do not expose individual `SKILL.md` file symlinks as the
  active Codex discovery surface.

## Purpose

Create one maintained source of truth for the local agent runtime layer that is
currently split between:

- `$HOME/.config/agent-kit`
- `$HOME/.config/claude`

The new repository should own shared skills, workflows, hooks, policy docs,
plugin metadata, install/link management, and drift detection. Codex and Claude
should become product targets rather than separate source repositories.

## Current State Inventory

### `agent-kit`

Path: `$HOME/.config/agent-kit`

Observed role:

- Current Codex-oriented source of truth.
- `$HOME/.agents` is a symlink to this repo.
- `$HOME/.codex/AGENTS.md` links to `$HOME/.agents/CODEX_AGENTS.md`.
- Codex hook source lives under `hooks/codex/`.
- Codex hook activation is managed by syncing a managed block into
  `$HOME/.codex/config.toml`, not by symlinking the full config file.
- Public skills use a multi-level layout under `skills/`, for example:
  `skills/workflows/...`, `skills/tools/...`, `skills/automation/...`.

Observed skill count:

- `77` unique `SKILL.md` directories under `$HOME/.config/agent-kit/skills`.

Important existing contract:

- Do not track or symlink the whole Codex `config.toml`.
- Preserve product-local runtime state such as auth, logs, history, cache,
  sessions, and generated runtime files outside the canonical source tree.

### `claude-kit`

Path: `$HOME/.config/claude`

Observed role:

- Current Claude Code extension repo.
- `install.sh` links tracked surfaces into `$HOME/.claude`.
- `scripts/_symlinks.env` is the canonical symlink list for Claude surfaces.
- Tracked surface families (each must be enumerated in the canonical link map):
  - `skills/<name>/SKILL.md` (user-global root skills, legacy layout).
  - `plugins/<domain>/skills/<skill>/SKILL.md` (Hybrid C plugin layout).
  - `agents/<name>.md` and `plugins/<domain>/agents/<name>.md`
    (subagent definitions invoked via the Agent tool).
  - `commands/<name>.md` and `plugins/<domain>/commands/<name>.md`
    (slash commands).
  - `hooks/` scripts plus the `hooks` block in `settings.json`
    (and per-plugin `plugins/<domain>/hooks/`).
  - `output-styles/<name>.md`.
  - `statusline` configuration via `settings.json`.
  - `.claude-plugin/plugin.json` per plugin.
  - `.claude-plugin/marketplace.json` (local marketplace).
- The Heuristic System lives under `HEURISTIC_SYSTEM.md` plus
  `heuristic-system/operation-records/` and `heuristic-system/error-inbox/`.
  It is currently claude-kit-local but topic-portable and is a candidate for
  `core/` ownership.
- Project-local overlay contract: many skills (`bench`, `demo`, `deploy`,
  `pre-pr`, `release`, `bootstrap`) dispatch to
  `<target-repo>/.agents/scripts/<name>.sh`. Each consuming repo owns the real
  implementation; claude-kit only ships the entry-point shim.

Observed skill count:

- `84` unique `SKILL.md` directories across `$HOME/.config/claude/plugins`
  and `$HOME/.config/claude/skills`.

Important existing contract:

- Claude has flatter runtime skill discovery than Codex.
- The Hybrid C plugin reorganization moved many skills from user-level
  `skills/` into plugin roots, but path references can still drift if scripts,
  tests, or docs assume legacy top-level skill locations.
- Current `claude-kit` working tree has unrelated local changes; migration work
  must inspect and preserve them rather than treating the tree as clean.

### `nils-cli`

Path: `~/Project/sympoies/nils-cli`. Repo: `github.com/sympoies/nils-cli`
(public, MIT). Installed via Homebrew onto `/opt/homebrew/bin` (macOS) /
`/home/linuxbrew/.linuxbrew/bin` (Linux).

Observed role:

- Rust workspace of focused CLI binaries that already crystallise many of the
  capabilities skills currently embed inline. This is the deliberate
  maintenance pattern going forward: heavy, deterministic logic lives here;
  agent-runtime-kit skills wrap and orchestrate it.
- Tracked binary surface today (non-exhaustive):
  - **Agent policy / evidence:** `agent-docs`, `agent-out`, `agent-scope-lock`,
    `heuristic-inbox`, `repo-retro`, `skill-usage`, `review-evidence`,
    `test-first-evidence`, `web-evidence`, `browser-session`, `canary-check`,
    `docs-impact`, `model-cross-check`.
  - **Planning and delivery:** `plan-tooling`, `plan-issue`,
    `plan-issue-local`, `semantic-commit`, `forge-cli` (PR/MR/Issue lifecycle
    on GitHub via `gh` and GitLab via `glab`, including the `pr deliver`
    macro).
  - **API testing:** `api-rest`, `api-gql`, `api-grpc`, `api-websocket`,
    `api-test`.
  - **Git tooling:** `git-cli`, `git-scope`, `git-summary`, `git-lock`.
  - **Provider lanes:** `codex-cli`, `gemini-cli`.
  - **Desktop / media / shell:** `macos-agent`, `screen-record`,
    `image-processing`, `fzf-cli`, `memo-cli`.
- Releases are tagged with semver; CI publishes Homebrew formulas. The
  agent-runtime-kit treats nils-cli as an external dependency with declared
  minimum versions per skill.
- `BINARY_DEPENDENCIES.md` in nils-cli already enumerates third-party
  binaries each crate calls (`gh`, `glab`, `git`, `fzf`, `grpcurl`, `ffmpeg`,
  `osascript`, etc.). Doctor in agent-runtime-kit defers to those
  declarations rather than re-checking what nils-cli already verifies.

Important existing contract:

- nils-cli's CLI contract is the durable surface. Skill bodies invoke these
  binaries; they do not re-implement the underlying logic.
- Many present-day skills in claude-kit / agent-kit duplicate logic that
  already exists as a nils-cli binary (`semantic-commit`, `agent-docs`,
  `agent-scope-lock`, `heuristic-error-inbox`, `api-test-runner`, `pr:*` →
  `forge-cli`, `dispatch:*` → `plan-issue` / `plan-tooling`,
  `macos-agent-ops` → `macos-agent`). Migration is largely the act of
  rewriting those skill bodies to call the CLI.

### GitHub Repositories

- `graysurf/agent-kit`: public, default branch `main`. **To be archived** once
  migration completes (see Phase 4); contents move to `agent-runtime-kit`.
- `graysurf/claude-kit`: private, default branch `main`. **To be archived**
  once migration completes; contents move to `agent-runtime-kit`.
- `graysurf/agent-runtime-kit`: private, default branch `main` (established
  by initial commit). The **sole content** repo (skills, plugin manifests,
  hooks, render templates, manifests, policies) after migration. Ships
  no standalone CLI binary; orchestration lives in nils-cli. A future
  split of public-portable assets back into a public face is left as a
  follow-up decision.
- `sympoies/nils-cli`: public, default branch `main`. Rust workspace
  hosting **every binary** the runtime kit needs — both the capability
  binaries (`agent-docs`, `agent-out`, `forge-cli`, `semantic-commit`,
  `plan-issue`, …) and the orchestration binary (`agent-runtime`, new
  crate `crates/agent-runtime-cli/`). Kept on its own release cadence.
  See [`nils-cli`](#nils-cli) above and
  [CLI Boundary](#cli-boundary-nils-cli-owns-the-cli-surface) for the
  ownership split.
- `sympoies/homebrew-tap`: public, default branch `main`. Distribution
  channel for nils-cli (and any other sympoies Rust binaries, e.g.
  `agent-workspace-launcher`). Touched at release time only — bumping
  formula version + tarball SHA after a nils-cli release. Not a daily
  development surface; see
  [Install Channels](#install-channels) for the install ladder.

#### Multi-Repo Maintenance Workflow

Day-to-day work is mostly two repos (agent-runtime-kit ↔ nils-cli);
homebrew-tap is the release destination on top. Treat the three as one
logical product:

| Doing | Repo | Why |
| --- | --- | --- |
| Writing or editing a skill body, plugin manifest template, hook source, render template, or product policy doc | `agent-runtime-kit` | Content surface |
| Adding or modifying a deterministic CLI behaviour, JSON contract, exit code, or any logic inside `agent-runtime` (render / install / doctor / audit-drift) or any capability binary | `sympoies/nils-cli` | All Rust binaries live here |
| Bumping a skill's declared `required_clis` floor after a nils-cli release | `agent-runtime-kit` | Manifest change only |
| Releasing a new nils-cli binary, subcommand, or flag first used by a new skill | nils-cli → tap → agent-runtime-kit | Land + tag nils-cli; bump formula in homebrew-tap; then add the skill calling it |
| Fixing a bug that started in a skill but root cause is in a nils-cli binary | nils-cli → tap → agent-runtime-kit | Patch + release nils-cli; bump formula; bump `required_clis` in agent-runtime-kit |
| Extracting embedded skill logic into a new nils-cli binary | nils-cli → tap → agent-runtime-kit | Implement + release in nils-cli; bump tap; rewrite the skill; log the move in `docs/source/extraction-backlog.md` |
| Updating brew formula version + tarball SHAs after a nils-cli release | `sympoies/homebrew-tap` | Release destination only |

Cross-repo discipline:

- **No silent forks.** If a skill in `agent-runtime-kit` needs a CLI flag
  that nils-cli does not yet expose, the change goes into nils-cli first.
  Skill bodies do not work around missing CLI behaviour with embedded shell
  or Python.
- **`required_clis` is the version contract.** When a nils-cli release
  breaks a flag a skill depends on, drift audit fails until the skill is
  rewritten or the floor is pinned to the pre-break version.
- **Issue and PR cross-linking.** A skill change that depends on a
  nils-cli change references the nils-cli PR / release tag in its
  description, and vice versa. Tap formula bumps reference the upstream
  nils-cli release tag.
- **Local development setup.** Contributors typically clone all three
  repos side-by-side under `~/Project/`. `agent-runtime doctor` accepts
  `--nils-cli-source <path>` to point at a local nils-cli checkout when
  testing unreleased binaries.

#### Local nils-cli Development Loop

Active agent-runtime-kit work often discovers missing nils-cli behavior.
That should not block content work on a release cycle. The local loop is:

1. Keep a fresh nils-cli checkout at `$HOME/Project/sympoies/nils-cli`.
   Start each coupled task from latest `main`:
   ```bash
   if [ ! -d "$HOME/Project/sympoies/nils-cli/.git" ]; then
     git clone https://github.com/sympoies/nils-cli \
       "$HOME/Project/sympoies/nils-cli"
   fi
   git -C "$HOME/Project/sympoies/nils-cli" fetch origin
   git -C "$HOME/Project/sympoies/nils-cli" switch main
   git -C "$HOME/Project/sympoies/nils-cli" pull --ff-only origin main
   ```
2. For task isolation, create nils-cli worktrees under
   `$HOME/Project/sympoies/nils-cli-worktrees/<topic>`, not inside the
   agent-runtime-kit repo, `build/`, or test fixture trees:
   ```bash
   TOPIC="agent-runtime-topic"
   mkdir -p "$HOME/Project/sympoies/nils-cli-worktrees"
   git -C "$HOME/Project/sympoies/nils-cli" worktree add \
     -b "$TOPIC" "$HOME/Project/sympoies/nils-cli-worktrees/$TOPIC" origin/main
   ```
3. Build debug binaries locally and invoke them by absolute path while
   editing agent-runtime-kit:
   ```bash
   cargo build -p agent-runtime-cli \
     --manifest-path "$HOME/Project/sympoies/nils-cli/Cargo.toml"

   AGENT_RUNTIME="$HOME/Project/sympoies/nils-cli/target/debug/agent-runtime"
   "$AGENT_RUNTIME" render --product codex
   "$AGENT_RUNTIME" render --product claude
   "$AGENT_RUNTIME" audit-drift
   ```
   If a full repo gate needs the unreleased binary, put `target/debug`
   first only for that shell command:
   ```bash
   PATH="$HOME/Project/sympoies/nils-cli/target/debug:$PATH" \
     bash scripts/ci/all.sh
   ```
4. Do not overwrite the Homebrew-installed `agent-runtime` during normal
   development. The brew binary represents the released consumer contract;
   debug binaries represent provisional nils-cli work.
5. When the agent-runtime-kit and nils-cli changes are both validated,
   land the nils-cli PR, cut the nils-cli release, bump the tap, then
   return to agent-runtime-kit to refresh `docs/source/nils-cli-surface.md`
   and bump any affected `required_clis` floors. Local debug validation is
   useful development evidence, but it is not a released version contract.

For end-to-end install rehearsal against a local tap checkout, symlink the
working tree into Homebrew's taps directory:
  ```bash
  ln -s ~/Project/sympoies/homebrew-tap \
    "$(brew --prefix)/Library/Taps/sympoies/homebrew-tap"
  ```
  brew then resolves `brew install sympoies/tap/nils-cli` against the
  local checkout. Remove the symlink to fall back to the published tap.

## Target Architecture

The repository should be structured around one canonical source and explicit
product adapters:

```text
agent-runtime-kit/
  CODEX_AGENTS.md             # Codex home-scope policy, linked by ~/.codex/AGENTS.md
  core/                       # portable, product-independent source of truth
    policies/                 # commit/PR rules, agent-docs gates, heuristic system, secrets
    skills/<domain>/<skill>/  # skill bodies, assets, scripts
    hooks/                    # portable hook logic (activation lives in targets/)
    docs/                     # ADRs, schema specs, contributor guides
    scripts/                  # skill/policy helper shims, not orchestration CLI
  targets/                    # product adapter surfaces
    codex/
      AGENTS.md.template
      config.block.toml       # managed block synced into ~/.codex/config.toml
      plugins/<domain>/.codex-plugin/plugin.json
      hooks/                  # codex-specific activation wrappers
      link-map.yaml
    claude/
      CLAUDE.md.template
      AGENTS.md.template
      settings.json.template
      plugins/<domain>/.claude-plugin/plugin.json
      hooks/                  # claude-specific activation wrappers
      link-map.yaml
  manifests/                  # machine-checkable source of truth
    skills.yaml
    plugins.yaml
    product-capabilities.yaml
    runtime-roots.yaml
  build/                      # render output (gitignored, regenerated)
    codex/...
    claude/...
  scripts/                    # Bash host bootstrap and CI glue
    setup.sh                  # macOS + Linux unified bootstrap (OS detect)
    profile.recommended.yaml  # optional override of manifests/cli-tools.yaml
```

Note: there is **no** standalone CLI binary in this repo. The
orchestration commands (`render`, `install`, `uninstall`, `doctor`,
`audit-drift`, `gc-backups`) live in `nils-cli` as the `agent-runtime`
binary. See [CLI Boundary](#cli-boundary-nils-cli-owns-the-cli-surface).

### Core Layer

`core/` owns portable intent and implementation:

- `core/policies/` — portable policy docs (commit/PR rules, agent-docs gates,
  heuristic-system contract, secret boundaries, `cli-tools.md` — the
  human-readable catalog of third-party CLIs migrated from agent-kit's
  `CLI_TOOLS.md`). Per-product flavour text lives in target adapters.
- `core/skills/<domain>/<skill>/` — canonical skill bodies and assets.
- `core/hooks/` — portable hook logic. Hook activation contracts differ between
  products and live in target adapters; see Hook Portability below.
- `core/docs/` — architecture decisions (ADRs), schema specs, contributor
  guides, and policy explainers. Not product-facing runtime docs.
- `core/scripts/` — helpers consumed *inside* skills/policies (e.g. shared
  shell libs, template helpers). Distinct from top-level `scripts/`, which
  contains Bash host bootstrap and CI glue. The install/render/doctor/drift
  orchestration CLI lives in nils-cli.
- canonical domain grouping (see Manifest Layer for cross-product domain
  mapping).

The core layer should not contain runtime-home paths such as `~/.codex` or
`~/.claude` except in examples or adapter documentation. Render-time helpers
resolve product paths; runtime resolution is the adapter's job.

### Product Adapter Layer

`targets/codex/` owns Codex-specific activation:

- `$CODEX_HOME/AGENTS.md` link target policy. For the home-scope Codex prompt,
  this repo uses root `CODEX_AGENTS.md` as the source file and links
  `$CODEX_HOME/AGENTS.md` directly to it.
- `.codex-plugin/plugin.json` generation or storage
  *(local convention; not a Codex upstream contract — see
  [Codex Activation Surface](#codex-activation-surface-reality-check) below)*
- Codex plugin marketplace entries *(local-only; Codex has no published
  marketplace API)*
- managed hook block for `~/.codex/config.toml`
- Codex-specific skill root or plugin path rules

`targets/claude/` owns Claude-specific activation:

- `CLAUDE.md` / `AGENTS.md` rendering
- `.claude-plugin/plugin.json` generation or storage
- Claude marketplace entries
- `settings.json` hook registration
- flat skill adapters or plugin-root skill layout

Product adapters may contain wrappers or compatibility shims, but durable
workflow instructions should remain in `core/` whenever possible.

> **Codex / Claude plugin-format asymmetry.** `.claude-plugin/plugin.json`
> and the Claude marketplace are published upstream contracts. There is no
> equivalent upstream Codex plugin manifest spec today;
> `.codex-plugin/plugin.json`, Codex marketplace entries, and the Codex
> plugin layout in this design are conventions inherited from `agent-kit`
> and owned by this repo. Reviewers and implementers should treat the
> Codex side as a local schema we maintain (and may need to revise if
> Codex publishes an official plugin contract), not as a mirror of an
> existing upstream format.

### Codex Activation Surface (Reality Check)

The asymmetry callout above is important enough to spell out explicitly,
because the directory tree under `targets/codex/` and the parallel
bullets between the two products invite the assumption that Codex has a
matching loader for each Claude concept. It does not.

**What Codex actually reads at session start:**

- `~/.codex/AGENTS.md` — primary agent prompt. Read on every session
  start. Can be a symlink. The runtime kit uses root `CODEX_AGENTS.md`
  as this source.
- `~/.codex/skills/**/SKILL.md` — local skill discovery root observed from
  `codex debug prompt-input` in the May 2026 cutover environment. The
  generated prompt input lists `$HOME/.codex/skills` as a skill root, while
  `$HOME/.codex/plugins/<domain>/skills` is not listed as a runtime-kit
  discovery root.
- `~/.codex/config.toml` — TOML config with custom hooks declared
  inline. The runtime kit writes only into the
  `# >>> agent-runtime-kit:hooks >>>` managed block; everything outside
  is owned by the user.
- File reads relative to `$CODEX_HOME` invoked from inside hooks or from
  `AGENTS.md`-referenced scripts.

**What Codex does NOT have (no matter how much the directory tree
suggests otherwise):**

- A `.codex-plugin/plugin.json` loader. Codex never opens these files.
- A plugin marketplace API. There is no analogue of Claude's
  `marketplace.json` discovery / install protocol.
- A `settings.json`-equivalent hook registration. Hooks are TOML-only.
- Plugin-scoped skill discovery the way Claude's `${CLAUDE_PLUGIN_ROOT}`
  works. Codex local skills are exposed through `$CODEX_HOME/skills`, not by
  loading `$CODEX_HOME/plugins/<domain>/.codex-plugin/plugin.json`.

**Why the runtime kit still uses a `targets/codex/plugins/` layout:**

`targets/codex/plugins/<domain>/` and `.codex-plugin/plugin.json` are
purely a source-organisation convention so the same plugin abstraction
can describe both products on the authoring side. At render time,
`agent-runtime render` keeps deterministic plugin-organized build output, and
`agent-runtime install` exposes each active skill as a domain-nested symlinked
folder under `$CODEX_HOME/skills/<domain>/<skill>/`. The symlink target remains
the plugin-organized rendered folder under
`build/codex/plugins/<domain>/skills/<skill>/`. `.codex-plugin/plugin.json`
exists in `build/codex/` and `$CODEX_HOME/plugins/` for our own audit and
drift purposes only — Codex never opens it.

**Home-scope prompt source invariant:**

The checked-out source file for Codex's home-scope prompt is
`<source_root>/CODEX_AGENTS.md`. `$CODEX_HOME/AGENTS.md` may symlink directly
to it. Do not use `<source_root>/AGENTS.md` for this source because Codex also
loads project-local `AGENTS.md` files while developing this repository; using
the same filename for both surfaces would cause duplicate global/project policy
reads. Do not reintroduce `$HOME/.agents` as an indirection for this link.

**Implications for drift audit, install, and review:**

- `audit-drift` validates `.codex-plugin/plugin.json` only against the
  local schema in `core/docs/schemas/`. It does NOT compare against any
  upstream Codex registry, because none exists. A Codex `plugin.json`
  schema change is a local-only revision.
- `install` for Codex does not rely on plugin package loading. The active
  install plan is: expose rendered skills under `$CODEX_HOME/skills`, sync the
  managed hook block into `config.toml`, drop hook scripts under
  `$CODEX_HOME/hooks/<name>/`, and retain `$CODEX_HOME/plugins` metadata only
  for audit/compatibility.
- PR review must not flag "missing Codex marketplace entry" as a defect.
  There is no such thing to be missing.

If Codex eventually publishes an upstream plugin manifest spec,
Resolved Decision #10 will need to be revisited. Until then, the
contract above is the working assumption.

### Manifest Layer

`manifests/` should make the source of truth machine-checkable:

- `skills.yaml`: skill id, domain, source path, supported products, aliases,
  product-specific names, `required_clis` (per-binary nils-cli semver
  floors — see [CLI Boundary](#cli-boundary-nils-cli-owns-the-cli-surface)),
  `state_out_mode` (default `runtime`), portability notes, and per-product
  `path_override` (see Cross-Product Domain Mapping below).
- `plugins.yaml`: domain plugin metadata, contained skills, product manifests,
  dependencies, and install policy.
- `product-capabilities.yaml`: product differences such as nested skill support,
  plugin manifest schema, hooks model, config activation, runtime state
  boundaries, and the explicit field-level diff between
  `.codex-plugin/plugin.json` and `.claude-plugin/plugin.json`.
- `runtime-roots.yaml`: per-product root resolution (see Runtime Root Model).
- `cli-tools.yaml`: profile-keyed third-party CLI install list consumed by
  `scripts/setup.sh` and `agent-runtime doctor`. Mirrors the catalog in
  `core/policies/cli-tools.md`. Schema:
  ```yaml
  schema_version: 1
  profiles:
    core: [ripgrep, fd, fzf, jq, yq, gh, bat]
    recommended: [<core> + glow, delta, ast-grep, watchexec, ...]
    full: [<recommended> + imagemagick, vips, playwright, ...]
  formulas:
    ripgrep:
      brew: ripgrep
      command: rg
      linux_only_alternative: null
      categories: [search]
    # ...
  ```

Every manifest file MUST carry a `schema_version: <int>` at the top. Drift
audit reads this to choose the validator. A manifest without `schema_version`
is treated as invalid.

#### Skill ID Convention

- Canonical ID is `<domain>.<skill>` (dot-separated, lowercase, hyphenated).
  This form is used in `skills.yaml`, `{{ skill_ref(...) }}` source helpers,
  and CLI output.
- Product render may map this to product-native invocation syntax. Claude's
  plugin-scoped slash invocation produces `<domain>:<skill>` (colon), which is
  a render-time presentation choice, not an inconsistency. The dot remains the
  source-of-truth ID.

#### Cross-Product Domain Mapping

Some skills already exist under different domain roots in each product
(`reporting` in source vs. `tools/market-research/<x>` in Codex). To preserve
existing runtime invocation while letting source group them sanely, each skill
may declare:

```yaml
- id: reporting.topic-radar
  domain: reporting
  products:
    codex:
      path_override: skills/tools/market-research/topic-radar
    claude:
      path_override: plugins/reporting/skills/topic-radar
```

`path_override` is rendered under the product's `command_root`. Drift audit
checks `path_override` against the product's live layout.

#### Skill Naming Collision Policy

Codex (77 skills) and Claude (84 skills) have overlapping and divergent
inventories. The policy:

1. **Identical name + identical behaviour** → single canonical source under
   `core/skills/<domain>/<skill>/`, both products render from it.
2. **Identical name + divergent behaviour** → keep the name, declare
   `divergent: true` in `skills.yaml`, and source must split into
   `core/skills/<domain>/<skill>/{shared,codex,claude}/` with adapter-specific
   bodies. Drift audit warns on every divergent entry.
3. **Only one product supports it** → declare `products: [claude]` (or
   `[codex]`). Adapter for the unsupported product emits nothing; audit does
   not flag this as missing.
4. **Same behaviour, different product-native names** → use `aliases:` map.
   Canonical ID is still `<domain>.<skill>`; the alias is for invocation
   surface only.

The manifest layer is the right place to record intentional Codex/Claude
differences so they do not become undocumented drift.

### Runtime Root Model

There is no portable "agent home" concept in this project. Each product uses
its own native runtime root, and the source checkout sits in its own
location independent of either product. The migration explicitly drops
`AGENT_HOME` / `$HOME/.agents`: any reference to them in legacy `agent-kit`
content is rewritten to product-native paths during render.
The Codex home prompt is the deliberate source-link exception:
`$CODEX_HOME/AGENTS.md` links directly to `<source_root>/CODEX_AGENTS.md` so the
source filename stays distinct from project-local `AGENTS.md`.

| Root | Meaning | Codex value | Claude value | Target rule |
| --- | --- | --- | --- | --- |
| `source_root` | Versioned source checkout | `$HOME/.config/agent-runtime-kit` | `$HOME/.config/agent-runtime-kit` | Single canonical source; both products are downstream render targets. |
| `live_home` | Product runtime home loaded by the agent product | `$CODEX_HOME` (default `$HOME/.codex`) | `$HOME/.claude` | Only approved rendered files, symlinks, or managed config blocks may be installed here. |
| `docs_home` | Home-scope `agent-docs` policy root | `$CODEX_HOME` (so `$HOME/.codex`) | `$HOME/.claude` | Always render explicit `agent-docs --docs-home <path>` per product. Do not rely on ambient `AGENT_DOCS_HOME`. |
| `state_home` | Writable runtime state, temporary output, local evidence, and backups | `${CODEX_AGENT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/codex}` | `${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude}` | Product adapter chooses the default. Core workflows receive it as a parameter or rendered variable. |
| `plugin_root` | Installed plugin package root, when the product supports plugin-scoped execution | `$CODEX_HOME/plugins/<domain>` (no dedicated env var assumed) | `$CLAUDE_PLUGIN_ROOT` | Core skills must not assume a plugin root. Product adapters render plugin-root-relative commands. |

The Claude `state_home` keeps the legacy env var name `CLAUDE_KIT_STATE_HOME`
for back-compat with existing shell config, hooks, and skill bodies, but the
XDG fallback path is rebased onto the new repo namespace
(`agent-runtime-kit/claude`) so both products share one parent directory
under `$XDG_STATE_HOME`. Migration tooling moves any pre-existing
`$XDG_STATE_HOME/claude-kit/` tree into the new path; users with
`CLAUDE_KIT_STATE_HOME` explicitly exported are unaffected.

`AGENT_DOCS_HOME` is rejected as a target-level default because it can leak
from the shell and select the wrong home policy. Prefer explicit
`--docs-home` in rendered policy, hooks, runbooks, and examples.

`AGENT_HOME` is **not** in the target architecture at all. The Codex render
emits `$CODEX_HOME`-relative or `$CODEX_AGENT_STATE_HOME`-relative paths,
never `$AGENT_HOME`. Drift audit treats any rendered `$AGENT_HOME` reference
as an error.

#### Cross-OS / Multi-Machine Portability

`runtime-roots.yaml` carries per-host overrides because default `live_home`,
`state_home`, and `docs_home` vary by OS (Linux contributors, CI runners,
remote dev boxes). Resolution order for any root:

1. CLI flag (`--state-home`, `--docs-home`).
2. Product-specific env var (`CLAUDE_KIT_STATE_HOME`, `CODEX_AGENT_STATE_HOME`).
3. Per-host block in `runtime-roots.yaml` matched by `uname -s` /
   `$AGENT_RUNTIME_HOST_PROFILE`.
4. Cross-OS default (XDG on Linux/BSD, `~/Library/Application Support` on macOS
   only if the product expects it, otherwise XDG paths still apply because the
   user's setup runs XDG on macOS too).

> **Host profile env var.** `AGENT_RUNTIME_HOST_PROFILE` is a new env var
> introduced by this design (no upstream provider). When set, its value
> selects the matching block in `runtime-roots.yaml`; when unset, the
> installer falls back to `uname -s` (`Darwin` / `Linux`, or `WSL`
> synthesized when `/proc/version` matches Microsoft's marker). Recommended
> setup is to export it from the host's shell profile when one user
> maintains multiple machine archetypes (laptop / corp box / remote dev
> box / CI runner) with divergent paths or override needs. Doctor reports
> the resolved profile name alongside the resolved roots so misconfigured
> exports surface immediately.

Hard-coded macOS paths (`$HOME/.codex`, `$HOME/.claude`) are acceptable as
*defaults* because both products use them today; `runtime-roots.yaml` is the
escape hatch when that ceases to be true.

Runtime output should use this precedence:

1. A tool-specific explicit flag, such as `--state-dir` or `--out`.
2. A product adapter variable, such as `CODEX_AGENT_STATE_HOME` or
   `CLAUDE_KIT_STATE_HOME`.
3. An XDG state fallback, normally `${XDG_STATE_HOME:-$HOME/.local/state}/...`.
4. A repo-local `out/` only when the target project or tool contract explicitly
   requires project-local artifacts.

The canonical `out/` layout under a chosen `state_home` should be:

```text
<state_home>/
  out/
    projects/<owner>__<repo>/<run-id>-<topic>/
    tools/<tool-name>/<run-id>/
    workflows/<workflow-name>/<repo-slug>/<run-id>/
  backups/
    <product>/<timestamp>-<surface>/
```

Existing legacy names such as `$AGENT_HOME/out/projects/...`,
`$AGENT_HOME/out/playwright/...`, and `${CLAUDE_KIT_STATE_HOME}/out/...` are
migration inputs only — they are read by the migration tooling, mapped into
the new product-specific `state_home`, and never appear in rendered target
output. The new schema classifies them under `projects`, `tools`, or
`workflows` instead of preserving every historical top-level directory as a
durable target shape.

### Portable Skill References

Core skill bodies should describe intent and required entrypoints without
hard-coding product runtime paths. Product adapters render path references.

Portable source example:

```markdown
Run the topic radar helper:

{{ script("reporting/topic-radar/topic-radar.sh") }} --preset ai-news --format json
```

Codex adapter render (plugin-scoped):

```markdown
$CODEX_HOME/plugins/reporting/skills/topic-radar/scripts/topic-radar.sh \
  --preset ai-news --format json
```

Claude plugin adapter render:

```markdown
${CLAUDE_PLUGIN_ROOT}/scripts/topic-radar.sh --preset ai-news --format json
```

Claude legacy root-skill adapter render (only when a skill is intentionally
kept at the user root rather than plugin-scoped):

```markdown
$HOME/.claude/skills/topic-radar/scripts/topic-radar.sh \
  --preset ai-news --format json
```

The same rule applies to policy references:

- Core source says "resolve the startup docs for this product".
- Codex target renders
  `agent-docs --docs-home "$CODEX_HOME" resolve --context startup ...`.
- Claude target renders
  `agent-docs --docs-home "$HOME/.claude" resolve --context startup ...`.

Render output never contains `$AGENT_HOME`. Drift audit treats any leak as a
blocking error.

### Project-Local Extensibility

Several skills (`bench`, `demo`, `deploy`, `pre-pr`, `release`, `bootstrap`)
ship only a thin shim that dispatches to `<target-repo>/.agents/scripts/<name>.sh`
inside the user's working repository. The runtime kit must keep this contract
because each consuming repo owns the real implementation (cargo vs npm vs uv,
deploy targets, version schemes, etc.).

Rules:

- Core skill source documents the dispatch contract (script path, expected
  arguments, exit codes) but does not implement the body.
- `product-capabilities.yaml` does *not* enumerate per-repo scripts; the
  contract is repo-side.
- A consuming repo discovers and runs `<repo-root>/.agents/scripts/<name>.sh`
  only when the file exists and is executable. Missing script → skill reports
  "no project-local implementation" and exits non-zero rather than guessing.
- Doctor includes an opt-in `--check-project <path>` mode that scans a target
  repo for declared overlays and reports which are wired.

### Overlay Merge Semantics

Three overlay files extend tracked manifests without forking the repo.
Each has fixed merge rules and `agent-runtime install --dry-run` MUST
print the post-merge "effective config" so reviewers see the resolved
state, not the inputs.

| Overlay file | Tracked counterpart | Merge rule |
| --- | --- | --- |
| `.private/runtime-roots.yaml` | `manifests/runtime-roots.yaml` | Per-product deep merge. Each top-level product key merges its sub-keys recursively; on collision the `.private/` value wins. A `null` value in `.private/` removes that key from the merged result. |
| `.private/link-map.overrides.yaml` | `targets/<product>/link-map.yaml` | Per-entry override. Entry id is the key; the `.private/` entry **replaces** the tracked entry as a whole (no deep merge — avoids subtle drift in nested install metadata). `enabled: false` in an overlay entry drops that entry from the install plan. |
| `profile.recommended.yaml` | `manifests/cli-tools.yaml` | Profile-level. New profile names are allowed verbatim. For existing profiles, list-valued keys (`profiles.recommended: [...]`) are **union**-merged; scalar / map-valued keys are **replaced**. Under `formulas.<name>`, the entire formula entry is replaced. A `null` formula entry removes that formula from the profile. |

Merge ordering is fixed: tracked first, overlay second. `.private/` is
read once per `install` / `audit-drift` / `doctor` invocation; in-memory
mutations in one subcommand do not leak into another.

Validation expectations:

- Drift audit refuses to start if any overlay file fails its schema —
  blocking finding, not a warning.
- `agent-runtime install --dry-run` must print the resolved roots,
  link map, and profile after merge. CI gates can `diff` this against
  a pinned fixture to catch silent overlay drift.
- `doctor` reports which overlay files were present, their schema
  versions, and the effective config hash so multi-machine
  configurations are reproducible.

Adding a fourth overlay mechanism (e.g. `*.local.yaml` siblings) is
explicitly out of scope. `.private/` is the only untracked overlay
surface; everything else lives in tracked manifests so review history
captures the change.

## Hook Portability

Hook activation contracts differ between products: Codex syncs a managed block
into `~/.codex/config.toml`; Claude registers hooks via `settings.json` `hooks`
blocks. Hook *scripts* (the actual logic) are often portable, but the wrapper
that adapts payload shape, exit-code semantics, and stdin/stdout protocol is
product-specific.

Layout:

- `core/hooks/<hook-name>/` — portable logic (Python/shell), pure function over
  a normalised payload object.
- `targets/<product>/hooks/<hook-name>/` — thin adapter that:
  1. parses the product's hook payload (stdin/env vars),
  2. normalises it into the core helper's expected schema,
  3. invokes `core/hooks/<hook-name>/main.<ext>`,
  4. translates the result back into the product's expected response
     (exit code, JSON on stdout, etc.).
- `manifests/product-capabilities.yaml` lists per-product hook payload shape
  and supported lifecycle events.

A hook may also be product-only when its trigger or payload has no equivalent
on the other side. In that case the core slot is empty and the adapter ships
the full implementation. Drift audit accepts this if `skills.yaml`-style
`products: [claude]` is declared on the hook.

## Heuristic System Placement

The Heuristic System (workflow failure → durable knowledge pipeline currently
documented in claude-kit's `HEURISTIC_SYSTEM.md`) splits cleanly across the
core/target boundary:

| Surface | Location | Notes |
| --- | --- | --- |
| Policy doc (`HEURISTIC_SYSTEM.md`) | `core/policies/heuristic-system/HEURISTIC_SYSTEM.md` | Product-independent routing rules |
| Operation records | `core/policies/heuristic-system/operation-records/<slug>.md` | Cross-product reusable lessons |
| Error inbox (active) | `<state_home>/heuristic-system/error-inbox/` | Per-product writable state, not tracked |
| Error inbox (archive) | `<state_home>/heuristic-system/error-inbox/archive/YYYY/` | Pruned by retention policy |
| Skill driver | `core/skills/meta/heuristic-error-inbox/` | Same skill body for both products |

Rationale:

- Policy and routing rules do not depend on product. They belong in `core/`.
- Active inbox entries are writable runtime state. Tracking them creates
  noise and merge conflicts; they belong under `state_home`.
- Operation records that capture cross-product lessons (skill workflow
  failures, install pitfalls) should be reusable and live in `core/`.
- A claude-only or codex-only lesson can live under
  `targets/<product>/policies/heuristic-system/operation-records/` and is
  read in addition to core records.

Migration note: existing `heuristic-system/error-inbox/` under claude-kit must
move into the per-product `state_home` during the migration phase. Archived
entries in `archive/YYYY/` are preserved as-is — the path moves, not the
content. The CLI side moves to the `heuristic-inbox` nils-cli binary; the
skill body wraps that binary rather than re-implementing inbox parsing.

## CLI Boundary: nils-cli Owns The CLI Surface

`nils-cli` is the durable, deterministic capability layer **and** the
orchestration CLI. agent-runtime-kit is a pure content repo: skills, plugin
manifests, hook source, render templates, policy docs. There is no
standalone CLI binary inside agent-runtime-kit — orchestration commands
(`render`, `install`, `uninstall`, `doctor`, `audit-drift`, `gc-backups`)
live in a new nils-cli crate `agent-runtime-cli`, distributed alongside
every other nils-cli binary via `brew install sympoies/tap/nils-cli`.

### Why No Separate Orchestration CLI

Three reasons:

1. **Single install path.** Users run one `brew install` to get capability
   binaries *and* orchestration. No second bootstrap, no second language
   runtime.
2. **Single release cadence.** Render / install / drift audit ship in lock
   step with the capability binaries they depend on. No version skew
   between "skill body expects flag X" and "render binary too old to know
   about it".
3. **Shared internals.** `nils-common`, `nils-term`, JSON contracts, exit
   code conventions, terminal UX — all already standardised in nils-cli.
   A separate Python orchestrator would reinvent them.

The template engine moves to **Tera** (Rust, jinja2-compatible syntax) so
existing helper API design (`script()`, `skill_ref()`, `state_out()`,
`cli_ref()`) ports over as Tera registered functions with no syntax
changes to skill bodies.

### Ownership Split

| Concern | nils-cli (Rust workspace) | agent-runtime-kit (this repo) |
| --- | --- | --- |
| Network / FS / parsing logic | Yes (typed, tested, semver) | No |
| JSON contracts, exit codes, machine output | Yes | Consumes them |
| Cross-shell, cross-IDE invocation | Yes | Manifests assume `agent-runtime` is on PATH |
| Render engine (Tera + helpers) | Yes (`agent-runtime-cli` crate) | No |
| Skill / plugin / hook source content | No | Yes |
| Markdown skill bodies (LLM-readable prose) | No | Yes |
| Plugin packaging (`.codex-plugin/`, `.claude-plugin/` templates) | No | Yes |
| Hook source logic | No | Yes (under `core/hooks/`) |
| Hook activation (settings.json, config.toml managed blocks) | Yes (`agent-runtime install`) | Wiring declared in `manifests/` |
| Slash commands, subagent definitions | No | Yes |
| Install / render / drift audit / doctor | Yes (`agent-runtime` binary) | No |
| Repo bootstrap / CI glue | No | Yes (Bash scripts that invoke released CLIs) |
| Skill-local data helpers | Extract when shared or contract-bearing | Yes, only when owned by one skill |
| "When to use which CLI and how to compose them" | No | Yes (skill prose) |

### Script And Helper Boundary

Scripts in this repo are allowed, but they are not a second product runtime.

- Top-level `scripts/` uses Bash for host bootstrap, CI sequencing, fixture
  comparison, and other repository glue. These scripts must stay compatible with
  macOS system Bash 3.2 and Linux Bash unless a script states a narrower host
  contract.
- Skill-local wrappers under `core/skills/**/scripts/` should stay thin: resolve
  paths, adapt product invocation shape, and call a nils-cli binary or a
  skill-owned helper.
- Python may live under `core/skills/**/bin/` for skill-owned data processing or
  source aggregation, but not for repo-wide orchestration. If Python logic
  becomes a shared capability, stable machine-output producer, parser, or
  exit-code contract, move it to nils-cli and declare the binary in
  `required_clis`.
- New network, filesystem, parsing, install, render, doctor, audit, or lifecycle
  behavior defaults to nils-cli. This repo should hold the source content,
  manifests, fixtures, and shell glue needed to exercise that released behavior.

### Skill Anatomy After The Split

A skill body is roughly: prose decision logic + one or more nils-cli
invocations + product-native operations (Read/Write/Edit in Claude,
equivalent in Codex) + reasoning prompts. Heavy logic is gone.

Before (claude-kit, today):

> The `semantic-commit` skill body has 200 lines of shell + Python helpers,
> embedded validation rules, and an inline implementation of the commit body
> gate.

After (agent-runtime-kit, target):

> The `semantic-commit` skill body documents *when* to invoke
> `semantic-commit` (the nils-cli binary), what flags to pass, how to
> interpret its JSON output, and what to do on failure. No commit logic
> lives in the skill.

### `required_clis` In `skills.yaml`

Every skill declares the nils-cli binaries it invokes, with a minimum semver
range. This is a manifest contract, not a soft hint:

```yaml
schema_version: 1
skills:
  - id: pr.deliver-feature-pr
    source: core/skills/pr/deliver-feature-pr
    required_clis:
      forge-cli: "<TBD: pin during Phase 1>"
      git-scope: "<TBD: pin during Phase 1>"
      semantic-commit: "<TBD: pin during Phase 1>"
    products:
      codex:
        name: pr-deliver-feature
        render_to: build/codex/plugins/pr/skills/deliver-feature-pr
      claude:
        name: pr:deliver-feature-pr
        render_to: build/claude/plugins/pr/skills/deliver-feature-pr
```

`schema_version` permits later schema growth (e.g. `required_clis_optional`
for fallbacks). Drift audit cross-references `required_clis` against the
nils-cli release manifest and fails on (a) missing binary, (b) version
below the declared floor, (c) binary that has since been deleted upstream.

`<TBD: pin during Phase 1>` is a placeholder used in this design document
only. Real manifests pin every `required_clis` entry to a concrete semver
range (e.g. `">=0.5.0"`) against the snapshot in
`docs/source/nils-cli-surface.md`. Drift audit treats any literal `<TBD>`
in a tracked manifest as a Phase 1 gate failure — no `<TBD>` may survive
into Phase 2.

### State Path Allocation Via `agent-out`

`agent-out` (nils-cli) is the canonical artifact path allocator. The
`state_home` model in this document is the *policy*; `agent-out` is the
*runtime allocator*. Render-time:

```tera
Write the raw collection output under {{ state_out(domain="projects", topic="daily-brief") }}.
```

(Tera passes function arguments by keyword; helper signature mirrors what
Jinja2 sketches would have looked like.)

Two rendering modes:

1. **Runtime allocation (preferred).** Helper renders to a literal
   `agent-out` invocation:
   ```bash
   $(agent-out path-for projects --repo "$REPO_SLUG" --topic daily-brief)
   ```
   Skill calls `agent-out` at execution, picks up env-resolved
   `state_home`, supports the `--apply` / `--ensure` flag set, and writes
   into the correct subtree without the skill knowing the path.
2. **Literal fallback.** When the consuming context cannot exec
   (documentation examples, dry-run output), helper renders the resolved
   path. Marked as such in render output so reviewers see it is a fallback.

Manifest carries `state_out_mode: runtime|literal` per skill if a skill
needs to pin one mode; default is `runtime`.

### Doctor Coverage

`agent-runtime doctor` includes a `nils-cli` check that:

- runs `<binary> --version` for every binary named in any tracked skill's
  `required_clis` (nils-cli ships as a workspace of independent binaries;
  there is no umbrella `nils-cli` command).
- compares against the declared minimum and reports `missing` / `outdated`
  / `ok` per binary.
- defers third-party tool checks (`gh`, `glab`, `git`, `fzf`, `grpcurl`,
  `ffmpeg`, etc.) to nils-cli's own probe logic instead of re-implementing
  them. Source of truth is nils-cli's `BINARY_DEPENDENCIES.md`; the
  `agent-runtime doctor` subcommand re-uses the same probe routine because
  it lives in the same Rust workspace.

### Extraction Pattern

Skill complexity ratchets *down* over time:

1. Inline logic discovered in a skill → file an extraction candidate
   (operation record / heuristic inbox entry pointing at the skill).
2. Logic moves into a new or existing nils-cli crate, released, Homebrew
   updated.
3. Skill body shrinks to a `required_clis` declaration + the prose around
   the new binary call.

The migration phase explicitly scans existing skills for this pattern and
records candidates in `docs/source/extraction-backlog.md` (separate from the
plan files).

## Install Channels

Host bootstrap goes through Homebrew (macOS) / Linuxbrew (Linux) by default;
fallbacks exist for environments where brew cannot be installed.

### Tap Layout

`sympoies/homebrew-tap` (`brew tap sympoies/tap`) ships:

| Formula | Provides | Source repo |
| --- | --- | --- |
| `nils-cli` | All capability binaries **and** the `agent-runtime` orchestration binary | `sympoies/nils-cli` |
| `agent-workspace-launcher` | Workspace lifecycle helper (unrelated to runtime kit core) | `graysurf/agent-workspace-launcher` |

When `nils-cli` ships a new release, formula bump in the tap is the
single distribution event. The tap does not need a separate `arkit` or
`agent-runtime-cli` formula because both ride inside `nils-cli`.

### Brew-First Bootstrap

`scripts/setup.sh` (macOS + Linux unified) does:

1. Install Homebrew if missing (skip with `--skip-homebrew-install`).
2. `brew tap sympoies/tap`.
3. `brew install nils-cli` (or `brew upgrade nils-cli` when present). This
   makes `agent-runtime` available on PATH alongside every capability
   binary.
4. Read `manifests/cli-tools.yaml`, filter by `--profile core|recommended|full`,
   and `brew install` the third-party CLIs in the chosen profile (the
   set previously enumerated in agent-kit's `CLI_TOOLS.md`).
5. Clone agent-runtime-kit into `$HOME/.config/agent-runtime-kit` if
   missing.
6. Invoke `agent-runtime install --product claude` and
   `agent-runtime install --product codex`.
7. Run `agent-runtime doctor` and print a one-screen summary.

### Linuxbrew

The same `setup.sh` works on Linux because Homebrew on Linux uses the
same `brew` binary with a different prefix
(`/home/linuxbrew/.linuxbrew/bin`). `setup.sh` detects the prefix via
`brew --prefix` rather than hard-coding `/opt/homebrew`. Per-formula
support varies — `manifests/cli-tools.yaml` carries an optional
`linux_only_alternative:` field for formulas that ship only on macOS
(e.g. native screen-capture tools).

### Fallback Ladder For Non-Brew Hosts

Order of preference when Homebrew/Linuxbrew cannot be installed:

1. **`cargo install --git`** for nils-cli binaries (requires Rust
   toolchain). `scripts/setup.sh --no-brew --with-cargo` chooses this
   path.
2. **Direct release tarball** from `sympoies/nils-cli` GitHub releases —
   downloaded, verified by SHA, extracted to `$HOME/.local/bin/`.
   `setup.sh --no-brew --tarball` chooses this path.
3. **Source build** from a local `nils-cli` checkout (`cargo build
   --release` + manual PATH wiring). Reserved for active nils-cli
   development; recorded only as a documented option, not part of
   `setup.sh`.

For each path, the third-party CLI_TOOLS catalog has to be installed by
the host package manager (`apt`, `dnf`, manual download); `setup.sh`
prints the missing tool list and exits non-zero rather than guessing.

### CI / Sandbox Hosts

CI runs typically pre-install nils-cli via cached brew, then invoke
`agent-runtime <subcommand>` directly. `setup.sh --skip-brew-update
--skip-homebrew-install --skip-cli-tools` short-circuits the host-tool
install loop when CI already provides them.

## Install And Link Strategy

The installer should manage links and rendered files explicitly. It should never
blindly replace an entire runtime home.

Recommended behavior:

1. Render product target files into a build or generated target directory.
2. Link only approved files/directories into `~/.codex` and `~/.claude`.
3. Sync mutable config via managed blocks where the product stores local state in
   the same file.
4. Back up existing non-symlink files before replacing them.
5. Preserve runtime state directories and secrets.

Product-specific examples:

- Codex: link `~/.codex/AGENTS.md` to `<source_root>/CODEX_AGENTS.md`, expose
  runtime-kit skills under `~/.codex/skills`, sync managed hooks into
  `~/.codex/config.toml`, retain plugin metadata for audit only, and leave
  auth/history/logs/cache untouched.
- Claude: link approved files from the canonical link map into `~/.claude`,
  register the local plugin marketplace, install configured plugins, and leave
  projects/history/session/cache/plugin install artifacts untouched.

### Build And Render Output

- `build/` is **gitignored**. Install always regenerates it from manifests +
  source. Two clean clones must produce byte-identical `build/` for the same
  manifest commit — render determinism is a CI invariant. The
  implementation constraints that make this hold are in
  [Resolved Decision #9](#resolved-decisions): no wall-clock, no
  randomness, no HashMap iteration order, only commit-derived time
  values, `IndexMap` / `BTreeMap` at Tera context entry points,
  clippy-enforced.
- Render reads only from `core/`, `targets/`, `manifests/`. It must not read
  `~/.codex`, `~/.claude`, or any runtime state.
- Render is incremental: a per-skill hash (source + product capability hash)
  is stored in `build/<product>/.render-cache.json`; unchanged skills are
  copied verbatim from the previous build to keep install fast on large
  inventories (160+ skills). Cache hit and cache miss MUST produce
  byte-identical output — this is verified by the cross-process
  determinism test described in Decision #9.

### Managed-Block Contract

For products whose config is co-owned with local state (Codex `config.toml`,
Claude `settings.json`), the installer edits in place using paired markers:

```
# >>> agent-runtime-kit:<surface> >>>
<rendered content>
# <<< agent-runtime-kit:<surface> <<<
```

Outside the marker pair, the file is preserved byte-for-byte. Re-running
install only rewrites the managed range. Removing the markers is the
"unmanaged" escape hatch — the installer refuses to re-add a managed block
without `--force`.

### Uninstall Behavior

- Default: remove only the symlinks/managed-blocks the install map currently
  owns. Backups, runtime state, secrets, and `~/.codex` / `~/.claude` history
  are never touched.
- Uninstall is idempotent. Running it twice on a clean home is a no-op, not an
  error.
- Restoring previously-replaced files is **not** an `uninstall` mode — it
  lives in the dedicated `agent-runtime restore-backups` subcommand (see
  below). Purging writable state likewise lives in
  `agent-runtime purge-state`. Keeping these out of `install` / `uninstall`
  removes the foot-gun where a flag typo wipes state.

### Restore-Backups Subcommand

- `agent-runtime restore-backups --from <timestamp>|latest` restores the
  named backup of any pre-existing file the installer replaced.
- `--from` is required; running without it exits non-zero with a list of
  available timestamps. The CI-friendly shorthand is `--from latest`.
- Restore is per-product (`--product codex|claude`) and per-surface
  (`--surface <name>`); both default to "all owned by the install map".
- Dry-run first via `--dry-run` (no file mutation, prints planned
  restores). `--apply` performs the restore.

### Purge-State Subcommand

- `agent-runtime purge-state --scope out|backups|all` removes writable
  state under `<state_home>`. Scope values:
  - `out` — clears `<state_home>/out/` only (runtime artifacts).
  - `backups` — clears `<state_home>/backups/` only.
  - `all` — both. Rejected if no scope value is passed; never defaults.
- Always prompts for confirmation unless `--yes` is set; `--yes` is
  reserved for CI / scripted contexts and is logged.
- Does **not** touch product runtime homes (`~/.codex`, `~/.claude`),
  auth, history, or sessions — those remain off-limits for any
  `agent-runtime` subcommand.

### Backup Retention

- Backups live under `<state_home>/backups/<product>/<timestamp>-<surface>/`.
- Retention default: last 5 install runs per surface, plus any backup tagged
  manually via `agent-runtime install --tag <name>`.
- Doctor reports backup directory size; aged backups beyond retention are
  pruned by the dedicated `agent-runtime gc-backups` subcommand (never
  silently by `install` itself).

### Doctor Checks

`agent-runtime doctor` reports — never mutates:

- symlink integrity (every entry in the product link map exists and points
  to a tracked source file)
- managed-block presence and marker pairing in product config files
- `runtime-roots.yaml` resolution against the current host (paths exist,
  permissions readable)
- product runtime version: runs each product's `version_probe`, parses
  the output, and compares against three pinned values in
  `runtime-roots.yaml`:
  - `min_version` — installed version below this is **block** (today,
    once `min_version_effective_from` has passed).
  - `recommended_version` — installed version below this but at-or-above
    `min_version` is **warn** (printed, non-blocking, exit `1`).
  - `min_version_effective_from` — ISO date. Before this date, falling
    below `min_version` produces a warn-only finding ("future-pinned
    floor"); on or after this date the same finding flips to blocking.
    Lets a `min_version` bump be merged with a forward-pinned grace
    window instead of breaking every build on the merge commit.

  Status values reported per product: `ok` / `recommended-only` / `warn`
  / `outdated` / `unparseable`. Only `outdated` (when effective) is
  blocking; the rest are reported with their disposition.
- `agent-runtime doctor --suggest-upgrade` mode: prints the exact
  `brew upgrade <formula>` commands needed to bring every probed
  binary (product CLI + `required_clis` nils-cli binaries + cli-tools
  catalog entries) to the declared `recommended_version` / latest
  formula. Read-only — never executes the upgrade. CI gates and local
  developers can copy-paste from the output.
- nils-cli binary coverage: every `required_clis` entry across tracked
  skills is on PATH and at or above the declared minimum semver; reports
  `missing` / `outdated` / `ok` per binary
- third-party CLI catalog coverage: reads `manifests/cli-tools.yaml`,
  filters by the active profile, and verifies every formula's `command:`
  binary is on PATH; reports per-tool status and the brew command to
  install anything missing
- third-party binaries used by nils-cli itself (delegates to nils-cli's
  own probe routine inside the same workspace; source of truth is
  `BINARY_DEPENDENCIES.md` in the installed nils-cli)
- product CLIs on PATH (Codex CLI, Claude CLI) for live-home install paths
- render determinism canary (re-render one skill, diff against `build/`);
  the full guarantee lives in Resolved Decision #9 and the render-golden
  CI gate — this is the fast local sanity probe.
- drift audit summary (delegates to `audit-drift`, surfaces top findings)
- backup directory size and oldest entry age
- optional `--check-project <path>` to inspect a consuming repo's
  `<repo>/.agents/scripts/` overlay coverage

Exit code: `0` clean, `1` warnings only, `2` blocking issues. Same code shape
as `audit-drift` so CI gates can chain them.

### Runtime Skill Acceptance

Plan 06 adds `tests/runtime-smoke/` as the repo-local acceptance harness for
runtime skill surfaces. The default gate stays deterministic, offline, and
credential-free: `scripts/ci/all.sh` runs `bash tests/runtime-smoke/run.sh
--mode deterministic` after render, golden, drift, and sandbox install checks.

Product-in-the-loop smoke is separate from default CI. The product probe mode
uses temporary homes only. Default product mode first proves isolated CLI
invocation, then installs the rendered runtime into temp product homes and
records representative prompt cases for `agent-docs`, `agent-out`,
`canary-check`, `skill-usage`, and `docs-impact`. Prompt execution stays
quarantined and is recorded as `skip-host-capability` unless the operator
explicitly enables it with isolated provider/auth state:

- Codex probe contract: `CODEX_HOME=<temp> codex exec --ignore-user-config
  --ephemeral --skip-git-repo-check ...`. This proves an isolated CLI prompt
  path. If no isolated local provider is running, the prompt path is
  manual-only rather than a CI blocker.
- Claude probe contract: `CLAUDE_CONFIG_DIR=<temp> claude -p --bare
  --no-session-persistence ...`. This proves an isolated CLI prompt path. If no
  isolated API key or auth helper is supplied, the prompt path is manual-only
  rather than a CI blocker.

No runtime smoke mode may read or mutate real `$HOME/.codex`, `$HOME/.claude`,
auth, sessions, history, logs, caches, or product state. Product smoke must
remain outside required CI until prompt execution can run without those
dependencies. The acceptance matrix may contain both deterministic and product
prompt cases, but deterministic smoke is the required continuation gate.

The installer must also render a product-specific root map before it renders
skills, hooks, or docs. A minimal local machine map could look like:

```yaml
schema_version: 1
products:
  codex:
    live_home: "$CODEX_HOME"
    docs_home: "$CODEX_HOME"
    state_home: "${CODEX_AGENT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/codex}"
    plugin_root: "$CODEX_HOME/plugins"
    hook_config_strategy: managed-block
    min_version: "0.18.0"
    recommended_version: "0.19.0"
    min_version_effective_from: "2026-06-01"
    version_probe: "codex --version"
  claude:
    live_home: "$HOME/.claude"
    docs_home: "$HOME/.claude"
    state_home: "${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude}"
    plugin_root_env: "CLAUDE_PLUGIN_ROOT"
    hook_config_strategy: settings-json
    min_version: "1.0.45"
    recommended_version: "1.0.50"
    min_version_effective_from: "2026-06-01"
    version_probe: "claude --version"
```

`min_version` is the blocking policy floor; `recommended_version` is the
warn floor; `min_version_effective_from` is the forward-pin date that
gates when a `min_version` bump starts blocking instead of warning.
Drift audit and doctor both probe `version_probe` and fail when the
parsed version is below the blocking floor *and* the effective-from date
has passed. Bumping product versions on the host is therefore an
in-band, audited action — never silent — and a `min_version` bump in
the manifest is itself an audited action with the ceremony described in
[Resolved Decision #7](#resolved-decisions).

The probe output is parsed with a permissive semver matcher to tolerate
product-specific prefixes (`codex 0.18.2 (build abc1234)` etc.). Numbers
that cannot be parsed are treated as fail-open with a loud warning, not as
pass.

Values shown above are illustrative — actual floors are pinned during
Phase 1 by reading the installed product versions on the development host
and adopting them as the initial baseline.

## Secrets And Sensitive Data

The repository tracks portable source and product activation glue. It must not
track auth tokens, session state, history, cache, or any per-host secrets.

### What Counts As Sensitive

- API tokens and refresh tokens (GitHub, GitLab, Telegram bot, Jira, Anthropic).
- 1Password references that resolve secrets (`op://` URIs) when paired with
  account-scoped identifiers.
- Product runtime auth files: `~/.codex/auth.json`, `~/.claude/.credentials`,
  any `oauth.json`.
- Per-user MCP server connection strings that embed credentials.
- Personal directory data (`gamania_work_toolbox` directory search caches,
  contact lists, calendar payloads).
- Anything under a runtime `live_home/state/`, `live_home/history/`,
  `live_home/sessions/`, `live_home/projects/`.

### Baseline `.gitignore`

Top-level `.gitignore` must include at minimum:

```
build/
*.local.*
.env
.env.*
secrets/
secrets.*.yaml
auth.json
.credentials*
**/sessions/
**/history/
**/cache/
.private/
```

### `.private/` Shadow Overlay

The existing claude-kit pattern of `.private/` shadowing user-level configs is
preserved as an opt-in overlay:

- `.private/` lives outside version control (top-level gitignore entry).
- When present, install reads `.private/runtime-roots.yaml` and
  `.private/link-map.overrides.yaml` after the tracked versions, so private
  hosts and overlays can ride on top without forking the repo. Merge
  rules are defined in [Overlay Merge Semantics](#overlay-merge-semantics).
- Drift audit treats `.private/` as a "tracked input, untracked source": it
  validates structure but never reports diffs against it.

### Drift Audit `unsafe` Class

The `unsafe` classification covers any sensitive-data leak into tracked
surface. Scope:

- every file under `core/` and `targets/`
- every rendered file in `build/`
- every link target the installer would create

Disposition is driven by the composite scoring rules in
[Unsafe Scoring](#unsafe-scoring) (signals, weights, thresholds,
allowlist). The short version: two or more signals → block; one signal →
warn; zero signals → not reported. Allowlist entries in
`drift-audit.allow.yaml` may demote a finding by one tier but never
silence it.

## Drift Detection

The project needs first-class drift audit because Codex and Claude will continue
to evolve independently.

`agent-runtime audit-drift` should check:

- source manifest versus rendered target files
- rendered target files versus live symlink destinations
- product plugin manifests versus local plugin schema (Claude marketplace
  entries compare against Claude's published plugin.json contract; Codex
  `.codex-plugin/plugin.json` compares only against the local schema in
  `core/docs/schemas/` — there is no upstream Codex registry to diff
  against, see
  [Codex Activation Surface](#codex-activation-surface-reality-check))
- live runtime config managed blocks versus source blocks
- skill inventory differences across products
- local runtime paths that should never be tracked
- known intentional product differences from `product-capabilities.yaml`
- root-map correctness, including whether rendered docs use the intended
  `docs_home` and whether generated outputs stay under the intended `state_home`

The audit should classify findings:

- `missing`: source says a surface should exist but it does not
- `stale`: live/rendered content differs from source
- `extra`: live surface exists but is unmanaged
- `intentional-difference`: documented divergence
- `unsafe`: secret/runtime/cache/history material appears in a tracked surface

### Unsafe Scoring

Single-signal entropy detection produces too many false positives on
synthetic fixtures (base64 test data, render-golden snapshots, mocked
credentials). `unsafe` is therefore a **composite** score rather than a
single match.

Signal weights and threshold:

| Signal | Weight |
| --- | --- |
| `path_match` — file path matches a known runtime / auth / state pattern (e.g. `**/auth.json`, `**/.credentials*`, `**/sessions/**`) | 0.4 |
| `keyword_prefix` — line matches one of `token`, `api_key`, `password`, `bearer`, `secret`, `private_key` (case-insensitive) within 16 chars before a value-shaped token | 0.4 |
| `entropy_above_threshold` — Shannon entropy ≥ 4.0 bits/byte over a contiguous ≥ 24-char run on the same line | 0.4 |

Disposition:

- `score >= 0.8` (any two signals or stronger) → **block**. Install and
  CI both fail until the finding clears or is allowlisted.
- `0.4 <= score < 0.8` → **warn**. Reported, `audit-drift` exits `1`,
  but does not block. Treated as a backlog item to investigate.
- `score < 0.4` → **suppressed**. Reachable only via `--verbose`.

Allowlist:

- Tracked file `drift-audit.allow.yaml` (top-level) carries the explicit
  allowlist:
  ```yaml
  schema_version: 1
  unsafe_allow:
    - path: "tests/drift/fixtures/**"
      reason: "Synthetic credentials by design"
    - path: "tests/golden/**/*.snap"
      reason: "Render golden snapshots may contain base64 binary"
  ```
- Each entry requires both `path` (glob) and `reason` (free text). Missing
  `reason` is a schema error.
- Allowlist entries demote a finding by exactly one tier (`block` → `warn`,
  `warn` → `suppressed`). They never silence a finding outright — that
  would make adding a legitimate secret to a fixture path invisible.
- The allowlist is tracked so review history captures every relaxation;
  putting `unsafe` allowances in `.private/` is intentionally not
  supported.

## Testing And Validation

Drift audit and doctor catch *integration* problems on a real host. Unit-level
correctness is a separate stack and lives in `tests/`.

### Test Layers

1. **Manifest schema validation** — every YAML in `manifests/` validates
   against a schema in `core/docs/schemas/`. Failure on missing
   `schema_version`, unknown product, dangling skill source path, or duplicate
   canonical IDs. Runs on every commit.
2. **Render golden files** — for each (skill, product) pair, a tiny snapshot
   under `tests/golden/<product>/<skill>/expected/` is the byte-exact render
   target. CI fails if `agent-runtime render` produces a diff against the
   pinned snapshots. Regenerated explicitly via
   `agent-runtime render --update-golden` (review the diff before
   committing).
3. **Hook adapter contract tests** — for each `targets/<product>/hooks/<name>`
   adapter, fixed payload fixtures in `tests/hooks/<product>/<name>/` exercise
   parse → invoke → response. Independent of any running product.
4. **Install dry-run snapshots** — `agent-runtime install --dry-run --product <p>`
   produces deterministic plan output; `tests/install/<product>/expected.txt`
   pins it. Catches accidental scope expansion (extra symlinks, extra managed
   blocks) in review.
5. **Drift audit fixtures** — synthetic `live_home` trees under
   `tests/drift/<scenario>/` exercise each finding class (`missing`, `stale`,
   `extra`, `intentional-difference`, `unsafe`). Each fixture pins both the
   text report and the exit code.
6. **Sandbox install rehearsal** — for each product, install into a
   throwaway `live_home`:
   ```
   agent-runtime install --product claude --live-home /tmp/claude-sandbox
   claude --home /tmp/claude-sandbox --list-skills | jq -r '.[].id' \
     | sort > /tmp/observed-claude-skills.txt
   diff tests/sandbox/claude/expected-skills.txt /tmp/observed-claude-skills.txt
   ```
   The expected file is pinned per product and updated explicitly. Catches
   load-time errors that render golden cannot see: broken symlinks,
   `plugin.json` schema drift, `settings.json` hooks pointing at missing
   files, marketplace entries that the product refuses. **Lands in
   Phase 3 alongside the installer body**, not Phase 1 — the reporting POC
   uses manual rehearsal.
7. **Project-local overlay smoke** — `tests/projects/<sample-repo>/` ships
   a minimal `.agents/scripts/` and asserts that dispatching skills find
   and execute them with the right env.

### CI Gate Order

The standard pipeline runs gates from cheapest to most expensive, fail-fast:

```
1. manifest schema validation        (seconds)
2. render golden diff                (seconds)
3. hook adapter unit tests           (seconds)
4. install dry-run snapshot          (seconds)
5. drift audit on fixture homes      (tens of seconds)
6. sandbox install rehearsal         (tens of seconds per product;
                                      Phase 3+ only)
7. doctor on the CI host             (seconds)
8. project-local overlay smoke       (longer; matrix per overlay sample)
```

The `pre-pr` skill (project-local; dispatches to
`<repo>/.agents/scripts/pre-pr.sh`) chains the same gates locally before push,
so CI failures surface in the developer loop rather than after the fact.

## Proof Of Concept Scope

Recommended first domain: `reporting`.

Why:

- Small enough for a pilot.
- Contains useful cross-product workflow behavior.
- Exercises plugin packaging and skill references without touching high-risk PR,
  CI, or dispatch delivery paths.
- Current Claude plugin already has `daily-brief` and `project-retro`; current
  agent-kit also has `topic-radar` under market research, so the pilot will
  expose real domain-boundary decisions.

POC deliverables:

1. Create `core/skills/reporting/` with canonical source for the chosen skills.
2. Create Codex adapter metadata for a `reporting` plugin.
3. Create Claude adapter metadata for a `reporting` plugin.
4. Add root-map entries for Codex and Claude.
5. Add a manifest entry for each skill and plugin.
6. Add a render or link script for this one domain.
7. Add a drift audit that compares source, rendered files, live target paths,
   docs home usage, and state home usage.
8. Verify that `AGENTS.md` / runtime-home files remain outside version control
   unless explicitly intended.

### Simulated Reporting POC

This example shows the intended effect before any live runtime homes are
mutated.

Source inventory:

```text
core/
  skills/reporting/daily-brief/SKILL.md
  skills/reporting/project-retro/SKILL.md
  skills/reporting/topic-radar/SKILL.md
  skills/reporting/topic-radar/scripts/topic-radar.sh
targets/
  codex/plugins/reporting/.codex-plugin/plugin.json
  claude/plugins/reporting/.claude-plugin/plugin.json
manifests/
  skills.yaml
  plugins.yaml
  runtime-roots.yaml
```

Portable `skills.yaml` slice:

```yaml
schema_version: 1
skills:
  - id: reporting.daily-brief
    source: core/skills/reporting/daily-brief
    required_clis:
      agent-out: "<TBD: pin during Phase 1>"
      git-scope: "<TBD: pin during Phase 1>"
    state_out_mode: runtime
    products:
      codex:
        name: daily-brief
        render_to: build/codex/plugins/reporting/skills/daily-brief
        command_root: "$CODEX_HOME/plugins/reporting/skills"
      claude:
        name: daily-brief
        render_to: build/claude/plugins/reporting/skills/daily-brief
        command_root: "${CLAUDE_PLUGIN_ROOT}"
  - id: reporting.topic-radar
    source: core/skills/reporting/topic-radar
    required_clis:
      agent-out: "<TBD: pin during Phase 1>"
    state_out_mode: runtime
    products:
      codex:
        name: topic-radar
        render_to: build/codex/plugins/reporting/skills/topic-radar
        command_root: "$CODEX_HOME/plugins/reporting/skills"
      claude:
        name: topic-radar
        render_to: build/claude/plugins/reporting/skills/topic-radar
        command_root: "${CLAUDE_PLUGIN_ROOT}"
```

Portable source snippet in `daily-brief/SKILL.md`:

```markdown
Use topic radar for source collection:

{{ skill_ref("reporting.topic-radar") }}
{{ script("reporting/topic-radar/scripts/topic-radar.sh") }} \
  --preset ai-news --format json --refresh

Write temporary raw collection output under:

{{ state_out("projects", topic="daily-brief") }}
```

Rendered Codex snippet (`state_out_mode: runtime`):

```markdown
Use topic radar for source collection:

topic-radar
$CODEX_HOME/plugins/reporting/skills/topic-radar/scripts/topic-radar.sh \
  --preset ai-news --format json --refresh

Write temporary raw collection output under:

$(agent-out path-for projects --repo "$REPO_SLUG" --topic daily-brief --ensure)
```

Rendered Claude plugin snippet (`state_out_mode: runtime`):

```markdown
Use topic radar for source collection:

reporting:topic-radar
${CLAUDE_PLUGIN_ROOT}/scripts/topic-radar.sh \
  --preset ai-news --format json --refresh

Write temporary raw collection output under:

$(agent-out path-for projects --repo "$REPO_SLUG" --topic daily-brief --ensure)
```

The `agent-out` invocation is identical across products because it reads the
product-specific `state_home` from the runtime env (set by `agent-runtime install`'s
managed config block). Literal-fallback render is reserved for documentation
and `--dry-run` output (shown below).

Dry-run install output:

```text
DRY render product=codex domain=reporting
  source core/skills/reporting/daily-brief
  -> build/codex/plugins/reporting/skills/daily-brief
  docs_home=$CODEX_HOME
  state_home=${CODEX_AGENT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/codex}
  live target candidate: $CODEX_HOME/plugins/reporting

DRY render product=claude domain=reporting
  source core/skills/reporting/daily-brief
  -> build/claude/plugins/reporting/skills/daily-brief
  docs_home=$HOME/.claude
  state_home=${CLAUDE_KIT_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/agent-runtime-kit/claude}
  live target candidate: $HOME/.claude/plugins/reporting

No live files changed. Re-run with --apply after drift audit passes.
```

Drift audit output:

```text
ok      source-manifest        reporting.daily-brief source exists
ok      codex-render           no ~/.claude path in Codex render
ok      codex-render           no $AGENT_HOME reference in Codex render
ok      claude-render          no $AGENT_HOME reference in Claude render
ok      codex-docs-home        rendered --docs-home "$CODEX_HOME"
ok      claude-docs-home       rendered --docs-home "$HOME/.claude"
ok      codex-state-home       output path under CODEX_AGENT_STATE_HOME fallback
ok      claude-state-home      output path under CLAUDE_KIT_STATE_HOME fallback
skip    live-install           dry-run mode
```

The visible effect is that one portable skill source produces two different
runtime-safe surfaces:

- Codex renders with `$CODEX_HOME`-relative paths only; no `$AGENT_HOME`.
- Claude receives plugin-root or `$HOME/.claude` paths.
- Temporary outputs are routed through a product-specific `state_home` instead
  of being written into the shared source tree by accident.

## Migration Phases

### Phase 1: Inventory And Schema

- Freeze current inventory from `agent-kit` and `claude-kit`.
- Define `skills.yaml`, `plugins.yaml`, `product-capabilities.yaml`,
  `runtime-roots.yaml`, and `cli-tools.yaml` (each carries
  `schema_version: 1`).
- Settle product-specific alias naming for the first migrated domain.
- Decide per-domain whether product adapters are generated, hand-maintained,
  or hybrid (the default is generated from `core/` via Tera; opt out only
  where a target needs hand-written specifics).
- Open new nils-cli crate `crates/agent-runtime-cli/` with subcommand
  stubs (`render`, `install`, `uninstall`, `doctor`, `audit-drift`,
  `gc-backups`, `restore-backups`, `purge-state`) returning
  "not implemented" so the CLI contract is fixed before any subcommand
  logic lands. Cut a `0.12.0` release on `sympoies/homebrew-tap` so
  the install ladder can be exercised end-to-end against the placeholder
  binary.

### Phase 1.5: Upstream nils-cli Render Enablement

Cross-repo dependency made explicit. Phase 2 cannot start until the
following lands **inside `sympoies/nils-cli`** and is published through
the tap:

- Implement the body of `agent-runtime render` against the Phase 1
  manifest schemas (`skills.yaml`, `plugins.yaml`,
  `product-capabilities.yaml`, `runtime-roots.yaml`, `cli-tools.yaml`).
- Register the Tera helpers (`script`, `skill_ref`, `state_out`,
  `cli_ref`) wired to `nils-common` paths and the `agent-out`
  invocation contract.
- Implement the minimal body of `agent-runtime audit-drift` covering at
  least source-manifest / rendered-target / `$AGENT_HOME` leak / docs-home
  classes — enough for the Phase 2 reporting POC to be validated.
- Cut a `0.1.0` nils-cli release; bump the formula in
  `sympoies/homebrew-tap`; bump `required_clis` floors in this repo's
  manifests to match.

Phase 2 references `agent-runtime render` and `agent-runtime audit-drift`
as if they exist. They only exist after Phase 1.5 ships; the
agent-runtime-kit side of Phase 2 should not be planned in parallel with
this work.

### Phase 2: Reporting POC

- Migrate one low-risk domain.
- Render Codex and Claude targets via `agent-runtime render`.
- Validate local activation without disturbing current production homes.
- Add drift audit for the pilot, including root-map checks.

### Phase 3: Installer

- Implement `agent-runtime install` subcommand body (dry-run-first;
  `--live-home <path>` flag for sandbox installs).
- Implement `agent-runtime uninstall` and `agent-runtime doctor`
  (including the `version_probe` check against `min_version`).
- Preserve the existing Claude `_symlinks.env` model as a design input.
- Preserve the existing Codex managed-block model for `config.toml`.
- Land `scripts/setup.sh` end-to-end: brew tap → install nils-cli → clone
  agent-runtime-kit → `agent-runtime install --product claude` and
  `--product codex`.
- Land the **sandbox install rehearsal** harness
  (`tests/sandbox/<product>/expected-skills.txt` + the CI gate at
  position 6) — uses `agent-runtime install --live-home /tmp/<product>-sandbox`
  then `<product-cli> --home /tmp/<product>-sandbox --list-skills`.

### Phase 4: Domain Migration

Suggested order:

1. `reporting` (low coupling; mostly net-new bodies; smoke-tests the
   render + drift pipeline on a domain with no cross-skill dependencies).
2. `meta` (wraps `agent-docs`, `agent-scope-lock`, `agent-out`,
   `heuristic-inbox`, `repo-retro`, `semantic-commit`). Promoted ahead of
   the heavier domains because every downstream migration relies on
   `agent-docs` preflight, `agent-out` state allocation, and
   `semantic-commit` for landing changes; migrating `meta` second means
   subsequent domains rewrite against the new skill bodies instead of
   the legacy claude-kit / agent-kit ones.
3. `media` (wraps `image-processing`, `screen-record`).
4. `browser` (wraps `browser-session`, `canary-check`).
5. `evidence` (wraps `web-evidence`, `test-first-evidence`,
   `review-evidence`, `skill-usage`, `docs-impact`, `model-cross-check`).
6. `pr` (wraps `forge-cli` end-to-end lifecycle, including `pr deliver`).
7. `dispatch` (wraps `plan-issue`, `plan-issue-local`, `plan-tooling`,
   coordinates with `forge-cli` for issue / PR mirroring).
8. project/company/private overlays.

For each migrated domain, the per-skill checklist is:

1. Identify the nils-cli binary that owns the deterministic logic.
2. Strip embedded shell / Python / inline logic from the skill body.
3. Rewrite the body to invoke the binary with documented flags, JSON
   handling, and error recovery prose.
4. Add `required_clis` with a verified minimum semver.
5. If logic does not yet exist as a nils-cli binary, log an extraction
   candidate in `docs/source/extraction-backlog.md` rather than reinventing
   it inside the skill.

High-risk domains such as `pr` and `dispatch` should migrate only after the
installer and drift audit are reliable.

## Resolved Decisions

Pinned for the rest of this document and Phase 1+ implementation:

1. **Template / render engine — Tera (Rust, jinja2-compatible).** Source
   uses `{{ script(...) }}`, `{{ skill_ref(...) }}`, `{{ state_out(...) }}`,
   `{{ cli_ref(...) }}`. These become Tera registered functions inside the
   `agent-runtime-cli` crate in nils-cli. Rationale:
   - Renders inside the nils-cli Rust workspace alongside every other
     binary; no second language runtime on the host.
   - Tera's syntax is jinja2-compatible (`{{ var }}`, `{% if %}`,
     `{% include %}`, `{% extends %}`, custom filters and functions) so
     the previously-sketched helper API ports over without changes to
     skill body syntax.
   - Atomic release with capability binaries it depends on; no Python
     + Jinja2 + arkit pipeline to maintain in parallel.
   - Mature crate (`tera` on crates.io) with sandboxed evaluation and
     well-defined whitespace control.
   - CI test harness uses `cargo test` + golden file diff, consistent
     with the rest of nils-cli.
   - Considered and rejected: Jinja2 (forces a Python runtime + a separate
     install bootstrap), Go `text/template` (introduces a third language),
     hand-rolled substitution (reinvents escape and partial-include rules).
2. **No standalone orchestration CLI in agent-runtime-kit.** Render /
   install / uninstall / doctor / audit-drift / gc-backups /
   restore-backups / purge-state live in nils-cli as the `agent-runtime`
   binary (new crate `nils-cli/crates/agent-runtime-cli/`). Distribution:
   `brew install sympoies/tap/nils-cli`. Invocation pattern:
   `agent-runtime <subcommand>`. agent-runtime-kit itself ships only
   bootstrap scripts under `scripts/` for host setup. See
   [CLI Boundary](#cli-boundary-nils-cli-owns-the-cli-surface).
3. **Repo relationship — replace both.** `agent-runtime-kit` (private)
   replaces `agent-kit` and `claude-kit` as sole source of truth after
   migration. Both legacy repos are archived. nils-cli stays separate
   (public, Rust, upstream). A future split of public portable assets
   from agent-runtime-kit is a follow-up question, not a Phase 1 blocker.
4. **Hook portability — core logic + product adapter.** Hooks live as
   pure logic under `core/hooks/<name>/` with payload-normalising wrappers
   under `targets/<product>/hooks/<name>/`. Product-only hooks may live
   entirely in the adapter; the manifest declares which slot is filled.
5. **`$AGENT_HOME` removed entirely.** Not used in source, render output,
   or runtime roots. Codex render emits `$CODEX_HOME` /
   `$CODEX_AGENT_STATE_HOME` only. Drift audit treats any rendered
   `$AGENT_HOME` as a blocking error. Legacy `$AGENT_HOME/...` paths in
   inherited `agent-kit` content are migration inputs, rewritten in place.
6. **nils-cli owns the entire CLI surface; agent-runtime-kit is pure
   content.** See [CLI Boundary](#cli-boundary-nils-cli-owns-the-cli-surface)
   for the ownership table. Render / install / doctor / drift audit live
   in `nils-cli/crates/agent-runtime-cli/` as the `agent-runtime` binary.
   Every skill declares `required_clis` with semver floors; doctor + drift
   audit enforce coverage. State paths default to runtime allocation via
   `agent-out` rather than render-time string substitution.
7. **Product version floor — latest-stable, with explicit Bump
   Ceremony.** Each product carries `min_version` + `recommended_version`
   + `min_version_effective_from` + `version_probe` in
   `runtime-roots.yaml`. Initial values pinned during Phase 1 by reading
   the installed product versions on the development host. `doctor` and
   `audit-drift` probe the product CLI; below `min_version` and past
   the effective-from date is **block**, below `recommended_version` is
   **warn**, before the effective-from date a sub-`min_version` finding
   is **warn** ("future-pinned floor"). Bumping product versions is a
   deliberate, audited action with four enforced gates:
   - **`recommended_version` runway.** Bump `recommended_version`
     ahead of `min_version` so doctor warns for at least one release
     cycle before the floor moves.
   - **`min_version_effective_from` forward-pin.** Every
     `min_version` bump carries a future ISO date; doctor warns until
     the date, blocks on and after. Default runway: 14 days.
   - **`agent-runtime doctor --suggest-upgrade`** prints the exact
     `brew upgrade <formula>` commands needed to clear the warning
     before the cutover date.
   - **PR template.** Bump PRs use
     `.github/PULL_REQUEST_TEMPLATE/min-version-bump.md`, which
     requires the author to enumerate impacted CI / local environments,
     tested version combinations (old + old, new + new, mixed during
     runway), the rollback path (revert PR + tap formula pin), and the
     team-channel notification timestamp (24–48 h advance notice).
     Reminder-shaped, not a required CI check — softer than a hard
     gate but loud enough to make silent bumps obvious in review.

   No rolling support window beyond the forward-pinned runway; no
   per-feature floors. The runway exists to absorb host upgrade time,
   not to maintain back-compat with older product releases.
8. **Skill testing strength — render golden + sandbox install rehearsal.**
   Phase 1–2 ships render-golden + drift-audit fixtures only. Phase 3
   adds the sandbox install rehearsal: `agent-runtime install --product
   <p> --live-home /tmp/<p>-sandbox` followed by `<product-cli> --home
   /tmp/<p>-sandbox --list-skills`, diffed against
   `tests/sandbox/<product>/expected-skills.txt`. Catches load-time
   errors (broken symlinks, plugin.json drift, missing hook files) that
   render-golden cannot see. No full execute-and-assert; that step is
   not on the roadmap because it requires mocking skill-side external
   dependencies.
9. **Render output determinism.** `agent-runtime render` output MUST
   NOT contain any per-run-varying value: no wall-clock timestamps, no
   PIDs, no random numbers, no HashMap iteration order. Implementation
   constraints:
   - Tera context entry points use `IndexMap` (preserve-insertion-order)
     or `BTreeMap` (lexicographic). Bare `HashMap` is rejected by a
     clippy lint inside `agent-runtime-cli` and `nils-common`.
     Iteration order leaks into render output, so the convention is
     enforced at compile-time rather than by convention only.
   - The only sanctioned time-shaped value in rendered output is the
     source commit timestamp obtained from `git log -1 --format=%cI
     HEAD` at render start; helpers never read `SystemTime::now()` or
     `chrono::Utc::now()`. A clippy lint blocks those imports inside
     helper modules.
   - The render-golden CI gate doubles as a determinism check: any
     helper that introduces non-deterministic output diffs the
     pinned snapshots and fails the gate.
   - Cross-process determinism is verified by a second test that
     deletes `.render-cache.json` before re-render and asserts a
     zero diff against the snapshot.

   See [Build And Render Output](#build-and-render-output) for the
   downstream consumer (golden snapshots, install-time cache).
10. **Codex adapter is source-organisation only.** `targets/codex/`
    holds plugin / marketplace / `.codex-plugin/plugin.json` files
    purely as an authoring abstraction shared with the Claude side.
    Runtime-kit plugin metadata is not loaded by Codex; active local skills
    are exposed as domain-nested folders under `~/.codex/skills`, alongside
    `~/.codex/AGENTS.md` and the `agent-runtime-kit` managed block inside
    `~/.codex/config.toml`.
    Implications:
    - `audit-drift` validates `.codex-plugin/plugin.json` against the
      local schema only — there is no upstream Codex registry to diff
      against.
    - `install` for Codex does not depend on plugin packages; the active
      plan exposes skills under `$CODEX_HOME/skills`, syncs the
      `config.toml` managed block, installs hook scripts under
      `$CODEX_HOME/hooks/<name>/`, and retains `$CODEX_HOME/plugins`
      metadata for audit/compatibility only.
    - PR review must not flag "missing Codex marketplace entry" as a
      defect; the marketplace concept is local-only.
    - Phase 4 estimates for Codex domains exclude any "plugin
      packaging" work because there is no Codex-side packaging step.

    Revisit this decision if Codex publishes an official plugin
    manifest spec or marketplace API. Until then, see
    [Codex Activation Surface](#codex-activation-surface-reality-check)
    for the full reality check.

## Open Questions

Longer-term, not POC-blocking:

- Which domains should stay private because they include company or local
  workspace assumptions?
- Should Codex use plugin-first packaging for all domains, or keep multi-level
  skill roots for some local-only workflows?
- Should Claude flat root skills become generated adapters from plugin/core
  source, or stay hand-maintained?
- Marketplace strategy (Claude-side only): public `marketplace.json`
  published from this repo, or remain local-only with publishing
  handled by per-product downstream repos? Codex has no marketplace
  concept and is settled by Resolved Decision #10.
- Public face: does any subset of `core/` eventually get extracted into a
  new public repo, or does `agent-runtime-kit` stay fully private?

## Next Session Checklist

1. Confirm this target architecture (Resolved Decisions block included).
2. Confirm the first POC domain is `reporting`.
3. Snapshot nils-cli's current binary surface + semver into a frozen
   reference (e.g. `docs/source/nils-cli-surface.md`) so manifest authors
   write `required_clis` against a stable list.
4. Draft the manifest schemas (`skills.yaml`, `plugins.yaml`,
   `product-capabilities.yaml`, `runtime-roots.yaml`, `cli-tools.yaml`)
   with `schema_version: 1`, including `required_clis` and
   `state_out_mode` fields.
5. Open `nils-cli/crates/agent-runtime-cli/` (cargo new from
   `crates/cli-template/`); register the binary in the workspace
   `Cargo.toml`; stub all subcommands (`render`, `install`, `uninstall`,
   `doctor`, `audit-drift`, `gc-backups`, `restore-backups`,
   `purge-state`) so the CLI contract is reviewable before logic lands.
   Match the enumeration in Resolved Decision #2 and Phase 1.
6. Inside `agent-runtime-cli`, register the Tera helpers (`script`,
   `skill_ref`, `state_out` with runtime/literal modes, `cli_ref`); wire
   them to `nils-common` paths and `agent-out` invocation.
7. Migrate `CLI_TOOLS.md` from `agent-kit` into
   `core/policies/cli-tools.md` and derive `manifests/cli-tools.yaml`
   (profile-keyed brew formula list) so `scripts/setup.sh` and
   `agent-runtime doctor` can both read it.
8. Land `scripts/setup.sh` (macOS + Linux): brew tap → install nils-cli
   (which now ships `agent-runtime`) → clone agent-runtime-kit → install
   profile-selected CLI_TOOLS → invoke `agent-runtime install` per
   product.
9. Cut a `0.12.0` nils-cli release on `sympoies/homebrew-tap` with
   the stub `agent-runtime` binary so the bootstrap path is verified
   before content migration starts.
10. Import the current reporting-domain source files from `agent-kit`
    and `claude-kit`; rewrite bodies to call nils-cli where applicable;
    log extraction candidates for any inline logic.
11. Add `agent-runtime render` + `agent-runtime audit-drift` logic for
    the pilot domain only.
12. Validate without mutating live `~/.codex` or `~/.claude` until the
    dry-run output is reviewed.
