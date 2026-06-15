# forge-cli PR ready GraphQL rate-limit hit

During PR #228 delivery for sympoies/symphony-board, `forge-cli pr ready 228
--provider github` failed with:

```text
GraphQL: API rate limit already exceeded for user ID <redacted>.
```

`gh api rate_limit` showed `graphql.remaining = 0` while REST/core still had
thousands of requests remaining. The workaround was to wait until the GraphQL
reset timestamp, verify `graphql.remaining = 5000`, then retry
`forge-cli pr ready`, wait checks, sweep review threads/tasks, and merge.
