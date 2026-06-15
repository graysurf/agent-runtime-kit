# forge-cli pr deliver reported valid test-first evidence as unreadable

Date: 2026-06-15

During `graysurf/agent-runtime-kit` issue #381 delivery, the existing draft PR
#388 was updated and the local `test-first-evidence` record verified
successfully with `test-first-evidence verify`.

The follow-up adoption command:

```bash
forge-cli pr deliver --provider github --kind bug --title "fix(hooks): reject value-suffixed Bash metadata options" --body-file <pr-body> --base main --method squash --label type::bug --label area::hooks --label size::s --label risk::medium --label-catalog manifests/forge-labels.yaml --strict-labels --test-first-evidence <test-first-evidence.json> --no-merge --format json
```

failed after adopting PR #388 with:

```text
code=test_first_evidence_unreadable
message=could not read test-first evidence at '<test-first-evidence.json>'
```

The same evidence path was readable by the shell, and
`test-first-evidence verify --out <evidence-dir> --format json` returned
`ok=true`, `complete=true`, and no missing fields.

Impact:

- The delivery macro could not be re-run after a force-push/rebase even though
  the evidence record was valid.
- The delivery had to continue through lower-level `forge-cli pr checks`,
  `forge-cli pr ready`, `forge-cli pr merge`, and explicit issue close surfaces.

Current workaround:

- Verify the evidence record directly with `test-first-evidence verify`.
- Continue with the lower-level PR lifecycle commands when the PR already exists
  and provider checks are clean.

Resolution (2026-06-16):

- Operator misuse, not a `forge-cli` defect. The `--test-first-evidence` flag
  takes a DIR (clap `value_name = "DIR"`); the gate reads
  `<dir>/test-first-evidence.json`. Above, `verify` was run with the directory
  (`--out <evidence-dir>`) but `pr deliver` was given the JSON *file*
  (`--test-first-evidence <test-first-evidence.json>`), so the gate read
  `<file>/test-first-evidence.json` and returned `test_first_evidence_unreadable`
  ("Not a directory").
- Reproduced locally: the verify-clean directory passes the gate; the JSON file
  fails with the exact error. Correct usage: `--test-first-evidence "$EVIDENCE_DIR"`.
- Case resolved `wontfix`.
