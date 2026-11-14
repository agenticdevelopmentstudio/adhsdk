
- **Data handled**: The inbound events its caller passes in, which can include owner message text and session titles; it inspects only each event's `coalescingKey`.
- **Storage**: In memory only, in the array held by the struct.
- **Transmission**: None; it performs no network access. The owner later sends a dequeued event's text to the partner process.
- **Retention**: Until `next()` removes an entry or a coalesced event replaces it; nothing survives the value's lifetime.

