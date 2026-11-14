
- **Empty id lists** (MUST): `normalized()` on empty `addedBundleIds` and `removedBundleIds` returns them empty.
- **Retention at the bounds** (MUST): 7 and 3650 are returned unchanged by `normalized()`. Values below 7 become 7 and values above 3650 become 3650. A negative value becomes 7.
- **An id in both lists** (MUST): `normalized()` keeps it in both. The source does not reconcile `addedBundleIds` against `removedBundleIds`. The layer that applies them owns that rule.
- **Empty or non-prefixed session id** (MUST): `spanId(sessionId:)` returns nil for an empty string and for any id without the `app:` prefix. For exactly `app:` it returns the empty string.
- **Span id that contains the prefix** (MUST): `spanId(sessionId: "app:app:X")` returns `app:X`, because only the first prefix is dropped.
- **Concurrent access**: not a concern in the file. The types are immutable-by-copy values, and the only mutation is on a caller's own variable.
- **Error states**: not applicable to the models. Nothing throws, and the failure signal for a list read is `WorkTrackingWire.readFailedRow`.
- **Offline or disconnected state**: not applicable to the models. The transport that carries them is a sibling type, not this file.
- **Malformed input** (SHOULD): the file does not parse text itself. Decoding a `WorkTrackingStatus` with an unknown `accessibility` string fails in the caller's `Decoder`, as the raw-value enum gives it no fallback.

