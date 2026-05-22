---
name: browser-session
description:
  Record browser-session goals, steps, artifacts, and verification status through the nils-cli `browser-session` command.
---

# Browser Session

## Contract

Prereqs:

- `browser-session` is installed from the released nils-cli package and available on `PATH`.
- The browser target, acceptance goal, and evidence output directory are known.
- Browser automation or manual browser work is performed by the caller, not by this primitive.

Inputs:

- Output directory.
- Target URL or application surface.
- Goal statement.
- Step actions, pass/fail status, and optional artifact paths.

Outputs:

- Deterministic browser-session evidence record and verification result.

Failure modes:

- Session record has no goal, target, or passing verification step.
- Referenced artifacts are missing.
- The output directory is not writable.

## Entrypoint

Use the released CLI directly:

```bash
browser-session init --out /tmp/browser --target http://localhost:3000 --goal "verify checkout flow"
browser-session record-step --out /tmp/browser --action "opened checkout page" --status pass --artifact screenshot.png
browser-session verify --out /tmp/browser --format json
browser-session show --out /tmp/browser
```

## Workflow

1. Initialize the session before browser work starts.
2. Record each meaningful navigation, interaction, assertion, or artifact.
3. Use artifact paths for screenshots, videos, HTTP evidence, or logs that support the step.
4. Verify the session before using it as acceptance evidence.

## Boundary

`browser-session` owns evidence record structure. Browser operation, visual judgment, and product acceptance decisions remain the caller's responsibility.
