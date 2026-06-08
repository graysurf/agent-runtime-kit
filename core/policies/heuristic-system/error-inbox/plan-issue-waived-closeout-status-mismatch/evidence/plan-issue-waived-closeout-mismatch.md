# Evidence: plan-issue close-ready accepts waived task but record close rejects it

Date: 2026-06-08

During sympoies/nils-cli issue #797 closeout, the strict non-mutating gate
passed with a terminal task ledger containing a conditional row marked
`waived`:

```text
plan-issue tracking close-ready --profile tracking --expect-visible
ready=true, blockers=[]
```

The following `record close` attempt failed:

```text
record-close-gate-failed:
strict closeout gate blocked: state-tasks-incomplete
(execution state: complete but tasks are not all done/deferred)
```

Diagnosis:

- `tracking close-ready` treats `waived` as a terminal ledger status.
- `record close` only accepted `done` or `deferred` in the state task payload.
- `plan-tooling ledger-update --help` offered `waived` but not `deferred`,
  making the two closeout gates inconsistent for conditional or waived rows.

Workaround used:

- Reclassify the conditional release/runtime follow-up row as `done` because
  the decision was completed and no release/runtime install was requested.
- Repost final state/session.
- Rerun close-ready, then rerun `record close`.

Durable links:

- Tracking issue: https://github.com/sympoies/nils-cli/issues/797
- Closeout comment: https://github.com/sympoies/nils-cli/issues/797#issuecomment-4647754767
- Merged PR: https://github.com/sympoies/nils-cli/pull/798

Runtime evidence pointer:

- `$HOME/.local/state/agent-runtime-kit/out/projects/sympoies__nils-cli/20260608-173644-skill-usage/skill-usage.record.json`
