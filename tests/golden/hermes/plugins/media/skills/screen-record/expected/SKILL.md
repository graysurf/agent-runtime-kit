---
name: screen-record
description: >
  Capture screenshots or recordings from windows or displays through the nils-cli `screen-record` command.
---

# Screen Record

## Contract

Prereqs:

- `screen-record` is installed from the released nils-cli package and available on `PATH`.
- The host supports the requested capture mode.
- macOS screen-recording permissions or Linux capture prerequisites are available before capture.

Inputs:

- Screenshot or recording mode.
- Window, app, active-window, display, or display-id selector.
- Output path or directory.
- Optional metadata, diagnostics, duration, audio, format, and if-changed settings.

Outputs:

- Screenshot image, recording file, metadata JSON, diagnostics artifacts, or selectable target list.

Failure modes:

- Capture permission is missing.
- The selected window or display cannot be resolved.
- Required recording backend is unavailable.

## Entrypoint

Use the released CLI directly:

```bash
screen-record --preflight
screen-record --list-windows
screen-record --screenshot --active-window --path /tmp/window.png
screen-record --display --duration 10 --path /tmp/session.mov --metadata-out /tmp/session.json
```

## Workflow

1. Run `--preflight` when host permissions or capture backend status is uncertain.
2. Use `--list-windows`, `--list-displays`, or `--list-apps` before selecting a target by id or name.
3. Prefer explicit `--path` for evidence artifacts that need to be linked from validation.
4. Use `--diagnostics-out` for failed or flaky recording checks.

## Boundary

`screen-record` owns capture and metadata mechanics. The caller owns choosing a non-sensitive target and deciding whether artifacts are temporary evidence or durable records.
