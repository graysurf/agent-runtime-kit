# Harness Shape Fixture

- arkit source: `core/skills/<domain>/<skill>/`, rendered tree;
  2 Codex plugin-scoped skill entries are declared in `manifests/skills.yaml`
  (`manifests/skills.yaml:12-30`).
- Acceptance lane: sandbox install rehearsal diffs
  `tests/sandbox/codex/expected-skills.txt`; runtime-smoke deterministic mode
  exercises representative skills
  (`tests/sandbox/codex/expected-skills.txt:1-2`).
