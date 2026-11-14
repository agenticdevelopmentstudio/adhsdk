
- **Empty `endedAt` with a non-empty `lastSeenAt`**: The span MUST be open; a heartbeat does not close a span, because `isOpen` reads only `endedAt`.
- **Whitespace `endedAt`**: A value of a single space MUST count as closed, because `isOpen` tests `isEmpty` and does not trim.
- **Malformed timestamps**: A `startedAt`, `endedAt` or `lastSeenAt` that is not ISO-8601 MUST be stored and encoded unchanged; the type does not parse timestamps, so no error is raised.
- **Empty `bundleId`, `appName` or `tz`**: The initializer MUST accept them; callers own that precondition, since no validation exists.
- **Duplicate ids**: Two spans with the same `id` MUST be representable; uniqueness is not enforced in this type. The `ActivityPersistence` contract owns the rule: its doc comment says opening an id that already exists throws, and `InMemoryActivityStore` throws `duplicateSpanId`.
- **Missing keys on decode**: Decoding JSON that lacks any property MUST fail with the standard `DecodingError`, because synthesized `Codable` has no default for absent keys, including the ones the initializer defaults.
- **Ended before started**: `endedAt` earlier than `startedAt` MUST be accepted without error; ordering is not checked.
- **Concurrent access**: The type is a `Sendable` value type; each thread works on its own copy, so there is no shared mutable state and no ordering rule.
- **Error states, offline and cancellation**: Not applicable — the type performs no I/O, networking, or async work and raises no errors of its own.

