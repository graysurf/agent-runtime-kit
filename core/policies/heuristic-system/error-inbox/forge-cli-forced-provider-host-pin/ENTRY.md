# forge-cli forced --provider pins host to provider default (gitlab.com), ignoring the remote

## Status

- Status: open
- First observed: 2026-05-31
- Area: forge-cli provider detection
- Severity: medium
- CLI versions: forge-cli 0.31.3 (plan-issue 0.31.3 via ForgeCliAdapter)

## Signal

`forge-cli`'s `detect()` returns immediately on a forced `--provider`:
`ProviderHint::Forced(p)` yields `host = default_host_for(p)` (`gitlab.com` for
GitLab) and never consults the remote (`crates/forge-cli/src/provider.rs`).
There is no `--host` override. So any caller that forces `--provider gitlab` —
including `plan-issue-cli`'s `ForgeCliAdapter` (`base_args` emits
`--provider gitlab --repo <slug>`) — computes the host as `gitlab.com`, not a
self-hosted instance like `gitlab.<corp>.com`.

In practice the issue/MR operations still reached the self-hosted host during
Task 3.2 because `forge-cli` does not pass `--hostname` for them, so `glab`
resolves the host from its own config (and only one host was authed). But that
is incidental: the forced-provider host is wrong by construction, and a box with
multiple authed GitLab hosts (or any path that does honor `forge-cli`'s host,
e.g. the `--with-comments` notes call derives host from the issue `web_url` to
work around exactly this) would target the wrong instance.

## Evidence

- Raw record: not captured (diagnosed live during Task 3.2, 2026-05-31);
  attach redacted evidence later via `heuristic-inbox ingest-evidence`.
- Source: `crates/forge-cli/src/provider.rs` `detect()` — the
  `ProviderHint::Forced` branch returns `default_host_for(provider)` before the
  `remote_url_lookup` path.
- Probe: `forge-cli --provider gitlab --repo terrylin/plan-tracking-testbed-gitlab
  --dry-run --format json issue list` → plan is `glab issue list ... --repo <slug>`
  with no `--hostname` (host delegated to `glab`).
- `classify_host` accepts `gitlab.<corp>` (`starts_with("gitlab.")`), so the
  remote-detection path *would* resolve a self-hosted host correctly — it is
  only the forced path that pins `gitlab.com`.

## Impact

A future agent forcing `--provider gitlab` against a self-hosted GitLab can
silently target `gitlab.com` (or rely on `glab`'s ambient default host). Any
`forge-cli` code path that uses its own computed host against a forced provider
will hit the wrong instance.

## Current Workaround

Do not force `--provider`. Run `forge-cli` from a checkout of the target repo so
`detect()` reads provider AND host from that remote. The `test-plan-tracking`
driver's `tb_forge` helper does exactly this (`graysurf/agent-runtime-kit#210`):
it `cd`s into `TESTBED_ROOT` and never passes `--provider`.

## Promotion Criteria

Promote when `forge-cli` gains a `--host` global override, or forced
`--provider` consults `--remote` / the cwd remote for the host instead of
defaulting; validated by a forced-provider call resolving a self-hosted GitLab
host. (Not yet filed as a `forge-cli` issue — file before promotion.)

## Next Action

Upstream `forge-cli`: add a `--host` override, or have forced `--provider`
consult `--remote` / the cwd remote for the host. Workaround: omit `--provider`
and run `forge-cli` from the target repo checkout so `detect()` reads
provider+host from its remote (the `test-plan-tracking` driver's `tb_forge`
does this).
