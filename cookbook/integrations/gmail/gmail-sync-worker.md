---
id: 1157bca1-0d27-49e9-a989-d637505ba5f1
title: "Gmail Sync Worker"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Struct that mirrors one Gmail account into IntegrationsStore with a full sync, a history-based incremental sync, and a full fallback when the cursor expires."
platforms:
  - swift
  - macos
  - ios
tags:
  - gmail
  - mail-sync
  - integrations
depends-on:
  - c19280fd-b80c-46f3-a6a7-0b60a0c90d91
  - cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302
  - df121975-deb8-49a9-b023-0aadcb0923d8
  - 18871853-95b7-492a-9f1f-417283594824
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references:
  - https://developers.google.com/gmail/api/reference/rest/v1/users.history/list
  - https://developers.google.com/gmail/api/reference/rest/v1/users.messages/get
approved-by: ""
approved-date: ""
---

# Gmail Sync Worker

## Overview

`GmailSyncWorker` is a public, `Sendable` Swift `struct` that mirrors one Gmail account into `IntegrationsStore`. One call to `sync(connection:)` first refreshes the connection's labels, then runs either a full sync, when the connection has no `syncCursor`, or an incremental sync that replays Gmail history since that cursor. When Gmail no longer has the cursor, the incremental sync raises `GmailCursorExpired` and the worker runs one full sync in its place. On success the worker writes the new cursor, the time and an `active` status to the store once, and returns a `GmailSyncOutcome` saying which mode ran and how many rows it upserted and tombstoned.

What is kept is decided by the connection's `MailSyncSettings` (`allows(_:)` per mail class, and `windowDays`) and by the `mailClass` that `GmailMessageParser` assigns to each message. The worker bounds what it keeps to a rolling window of `windowDays` days, and it tombstones rows that fall outside the window or that Gmail no longer lists.

The worker does not talk to HTTP, pace quota, parse message bodies, classify mail or schedule itself. It takes a `GmailAPI`, an `IntegrationsStore` and a clock, and it relies on the owner of those collaborators for authentication, retry, pacing, scheduling and per-connection serialisation. `MailIntegrationService` is that owner: it builds a worker per run, serialises runs per connection, and records an `error` or `revoked` status when `sync` throws. The same file also exposes `storeLabels(_:connectionId:in:)`, which the service calls on its own to refresh labels outside a sync.

## Behavioral Requirements

Contract: `public struct GmailSyncWorker: Sendable` with `public init(api: any GmailAPI, store: IntegrationsStore, now: @escaping @Sendable () -> Date = Date.init)`, `public func sync(connection: IntegrationConnection) async throws -> GmailSyncOutcome`, and an internal `static func storeLabels(_ dtos: [GmailLabelDTO], connectionId: String, in store: IntegrationsStore) throws`. The worker holds no mutable state; every run keeps its sets, counters and pending batches in local variables.

### Outcome

- **outcome-shape**: `GmailSyncOutcome` MUST be a `Sendable`, `Equatable` struct with the fields `mode`, `upserted` and `tombstoned`, and a public memberwise initializer.
- **outcome-modes**: `GmailSyncOutcome.Mode` MUST have exactly two cases, `full` and `incremental`, with the raw values "full" and "incremental".
- **mode-reports-last-pass**: The returned `mode` MUST be `full` when the run ended in a full pass, including a full pass that replaced an expired incremental one.

### Entry point

- **labels-first**: `sync(connection:)` MUST refresh the connection's labels before it starts either kind of message pass.
- **no-cursor-full**: `sync(connection:)` MUST run a full sync when `connection.syncCursor` is nil.
- **cursor-incremental**: `sync(connection:)` MUST run an incremental sync from `connection.syncCursor` when it is not nil.
- **expired-falls-back**: When the incremental pass throws `GmailCursorExpired`, `sync(connection:)` MUST run one full sync and return that sync's outcome.
- **fallback-only-expired**: `sync(connection:)` MUST NOT fall back to a full sync for any error other than `GmailCursorExpired`; every other error propagates.
- **state-written-once**: On success `sync(connection:)` MUST call `store.updateSyncState` exactly once, with the pass's cursor, `IntegrationClock.string(from: now())` as `lastSyncAt`, status `.active` and a nil `lastError`.
- **no-state-on-failure**: When `sync(connection:)` throws, it MUST NOT call `store.updateSyncState`, so the stored cursor is unchanged.
- **status-not-recorded**: The worker MUST NOT record an `error` or `revoked` status itself; recording a failed run belongs to the caller.
- **thrown-errors-unchanged**: Errors from `GmailAPI` and from the store MUST reach the caller of `sync(connection:)` unchanged, with no wrapping.

### Labels

- **labels-replace**: `storeLabels` MUST hand the store the complete list of labels Gmail returned through `store.replaceLabels(connectionId:with:)`, so the store upserts those labels and tombstones every live label not in the list.
- **label-fields**: Each `EmailLabel` MUST carry the Gmail label's `externalId`, `name`, `color`, `messagesTotal` and `messagesUnread`, taken from the `GmailLabelDTO`'s `id`, `name`, `color`, `messagesTotal` and `messagesUnread`.
- **label-type**: A label's `type` MUST be "system" when the DTO's `type` is exactly "system" and "user" for any other value.
- **label-parent**: A label's `parentName` MUST be the part of its `name` before the last "/" and MUST be nil when the name has no "/".
- **label-local-id**: `storeLabels` MUST offer a freshly generated lowercase UUID string as each label's local `id`, and the store keeps the local id of a label already present, so a label's id is stable across syncs.
- **labels-before-messages**: Labels MUST be committed before any message is fetched, so a sync that fails later leaves the label refresh in place.

### Full sync

- **baseline-first**: The full pass MUST read the account profile's `historyId` before it lists any message ids, so a change made while listing is replayed by the next incremental sync.
- **baseline-is-cursor**: The cursor a full pass returns MUST be that profile `historyId`, not any later value.
- **query-from-settings**: The full pass MUST list ids with the query and `includeSpamTrash` flag that `GmailQuery.fullSync(settings:now:)` builds from the connection's settings and the clock.
- **list-all-pages**: The full pass MUST call `listMessageIds` again with the returned `nextPageToken` until a page returns no token, and MUST collect the ids of every page.
- **filter-by-class**: The full pass MUST keep a fetched message only when `settings.allows(message.mailClass)` is true.
- **missing-skipped**: The full pass MUST drop a message Gmail answered with a 404 without counting or storing it.
- **batched-upserts**: The full pass MUST store kept messages through `store.upsertMessages` batch by batch as the fetch yields them, not after the whole fetch.
- **tombstone-after-pass**: The full pass MUST tombstone nothing until every id has been fetched and stored.
- **tombstone-unkept**: After the pass the worker MUST tombstone every live row whose `internalDate` is at or after the window start and whose `externalId` was not kept in this pass.
- **tombstone-old**: After the pass the worker MUST also tombstone every live row older than the window start.
- **full-counts**: The full outcome MUST report `upserted` as the number of distinct `externalId` values kept and `tombstoned` as the sum of both tombstone calls' counts.

### Incremental sync

- **history-all-pages**: The incremental pass MUST call `history(startHistoryId:pageToken:)` following `nextPageToken` until it is nil, and MUST send the cursor it started with as `startHistoryId` on every call, not the page's newer `historyId`.
- **cursor-latest-page**: The cursor an incremental pass returns MUST be the `historyId` of the last history page.
- **deleted-first**: The incremental pass MUST tombstone the ids Gmail reported as deleted before it fetches any changed message.
- **deleted-not-fetched**: The incremental pass MUST NOT fetch a changed id that also appears among the deleted ids.
- **changed-deduped**: The incremental pass MUST fetch each changed id once, in first-seen order, however many times history lists it.
- **upsert-rule**: The incremental pass MUST upsert a fetched message only when `settings.allows(message.mailClass)` is true and the message's `internalDate` is at or after the window start.
- **tombstone-rule**: The incremental pass MUST tombstone a fetched id when Gmail no longer has it (a 404), when its class is not allowed, or when it is older than the window.
- **batch-order**: Within one batch the incremental pass MUST tombstone first and upsert second.
- **window-sweep**: After the batches the incremental pass MUST tombstone every live row older than the window start, as the full pass does.
- **incremental-counts**: The incremental outcome MUST report `upserted` as the number of messages it handed to `store.upsertMessages` and `tombstoned` as the sum of the counts the store returned, so ids the store did not hold do not count.

### Fetching

- **fetch-concurrency**: The fetch MUST keep at most 8 `GmailAPI.message(id:)` calls in flight at once.
- **fetch-batch-size**: The fetch MUST hand results to its handler in batches of exactly 100, and the final batch MAY be smaller.
- **fetch-completion-order**: The fetch MUST batch results in the order they complete, not the order of the ids.
- **fetch-handler-serial**: The fetch MUST call its handler one batch at a time from the parent task, so the handler's captured sets and counters are never mutated concurrently.
- **fetch-404-nil**: The fetch MUST turn `IntegrationError.gmail(status: 404, message: _)` from `message(id:)` into a nil message for that id.
- **fetch-error-fails**: Any other error from `message(id:)` MUST fail the fetch, and the batches already handed over MUST stay stored.
- **fetch-parse**: Each fetched DTO MUST be parsed with `GmailMessageParser.parse` using the connection's id, the `existingId` set by **local-id-kept** and the clock value read once at the start of the fetch.
- **local-id-kept**: The worker MUST pass a nil `existingId`, and relies on `store.upsertMessages` to keep the local id and `createdAt` of a row already stored for the same connection and `externalId`.

### Ordering and concurrency

- **struct-sendable**: `GmailSyncWorker` MUST be `Sendable`, and its collaborators `GmailAPI` and the clock closure MUST be `Sendable`.
- **no-self-serialisation**: The worker MUST NOT guard against two overlapping `sync` calls on the same connection; `MailIntegrationService` serialises them per connection.
- **clock-reads**: The worker MAY read the injected clock separately for the query, the window start, the fetch and the stored `lastSyncAt`, so a moving clock gives each read a different value; a port MAY read it once per run (see the last Design Decision).

## Appearance

Not applicable — this is a synchronisation engine, not a visual component.

## States

Not applicable — this is a synchronisation engine, not a visual component. Its runtime path is a sequence rather than a stored state machine: labels are refreshed, then a full or an incremental pass runs (an expired cursor turns the incremental pass into a full one), then the sync state is written once. The worker keeps no state between calls; the connection's cursor and status live in the store.

## Accessibility

Not applicable — this is a synchronisation engine, not a visual component.

## Conformance Test Vectors

Vectors named for a test come from `GmailSyncWorkerTests`, which runs the worker against a `FakeGmailAPI` and an in-memory `IntegrationsStore` with a fixed clock. Vectors marked "Derived" follow from the source and have no test of their own.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sync-worker-001 | no-cursor-full, filter-by-class, baseline-is-cursor, state-written-once, outcome-shape | Test `fullSyncKeepsFiledDropsArchivedByDefault`: no cursor, profile historyId "500", messages a (INBOX), b (user label), c (STARRED), d (CATEGORY_PROMOTIONS), default settings | Outcome is `full`, upserted 3, tombstoned 0; live ids a, b, c; stored cursor "500", status `active`, `lastError` nil, `lastSyncAt` set |
| sync-worker-002 | baseline-first, baseline-is-cursor | Test `fullSyncUsesBaselineHistoryIdTakenBeforeListing`: profile "500"; listing changes the fake's historyId to "900" | Stored cursor is "500" |
| sync-worker-003 | filter-by-class | Test `fullSyncWithArchivedOnKeepsArchived`: `includeArchived` true, messages a (INBOX) and d (CATEGORY_PROMOTIONS) | Live ids a and d |
| sync-worker-004 | tombstone-unkept, tombstone-old, full-counts, tombstone-after-pass | Test `fullSyncTombstonesMissing`: Gmail lists only a; the store holds "gone" (2 days old) and "old" (90 days old) | tombstoned 2; live ids a only |
| sync-worker-005 | list-all-pages, full-counts | Test `fullSyncReadsEveryPage`: id pages [a], [b], [c] | 3 `listMessageIds` calls; upserted 3; live ids a, b, c |
| sync-worker-006 | fetch-batch-size, batched-upserts, full-counts | Test `fullSyncStoresMoreThanOneBatch`: 250 messages | Outcome full, upserted 250, tombstoned 0; all 250 live |
| sync-worker-007 | fetch-error-fails, batched-upserts, tombstone-after-pass, no-state-on-failure, thrown-errors-unchanged | Test `fullSyncFailurePartwayKeepsStoredBatches`: 250 messages, `message(id:)` for m240 fails with `IntegrationError.gmail(status: 500, message: "Boom")`, a stale in-window row exists | `sync` throws that same error; the stored count is a multiple of 100 and at least 200; the stale row is still live; the cursor is still nil |
| sync-worker-008 | list-all-pages, no-state-on-failure, thrown-errors-unchanged | Test `fullSyncListErrorPropagates`: listing fails with `IntegrationError.gmail(status: 403, message: "Forbidden")`, a row "kept" exists | `sync` throws 403; "kept" is still live; the cursor is nil |
| sync-worker-009 | query-from-settings | Test `spamAndTrashFollowSettings`: default settings, then `includeSpam` and `includeTrash` true; messages in (INBOX), spam (SPAM), trash (TRASH) | Default run: `includeSpamTrash` false, live ids in. Second run: `includeSpamTrash` true, live ids in, spam, trash |
| sync-worker-010 | local-id-kept | Test `resyncKeepsLocalId`: row "a" already stored with local id "local-a", then a full sync returns "a" | The stored row's `id` is still "local-a" |
| sync-worker-011 | cursor-incremental, history-all-pages, cursor-latest-page, upsert-rule, deleted-first, incremental-counts | Test `incrementalUpsertsChangedAndTombstonesDeleted`: cursor "600"; history page 1 changed [new], historyId "610", next token; page 2 deleted [del], historyId "620", no token; "del" is stored | Outcome incremental, upserted 1, tombstoned 1; live ids new; history called twice with "600" both times; stored cursor "620" |
| sync-worker-012 | incremental-counts | Test `incrementalCountsRealTombstones`: history deletes ["del", "never-stored"], and only "del" is stored | tombstoned 1, upserted 0 |
| sync-worker-013 | upsert-rule, tombstone-rule | Test `incrementalTombstonesOutOfWindowChange`: changed message "old" is 90 days old with a STARRED label, and is stored | upserted 0, tombstoned 1; no live rows |
| sync-worker-014 | tombstone-rule | Test `incrementalTombstonesMessageThatBecameArchived`: stored "a" now carries only CATEGORY_PROMOTIONS and is changed in history | tombstoned 1; no live rows |
| sync-worker-015 | tombstone-rule, fetch-404-nil | Test `messageFetch404DuringIncrementalTombstones`: changed id "a" answers 404 and is stored | Outcome incremental, upserted 0, tombstoned 1; no live rows |
| sync-worker-016 | fetch-error-fails, no-state-on-failure, fallback-only-expired | Test `fetchErrorPropagates`: cursor "600"; fetching changed id "a" fails with `IntegrationError.gmail(status: 500, message: "Boom")` | `sync` throws that error; the cursor is still "600" |
| sync-worker-017 | expired-falls-back, mode-reports-last-pass, baseline-is-cursor | Test `incrementalFallsBackToFullOn404`: cursor "600"; `history` throws `GmailCursorExpired`; profile "700"; message a (INBOX) | Outcome mode `full`, upserted 1; exactly 1 `listMessageIds` call; stored cursor "700" |
| sync-worker-018 | expired-falls-back, tombstone-unkept, full-counts | Test `fallbackFullSyncTombstones`: cursor "600"; `history` throws `GmailCursorExpired`; Gmail lists a; "gone" (3 days old) is stored | Outcome `full`, upserted 1, tombstoned 1; live ids a |
| sync-worker-019 | labels-first, labels-replace, label-fields, label-type, label-parent, label-local-id | Test `labelsSyncedAndVanishedTombstoned`: labels INBOX (id INBOX, system), "Work/Clients/Acme" (id Label_1, user, total 4), "Gone" (id Label_2, user); then a second sync lists only Label_1 | First sync stores 3 labels; Acme has `parentName` "Work/Clients", type "user", `messagesTotal` 4; INBOX has type "system" and `parentName` nil. After the second sync only Label_1 is live, with the same local id |
| sync-worker-020 | window-sweep, deleted-not-fetched, changed-deduped | Derived: cursor "600"; history changed ["x", "x", "y"], deleted ["y"]; a live row older than the window exists | `message(id:)` is called once, for "x" only; "y" is tombstoned and never fetched; the old row is tombstoned |
| sync-worker-021 | no-state-on-failure, labels-before-messages | Derived: `labels()` succeeds, `profile()` throws | `sync` throws that error; labels are already replaced; the cursor is unchanged |
| sync-worker-022 | fetch-concurrency | Derived: 50 ids, each `message(id:)` suspends until released, counting in-flight calls | The in-flight count never exceeds 8 |
| sync-worker-023 | label-type, label-parent | Derived: a label with type "other" named "A/B" and a label of type "user" named "/x" | First: type "user", `parentName` "A". Second: type "user", `parentName` "" (empty string) |
| sync-worker-024 | fallback-only-expired | Derived: cursor present; `history` throws `IntegrationError.gmail(status: 500, message: "Boom")` | `sync` throws that error; no `listMessageIds` call is made |

## Edge Cases

- **Empty account (null and empty input)**: When Gmail lists no ids, the full pass fetches nothing, tombstones every live row in the window and every row older than it, and returns upserted 0. This MUST hold.
- **Empty history**: When history returns changed and deleted ids that are both empty, the incremental pass fetches nothing and returns upserted 0 with whatever the window sweep tombstoned. The cursor still advances to the last page's `historyId`. This MUST hold.
- **No ids to tombstone**: Passing an empty list to `tombstoneMessages(connectionId:externalIds:)` returns 0 without a write, so a batch that has no tombstones adds nothing. This MUST hold.
- **Message deleted between listing and fetching**: The 404 makes the fetch return nil for that id. The full pass drops it; the incremental pass tombstones it. This MUST hold.
- **Id in both changed and deleted**: It is tombstoned as deleted and never fetched. This MUST hold.
- **Same id changed many times**: History repeats an id once per change; the worker fetches it once. This MUST hold.
- **Boundary at the window start**: A message dated exactly at the window start is kept, because the comparisons use "at or after". Rows older than the start are tombstoned. The incremental upsert compares `message.internalDate >= windowStart` as ISO-8601 strings, which order the same as the instants when both sides use `IntegrationClock`'s format. This MUST hold.
- **Window settings (boundary values)**: The worker does not check `windowDays`; this is a gap in the code, not a requirement, and a port SHOULD accept only validated settings. `MailSyncSettings.validated()` limits it to 1 through 3650 and its caller owns that check; a value of 0 or less would put the window start at or after the present and tombstone nearly everything. The worker computes the start as the clock minus `windowDays` times 86,400 seconds.
- **Exactly 100 results**: The fetch hands over a full batch of 100 and then, with nothing pending, no empty final batch. This MUST hold.
- **Expired cursor mid-history**: `GmailCursorExpired` thrown by any history page discards the pages already read and triggers the full sync. The partly gathered ids are not used. This MUST hold.
- **Expired cursor on the fallback**: The `catch` covers only the incremental call, so a `GmailCursorExpired` thrown by the fallback full pass propagates to the caller. A port MUST propagate it and MUST NOT retry the fallback.
- **Failure partway through a full pass (error states)**: Batches already stored stay stored, no tombstoning happens, and no cursor is written. The next `sync` repeats a full pass when the run began without a cursor (it is still nil); when the full pass was the fallback for an expired cursor, the stored cursor is still the expired one, so the next run tries the incremental pass again and falls back again. This MUST hold.
- **Failure partway through an incremental pass**: The deleted ids have been tombstoned and some batches stored, but the cursor stays at its old value, so the next run replays the same history. Replaying is safe because upserts are keyed on `(connection_id, external_id)` and tombstoning a tombstoned row changes nothing. This MUST hold.
- **Failure after the labels step**: A later failure leaves the refreshed labels in place. This MUST hold (see **labels-before-messages**).
- **Cancellation**: The worker never checks `Task.isCancelled` and has no cancel path. Cancelling the calling task propagates into the awaited `GmailAPI` calls and the task group, which end the run by throwing; the stored cursor is then unchanged. `MailIntegrationService` treats that outcome as not an error. The worker's own promise ends at "the cursor is written only on success".
- **Offline or unreachable Gmail**: The worker has no connectivity handling. A failed `GmailAPI` call throws and the sync fails with the cursor unchanged. Timeouts, retry, backoff and pacing belong to `GmailRESTClient`, which is outside this recipe.
- **Concurrent access**: The worker itself keeps no shared state and runs concurrent fetches only inside one run; their results are consumed one at a time. Two overlapping `sync` calls for the same connection are not prevented here and would interleave their store writes; `MailIntegrationService` keeps one running sync per connection and cancels it before starting another. Within one run the batch contents depend on completion order and so vary between runs, while the final stored set does not.
- **Lost clock consistency**: Because the clock is read separately for the query, the fetch and the window start, a clock that advances during a long run gives later reads a later window. The worker does not freeze one instant. A port MAY read the clock once per run (see **clock-reads**).
- **Rows excluded by settings**: A row stored under an earlier, wider setting is tombstoned by the next full pass if it is in the window and not kept, and by the incremental pass only if it changes. This MUST hold.
- **Label name edge cases**: A name ending in "/" has the whole name before that slash as its parent. A name starting with "/" has the empty string as its parent. A port that must stay compatible with stored data MUST copy this; the behavior is otherwise unspecified.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api` | `any GmailAPI` | none | The Gmail client; the worker calls `labels`, `profile`, `listMessageIds`, `history` and `message`. |
| `store` | `IntegrationsStore` | none | The local mirror; receives labels, messages, tombstones and the sync state. |
| `now` | `@Sendable () -> Date` | `Date.init` | The clock, injected so tests fix time. |
| `connection` (argument to `sync`) | `IntegrationConnection` | none | Supplies `id`, `syncCursor` and `syncSettings`. |
| `syncSettings.includeArchived`, `includeSpam`, `includeTrash` | `Bool` | false, false, false | Decide, through `allows(_:)` and `GmailQuery.fullSync`, which mail classes are listed and kept; filed mail is always kept. |
| `syncSettings.windowDays` | `Int` | 30 | How many days back the window reaches; validated elsewhere to 1 through 3650. |
| `fetchConcurrency` | `Int` constant | 8 | Message fetches in flight at once. |
| `upsertBatchSize` | `Int` constant | 100 | Messages handed to the store per batch. |

There are no environment variables or settings keys read by the worker. `syncSettings.pollIntervalMinutes` exists on the settings type but is not read here; the caller schedules runs.

## Deep Linking

Not applicable: the source has no URLs or routes of its own; the Gmail requests are built by the injected `GmailAPI`.

## Localization

Not applicable: the worker produces no user-facing strings of its own; it passes through the errors that `GmailAPI` and the store throw, and `MailIntegrationService` turns them into the `lastError` text.

## Accessibility Options

Not applicable: the source has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the source reads no flag; its behavior is switched only by the connection's `MailSyncSettings`, listed under Configuration.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: The worker reads each Gmail message the settings allow, through `GmailAPI.message(id:)`, and parses it into an `EmailMessage` with `GmailMessageParser`. It reads label names and counts. It handles no password or token itself; credentials live inside the injected `GmailAPI`.
- **Storage**: Messages, labels and the sync state go to the injected `IntegrationsStore` only. The worker writes nothing else to disk.
- **Transmission**: The worker sends only ids, query text, history cursors and page tokens to Gmail, through `GmailAPI`. It sends no stored data anywhere.
- **Retention**: A message that leaves the window, is deleted in Gmail or is excluded by the settings is tombstoned, which the store records as a soft delete with `is_deleted` and `deletedAt`; this worker never purges a row.

## Logging

Not applicable: the source makes no log call; failures reach the caller as thrown errors.

## Platform Notes

- **SwiftUI**: Not a view, so nothing to translate. A SwiftUI app sees the worker's effect through store queries and the connection's `status`, `lastSyncAt` and `lastError`, which `MailIntegrationService` publishes; the worker has no `Observable` or `ObservableObject` dependency and holds no UI state.
- **Compose**: Port as a Kotlin class with `suspend fun sync(connection: IntegrationConnection): GmailSyncOutcome`. Use a `data class GmailSyncOutcome` with an `enum class Mode`. Replace the task group with `coroutineScope` and a `kotlinx.coroutines.sync.Semaphore(8)` or a `Channel`, collecting results as they complete and flushing every 100; the handler must run in one coroutine so the shared sets need no lock. Persist with Room: `@Upsert` for messages keyed on a unique index over connection and external id, and a transaction per call for tombstones. Map a 404 to a nil result by catching the HTTP client's exception type (for example Retrofit `HttpException` with code 404). Cancellation is cooperative through `ensureActive()`, so the 8-wide fetch ends when the parent scope cancels. Inject the clock as a `() -> Instant` or `java.time.Clock`.
- **React/Web**: Port as a TypeScript class with `async sync(connection): Promise<GmailSyncOutcome>`. JavaScript is single-threaded, so keep a pool of 8 promises (a small `Promise.race` loop or a worker-pool helper) and run the batch handler between awaits; no lock is needed because nothing interleaves inside the handler. Persist in IndexedDB (a transaction per batch, with a unique index on connection id and external id) or behind an HTTP API. Compare window dates as ISO-8601 strings only if both sides share the format, or compare `Date` values. Use `AbortSignal` for cancellation, which the Swift worker leaves to task cancellation. Catch a fetch error whose status is 404 to produce a null message.
- **AppKit / UIKit**: Source platform. The code is `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailSyncWorker.swift`. It imports Foundation only and relies on Swift concurrency: `async throws` methods and `withThrowingTaskGroup` for the 8-wide fetch, with a nested `addNext()` that refills the group as each task ends, and a closure handler called from the parent task. `IntegrationClock.string(from:)` supplies ISO-8601 strings with fractional seconds, and ordering of dates is a string comparison. The store is GRDB-backed and synchronous, so its calls run on whichever executor resumes the task. The other types it uses are `GmailAPI`, `GmailCursorExpired`, `GmailQuery`, `GmailMessageParser`, `MailSyncSettings`, `IntegrationError` and `IntegrationsStore`, compiled into the `AgenticDeveloperHubSDKIntegrations` framework target (declared in `packages/apple/AgenticDeveloperHubSDK/project.yml`). `GmailSyncWorkerTests` in `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKIntegrationsTests/GmailSyncWorkerTests.swift` is the only test file for the worker.
- **WinUI 3**: Write a `sealed class GmailSyncWorker` in C# with `Task<GmailSyncOutcome> SyncAsync(IntegrationConnection connection, CancellationToken ct)` and a `readonly record struct GmailSyncOutcome(SyncMode Mode, int Upserted, int Tombstoned)`. Take an `IGmailApi`, a store interface and a `Func<DateTimeOffset>` clock by constructor. For the 8-wide fetch, use `System.Threading.Channels` or `SemaphoreSlim(8)` with `Task.WhenAny`, or `Parallel.ForEachAsync` with `MaxDegreeOfParallelism = 8` writing into a `Channel<(string, EmailMessage?)>`; one consumer drains it into batches of 100 so the handler never runs concurrently. Map the 404 to null by catching `HttpRequestException` with `StatusCode == HttpStatusCode.NotFound` from `HttpClient`, or a typed exception from the client wrapper. Model `GmailCursorExpired` as an exception class and use `catch (GmailCursorExpiredException)` for the fallback. Persist with `Microsoft.Data.Sqlite` or Entity Framework Core: `INSERT ... ON CONFLICT(connection_id, external_id) DO UPDATE` for upserts, keeping the local id and created time, and one `DbContext` transaction per batch. Store dates as ISO-8601 text or `DateTimeOffset` and compare as instants. Run the worker from an `IHostedService` or a `DispatcherQueueTimer` rather than from UI code, and surface `status` and `lastError` through an `INotifyPropertyChanged` view model; the worker itself exposes no observable state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailSyncWorker.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Take the history baseline from the profile before listing, and return it as the full sync's cursor.
**Rationale**: The source comment says it is "Taken before listing, so a change made while listing is replayed by the next incremental sync." A baseline read after listing could skip a change made during the listing. The cost is that the next incremental sync may replay a few changes the listing already saw, which is harmless because upserts are idempotent.
**Approved**: pending

**Decision**: Store and tombstone a full sync batch by batch, and tombstone only after the whole pass.
**Rationale**: The doc comment says this lets "a long first sync keep what it has fetched if it fails partway". Tombstoning from a partial listing would wrongly delete rows that were simply not reached. The price is that a failed first sync leaves a partial mirror with no cursor, and the next run repeats the full pass.
**Approved**: pending

**Decision**: Write the cursor and status once, only on success, and leave recording failures to the caller.
**Rationale**: The doc comment on `sync` states it persists them "once, on success". An unchanged cursor on failure means the next run replays the same history or repeats the same full pass. `MailIntegrationService.record` sets the `error` or `revoked` status and skips it for cancellation, which keeps that policy in one place.
**Approved**: pending

**Decision**: The incremental pass also tombstones rows the window has moved past.
**Rationale**: The doc comment says this is done "as a full sync does, so the window bounds what is kept in steady state — a full sync runs only when the cursor is missing or expired." Without the sweep, a row would stay until a full sync ran, which in steady state is almost never.
**Approved**: pending

**Decision**: The incremental pass tombstones a changed message that falls outside the window or the allowed classes, and one Gmail no longer has, rather than ignoring it.
**Rationale**: A message that became archived, or whose date or class no longer qualifies, must leave the mirror. The 404 case covers a message deleted after history was written. The tests `incrementalTombstonesMessageThatBecameArchived` and `incrementalTombstonesOutOfWindowChange` pin this.
**Approved**: pending

**Decision**: Fetch eight messages at a time and store in batches of 100.
**Rationale**: The numbers are `fetchConcurrency` and `upsertBatchSize`; the source does not state why. Eight is small enough to stay modest against Gmail's per-user quota, which `GmailRESTClient` also paces, and 100 bounds how much a partial failure can lose, because the stored count is a multiple of the batch size. Whether eight is the best number is outside the source.
**Approved**: pending

**Decision**: Batch results in completion order, and never in id order.
**Rationale**: The fetch refills the group as soon as any task ends, so a slow message does not hold up the others. The cost is that batch contents vary between runs, which the failure test accounts for by asserting a multiple of 100 rather than exact ids.
**Approved**: pending

**Decision**: Pass `existingId: nil` to the parser and let the store keep the local id.
**Rationale**: The source comment says "The store keeps the local id of a row that already exists." This keeps the worker from reading each row before it fetches, and `resyncKeepsLocalId` pins the result.
**Approved**: pending

**Decision**: The worker does not serialise overlapping syncs, retry, pace, or log.
**Rationale**: Per-connection serialisation, status recording and scheduling live in `MailIntegrationService`; retry, backoff and pacing live in `GmailRESTClient` and `GmailQuotaPacer`. Keeping the worker free of them keeps it testable against a fake API with a fixed clock. A port must put these concerns in the same owners.
**Approved**: pending

**Decision**: Technical debt: the clock is read separately for the query, the fetch, the window start and the stored time.
**Rationale**: The worker calls `now()` several times per run, so on a long run the window start used for the final sweep is later than the one in the query. It is harmless in the tests because the clock is fixed, and the effect is a window that drifts a little during one run. A port may read the clock once, but it should record that as a deliberate change.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

The worker separates concerns cleanly: it sequences calls to an injected `GmailAPI`, an injected store and an injected clock, and leaves transport, retry, pacing, parsing, classification, scheduling, serialisation and status recording to other components. Unit-test coverage is partial: `GmailSyncWorkerTests` has 19 tests covering both modes, paging, batching, partial failure, fallback, tombstoning and labels, but none asserts the fetch concurrency limit of 8, an empty account, changed-id deduplication, the deleted-id exclusion, cancellation, a failure in `labels()` or `profile()`, or the label-name edge cases, and vectors sync-worker-020 to sync-worker-024 are derived from the code. Explicit error handling passes because no error is swallowed: every `GmailAPI` and store error propagates unchanged, the one handled error `GmailCursorExpired` and the one converted status, a 404 on a message, are deliberate and tested. Idempotent operations pass because a repeat of any pass leaves the same stored set: upserts are keyed on connection and external id and revive tombstoned rows, and tombstoning a tombstoned row changes nothing. Data integrity is partial: each store call is its own transaction, so a failed run can leave labels, some batches and the deleted-id tombstones written without a cursor, and the design relies on replay rather than a single transaction to reach a consistent mirror.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
