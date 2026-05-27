# Heuristic System Pointer

`core/policies/heuristic-system/HEURISTIC_SYSTEM.md` is the full routing policy
for turning workflow failures and repeated lessons into durable knowledge.

- Same-turn transient fixes need no retained record; mention them in the reply.
- Important unresolved workflow gaps or suspected nils-cli / primitive bugs go
  through `heuristic-inbox`, with version, minimal repro, upstream issue link
  when found, and the current workaround.
- Reproducible product bugs get a focused test or script fix. Repeated
  cross-skill lessons belong in operation records; stable policy belongs in
  `AGENT_HOME.md`, project policy files, or the relevant skill `SKILL.md`.
- After the session goal is achieved, use `$heuristic-session-closeout` to
  review evidence and preserve warranted retained records on `main`.
- Active inbox entries live under
  `core/policies/heuristic-system/error-inbox/`; archive promoted or `wontfix`
  entries via `heuristic-inbox`, never by deleting them in place.
