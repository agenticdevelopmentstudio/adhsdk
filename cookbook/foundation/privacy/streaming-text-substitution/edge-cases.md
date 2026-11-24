
- **Null / empty input**: `feed` with an empty sequence rescans the held bytes and emits any part that can no longer become a match, keeping the rest held; with nothing held it returns empty (MUST). With no pairs the input is returned unchanged (MUST).
- **Boundary values**: A pattern split at every byte position across reads is still replaced once. The held run is at most the longest pattern length minus one (MUST). A one-byte pattern is replaced immediately and never held unless a longer pattern begins with the same byte, in which case that byte is held like any other prefix.
- **Concurrent access**: A value type with no synchronisation. A port MUST confine an instance to one caller at a time.
- **Error states**: Nothing throws; invalid UTF-8 is passed through untouched (MUST).
- **Held bytes at stream end**: Bytes still held when no more input will come are not released by the type; the owner MUST call `flush()` or the final partial match stays held; An owner that flushes only one side leaves the other side's partial match held until the next input or an explicit flush. `flush` passes a partial prefix through unchanged.
- **Non-ASCII patterns**: Words with non-ASCII letters match only in exact case, unlike the filter's `String` matching which folds case for every script; this is deliberate (see Design Decisions).
- **Partial prefix then divergence**: Held `mik` followed by `x` is rescanned as `mikx`: the first-byte rule is applied again from the start, and the bytes come out as `mikx` unless a different pattern starts inside them.
- **Overlapping patterns**: With `mike` and `ike`, `mike` is consumed whole before `ike` is looked at; the replaced text is not rescanned.
- **Offline / disconnected state**: Not applicable: the type performs no network access.
- **Cancellation**: Not applicable: each call completes synchronously and there is no cancel call.

