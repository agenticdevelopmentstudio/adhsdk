
- **Empty prefix**: Known hazard: an empty prefix stores under the bare keys, which are the daemon's own `settings` keys, and the source does not forbid it. Callers SHOULD pass a non-empty prefix.
- **Duplicate and unsorted ids**: Assigned lists MUST be stored as given and only the `preferences` snapshot MUST sort and de-duplicate them.
- **Out-of-range retention**: A value below 7 or above 3650 MUST be stored unchanged and clamped in `preferences`.
- **Stored text that does not decode**: Not decided here; decoding and fallback to the default belong to `UserSetting` and `UserSettings.shared`, outside the given source.
- **Concurrent access**: The class is `@MainActor`, so the compiler keeps access on the main actor and calls from elsewhere need `await`; there is no other ordering rule to state.
- **Cleanup**: Each setting can be removed (the test calls `remove()` on all four), which returns it to its default; that reset belongs to `UserSetting`, outside the given source, so it is not a requirement here.
- **Errors, timeouts, offline, cancellation**: Not applicable — the class is synchronous, throws nothing and does no I/O of its own.

