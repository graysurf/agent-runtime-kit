# nils-cli Surface Snapshot

- Snapshot date: 2026-05-31 (refreshed for `v0.31.2`)
- Source repo: [`sympoies/nils-cli`](https://github.com/sympoies/nils-cli) (main)
- Source command: `ls crates/` and `bash scripts/workspace-bins.sh` in the
  `sympoies/nils-cli` release worktree
- Active `git describe --tags` output: `v0.31.2`
- Machine-readable pin for the CI gate: `docs/source/nils-cli-pin.yaml`
  (`pinned_tag: v0.31.2`), consumed by `scripts/ci/all.sh` Position 2 via
  `agent-runtime doctor --class version-alignment`. Keep that `pinned_tag`
  and the `Active git describe --tags output:` line above in lock-step.
- Head commit: `937e7b1`
  (`chore(release): bump cli versions to 0.31.2 (#704)`)
- Release:
  [`v0.31.2`](https://github.com/sympoies/nils-cli/releases/tag/v0.31.2),
  Homebrew tap formula at `Formula/nils-cli.rb` on `sympoies/homebrew-tap`
  `main`
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
  `crates/` in the source repo (34 entries).
- The **Binary** column lists every binary the crate produces. Library
  crates show `(library only)`. Crates that ship more than one binary
  enumerate them comma-separated.
- The **Notes** column captures intent: stub status, multi-binary
  fanout, library-only role, or other manifest-author-facing context.

## Crate → binary table

| Crate                       | Binary                                                                                                              | Notes                                                                                                                                                                                                                                                                  |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `agent-docs`                | `agent-docs`                                                                                                        | Data-driven required-doc resolver and auditor; no hardcoded builtins. As of `v0.30.0` the surface is `audit` (repo health: install-symlink wiring + declared-doc presence/validity + catalog validity), `preflight --intent X` (resolve the doc set plus the per-repo validation contract as versioned `agent-docs.preflight.v1` JSON for hooks to inject and enforce), and `init` / `explain` / `list` / `remove`. Policy is declared in `AGENT_DOCS.toml` (`[[document]]` + `[[validation]]`, `when` predicates, content validation); docs-home is derived from the install symlink. As of `v0.30.1`, a docs-home catalog's `scope = "project"` documents and its `[[validation]]` contracts are scoped to the declaring repository, so they never leak into unrelated projects. The `resolve` / `baseline` / `scaffold-*` / `add` / `contexts` commands and the `startup` per-task context were retired in the redesign.                                                                                                  |
| `agent-out`                 | `agent-out`                                                                                                         | Agent output / artifact helper.                                                                                                                                                                                                                                        |
| `agent-runtime-cli`         | `agent-runtime`                                                                                                     | Runtime kit CLI. As of `v0.20.0`, this repo consumes released `render`, `install`, `uninstall`, `doctor` (including `--class skill-surface --product codex`), `audit-drift`, `gc-backups`, `restore-backups`, `purge-state`, and `pr-body render` bodies through Homebrew. The `pr-body render` surface renders standardized feature / bug PR and MR bodies before `forge-cli pr create` / `forge-cli pr deliver`. As of `v0.22.4`, `sync-runtime-skills` consumes `agent-runtime prune-stale` to remove stale managed Codex and Claude skill surfaces after install. As of `v0.28.0`, ships `doctor --class version-alignment --pin <manifest>` (the surface-pin drift gate this repo's Position 2 consumes via `docs/source/nils-cli-pin.yaml`) and adds build metadata to the `agent-runtime --version` output. |
| `agent-scope-lock`          | `agent-scope-lock`                                                                                                  | Workspace scope-lock helper.                                                                                                                                                                                                                                           |
| `agent-workflow-primitives` | `agent-run`, `browser-session`, `canary-check`, `docs-impact`, `heuristic-inbox`, `model-cross-check`, `review-evidence`, `review-specialists`, `repo-retro`, `skill-usage`, `test-first-evidence` | Multi-binary crate. Each binary is its own clap CLI; manifests should pin individual binary names, not the crate. As of `v0.20.0`, `agent-run exec` normalizes project command execution through explicit `.envrc` / `.env` decisions. As of `v0.31.0`, `repo-retro report` emits schema v2 (`cli.repo-retro.report.v2` / `repo-retro.report.v2`): a deterministic pre-digestion layer (`git.churnByClass`, `git.archival`, commit-frequency `fileHotspots` with `class` / `netDeleted`) plus a `--path-class-config` override; the v1 envelope was removed (breaking). |
| `api-gql`                   | `api-gql`                                                                                                           | GraphQL API testing CLI.                                                                                                                                                                                                                                               |
| `api-grpc`                  | `api-grpc`                                                                                                          | gRPC API testing CLI.                                                                                                                                                                                                                                                  |
| `api-rest`                  | `api-rest`                                                                                                          | REST API testing CLI.                                                                                                                                                                                                                                                  |
| `api-test`                  | `api-test`                                                                                                          | API testing orchestrator.                                                                                                                                                                                                                                              |
| `api-testing-core`          | (library only)                                                                                                      | Shared core for the `api-*` CLIs; never appears in `required_clis`.                                                                                                                                                                                                    |
| `api-websocket`             | `api-websocket`                                                                                                     | WebSocket API testing CLI.                                                                                                                                                                                                                                             |
| `cli-template`              | `cli-template`                                                                                                      | Internal template/example crate. Marked `excluded` in `docs/specs/completion-coverage-matrix-v1.md`; manifests should not pin against it.                                                                                                                              |
| `codex-cli`                 | `codex-cli`                                                                                                         | Codex runtime helper. Alias family `cx*` ships in `aliases.zsh` / `aliases.bash`.                                                                                                                                                                                      |
| `forge-cli`                 | `forge-cli`                                                                                                         | Forge runtime helper. As of `v0.20.0`, this repo consumes released PR create/deliver/check/merge/comment and general issue create/view/comment/list surfaces. Issue-backed plan-record lifecycle mutation is owned by `plan-issue record`, not by composing `forge-cli issue` calls in dispatch skills. `v0.20.1` adds `forge-cli label list`, `label audit`, and `label ensure` for GitHub/GitLab label catalogs, plus repeatable `--label`, `--label-catalog`, and `--strict-labels` on `pr create` and `pr deliver` so create/deliver macros preserve selected taxonomy labels. `v0.21.0` extends the `plan-issue record` surface with `--label` on `record open`, and `--add-label` / `--remove-label` on `record post` and `record close` so v3 lifecycle commands can apply taxonomy labels alongside issue creation, state transitions, and closeout. |
| `fzf-cli`                   | `fzf-cli`                                                                                                           | fzf wrapper. Alias family `fx*` ships in `aliases.zsh` / `aliases.bash`.                                                                                                                                                                                               |
| `gemini-cli`                | `gemini-cli`                                                                                                        | Gemini runtime helper.                                                                                                                                                                                                                                                 |
| `git-cli`                   | `git-cli`                                                                                                           | git workflow helper. Alias family `gx*` ships in `aliases.zsh` / `aliases.bash`.                                                                                                                                                                                       |
| `git-lock`                  | `git-lock`                                                                                                          | git lock helper.                                                                                                                                                                                                                                                       |
| `git-scope`                 | `git-scope`                                                                                                         | git scope summariser. Alias family `gs*` ships in `aliases.zsh` / `aliases.bash`.                                                                                                                                                                                      |
| `git-summary`               | `git-summary`                                                                                                       | git diff summariser.                                                                                                                                                                                                                                                   |
| `image-processing`          | `image-processing`                                                                                                  | User-facing image-processing CLI.                                                                                                                                                                                                                                      |
| `macos-agent`               | `macos-agent`                                                                                                       | macOS automation helper (AX, app intents).                                                                                                                                                                                                                             |
| `memo-cli`                  | `memo-cli`                                                                                                          | Memo storage CLI.                                                                                                                                                                                                                                                      |
| `nils-build-info`           | (library only)                                                                                                      | Build metadata helper for the workspace `--version` output; consumed transitively, never appears in `required_clis`. New crate as of `v0.28.0` (#625).                                                                                                                 |
| `nils-common`               | (library only)                                                                                                      | Shared workspace utilities; never appears in `required_clis`.                                                                                                                                                                                                          |
| `nils-markdown`             | `md-render`                                                                                                         | Shared Tera-backed Markdown template layer. Ships the `md-render` binary behind the `bin-cli` cargo feature (enumerated by `workspace-bins.sh`); library role otherwise, not consumed by any skill today. Present since before `v0.25.8`; the prior snapshot omitted it. |
| `nils-term`                 | (library only)                                                                                                      | Terminal / TTY helpers; never appears in `required_clis`.                                                                                                                                                                                                              |
| `nils-test-support`         | (library only)                                                                                                      | Integration-test harness; test-only, never appears in `required_clis`.                                                                                                                                                                                                 |
| `plan-archive`              | `plan-archive`                                                                                                      | Plan-archive workflow CLI. As of `v0.25.0`, ships `validate-hosts` / `validate-local` / `validate-metadata` validators, `migrate` (dry-run default, `--apply`), `refresh` (forge-cli payload fetch + secret-scrub + append-only `_index/` snapshots, holds commit for scrub-log review), and `query` (single-ref / cross-host aggregate / plan-link traversal). As of `v0.25.5`, adds `discover` (read-only candidate scanner that classifies plan folders as eligible / blocked / unknown and emits one combined `suggested_migrate_command` per eligible folder). As of `v0.28.5`, `migrate` reconciles an archived plan's `*-execution-state.md` `## Execution State` header (`Status` / `Current task` / `Next task`) to a terminal "archived" status deferring to the issue/PR ref, and the apply report adds `execution_state_reconciled`. As of `v0.30.2`, `catalog` gains `--deep` (extends `--grep` to also match issue/PR/MR body + comment text via each ref's latest snapshot, composing with `--area` / `--refs-to`) and a new `search <term>` subcommand returns hit-level matches (owning plan slug + ref URL + matched field + snippet) in a versioned JSON envelope; both are additive. Consumed by `meta:plan-archive-migrate`, `meta:plan-archive-query`, and `meta:plan-archive-discover`. |
| `plan-issue-cli`            | `plan-issue`, `plan-issue-local`                                                                                    | Multi-binary crate. `plan-issue` is the GitHub-backed orchestrator; `plan-issue-local` is the local rehearsal pair. Manifests pin individual binary names. As of `v0.20.0`, issue-backed records use the provider-backed `record open`, `record post`, `record audit`, `record repair-dashboard`, and `record close` surface. The current marker is `plan-issue-record:v2 role=<source|plan|state|session|validation|review|closeout> profile=<tracking|dispatch>`. As of `v0.22.3`, state lifecycle comments can render canonical execution-state markdown through `record post --kind state --execution-state-file <path>`, support `--task-ledger-display auto|collapsed|expanded|open`, and render validation, review, session, and closeout evidence visibly alongside hidden payload carriers. As of `v0.25.6`, ships `record template --kind <role> --shape markdown|json` for non-mutating skeleton preview, `record audit --expect-visible` for visible-completeness lint, and the `tracking` controller surface (`tracking status`, `tracking run init`, `tracking run update`, `tracking checkpoint`, `tracking close-ready`) backed by `plan-issue.execution-run.v1` run state and `plan-issue.execution-event.v1` events. `tracking checkpoint --live --post <roles> --repair-dashboard` posts one provider lifecycle comment per role in declaration order, aborts on the first per-role failure with a `tracking-checkpoint-live-post-failed` blocker, and only refreshes the dashboard once every role succeeds; combine with `--fixture DIR` to exercise the live path deterministically (synthesized `fixture://issue/N/role` URLs and no provider mutation). As of `v0.25.7`, `tracking close-ready` emits a `ledger-rows-pending` blocker (one entry per stuck row) when `phase ∈ {ready_for_close, closed}` and the run-state's `bundle` resolves to a `*-execution-state.md` whose ledger still carries `Status ∈ {pending, in-progress}`; the silent-skip path keeps older run-states without a `bundle` field working. The `open` task-ledger-display mode renders an open `<details open>` fold (toggle present, rows visible by default), and `record open` posts the first Execution State with it so the full Task Ledger is visible on load while `expanded` stays raw rows for the final pre-closeout state. As of `v0.28.3`, `tracking checkpoint --live` inherits `repo`/`issue` from the run-state when `--provider-repo`/`--issue` are omitted (consistent with `tracking status` / `close-ready`), and `tracking checkpoint --post session` synthesizes the session summary from run-state activity (selected task, branch, linked PRs, validation, phase) when no explicit `--note` exists instead of silently dropping the role ([#644](https://github.com/sympoies/nils-cli/pull/644), [#645](https://github.com/sympoies/nils-cli/pull/645)). |
| `plan-tooling`              | `plan-tooling`                                                                                                      | Plan bundle linter / validator. As of `v0.25.7`, adds `ledger-update` (atomic one-call row patch for the canonical `*-execution-state.md` `## Task Ledger` table; stable error codes `ledger-row-not-found`, `ledger-row-ambiguous`, `ledger-table-malformed`, `ledger-status-invalid`) and `ledger-sync --from-issue` (read-mostly drift reconciliation against issue body + comments; `--write` patches only empty Evidence cells via the empty-cell preference rule). Both consumed by the tracking-profile SKILL bodies and by the `plan-issue tracking close-ready` `ledger-rows-pending` blocker. |
| `screen-record`             | `screen-record`                                                                                                     | Screen-recording helper (macOS).                                                                                                                                                                                                                                       |
| `semantic-commit`           | `semantic-commit`                                                                                                   | Semantic commit message validator and committer.                                                                                                                                                                                                                       |
| `web-evidence`              | `web-evidence`                                                                                                      | Web evidence capture helper.                                                                                                                                                                                                                                           |

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
