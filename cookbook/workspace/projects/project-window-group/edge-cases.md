
- **Null and empty input**: An empty list: `deactivate` of anything returns the
  current selection; `activate` appends (MUST). A `nil` selection makes
  `activate` append at the end (MUST). `select(nil)` clears (MUST).
- **Boundary values**: Deactivating the last element of the selected project
  picks the one before; the first picks the new first; the only one returns
  `nil` (MUST). The index is clamped with `min(index, count - 1)`.
- **Duplicates**: `activate` never creates a duplicate; the initializer accepts
  whatever list the state holds, including duplicates, without checking (see
  the requirement `selection-not-validated`).
- **Concurrent access**: Main-actor isolated, so all access and every change is
  serialized on one actor (MUST). Callers off the main actor hop first.
- **Error states**: No operation throws or returns an error; an unknown id is
  handled as a no-op or a returned selection (MUST).
- **Selection drift**: `deactivate` returns the next selection but does not apply
  it; a caller that ignores the return leaves `selectedRepoID` pointing at a
  project no longer in the list.
- **Offline or disconnected state**: Not applicable: no network or file access.
  Persistence is the caller's, through `state` and `UserSettings.projectWindows`.

