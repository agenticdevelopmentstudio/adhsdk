---
id: 39a27113-5478-468c-8417-a291d587aab6
title: "IntegrationsSchema"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The local SQLite schema and one-shot migration for the five integration tables (provider configs, connections, email messages, email labels, action logs)."
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - persistence
  - schema
depends-on:
  - ea580796-8b16-4832-b11d-ad3cae991ecd
related:
  - 888b7ba2-61f6-4251-88df-3586c5c86b1f
references: []
approved-by: ""
approved-date: ""
---

# IntegrationsSchema

## Overview

`IntegrationsSchema` is a caseless public enum that creates the local mirror of the hub's integration tables. Its doc comment says "Names and columns follow adhbackend; JSON columns are TEXT, timestamps are ISO-8601 UTC strings." It exposes one public operation, `migrate(_:)`, which runs a GRDB `DatabaseMigrator` holding a single migration, `integrations-v1`, against a `BoundedDatabase`. The migration creates five tables: `integration_provider_configs`, `integration_connections`, `integration_email_messages`, `integration_email_labels` and `integration_action_logs`. `IntegrationsStore` calls `migrate` from its initializer. The record structs that map to these tables are described in [adhsdk.ingredient.integrations.model.integration-records](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f), and the database wrapper in [adhsdk.ingredient.data.storage.database](cookbook:ea580796-8b16-4832-b11d-ad3cae991ecd).

## Behavioral Requirements

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

## Appearance

Not applicable — this is a database schema and migration, not a visual component.

## States

Not applicable — this is a database schema and migration, not a visual component.

## Accessibility

Not applicable — this is a database schema and migration, not a visual component.

## Conformance Test Vectors

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
## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | none (required) | The database to migrate; `migrate` uses its `writer` property. Supplied by the caller, in practice `IntegrationsStore.init(database:)`. |
| Migration name | `String` | `integrations-v1` | Fixed identifier GRDB records once the migration has run. Not configurable. |
| Database path | `String` | none | Owned by the caller's `BoundedDatabase` (a file path or `:memory:`); the schema never opens a file. |

## Deep Linking

Not applicable: the component is a database schema with no URL, route or scheme.

## Localization

Not applicable: the component emits no user-facing string; table and column names are internal identifiers.

## Accessibility Options

Not applicable: the component has no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag; `migrate` always runs the migration.

## Analytics

Not applicable: the source emits no event.

## Privacy

- **Data collected**: The tables are built to hold email message addresses, subjects, snippets, bodies, labels and connection scopes mirrored from the hub; the schema itself collects nothing.
- **Storage**: Plain TEXT columns in the local SQLite file behind the `BoundedDatabase`; the schema declares no encryption, and protecting the file is outside this source.
- **Transmission**: None. The schema only creates local tables.
- **Retention**: Rows remain until a store operation tombstones them through `deleted_at` or `is_deleted`; the schema declares no expiry and no purge. Action log rows have no tombstone column.

## Logging

Not applicable: the source makes no log call; a migration failure surfaces only as a thrown error.

## Platform Notes

- **SwiftUI**: Source platform. The file is `packages/apple/AgenticDeveloperHubSDK/Integrations/Store/IntegrationsSchema.swift`, in the integrations module, importing `Foundation`, `AgenticDeveloperHubSDKDatabase` (for `BoundedDatabase`) and GRDB (for `DatabaseMigrator`). A caseless `enum` serves as a namespace; the DDL strings are `private static let` constants and `migrator()` is internal. An app does not call this directly; `IntegrationsStore.init(database:)` does, and the call is synchronous, so run it off the main actor.
- **Compose**: Use Room with a `@Database` listing five `@Entity` classes, and a `Migration` or an auto-migration for later versions. Room's `version` plus its `room_master_table` replaces GRDB's migration-name record, so the single `integrations-v1` step becomes database version 1. Declare the two UNIQUE indices with `@Index(value = ["connection_id", "external_id"], unique = true)`, and note Room has no `DEFAULT` unless declared with `@ColumnInfo(defaultValue = "...")`.
- **React/Web**: Use a SQLite build for the browser (SQLite WASM with OPFS, or `better-sqlite3` on Node) and run the same five `CREATE TABLE` and index statements inside one transaction guarded by a migrations table, or `PRAGMA user_version = 1`. Where only IndexedDB exists, model each table as an object store and each UNIQUE index as an index with `unique: true` on the compound key path; foreign keys and `DEFAULT` values then become application code.
- **AppKit / UIKit**: Same Swift source as above; it has no AppKit or UIKit dependency, so macOS and iOS share it unchanged.
- **WinUI 3**: Use `Microsoft.Data.Sqlite` (or EF Core with the SQLite provider) in a .NET / Windows App SDK app. Run the five DDL strings in one `SqliteTransaction` and record applied migrations in a small `__migrations` table, or use EF Core's `Migrate()` with `HasIndex(...).IsUnique()` for the two unique indices and `HasDefaultValue(true)` and `HasDefaultValue(false)` for `enabled` and `is_deleted`. Call it with `await Task.Run(...)` or `MigrateAsync()` so the UI thread is not blocked, and surface `SqliteException` to the caller instead of swallowing it, matching the source's `throws`. SQLite enforces foreign keys only after `PRAGMA foreign_keys = ON`; the source declares none, so a port should leave them off to match.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Store/IntegrationsSchema.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Keep every JSON value and timestamp as TEXT rather than using a native JSON or date type.
**Rationale**: The doc comment states "JSON columns are TEXT, timestamps are ISO-8601 UTC strings", and says names and columns follow adhbackend; SQLite has no date type and ISO-8601 UTC strings sort as text.
**Approved**: pending

**Decision**: Declare `integration_email_messages_external` and `integration_email_labels_external` as UNIQUE on `(connection_id, external_id)`, but leave `integration_connections_account` non-unique.
**Rationale**: The unique indices make a provider's message or label id a stable key per connection, and back the one-row-per-message result that `IntegrationsStoreTests.upsertMessagesIsIdempotent` checks (the store's `upsertMessages` looks up the existing row by that key and reuses its `id`). The connections index is only a lookup aid; the source gives no comment on why it is not unique, and `IntegrationsStoreTests.upsertConnectionReusesRowForSameEmail` shows the store, not the schema, prevents duplicate accounts.
**Approved**: pending

**Decision**: Tombstone rows with `deleted_at` (and `is_deleted` on messages and labels) instead of deleting them, and leave the action log without either column.
**Rationale**: The `IntegrationsStore` doc comment defines "live" as `deleted_at IS NULL` for connections and configs and `is_deleted = 0` for messages and labels, and a tombstoned message keeps its unique key. The action log is an append-style record with only `created_at` and `updated_at`.
**Approved**: pending

**Decision**: Declare no foreign keys, CHECK constraints or enum constraints.
**Rationale**: The DDL contains none. Referential and value rules live in the record and store layers, so a port must enforce them there. This is deliberate, prudent technical debt: the store owns integrity, matching adhbackend, so the local mirror stays a plain copy of the hub tables. The cost is that orphaned rows and unknown `status` values are accepted. Constraints belong in a later migration with a new name, added once the record and store layers no longer need to write rows that violate them.
**Approved**: pending

**Decision**: Use a single migration, `integrations-v1`, whose DDL uses plain `CREATE TABLE` without `IF NOT EXISTS`.
**Rationale**: GRDB's migrator skips a migration it has recorded, so the DDL never reruns on a migrated database. A database that has the tables but no record makes `migrate` throw.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |

The enum holds only DDL and the migrator call, with reads, writes and tombstoning in `IntegrationsStore` and the row shapes in the record structs, so separation of concerns passes. No test file targets `IntegrationsSchema`; `IntegrationsStoreTests` migrates through the store and covers the unique message key, but not the label key, the defaults, the NOT NULL columns or a second `migrate` call, so unit test coverage is partial. Data integrity is partial because the schema declares no foreign keys or CHECK constraints, so orphan rows and free-text `status`, `type` and `mail_class` values are accepted. Secure data storage is partial because the tables keep addresses, subjects and bodies in plain columns, and protection of the database file is outside this source.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
