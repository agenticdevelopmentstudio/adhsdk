
- **Null / empty input**: `dayAfter("")` builds the text `T00:00:00Z`, which is shorter than the 19 bytes the fast path needs, so it falls to `TimestampParsing.parse`, which declines it; the call MUST return the empty string unchanged.
- **Boundary values**: Month ends, year ends and leap days MUST roll over to the next civil day; a non-leap 28 February MUST be followed by 1 March.
- **Malformed input**: A string that does not parse as `<day>T00:00:00Z` MUST come back unchanged rather than produce a wrong day; a caller cannot distinguish this from success except by comparing input to output.
- **Concurrent access**: Both functions are stateless and the only stored value is an immutable private `TimeZone`, so concurrent calls need no coordination.
- **Error states**: Nothing throws or logs; the only error signal is the unchanged return of `dayAfter(_:)`.
- **Offline / disconnected state**: Not applicable: the type has no network or file access.
- **Cancellation**: Not applicable: both functions are synchronous and return immediately.

