
- **Null / empty input**: `next()` on an empty queue returns `nil` (MUST). An event with a nil `coalescingKey` never matches anything and is always appended (MUST). An owner message with empty text is queued like any other.
- **Boundary values**: One queued entry is both first and last; `next()` empties the queue and `count` returns to 0. There is no upper bound on `count` (MUST NOT drop).
- **Concurrent access**: The queue is a value with no internal synchronisation; the single owner mutates it on the main actor, so ordering is the owner's call order. A port MUST serialise access the same way.
- **Error states**: No operation can fail; there is nothing to raise or return (MUST NOT throw).
- **Offline / disconnected state**: Not applicable: the queue performs no network access; the owner keeps work across a process restart only by re-queuing the interrupted turn with `enqueueFirst`.
- **Cancellation**: Not applicable: every operation completes synchronously and there is no cancel call; the only removals are `next()` and in-place replacement.
- **Duplicate keys from front insertion**: `enqueueFirst` can leave two entries with equal keys; a later `enqueue` with that key replaces the nearest-front one only (MUST).
- **Lossy replacement**: A coalesced event discards the older payload entirely (for example the earlier tick summary); this is the documented contract (MUST).

