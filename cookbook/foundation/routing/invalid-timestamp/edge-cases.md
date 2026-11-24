
- **Null / empty input**: An empty `message` MUST be accepted and kept as is; the type does not validate it.
- **Boundary values**: Not applicable: the type holds one string with no length limit.
- **Malformed input**: Any string, including one with quotes, newlines or non-ASCII text, is stored and returned unchanged; escaping is the consumer's concern (`RouteResponse.error` JSON-encodes it).
- **Concurrent access**: `message` is an immutable stored property of a value type, so concurrent reads are safe and there is no mutation to race.
- **Error states**: Not applicable: constructing the type cannot fail.
- **Offline / disconnected state**: Not applicable: the type performs no network access.
- **Cancellation and timeouts**: Not applicable: construction and reads are synchronous in-memory operations.

