
This store is a SQLite-backed implementation of the store contract driven by
the sync engine (see Sync Engine ([adhsdk.ingredient.data.sync.sync-engine](cookbook:355a8f54-aee5-45cd-a28d-12c3b7a3085c))).
It sits on a bounded, deadline-guarded write-ahead-logged connection pool and
keeps seven bookkeeping tables plus one mirror table per registered resource:

- `_sync_state` — the single-row pull cursor and the bound account.
- `_sync_resources` — the registered resource names and their schema versions.
- `_sync_outbox` — local mutations owed to the server, each `pending`, `inflight` or `quarantined`.
- `_sync_conflicts` — an append-only audit of conflicted pushes.
- `_change_log` — the local change feed, one entry per row write, capped at the newest `changeLogCapacity` entries.
- `_change_log_pruned` — how far the change feed has been pruned.
- `_sync_version_floor` — each resource's `local_version` high-water mark across resets and purges.
- one mirror table per resource — `(id, sync_version, deleted_at, data, origin, reached_accounts, local_version)` with the row's fields stored as a JSON blob in `data`.

An optional projection can claim a subset of resources and store them in typed
tables instead of the JSON mirror; every mirror-touching operation asks the
projection first and falls through to the JSON mirror for unclaimed resources.

Use it when a host needs the offline mirror and outbox to survive restarts.
Beyond the store contract it offers synchronous read helpers (`liveRows`,
`liveRow`, `registeredResources`, `status`) for a daemon or UI,
transaction-joining variants of `prepare` and `stage` for a store layered on
top of it, a local write path (`writeLocal`, `localVersion`, `localRecord`,
`acceptsLocalWrites`, `isPullOnly`), a change feed (`changes`, `changeHead`,
`changeLogFloor`, `observeCommittedChanges`), and an account guard (`signIn`,
`signOut`, `checkAccountGuard`, `discardAccountState`).

