
- **Empty or relative paths**: The initializer MUST store an empty `socketPath` or a relative `databasePath` as given; the struct does no validation, and a failure surfaces later where the path is used.
- **Zero or negative retention**: `retentionDays` MUST be stored as given, including 0 and negative values; the struct does not constrain it, and what such a value means is up to `RetentionService`.
- **Zero or negative intervals**: `livenessCheckInterval` and `retentionCheckInterval` MUST be stored as given; the struct does not constrain them.
- **Port 0**: `httpPort` of 0 MUST be accepted, and means the OS assigns a port; `test` uses it.
- **Boundary values of `httpPort`**: The `UInt16` type limits the port to 0 through 65535 at compile time; a larger literal does not compile.
- **Default derived from a nil argument only**: A default for `databasePath`, `spoolPath` or `errorsDirectory` MUST be computed from the arguments passed to the same call; changing `supportDirectory` later on the `var` does not update `databasePath`, `spoolPath` or `errorsDirectory`.
- **Shared settings file**: Two daemons whose `hook.settingsURL` point at the same `settings.json` coexist because each hook marker is distinct; the marker rules belong to `ClaudeHookConfiguration`.
- **Concurrent access**: Not applicable: the struct is a `Sendable` value type, copied on assignment, so no two holders share mutable state.
- **Error states, offline, cancellation**: Not applicable: building the value does no I/O and cannot throw.

