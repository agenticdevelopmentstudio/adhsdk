
- **Unvalidated ids**: `save` and `load` do not check that an id looks like a bundle identifier; any string, including an empty one, is stored and returned, and an empty string survives de-duplication as one entry.
- **Never-set keys**: Each key a caller never wrote MUST read as its default (disabled, no ids, 90 days, `.unknown` accessibility); `setting(for:)` returning nil is not an error.
- **Hand-edited retention**: A value below 7 or above 3650 MUST be clamped on read and on write; an unparseable value MUST become 90.
- **Garbage id lists**: An absent, empty or non-array value (including an array of non-strings) MUST read as no ids; the source discards it without an error or a log line, and the doc comment on `decodeIds` declares that behavior.
- **Duplicate and unsorted ids**: Ids MUST come back sorted ascending by string order and unique, whatever order they were stored in.
- **Empty id list**: An empty list MUST be stored as `[]` and read back as no ids.
- **Store throws on read or write**: The error MUST reach the caller unchanged; a failed `save` MUST leave the four keys at their previous values when the store's `transaction` honors its atomic contract.
- **Missing signer record**: A `.granted` answer stored before signatures were recorded (no `activity_ax_signer` key) MUST read as `.unknown` through `trustedAccessibility`.
- **Concurrent access**: `WorkTrackingPrefs` holds no state and its functions are not isolated. `WorkTrackingSettingsStore` itself carries no `Sendable` requirement, but the host store reaches `ActivityPersistence`, which is `AnyObject, Sendable`, so one instance can be shared; the source states no ordering rule, so ordering of reads against `save` is the host's. Writes are atomic through `transaction`; reads are not grouped (see the open question on `load-key-reads-separate`).
- **Cancellation, timeouts, offline**: Not applicable — every call is synchronous, and the code does no networking, so there is nothing to cancel or to time out.

