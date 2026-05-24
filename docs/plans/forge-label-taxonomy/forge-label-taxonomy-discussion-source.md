# Forge Label Taxonomy Discussion Source

- Status: ready for plan execution
- Date: 2026-05-24
- Source: user discussion about unifying GitHub issue / PR labels and
  GitLab issue / MR labels across agent workflows.
- Intended next step: open a lightweight tracking issue in
  `graysurf/agent-runtime-kit`, then open a linked `sympoies/nils-cli`
  follow-up for the `forge-cli` provider implementation.

## Execution

- Recommended plan: docs/plans/forge-label-taxonomy/forge-label-taxonomy-plan.md
- Recommended execution state: docs/plans/forge-label-taxonomy/forge-label-taxonomy-execution-state.md

## Purpose

Agents need a provider-neutral label system that works the same way on GitHub
and GitLab. The taxonomy must be small enough for daily use, machine-readable
enough for `forge-cli` to audit and ensure, and explicit enough that agents can
apply labels automatically when creating issues, pull requests, and merge
requests.

## Confirmed Facts

- [U1] The desired taxonomy groups are at least size, severity, and urgency /
  priority, with room for other practical groups.
- [U2] The accepted baseline groups are `type::`, `area::`, `priority::`,
  `severity::`, `size::`, `state::`, plus optional `risk::` and `provider::`.
- [U3] The user wants the system to actually run, not only exist as policy:
  provider labels should be confirmed or created, agent rules should describe
  when to use them, and agents should automatically apply them to issue and
  PR/MR creation.
- [F1] `agent-runtime-kit` PR/MR skill sources route provider mutation through
  the released `forge-cli` surface.
- [F2] `nils-cli` README describes `forge-cli` as the provider-neutral wrapper
  for GitHub and GitLab PR/MR plus issue lifecycle operations.
- [F3] Current `forge-cli` supports labels on `pr create`, `issue create`,
  `issue edit`, `issue list`, `pr edit`, `pr view`, and `issue view`.
- [F4] Current `forge-cli pr deliver` does not expose label arguments and its
  create step passes an empty label list.
- [F5] Both `gh label` and `glab label` expose label list/create/edit
  subcommands, so `forge-cli` can own provider-neutral label ensure and audit.
- [I1] Therefore, `agent-runtime-kit` should own taxonomy policy, catalog
  source, and skill guidance; `nils-cli` should own provider label
  administration and create/deliver label application.

## Decisions

1. Use GitLab-style scoped names for every shared group, such as
   `type::bug`, `priority::p1`, and `size::m`. GitHub treats them as plain
   label strings, while GitLab keeps scoped label behavior.
2. Keep the required taxonomy groups compact:
   `type::`, `area::`, `priority::`, `severity::`, `size::`, and `state::`.
3. Add optional groups for workflow automation:
   `risk::`, `provider::`, and `workflow::`.
4. Do not create a separate `urgency::` group in the first version. Use
   `priority::p0` through `priority::p3` for scheduling order and
   `severity::s0` through `severity::s3` for impact.
5. Keep repo-specific `area::` labels extensible. The shared catalog should
   define required core areas and allow per-repo extensions.
6. Implement provider label lifecycle in `nils-cli` / `forge-cli`, not inside
   `agent-runtime-kit` skills.
7. Update agent policy and skills only after the CLI can audit/ensure labels
   and carry labels through both `pr create` and `pr deliver`.
8. Preserve existing `plan` and `issue` labels during rollout, then map them to
   `workflow::plan` / `workflow::tracking` once ensure support exists.

## Proposed Taxonomy

Core groups:

| Group | Items | Required use |
| --- | --- | --- |
| `type::` | `bug`, `feature`, `improvement`, `refactor`, `docs`, `test`, `chore`, `spike` | Issue and PR/MR creation |
| `area::` | repo-defined values such as `cli`, `skills`, `hooks`, `docs`, `ci`, `runtime`, `provider`, `infra` | Issue and PR/MR creation |
| `priority::` | `p0`, `p1`, `p2`, `p3` | Issues after triage |
| `severity::` | `s0`, `s1`, `s2`, `s3` | Bug, security, and incident issues |
| `size::` | `xs`, `s`, `m`, `l`, `xl` | PR/MR creation and ready issues |
| `state::` | `needs-triage`, `ready`, `blocked`, `needs-info`, `needs-decision`, `do-not-merge` | Workflow exceptions |

Optional automation groups:

| Group | Items | Required use |
| --- | --- | --- |
| `risk::` | `low`, `medium`, `high` | Higher-risk PR/MR changes |
| `provider::` | `github`, `gitlab`, `both`, `neutral` | Provider workflow/tooling work |
| `workflow::` | `plan`, `dispatch`, `tracking`, `follow-up` | Agent-owned durable workflow records |

## Target Behavior

- `forge-cli label audit --catalog <catalog> --provider github|gitlab --repo
  <owner/repo>` reports missing labels, color/description drift, unknown shared
  labels, mutually exclusive group conflicts, and optional cleanup candidates.
- `forge-cli label ensure --catalog <catalog>` creates missing labels and can
  update color/description drift, but never deletes or renames labels by
  default.
- `forge-cli pr create` and `forge-cli pr deliver` accept repeatable
  `--label` flags for both GitHub PRs and GitLab MRs.
- Agent PR/MR and issue skills choose labels before live provider mutation,
  run label ensure when needed, and apply the selected labels in the provider
  create call.
- Existing provider workflows remain usable during rollout through warning-mode
  validation before strict enforcement.

## Open Questions

- Whether the default catalog path should be `manifests/forge-labels.yaml`,
  `core/policies/forge-labels.yaml`, or both with one generated from the other.
  Lean toward `manifests/forge-labels.yaml` as the machine-readable source and
  `core/policies/forge-label-taxonomy.md` as the human policy.
- Whether `forge-cli label ensure` should update color and description drift by
  default or require an explicit `--update-existing` flag. Lean toward an
  explicit flag.
- Whether strict label validation should ship as a default for `pr create` /
  `issue create`, or first as opt-in `--strict-labels`. Lean toward opt-in
  strict mode for the first rollout.
