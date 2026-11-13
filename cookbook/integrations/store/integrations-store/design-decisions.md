
**Decision**: Delete by tombstone, never by removing the row.
**Rationale**: The type's doc comment calls it a local mirror of the hub's tables, whose rows carry `deleted_at` and `is_deleted`; keeping the row lets a later upsert revive it with its id and creation time. The cost is that content stays on disk (see Privacy).
**Approved**: pending

**Decision**: Key a connection upsert on provider and account address, ignoring case, among live rows.
**Rationale**: The doc comment says Gmail addresses are case-insensitive and that signing in again "updates the existing row and keeps its id". The tests `emailMatchingIgnoresCase` and `upsertConnectionReusesRowForSameEmail` pin it. A tombstoned connection does not match, so signing in after a delete makes a new row (`reUpsertAfterDelete`).
**Approved**: pending

**Decision**: Look up an existing message or label for an upsert across tombstoned rows too, and clear the tombstone.
**Rationale**: The unique indexes on `(connection_id, external_id)` forbid a second row, so the store must find the tombstoned one and revive it, as the doc comment says: "a tombstoned row is revived".
**Approved**: pending

**Decision**: Resume a page with a keyset (`after`) in addition to `offset`.
**Rationale**: The doc comment on `after` says a page resumed from the last row it was given "cannot skip or repeat rows when rows ahead of it change". An offset shifts when a row ahead is tombstoned; a key does not. `offset` stays for callers that want positional paging.
**Approved**: pending

**Decision**: Order by `internal_date` descending, then `id` ascending.
**Rationale**: `MessageKey` is documented as a message's place in that order; the id breaks ties so the key identifies one position. The mixed direction is why the `after` filter reads "date less than, or date equal and id greater than".
**Approved**: pending

**Decision**: Bind at most 500 ids per statement in `tombstoneMessages(connectionId:externalIds:)`, inside one transaction.
**Rationale**: The comment says 500 is "well under SQLite's 32766-variable limit". One transaction keeps the tombstone all-or-nothing. The source does not say why 500 and not another number.
**Approved**: pending

**Decision**: Cache `mail_class` on each message and tombstone by class with a column filter.
**Rationale**: The `EmailMessage.mailClass` comment says it is "Cached so queries and tombstoning need not re-derive it from `labelIds`". The cost is that a stale `mail_class` after a label change is the caller's to avoid by upserting the message again.
**Approved**: pending

**Decision**: Match label membership with `json_each` over the `label_ids` JSON text.
**Rationale**: Labels are stored as a JSON array in one TEXT column, so SQLite's `json_each` is the way to filter on them in SQL. The cost is that label filters cannot use an index.
**Approved**: pending

**Decision**: Clamp `limit` and `offset` to at least 0 and bind them as parameters.
**Rationale**: SQLite treats a negative `LIMIT` as no limit; clamping keeps a bad value from returning the whole table. The source does not state this reason.
**Approved**: pending

**Decision**: Deletes of an unknown config or connection are silent, while `updateSyncState` throws.
**Rationale**: A delete that finds nothing has reached its goal, so it is idempotent. `updateSyncState` has a caller that must know the connection is gone, and its doc comment states the throw. `finishActionLog` follows neither rule and is the open question on `log-finish-unknown`.
**Approved**: pending

**Decision**: Tombstoning a connection cascades to its messages and labels in the same transaction, and not to its action logs.
**Rationale**: The doc comment says "the connection's messages and labels are tombstoned with it". The action log has no `is_deleted` column, so it keeps its rows; the source states no reason.
**Approved**: pending

**Decision**: `replaceLabels` binds every kept external id in one `NOT IN` list without chunking.
**Rationale**: Technical debt that affects behavior: unlike the message tombstone, it relies on a mailbox having far fewer labels than SQLite's variable limit. The source has no comment on it.
**Approved**: pending

