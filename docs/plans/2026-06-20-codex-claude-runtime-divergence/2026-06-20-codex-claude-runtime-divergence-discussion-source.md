# Codex / Claude Runtime Divergence — Options Evaluation

- **Status**: graduated into this L2 plan bundle on 2026-06-20; the four
  decisions are resolved (per-product home render, an agent-docs product
  dimension, a broad leakage lint). This file is the bundle's discussion source;
  the plan and execution-state are siblings. Not yet executed.
- **Date**: 2026-06-20
- **Source**: in-session evaluation run as two multi-agent workflows
  (19 subagents total), plus a follow-up fact check of the home prompt against
  the skill bodies. Feasibility was verified by reading the `nils-cli` render and
  agent-docs crates in `sympoies/nils-cli` and the documented Codex and Claude
  harness behavior. Decisions appended 2026-06-20.
- **Intended next step**: open a tracking issue with
  `create-plan-tracking-issue`, then run the coupled nils-cli change (R1 + C1)
  gate-first, consume it in this repo, and bump the pin.

## Execution

- Recommended plan: docs/plans/2026-06-20-codex-claude-runtime-divergence/2026-06-20-codex-claude-runtime-divergence-plan.md
- Recommended execution state: docs/plans/2026-06-20-codex-claude-runtime-divergence/2026-06-20-codex-claude-runtime-divergence-execution-state.md

## Purpose

`agent-runtime-kit` is the single shared source for two CLIs whose harnesses
differ. Some user-side content must differ per runtime. The canonical example:
Codex must be actively told to dispatch subagent reviewers, while Claude already
does so by default.

The goal is a mechanism where the running environment (Codex or Claude) is
auto-detected and the corresponding content is applied to that runtime, without
polluting the other runtime's loaded context.

This document records the evaluated option space, the probe-verified
feasibility, the resolved decisions, and the chosen convergence path. It is the
read-first source for the L2 plan that will execute the change; it is not itself
a task-by-task plan.

## Confirmed Facts

Detection already exists; application is the gap.

- **Detection primitive**: the `AGENT_RUNTIME_PRODUCT` environment variable is
  set per runtime — `=claude` on every Claude hook command
  (`core/hooks/claude/settings.hooks.jsonc`) and `=codex` on every Codex hook
  command (`targets/codex/hooks/config.block.toml`, mirrored in
  `targets/codex/link-map.yaml`). Shared hook scripts read
  `product="${AGENT_RUNTIME_PRODUCT:-agent-runtime}"`. It is visible only inside
  hook subprocesses, never in the agent's loaded prompt.
- **Pollution source 1 (home prompt)**: `AGENT_HOME.md` is symlinked verbatim
  into `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md` — never rendered. Its
  "Code Review Delegation" section says "This policy is Codex-only" and is loaded
  word for word by both runtimes (SUPPORT_MATRIX surfaces 1 and 17).
- **The home authorization and the skill baseline disagree for Codex.** The
  `AGENT_HOME.md` "Code Review Delegation" section — added in commit `dd58860`,
  the most recent change on `main` — authorizes Codex to "use subagent reviewers
  by default." The five `core/skills/code-review/*/SKILL.md.tera` bodies set the
  opposite baseline for explicit-only hosts: "on hosts that only spawn subagents
  on explicit request (e.g. Codex), run the lenses inline by default — the
  expected path for that host, not a waiver — and dispatch only when the user
  explicitly opts in." The home paragraph is the standing per-product opt-in
  layered on top of the product-neutral skill baseline (skills cannot branch per
  product; see the null Tera view below). Consequence: deleting the home
  paragraph is **not** behavior-neutral — it reverts Codex to inline-by-default.
  An earlier draft of this document claimed the skills already encode the
  behavior and the section "can simply be deleted"; that was wrong and is
  corrected here. The fix is to deliver the authorization per-product, not to
  delete it.
- **Pollution source 2 (skills)**: the five code-review `SKILL.md.tera` files
  carry cross-product prose, and the `tests/golden/codex` and
  `tests/golden/claude` versions are byte-identical, so the per-product split is
  expressed only as capability prose, not as rendered divergence.

Probe-verified feasibility (evidence is in `sympoies/nils-cli` unless noted):

- **Skills render with an empty Tera context.** The skill render path passes
  `Value::Null` as the view (`crates/agent-runtime/src/render/writer.rs`
  `render_template`), so `product` is not a variable in scope; a
  `{% if product == "codex" %}` would silently take the `else` branch for both
  products with no error and no golden change. Agents are different — the agent
  render path passes `json!({ "product": product, ... })`, so agent templates
  already branch on product correctly.
- **Render accepts only two targets.** `RenderTarget` is `Product` or
  `SupportMatrix` (`crates/agent-runtime/src/commands/render.rs`); there is no
  home-prompt target, so rendering `AGENT_HOME.md` per product needs new
  nils-cli code.
- **The `products` map can omit a product cleanly.** Both `codex` and `claude`
  keys are independently optional; an omitted product renders nothing and trips
  no drift fixture. Shipping an artifact to one product only is pure-repo and
  audit-clean.
- **Claude `additionalContext` is not durable.** Hook-injected
  `additionalContext` is conversation-scoped and lost on `/compact` with no
  reload, unlike `CLAUDE.md` which re-injects from disk each session start. It is
  unsuitable for load-bearing per-product policy on Claude.
- **Claude `@import` works at home scope.** `~/.claude/CLAUDE.md` honors
  `@import` with relative and absolute (`~/`) paths, including files outside
  `~/.claude`, durable across compaction.
- **Codex has a single home file.** Codex reads exactly one home-scope file
  (`$CODEX_HOME/AGENTS.md`, or an `AGENTS.override.md`); there is no include
  directive or second home file. A Codex-only home delta must live in those
  bytes, or be rendered per product.
- **Codex honors `additionalContext`** as developer context (advisory,
  session/turn-scoped, undocumented authority parity with `AGENTS.md`).
- **Env vars never reach the model context.** On both runtimes, environment
  variables are visible to subprocesses only; self-detection by the model
  reading an env var directly is not viable.
- **Live detection hazard.** A Claude session on this machine has both
  `CLAUDECODE=1` and `CODEX_HOME` set (profile cross-leak). Any marker-based
  self-detection must rank a positive session marker above the mere presence of
  the other product's path variables, and must prefer `AGENT_RUNTIME_PRODUCT`
  when set.

## Problem Framing: Four Orthogonal Axes

The problem is a product of independent axes; a solution picks one cell from
each.

- **Detect** — how the selector knows the runtime. Five signals exist; only some
  reach the agent.
- **Apply** — how content is physically selected or injected: render-time,
  load-time, hook-injection, agent-docs-catalog, or runtime-self-detect.
- **Author** — how the single source is structured so divergence stays
  maintainable and reviewable.
- **Enforce** — a cross-product leakage lint that turns "do not pollute" into a
  CI invariant. Mechanism-agnostic; pairs with any apply choice.

## Detection Inventory

1. `AGENT_RUNTIME_PRODUCT` env var — repo-controlled; set per runtime on hook
   commands. Visible to hook subprocesses only.
2. Render-time `product` Tera variable — repo-controlled; baked in at build.
   Works for agents today; not for skills (empty view).
3. Install-time product argument — repo-controlled; `render` / `setup --product`
   decides at install.
4. Intrinsic harness env markers — upstream-controlled; `CLAUDECODE` /
   `CLAUDE_CODE_SESSION_ID` versus `CODEX_*`. The only signal an agent could read
   itself, and only by running a shell command; `CODEX_*` markers are
   sandbox-coupled, not identity.
5. Load-path identity — which entry file the CLI opens
   (`$CODEX_HOME/AGENTS.md` versus `~/.claude/CLAUDE.md`) is itself the signal.

## Options Evaluated

Feasibility legend: `pure-repo` (doable in this repo now); `needs-nils-cli`
(upstream release plus pin bump); `blocked` (verified infeasible as worded);
`interim` (works but behavioral isolation only); `split` (differs by runtime).

### Render-Time

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| R1 | Render `AGENT_HOME.md` per product | both | needs-nils-cli | high | Strongest isolation; breaks the raw-symlink contract and must keep a neutral fallback. **Chosen for the home delegation (D1).** |
| R2 | Three-variant render (codex/claude/neutral) | both | needs-nils-cli | high | Satisfies the fallback contract; costs a third golden tree and a "neutral" product. |
| R3 | Per-product skill bodies via `{% if product %}` | both | needs-nils-cli | medium | Looks pure-repo but is not — skills render with a null view, so the branch silently mis-renders. Requires giving the skill render path a product view. |
| R3' | Per-product agent bodies via `{% if product %}` | both | pure-repo | low | Works today (agents have the product var); only carries divergence anchored to a subagent definition, not parent routing or home policy. |

### Load-Time

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| L1a | Claude `@import` per-product appendix | claude | pure-repo | medium | Verified durable; clean for the Claude side only. |
| L1b | Codex home appendix (sibling include) | codex | blocked | — | Codex has no include and reads one home file. The core asymmetry. |

### Hook-Injection

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| H1 | SessionStart product-policy injector | codex / claude | split: codex ok, claude blocked | low | Codex honors it (advisory); Claude drops it on `/compact`. Safe only for soft, re-derivable steering. |
| H2 | Runtime beacon one-liner | both | interim | low | Makes today's prose decidable, but both blocks still load — fails the "no pollution" bar. |
| H3 | Product-scoped registration (one hook per product) | both | pure-repo | medium | The foreign script never runs; still bound by `additionalContext` durability. |
| H4 | PreToolUse action-gated nudge | both | pure-repo | high | High signal-to-noise, action-only, brittle trigger; PreToolUse `additionalContext` is "parsed but not supported" on Codex. |

### Agent-Docs-Catalog

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| C1 | Catalog `product` field plus `preflight --product` | both | needs-nils-cli | high | Declarative, audit-visible, zero pollution; fixes the cue and the finish-line validation parity. Contract bump every AGENT_DOCS repo inherits. **Scheduled now (D4).** |
| C2 | `when = "product:codex"` predicate | both | needs-nils-cli | high | `[[validation]]` has no `when` today; overloads a path-only predicate with a runtime axis. |
| C3 | Hook-side post-filter on a naming convention | both | pure-repo | low | Ships today as a bridge, but partial (cue-only) and convention-based. |
| C4 | Capability-as-presence — ship a Codex-only artifact | codex | pure-repo | medium | Strongest isolation (absent for the other runtime); may package what the parent already does. |

### Runtime-Self-Detect

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| S1 | Documented self-detect contract (with precedence) | both | pure-repo | medium | Turn-one identity even with hooks off; identity-only, depends on upstream markers, precedence essential. |
| S2 | Self-detect then fetch indirection | both | pure-repo | medium | Real token-level isolation with no render path; can under-apply or mis-apply. |
| S3 | Deterministic identity probe (`agent-runtime whoami`) | both | pure-repo / needs-nils-cli | medium | Identity as a checkable fact; costs a tool call. |
| S4 | In-doc symmetric If-Codex / If-Claude blocks | both | interim | low | Instantly shippable, but both branches stay resident — fails the pollution bar. |

### Authoring And Enforce

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| A0 | Capability-conditional prose ("on hosts that...") | both | pure-repo | low | The pattern in the code-review skills — true for both, renders identical, the runtime self-selects. Carries the conservative baseline, not the Codex dispatch-by-default override. |
| A1 | Fenced product blocks stripped at apply | both | needs-nils-cli | medium | Single-source, lint-verifiable; a bespoke preprocessor and a durable strip step that belongs upstream. |
| A2 | Shared-core plus per-product overlay composed at apply | both | pure-repo / needs-nils-cli | medium | Filename-level product scope; merge semantics need defining. |
| A3 | Capability-data-driven fragment assembly | both | needs-nils-cli | high | Most auditable view, and the heaviest — over-built for today's divergence. |
| A4 | Cross-product leakage lint | both | pure-repo | low | A repo-local bash check that fails CI on the other product's sentinel. Ship it with the content fix or it red-gates. **Chosen, broad-sentinel form (D2).** |

## Decisions (Settled By The Evaluation)

- The code-review divergence is carried by two layers that currently disagree:
  the product-neutral skill baseline (inline for explicit-only hosts) and the
  Codex-only home authorization (dispatch by default, commit `dd58860`). The
  home authorization is real, recent, and load-bearing; the fix is to deliver it
  per-product, not to delete it.
- R3 (per-product skill bodies) is not pure-repo: skills render with a null Tera
  context, so it requires giving the skill render path a product view upstream.
- H1 (hook injection of policy) is split: usable on Codex as advisory steering,
  unusable on Claude for load-bearing policy because `additionalContext` is lost
  on `/compact`.
- A per-product home appendix via `@import` is Claude-only; Codex has no
  equivalent include.
- Shipping a product-only artifact through the `products`-omit lever is pure-repo
  and audit-clean.
- There is no single symmetric pure-repo channel for per-product **home**
  content. Each runtime supports the mechanism the other lacks; the only durable
  both-sides answer is per-product render of the home prompt, which needs
  nils-cli.

## Resolved Decisions (2026-06-20)

The owner chose the durable path over the quick-win. The four open decision
points are now resolved:

- **D1 — Codex-only review authorization → per-product render home (R1).** Keep
  the `dd58860` authorization as real policy and deliver it via a per-product
  rendered home prompt: the Codex-rendered home carries the delegation block, the
  Claude-rendered home does not, and a product-neutral `AGENT_HOME.md` remains
  the safe fallback when `AGENT_RUNTIME_PRODUCT` is unset or in an unrelated repo.
  Strongest, durable isolation. Requires nils-cli (a home-prompt render target)
  plus a pin bump, and supersedes the raw-symlink delivery of the home prompt.
- **D2 — Leakage lint → broad sentinel.** The A4 lint forbids the bare product
  names (`Codex`, `Claude`, `CODEX_`) in the other product's loaded artifacts,
  not only the strong "Codex-only" phrases. This catches paraphrased leaks at the
  cost of a larger allowlist, which must cover the legitimately-shared docs
  (`SUPPORT_MATRIX.md`, `docs/source/harness-shape-*.md`, the A0 capability
  prose). The allowlist needs documented reasons and a negative self-test so it
  neither red-gates the tree nor gets neutered.
- **D3 — C1 schema version → bump to v2.** Adding the `product` field bumps the
  preflight contract to `agent-docs.preflight.v2`, an explicit closed-contract
  signal, rather than treating it as an additive v1 field. Every AGENT_DOCS
  consumer's pinned agent-docs must understand v2 before any catalog adds a
  `product` key.
- **D4 — Invest now → schedule C1 (nils-cli) in this effort.** The agent-docs
  catalog product dimension is built now, not deferred. Combined with D1, this is
  one coupled nils-cli effort: render gains a per-product home target (R1) and
  agent-docs gains the `product` field/filter at v2 (C1), shipped together, then
  pin-bumped, then consumed in the repo.

## Chosen Convergence Path

A single coupled nils-cli effort, gate-first (ship upstream, release, pin bump,
then consume), mirroring the precedent in
`docs/discussions/2026-06-14-test-first-discipline-redesign.md`.

1. **Upstream nils-cli (one release).**
   - R1: add a home-prompt render target so `AGENT_HOME.md` can render per
     product (a Codex block, a Claude block, and a product-neutral fallback),
     with the golden and audit-drift surfaces extended to cover it.
   - C1: add an optional `product` field to `[[document]]` and `[[validation]]`
     in the agent-docs catalog, a `--product` flag on
     preflight/list/explain/audit, a one-place resolver filter (documents and
     validation contracts), and the `agent-docs.preflight.v2` schema. Unset
     product means include-all (safe fallback). Validate product names against a
     fixed `{codex, claude}` enum so a typo hard-errors.
2. **Release, tap, brew upgrade, pin bump** via `meta:nils-cli-bump`; raise the
   `agent-docs` `required_clis` floor to the release that introduces `product`
   and `agent-docs.preflight.v2`.
3. **Consume in `agent-runtime-kit`.**
   - Move the Codex-only delegation authorization out of the shared
     `AGENT_HOME.md` body into the Codex-rendered home block (R1); keep a
     product-neutral fallback. Optionally also register it as a `product=codex`
     catalog doc so a Codex session's preflight cue surfaces it.
   - Forward `AGENT_RUNTIME_PRODUCT` as `--product` from
     `core/hooks/shared/user-prompt-agent-docs.sh` and
     `core/hooks/shared/hook_common.py`, capability-probed; add the active
     product to the validation-contract cache key; keep cue and finish-line gate
     in parity.
   - Add the broad-sentinel cross-product leakage lint (A4) with its allowlist
     and a negative self-test; register it in `scripts/ci/all.sh` and document it
     in `DEVELOPMENT.md`.
   - Update render golden, `audit-drift` (including the `agent-home-leak`
     class), and `SUPPORT_MATRIX.md` surface 1 to reflect the home prompt
     becoming a rendered artifact.

## Scoped Plan

### Upstream (sympoies/nils-cli)

1. R1 home-prompt render target: a new `RenderTarget` (or manifest entry) that
   emits a per-product home prompt with a product-neutral fallback; extend the
   render-golden and audit-drift coverage.
2. C1 catalog product dimension: parser (allowed fields), model (`DocumentEntry`
   / `ValidationEntry` plus the resolved JSON surface), CLI (`--product`),
   resolver (filter in one place for documents and validation contracts), schema
   `agent-docs.preflight.v2`. Unset means include-all.

### Consume (agent-runtime-kit)

1. Adopt the per-product home render and move the delegation authorization into
   the Codex block; keep a product-neutral fallback `AGENT_HOME.md`.
2. Forward `--product` from the two hook consumers; add product to the contract
   cache key; verify cue and finish-line gate parity.
3. Add the broad-sentinel leakage lint plus allowlist and negative self-test;
   register and document it.
4. Refresh render golden, audit-drift, and the SUPPORT_MATRIX surface-1
   acceptance for the home prompt; bump the pin via `meta:nils-cli-bump`.

Ordering: ship and pin the nils-cli release before the catalog or rendered-home
consume edits — an older binary hard-errors on the new `product` key and lacks
the home render target.

## Scope

- The evaluation, the resolved decisions, and the scoped coupled plan that the
  L2 plan will execute.

## Non-Scope

- Executing the change. The upstream nils-cli work, the pin bump, and the repo
  consume are carried out by the L2 plan, not here.
- Adopting Codex's plugin loader / marketplace, or any other change to the
  product-capabilities baseline.

## Implementation Boundaries

- Durable runtime behavior (the home render target, the catalog product
  dimension) belongs in `sympoies/nils-cli`, released and pinned. The leakage
  lint is a deliberate repo-local bash exception, not a new nils-cli audit class.
- `AGENT_HOME.md` must remain safe fallback policy for unrelated workspaces where
  `AGENT_RUNTIME_PRODUCT` is unset; the per-product render must keep a
  product-neutral fallback.
- Repo content (docs, commits, code, comments) is English.
- `main` is protected and requires verified signatures; never force-push it.

## Acceptance Criteria

- The Codex-rendered home prompt contains the review-delegation authorization;
  the Claude-rendered home does not; a product-neutral fallback exists for unset
  product.
- `agent-docs preflight --product codex` includes a `product=codex` doc;
  `--product claude` excludes it; unset includes all; the finish-line validation
  contract filters identically (no Codex-only validation can block a Claude
  stop).
- The broad-sentinel leakage lint passes against the fixed tree with a documented
  allowlist, and a negative self-test (re-adding a foreign product name to a
  loaded artifact) fails.
- Render golden, `audit-drift` (including `agent-home-leak`), and the
  SUPPORT_MATRIX surface-1 acceptance are updated and green.
- `bash scripts/ci/all.sh && bash tests/hooks/run.sh` passes.

## Validation Plan

- `bash scripts/ci/all.sh && bash tests/hooks/run.sh` (the declared project
  validation; also the `pre-push` gate).
- Render plus golden diff for the new per-product home artifact, and
  `agent-runtime audit-drift` for the home-prompt and catalog changes.
- `agent-docs preflight --product codex|claude` and an unset run, asserting the
  expected document and validation sets.

## Risks And Guardrails

- Making `AGENT_HOME.md` a render artifact breaks the raw-symlink acceptance
  contract (SUPPORT_MATRIX surface 1) and must keep a product-neutral fallback.
  Guardrail: render a neutral baseline for unset/unknown product and keep the
  fallback file valid for unrelated repos.
- The broad-sentinel lint flags many legitimately-shared docs. Guardrail: a
  documented allowlist plus a negative self-test so it neither red-gates nor gets
  neutered; ship the lint in the same change as the content relocation.
- The v2 schema bump forces consumers to acknowledge v2. Guardrail: raise the
  pinned `agent-docs` floor and confirm every AGENT_DOCS repo runs a v2-capable
  binary before any catalog adds a `product` key.
- Adding `{% if product %}` to a `SKILL.md.tera` silently mis-renders (null
  view). Guardrail: skill-level per-product divergence needs the upstream skill
  product view; do not attempt it as a repo edit.
- Ordering hazard: an older nils-cli hard-errors on the new catalog key and lacks
  the home render target. Guardrail: ship and pin the release before the consume
  edits.

## Retention Intent

Coordination material that now feeds a decided plan. Graduate it into a
`docs/plans/<YYYY-MM-DD>-<slug>/` bundle as the discussion source when the L2
plan is authored; promote any durable architecture conclusions into
`docs/source/` if the divergence model becomes canonical.

## Read-First References

- `AGENT_HOME.md` — the `dd58860` "Code Review Delegation" authorization and the
  safe-fallback contract.
- `core/skills/code-review/*/SKILL.md.tera` and the domain `README.md` — the
  conservative inline baseline (A0) that the home authorization overrides.
- `core/hooks/claude/settings.hooks.jsonc`, `targets/codex/hooks/config.block.toml`,
  `core/hooks/shared/user-prompt-agent-docs.sh`, `core/hooks/shared/hook_common.py`
  — the detection primitive and the agent-docs injection path.
- `SUPPORT_MATRIX.md`, `docs/source/harness-shape-codex.md`,
  `docs/source/harness-shape-claude.md` — per-product surface model and the
  surface-1 raw-symlink acceptance that R1 changes.
- `manifests/product-capabilities.yaml`, `manifests/skills.yaml` — capability and
  `products`-map model.
- `sympoies/nils-cli` `crates/agent-runtime/src/render/` and the agent-docs crate
  — render and catalog source of truth for the R1 and C1 work.
- `docs/discussions/2026-06-14-test-first-discipline-redesign.md` — the
  gate-first coupled nils-cli precedent this plan follows.

## Recommended Next Artifact

Graduate this capture into an L2 plan: move it into a
`docs/plans/<YYYY-MM-DD>-<slug>/` bundle as `<slug>-discussion-source.md`, author
`<slug>-plan.md` and `<slug>-execution-state.md` for the coupled nils-cli effort
(upstream R1 + C1 release, pin bump, repo consume), then open a tracking issue
with `create-plan-tracking-issue`.
