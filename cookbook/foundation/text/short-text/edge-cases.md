
- **Null / empty input**: An empty string is returned unchanged for any `limit` of 0 or more (MUST); with a negative `limit` the comparison `count > limit` is true and the cut traps.
- **Boundary values**: A text of exactly `limit` characters is returned whole; one more character is cut (MUST). A `limit` of 3 on a longer text yields only the ellipsis (MUST).
- **Limit below 3**: A `limit` of 0, 1 or 2 with a text longer than the limit makes `prefix(limit - 3)` receive a negative count and trap; the doc comment declares "`limit` must be at least 3" and the method does not check it, so the contract belongs to the caller.
- **Multi-scalar characters**: Combining marks, emoji sequences and CRLF count as one `Character` each and are never split (MUST); the result can therefore have more bytes or UTF-16 units than `limit - 2`.
- **Cut length versus limit**: The result of a cut is `limit - 2` characters, two under the limit, not `limit` (MUST).
- **Concurrent access**: Not applicable: the method is a pure function over an immutable value and shares no state.
- **Error states**: There is no error return; the only failure is the trap for a limit under 3 on a longer text.
- **Offline / disconnected state**: Not applicable: the method performs no I/O.

