# Additional evidence: skill-usage concurrent validation writes

During the 2026-06-10 `symphony-board` `$deliver-pr` run for PR #138, multiple
`skill-usage record-validation` commands were accidentally launched in parallel
against the same output directory:

- `$HOME/.local/state/agent-runtime-kit/out/projects/sympoies__symphony-board/20260610-000211-skill-usage/`

Observed behavior:

- The individual parallel `record-validation` calls returned success.
- `skill-usage verify` later reported `ok: true` with no violations.
- The verified record did not retain every intended validation write from the
  parallel batch. In particular, the hook-environment targeted release-script
  test and one post-fix typecheck evidence entry were absent from the final
  validation list, while nearby writes from the same closeout were retained.

Why this matters:

- This repeats the active case pattern: same-record `record-*` mutations can
  silently drop evidence while still producing a verify-clean envelope.
- The current workaround remains valid: serialize all `skill-usage record-*`
  writes for a given `--out` directory.

Task outcome:

- The product PR still merged successfully.
- The missing validation evidence was represented in the PR body / provider
  review outcome and the command output, but the retained `skill-usage` envelope
  is another concrete example of the concurrency gap.
