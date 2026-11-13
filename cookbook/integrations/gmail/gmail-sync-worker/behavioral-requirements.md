
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

