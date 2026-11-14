
- **wraps-api**: `init(api:)` MUST route `pull` to `ADHSyncAPI.pull(cursor:limit:)` and `push` to `ADHSyncAPI.push(body:)`, and hold no other state.
- **cursor-raw-value**: `pull` MUST pass the cursor's `rawValue`, or nil when the engine has no cursor, and the engine's limit unchanged.
- **decode-pull**: `pull` MUST decode the response body as `SyncPullResponse` with a default `JSONDecoder` (camelCase keys, as the hub sends them).
- **encode-push**: `push` MUST encode the request with a default `JSONEncoder` and decode the body as `SyncPushResponse`.
- **map-unauthorized**: `ADHSyncAPI.Failure.unauthorized` MUST become `SyncTransportError.unauthorized`.
- **map-resync**: `.resyncRequired` MUST become `.resyncRequired`.
- **map-http**: `.http(code)` MUST become `.invalidResponse(statusCode: code)`.
- **map-transport**: `.transport(message)` MUST become `.transport(message)`.
- **map-coding**: A decode or encode failure, and any other error, MUST become `.transport` carrying the error's description.
- **cancellation-passes**: A `CancellationError` MUST be rethrown unchanged, so a stopped engine is not counted as a failed cycle.
- **injectable-calls**: An internal initializer MUST accept the two calls as closures, so tests drive the transport without a network.

