# project-bump-version-tag-release post-merge checkout failure (redacted)

Run from a dedicated worktree under <workspace>/worktrees/.../release-1-6-0:

    info: opening + waiting + merging release PR via forge-cli pr deliver
    delivered: 6 steps
    info: switching back to main and fast-forwarding
    fatal: 'main' is already used by worktree at '<primary checkout>'
    === release script exit: 128 ===

Recovery (from the primary main checkout):

    git fetch origin main && git merge --ff-only origin/main
    git tag -a v1.6.0 -m v1.6.0 <merge-sha>   # signed; tag.gpgsign=true
    git push origin v1.6.0                      # triggers release.yml
    project-bump-version-tag-release.sh --from-tap --version 1.6.0

Observed identically for v1.4.0, v1.5.0, v1.6.0.
