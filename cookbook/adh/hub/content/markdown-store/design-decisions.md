
**Decision**: Keep the revive-on-conflict update's guard clause — reviving only a row whose delete column is set — so that re-adding an edge, assignment, or keyword that is already live changes no columns, rather than letting the upsert unconditionally rewrite the updated-at and ordering columns on every call.
**Rationale**: An unconditional update would stage a mutation into the taxonomy outbox on every idempotent re-add, since staging follows the count of rows the database engine reports as actually changed; the guard makes "already exists and live" distinguishable from "actually changed" at the SQL level instead of requiring a pre-read.
**Approved**: pending

**Decision**: Add a local-only `local_version` per document as the concurrency token and the change-feed version, rather than reusing the server's `current_version`.
**Rationale**: The server's version moves only when adh accepts a write, so it cannot order local writers against each other or against a pull; a local counter bumped by every local write and every applied pull can. It never travels, because adh has no such column.
**Approved**: pending

**Decision**: An expected version is optional on update, mutate and delete, and omitting it writes unconditionally.
**Rationale**: Existing callers (the app's own notes storage) have no token to quote and kept their last-writer-wins behavior; a daemon serving several clients quotes one and gets a stale error instead of overwriting.
**Approved**: pending
