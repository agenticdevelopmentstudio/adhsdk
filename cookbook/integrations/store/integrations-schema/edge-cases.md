
- **empty-database**: On a database with no tables, `migrate` MUST create all five tables.
- **already-migrated**: See `#requirements/migrate-idempotent`.
- **partial-failure**: If a DDL statement fails, the error MUST reach the caller unchanged; GRDB runs the migration in a transaction, so the migration is not recorded as applied.
- **table-already-exists**: A database that holds an `integration_*` table but no `integrations-v1` record makes `CREATE TABLE` fail with a SQLite error that `migrate` MUST propagate; the DDL has no `IF NOT EXISTS`.
- **duplicate-external-id**: Inserting a second message or label with an existing `(connection_id, external_id)` fails with a UNIQUE constraint error; a tombstoned row still occupies the key, so a caller MUST update that row to revive it. `IntegrationsStore.upsertMessages` does this by reusing the existing row's `id`.
- **boundary-nullability**: `last_sync_at`, `last_error`, `sync_cursor`, `body_text`, `body_html`, `history_id`, `parent_name`, `color`, `messages_total`, `messages_unread`, `idempotency_key`, `result` and `error` accept NULL; every other column except `deleted_at` is `NOT NULL` and rejects NULL.
- **empty-strings**: The schema has no CHECK constraint, so empty strings are accepted in every `TEXT NOT NULL` column today, an empty subject included. This is current behavior of the DDL, not a contract the schema promises.
- **unvalidated-values**: `status`, `type`, `mail_class` and `provider` are free text with no CHECK or enum constraint; value sets live in the record layer, so a port MUST NOT assume the schema enforces them.
- **orphan-rows**: Without foreign keys, a hard `DELETE` of a connection row would leave its messages, labels and action logs behind. `IntegrationsStore.deleteConnection` avoids this by soft-deleting the connection and tombstoning its messages and labels (action logs are untouched), and a caller SHOULD go through the store rather than delete rows directly.
- **concurrent-access**: Two simultaneous `migrate` calls on one `BoundedDatabase` serialise on its single writer, and the second finds the migration applied. Two separate `BoundedDatabase` instances on one file contend for the SQLite write lock and fail with a busy error after the configured busy timeout, which `migrate` MUST propagate.
- **offline**: Not applicable: the schema touches only the local SQLite file and makes no network call.
- **schema-evolution**: Changing a column in `integrations-v1` after databases have applied it does not reach those databases; a change MUST use a new migration name.

