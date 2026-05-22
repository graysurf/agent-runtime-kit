# Project Local Smoke Fixture

This fixture proves the runtime-kit project-local shim contract for:

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
