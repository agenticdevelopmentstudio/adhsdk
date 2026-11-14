
The source has no test file of its own. `IntegrationsStoreTests` builds every database through `IntegrationsStore.init`, which calls `IntegrationsSchema.migrate`, so its assertions exercise the schema indirectly. Vectors 001 to 009 and 011 to 018 are derived from the DDL; 010 names the test whose behavior depends on the schema.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| schema-001 | migration-creates-five-tables, migrate-runs-on-writer | An empty in-memory `BoundedDatabase`; call `IntegrationsSchema.migrate` | The names in `sqlite_master` of type table include `integration_provider_configs`, `integration_connections`, `integration_email_messages`, `integration_email_labels` and `integration_action_logs` |
| schema-002 | migrate-idempotent | Call `migrate` twice on the same database | The second call returns without throwing; the table list is unchanged |
| schema-003 | migrate-idempotent | Migrate, insert one connection row, call `migrate` again | The connection row is still present |
| schema-004 | messages-unique-external | Insert two `integration_email_messages` rows with the same `connection_id` and `external_id` but different `id` | The second insert fails with a UNIQUE constraint error |
| schema-005 | messages-unique-external | Insert two message rows with the same `external_id` under different `connection_id` values | Both inserts succeed |
| schema-006 | labels-unique-external | Insert two `integration_email_labels` rows with the same `connection_id` and `external_id` | The second insert fails with a UNIQUE constraint error |
| schema-007 | connections-account-index | Insert two connection rows with the same `provider` and `external_account_id` and different `id` | Both inserts succeed (the index is not unique) |
| schema-008 | booleans-default, provider-configs-columns | Insert a provider config row and a message row without `enabled` or `is_deleted` | `enabled` reads back as 1 and `is_deleted` reads back as 0 |
| schema-009 | connections-required-columns | Insert a connection row with `status` NULL | The insert fails with a NOT NULL constraint error |
| schema-010 | messages-unique-external | `IntegrationsStoreTests.upsertMessagesIsIdempotent`: upsert message `e1` with subject "old", then again with subject "new" | `SELECT COUNT(*) FROM integration_email_messages` is 1 and the stored subject is "new" |
| schema-011 | action-logs-no-index, action-log-no-tombstone | Insert two action log rows with the same non-null `idempotency_key` | Both inserts succeed; the table has no `deleted_at` or `is_deleted` column |
| schema-012 | no-foreign-keys | Insert a message row whose `connection_id` matches no connection | The insert succeeds |
| schema-013 | migration-name | Migrate, then `SELECT identifier FROM grdb_migrations` | Exactly one row, `integrations-v1` |
| schema-014 | json-columns-text, timestamps-text | `PRAGMA table_info` on each table | `sync_settings`, `scopes`, `to_addresses`, `cc_addresses`, `label_ids`, `attachments`, `request_payload` and every `created_at`, `updated_at`, `deleted_at`, `last_sync_at`, `internal_date` column report type `TEXT` |
| schema-015 | provider-configs-no-secret, provider-configs-no-index | `PRAGMA table_info` and `PRAGMA index_list` on `integration_provider_configs` | The columns are exactly `id`, `provider_id`, `name`, `client_id`, `enabled`, `created_at`, `updated_at`, `deleted_at`; no index other than the primary key's |
| schema-016 | messages-date-index | `PRAGMA index_list` and `PRAGMA index_info` on `integration_email_messages` | `integration_email_messages_date` exists, is not unique, and covers `connection_id` then `internal_date` |
| schema-017 | table-already-exists | On a fresh database, create `integration_connections` by hand, then call `migrate` | `migrate` throws a SQLite error and `integrations-v1` is not recorded |
| schema-018 | primary-key-text | Insert a connection row with `id` NULL | The insert fails with a NOT NULL constraint error |
