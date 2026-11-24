
- **Null / empty input**: `subsystem("")` returns the label plus a trailing dot; the suffix is not validated (the type MUST NOT reject it). A `home` that does not exist yields URLs for nonexistent paths without error.
- **Boundary values**: `httpPort` is fixed at `22849`; the type does not check that the port is free. No numeric input is accepted.
- **Concurrent access**: Not applicable: every member is an immutable constant or a pure computed property over an immutable `home`, and `ADKDPaths` is `Sendable`.
- **Error states**: Not applicable: no member throws, returns an optional or touches the file system.
- **Offline / disconnected state**: Not applicable: the type performs no network access; `httpBaseURL` is only a string naming the loopback address.
- **Drift between the two storage-token spellings**: `storageToken` is a hand-written copy of a value the database layer derives from the display name. The doc comment on `ADKDPaths.storageToken` in `ADKDIdentifiers.swift` says a test in the app's own target checks the two agree; that test is outside the sources given here, so a port carries its own check (see `storage-token-agreement-test`).

