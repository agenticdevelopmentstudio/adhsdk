
### Migration

- **migrate-entry-point**: `IntegrationsSchema` MUST expose `migrate(_ database: BoundedDatabase) throws` as its only public operation.
- **migrate-runs-on-writer**: `migrate` MUST run the migrator against `database.writer`, the underlying GRDB writer of the `BoundedDatabase`.
- **migration-name**: The migrator MUST register exactly one migration, named `integrations-v1`.
- **migration-creates-five-tables**: The `integrations-v1` migration MUST create `integration_provider_configs`, `integration_connections`, `integration_email_messages`, `integration_email_labels` and `integration_action_logs`, in that order.
- **migration-single-transaction**: Each table's DDL MUST run inside the one `integrations-v1` migration, so GRDB applies and records the migration as a unit.
- **migrate-idempotent**: Calling `migrate` again on a database that already ran `integrations-v1` MUST NOT recreate tables or change data, because GRDB records the applied migration by name and skips it.
- **migrate-propagates-errors**: `migrate` MUST declare `throws` and MUST let any GRDB or SQLite error propagate to the caller unchanged; it has no catch and no recovery path.
- **no-foreign-keys**: The DDL MUST NOT declare foreign key constraints; `connection_id` columns are plain `TEXT NOT NULL` references that SQLite does not enforce.
- **no-drop-or-alter**: The `integrations-v1` migration MUST NOT drop or alter a table. A later schema change MUST use a new migration name.

### Column conventions

- **primary-key-text**: Every table MUST use `id TEXT PRIMARY KEY NOT NULL`.
- **json-columns-text**: Columns holding structured values (`sync_settings`, `scopes`, `to_addresses`, `cc_addresses`, `label_ids`, `attachments`, `request_payload`) MUST be declared `TEXT`.
- **timestamps-text**: Every timestamp column (`created_at`, `updated_at`, `deleted_at`, `last_sync_at`, `internal_date`) MUST be declared `TEXT`, holding an ISO-8601 UTC string.
- **booleans-default**: Boolean columns (`enabled`, `is_deleted`) MUST be declared `BOOLEAN NOT NULL` with a default: `enabled` defaults to `1`, `is_deleted` defaults to `0`.
- **tombstone-columns**: The provider config, connection, message and label tables MUST each carry a nullable `deleted_at TEXT` column. The message and label tables MUST also carry `is_deleted`.
- **action-log-no-tombstone**: `integration_action_logs` MUST NOT carry `deleted_at` or `is_deleted`; action log rows are never tombstoned by the schema.

### integration_provider_configs

- **provider-configs-columns**: The table MUST have `id`, `provider_id`, `name` and `client_id` as `TEXT NOT NULL`, `enabled BOOLEAN NOT NULL DEFAULT 1`, `created_at` and `updated_at` as `TEXT NOT NULL`, and nullable `deleted_at TEXT`.
- **provider-configs-no-secret**: The table MUST NOT have a client secret or token column; the only credential-related column is `client_id`.
- **provider-configs-no-index**: The table MUST NOT declare a secondary index or a UNIQUE constraint beyond the primary key.

### integration_connections

- **connections-required-columns**: The table MUST have `id`, `provider`, `service_type`, `external_account_id`, `display_name`, `status`, `sync_settings`, `scopes`, `created_at` and `updated_at` as `TEXT NOT NULL`.
- **connections-nullable-columns**: The table MUST have `last_sync_at`, `last_error`, `sync_cursor` and `deleted_at` as nullable `TEXT`.
- **connections-account-index**: The migration MUST create a non-unique index `integration_connections_account` on `(provider, external_account_id)`, so two live rows for one account are not prevented by the schema.

### integration_email_messages

- **messages-required-columns**: The table MUST have `id`, `connection_id`, `provider`, `external_id`, `thread_id`, `from_address`, `to_addresses`, `cc_addresses`, `subject`, `snippet`, `label_ids`, `internal_date`, `attachments`, `mail_class`, `created_at` and `updated_at` as `TEXT NOT NULL`.
- **messages-nullable-columns**: The table MUST have `body_text`, `body_html`, `history_id` and `deleted_at` as nullable `TEXT`.
- **messages-is-deleted**: The table MUST have `is_deleted BOOLEAN NOT NULL DEFAULT 0`.
- **messages-unique-external**: The migration MUST create a UNIQUE index `integration_email_messages_external` on `(connection_id, external_id)`, so one connection holds at most one row per provider message id, tombstoned rows included.
- **messages-date-index**: The migration MUST create a non-unique index `integration_email_messages_date` on `(connection_id, internal_date)`, for date-range and ordered reads per connection.

### integration_email_labels

- **labels-required-columns**: The table MUST have `id`, `connection_id`, `external_id`, `source_provider`, `name`, `type`, `created_at` and `updated_at` as `TEXT NOT NULL`.
- **labels-nullable-columns**: The table MUST have `parent_name`, `color` and `deleted_at` as nullable `TEXT`, and `messages_total` and `messages_unread` as nullable `INTEGER`.
- **labels-is-deleted**: The table MUST have `is_deleted BOOLEAN NOT NULL DEFAULT 0`.
- **labels-unique-external**: The migration MUST create a UNIQUE index `integration_email_labels_external` on `(connection_id, external_id)`.

### integration_action_logs

- **action-logs-required-columns**: The table MUST have `id`, `connection_id`, `provider`, `action_type`, `request_payload`, `status`, `created_at` and `updated_at` as `TEXT NOT NULL`.
- **action-logs-nullable-columns**: The table MUST have `idempotency_key`, `result` and `error` as nullable `TEXT`.
- **action-logs-no-index**: The table MUST NOT declare a secondary index or a UNIQUE constraint, so `idempotency_key` is not unique at the schema level.

### Concurrency and side effects

- **writer-serialised**: The Swift `migrate` is a synchronous call that blocks until the migration finishes, and a port MUST complete the migration before its store accepts writes; ordering against other writes is the serialisation GRDB's writer provides (a serial `DatabaseQueue` in memory, a `DatabasePool` writer for a file).
- **only-side-effect**: The only side effect of `migrate` MUST be the schema change and GRDB's own migration bookkeeping in the target database; it does no logging, network call or file access of its own.
- **migrator-internal**: `migrator()` MUST stay internal (not public), so only `migrate` and `@testable` tests can build it.

