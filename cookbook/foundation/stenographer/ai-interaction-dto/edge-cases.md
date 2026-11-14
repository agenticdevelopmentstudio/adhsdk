
- **Null / empty input**: The DTO has no optionals; absent values are carried as empty strings (`sessionId` when not session-scoped, `configName` on the CLI path, `error` on success, `response` on failure); see `decoder-empty-string-present`.
- **Boundary values**: A row whose text is exactly at the truncation length is not marked truncated, because the daemon's check is a strict length greater than the limit. The DTO itself holds no limit.
- **Concurrent access**: Not applicable: the type is an immutable value and `Sendable`.
- **Error states**: A DTO whose `outcome` is not `ok` is a failure result, not a decoding error; the reason is in `error`. A missing key fails decoding for the whole payload, with no field fallback.
- **Offline / disconnected state**: Not applicable: the type does no networking; transport failures are the HTTP client's and XPC service's concern.
- **Unknown vocabulary**: A newer daemon may send a `feature`, `providerKind` or `outcome` this build does not list. It decodes, and any unrecognised `outcome` is treated as a failure by `isFailure`.

