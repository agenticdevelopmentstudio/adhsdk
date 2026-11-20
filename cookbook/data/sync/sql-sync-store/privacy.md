
- **Data collected**: The store persists whatever row data the host syncs (JSON object payloads), the pull cursor, and conflict reasons; it adds nothing of its own.
- **Storage**: Everything lives unencrypted in the SQLite file at its configured path; the store applies no encryption and relies on the file's location and OS file protection.
- **Transmission**: The store performs no network I/O; outbox ops leave the device only when the caller pushes them.
- **Retention**: Mirror rows stay until a newer pull, `resetForResync` or `purgeResources` removes them, and survive an identity change (the host pauses sync instead); tombstones and quarantined ops stay indefinitely; `_sync_conflicts` rows (op id, resource, row id, reason) are never deleted. `_change_log` keeps resource names, row ids, kinds and versions (no row data) for the newest `changeLogCapacity` entries. `discardAccountState` deletes the outbox and each projection's local-only state when a host explicitly drops a departing account's data.

