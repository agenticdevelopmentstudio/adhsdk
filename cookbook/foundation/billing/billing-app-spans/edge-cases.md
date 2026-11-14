
- Null and empty input: there are no optionals; every absent value is the empty string (`workingPath`, `repoRoot`, `endedAt`, `idleUntil`), and consumers MUST treat the empty string as the documented sentinel, not as a timestamp.
- Boundary values: nothing is clamped; an `endedAt` earlier than `startedAt`, or an `idleUntil` earlier than `idleFrom`, is stored as given.
- Malformed input: a timestamp that does not parse is stored unchanged; derivation yields no runs for it (`testMalformedTimestampIsEmpty`).
- Concurrent access: the types are `Sendable` immutable values, so concurrent reads are safe and there is nothing to serialise.
- Error states: the types raise no error and perform no I/O.
- Offline or disconnected state: not applicable; the types touch no network.
- An `id` that already begins with `app:` yields a `sessionId` with the prefix doubled, because the prefix is added unconditionally.

