# Codex / Claude Runtime Divergence — Options Evaluation

- **Status**: broad evaluation complete; convergence pending. Material for
  continued discussion — not yet an executed-and-archived plan.
- **Date**: 2026-06-20
- **Source**: in-session evaluation run as two multi-agent workflows
  (19 subagents total). Feasibility was verified by reading the `nils-cli`
  render and agent-docs crates in `sympoies/nils-cli` and the documented Codex
  and Claude harness behavior.
- **Intended next step**: pick a convergence path (recommended defaults below),
  then implement Step 1 as a pure-repo, test-first change.

## Purpose

`agent-runtime-kit` is the single shared source for two CLIs whose harnesses
differ. Some user-side content must differ per runtime. The canonical example:
Codex must be actively told to dispatch subagent reviewers, while Claude already
does so by default.

The goal is a mechanism where the running environment (Codex or Claude) is
auto-detected and the corresponding content is applied to that runtime, without
polluting the other runtime's loaded context.

This document records the evaluated option space, the probe-verified
feasibility, the recommended convergence path, and the decisions that remain. It
is the read-first source for the next discussion or for generating an
implementation plan; it is not itself a task-by-task plan.

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
- **Pollution source 2 (skills)**: the five
  `core/skills/code-review/*/SKILL.md.tera` files carry cross-product prose but
  have no `{% if product %}`, and the `tests/golden/codex` and
  `tests/golden/claude` versions are byte-identical — a second leak at the
  render layer.

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
  no drift fixture (`writer.rs`; `rendered_target` re-renders and byte-compares,
  so absent-on-both is a zero diff). Shipping an artifact to one product only is
  pure-repo and audit-clean.
- **Claude `additionalContext` is not durable.** Hook-injected
  `additionalContext` is conversation-scoped and lost on `/compact` with no
  reload, unlike `CLAUDE.md` which re-injects from disk each session start. It is
  unsuitable for load-bearing per-product policy on Claude.
- **Claude `@import` works at home scope.** `~/.claude/CLAUDE.md` honors
  `@import` with relative and absolute (`~/`) paths, including files outside
  `~/.claude`, and the import is durable across compaction.
- **Codex has a single home file.** Codex reads exactly one home-scope file
  (`$CODEX_HOME/AGENTS.md`, or an `AGENTS.override.md`); there is no include
  directive or second home file. A Codex-only home delta must live in those
  bytes, or be rendered per product.
- **Codex honors `additionalContext`.** Codex feeds SessionStart and
  UserPromptSubmit `additionalContext` to the model as developer context.
  Authority parity with `AGENTS.md` is undocumented, and persistence is
  session/turn-scoped, so it is suitable for advisory steering, not load-bearing
  policy.
- **Env vars never reach the model context.** On both runtimes, environment
  variables (including any `AGENT_RUNTIME_PRODUCT`) are visible to subprocesses
  only; the model only learns a value if a command echoes it. Self-detection by
  the model reading an env var directly is not viable.
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
| R1 | Render `AGENT_HOME.md` per product | both | needs-nils-cli | high | Strongest isolation; breaks the raw-symlink contract and must keep a neutral fallback. |
| R2 | Three-variant render (codex/claude/neutral) | both | needs-nils-cli | high | Satisfies the fallback contract; costs a third golden tree and a "neutral" product. |
| R3 | Per-product skill bodies via `{% if product %}` | both | needs-nils-cli | medium | Looks pure-repo but is not — skills render with a null view, so the branch silently mis-renders. Requires giving the skill render path a product view. |
| R3' | Per-product agent bodies via `{% if product %}` | both | pure-repo | low | Works today (agents have the product var); only carries divergence anchored to a subagent definition, not parent routing or home policy. |

### Load-Time

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| L1a | Claude `@import` per-product appendix | claude | pure-repo | medium | Verified durable; clean for the Claude side only. |
| L1b | Codex home appendix (sibling include) | codex | blocked | — | Codex has no include and reads one home file; a delta must be concatenated (breaks symlink) or rendered. The core asymmetry. |

### Hook-Injection

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| H1 | SessionStart product-policy injector | codex / claude | split: codex ok, claude blocked | low | Codex honors it (advisory); Claude drops it on `/compact`. Safe only for soft, re-derivable steering. |
| H2 | Runtime beacon one-liner | both | interim | low | Makes today's prose decidable, but both blocks still load — fails the "no pollution" bar. |
| H3 | Product-scoped registration (one hook per product) | both | pure-repo | medium | The foreign script never runs (precedent: the Claude-only coauthor guard); still bound by `additionalContext` durability. |
| H4 | PreToolUse action-gated nudge | both | pure-repo | high | High signal-to-noise, action-only, brittle trigger; PreToolUse `additionalContext` is "parsed but not supported" on Codex today. |

### Agent-Docs-Catalog

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| C1 | Catalog `product` field plus `preflight --product` | both | needs-nils-cli | high | Declarative, audit-visible, zero pollution; fixes the cue and the finish-line validation parity. Contract bump every AGENT_DOCS repo inherits. |
| C2 | `when = "product:codex"` predicate | both | needs-nils-cli | high | `[[validation]]` has no `when` today (two grammar changes); overloads a path-only predicate with a runtime axis. |
| C3 | Hook-side post-filter on a naming convention | both | pure-repo | low | Ships today as a bridge, but partial (cue-only) and convention-based, not parser-enforced. |
| C4 | Capability-as-presence — ship a Codex-only artifact | codex | pure-repo | medium | Strongest isolation (absent for the other runtime); may package what the parent already does. |

### Runtime-Self-Detect

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| S1 | Documented self-detect contract (with precedence) | both | pure-repo | medium | Turn-one identity even with hooks off; identity-only, depends on upstream markers, precedence essential. |
| S2 | Self-detect then fetch indirection | both | pure-repo | medium | Real token-level isolation with no render path; can under-apply (missed fetch) or mis-apply (wrong identity). |
| S3 | Deterministic identity probe (`agent-runtime whoami`) | both | pure-repo / needs-nils-cli | medium | Identity as a checkable fact; skill-bin form is pure-repo, a durable subcommand is upstream; costs a tool call. |
| S4 | In-doc symmetric If-Codex / If-Claude blocks | both | interim | low | Instantly shippable, but both branches stay resident — fails the pollution bar and doubles in-context text. |

### Authoring And Enforce

| ID | Option | Runtime | Feasibility | Effort | Key tradeoff |
| --- | --- | --- | --- | --- | --- |
| A0 | Capability-conditional prose ("on hosts that...") | both | pure-repo | low | The pattern already in use in the code-review skills — true for both, renders identical, the runtime self-selects. No detection needed. |
| A1 | Fenced product blocks stripped at apply | both | needs-nils-cli | medium | Single-source, lint-verifiable; a bespoke preprocessor and a durable strip step that belongs upstream. |
| A2 | Shared-core plus per-product overlay composed at apply | both | pure-repo / needs-nils-cli | medium | Filename-level product scope, minimal duplication; merge semantics need defining; a real merge surface is upstream. |
| A3 | Capability-data-driven fragment assembly | both | needs-nils-cli | high | Most auditable "what is Codex-only?" view, and the heaviest — likely over-built for today's divergence. |
| A4 | Cross-product leakage lint | both | pure-repo | low | A repo-local bash check (not a nils-cli audit class) that fails CI on the other product's sentinel. Ship it with the content fix or it red-gates against today's identical goldens. |

## Decisions (Settled By The Evaluation)

- The code-review delegation divergence is **already solved** by the
  capability-conditional prose (A0) in the skill bodies and the per-product
  reviewer agents. It renders byte-identical and the runtime self-selects, so it
  needs no detection mechanism. The only real leak is the `AGENT_HOME.md`
  section, which can simply be deleted.
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

## Recommended Convergence Path

Match the mechanism weight to the divergence volume, which today is essentially
one home section plus the code-review family.

1. **Ship now (pure-repo, ~1 PR).** Delete the `AGENT_HOME.md` "Code Review
   Delegation" section — the behavior already lives in the skills' capability
   prose (A0) and the reviewer agents. Backfill the host-capability note in the
   skills that lack it. Add the A4 leakage lint in the same PR, with its
   allowlist, so CI never red-gates. Optionally add a thin Codex SessionStart
   reinforcement (advisory only).
2. **If per-skill variance is later needed (needs-nils-cli).** Give the skill
   render path a `product` view (mirroring agents), then real `{% if product %}`
   in `SKILL.md.tera` works (R3). Upstream release plus pin bump.
3. **Long-term declarative endpoint (needs-nils-cli).** Add a `product` field to
   the agent-docs catalog plus `preflight --product` (C1). Zero pollution by
   construction for both the injected cue and the finish-line validation parity.
   Pair with the S1 self-detect contract as cheap insurance. Every AGENT_DOCS
   repo inherits the contract, so it follows a release plus pin-bump ceremony.

## Scoped Plan — Step 1 (Quick-Win, Pure-Repo)

1. Delete the leaky "Code Review Delegation" section in `AGENT_HOME.md`; confirm
   `grep -niE 'codex|claude' AGENT_HOME.md` returns zero.
2. Backfill the host-capability note in the `core/skills/code-review/*/SKILL.md.tera`
   files that lack it, so no skill relies on the deleted home section. Keep the
   shared body that describes both branches — do not add a product conditional
   (it would silently mis-render).
3. Add `scripts/ci/product-leak-audit.sh` plus an allowlist, modeled on
   `scripts/ci/skill-governance-audit.sh` and the needle logic of the nils-cli
   `agent_home_leak` audit class. It scans each product's loaded artifacts and
   fails on the other product's sentinel outside the allowlist. Register it last
   in `scripts/ci/all.sh` and document it in `DEVELOPMENT.md`.
4. Optional: add `core/hooks/shared/session-start-product-policy.sh` plus
   per-product fragment files that emit only the matching product's advisory
   text as `additionalContext`, no-op when the product is unset. Write the
   failing hook-contract test first.

Sequencing: land everything in one change with the allowlist and content fix
before the lint is registered, so the lint is green on first run. The golden
gate stays a clean no-op because no `SKILL.md.tera` gains a product conditional.

## Scoped Plan — Step 3 (C1 Declarative, Needs nils-cli)

1. Add an optional `product` field to `[[document]]` and `[[validation]]` in
   `AGENT_DOCS.toml`; unset means include-all (safe fallback). Validate names
   against a fixed `{codex, claude}` enum so a typo hard-errors rather than
   silently never-matching.
2. Upstream `nils-agent-docs`: extend the parser (allowed fields), the model
   (`DocumentEntry` / `ValidationEntry` plus the resolved JSON surface), the CLI
   (`--product` flag on preflight/list/explain/audit), and the resolver (filter
   in one place, in both `resolve_documents` and the validation-contract path).
3. Forward `AGENT_RUNTIME_PRODUCT` as `--product` from
   `core/hooks/shared/user-prompt-agent-docs.sh` and
   `core/hooks/shared/hook_common.py`, capability-probed against
   `preflight --help`. Add the active product to the contract cache key.
4. Migrate the Codex-only delegation prose into a `product=codex` doc; remove it
   from `AGENT_HOME.md`. Order: release, tap, brew upgrade, pin bump (via
   `meta:nils-cli-bump`), then add the field to the catalog — an older binary
   hard-errors on the new key, so the catalog edit must follow the pin floor.

Parity is the correctness crux: docs and validations must filter identically, in
one place in the resolver, or a Codex-only validation could block a Claude stop.

## Scope

- A broad, probe-verified menu of options to detect the runtime and apply
  per-product content without cross-context pollution.
- A recommended convergence path and two scoped plans (Step 1 pure-repo, Step 3
  declarative).

## Non-Scope

- Implementing any option. Step 1 is ready to execute test-first but is not done
  here.
- Adopting Codex's plugin loader / marketplace, or any change to the
  product-capabilities baseline.
- Changing the nils-cli pin or cutting a release.

## Implementation Boundaries

- Durable runtime behavior belongs in `sympoies/nils-cli` (release plus pin
  bump), not repo shell glue. The Step 1 leakage lint is a deliberate repo-local
  bash exception, not a new nils-cli audit class.
- `AGENT_HOME.md` must remain safe fallback policy for unrelated workspaces where
  `AGENT_RUNTIME_PRODUCT` is unset; any relocation of policy must define the
  unset-product behavior (include-all or neutral).
- Repo content (docs, commits, code, comments) is English.
- `main` is protected and requires verified signatures; never force-push it.

## Acceptance Criteria (Step 1)

- `grep -niE 'codex|claude' AGENT_HOME.md` returns zero hits after the deletion.
- `agent-runtime render --product codex|claude` plus
  `git diff --exit-code -- tests/golden/` is a clean no-op (no product
  conditional crept into any skill).
- `scripts/ci/product-leak-audit.sh` passes against the fixed tree, and a
  negative self-test (temporarily re-adding a "Codex-only" line to a
  Claude-loaded artifact) fails.
- `bash tests/hooks/run.sh` passes, including the new hook-contract cases if the
  optional SessionStart reinforcement ships.

## Validation Plan

- `bash scripts/ci/all.sh && bash tests/hooks/run.sh` (the declared project
  validation; also the `pre-push` gate).
- Render plus golden no-op diff, and `agent-runtime audit-drift` (the
  `agent-home-leak` class stays green; no `$AGENT_HOME` token is added).

## Risks And Guardrails

- Adding `{% if product %}` to a `SKILL.md.tera` silently takes the `else` branch
  for both products with no error and no golden change. Guardrail: forbid product
  conditionals in skills until the skill render path gains a product view.
- `additionalContext` is weak and non-persistent on both runtimes and is dropped
  by `/compact`. Guardrail: keep load-bearing behavior in always-loaded skill
  bodies; any hook fragment is advisory and re-derivable.
- Deleting the `AGENT_HOME.md` section is live in both homes on the next sync.
  Guardrail: confirm the skills and reviewer agents already encode the behavior
  before deletion, and backfill the skills that lack the note in the same change.
- The leakage lint will flag the legitimate capability prose that names both
  products. Guardrail: allowlist by capability-prose marker with documented
  reasons, and include a negative self-test so the allowlist does not neuter the
  lint.

## Decision Points (Recommended Defaults)

These are the choices the next discussion converges on. Defaults are recommended,
not yet adopted.

- **Ship the H1 SessionStart reinforcement at all?** Recommended: no for now.
  The skills already carry the load-bearing behavior, and Claude drops the
  injected text on `/compact`, so it is redundant nicety.
- **Leakage-lint sentinel breadth.** Recommended: start with strong sentinels
  ("Codex-only", "Claude-only", "This policy is Codex-only") to catch the exact
  leak class with low noise; broaden later if a real leak slips through.
- **C1 schema version.** Recommended: keep `agent-docs.preflight.v1` (the new
  field is additive and the kit hooks parse leniently); bump to v2 only if a
  strict external JSON consumer is identified.
- **Does the divergence volume justify the heavy mechanisms yet?** Recommended:
  defer R1, A3, and C4-at-scale until divergence grows beyond the current one
  home section plus the code-review family.

## Retention Intent

Coordination material: cleanup-eligible once the described work ships or is
abandoned. Promote to `docs/source/` (repo-wide architecture / policy) if the
divergence model becomes authoritative knowledge rather than a single
convergence's substrate.

## Read-First References

- `AGENT_HOME.md` — the leaking "Code Review Delegation" section and the
  safe-fallback contract.
- `core/skills/code-review/*/SKILL.md.tera` and the domain `README.md` — the
  capability-conditional prose pattern (A0).
- `core/hooks/claude/settings.hooks.jsonc`, `targets/codex/hooks/config.block.toml`,
  `core/hooks/shared/user-prompt-agent-docs.sh`, `core/hooks/shared/hook_common.py`
  — the detection primitive and the agent-docs injection path.
- `SUPPORT_MATRIX.md`, `docs/source/harness-shape-codex.md`,
  `docs/source/harness-shape-claude.md` — per-product surface model.
- `manifests/product-capabilities.yaml`, `manifests/skills.yaml` — the
  capability and `products`-map model.
- `sympoies/nils-cli` `crates/agent-runtime/src/render/` and the agent-docs crate
  — render and catalog source of truth for the needs-nils-cli options.

## Recommended Next Artifact

- For Step 1: implement directly as a pure-repo, test-first change (no plan
  bundle needed).
- For Step 3 (C1): when it is scheduled, move this capture into a
  `docs/plans/<YYYY-MM-DD>-<slug>/` bundle as the discussion source, author the
  plan and execution-state files, and open a plan-tracking issue.
