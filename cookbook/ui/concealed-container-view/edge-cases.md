
- **Null/empty input** (MUST): a container with no window does nothing on reveal; a window with no content view is left alone.
- **Boundary values** (MUST): the first container revealed blanks the window and the last one concealed restores it (see `capture-any-container`).
- **Container removed while revealed** (MUST): the old window is restored when no other container there is revealed (see `capture-on-detach`).
- **Container inside container** (MAY): the window search does not descend into a concealed container once found, so a nested container's reveal state is not counted; only the outer one is.
- **Non-container ancestor** (MUST): ordinary ancestors are skipped; only a concealed container ancestor counts for `isConcealed(_:)`.
- **Sharing type changed by someone else** (MAY): the source writes the window's sharing type on every re-evaluation, overriding a value set elsewhere, and restores only to read-only, never to a previously held value.
- **Concurrent access** (MUST): confined to the main thread.
- **Error states**: Not applicable: no I/O or throwing operation.
- **Offline/disconnected state**: Not applicable: no networking.

