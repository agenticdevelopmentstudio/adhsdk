
**Decision**: Keep every JSON value and timestamp as TEXT rather than using a native JSON or date type.
**Rationale**: The doc comment states "JSON columns are TEXT, timestamps are ISO-8601 UTC strings", and says names and columns follow adhbackend; SQLite has no date type and ISO-8601 UTC strings sort as text.
**Approved**: pending

**Decision**: Declare `integration_email_messages_external` and `integration_email_labels_external` as UNIQUE on `(connection_id, external_id)`, but leave `integration_connections_account` non-unique.
**Rationale**: The unique indices make a provider's message or label id a stable key per connection, and backs the one-row-per-message result that `IntegrationsStoreTests.upsertMessagesIsIdempotent` checks (the store's `upsertMessages` looks up the existing row by that key and reuses its `id`). The connections index is only a lookup aid; the source gives no comment on why it is not unique, and `IntegrationsStoreTests.upsertConnectionReusesRowForSameEmail` shows the store, not the schema, prevents duplicate accounts.
**Approved**: pending

**Decision**: Tombstone rows with `deleted_at` (and `is_deleted` on messages and labels) instead of deleting them, and leave the action log without either column.
**Rationale**: The `IntegrationsStore` doc comment defines "live" as `deleted_at IS NULL` for connections and configs and `is_deleted = 0` for messages and labels, and a tombstoned message keeps its unique key. The action log is an append-style record with only `created_at` and `updated_at`.
**Approved**: pending

**Decision**: Declare no foreign keys, CHECK constraints or enum constraints.
**Rationale**: The DDL contains none. Referential and value rules live in the record and store layers, so a port must enforce them there. This is technical debt that affects behavior: orphaned rows and unknown `status` values are accepted.
**Approved**: pending

**Decision**: Use a single migration, `integrations-v1`, whose DDL uses plain `CREATE TABLE` without `IF NOT EXISTS`.
**Rationale**: GRDB's migrator skips a migration it has recorded, so the DDL never reruns on a migrated database. A database that has the tables but no record makes `migrate` throw.
**Approved**: pending

