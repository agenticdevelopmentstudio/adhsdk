
- **Null/empty input**: An absent arrangement is valid and means "nothing to copy" (**arrangement-optional**); the window manager also produces one when the source project has no stored tabs.
- **Source and target are the same project**: Not handled here — the window manager skips adopting a project's own configuration.
- **Arrangement from a different edge layout**: Edges are not carried (**no-edges**), so a source project on the left edge and a target on the top edge exchange pane sizes only; each keeps its own edges.
- **Concurrent access**: Not applicable — an immutable value (**immutable-value**).
- **Error states**: Not applicable — construction cannot fail.
- **Offline/disconnected state**: Not applicable — no I/O.
