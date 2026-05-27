# Codex Skill Discovery Cutover Execution State

## Current State

- Status: superseded by codex-skill-surface-acceptance-cutover for Sprint 1 preflight
- Target scope: original plan covers Sprint 1 (discovery contract), Sprint 2 (runtime-kit Codex surface), and Sprint 3 (reversible alias retirement)
- Execution window: 2026-05-23 onward
- Staged execution confirmation: not applicable
- Current task: Sprint 1 preflight is delegated; Sprint 2 and Sprint 3 still owned by the original plan
- Next task: see codex-skill-surface-acceptance-cutover Sprint 3 for live Codex Desktop acceptance and alias decision
- Last updated: 2026-05-23 CST
- Branch/commit/PR: tracked via issue #43 (closed) and successor issue #55
- Source document: docs/plans/2026-05-22-codex-skill-discovery-cutover/codex-skill-discovery-cutover-plan.md
- Direct source-doc execution waiver: not applicable

## Successor Plan

The Codex Skill Surface Acceptance Cutover plan (issue #55) supersedes the
original Sprint 1 preflight model. The released `agent-runtime doctor --class
skill-surface --product codex` diagnostic is now the deterministic shape
preflight wired into `scripts/ci/all.sh` position 6; that gate replaces the
"prove what Codex Desktop reads" research lane in the original Sprint 1.

The original plan's Sprint 2 (runtime-kit Codex surface implementation) is
substantially complete: required acceptance skills are present in
runtime-kit (`conversation.discussion-to-implementation-doc`,
`conversation.handoff-session-prompt`,
`dispatch.execute-plan-tracking-issue`,
`dispatch.deliver-plan-tracking-issue`, `meta.semantic-commit`),
`targets/codex/link-map.yaml` lists the directory-symlink entries, and
`tests/sandbox/codex/expected-skills.txt` covers the acceptance set.

The original plan's Sprint 3 (reversible alias retirement) is still open and
is the live acceptance window owned by the successor plan's Sprint 3. See
`docs/plans/2026-05-23-codex-skill-surface-acceptance-cutover/` for the live protocol,
expected `codex debug prompt-input` evidence, rollback commands, and the
alias retention decision record.

## Shape vs Live Boundary

`agent-runtime doctor --class skill-surface --product codex` is shape
validation only. A clean shape report (`checks>=baseline`, `ok=checks`,
`warn=0`, `block=0`) is necessary but not sufficient for live Codex Desktop
skill discovery. The successor plan retains the live acceptance contract:
a fresh Codex Desktop session must capture `codex debug prompt-input`
evidence with `$HOME/.agents` absent or disabled inside a reversible window
before the compatibility alias is retired.
