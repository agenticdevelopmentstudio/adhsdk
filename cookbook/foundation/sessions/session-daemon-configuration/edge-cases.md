
- **Empty or relative paths**: stored as given under `#requirements/no-validation`; a failure surfaces later where the path is used.
- **Zero or negative retention**: stored as given under `#requirements/no-validation`, including 0 and negative values; what such a value means is up to `RetentionService`.
- **Zero or negative intervals**: stored as given under `#requirements/no-validation`.
- **Port 0**: accepted under `#requirements/no-validation`; it means the OS assigns a port, and `test` uses it (`#requirements/test-port`).
- **Boundary values of `httpPort`**: The `UInt16` type limits the port to 0 through 65535 at compile time; a larger literal does not compile.
- **Default derived from a nil argument only**: A default for `databasePath`, `spoolPath` or `errorsDirectory` is computed once from the arguments passed to the same call (`#requirements/database-default`, `#requirements/spool-default`, `#requirements/errors-default`); changing `supportDirectory` later on the `var` does not update `databasePath`, `spoolPath` or `errorsDirectory`.
- **Shared settings file**: Two daemons whose `hook.settingsURL` point at the same `settings.json` coexist because each hook marker is distinct; the marker rules belong to `ClaudeHookConfiguration`.
- **Concurrent access**: Not applicable: the struct is a `Sendable` value type, copied on assignment, so no two holders share mutable state.
- **Error states, offline, cancellation**: Not applicable: building the value does no I/O and cannot throw.

