
Not applicable — this is a persistence component over SQLite, not a visual component. The only lifecycle it has is the tombstone: a message, label, connection or config row is live or tombstoned, and an upsert moves a tombstoned message or label back to live, while a tombstoned config or connection stays tombstoned and the upsert stores a new live row. A connection's `status` (`active`, `error`, `revoked`, `pending`) is data the caller writes through `updateSyncState`; the store holds no state machine over it.

