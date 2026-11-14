
- **Null and empty input**: A tab with a null or empty `working_directory` falls
  back to the repository path (MUST). An empty label is valid and is the default.
  A `nil` `paneNodeID` is stored as null (MUST for a worktree jar). A key with no
  period after the prefix, or with a non-UUID first component, is not a nested
  pane (MUST).
- **Boundary values**: An empty database returns empty lists and maps and an
  upgrade that writes nothing (MUST). A state key that is exactly the prefix
  has no UUID and is ignored (MUST).
- **Concurrent access**: The store is not `Sendable`; callers serialize
  access (see the requirement on isolation). Two callers racing to make the same
  jar are resolved by the unique indexes: one insert throws and that caller reads
  the winner's row (MUST). The upgrade's row writes are separate statements with no
  transaction of their own; migration 5 calls it inside the migration chain's
  single transaction, so they roll back with the migration, while a direct call
  (as the test makes) is not wrapped.
- **Error states**: A statement that fails to prepare throws
  `prepareFailed` with the SQLite message (MUST). A duplicate insert throws and
  the row is unchanged (MUST). Malformed rows are skipped, see the open question
  on `malformed-row-skipped`.
- **Corrupt stored values**: A corrupt override index is rewritten to the single
  storage-jar name (MUST); the previous value is lost.
- **Moved or removed panes**: A pane whose leaf now shows other content stops
  counting as a browser pane while keeping its node id (MUST); its jar becomes a
  leftover for the reconciler.
- **Nested panes**: A nested browser that has written no state is invisible to
  these queries (MUST); the registry's in-use set covers it while it is open.
- **Offline or disconnected state**: Not applicable: local SQLite only, with no
  network.

