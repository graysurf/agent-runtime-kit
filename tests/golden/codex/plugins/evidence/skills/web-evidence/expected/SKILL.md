---
name: web-evidence
description: >
  Capture redacted HTTP metadata, previews, and manifests through the nils-cli `web-evidence` command.
---

# Web Evidence

## Contract

Prereqs:

- `web-evidence` is installed from the released nils-cli package and available on `PATH`.
- External lookup policy has been satisfied before remote requests.
- The target URL and output directory are explicit.

Inputs:

- HTTP or HTTPS URL.
- Output directory.
- Optional method and JSON output format.

Outputs:

- Redacted HTTP evidence artifact directory and optional JSON summary.

Failure modes:

- Network request fails or times out.
- URL is invalid or unsupported.
- Output directory cannot be written.

## Entrypoint

Use the released CLI directly:

```bash
web-evidence capture https://example.com --out /tmp/web-evidence
web-evidence capture https://example.com --out /tmp/web-evidence --format json
web-evidence capture https://example.com --out /tmp/web-evidence --method head
```

## Workflow

1. Use web evidence when a static HTTP source needs a durable, redacted evidence bundle.
2. Capture the exact URL used to support the claim or validation step.
3. Link the artifact directory from session, validation, review, or issue evidence.
4. Report source failures directly instead of quoting uncaptured or stale web content.

## Boundary

`web-evidence` owns HTTP capture and artifact layout. Source selection, claim synthesis, and citation judgment remain caller responsibilities.
