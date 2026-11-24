
- **Null and empty input**: An empty `Data` passed to `decode` MUST return `nil`. An empty `workUnits` array is valid and decodes as an empty array. A null `nextActivation` or `lastMessage` decodes as `nil`.
- **Malformed input**: Any JSON that does not match the schema, including a missing required key, a wrong type, or an unknown `state` value, MUST yield `nil` from `decode`; the decoder never returns a partially filled report.
- **Date format**: A `nextActivation` that is not an ISO-8601 date string (for example a numeric timestamp; whether fractional seconds parse is up to the OS release's `.iso8601` strategy, and macOS 26 accepts them) fails decoding of the whole report, so `decode` returns `nil`.
- **Boundary values**: `uptimeSeconds` and `consecutiveFailures` are not range-checked; negative or very large values pass through unchanged.
- **Deep or wide trees**: `first(ofKind:)` recurses without a depth limit, and a tree is bounded only by what the daemon sends.
- **Unreachable server**: A refused connection, DNS failure or lost connectivity MUST make the probe closure return `nil`; the closure does not distinguish those causes from one another or from a non-200 status.
- **Timeout**: A request that receives no data for `timeout` seconds MUST make the closure return `nil`. A server that sends bytes slowly but steadily never trips the timeout, so the closure can run longer than `timeout` seconds.
- **Base URL with a trailing slash or a path**: `http://h:9000/` MUST probe `http://h:9000/health`, and `http://h/api` MUST probe `http://h/api/health`.
- **Non-200 status**: Any status other than 200, including other 2xx codes and redirects the session does not follow to a 200, MUST return `nil`; the body of such a response is discarded.
- **Cancellation**: The closure has no explicit cancellation handling; its `try?` turns a cancelled request into `nil`, so cancellation is indistinguishable from failure.
- **Concurrent access**: The report types are immutable value types marked `Sendable`, so they are safe to share. Concurrent invocations of one probe closure each issue an independent request and share the one ephemeral session; the probe adds no serialisation, and none is needed because the closure holds no mutable state.
- **Offline state**: There is no offline mode; losing connectivity mid-request is the same as an unreachable server and returns `nil`.
- **Daemon up but different schema**: A 200 response whose body is in the daemon's own shape returns the body from the probe, and `decode` then returns `nil`; a caller can treat that combination as reachable but opaque.

