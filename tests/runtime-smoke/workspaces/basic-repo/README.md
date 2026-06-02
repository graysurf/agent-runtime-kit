# Runtime Smoke Basic Repo

This fixture is the default workspace for deterministic runtime skill probes.
The fixture path only needs to exist so the acceptance matrix can
refer to a committed workspace. Probes can add tightly scoped files here
when individual skill probes need sample inputs, fixture-local git state, or
controlled diffs.

The fixture must stay offline and credential-free. Tests may write only to a
temporary output root, a caller-provided artifact directory, or fixture-local
scratch paths that are removed by the runner.
