# Releasing

`agent-runtime-kit` ships one published artifact: the standalone Linux container
image (see `docker/`) published to the GitHub Container Registry (GHCR) at
`ghcr.io/graysurf/agent-runtime-kit`. This document defines how versions are
named and how a release is cut.

## Versioning — CalVer

Releases use **CalVer**: a date-stamped tag `vYYYY.MM.DD` (zero-padded), e.g.
`v2026.05.30`. The image is a *snapshot of the runtime surface as of that date*.
The kit is a continuously-evolving config / skills / hooks / docs layer with no
API-compatibility contract, so a dated snapshot is the honest version unit.

- One release per day is the norm. If a second release is genuinely needed the
  same day, re-run the published release's workflow (it rebuilds the same tag)
  or cut the next day's date.
- The bundled `nils-cli` version is **independent** of the CalVer tag: the image
  always builds against `docs/source/nils-cli-pin.yaml` (the repo's pin gate).
  The CalVer tag versions the kit snapshot, not its `nils-cli` dependency.

## Published image tags

Each release publishes, for `linux/amd64` and `linux/arm64`:

| Tag | Example |
| --- | --- |
| Dated | `ghcr.io/graysurf/agent-runtime-kit:2026.05.30` |
| Rolling | `ghcr.io/graysurf/agent-runtime-kit:latest` (non-prerelease only) |

## Cutting a release

1. Make sure `main` is in the state you want to ship — the image bakes the
   source tree, so whatever is on `main` is what the image contains.
2. Create the GitHub Release. This creates the tag and fires the publish
   workflow:

   ```bash
   gh release create "v$(date +%Y.%m.%d)" --generate-notes \
     --title "v$(date +%Y.%m.%d)"
   ```

3. `.github/workflows/publish-image.yml` then runs on `release: published`:
   - resolves the `nils-cli` pin from `docs/source/nils-cli-pin.yaml`,
   - builds `linux/amd64` and smoke-tests it (`claude` / `codex` /
     `agent-runtime` versions and the rendered-home symlinks),
   - builds multi-arch and pushes to GHCR with the dated tag plus `latest`.

Mark the GitHub Release as a **pre-release** to skip the `latest` tag.

## One-time: make the package public

GHCR packages are **private** by default. After the first successful publish,
open the package from the repository's **Packages** section →
**Package settings** → **Change visibility** → **Public**. This is a one-time
manual step; subsequent pushes keep the chosen visibility.

## Pulling the image

```bash
docker pull ghcr.io/graysurf/agent-runtime-kit:latest
docker run --rm -it ghcr.io/graysurf/agent-runtime-kit:latest
```
