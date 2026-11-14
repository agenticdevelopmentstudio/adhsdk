
- **Encoding failure**: see `#requirements/caller-skips-on-encode-failure`; a failed encode is a logged drop, not a crash.
- **Nil session id**: `broadcast` with `sessionId` of `nil` MUST be accepted; a transport that filters by session decides who receives it.
- **Empty payload**: The protocol does not reject an empty `Data` payload; no source rule covers it, and the sink publishes what it is given.
- **No subscribers or transport down**: A sink MAY drop or ignore the call; the protocol has no return value or throw, so ingestion proceeds regardless.
- **Slash in a session id**: The encoder sets only `sortedKeys`, so Foundation's default escaping of `/` as `\/` applies to any string value; `encode-slash-escaping` makes that part of the contract for every port.
- **Snake-case conversion of keys**: `convertToSnakeCase` applies to every key of the encoded value, including nested objects, and not only top-level ones.
- **Status payload keys**: `StatusPayload` declares its own coding keys `session_id` and `status`, which are already snake_case, so the conversion leaves them unchanged.
- **Concurrent access**: The protocol is `Sendable`, so calls MAY arrive from several queues at once; whether a sink serializes them is the conforming type's job. The encoding type is stateless and safe to call concurrently. `RecordingSink` guards its arrays with an `NSLock`.
- **Boundary values, offline, cancellation**: Not applicable to the protocol: it holds no numeric limits, does no I/O of its own and has no asynchronous work to cancel; network behavior belongs to a conforming transport.

