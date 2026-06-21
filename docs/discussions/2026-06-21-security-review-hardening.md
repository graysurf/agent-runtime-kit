# Security Review Hardening Implementation Handoff

- **Status**: captured for later work — tracked as an L1 follow-up issue; not
  scheduled for implementation in this pass.
- **Date**: 2026-06-21
- **Source**: In-session security review and dependency-swap audit of
  `agent-runtime-kit`, run as a multi-lane workflow (7 specialist lanes →
  adversarial per-finding verification → completeness critic → synthesis;
  46 agents). Two highest-leverage findings were additionally reproduced live
  against the installed hooks in the same session.
- **Intended next step**: triage each fix to its own tier when picked up (most
  are L0 single-PR edits); land the highest-leverage guardrail and supply-chain
  items first. This document is the read-first source for that work.

## Purpose

Preserve the converged conclusions of the security review so the fixes can be
implemented later without re-running the audit. The review found **no critical or
high-severity issues and no external-attacker remote-code path**. The real
exposure is two-fold and worth tracking deliberately:

1. **Guardrail fail-open under prompt injection** — the hook control plane
   inspects one canonical form of an action and trusts every equivalent form
   that wraps or routes around it.
2. **Latent supply-chain trust on the published GHCR image path** — mutable
   action/base-image refs and unverified bundled binaries that a future upstream
   compromise would flow into silently.

## Threat Model (the lens for every severity)

`agent-runtime-kit` is a local, single-user runtime layer. Its realistic
adversaries are:

- **Prompt-injected content** the agent ingested (web page, issue, file) that
  steers the agent to perform a guarded action or write a guarded file. Agent
  -triggered paths and guardrail fail-open are in scope.
- **Third-party supply-chain compromise** of the Docker image published to GHCR
  (mutable action refs, mutable base tags, unverified bundled binaries).

Down-ranked: sinks only reachable by the user typing their own command locally.
Not down-ranked: guardrail bypass, CI/supply-chain, XXE/SSRF on untrusted
payloads, and anything touching the published image.

## Confirmed Facts

- This repo has **no `package.json` / `Cargo.toml` / `requirements.txt`**, and
  the Python is **stdlib-only** (`core/hooks/shared/hook_common.py` is the shared
  parser). There is therefore no classic vulnerable third-party package to
  replace. "Dependencies" here = stdlib module choices, bundled CLI binaries,
  GitHub Action versions, and the Docker base image. [F1] [A1]
- The command-gating hooks unwrap only a fixed wrapper set
  (`env`/`time`/`command`/`exec`/`agent-run exec --`) and never descend into a
  `sh -c` / `bash -c` / `eval` string or process substitution. Reproduced live:
  `git commit -m x` → BLOCKED, but `bash -c "git commit -m x"`,
  `sh -c "…"`, `eval "…"` → ALLOWED; same for `bash -c "gh pr create …"`. The
  heredoc form (`bash <<EOF … EOF`) is already caught. [F2] [A2]
- The content scanners (`mcp-secret-scan.py`, `block-project-memory-write.py`,
  `portable-paths-scan.py`) are wired only to the `Write|Edit|NotebookEdit`
  matcher (`core/hooks/claude/settings.hooks.jsonc:102-123`). Reproduced live:
  an `sk-ant-…` key written to `.mcp.json` via the Write tool is BLOCKED, but the
  same key written via a Bash heredoc is NOT scanned. Two of the three have no
  Stop-time backstop. [F3] [A3]
- `xml.etree.ElementTree` parses untrusted remote feeds in
  `topic-radar` (`bin/topic_radar.py:17,1147,1249,1410`) over an unbounded
  `resp.read()` (`:619-629`). Verified: stdlib CPython does **not** resolve
  external entities or fetch external DTDs and **caps** billion-laughs — so there
  is **no reachable XXE/SSRF file-read today**; the residual is entity-expansion
  / oversized-body DoS from a compromised or MITM'd feed origin. [F4] [A4]
- The `publish` job in `.github/workflows/publish-image.yml` holds
  `packages: write`, logs into GHCR with `secrets.GITHUB_TOKEN`, and is the sole
  builder of the multi-arch image. Every action it uses is a floating major tag;
  `ci.yml:37` uses `Homebrew/actions/setup-homebrew@main` (a mutable branch).
  No `.github/dependabot.yml` exists. [F5]
- In `docker/Dockerfile`, `nils-cli` (L50-59) and `glab` (L109-116) are checksum
  -verified, but `gh` (L105-108) and `yq` (L117-119) are installed with **no**
  checksum. Base images (`debian:trixie-slim` L38, `node:22-trixie-slim` L71) are
  tag-pinned, not digest-pinned. The published image has no provenance / SBOM /
  signature and pushes a mutable `latest`. [F6]
- A quadratic-backtracking regex in `block-claude-coauthor-trailer.py:34`
  (`^\s*…` with `MULTILINE` where `\s` consumes newlines) over an uncapped
  message body stalls ~26 s at ~100k blank lines. Reachable via a prompt-injected
  `semantic-commit -m`; wired for Claude only. [F7]

## Decisions

1. **Track as L1, implement later.** Open one follow-up issue as the durable
   timeline; do not implement fixes in this pass. Each fix is triaged to its own
   tier (most are L0 single-PR edits) when scheduled.
2. **Severity floor stands as audited.** No critical/high. Medium = guardrail
   fail-open + published-image supply-chain. Implementation order follows the
   priority list below (leverage first).
3. **`defusedxml` is the one true library swap.** Because the kit is stdlib-only,
   vendor the small pure-Python shim or pre-reject `DOCTYPE`/`ENTITY` rather than
   add a runtime dependency. All other "swaps" are integrity fixes or additive
   layers, not vulnerable-dependency replacements.
4. **Keep the inline secret scanner.** Any `gitleaks`/`detect-secrets` adoption
   is an *additive* pre-commit/CI layer only; a hard dependency would violate the
   stdlib-only / dependency-free design.
5. **Fixes that span `nils-cli` are out of this repo's scope.** The hook scripts
   live here; if a fix needs new released CLI behavior it follows the coupled
   nils-cli release boundary. (No such coupling is required for the items
   below — all are repo-local edits.)
6. **SEC-02 cleanup is optional and recorded generically.** This document does
   not repeat the leaked host/username; the fix is to placeholder them in the
   archived entry, consistent with the repo's portable-paths hygiene.

## Scope

- Repo-local fixes to `core/hooks/shared/*`, `core/hooks/claude/settings.hooks.jsonc`,
  `core/skills/reporting/topic-radar/bin/topic_radar.py`,
  `.github/workflows/*.yml`, `.github/dependabot.yml` (new), and
  `docker/Dockerfile`.
- Re-render of any hook/settings changes through the standard surface pipeline
  and the matching golden/runtime-smoke updates.

## Non-Scope

- No `nils-cli` / external-binary behavior changes (no coupled release needed).
- No replacement of the inline secret scanner with a third-party library.
- No change to the deliberate runtime-extension RCE surface in
  `docker/entrypoint.sh` (operator-controlled by design; document only).
- No remediation of the nine ruled-out candidates (see "Ruled Out").

## Implementation Boundaries

- Hook fixes must re-use existing machinery where it exists:
  `forge-label-reminder.py` already has `shell_c_payload` + recursive
  `simple_commands` re-scan and `strip_heredoc_bodies`; lift the nested-shell
  descent into `hook_common` so all four block hooks share it (they currently
  clone the unwrap logic).
- The content-scanner Bash gap is fixed either by a Bash-tool guard over
  redirection/heredoc/`tee` targets, or by a Stop-time backstop using the
  scanners' existing `--staged`/`--tracked` modes (nothing invokes them today).
- Any hook/settings edit must keep Claude and Codex render parity and pass the
  golden + runtime-smoke gates.

## Findings — Confirmed (21)

Deduplicated to the canonical issue; converging lane findings are noted. `Live`
marks findings reproduced against the installed hooks this session.

| ID | Sev | Finding | Evidence (file:line) | Fix location |
| --- | --- | --- | --- | --- |
| H-1 | Med · Live | All command gates bypassed by shell wrapper (`bash -c`/`sh -c`/`eval`/`<()`) | `block-direct-{git-commit,pr-create,git-worktree,python}.py`; `hook_common.py:1240-1270` | `hook_common.py` (shared descent) + 4 block hooks |
| H-2 | Med · Live | Bash-authored writes skip secret/memory/portable-path scanners; no Stop backstop | `core/hooks/claude/settings.hooks.jsonc:102-123` | settings wiring + Bash guard or Stop backstop |
| H-3 | Med | PR-skill marker is a free-text global off-switch | `block-direct-pr-create.py:84-86,264-266,275-279` | `block-direct-pr-create.py` |
| S-1 | Med | `setup-homebrew@main` mutable branch ref | `.github/workflows/ci.yml:37` | `ci.yml` |
| S-2 | Med | All publish-job actions floating major tags, no SHA pins | `.github/workflows/publish-image.yml:30,48,51,54,62,72,130` | `publish-image.yml` |
| S-3 | Med | Published image has no provenance/SBOM/signature; mutable `latest` | `publish-image.yml:129-141` | `publish-image.yml` |
| S-4 | Med | `gh` + `yq` baked with no checksum (glab/nils ARE verified) | `docker/Dockerfile:103-121` | `docker/Dockerfile` |
| S-5 | Med | Base images tag-pinned, not digest-pinned | `docker/Dockerfile:38,71` | `docker/Dockerfile` |
| S-6 | Low | `nils-cli`/`glab` verified only by same-server sidecar; no in-repo digest | `docker/Dockerfile:50-59,109-116` | `docker/Dockerfile` + pin manifest |
| S-7 | Info | No Dependabot/Renovate config | `.github/dependabot.yml` (absent) | new `.github/dependabot.yml` |
| P-1 | Low | `topic-radar` parses remote XML with stdlib ElementTree (DoS residual) | `topic_radar.py:17,1147,1249,1410` | `topic_radar.py` |
| P-2 | Low | Unbounded `resp.read()`; default opener follows cross-host redirects | `topic_radar.py:619-629` | `topic_radar.py` |
| D-1 | Low | `mcp-secret-scan` matches only exact basename `.mcp.json` | `mcp-secret-scan.py:69-71` | `mcp-secret-scan.py` |
| D-2 | Low | Narrow secret patterns; block message echoes first-4…last-4 | `mcp-secret-scan.py:19-31,57-62` | `mcp-secret-scan.py` |
| D-3 | Info | Gates read arbitrary `--message-file` path (symlink-following) | `hook_common.py:217-229` | accept / optional confine |
| D-4 | Info | Internal corp GitLab host + maintainer username in an archived heuristic doc | archived `error-inbox/.../ENTRY.md` | placeholder the entry |
| A-1 | Low | Quadratic ReDoS in co-author trailer guard | `block-claude-coauthor-trailer.py:34` | one-line regex fix |

Lane-level duplicates folded into the rows above (same root cause): the
action-pinning issue surfaced independently as `CI-01`, `CI-02`, `DK-05`, and an
`SH-01/shell` finding → rows S-1/S-2; the topic-radar XML/read issues surfaced as
`SH-02/shell`, `SH-03/python`, and `SWAP-01` → rows P-1/P-2.

## Fix Backlog — Priority Order (with acceptance criteria)

1. **H-1 — close the shell-wrapper bypass.** When the command-position token
   after unwrapping is a known shell with a `-c`/`--command` string (or `eval`),
   recursively parse the string and re-apply the guard; bias toward block on
   ambiguity.
   - *Accept*: `bash -c "git commit …"`, `sh -c "git commit …"`,
     `eval "git commit …"`, and the `gh pr create` / `git worktree`
     equivalents are BLOCKED; existing allowed paths still pass; a new
     `tests/hooks/` case covers wrapper block + a legitimate non-block.
2. **S-1 + S-2 + S-7 — SHA-pin actions + add Dependabot.** Replace
   `setup-homebrew@main` and every floating `@vN` with a 40-char SHA (version in
   a trailing comment); add `.github/dependabot.yml` for `github-actions` (+
   `docker`).
   - *Accept*: `grep -REn 'uses:.*@(main|v[0-9]+)\b' .github/workflows` returns
     nothing; `.github/dependabot.yml` lists both ecosystems; `scripts/ci/all.sh`
     passes.
3. **H-2 — scan Bash-authored writes.** Add a Bash-tool guard over
   redirection/heredoc/`tee` targets for the protected paths/patterns, or a
   Stop-time backstop using the scanners' `--staged`/`--tracked` modes.
   - *Accept*: an `sk-ant-…` heredoc write to `.mcp.json` is blocked or caught at
     Stop; project-memory and portable-paths writes via Bash are likewise
     covered; a `tests/hooks/` case proves it.
4. **S-4 — checksum-verify `gh` and `yq`.** Mirror the in-file `glab` /
   `nils-cli` `sha256sum -c -` pattern; optionally pin known-good SHA256 as build
   ARGs.
   - *Accept*: the Dockerfile fetches and verifies a checksum for both `gh` and
     `yq` before install; the image builds.
5. **S-3 + S-5 — image integrity.** Set `provenance: true` + `sbom: true` (or add
   `actions/attest-build-provenance` with scoped `id-token`/`attestations`);
   digest-pin both base images; document consumer verification.
   - *Accept*: the publish step emits provenance + SBOM; base `FROM` lines carry
     `@sha256:`; `RELEASING.md` / `docker/README.md` document a verify step.
6. **A-1 — ReDoS one-liner.** Change the regex to `^[ \t]*co-authored-by:\s*claude\b`;
   optionally cap `message[:65536]`.
   - *Accept*: a 200k-blank-line message returns in well under a second; Claude
     co-author trailers (incl. leading-space) are still detected.
7. **H-3 — bind the PR-skill marker.** Honor the marker only as a leading
   env-assignment on the same simple-command as `gh`/`glab`, via existing
   `skip_env_prefix`/`is_assignment` parsing.
   - *Accept*: a marker inside `--body` / after `;` / in a comment no longer
     disarms the gate; the legitimate leading-prefix path still passes.
8. **D-1 + D-2 — broaden `mcp-secret-scan`.** Match `mcp.json`,
   `.vscode/mcp.json`, `.cursor/mcp.json`; add `github_pat_`, AWS secret-key,
   `-----BEGIN … PRIVATE KEY-----`, `AGE-SECRET-KEY-1`, `AIza`, `ya29.`; replace
   the first-4…last-4 mask with `<redacted>`.
   - *Accept*: each new pattern/path is caught by a unit test; no secret bytes
     appear in any block message.
9. **P-1 + P-2 — harden `topic-radar` fetch/parse.** Cap `resp.read(MAX_BYTES)`
   (~8-16 MiB); parse via vendored `defusedxml` or a `DOCTYPE`/`ENTITY`
   pre-reject; re-validate redirect hosts against the known feed set.
   - *Accept*: an oversized body is rejected, not buffered; an entity-expansion
     feed is refused; the skill still parses the real feeds.
10. **S-6 — pin `nils-cli`/`glab` digest in-repo.** Cross-check the downloaded
    sha256 against an expected value stored in this repo (bumped via the existing
    pin gate), or verify a signature.
    - *Accept*: the build fails if the upstream artifact digest changes
      without a matching in-repo bump.
11. **D-3 / D-4 (optional).** Optionally confine `--message-file` reads to the
    repo tree; placeholder the corp host/username in the archived entry.

## Validation Plan

- Per-fix: add or extend a `tests/hooks/` case for each hook change (block +
  allow paths); run `bash tests/hooks/run.sh`.
- Repo-wide gate for every PR: `bash scripts/ci/all.sh && bash tests/hooks/run.sh`
  (the declared `project-dev` validation), including the version-alignment and
  surface/golden positions after any hook/settings re-render.
- Docs-only change landing this capture: markdown lint (`rumdl`) on the new file
  plus `scripts/ci/all.sh` docs positions.
- Spot-check the two live findings post-fix using the same payloads recorded in
  Confirmed Facts.

## Risks And Guardrails

- **Wrapper-descent over-blocking (H-1).** Recursive re-scan could block
  legitimate `bash -c` usage. Guardrail: scope the re-scan to the specific guarded
  commands each hook already targets; cover allow-paths in tests.
- **Render parity drift.** Hook/settings edits must re-render to both products;
  the golden + runtime-smoke gates catch divergence — do not hand-edit rendered
  targets.
- **SHA-pin rot.** SHA pins go stale without Dependabot; ship S-7 with S-1/S-2 so
  the pins stay fresh.
- **`defusedxml` vendoring.** Adding a real pip dependency would violate the
  stdlib-only design; vendor the shim or pre-reject DTDs instead.

## Retention Intent

Coordination material; cleanup-eligible once the tracked fixes ship or the L1
issue is closed. Promote a durable subset (e.g. the hook-bypass class as a
guardrail-design note, or the supply-chain pinning policy) into
`core/policies/` or `docs/source/` only if it becomes authoritative reference
beyond this backlog.

## Read-First References

- `[F1]` Repo manifest survey — no `package.json`/`Cargo.toml`/`requirements.txt`;
  Python stdlib-only.
- `[F2]` `core/hooks/shared/block-direct-git-commit.py`,
  `block-direct-pr-create.py`, `block-direct-git-worktree.py`,
  `block-direct-python.py`, `hook_common.py` (the command gates).
- `[F3]` `core/hooks/claude/settings.hooks.jsonc` (matcher wiring);
  `mcp-secret-scan.py`, `block-project-memory-write.py`, `portable-paths-scan.py`.
- `[F4]` `core/skills/reporting/topic-radar/bin/topic_radar.py`.
- `[F5]` `.github/workflows/ci.yml`, `.github/workflows/publish-image.yml`.
- `[F6]` `docker/Dockerfile`, `RELEASING.md`, `docker/README.md`.
- `[F7]` `core/hooks/shared/block-claude-coauthor-trailer.py`.
- `core/policies/work-tier-levels.md` (tier classification for each fix).
- `core/policies/git-delivery.md` (PR/label mechanics for delivery).

## Ruled Out (recorded so the absence is intentional, not an oversight)

Nine candidates were investigated and deliberately not flagged: the finish-line
gate "credit without running" (self-discipline over the agent's own commands,
waiver exists); scope-lock advisory-on-Stop (PreToolUse deny intact by design);
fixed `/tmp` paths in CI scripts (hosted ephemeral runner); `memory-snapshot.sh`
tar extraction (libarchive/GNU tar reject traversal by default); billion-laughs
in topic-radar (affirmatively refuted — expat caps it); `meta.outputs.tags` into
a `run:` block (unreachable — repo-derived CalVer value, release-triggered);
publish trigger/token scope (confirmed least-privilege — a do-not-regress note);
the `entrypoint.sh` zsh-kit clone (intended operator-controlled extension);
`agent-out` not in `.gitignore` (lives under `$HOME/.local/state`, no exposure).

## Recommended Next Artifact

The L1 follow-up issue that tracks this backlog (`issue-follow-up`, open mode),
linking this document under read-first context. When a fix is picked up, triage
its tier per `work-tier-levels.md` (most are L0 single-PR edits) and deliver
through the standard PR floor, linking the PR back to the issue.
