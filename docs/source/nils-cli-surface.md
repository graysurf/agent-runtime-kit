# nils-cli Surface Snapshot

- Snapshot date: 2026-06-04 (refreshed for `v1.0.8`)
- Source repo: [`sympoies/nils-cli`](https://github.com/sympoies/nils-cli) (main)
- Source command: `ls crates/` and `bash scripts/workspace-bins.sh` in the
  `sympoies/nils-cli` release worktree
- Active `git describe --tags` output: `v1.0.8`
- Machine-readable pin for the CI gate: `docs/source/nils-cli-pin.yaml`
  (`pinned_tag: v1.0.8`), consumed by `scripts/ci/all.sh` Position 2 via
  `agent-runtime doctor --class version-alignment`. Keep that `pinned_tag`
  and the `Active git describe --tags output:` line above in lock-step.
- Head commit: `2851e86`
  (`chore(release): bump cli versions to 1.0.8 (#769)`)
- Release:
  [`v1.0.8`](https://github.com/sympoies/nils-cli/releases/tag/v1.0.8),
  Homebrew tap formula at `Formula/nils-cli.rb` on `sympoies/homebrew-tap`
  `main`
- `v1.0.8` is a **patch** over `fzf-cli def` on Linux: the generated preview
  script temp file is flushed and converted to a closed `TempPath` before fzf's
  preview shell executes it, avoiding `zsh: text file busy` in container TTYs
  ([#768](https://github.com/sympoies/nils-cli/pull/768),
  [#769](https://github.com/sympoies/nils-cli/pull/769)). Additive runtime
  bug fix only — no consumed flag or JSON envelope changed and no
  `required_clis[]` floor moves.
- `v1.0.7` ships the new `zsh-kit` binary, whose `setup` subcommand clones or
  updates an operator-supplied Zsh repo URL/path and dispatches that repo's
  public setup hook (`bootstrap/zsh-kit-setup.zsh` or `.zsh-kit/setup.zsh`) in
  dry-run or apply mode
  ([#763](https://github.com/sympoies/nils-cli/pull/763),
  [#765](https://github.com/sympoies/nils-cli/pull/765)). This repo's Docker
  surface consumes it for runtime shell setup, so `zsh-kit >= 1.0.7` is added
  to `required_clis[]`.
- `v1.0.6` is a **patch** over `git-cli worktree remove`: when the remove
  target is not found but exactly matches a live linked worktree branch name,
  `git-cli` now returns a recovery hint pointing at the managed slug and full
  path, and text-mode errors print hints on stderr instead of hiding them in
  JSON-only output
  ([#760](https://github.com/sympoies/nils-cli/pull/760)). Additive — this
  repo's consumers already remove managed worktrees by slug or path, so no
  `required_clis[]` floor moves.
- `v1.0.4` adds a `--kind <feature|bug|chore|docs|ci|refactor>` flag to
  `git-cli worktree add` (default `feature`, so the prior `feat/<slug>` behavior
  is unchanged), deriving the branch as `<prefix>/<slug>` where the prefix is
  the one `forge-cli pr deliver/create --kind` already enforces
  (`feature->feat/`, `bug->fix/`, `chore->chore/`, `docs->docs/`, `ci->ci/`,
  `refactor->refactor/`). The kind set and its prefix mapping now live once in
  `nils_common::git::PrKind`; `forge-cli`'s `branch_kind` rule re-exports that
  type and compares `branch_prefix()` instead of a duplicate pairing, so the two
  tools can no longer drift. A worktree opened with `--kind bug` now delivers
  cleanly under `--kind bug` with no rename step
  ([#751](https://github.com/sympoies/nils-cli/pull/751)). This repo documents
  the flag in `core/policies/git-delivery.md`; it is policy guidance, not yet an
  automated skill invocation, so the `git-cli` `required_clis[]` floor does not
  move.
- `v1.0.3` adds a repeatable `--label` flag to `heuristic-inbox deliver`
  ([#748](https://github.com/sympoies/nils-cli/pull/748)), forwarded verbatim to
  `forge-cli pr create --label`, so records-branch PRs can carry taxonomy
  labels. `heuristic-session-closeout` consumes it with
  `--label workflow::heuristic-records` plus a fixed title, so the
  `heuristic-inbox >= 1.0.3` `required_clis[]` floor and the `heuristic-system`
  surface `min_nils_cli` (`v1.0.3`) are set.
- `v1.0.2` adds the **`heuristic-inbox deliver`** subcommand: a cwd-independent
  records-branch PR writeback for uncommitted heuristic-system records (fetch
  `origin/<base>` → managed worktree on a `<prefix>/<slug>` branch matching
  `--kind` → stage only the heuristic-system root → `semantic-commit` → push →
  `forge-cli pr create`), returning `branch` / `pr_url` / `committed_paths` /
  `worktree_path` in a `cli.heuristic-inbox.deliver.v1` envelope with `--dry-run`
  plan rendering. This is the deterministic replacement for the
  `heuristic-session-closeout` skill-prose writeback delivered in #237, and the
  closeout skill now consumes it, so the `heuristic-inbox >= 1.0.2`
  `required_clis[]` floor and the `heuristic-system` surface `min_nils_cli`
  (`v1.0.2`) are set
  ([#745](https://github.com/sympoies/nils-cli/pull/745)).
- `v1.0.1` adds the **execution-state synchronization** surface consumed by the
  plan-tracking skills: `plan-issue record open` writes the tracking issue URL
  into the bundle `*-execution-state.md`; `record close --bundle` writes the
  terminal state back; `tracking checkpoint --live` reconciles and self-heals
  the `Tracking issue` bullet while `tracking close-ready` gates it
  (`execution-state-issue-missing` / `-mismatch`); and `plan-tooling
  exec-state-sync` repairs existing bundles offline
  ([#741](https://github.com/sympoies/nils-cli/pull/741)).
- `v1.0.0` is the **major** naming-convention milestone: the workspace
  finalizes the `crate dir == binary base` / `package == nils-<dir>`
  convention and drops the `-cli` suffix from three crate directories.
  `agent-runtime-cli` → `agent-runtime`, `memo-cli` → `memo` (crate, binary,
  and the `cli.memo.*` JSON contract), and `plan-issue-cli` → `plan-issue`
  (crate, package, library, and the JSON output contract namespace — now
  `plan-issue.*`, renamed from the prior `plan-issue-cli.*` with no backward
  compatibility). Binary names are unchanged (`agent-runtime`, `memo`,
  `plan-issue` / `plan-issue-local`). This repo consumes the renamed
  `plan-issue.*` envelope in its runtime-smoke `dispatch` / `pr` cases; the
  `agent-runtime` doctor envelope (`agent-runtime-cli.doctor.v1`) was **not**
  renamed and is unchanged
  ([#735](https://github.com/sympoies/nils-cli/pull/735),
  [#736](https://github.com/sympoies/nils-cli/pull/736)).
- `v0.31.8` is a **patch** that adds the `plugin-manifest-skills` block-tier
  drift class to `agent-runtime audit-drift`: for every Codex
  `targets/codex/plugins/<domain>/.codex-plugin/plugin.json` whose domain has a
  `plugins.yaml` plugin, the advertised `skills[]` entries must mirror that
  plugin's `contained_skills` and each entry's `source` must match
  `skills.yaml` and resolve to a directory on disk. This repo consumes
  `agent-runtime audit-drift` in `scripts/ci/all.sh`; the class closes the gap
  that let `#220`'s renamed-skill `plugin.json` entry ship green (this repo's
  `#225`). Additive — no flag or envelope changed and no `required_clis[]`
  floor moves
  ([#725](https://github.com/sympoies/nils-cli/pull/725),
  [#726](https://github.com/sympoies/nils-cli/pull/726)).
- `v0.31.7` is a **patch** that ships the `forge-cli search` surface —
  `search issues` / `search prs` (GitHub full-text via `gh search`) and
  `search refs-to <ref>` (cross-reference events via `gh api graphql`), all
  GitHub-only behind the provider seam, single-repo scoped, with three
  versioned envelopes (`cli.forge-cli.search.{issues,prs,refs-to}.v1`) — and
  the `forge-cli activity` discovery surface from `v0.31.6`'s follow-up. Both
  are additive: this repo's skills consume the unchanged `forge-cli`
  `pr` / `issue` / `inbox` surfaces, so no `required_clis[]` floor moves. No
  surface was retired or renamed
  ([#721](https://github.com/sympoies/nils-cli/pull/721),
  [#722](https://github.com/sympoies/nils-cli/pull/722),
  [#723](https://github.com/sympoies/nils-cli/pull/723),
  [#724](https://github.com/sympoies/nils-cli/pull/724)).
- `v0.31.6` is a **patch** that adds an opt-in fail-closed `agent-docs
  preflight --require-declared-intent` guard for callers that already know the
  requested intent must be declared. Guarded undeclared intents return exit 65
  with a stable `undeclared-intent` JSON error envelope; unguarded preflight
  keeps the compatible document-only fallback. This repo consumes that surface
  in the prompt preflight and finish-line hooks, so the `agent-docs`
  `required_clis[]` floor moves to `0.31.6`. No surface was retired or renamed
  ([#719](https://github.com/sympoies/nils-cli/pull/719),
  [#720](https://github.com/sympoies/nils-cli/pull/720)).
- `v0.31.5` is a **patch** that publishes the Sprint 1 `git-cli worktree`
  surface: `git-cli worktree add/list/remove/prune` manages repo-scoped
  worktrees under `$AGENT_HOME/worktrees/<repo-key>/<branch-slug>` with text
  and JSON output, shares the worktree parser/removal path with
  `branch cleanup --remove-worktrees`, and includes completion coverage. This
  repo consumes that surface through the worktree policy and hook exception
  shipped in agent-runtime-kit#213, so the `git-cli` `required_clis[]` floor
  moves to `0.31.5`. No surface was retired or renamed
  ([#715](https://github.com/sympoies/nils-cli/pull/715),
  [#718](https://github.com/sympoies/nils-cli/pull/718)).
- `v0.31.4` is a **patch** that fixes the canonical `plan-issue tracking
  checkpoint --post state` bundle-backed ledger path: `tracking run init` stores
  absolute bundle / execution-state refs, state readers resolve the full
  `## Task Ledger` from the bundle when `execution_state_file` is absent, and a
  recorded-but-unreadable ledger now blocks with `state-ledger-unresolved`
  instead of silently rendering a synthesized single-row baseline. The
  plan-tracking workflows depend on this repaired state checkpoint behavior, so
  the `plan-issue` `required_clis[]` floor moves to `0.31.4`. No flag or JSON
  envelope was retired or renamed
  ([#713](https://github.com/sympoies/nils-cli/pull/713),
  [#714](https://github.com/sympoies/nils-cli/pull/714)).
- `v0.31.3` is a **patch** with two additive surface changes and no retired or
  renamed surfaces, so no consumer floor moves: `repo-retro` now auto-discovers
  the heuristic-system root (`heuristic-system/` then
  `core/policies/heuristic-system/`, with a new `--heuristic-root` override) and
  summarizes nested `<slug>/ENTRY.md` inbox cases, so the `## HEURISTIC_SYSTEM`
  report section is correct for `core/policies`-nested roots like this repo
  ([#706](https://github.com/sympoies/nils-cli/pull/706)); and `forge-cli`
  `--provider` gains a `local` file-backed backend value plus a `--store-root`
  flag (and the `FORGE_CLI_LOCAL_STORE` env var), with the `github` / `gitlab`
  provider surfaces unchanged
  ([#705](https://github.com/sympoies/nils-cli/pull/705),
  [#707](https://github.com/sympoies/nils-cli/pull/707)).
- `v0.31.2` is a **patch** fixing plan-tracking dashboard/state staleness:
  `tracking checkpoint` now derives the state payload's `current` /
  `next_action` / `target_scope` from the durable `## Task Ledger` plus the
  authored scope, and re-renders the visible Execution State header from that
  payload, so a completed plan's Final Dashboard and state comment no longer
  show pre-flight values. Internal rendering only — no surface retired or
  renamed, no consumer floor moves
  ([#702](https://github.com/sympoies/nils-cli/pull/702),
  [#703](https://github.com/sympoies/nils-cli/pull/703)).
- `v0.31.1` is a **patch** fixing `repo-retro` path classification: generated
  Markdown fixtures under `tests/golden/**` (and test-tree files) now classify
  as `tests` instead of `productDocs`, so a single skill edit is no longer
  triple-counted across `source` + `productDocs` in `churnByClass` /
  `fileHotspots`; `docs/specs` stays `productDocs`. Additive — no surface
  retired or renamed, no consumer floor moves
  ([#698](https://github.com/sympoies/nils-cli/pull/698)).
- `v0.31.0` is a **minor** that ships `repo-retro report` **schema v2**
  (`cli.repo-retro.report.v2` / `repo-retro.report.v2`): a deterministic
  pre-digestion layer — `git.churnByClass` (source / tests / productDocs /
  processArtifacts / other, reconciling to the summary total), `git.archival`
  (net-deletion as the primary signal), and commit-frequency
  `fileHotspots.topFiles` carrying `class` / `netDeleted` — plus a
  `--path-class-config` override. The analysis layer now reads that class split
  and never nominates a net-deleted file for review. The v1 envelope was
  removed (breaking), so the `project-retro` consumer moves to v2 in lock-step;
  no `required_clis[]` floor moves (`repo-retro` is not a floored binary)
  ([#694](https://github.com/sympoies/nils-cli/pull/694)).
- `v0.30.2` is a **patch** that extends the `plan-archive` body / full-text
  search surface: `catalog --deep` extends `--grep` to also match issue / PR /
  MR body and comment text (via each ref's latest snapshot), and a new
  `plan-archive search <term>` subcommand returns hit-level results (owning plan
  slug + ref URL + matched field + snippet) in a versioned JSON envelope. Both
  are additive — no surface was retired or renamed, so no consumer floor moves
  ([#690](https://github.com/sympoies/nils-cli/pull/690),
  [#691](https://github.com/sympoies/nils-cli/pull/691)).
- `v0.30.1` is a **patch** over the `v0.30.0` `agent-docs` redesign: a docs-home
  catalog's `scope = "project"` documents and its (scopeless, repo-local)
  `[[validation]]` contracts are now scoped to the declaring repository — they
  no longer leak into unrelated projects' `preflight` / `audit` / `explain`
  ([#685](https://github.com/sympoies/nils-cli/pull/685),
  [#686](https://github.com/sympoies/nils-cli/pull/686)). The finish-line
  validation gate in agent-runtime-kit#181 depends on this scoping, so the
  `agent-docs` `required_clis` floor moves to `0.30.1`.
- `v0.30.0` was a **breaking** bump: the `agent-docs` engine was redesigned to be
  fully data-driven. It retires the `resolve` / `baseline` / `scaffold-*` /
  `add` / `contexts` commands and the `startup` per-task context, and removes
  all hardcoded builtin requirements; required docs plus the per-repo validation
  contract are declared in `AGENT_DOCS.toml` (`[[document]]` + `[[validation]]`,
  with real `when` predicates and content validation). The new surface is
  `audit` / `preflight --intent X` (versioned `agent-docs.preflight.v1` JSON) /
  `init` / `explain` / `list` / `remove`, with docs-home derived from the
  install symlink. This is the surface adopted in agent-runtime-kit#181
  ([#671](https://github.com/sympoies/nils-cli/pull/671),
  [#674](https://github.com/sympoies/nils-cli/pull/674)).
- Prior pin: `v0.29.0` at `0f757df` (`chore(release): bump cli versions to
  0.29.0 (#661)`). `v0.29.1` is a patch bump hardening the same
  `git-cli branch cleanup --squash` path: branches with no merge-base against
  base (unrelated / orphan history) are now skipped instead of aborting the
  whole sweep, so a repo with orphan fixture branches can be cleaned
  ([#668](https://github.com/sympoies/nils-cli/pull/668)). No consumed flag or
  JSON envelope changed; `required_clis[]` floors are unchanged. The `v0.29.1`
  tag sits on `9681bb8`: the `0.29.1` bump (#669) was re-tagged after a docs
  table-alignment fix (#670). Further prior pin: `v0.28.6` at `67cb08b`
  (`chore(release): bump cli versions to 0.28.6 (#659)`). `v0.29.0` is a minor
  bump with one consumed-surface change:
  `git-cli branch cleanup --squash` (and `--remove-worktrees`, which only acts
  on detected branches) now detects multi-commit provider squash-merges by
  synthesizing the branch's diff as a single commit on its merge-base and
  patch-comparing against base, where a per-commit `git cherry` previously
  missed them
  ([#660](https://github.com/sympoies/nils-cli/pull/660)). No consumed surface
  was retired or renamed and no flags or JSON envelopes changed;
  `required_clis[]` floors are unchanged because no agent-runtime-kit consumer
  depends on the new behavior. Further prior pin: `v0.28.5` at `49f925b`
  (`chore(release): bump cli versions to 0.28.5 (#656)`). `v0.28.6` is an
  additive patch bump with one consumed
  surface: `agent-docs` now lets a project opt out of a non-`startup` built-in
  requirement by declaring a matching `[[document]]` entry with
  `required = false` for the built-in's own `(context, scope, path)` key in
  its `AGENT_DOCS.toml`; the built-in is downgraded to optional in `resolve`
  and `baseline --check` with `source = builtin-opt-out` (so it drops out of
  `missing_required` while staying auditable). `startup` cannot be opted out
  and a home catalog cannot opt an unrelated project out
  ([#658](https://github.com/sympoies/nils-cli/pull/658)). No consumed surface
  was retired or renamed; `required_clis[]` floors are unchanged because no
  agent-runtime-kit consumer depends on the new surface yet. Further prior pin:
  `v0.28.4` at `6335148` (`chore(release): bump cli versions to
  0.28.4 (#654)`). `v0.28.5` is an additive patch bump with one consumed
  surface: `plan-archive migrate` now reconciles an archived plan's
  `*-execution-state.md` `## Execution State` header to a terminal "archived"
  status that defers to the issue/PR ref (rewrites the `Status` / `Current
  task` / `Next task` bullets and drops their wrapped continuation lines; all
  other bundle files copy verbatim), and the apply report gains
  `execution_state_reconciled`
  ([#655](https://github.com/sympoies/nils-cli/pull/655)). No consumed surface
  was retired or renamed; `required_clis[]` floors are unchanged because the
  `meta:plan-archive-migrate` consumer needs no new surface. `v0.28.4` was an
  additive patch bump adding two consumed
  surfaces: `plan-issue record restore` re-materializes a tracking issue's
  `source` / `plan` snapshot comments back into bundle files (latest-per-role,
  online or offline `--comments-json`, non-destructive unless `--force`), the
  inverse of `record open`
  ([#652](https://github.com/sympoies/nils-cli/pull/652)); and `forge-cli pr
  deliver --dry-run` now runs the non-mutating lock-down rules and reports each
  verdict in an additive `data.local_preflight[]` block (no provider backend),
  body-section validation aggregates into one `body_missing_sections` error
  when both are missing, and `agent-runtime pr-body render --kind` covers all
  six deliver kinds with a scaffold pointer in the body-missing errors
  ([#653](https://github.com/sympoies/nils-cli/pull/653)). No consumed surface
  was retired or renamed; `required_clis[]` floors are unchanged because no
  agent-runtime-kit consumer depends on the new surfaces yet. `v0.28.3` was an
  additive patch bump for the dispatch
  `tracking checkpoint` lifecycle: `tracking checkpoint --live` now inherits
  `repo`/`issue` from the run-state when `--provider-repo`/`--issue` are
  omitted, so the documented dispatch entrypoint posts instead of silently
  no-opping ([#644](https://github.com/sympoies/nils-cli/pull/644)); and
  `tracking checkpoint --post session` synthesizes the session summary from
  run-state activity (selected task, branch, linked PRs, validation, phase)
  when no explicit note exists, instead of dropping the role
  ([#645](https://github.com/sympoies/nils-cli/pull/645)). The release tooling
  also re-pins only workspace versions in the lockfile refresh
  ([#646](https://github.com/sympoies/nils-cli/pull/646), not a consumed
  surface). No consumed surface was retired or renamed. `v0.28.2` made the
  dispatch-profile dashboard name every lane PR: `plan-issue` accumulates each
  lane's linked PR into the state-checkpoint payload `prs[]`, so the dispatch
  dashboard's Linked PRs field lists every lane PR instead of `none yet`
  ([#642](https://github.com/sympoies/nils-cli/pull/642)). `v0.28.1` added the
  `plan-issue record post --task-ledger-display open` mode plus the
  `record open` open-fold default for the first Execution State
  ([#640](https://github.com/sympoies/nils-cli/pull/640)), `profile=dispatch`
  markers on dispatch `tracking checkpoint` lifecycle comments
  ([#639](https://github.com/sympoies/nils-cli/pull/639)), and the new
  `agent-memory` CLI ([#638](https://github.com/sympoies/nils-cli/pull/638),
  not consumed by this repo). Earlier release history retained below.
  `v0.25.8` at `4d0d621`
  (`chore(release): bump cli versions to 0.25.8 (#608)`). `v0.28.0` spans the
  v0.25.9–v0.28.0 releases and adds: the
  `agent-runtime doctor --class version-alignment` surface
  ([#636](https://github.com/sympoies/nils-cli/pull/636)) — now consumed by
  this repo's `scripts/ci/all.sh` Position 2 through
  `docs/source/nils-cli-pin.yaml`; build metadata in the `agent-runtime
  --version` output (#625); the new `nils-build-info` library crate; and the
  `plan-issue` accumulative state payload tasks ledger (#633). Earlier release
  history retained below. `v0.25.7` at `0c070f8` (`feat(plan-tooling):
  per-task ledger durability (0.25.7) (#607)`); `v0.25.8` is a workspace-wide
  lock-step bump that catches the 31 crates skipped by the v0.25.7 partial release
  (`agent-runtime-cli`, `forge-cli`, `semantic-commit`, the `api-*` and
  `git-*` families, the rest) up to the workspace floor, restoring the
  convention from `1edf007` that every release tag matches every crate's
  `Cargo.toml` version. No new consumed surface relative to v0.25.7. The
  v0.25.7 entry remains the source of the `plan-tooling ledger-update`
  and `plan-tooling ledger-sync --from-issue` subcommands plus the
  `ledger-rows-pending` blocker on `plan-issue tracking close-ready`
  (read-mostly drift reconciliation against issue lifecycle evidence;
  one-call row patching for the canonical `*-execution-state.md`
  ledger; refuses ready handoff while a ledger row remains `pending`
  or `in-progress` at `phase=ready_for_close`). Consumed by the four
  tracking-profile SKILL bodies plus the `conversation:handoff-session-prompt`
  guidance. `v0.25.6` lands live posting in `plan-issue tracking
  checkpoint --live --post <roles> --repair-dashboard` (one provider
  comment per role, fixture-mode parity for deterministic tests, abort
  on first per-role failure) consumed by the
  `dispatch:deliver-plan-tracking-issue` close-ready handoff and the
  `dispatch:plan-tracking-issue-closeout` preflight-repair pass.
  `v0.25.5` adds the `plan-archive discover` read-only candidate
  scanner consumed by the `meta:plan-archive-discover` skill. `v0.25.0`
  introduced the `plan-archive` binary with the `migrate`, `refresh`, and
  `query` subcommands (plus the `validate-hosts`, `validate-local`,
  `validate-metadata` validators) consumed by the
  `meta:plan-archive-migrate` and `meta:plan-archive-query` skills.

This file is the human-readable pin source for `required_clis` placeholders
in `manifests/skills.yaml` and `manifests/plugins.yaml`. Manifest authors
should reference binary names from the **Binary** column when declaring
`required_clis`, and refresh this snapshot at every nils-cli release that
changes a consumed surface. The machine-readable pin the CI gate enforces
lives in `docs/source/nils-cli-pin.yaml`; the `meta:nils-cli-bump` skill
keeps both in sync on a release bump.

Notes on derivation:

- The **Crate** column lists every directory currently under
  `crates/` in the source repo (36 entries).
- The **Binary** column lists every binary the crate produces. Library
  crates show `(library only)`. Crates that ship more than one binary
  enumerate them comma-separated.
- The **Notes** column captures intent: stub status, multi-binary
  fanout, library-only role, or other manifest-author-facing context.

## Crate → binary table

| Crate                       | Binary                                                                                                              | Notes                                                                                                                                                                                                                                                                  |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `agent-docs`                | `agent-docs`                                                                                                        | Data-driven required-doc resolver and auditor; no hardcoded builtins. As of `v0.30.0` the surface is `audit` (repo health: install-symlink wiring + declared-doc presence/validity + catalog validity), `preflight --intent X` (resolve the doc set plus the per-repo validation contract as versioned `agent-docs.preflight.v1` JSON for hooks to inject and enforce), and `init` / `explain` / `list` / `remove`. Policy is declared in `AGENT_DOCS.toml` (`[[document]]` + `[[validation]]`, `when` predicates, content validation); docs-home is derived from the install symlink. As of `v0.30.1`, a docs-home catalog's `scope = "project"` documents and its `[[validation]]` contracts are scoped to the declaring repository, so they never leak into unrelated projects. As of `v0.31.6`, `preflight --require-declared-intent` lets known-intent callers fail closed for undeclared intent names while preserving the unguarded compatibility fallback. The `resolve` / `baseline` / `scaffold-*` / `add` / `contexts` commands and the `startup` per-task context were retired in the redesign.                                                                                                  |
| `agent-memory`              | `agent-memory`                                                                                                      | Agent memory helper. Not consumed by this repo's runtime surfaces today.                                                                                                                                                                                               |
| `agent-out`                 | `agent-out`                                                                                                         | Agent output / artifact helper.                                                                                                                                                                                                                                        |
| `agent-runtime`         | `agent-runtime`                                                                                                     | Runtime kit CLI. As of `v0.20.0`, this repo consumes released `render`, `install`, `uninstall`, `doctor` (including `--class skill-surface --product codex`), `audit-drift`, `gc-backups`, `restore-backups`, `purge-state`, and `pr-body render` bodies through Homebrew. The `pr-body render` surface renders standardized feature / bug PR and MR bodies before `forge-cli pr create` / `forge-cli pr deliver`. As of `v0.22.4`, `sync-runtime-surfaces` consumes `agent-runtime prune-stale` to remove stale managed Codex and Claude skill surfaces after install. As of `v0.28.0`, ships `doctor --class version-alignment --pin <manifest>` (the surface-pin drift gate this repo's Position 2 consumes via `docs/source/nils-cli-pin.yaml`) and adds build metadata to the `agent-runtime --version` output. As of `v1.0.5`, `render` reconciles `build/<product>/` for retired skills — a skill removed from the manifest has its outputs and `.render-cache.json` entry dropped on the next render, so `sync-runtime-surfaces` + `prune-stale` no longer leave the retired skill in the live home ([#755](https://github.com/sympoies/nils-cli/pull/755)); `audit-drift` also gains `--json` / `--fail-on` and skips path/slug runs in entropy ([#754](https://github.com/sympoies/nils-cli/pull/754)). |
| `agent-scope-lock`          | `agent-scope-lock`                                                                                                  | Workspace scope-lock helper.                                                                                                                                                                                                                                           |
| `agent-workflow-primitives` | `agent-run`, `browser-session`, `canary-check`, `docs-impact`, `heuristic-inbox`, `model-cross-check`, `review-evidence`, `review-specialists`, `repo-retro`, `skill-usage`, `test-first-evidence` | Multi-binary crate. Each binary is its own clap CLI; manifests should pin individual binary names, not the crate. As of `v0.20.0`, `agent-run exec` normalizes project command execution through explicit `.envrc` / `.env` decisions. As of `v0.31.0`, `repo-retro report` emits schema v2 (`cli.repo-retro.report.v2` / `repo-retro.report.v2`): a deterministic pre-digestion layer (`git.churnByClass`, `git.archival`, commit-frequency `fileHotspots` with `class` / `netDeleted`) plus a `--path-class-config` override; the v1 envelope was removed (breaking). As of `v0.31.3`, `repo-retro report` auto-discovers the heuristic-system root (`heuristic-system/` then `core/policies/heuristic-system/`) with a `--heuristic-root` override and summarizes nested `<slug>/ENTRY.md` inbox cases, so the `## HEURISTIC_SYSTEM` section reports `present` with real counts for `core/policies`-nested roots like this repo (additive). As of `v1.0.2`, `heuristic-inbox` gains a `deliver` subcommand: a cwd-independent records-branch PR writeback for uncommitted heuristic-system records (`--root` / `--kind` / `--base` / `--dry-run`, `cli.heuristic-inbox.deliver.v1` envelope with `branch` / `pr_url` / `committed_paths` / `worktree_path`), the deterministic replacement for the `heuristic-session-closeout` skill-prose writeback (#237). As of `v1.0.3`, `deliver` gains a repeatable `--label` flag (forwarded to `forge-cli pr create --label`); `heuristic-session-closeout` consumes `deliver --label workflow::heuristic-records` with a fixed title, so `required_clis[]` carries `heuristic-inbox >= 1.0.3` and the `heuristic-system` surface `min_nils_cli` is `v1.0.3`. |
| `api-gql`                   | `api-gql`                                                                                                           | GraphQL API testing CLI.                                                                                                                                                                                                                                               |
| `api-grpc`                  | `api-grpc`                                                                                                          | gRPC API testing CLI.                                                                                                                                                                                                                                                  |
| `api-rest`                  | `api-rest`                                                                                                          | REST API testing CLI.                                                                                                                                                                                                                                                  |
| `api-test`                  | `api-test`                                                                                                          | API testing orchestrator.                                                                                                                                                                                                                                              |
| `api-testing-core`          | (library only)                                                                                                      | Shared core for the `api-*` CLIs; never appears in `required_clis`.                                                                                                                                                                                                    |
| `api-websocket`             | `api-websocket`                                                                                                     | WebSocket API testing CLI.                                                                                                                                                                                                                                             |
| `cli-template`              | `cli-template`                                                                                                      | Internal template/example crate. Marked `excluded` in `docs/specs/completion-coverage-matrix-v1.md`; manifests should not pin against it.                                                                                                                              |
| `codex-cli`                 | `codex-cli`                                                                                                         | Codex runtime helper. Alias family `cx*` ships in `aliases.zsh` / `aliases.bash`.                                                                                                                                                                                      |
| `forge-cli`                 | `forge-cli`                                                                                                         | Forge runtime helper. As of `v0.20.0`, this repo consumes released PR create/deliver/check/merge/comment and general issue create/view/comment/list surfaces. Issue-backed plan-record lifecycle mutation is owned by `plan-issue record`, not by composing `forge-cli issue` calls in dispatch skills. `v0.20.1` adds `forge-cli label list`, `label audit`, and `label ensure` for GitHub/GitLab label catalogs, plus repeatable `--label`, `--label-catalog`, and `--strict-labels` on `pr create` and `pr deliver` so create/deliver macros preserve selected taxonomy labels. `v0.21.0` extends the `plan-issue record` surface with `--label` on `record open`, and `--add-label` / `--remove-label` on `record post` and `record close` so v3 lifecycle commands can apply taxonomy labels alongside issue creation, state transitions, and closeout. As of `v0.31.3`, `--provider` gains a `local` file-backed backend value plus a `--store-root` flag (and the `FORGE_CLI_LOCAL_STORE` env var) for offline rehearsal; the `github` / `gitlab` lifecycle surfaces are unchanged (additive). As of `v0.31.7`, `forge-cli` gains a GitHub-only `activity` discovery surface (`activity commits` / `events` / `summary`) and a `search` surface (`search issues` / `search prs` full-text via `gh search`, plus `search refs-to` cross-reference via `gh api graphql`), both behind the provider seam — GitLab / Local return `provider_unsupported`. Additive; not yet consumed by this repo's skills, so no `required_clis[]` floor moves. |
| `fzf-cli`                   | `fzf-cli`                                                                                                           | fzf wrapper. Alias family `fx*` ships in `aliases.zsh` / `aliases.bash`. As of `v1.0.8`, `fzf-cli def` closes the generated preview script temp file before fzf executes it, avoiding Linux `text file busy` failures in container TTYs. |
| `gemini-cli`                | `gemini-cli`                                                                                                        | Gemini runtime helper.                                                                                                                                                                                                                                                 |
| `git-cli`                   | `git-cli`                                                                                                           | git workflow helper. Alias family `gx*` ships in `aliases.zsh` / `aliases.bash`. As of `v0.31.5`, this repo consumes `git-cli worktree add/list/remove/prune` for managed worktrees under `$AGENT_HOME/worktrees/<repo-key>/<branch-slug>` with text and JSON output. As of `v1.0.4`, `worktree add` gains `--kind <feature\|bug\|chore\|docs\|ci\|refactor>` (default `feature`), deriving `<prefix>/<slug>` from the shared `nils_common::git::PrKind` mapping that `forge-cli`'s `branch_kind` rule also consumes, so a non-feature worktree matches the prefix `forge-cli pr deliver --kind` expects without a manual rename. As of `v1.0.6`, `worktree remove` detects when a not-found target exactly matches a linked worktree branch name and returns a hint pointing at the slug and full path; text-mode errors now print hints as well. Both changes are additive; the `v1.0.4` flag remains policy guidance rather than an automated skill invocation, and the `v1.0.6` hint is an ergonomic recovery path, so no `required_clis[]` floor moves. |
| `git-lock`                  | `git-lock`                                                                                                          | git lock helper.                                                                                                                                                                                                                                                       |
| `git-scope`                 | `git-scope`                                                                                                         | git scope summariser. Alias family `gs*` ships in `aliases.zsh` / `aliases.bash`.                                                                                                                                                                                      |
| `git-summary`               | `git-summary`                                                                                                       | git diff summariser.                                                                                                                                                                                                                                                   |
| `image-processing`          | `image-processing`                                                                                                  | User-facing image-processing CLI.                                                                                                                                                                                                                                      |
| `macos-agent`               | `macos-agent`                                                                                                       | macOS automation helper (AX, app intents).                                                                                                                                                                                                                             |
| `memo`                  | `memo`                                                                                                          | Memo storage CLI.                                                                                                                                                                                                                                                      |
| `nils-build-info`           | (library only)                                                                                                      | Build metadata helper for the workspace `--version` output; consumed transitively, never appears in `required_clis`. New crate as of `v0.28.0` (#625).                                                                                                                 |
| `nils-common`               | (library only)                                                                                                      | Shared workspace utilities; never appears in `required_clis`.                                                                                                                                                                                                          |
| `nils-markdown`             | `md-render`                                                                                                         | Shared Tera-backed Markdown template layer. Ships the `md-render` binary behind the `bin-cli` cargo feature (enumerated by `workspace-bins.sh`); library role otherwise, not consumed by any skill today. Present since before `v0.25.8`; the prior snapshot omitted it. |
| `nils-term`                 | (library only)                                                                                                      | Terminal / TTY helpers; never appears in `required_clis`.                                                                                                                                                                                                              |
| `nils-test-support`         | (library only)                                                                                                      | Integration-test harness; test-only, never appears in `required_clis`.                                                                                                                                                                                                 |
| `plan-archive`              | `plan-archive`                                                                                                      | Plan-archive workflow CLI. As of `v0.25.0`, ships `validate-hosts` / `validate-local` / `validate-metadata` validators, `migrate` (dry-run default, `--apply`), `refresh` (forge-cli payload fetch + secret-scrub + append-only `_index/` snapshots, holds commit for scrub-log review), and `query` (single-ref / cross-host aggregate / plan-link traversal). As of `v0.25.5`, adds `discover` (read-only candidate scanner that classifies plan folders as eligible / blocked / unknown and emits one combined `suggested_migrate_command` per eligible folder). As of `v0.28.5`, `migrate` reconciles an archived plan's `*-execution-state.md` `## Execution State` header (`Status` / `Current task` / `Next task`) to a terminal "archived" status deferring to the issue/PR ref, and the apply report adds `execution_state_reconciled`. As of `v0.30.2`, `catalog` gains `--deep` (extends `--grep` to also match issue/PR/MR body + comment text via each ref's latest snapshot, composing with `--area` / `--refs-to`) and a new `search <term>` subcommand returns hit-level matches (owning plan slug + ref URL + matched field + snippet) in a versioned JSON envelope; both are additive. Consumed by `meta:plan-archive-migrate`, `meta:plan-archive-query`, and `meta:plan-archive-discover`. |
| `plan-issue`            | `plan-issue`, `plan-issue-local`                                                                                    | Multi-binary crate. `plan-issue` is the GitHub-backed orchestrator; `plan-issue-local` is the local rehearsal pair. Manifests pin individual binary names. As of `v0.20.0`, issue-backed records use the provider-backed `record open`, `record post`, `record audit`, `record repair-dashboard`, and `record close` surface. The current marker is `plan-issue-record:v2 role=<source|plan|state|session|validation|review|closeout> profile=<tracking|dispatch>`. As of `v0.22.3`, state lifecycle comments can render canonical execution-state markdown through `record post --kind state --execution-state-file <path>`, support `--task-ledger-display auto|collapsed|expanded|open`, and render validation, review, session, and closeout evidence visibly alongside hidden payload carriers. As of `v0.25.6`, ships `record template --kind <role> --shape markdown|json` for non-mutating skeleton preview, `record audit --expect-visible` for visible-completeness lint, and the `tracking` controller surface (`tracking status`, `tracking run init`, `tracking run update`, `tracking checkpoint`, `tracking close-ready`) backed by `plan-issue.execution-run.v1` run state and `plan-issue.execution-event.v1` events. `tracking checkpoint --live --post <roles> --repair-dashboard` posts one provider lifecycle comment per role in declaration order, aborts on the first per-role failure with a `tracking-checkpoint-live-post-failed` blocker, and only refreshes the dashboard once every role succeeds; combine with `--fixture DIR` to exercise the live path deterministically (synthesized `fixture://issue/N/role` URLs and no provider mutation). As of `v0.25.7`, `tracking close-ready` emits a `ledger-rows-pending` blocker (one entry per stuck row) when `phase ∈ {ready_for_close, closed}` and the run-state's `bundle` resolves to a `*-execution-state.md` whose ledger still carries `Status ∈ {pending, in-progress}`; the silent-skip path keeps older run-states without a `bundle` field working. The `open` task-ledger-display mode renders an open `<details open>` fold (toggle present, rows visible by default), and `record open` posts the first Execution State with it so the full Task Ledger is visible on load while `expanded` stays raw rows for the final pre-closeout state. As of `v0.28.3`, `tracking checkpoint --live` inherits `repo`/`issue` from the run-state when `--provider-repo`/`--issue` are omitted (consistent with `tracking status` / `close-ready`), and `tracking checkpoint --post session` synthesizes the session summary from run-state activity (selected task, branch, linked PRs, validation, phase) when no explicit `--note` exists instead of silently dropping the role ([#644](https://github.com/sympoies/nils-cli/pull/644), [#645](https://github.com/sympoies/nils-cli/pull/645)). As of `v0.31.4`, bundle-backed state checkpoints resolve the full `## Task Ledger` from the recorded bundle when `execution_state_file` is absent, and recorded-but-unreadable ledgers block with `state-ledger-unresolved` instead of degrading silently. As of `v1.0.0`, the crate (`plan-issue`), package (`nils-plan-issue`), library, and the JSON output contract namespace dropped the `-cli` suffix — the contract is now `plan-issue.*` (for example `plan-issue.record.post.v2`, `plan-issue.start.plan.v2`, `plan-issue.tracking.status.v1`), renamed from `plan-issue-cli.*` with no backward compatibility. The run-state / event schemas (`plan-issue.execution-run.v1`, `plan-issue.execution-event.v1`) were already `-cli`-free and are unchanged. |
| `plan-tooling`              | `plan-tooling`                                                                                                      | Plan bundle linter / validator. As of `v0.25.7`, adds `ledger-update` (atomic one-call row patch for the canonical `*-execution-state.md` `## Task Ledger` table; stable error codes `ledger-row-not-found`, `ledger-row-ambiguous`, `ledger-table-malformed`, `ledger-status-invalid`) and `ledger-sync --from-issue` (read-mostly drift reconciliation against issue body + comments; `--write` patches only empty Evidence cells via the empty-cell preference rule). Both consumed by the tracking-profile SKILL bodies and by the `plan-issue tracking close-ready` `ledger-rows-pending` blocker. |
| `screen-record`             | `screen-record`                                                                                                     | Screen-recording helper (macOS).                                                                                                                                                                                                                                       |
| `semantic-commit`           | `semantic-commit`                                                                                                   | Semantic commit message validator and committer.                                                                                                                                                                                                                       |
| `web-evidence`              | `web-evidence`                                                                                                      | Web evidence capture helper.                                                                                                                                                                                                                                           |
| `zsh-kit`                   | `zsh-kit`                                                                                                           | Zsh setup helper. As of `v1.0.7`, this repo's Docker surface consumes `zsh-kit setup --repo <URL_OR_PATH> --dry-run|--apply` for operator-supplied runtime shell setup, with `--features`, `--install-tools`, and optional `.zshenv` management. |

## Refresh procedure

When `sympoies/nils-cli` cuts a new release that consumers should pin against:

1. Pull the latest `main` of `sympoies/nils-cli`.
2. Re-run `ls ~/Project/sympoies/nils-cli/crates/` to verify the crate list.
3. Re-run `bash scripts/workspace-bins.sh` (in the nils-cli checkout) to
   verify the binary list.
4. Re-run `git describe --tags` and update the header.
5. Replace any row whose binary set changed; add new rows alphabetically.
6. Bump the snapshot date and head commit pointer.
7. Manifest authors then refresh `required_clis` pins in
   `manifests/skills.yaml` / `manifests/plugins.yaml` against the new surface.
