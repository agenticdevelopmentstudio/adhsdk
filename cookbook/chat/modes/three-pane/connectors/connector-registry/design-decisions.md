
**Decision**: `snapshot()` returns the same `RegistrySnapshot` object reference between changes, but that snapshot's `has()`/`get()` methods close over the live underlying `Map` rather than a frozen copy — only `ids()` is captured as a fixed array at the time the snapshot was built.
**Rationale**: A stable object reference lets `useSyncExternalStore`-style consumers treat an unchanged snapshot as identical (`===`) and skip re-rendering, while avoiding the cost of deep-copying the `Map` on every change; `ids()` is copied because callers commonly iterate or diff it.
**Approved**: pending

**Decision**: Re-registering the same id with the identical element reference is a no-op: `register()` returns an empty unregister function and does not notify subscribers.
**Rationale**: This prevents unnecessary subscriber notifications when a component re-registers itself on every render without its element having actually changed.
**Approved**: pending

**Decision**: Subscribers are notified synchronously, immediately after a state change, and the snapshot is rebuilt before any listener runs, so every listener in a given notification pass observes the same snapshot.
**Rationale**: Keeps consumers consistent with each other and with the change that triggered them, without introducing asynchronous scheduling.
**Approved**: pending

**Decision**: `useRegistrySnapshot()` is implemented with React's `useSyncExternalStore` rather than `useState`/`useEffect`.
**Rationale**: `useSyncExternalStore` is the API React provides for subscribing to state that lives outside React, and it guarantees hydration safety and tearing-free reads under concurrent rendering.
**Approved**: pending

