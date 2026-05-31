# Codex plugin.json skills array drift not caught by audit-drift

## Status

- Status: promoted
- First observed: 2026-05-31
- Area: audit-drift; skill governance; Codex plugin metadata
- Severity: low
- Tracking: https://github.com/graysurf/agent-runtime-kit/issues/225

## Signal

PR #220 renamed the meta skill `sync-runtime-skills` -> `sync-runtime-surfaces`
across `manifests/plugins.yaml`, `manifests/skills.yaml`,
`targets/codex/link-map.yaml`, the rendered goldens, and the Claude plugin
manifest, but the Codex meta plugin manifest
`targets/codex/plugins/meta/.codex-plugin/plugin.json` kept the old entry:

    { "id": "sync-runtime-skills", "source": "core/skills/meta/sync-runtime-skills" }

`core/skills/meta/sync-runtime-skills` no longer exists, so the entry advertised
a skill id backed by a dangling source path. The full CI gate
(`scripts/ci/all.sh`, positions 1-13, including `agent-runtime audit-drift` and
the sandbox install rehearsal) stayed green and the stale entry merged to
`main`. It was caught and fixed by hand only during the follow-up cleanup in
#224.

`audit-drift` reports the Codex `skills` field as a documented codex-only
`intentional-difference` and never compares its `id` / `source` entries against
the skill manifests, so this array can drift silently.

## Evidence

- Raw record: not captured (manual diagnosis, 2026-05-31); no transcript
  retained.
- `agent-runtime audit-drift` on the #220 merge state: `clean (20 findings)`,
  all documented intentional differences, none flagging the stale meta entry.
- `agent-runtime render` writes no Codex `.codex-plugin/plugin.json` into
  `build/`, confirming the committed `targets/` copy is hand-maintained rather
  than render-regenerated.
- The runtime-kit install is driven by `targets/codex/link-map.yaml`
  (correctly updated in #220), not by the plugin.json `skills` array, which is
  why install / `sandbox-install-rehearsal` did not surface the drift.

## Impact

A renamed or removed meta skill can still be advertised to live Codex/Claude
homes with a `source` pointing at a non-existent directory, while every gate
(`audit-drift`, golden diff, skill-surface doctor, sandbox install rehearsal)
stays green. Delivery agents can mistake a passing `scripts/ci/all.sh` for full
coverage of the Codex plugin skill list.

## Current Workaround

After any skill id rename/removal, manually reconcile
`targets/codex/plugins/<domain>/.codex-plugin/plugin.json` `skills[]` against
`manifests/plugins.yaml` (`contained_skills`) and `manifests/skills.yaml`
(`source`), and confirm each `source` path exists. This was done by hand in
#224.

## Promotion Criteria

Promote when a gate (upstream `agent-runtime audit-drift`, or the repo-owned
`scripts/ci/skill-governance-audit.sh`) asserts that every Codex
`.codex-plugin/plugin.json` `skills[]` entry has an `id` present in the matching
plugin's `contained_skills` and a `source` that matches `manifests/skills.yaml`
and exists on disk, with a fixture proving a stale entry fails CI.

## Next Action

None. Fixed by #226; #225 was closed.

Lifecycle link: `https://github.com/graysurf/agent-runtime-kit/pull/226`

## Archive

- Archived: 2026-05-31
- Reason: Fixed by #226 and issue #225 closed.
- Durable link: `https://github.com/graysurf/agent-runtime-kit/pull/226`
