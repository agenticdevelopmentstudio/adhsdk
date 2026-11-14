
- **Null / empty input**: `dayAfter("")` MUST return the empty string unchanged.
- **Boundary values**: Month ends, year ends and leap days MUST roll over to the next civil day; a non-leap 28 February MUST be followed by 1 March.
- **Out-of-range fields**: `dayAfter("2026-13-01")` MUST return the input unchanged. Other impossible dates (`2026-02-30`) and trailing characters (`2026-06-19x`) are not specified here, because the shared parser's handling of them is not covered by a test.
- **Malformed input**: A string that does not parse as `<day>T00:00:00Z` MUST come back unchanged rather than produce a wrong day; a caller cannot distinguish this from success except by comparing input to output.
- **Concurrent access**: Both functions are stateless and the only stored value is an immutable private `TimeZone`, so concurrent calls need no coordination.
- **Error states**: Nothing throws or logs; the only error signal is the unchanged return of `dayAfter(_:)`.
- **Offline / disconnected state**: Not applicable: the type has no network or file access.
- **Cancellation**: Not applicable: both functions are synchronous and return immediately.

