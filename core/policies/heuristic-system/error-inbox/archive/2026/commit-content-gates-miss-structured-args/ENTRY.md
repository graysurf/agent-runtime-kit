# semantic-commit message-content hooks only parse --message/-m; --trailer / --message-file / structured fields bypass them

## Status

- Status: promoted
- First observed: 2026-05-28
- Co-author gate fixed: 2026-05-28 (PR #140, squash 008a930)
- Area: core/hooks/shared (semantic-commit message-content gates)
- Severity: medium

## Signal

`block-claude-coauthor-trailer.py` and `semantic-commit-body-gate.py` both gate
on `hook_common.extract_message()`, which only recovers `--message` / `-m`
bodies (heredoc / double- / single-quoted). A `semantic-commit commit` that
carries content via `--trailer`, `--message-file`, or structured `--subject` /
`--body-bullet` makes `extract_message()` return `None`, so the gate falls
through to `ALLOW`. A Claude `Co-Authored-By` trailer reached PR #139 via
`--trailer` for exactly this reason.

## Evidence

- Raw record: PR #140 (merged, squash `008a930`) and its test-first run — the
  three bypass tests reported `FAILED (failures=3)` against the pre-fix gate and
  `OK` after the fix (`tests/hooks/test_shared_hooks.py`).
- PR #140 fixed the **co-author** gate by scanning every source via new
  `hook_common.iter_flag_values` + `read_message_file` primitives, with
  test-first coverage in `tests/hooks/test_shared_hooks.py`.
- `semantic-commit-body-gate.py` still consumes raw `extract_message()` and so
  still under-enforces the 1-2 bullet rule on `--message-file` and structured
  `--subject` + `--body-bullet` commits.

## Impact

Mechanical commit policy gates (no-Claude-attribution; non-trivial commits need
a body) are silently unenforced for the most idiomatic semantic-commit argument
forms. The co-author half is resolved; the body-gate half remains open.

## Current Workaround

For the body gate, pass content via `--message` / `-m` when enforcement matters.
The body gate can be extended to reuse the same `iter_flag_values` +
`read_message_file` scan the co-author gate now uses.

## Promotion Criteria

Promote once `semantic-commit-body-gate.py` covers the same argument sources
(reusing the shared `hook_common` primitives) with failing-first test coverage,
or an explicit accepted-risk decision for the body gate is recorded here.

## Prevention Rule

A message-content commit gate must scan every source `semantic-commit` accepts
for that content (`--message`/`-m`, `--message-file`, `--subject`,
`--body-bullet`, `--trailer`), not just the `--message` body — otherwise the
guardrail is bypassable through ordinary, documented flags.

## Next Action

None. Resolved: semantic-commit-body-gate.py now resolves subject/body from every message source semantic-commit accepts (--message/-m, --message-file, and the structured --type/--scope/--subject + --body-bullet form, reconstructing the conventional header for the trivial check), reusing hook_common.iter_flag_values / read_message_file; --trailer is intentionally excluded since a trailer is not an explanatory body. Failing-first coverage added in tests/hooks/test_shared_hooks.py (3 bypass repros went None->block). Delivered on branch feat/fix-body-gate-heuristic-closeout alongside this heuristic-inbox closeout sweep.

## Archive

- Archived: 2026-06-01
- Reason: Body-gate half closed: semantic-commit-body-gate.py covers --message-file + structured --subject/--body-bullet with failing-first tests (co-author half was PR #140)
