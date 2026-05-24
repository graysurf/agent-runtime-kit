# Project Local Smoke Fixture

This fixture proves the runtime-kit project-local contract for executable
`.agents/scripts` shims and `.agents/skills` project-local skill sources:

- `bench`
- `bootstrap`
- `demo`
- `deploy`
- `pre-pr`
- `release`

Each shim delegates to `.agents/scripts/<name>.sh` inside the target
repository. The scripts in this fixture are intentionally tiny and deterministic:
they write invocation markers under `PROJECT_LOCAL_SMOKE_OUT` and print a stable
`project-local-smoke:<name>:called` line.

The fixture also includes `.agents/skills/project-local-skill/SKILL.md` with a
skill-owned script so project-skill lifecycle checks can prove the canonical
project-local skill layout without touching runtime-kit manifests.
