---
id: c19280fd-b80c-46f3-a6a7-0b60a0c90d91
title: "Integrations Store"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "SQLite mirror of integration tables with tombstones, upserts, paged queries"
platforms:
  - swift
  - macos
  - ios
tags:
  - integrations
  - mail-sync
  - persistence
depends-on:
  - 888b7ba2-61f6-4251-88df-3586c5c86b1f
  - 351e3bf8-b137-4f59-94de-c769aa8b0666
related:
  - 1157bca1-0d27-49e9-a989-d637505ba5f1
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - 39a27113-5478-468c-8417-a291d587aab6
references: []
approved-by: ""
approved-date: ""
---

# Integrations Store

## Overview

`IntegrationsStore` is a public, `Sendable`, `final class` that owns the local mirror of the hub's integration tables: provider configs, connections, email messages, email labels and the action log. It takes a `BoundedDatabase`, runs `IntegrationsSchema.migrate` on it when it is created, and then exposes synchronous, throwing reads and writes over five tables. It holds no state of its own beyond the database handle.

The store never removes a row. A delete is a tombstone: `deleted_at` is set for connections and provider configs, and `is_deleted` and `deleted_at` are set for messages and labels. "Live" means not tombstoned: `deleted_at IS NULL` for connections and configs, `is_deleted = 0` for messages and labels. Reads return live rows only, except `message(connectionId:idOrExternalId:includingDeleted:)` when asked for a tombstoned row. An upsert reuses the local `id` and `createdAt` of the row it matches and, for a message or label, clears any tombstone on it. A config or connection upsert matches live rows only, so a tombstoned one stays tombstoned and the upsert stores a new row.

Two public value types belong to the contract. `MessageQuery` says which messages of one connection to list, and `MessageKey` is a message's place in the newest-first order, used to resume a page. The record types (`ProviderConfig`, `IntegrationConnection`, `EmailMessage`, `EmailLabel`, `ActionLog`), `ConnectionStatus`, `MailClass`, `IntegrationClock` and `IntegrationError` come from the integrations model (records: cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f, error: cookbook:351e3bf8-b137-4f59-94de-c769aa8b0666) and are used here as given. The component does not talk to the network, hold credentials, decide what to sync, or schedule anything; `GmailSyncWorker` (cookbook:1157bca1-0d27-49e9-a989-d637505ba5f1) and `MailIntegrationService` (cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a) call it.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a persistence component over SQLite, not a visual component.

## States

Not applicable — this is a persistence component over SQLite, not a visual component. The only lifecycle it has is the tombstone: a message, label, connection or config row is live or tombstoned, and an upsert moves a tombstoned message or label back to live, while a tombstoned config or connection stays tombstoned and the upsert stores a new live row. A connection's `status` (`active`, `error`, `revoked`, `pending`) is data the caller writes through `updateSyncState`; the store holds no state machine over it.

## Accessibility

Not applicable — this is a persistence component over SQLite, not a visual component.

## Conformance Test Vectors

Vectors named for a test come from `IntegrationsStoreTests`, which runs the store against `BoundedDatabase(path: ":memory:")`. Vectors marked "Derived" follow from the source and have no test of their own. Message dates in the tests are `2026-11-DDT10:00:00.000Z`, written below as "day D".

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| store-001 | migrate-on-init, schema-tables | Derived: open `BoundedDatabase(path: ":memory:")`, create the store, count the rows of each of the five tables | No error; each query succeeds and returns 0 |
| store-002 | init-propagates-migration-failure | Derived: pass a database that already holds a table named `integration_connections` but has no migration record, so the first migration fails | `init` throws the database's error and returns no store |
| store-003 | message-upsert-key, message-upsert-keeps-identity, message-unique-key, message-upsert-stamps | Test `upsertMessagesIsIdempotent`: upsert message `e1` with subject "old", then `e1` again with subject "new" | `SELECT COUNT(*)` on messages is 1; `message(connectionId: "c1", idOrExternalId: "e1")` has subject "new" |
| store-004 | message-upsert-revives, tombstone-ids, tombstone-fields | Test `upsertRevivesTombstone`: upsert `e1`, tombstone `e1`, look it up, upsert `e1` again, look it up | The first lookup is nil; the second has `isDeleted == false` and `deletedAt == nil` |
| store-005 | query-scope, query-since, query-until, query-labels-all, query-order | Test `queryFiltersByDateRangeAndAllLabels`: `e1` day 1 (INBOX, Label_1), `e2` day 2 (INBOX), `e3` day 3 (INBOX, Label_1) | No filter returns e3, e2, e1; since day 2 and until day 3 returns e3, e2; labelIds INBOX and Label_1 returns e3, e1; labelIds INBOX and Nope returns none |
| store-006 | query-labels-any, query-labels-combine | Test `queryMatchesAnyLabel`: `e1` (INBOX), `e2` (Label_1), `e3` (Label_2, STARRED), `e4` (INBOX, Label_1, STARRED), days 1 to 4 | anyLabelIds INBOX and Label_1 returns e4, e2, e1; with labelIds STARRED added returns e4; anyLabelIds Nope returns none |
| store-007 | query-limit, query-offset | Test `queryPagesWithLimitAndOffset`: `e1` to `e5` on days 1 to 5, limit 2, offset 1 | e4, e3 |
| store-008 | query-after, query-after-stable | Test `queryResumesAfterKey`: `e1` to `e5`, first page limit 2 returns e5, e4; tombstone e5; resume with `after` set to the key of e4, limit 2 | The first page is e5, e4; the resumed page is e3, e2 |
| store-009 | tombstone-classes, live-ids | Test `tombstoneByClassRemovesOnlyThatClass`: `keep` (INBOX), `junk` (SPAM), `bin` (TRASH); tombstone classes `[.spam]` | Live messages are keep and bin; `liveExternalIds` since 2026-01-01 is keep and bin |
| store-010 | labels-replace-upsert, labels-replace-tombstones, labels-read | Test `replaceLabelsTombstonesVanished`: replace with A, B; then B, C; then A | After the second call the live ids are B, C; after the third they are A |
| store-011 | connection-lookup-key, connection-lookup-miss, connections-list | Test `connectionLookupByIdOrEmail`: upsert `c1` with email a@b.c | Lookup by "c1" finds email a@b.c; by "a@b.c" finds id c1; by "nobody" returns nil; `connections(provider: "gmail")` has 1 row |
| store-012 | connection-lookup-key, connection-upsert-key | Test `emailMatchingIgnoresCase`: upsert `c1` with Me@Example.com, look up "me@example.COM", then upsert `c2` with me@example.com | The lookup returns id c1; the live ids afterwards are c1 only |
| store-013 | connection-upsert-keeps-identity, connection-upsert-stamps | Test `upsertConnectionReusesRowForSameEmail`: upsert `c1` with a@b.c, then `c2` with a@b.c and display name "Renamed" | One live row with id c1 and display name "Renamed" |
| store-014 | sync-state-unknown | Test `updateSyncStateOnUnknownIdThrows`: update "nope"; then upsert `c1`, delete `c1`, update `c1` | Both calls throw `IntegrationError.unknownAccount` carrying "nope" and "c1" |
| store-015 | tombstone-ids-chunked, tombstone-ids-dedupe, tombstone-ids-count | Test `tombstoneManyIdsIsChunkedAndCounted`: 1,200 stored messages; tombstone those ids plus "never-stored" plus 40,000 copies of "e0"; then tombstone the 1,200 again | The first call returns 1,200 and no live message remains; the second returns 0 |
| store-016 | tombstone-older | Test `tombstoneOlderThan`: `old` day 1, `edge` day 3, `new` day 5; cutoff day 3 | Returns 1; the live messages are edge and new |
| store-017 | connection-delete, connection-upsert-new-id | Test `reUpsertAfterDelete`: upsert `c1`, delete `c1`, upsert `c2` with the same email | `connection(idOrEmail: "a@b.c")` has id c2; the live connection ids are c2 only |
| store-018 | isolation-by-connection, live-ids | Test `connectionsAreIsolated`: message `e1` for `c1` and a message with external id `e1` for `c2`; tombstone `e1` for `c1` | `c1` lookup is nil; `c2` lookup returns `other-e1`; `c2` has 1 live message and `liveExternalIds` of `c2` is e1 |
| store-019 | live-ids | Test `liveExternalIdsSinceBoundary`: `before` day 2, `at` day 3; since day 3 | The set is `at` only |
| store-020 | connection-delete-cascade, labels-read, query-scope, message-lookup-live-only | Test `deleteConnectionTombstonesItsMessages`: `c1` with message `e1` and label A; delete `c1` | Lookup of "c1" is nil; the message query is empty; `labels(connectionId: "c1")` is empty |
| store-021 | sync-state-write, sync-state-nil-overwrites, config-read, config-upsert-key, config-upsert-keeps-identity, config-delete, log-insert, log-finish | Test `syncStateConfigsAndLogs`: update sync state of `c1` to cursor "99", status active; upsert config p1 then p2 for provider "gmail" with client ids cid and cid2; delete the config; insert and finish action log `a1` with status "ok" | The connection reads cursor "99", status `.active`; the config reads client id cid2, then nil after the delete; the log row has status "ok" |
| store-022 | config-delete-unknown, connection-delete-unknown | Derived: call `deleteProviderConfig(providerId: "nope")` and `deleteConnection(id: "nope")` on an empty store | Neither call throws |
| store-023 | labels-replace-empty, labels-replace-keeps-identity, labels-replace-revives, labels-replace-stamps, labels-replace-atomic | Derived: replace labels with A, B, then with an empty array, then with A again | After the empty call `labels(connectionId:)` is empty; after the last call it holds A under its original `id` with `isDeleted == false` |
| store-024 | query-limit, query-offset, query-defaults | Derived: five live messages; query with limit -3; then limit 2 with offset -4; then `MessageQuery(connectionId: "c1")` | The first returns no rows; the second returns the 2 newest; the third has limit 50, offset 0, and nil `since`, `until`, `after` |
| store-025 | log-insert-duplicate | Derived: insert action log `a1` twice | The second call throws the database's constraint error |
| store-026 | message-lookup-key, message-lookup-live-only, message-lookup-live-wins | Derived: upsert `e1`, tombstone it; call `message` with `includingDeleted` false, then true | nil, then the tombstoned row |
| store-027 | tombstone-ids-empty, tombstone-classes-empty | Derived: `tombstoneMessages(connectionId: "c1", externalIds: [])` and `tombstoneMessages(connectionId: "c1", classes: [])` | Both return 0 |
| store-028 | query-shape, key-shape, query-date-compare | Derived: encode a `MessageQuery` with an `after` key to JSON and decode it; query messages dated `2026-11-02T10:00:00.000Z` with `since` "2026-11-02T10:00:00.000Z" | The decoded query equals the original; the message is returned (string comparison, inclusive) |
| store-029 | timestamp-format, config-upsert-stamps, connection-upsert-stamps | Derived: upsert a config whose `updatedAt` is "x" and `deletedAt` is "y" | The stored `updatedAt` is a fractional-second ISO-8601 UTC string and `deletedAt` is nil |
| store-030 | transaction-per-call, message-upsert-batch | Derived: inside `database.write`, call `store.upsertMessages` with two messages and `store.deleteConnection(id: "c1")`, then throw from the outer closure | The outer call rethrows; neither message is stored and `c1`, its messages and its labels are still live |
| store-031 | log-finish-unknown | Derived: `finishActionLog(id: "nope", status: "ok", result: nil, error: nil)` on an empty log | Returns without throwing and changes no row |
| store-032 | errors-unwrapped | Derived: run a store write on a database built with a write deadline shorter than the statement needs | The call throws `BoundedDatabaseError.deadlineExceeded` with lane "write", unwrapped |
| store-033 | sendable | Derived: compile a use of the store from two tasks | The code compiles without a concurrency diagnostic |
| store-034 | tombstone-fields | Derived: tombstone a message with the store, then read its `deleted_at` and `updated_at` | `is_deleted` is 1 and the two columns hold the same string |
| store-035 | writes-serialised, reads-parallel | Derived: open a file database, start a store write that holds the writer, and call a store read from another thread | The read returns the last committed state without waiting for the write; a second write waits for the first |
| store-036 | message-upsert-batch-last-wins | Derived: `upsertMessages` with two messages of external id `e1`, subjects "first" and "second" | One row exists for `e1` and its subject is "second" |

## Edge Cases

- **Empty `externalIds` or `classes`**: `tombstoneMessages` returns 0 without a database call (MUST).
- **Repeated ids**: `tombstoneMessages(connectionId:externalIds:)` collapses `externalIds` to a set first, so 40,000 copies of one id bind once (MUST).
- **More than 500 ids**: ids are bound 500 per statement, so a list over SQLite's 32,766-variable limit still works, in one transaction (MUST).
- **`replaceLabels` with many labels**: the `NOT IN` list binds one parameter per label with no chunking, so a call with more labels than SQLite allows variables fails with the database's error and changes nothing, because the call is one transaction. This is a fact of the source, not a requirement.
- **Empty `replaceLabels`**: tombstones every live label of the connection (MUST).
- **Duplicate external ids inside one `replaceLabels` or `upsertMessages` call**: each later entry finds the row the earlier entry stored and overwrites it, so the last entry wins and one row remains.
- **Negative `limit` or `offset`**: both are clamped to 0, so a negative `limit` returns no rows and a negative `offset` skips none (query-limit, query-offset).
- **`limit` 0**: returns no rows (query-limit).
- **`after` and `offset` together**: both apply; `offset` skips rows after the `after` filter (query-after, query-offset).
- **Label id absent from every message**: matches nothing, so `labelIds` containing it returns no rows, and `anyLabelIds` containing only it returns no rows (MUST). The store does not validate label ids.
- **Dates that are not ISO-8601 UTC strings of the same width**: `since`, `until`, `cutoff` and `after.internalDate` are compared as strings with no validation, so a differently formatted value gives an order that does not follow time (callers SHOULD NOT pass them; the contract is the format `IntegrationClock` writes, and the store rejects nothing).
- **Missing connection on `updateSyncState`**: throws `IntegrationError.unknownAccount` after the statement runs and finds no row (MUST).
- **Tombstoned connection on `updateSyncState`**: treated as missing and throws (MUST).
- **Delete of a missing config or connection**: no error and no change (MUST).
- **Same email on a different provider**: the connection upsert key includes `provider`, so it creates a separate row, but `connection(idOrEmail:)` does not filter by provider and returns the earliest-created match (MUST).
- **Same account signed in again after a delete**: no live row matches, so a new row is stored under the id the caller gave, and the tombstoned row stays (MUST).
- **Message whose `id` equals another message's `external_id`**: `message(connectionId:idOrExternalId:includingDeleted:)` matches either column and returns the first row the database yields under the live-first ordering (SHOULD NOT be relied on by callers).
- **Concurrent calls**: writes serialise on the one writer connection; a read on a file database runs on a reader and sees the last committed state; an in-memory database shares one connection, so reads and writes queue together. A call made from inside another `read` or `write` on the same thread runs inline in that transaction (transaction-per-call).
- **Slow statement**: a read past 10 seconds or a write past 60 seconds (the `BoundedDatabase` defaults) is aborted and surfaces as `BoundedDatabaseError.deadlineExceeded`; a write that throws leaves no partial change (MUST).
- **Database busy**: a write waits up to the database's `busyTimeout` (5 seconds by default) and then fails with the database's error; this is `BoundedDatabase` behavior that the store passes through (errors-unwrapped).
- **Offline or disconnected**: not applicable; the store reads and writes a local SQLite file and makes no network call.
- **Missing required value**: the store writes the strings it is given without trimming or checking them; a `NOT NULL` column the record leaves unset is rejected with the database's error (MUST).
- **Action log `status` text**: not validated; `finishActionLog` stores any `status` string, although `ActionLog.status` documents "pending", "ok" or "error" (SHOULD callers pass one of the three).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | `BoundedDatabase` | none | The injected SQLite handle. The store migrates it on creation and routes every read and write through it. |
| `inListChunkSize` | `Int`, internal static | 500 | Ids bound per `IN (...)` statement in `tombstoneMessages(connectionId:externalIds:)`; the source comment says it is "well under SQLite's 32766-variable limit". |
| `MessageQuery.limit` | `Int` | 50 | Rows per page; clamped to at least 0. |
| `MessageQuery.offset` | `Int` | 0 | Rows skipped; clamped to at least 0. |
| `MessageQuery.since`, `until`, `after` | `String?`, `String?`, `MessageKey?` | nil | Optional lower bound, upper bound and resume key. |
| `MessageQuery.labelIds`, `anyLabelIds` | `[String]` | empty | Labels a message must all carry, and labels of which it must carry at least one. |
| `includingDeleted` | `Bool` | false | Lets `message(...)` return a tombstoned row. |
| Read and write deadlines | `Duration`, on `BoundedDatabase` | 10 seconds, 60 seconds | Set when the database is built, not by the store. |

The store reads no environment variable and no settings key.

## Deep Linking

Not applicable: the store is a persistence layer and has no URL, scheme or route.

## Localization

The store produces no user-facing text of its own. The one error it raises, `IntegrationError.unknownAccount`, carries only the account string; its sentence ("No connected account matches ...") is a hardcoded English `errorDescription` in `IntegrationError`, outside this component, and is not localized.

## Accessibility Options

Not applicable: the store has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the source reads no flag.

## Analytics

Not applicable: the source emits no event.

## Privacy

- **Data collected**: The store holds what its callers give it: message sender and recipient addresses, subjects, snippets, bodies, label ids and attachment references; connection account addresses and display names; provider client ids; error text; and action log request payloads and results. It holds no password, access token or refresh token; the schema has no column for one.
- **Storage**: In the SQLite database the injected `BoundedDatabase` points at. The source applies no encryption of its own and sets no file protection; whatever protects the file belongs to the caller.
- **Transmission**: None. The store makes no network call and sends nothing off the device.
- **Retention**: Rows are tombstoned, never purged, so message content and addresses stay in the file after a delete, including after `deleteConnection`. No code in the store removes them.

## Logging

Not applicable: the source makes no log call; failures reach the caller as thrown errors.

## Platform Notes

- **SwiftUI**: The store is not a view. A SwiftUI app reads it through an observable model that calls `messages(_:)`, `labels(connectionId:)` and `connections(provider:)` and republishes the results; GRDB's `ValueObservation` can drive refresh, which the source does not use. Inject the store into an `@Observable` model and put that model in the environment (the store itself is a plain `Sendable` class and publishes nothing), and run the synchronous calls off the main actor because each one blocks on SQLite.
- **Compose**: Port as a Room database with one `@Entity` per table and DAOs per section above. Use `@Upsert` or an `INSERT ... ON CONFLICT(connection_id, external_id) DO UPDATE` query for messages and labels, and keep the local id and created time by reading the row first inside `@Transaction`. Case-insensitive email matching is `COLLATE NOCASE` on the query. Chunk id lists at 500 with `chunked(500)`. Expose reads as `Flow` and writes as `suspend` functions on `Dispatchers.IO`. Room runs `@Transaction` on its single write thread, matching the serialised writer here.
- **React/Web**: Port over IndexedDB (for example Dexie) or SQLite compiled to WebAssembly. IndexedDB has no `json_each`, so test label membership in code or keep a multi-entry index on `label_ids`. A transaction per public write gives the same atomicity; with SQLite WASM, keep the same SQL. Compare dates as ISO-8601 strings exactly as the source does. JavaScript is single-threaded, so ordering inside one tab is by `await`; across tabs, rely on the database's own locking.
- **AppKit / UIKit**: Source platform. The file is `packages/apple/AgenticDeveloperHubSDK/Integrations/Store/IntegrationsStore.swift`, with `IntegrationsSchema.swift` beside it and the record types in `Integrations/Model/IntegrationRecords.swift`. It imports Foundation, GRDB and `AgenticDeveloperHubSDKDatabase`. Records are GRDB `FetchableRecord` and `PersistableRecord` types with snake_case column strategies; Codable properties that are not plain column values (`[String]`, `MailSyncSettings`, `[EmailAttachmentRef]`, `LabelColor`) are stored as JSON text, which is why the query uses SQLite's `json_each`. Calls are synchronous and `throws`; GRDB `save` writes by primary key, so the store sets `id` first when it reuses a row. The store's own test file is `IntegrationsStoreTests` in `Tests/AgenticDeveloperHubSDKIntegrationsTests`; the sync worker and service tests exercise it indirectly.
- **WinUI 3**: Write a C# class `IntegrationsStore` over `Microsoft.Data.Sqlite` (or Entity Framework Core with a SQLite provider) in a library project, taking a database wrapper by constructor and applying a numbered migration at construction. Use one `SqliteTransaction` per public write. Make the methods `async Task` over `SqliteCommand.ExecuteNonQueryAsync` so the UI thread never blocks, and serialise writes with a `SemaphoreSlim(1,1)` or one writer connection in WAL mode, with readers on separate connections as `BoundedDatabase` does. Use `INSERT ... ON CONFLICT(connection_id, external_id) DO UPDATE` for messages and labels, `COLLATE NOCASE` for email, and `json_each` in SQL for labels (SQLite ships it). Store dates as ISO-8601 text, not `DateTime`, so string comparison keeps working, and read them with `DateTimeOffset.ParseExact`. Chunk `IN` lists at 500 with `Enumerable.Chunk(500)` and bind with `SqliteParameter`. Return `IReadOnlyList<EmailMessage>` from queries and raise a typed `UnknownAccountException` where Swift throws `IntegrationError.unknownAccount`. Persist under `Windows.Storage.ApplicationData.Current.LocalFolder`, and expose results to views through an `ObservableCollection` in a view model that implements `INotifyPropertyChanged`; the store itself holds no observable state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Store/IntegrationsStore.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

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
**Rationale**: Technical debt that affects behavior: unlike the message tombstone, it relies on a mailbox having far fewer labels than SQLite's variable limit. The source has no comment on it. A port should chunk this list at `inListChunkSize` once a mailbox can carry more labels than SQLite binds in one statement.
**Approved**: pending

**Decision**: Compare dates as raw strings and validate none of them.
**Rationale**: `IntegrationClock` writes one fixed-width ISO-8601 UTC format, so string order is time order and SQLite can compare without parsing. The store takes `since`, `until`, `cutoff` and `after.internalDate` as `String` and rejects a malformed value nowhere; the source states no reason, and a differently formatted value gives an order that does not follow time.
**Approved**: pending

**Decision**: `connection(idOrEmail:)` ignores provider.
**Rationale**: The lookup takes one string that is either a local id or an account address, so it has no provider to filter on. The same address signed in under two providers has two rows, and the lookup returns the earliest-created. Callers that know the provider use `connections(provider:)`. The source states no reason.
**Approved**: pending

**Decision**: The store has no purge or hard delete; erasing tombstoned content belongs to whoever owns the database file.
**Rationale**: Every delete is a tombstone (see the first decision), so message bodies and addresses stay on disk, including after `deleteConnection`. No store method removes them, and the source names no owner for erasure.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

The store separates concerns well: it holds only SQL and the keyed-upsert and tombstone rules, takes its database by injection, and leaves fetching, parsing, classification, scheduling and status recording to `GmailSyncWorker`, `MailIntegrationService` and the model types. Unit-test coverage is partial: `IntegrationsStoreTests` has 19 tests covering upserts, revival, query filters, ordering, paging, class and date tombstones, labels, connection lookup and cascade, chunked tombstones and the unknown-account error, but none covers a rollback, the action log error paths, a negative `limit` or `offset`, a delete of an unknown row, `deadlineExceeded` or a migration failure, so vectors store-001, store-002 and store-022 to store-033 are derived from the code. Explicit error handling is partial because every error surfaces and `updateSyncState` raises a typed error, but `finishActionLog` returns silently when no row matches. Idempotent operations pass because upserts are keyed and revive tombstones, and a repeated tombstone changes nothing. Data integrity passes because each public write is one transaction and the schema has unique indexes on the message and label keys.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
