# Resolution Evidence: completion parity stale-content gate

- sympoies/nils-cli#831 merged on 2026-06-12 as squash merge
  `0e47cbe4de01c27848dc53880204425eedef7196`.
- sympoies/nils-cli#827 was closed after the merge.
- The delivered gate adds `scripts/ci/completion-freshness-audit.sh` and its
  self-test, wires the audit into local/CI checks, and refreshes stale
  committed completion assets.
- Validation passed:
  `bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast`; GitHub CI
  `test`, `test_macos`, `coverage`, and CodeQL; pre-merge review outcome
  `proceed-to-merge` with no findings.
