# plan-issue-record-post-concurrency promotion evidence

## Upstream route

- Issue: https://github.com/sympoies/nils-cli/issues/792
- Draft PR: https://github.com/sympoies/nils-cli/pull/793
- Branch: fix/plan-issue-lifecycle-lock
- Commit: 19b50aeae601e4cfe5ccd531ba7feeb61b3e3a3a

## Implementation

- Added issue-scoped fail-fast lifecycle mutation lock for live provider issue comment streams.
- Lock identity includes provider, host/default, repo slug, issue number, and record profile.
- Applied to live record post and tracking checkpoint live posting paths.

## Validation

- cargo fmt -p nils-plan-issue: passed
- cargo test -p nils-plan-issue lifecycle_lock: passed
- cargo test -p nils-plan-issue --test integration record_post_live_refuses_when_lifecycle_lock_is_busy: passed
- cargo test -p nils-plan-issue --test integration tracking_checkpoint_live_fixture_refuses_when_lifecycle_lock_is_busy: passed
- bash scripts/ci/nils-cli-checks-entrypoint.sh --local-fast: passed
- agent-runtime-kit runtime smoke with local nils-cli 1.0.12-dirty surface, dispatch domain: 13 passed, 0 failed
- agent-runtime-kit ad-hoc busy-lock e2e: returned plan-issue-lifecycle-lock-busy for a pre-held lifecycle lock

## Runtime-kit decision

- No runtime-kit skill policy guard is needed; the durable owner is the nils-cli primitive.
- Runtime-kit should consume the behavior through the next nils-cli release/pin rather than local skill serialization.
