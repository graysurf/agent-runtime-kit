# gh GraphQL rate-limit exhaustion during release CI polling (redacted)

After a ~10 min 25s gh run-list poll loop on release.yml, the resume step:

    $ gh -R <repo> release view v1.6.0 --json assets,url
    GraphQL: API rate limit already exceeded for user ID <id>.

    $ gh api rate_limit --jq '.resources'
    {"core":{"remaining":4821,"reset":...},
     "graphql":{"remaining":0,"reset":<~134s out>},
     "search":{"remaining":30}}

REST cross-check succeeded immediately (core budget, GraphQL-free):

    $ gh api repos/<repo>/releases/tags/v1.6.0 --jq '{name,assetCount:(.assets|length)}'
    {"assetCount":8,"name":"v1.6.0"}   # release was fully published
