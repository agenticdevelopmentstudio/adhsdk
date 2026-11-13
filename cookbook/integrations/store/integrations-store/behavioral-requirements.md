
### Construction and schema

- **migrate-on-init**: `init(database:)` MUST run `IntegrationsSchema.migrate` on the given `BoundedDatabase` before it returns.
- **init-propagates-migration-failure**: `init(database:)` MUST throw the migration's error when the migration fails.
- **schema-tables**: After `init(database:)`, the database MUST hold the tables `integration_provider_configs`, `integration_connections`, `integration_email_messages`, `integration_email_labels` and `integration_action_logs`.
- **message-unique-key**: The schema MUST enforce a unique index on `integration_email_messages (connection_id, external_id)`.
- **label-unique-key**: The schema MUST enforce a unique index on `integration_email_labels (connection_id, external_id)`.
- **timestamp-format**: Every timestamp the store writes (`updated_at`, `deleted_at`) MUST come from `IntegrationClock.now()`, an ISO-8601 UTC string with fractional seconds.
- **transaction-per-call**: Each public write MUST run all its statements inside one `BoundedDatabase.write` call, so they commit or roll back together, and a write made inside an enclosing `database.write` joins that transaction.

### Public shapes

- **query-shape**: `MessageQuery` MUST be a `Codable`, `Sendable`, `Equatable` struct with the fields `connectionId`, `since`, `until`, `labelIds`, `anyLabelIds`, `limit`, `offset` and `after`.
- **query-defaults**: `MessageQuery.init` MUST default `since`, `until` and `after` to nil, `labelIds` and `anyLabelIds` to empty, `limit` to 50 and `offset` to 0.
- **key-shape**: `MessageKey` MUST be a `Codable`, `Sendable`, `Equatable` struct with the fields `internalDate` and `id`.

### Provider configs

- **config-read**: `providerConfig(providerId:)` MUST return the config whose `provider_id` equals `providerId` and whose `deleted_at` is nil, or nil when there is none.
- **config-upsert-key**: `upsertProviderConfig(_:)` MUST match an existing live config by `providerId`, not by `id`.
- **config-upsert-keeps-identity**: When a live config matches, `upsertProviderConfig(_:)` MUST store the new values under the existing row's `id` and keep its `createdAt`.
- **config-upsert-stamps**: `upsertProviderConfig(_:)` MUST set `updatedAt` to the current time and `deletedAt` to nil on the row it stores.
- **config-delete**: `deleteProviderConfig(providerId:)` MUST set `deleted_at` and `updated_at` to one timestamp on every live config with that `provider_id`.
- **config-delete-unknown**: `deleteProviderConfig(providerId:)` MUST NOT throw when no live config has that `provider_id`.

### Connections

- **connections-list**: `connections(provider:)` MUST return the live connections whose `provider` equals the argument, ordered by `external_account_id`.
- **connection-lookup-key**: `connection(idOrEmail:)` MUST match a live connection whose `id` equals the argument exactly, or whose `external_account_id` equals it ignoring case.
- **connection-lookup-order**: When more than one live connection matches, `connection(idOrEmail:)` MUST return the one with the earliest `created_at`.
- **connection-lookup-miss**: `connection(idOrEmail:)` MUST return nil when no live connection matches.
- **connection-upsert-key**: `upsertConnection(_:)` MUST match an existing live connection by `provider` and `externalAccountId`, comparing the address ignoring case.
- **connection-upsert-keeps-identity**: When a live connection matches, `upsertConnection(_:)` MUST store the new values under the existing row's `id` and keep its `createdAt`, so signing in again with the same account keeps the id.
- **connection-upsert-new-id**: When no live connection matches, `upsertConnection(_:)` MUST store the row under the `id` the caller supplied.
- **connection-upsert-stamps**: `upsertConnection(_:)` MUST set `updatedAt` to the current time and `deletedAt` to nil on the row it stores.
- **connection-delete**: `deleteConnection(id:)` MUST set `deleted_at` and `updated_at` to one timestamp on the live connection with that `id`.
- **connection-delete-cascade**: `deleteConnection(id:)` MUST set `is_deleted` to 1 and `deleted_at` and `updated_at` to that same timestamp on every live message and every live label whose `connection_id` equals `id`.
- **connection-delete-unknown**: `deleteConnection(id:)` MUST NOT throw when no live connection has that `id`.
- **sync-state-write**: `updateSyncState(id:cursor:lastSyncAt:status:lastError:)` MUST write `sync_cursor`, `last_sync_at`, `status` (as the raw value of `ConnectionStatus`), `last_error` and `updated_at` on the live connection with that `id`.
- **sync-state-nil-overwrites**: `updateSyncState` MUST store a nil `cursor`, `lastSyncAt` or `lastError` as NULL; it does not keep the previous value.
- **sync-state-unknown**: `updateSyncState` MUST throw `IntegrationError.unknownAccount(id)` when no live connection has that `id`.

### Messages

- **message-upsert-key**: `upsertMessages(_:)` MUST match an existing message by `connectionId` and `externalId`, whether or not that message is tombstoned.
- **message-upsert-keeps-identity**: When a message matches, `upsertMessages(_:)` MUST store the new values under the existing row's `id` and keep its `createdAt`.
- **message-upsert-revives**: `upsertMessages(_:)` MUST set `isDeleted` to false and `deletedAt` to nil on every row it stores, so a tombstoned message comes back live.
- **message-upsert-stamps**: `upsertMessages(_:)` MUST set `updatedAt` to the current time on every row it stores.
- **message-upsert-batch**: `upsertMessages(_:)` MUST store the whole array in one transaction.
- **tombstone-ids**: `tombstoneMessages(connectionId:externalIds:)` MUST tombstone the live messages of that connection whose `external_id` is among `externalIds`.
- **tombstone-ids-dedupe**: `tombstoneMessages(connectionId:externalIds:)` MUST ignore repeated ids in `externalIds`.
- **tombstone-ids-empty**: `tombstoneMessages(connectionId:externalIds:)` MUST return 0 and touch nothing when `externalIds` is empty.
- **tombstone-ids-chunked**: `tombstoneMessages(connectionId:externalIds:)` MUST bind at most `inListChunkSize` (500) ids in one statement and MUST run all the statements in one transaction.
- **tombstone-ids-count**: `tombstoneMessages(connectionId:externalIds:)` MUST return the number of rows it newly tombstoned, not counting ids with no live row.
- **tombstone-classes**: `tombstoneMessages(connectionId:classes:)` MUST tombstone the live messages of that connection whose `mail_class` is among `classes`, and return how many it tombstoned.
- **tombstone-classes-empty**: `tombstoneMessages(connectionId:classes:)` MUST return 0 and touch nothing when `classes` is empty.
- **tombstone-older**: `tombstoneMessages(connectionId:olderThan:)` MUST tombstone the live messages of that connection whose `internal_date` is strictly less than `cutoff`, and return how many it tombstoned.
- **tombstone-fields**: Every tombstone operation MUST set `is_deleted` to 1 and `deleted_at` and `updated_at` to one timestamp taken at the start of the call.
- **live-ids**: `liveExternalIds(connectionId:since:)` MUST return the set of `external_id` values of live messages of that connection whose `internal_date` is greater than or equal to `since`.
- **message-lookup-key**: `message(connectionId:idOrExternalId:includingDeleted:)` MUST match a message of that connection whose `id` or `external_id` equals `idOrExternalId`.
- **message-lookup-live-only**: With `includingDeleted` false (the default), `message(connectionId:idOrExternalId:includingDeleted:)` MUST NOT return a tombstoned message.
- **message-lookup-live-wins**: With `includingDeleted` true, `message(connectionId:idOrExternalId:includingDeleted:)` MUST prefer a live match over a tombstoned one.

### Message query

- **query-scope**: `messages(_:)` MUST return only live messages whose `connection_id` equals `query.connectionId`.
- **query-since**: When `since` is set, `messages(_:)` MUST return only messages whose `internal_date` is greater than or equal to it.
- **query-until**: When `until` is set, `messages(_:)` MUST return only messages whose `internal_date` is less than or equal to it.
- **query-date-compare**: `messages(_:)` MUST compare `internal_date`, `since`, `until` and `after.internalDate` as strings without parsing or validating them, so correct ranges depend on the ISO-8601 format that `IntegrationClock` writes.
- **query-labels-all**: `messages(_:)` MUST return only messages whose `label_ids` contain every id in `labelIds`.
- **query-labels-any**: When `anyLabelIds` is not empty, `messages(_:)` MUST return only messages whose `label_ids` contain at least one id in `anyLabelIds`.
- **query-labels-combine**: `messages(_:)` MUST apply `labelIds` and `anyLabelIds` together, so a message must satisfy both.
- **query-order**: `messages(_:)` MUST order results by `internal_date` descending, then `id` ascending.
- **query-after**: When `after` is set, `messages(_:)` MUST return only messages that follow that key in the query order: `internal_date` less than `after.internalDate`, or equal to it with `id` greater than `after.id`.
- **message-upsert-batch-last-wins**: When one `upsertMessages(_:)` call holds two messages with the same `externalId`, the later one MUST be the stored row, and one row remains.
- **query-after-stable**: A page resumed with `after` set to the last row of the previous page MUST NOT skip or repeat rows when rows ahead of that key are tombstoned or removed from the filter.
- **query-limit**: `messages(_:)` MUST return at most `max(limit, 0)` rows.
- **query-offset**: `messages(_:)` MUST skip `max(offset, 0)` rows of the ordered result before it returns any.

### Labels

- **labels-replace-upsert**: `replaceLabels(connectionId:with:)` MUST store each given label with its `connectionId` set to the argument, matched by `connectionId` and `externalId`, whether or not the match is tombstoned.
- **labels-replace-keeps-identity**: When a label matches, `replaceLabels(connectionId:with:)` MUST store the new values under the existing row's `id` and keep its `createdAt`.
- **labels-replace-revives**: `replaceLabels(connectionId:with:)` MUST set `isDeleted` to false and `deletedAt` to nil on every label it stores.
- **labels-replace-stamps**: `replaceLabels(connectionId:with:)` MUST set `updatedAt` to one timestamp taken at the start of the call on every label it stores.
- **labels-replace-tombstones**: `replaceLabels(connectionId:with:)` MUST tombstone every live label of that connection whose `external_id` is not among the given labels.
- **labels-replace-empty**: With an empty `labels` array, `replaceLabels(connectionId:with:)` MUST tombstone every live label of that connection.
- **labels-replace-atomic**: `replaceLabels(connectionId:with:)` MUST do the upserts and the tombstoning in one transaction.
- **labels-read**: `labels(connectionId:)` MUST return the live labels of that connection ordered by `name`, then `id`.

### Action log

- **log-insert**: `insertActionLog(_:)` MUST insert the given `ActionLog` unchanged as a new row.
- **log-insert-duplicate**: `insertActionLog(_:)` MUST throw the database's error when a row with that `id` exists.
- **log-finish**: `finishActionLog(id:status:result:error:)` MUST set `status`, `result`, `error` and `updated_at` on the row with that `id`.
- **log-finish-unknown**: NEEDS REVIEW: Not implemented in source. `finishActionLog(id:status:result:error:)` changes no row and returns without a signal when no row has that `id`, unlike `updateSyncState`, which throws `IntegrationError.unknownAccount`; a caller cannot tell a finished entry from a lost one, and the call sites in `MailIntegrationService` plus the intended behavior would settle it.

### Concurrency and errors

- **isolation-by-connection**: A message, label or tombstone operation scoped to one `connectionId` MUST NOT change rows of any other connection.
- **sendable**: `IntegrationsStore` MUST be `Sendable` and MUST hold no mutable state of its own; it MAY be called from any thread.
- **writes-serialised**: The store MUST route every write through `BoundedDatabase.write`, which runs writes one at a time on the single writer connection.
- **reads-parallel**: The store MUST route every read through `BoundedDatabase.read`, which runs on a pooled reader connection and does not wait for the writer on a file database.
- **errors-unwrapped**: The store MUST let database errors and `BoundedDatabaseError.deadlineExceeded` reach the caller unchanged; it does not wrap, retry or log them.

