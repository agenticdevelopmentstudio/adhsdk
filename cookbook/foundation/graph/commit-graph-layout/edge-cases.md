
- **Null / empty input**: Appending no commits returns no rows and leaves the state unchanged.
- **Boundary values**: A commit whose parents are all already expected opens no slot; a history of independent roots stays in column 0 with a new lane each.
- **Concurrent access**: A value type; each copy has its own slots and lane counter. `append` is `mutating`, so callers serialise it through the owner of the value.
- **Error states**: The layout cannot fail. A parent that never appears keeps its slot open; a commit appended twice is laid out again from the current slots.
- **Offline / disconnected state**: Not applicable: The layout has no network access.
- **Cancellation**: Not applicable: The layout runs synchronously over the commits it is given.

