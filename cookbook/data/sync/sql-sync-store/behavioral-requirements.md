
### Concurrency and isolation

- **concurrency-safe-store**: The store MUST be safe to use concurrently from multiple callers; its internal state MUST NOT change after construction, and concurrent access MUST be serialized by the underlying connection pool.
- **serialized-operations**: Every store-mutating operation (`prepare`, `cursor`, `apply`, `stage`, `pendingOps`, `complete`, `resetForResync`, `registrations`, `purgeResources`, `boundAccount`, `bind(account:)`, `migrateProvenanceColumns`, `writeLocal`) MUST run through a single internal serialization point, so two such operations on the same store never execute at the same time. `signIn` and `discardAccountState` also run through it; `signOut` and `checkAccountGuard` only touch the in-memory sign-in state (the guard reads the binding on a reader connection). `writeLocal` keeps a synchronous signature: it blocks its caller until the serialization point reaches it, and MUST NOT be called from that serialization point.
- **single-transaction-operations**: Every such operation MUST perform all of its database work inside exactly one write transaction, so a failure anywhere in the operation leaves no partial effect.
- **concurrent-read-helpers**: `liveRows`, `liveRow`, `registeredResources` and `status` MUST be synchronous reads that bypass the serialization point, reading from a reader connection (or the writer connection when called during a write), so they MAY run concurrently with each other and with a mutating operation.
- **per-call-codecs**: The store MUST NOT share a JSON encoder or decoder between calls; each call that encodes or decodes builds its own, because a read may run on several pool connections at once.
- **no-cancellation**: Once an operation is queued it MUST run to completion or error; a cancellation requested after queuing MUST have no effect on it.
- **same-connection-variants**: The transaction-joining variants of `prepare` and `stage` MUST run on the caller-supplied connection without opening a transaction or going through the serialization point, so the caller's surrounding transaction commits or rolls back their effects together with its own.

### Resource names and mirror tables

- **table-name-charset**: The mirror-table-name mapping MUST raise an `unknownResource` error naming the resource when the resource is empty or contains any character outside lowercase `a`–`z`, digits `0`–`9`, underscore and period.
- **table-name-mapping**: The mirror-table-name mapping MUST return the resource with every `.` replaced by `_` (`personal.notes` → `personal_notes`).
- **table-name-chokepoint**: Every SQL statement that names a JSON mirror table MUST obtain the name through that one mapping, because SQL cannot bind identifiers and the name is interpolated into the SQL text.
- **projection-claim**: A resource MUST be routed to the projection only when a projection was supplied and its claimed-resources set contains the resource name; every other resource MUST use its JSON mirror table.

### prepare

- **prepare-bookkeeping**: `prepare` MUST create `_sync_state` (with `cursor` and `bound_account`), `_sync_resources`, `_sync_outbox`, `_sync_conflicts`, `_change_log`, `_change_log_pruned` and `_sync_version_floor` if they do not exist, and add `bound_account` to an existing `_sync_state` that lacks it.
- **prepare-projection-tables**: `prepare` MUST have the projection create its own tables on every call when a projection is supplied, even when the resource list is empty.
- **prepare-mirror-table**: For each unclaimed resource, `prepare` MUST create its mirror table if absent with columns `id TEXT PRIMARY KEY NOT NULL`, `sync_version INTEGER NOT NULL DEFAULT 0`, `deleted_at TEXT`, `data TEXT NOT NULL DEFAULT '{}'`, `origin TEXT NOT NULL DEFAULT 'local'`, `reached_accounts TEXT NOT NULL DEFAULT '[]'` and `local_version INTEGER NOT NULL DEFAULT 0`.
- **prepare-no-mirror-for-claimed**: For a resource the projection claims, `prepare` MUST NOT create a JSON mirror table.
- **prepare-register**: For each resource, `prepare` MUST insert `(resource, schemaVersion)` into `_sync_resources`, or overwrite the stored `schema_version` if the resource is already registered.
- **prepare-idempotent**: Calling `prepare` twice with the same resources MUST succeed and leave existing mirror rows intact.
- **prepare-bad-name**: `prepare` MUST raise an `unknownResource` error for an unclaimed resource whose name fails the mirror-table-name mapping, and the whole call MUST roll back.

### cursor and registrations

- **cursor-bootstrap**: `cursor` MUST create the bookkeeping tables if absent before reading, so it returns nothing on a never-prepared store instead of raising an error.
- **cursor-read**: `cursor` MUST return the `cursor` value of the `_sync_state` row with `id = 1`, or nothing when that row or value is absent.
- **registrations-bootstrap**: `registrations` MUST create the bookkeeping tables if absent, so it returns an empty map on a never-prepared store.
- **registrations-map**: `registrations` MUST return every `_sync_resources` row as `resource → schema_version`.

### apply (pulled changes)

- **apply-atomic**: `apply`, given a batch of changes and a new cursor, MUST write every change in the batch and the new cursor in one transaction; if any change fails, no change and no cursor update MUST persist.
- **apply-unknown-resource**: `apply` MUST raise an `unknownResource` error for a change whose resource is not in `_sync_resources`.
- **apply-version-strict**: `apply` MUST raise an `invalidChange` error with message "unparseable syncVersion: <value>" when a change's `syncVersion` does not parse as an integer, and MUST NOT coerce it to 0.
- **apply-upsert-mirror**: For an unclaimed resource, an upsert change MUST insert or replace the row so that `sync_version` equals the parsed version, `deleted_at` is empty, and `data` is the JSON encoding of the change's data (an empty object when the data is absent).
- **apply-delete-mirror**: For an unclaimed resource, a delete change MUST insert or update the row so that `sync_version` equals the parsed version, `deleted_at` is the current timestamp, and `data` is `'{}'`; a delete for a row never seen MUST still create the tombstone.
- **apply-upsert-projection**: For a claimed resource, an upsert change MUST call the projection's upsert operation, marking the row as a full replacement (not a partial patch), with the data (an empty object when absent).
- **apply-delete-projection**: For a claimed resource, a delete change MUST call the projection's mark-deleted operation with the parsed version.
- **apply-cursor-optional**: When a cursor is supplied, `apply` MUST store it as the `_sync_state` row `id = 1`; when no cursor is supplied, the stored cursor MUST be left unchanged.
- **apply-order**: Changes in a batch MUST be applied in array order, so a later change for the same row overwrites an earlier one.

### stage (local mutations)

- **stage-pull-only-first**: `stage` MUST raise a `pullOnlyResource` error naming the resource when the resource is in the pull-only set, before any database work and before the registration check; the same-connection variant of `stage` MUST apply the same check first.
- **stage-unknown-resource**: `stage` MUST raise an `unknownResource` error when the resource is not in `_sync_resources`.
- **stage-atomic**: The mirror write and the outbox write of one `stage` call MUST commit together or not at all.
- **stage-base-version**: `stage` MUST read the row's current `sync_version` (from the projection's stored-version lookup for a claimed resource) before writing, and use it as the base version; a row not yet stored has no base version.
- **stage-upsert-mirror**: For an unclaimed resource, an upsert MUST set `deleted_at` empty and `data` to the JSON encoding of the mutation's data (an empty object when absent), leaving an existing row's `sync_version` unchanged and creating a new row with `sync_version` 0.
- **stage-mirror-patch**: For an unclaimed resource, the JSON mirror MUST replace the row's `data` wholesale with the staged patch, while the outbox merges patches and the projection path treats a staged mutation as a partial patch; fields absent from a patch therefore vanish from `liveRow` until the next pull.
- **stage-delete-mirror**: For an unclaimed resource, a delete MUST set `deleted_at` to the current timestamp on the existing row and MUST NOT change its `data` or `sync_version`; when the row does not exist, no mirror row MUST be created.
- **stage-upsert-projection**: For a claimed resource, an upsert MUST call the projection's upsert operation with the base version (0 when absent), the data (an empty object when absent), marking the row as a partial patch (not a full replacement).
- **stage-delete-projection**: For a claimed resource, a delete MUST call the projection's mark-deleted operation with no version.
- **stage-new-op**: When no `pending` outbox op exists for the same `(resource, rowId)`, `stage` MUST insert one with a freshly minted UUIDv7 `op_id`, the mutation's type, `base_version` equal to the base version as a decimal string (empty when absent), `payload` equal to the JSON encoding of the data (an empty object when absent), `status` `pending`, `attempts` 0, and `created_at` set to the current timestamp.
- **stage-coalesce**: When a `pending` op exists for the same `(resource, rowId)`, `stage` MUST update that op in place, keeping its `op_id` and its original `base_version`, and MUST NOT insert a second op.
- **stage-coalesce-upsert**: When coalescing an upsert, the op's type MUST become `upsert` and its `payload` MUST become the existing payload merged with the new data, the new value winning for a repeated key.
- **stage-coalesce-delete**: When coalescing a delete, the op's type MUST become `delete` and its `payload` MUST become an empty object.
- **stage-no-coalesce-inflight**: `stage` MUST NOT coalesce into an `inflight` or `quarantined` op; it MUST insert a new op with a freshly minted `op_id`.

### pendingOps

- **pending-ops-select**: `pendingOps`, given a limit, MUST return at most that many ops whose status is `pending` or `inflight`, ordered by insertion order.
- **pending-ops-mark-inflight**: `pendingOps` MUST set every returned op's status to `inflight` in the same transaction that selects them.
- **pending-ops-replay**: An op already `inflight` MUST be returned again by later `pendingOps` calls until `complete` resolves it, with the same `op_id`.
- **pending-ops-shape**: Each returned pending op MUST carry `opId`, `resource`, `rowId`, `type`, `baseVersion` from the outbox row, and `data` set to the decoded payload, or nothing when the payload is absent or decodes to an empty object.
- **pending-ops-corrupt-type**: `pendingOps` MUST raise an `invalidChange` error with message "corrupt outbox type column: <value>" when an outbox row's `type` is not `upsert` or `delete`, and the inflight marking MUST roll back.

### complete

- **complete-applied-delete**: For an applied result, `complete` MUST delete the outbox row with that `op_id`.
- **complete-applied-adopt**: For an applied result whose new version parses as an integer, `complete` MUST write that version onto the row's mirror `sync_version` (or through the projection's version setter) before deleting the outbox row, in the same transaction.
- **complete-applied-bad-version**: For an applied result whose new version is present but does not parse as an integer, `complete` MUST skip the version adoption, MUST NOT raise an error, and MUST still delete the outbox row.
- **complete-conflict-audit**: For a conflict result, `complete` MUST insert a `_sync_conflicts` row with the `op_id`, the outbox row's `resource` and `row_id` (empty when the op is not in the outbox), the result's reason, and `resolved_at` set to the current timestamp.
- **complete-conflict-delete**: For a conflict result, `complete` MUST delete the outbox row and MUST NOT change the mirror; adopting the server's row is the caller's job through `apply`.
- **complete-rejected**: For a rejected result, `complete` MUST set the op's status to `quarantined` and increment `attempts` by 1, keeping the row.
- **complete-unknown-op**: A result whose `opId` has no outbox row MUST NOT raise an error; applied and rejected results MUST change nothing, and a conflict result MUST still write an audit row.
- **complete-atomic**: All results in one `complete` call MUST commit in one transaction.

### Recovery and purge paths

- **reset-mirrors**: `resetForResync` MUST delete every row of every registered resource's mirror (through the projection's truncate operation for claimed resources) and clear the stored cursor, keeping the `_sync_state` row and its `bound_account`.
- **reset-preserves-outbox**: `resetForResync` MUST leave `_sync_outbox`, `_sync_resources` and `_sync_conflicts` untouched.
- **purge-resources-empty**: `purgeResources` given an empty list MUST return immediately without touching the database.
- **purge-resources-effect**: For each named resource, `purgeResources` MUST empty its mirror, set its `pending` and `inflight` outbox ops to `quarantined`, and delete its `_sync_resources` row.
- **purge-resources-keeps**: `purgeResources` MUST leave the cursor, already-`quarantined` ops and other resources untouched.
- **purge-resources-unregistered**: `purgeResources` MUST skip the mirror truncation of an unregistered resource silently, without raising an error.
- **identity-change-keeps-data**: Signing in or out MUST NOT delete mirror rows, outbox ops or the cursor on its own. The only operation that drops the departing account's local state is `discardAccountState(rebindingTo:)`, which a host calls explicitly; an identity change is otherwise the host's to handle by pausing the engine.
- **account-binding**: `_sync_state.bound_account` MUST record the account the mirror belongs to; `boundAccount()` MUST return it (nothing when unbound) and `bind(account:)` MUST set it. `resetForResync` MUST clear the cursor and keep the binding.
- **provenance-columns**: `migrateProvenanceColumns()` MUST add the columns `origin TEXT NOT NULL DEFAULT 'local'`, `reached_accounts TEXT NOT NULL DEFAULT '[]'` and `local_version INTEGER NOT NULL DEFAULT 0` to every generic mirror table that lacks them, and MUST be idempotent.
- **provenance-upgrade-origin**: When it adds `origin` to a table that already holds rows, every row with no `pending` or `inflight` outbox op MUST get `origin = 'remote'` (pulled before any account was bound); a row with a queued op keeps `'local'`.
- **provenance-upgrade-version**: When it adds `local_version` to a table that already holds rows, every row MUST get `local_version = 1`, so a create (expected version 0) over an existing row is refused as stale.
- **schema-on-every-entry**: Every operation that reads or writes the bookkeeping tables or the provenance columns (`cursor`, `registrations`, `apply`, `stage`, `complete`, `resetForResync`, `purgeResources`, `bind`, `signIn`, `discardAccountState`) MUST first ensure the bookkeeping schema and run the provenance upgrade, because the engine skips `prepare` when its registrations already cover the manifest.
- **origin-values**: `origin` MUST be `'local'` for a row this device wrote, `'account:<principalId>'` for a row pulled while bound to that account, and `'remote'` for a row pulled while unbound. The first `bind` of an unbound store MUST rewrite `'remote'` rows to `'account:<bound>'` with `reached_accounts` `[<bound>]`.
- **reached-after-push**: An applied push MUST add the bound account to the row's `reached_accounts` only when no other `pending` or `inflight` op is queued for the same row.
- **version-floor**: Emptying a generic mirror (`resetForResync`, `purgeResources`) MUST log a `delete` entry at `local_version + 1` for each live row and raise the resource's `_sync_version_floor` to above every version it handed out; a row inserted afterwards MUST start at that floor plus 1, so `local_version` never decreases for an id. Both operations MUST notify the change observers after commit.

### Account guard

- **sign-in**: `signIn(account:)` MUST declare the account signed in and answer how the store's binding relates to it: `bound` when the store is (or, being empty and unbound, now becomes) bound to it, `mismatch(bound:signedIn:)` when bound to another account, and `unboundWithData(signedIn:)` when unbound but holding rows or queued ops. It MUST NOT bind a store that holds data.
- **sign-out**: `signOut()` MUST declare that nobody is signed in; it changes no stored data.
- **account-guard**: Once the host has declared a sign-in state, `cursor`, `apply` and `pendingOps` MUST raise `accountMismatch(bound:signedIn:)` when nobody is signed in, when the signed-in account differs from the bound one, or when the store is unbound and holds data. A host that never declared a state MUST be unguarded. `checkAccountGuard()` MUST expose the same check to a host draining its own queue.
- **discard-account-state**: `discardAccountState(rebindingTo:)` MUST, in one transaction, delete every `_sync_outbox` row, have each projection discard its local-only state, clear the cursor and bind the store to the given account.

### Local writes, versions and the change feed

- **local-version**: Every generic mirror row MUST carry `local_version`, raised by 1 on every write to the row's data or tombstone (pulled or staged, upsert or delete); a new row starts at 1 (or one past the resource's version floor). Adopting a pushed version in `complete` and updating `reached_accounts` or `origin` MUST NOT raise it or log to `_change_log`.
- **change-log**: Every write that raises a row's `local_version` MUST append `(resource, row_id, kind, version)` to `_change_log` in the same transaction, `kind` being `upsert` or `delete` and `version` the row's new `local_version`.
- **change-log-cap**: The store MUST keep only the newest `changeLogCapacity` entries (default 100,000; positive), deleting older ones in the transaction that logs past the cap and recording the highest pruned `seq` in `_change_log_pruned`.
- **changes-read**: `changes(since:limit:)` MUST return entries with `seq > since`, oldest first, at most `limit`; empty for a non-positive limit, for `since` at or above the head and on a store that never logged. It MUST raise `changeHistoryPruned(since:floor:)` when `since` is below `changeLogFloor()`.
- **changes-resource-filter**: `changes(since:limit:resources:)` given a set of resource names MUST return only entries for those resources, filtered in the query so `limit` counts matching entries; `nil` (the default) MUST mean every resource, and an empty set MUST return nothing. The pruned-history check is unchanged by the filter.
- **change-head**: `changeHead()` MUST return the highest `seq` ever logged (at least the pruning floor), `0` when nothing was logged; `changeLogFloor()` MUST return the highest pruned `seq`, `0` before any pruning.
- **observe-committed**: `observeCommittedChanges` MUST register an observer told after every commit that may have appended to `_change_log`; the call carries no data.
- **write-local**: `writeLocal(body)` MUST run `body` in one write transaction through the serialization point and notify the observers once it commits.
- **local-queries**: `localVersion(resource:id:in:)` MUST return a row's `local_version` and whether it is a tombstone, or nothing for an id never written; `localRecord(resource:id:)` MUST return a live row's data and `local_version`. Both MUST raise `unknownResource` for an unregistered or projection-claimed resource, including on a never-prepared store.
- **write-acceptance**: `isPullOnly(resource)` MUST report membership in the pull-only set, and `acceptsLocalWrites(resource:)` MUST return true only for a registered, unclaimed, push-allowed resource, returning false (never an SQL error) on a never-prepared store.
- **truncate-batched**: Every mirror truncation MUST filter the resources against `_sync_resources` first, then hand all claimed resources to the projection's truncate operation in one call, then delete rows from each unclaimed resource's table.
- **rows-only**: Store operations MUST NOT drop a table or delete the database file; recovery only deletes rows.

### Read helpers

- **live-rows-unknown**: `liveRows` and `liveRow` MUST raise an `unknownResource` error when the resource is not in `_sync_resources`.
- **live-rows-page**: `liveRows`, given a resource, limit and offset, MUST return the non-tombstoned rows (`deleted_at` empty) ordered by `id`, skipping `offset` rows and returning at most `limit`; defaults are `limit` 100 and `offset` 0.
- **live-row-lookup**: `liveRow` MUST return the row with that `id` when it is not tombstoned, and nothing otherwise.
- **live-row-shape**: A JSON-mirror row MUST be returned as its decoded data object with an added `"id"` key set to the row's `id` column, which overrides any `"id"` key inside the data.
- **live-rows-projection**: For a claimed resource, `liveRows` and `liveRow` MUST return the projection's own row-listing and row-lookup results unchanged.
- **registered-resources**: `registeredResources` MUST return the set of resource names in `_sync_resources`.
- **status-shape**: `status` MUST return a status value with `cursor` (the stored cursor or nothing), `outboxDepth` (count of `pending` plus `inflight` ops), `quarantinedDepth` (count of `quarantined` ops) and `conflictCount` (count of all `_sync_conflicts` rows).
- **status-codable**: The status value MUST support standard structured encoding and be safe to pass across concurrent contexts, with the four fields named `cursor`, `outboxDepth`, `quarantinedDepth`, `conflictCount`.

### Persistence and durability

- **durable-state**: The cursor, registrations, mirror rows, outbox ops and conflict audit MUST persist in the database file across process restarts; the store keeps no in-memory copy of them. The declared sign-in state (`signIn`/`signOut`) is the one exception: it is held in memory only, and a new store starts undeclared.
- **crash-replay**: Ops marked `inflight` when the process dies MUST be returned again by the first `pendingOps` after restart.
- **quarantine-retained**: Quarantined ops MUST remain in `_sync_outbox`; the store offers no operation that retries or deletes one individually.
- **conflicts-retained**: `_sync_conflicts` rows MUST never be deleted by any store operation.

### Projection contract

- **projection-sendable**: A projection MUST be safe to use across concurrent contexts.
- **projection-in-caller-txn**: Every projection operation MUST work on the connection it is handed and MUST NOT open its own transaction.
- **projection-create-idempotent**: The projection's table-creation operation MUST be idempotent, because every `prepare` calls it.
- **projection-mark-deleted-nil**: The mark-deleted operation, given no version (a local delete) SHOULD leave the stored version unchanged; the contract states this as guidance, and the store relies on it so a later push can adopt the server version.
- **projection-rows-shape**: The projection's row-listing and row-lookup operations MUST return objects that include an `"id"` key, matching the JSON mirror's return shape.
- **projection-upsert-default**: A projection that does not implement the full-row/partial-patch distinction for its upsert operation MUST receive calls through a default that forwards to a simpler upsert and discards that distinction.
- **projection-purge-default**: A projection that does not implement an identity-purge operation MUST get a default that does nothing.

