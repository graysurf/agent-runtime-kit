# agent-docs Intent System Completion - Discussion Source

- Status: accepted for Option C execution.
- Date: 2026-05-31
- Source issue: https://github.com/graysurf/agent-runtime-kit/issues/217
- Source repos:
  - `graysurf/agent-runtime-kit`
  - `sympoies/nils-cli`

## User Decision

The user asked for a recommendation on the residual gaps tracked in
`graysurf/agent-runtime-kit#217`, then chose Option C: complete the work across
both repos, including the upstream nils-cli primitive, release, runtime-kit
consumer changes, pin bump, and closeout.

The user then approved executing the six-step sequence and asked to start with
Step 1: create the L2 plan-tracking record.

## Execution

- Recommended plan:
  docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-plan.md
- Recommended execution state:
  docs/plans/2026-05-31-agent-docs-intent-system-completion/2026-05-31-agent-docs-intent-system-completion-execution-state.md
- Status: accepted for Option C execution.
- Next-task source: this document

## Issue Summary

Issue #217 tracks residual gaps after backing the `task-tools` intent and
slimming `AGENT_HOME.md`.

The issue states that the core design is sound:

- `agent-docs` is catalog-driven.
- There are no hardcoded builtins.
- Intent names are free-form `Context(String)` values.
- Current `task-tools` usage is docs-only.

It then lists four residual gaps.

## Gaps To Resolve

### Gap 1: Finish-line gate hardcodes `project-dev`

Current state:

- `core/hooks/shared/hook_common.py` resolves the finish-line validation
  contract with `--intent project-dev`.
- `core/hooks/shared/user-prompt-agent-docs.sh` already enumerates every
  declared intent.

Impact:

- A future non-`project-dev` intent with a `[[validation]]` contract would be
  surfaced by the cue hook but not enforced by the finish-line gate.

Desired result:

- Runtime-kit finish-line enforcement is intent-aware and enforces every
  declared validation contract that applies to the current repo.

### Gap 2: Cue composer silently truncates at six docs per intent

Current state:

- `core/hooks/shared/user-prompt-agent-docs.sh` lists only `docs[:6]` per
  intent.
- No overflow marker tells the agent that more required docs exist.

Impact:

- A cue with more than six required docs can read as complete when it is only a
  truncated summary.

Desired result:

- The cue appends an explicit overflow marker, for example `+N more`, or uses
  an equivalent non-silent representation.

### Gap 3: `cli-tools.md` may be too noisy as a required `task-tools` doc

Current state:

- `AGENT_DOCS.toml` declares `core/policies/cli-tools.md` as required for
  `task-tools`.
- The file is a large reference document and is named in every session cue.

Impact:

- Cue noise increases even when `external-facts.md` is the only document that
  truly must be read before external-fact claims.

Desired result:

- Keep `external-facts.md` required.
- Make `cli-tools.md` optional, auditable, and available on demand unless a
  later decision reclassifies it.

### Gap 4: No guard against mistyped or declared-but-unresolved intents

Current state:

- `agent-docs preflight --intent no-such-intent` resolves successfully with an
  empty document set and no validation contract.
- This is compatible with the free-form intent model, but it gives callers no
  way to require that a requested intent is declared.

Impact:

- A typo such as `project_dev` can silently skip required docs.
- A hook or script can call an intent that no catalog entry declares and still
  receive a successful empty result.

Desired result:

- Add a nils-cli `agent-docs` primitive that lets callers fail closed when an
  explicitly requested intent is not declared or resolves to no relevant
  contract, without reintroducing hardcoded builtins.

## Selected Option C

The selected path completes all four gaps, not just the runtime-kit-local
items:

1. Open and prepare an L2 tracking record from #217.
2. Design the nils-cli `agent-docs` primitive for declared-intent guarding.
3. Implement and merge the nils-cli PR.
4. Release nils-cli and update the Homebrew tap.
5. Implement runtime-kit consumer changes for gaps 1-3 and integrate the new
   primitive for gap 4.
6. Bump the runtime-kit nils-cli pin and close the tracking issue.

## Non-goals

- Do not add keyword-gated intent surfacing.
- Do not hardcode intent names into nils-cli.
- Do not make `task-tools` conditional on English prompt text.
- Do not move the runtime-kit nils-cli pin before a released nils-cli version
  exists.
- Do not treat unvalidated local run state as more authoritative than provider
  issue evidence.

## Open Design Point

The nils-cli primitive should be decided in Step 2. The preferred starting
point is a caller opt-in fail-closed contract, for example:

```bash
agent-docs preflight --intent project-dev --require-declared-intent
```

The exact flag name and semantics belong to the nils-cli design spike.
