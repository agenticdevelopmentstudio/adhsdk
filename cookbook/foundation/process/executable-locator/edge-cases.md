
- **Null / empty input**: An empty name finds nothing. A missing or empty `PATH` leaves only `extraDirectories`.
- **Boundary values**: The root directory `/` is kept as `/` and its candidate is `/<name>`.
- **Malformed input**: A name holding `/` is refused rather than resolved relative to a directory, so the locator cannot be steered to an arbitrary path.
- **Concurrent access**: The locator is an immutable `Sendable` value; `isExecutable` MUST itself be safe to call from any thread.
- **Error states**: Not applicable: nothing throws; absence is nil.
- **Offline / disconnected state**: Not applicable: no network access.
- **Cancellation and timeouts**: Not applicable: each call is a bounded, synchronous file-system check per directory.

