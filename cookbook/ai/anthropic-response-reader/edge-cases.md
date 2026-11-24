
- **Empty body**: `finish` with no `consume` MUST leave every field nil in both modes (MUST).
- **No `finish` call in non-streaming mode**: nothing is parsed, so every field stays nil (MUST); only streaming mode produces values from `consume` alone.
- **Non-UTF-8 line**: an invalid line is skipped without affecting later lines (MUST).
- **Non-integer usage value** (a string, a fractional number or a null; the source reads integers with `as? Int`): the field is left as it was (MUST).
- **Missing keys**: a `message_start` with no `usage` or no `model` changes nothing for the missing part (MUST).
- **Boundary**: a JSON body of exactly 4 MiB is buffered and parsed; one byte more overflows (MUST). In streaming mode the cap applies only to a partial line left after processing complete lines, so a large body made of many lines is fine (MUST).
- **Overflow is final**: once a non-streaming body has overflowed, later chunks are ignored and `finish` sets nothing (MUST).
- **Error responses**: an Anthropic error body (an object with `type` "error") parses as a JSON object with no `model`, `stop_reason` or `usage`, so every field stays nil; the reader has no error field (MUST).
- **Mid-stream `error` event**: it has type `error` and is ignored; fields read before it are kept (MUST).
- **Concurrent access**: the class is not thread-safe by its own documentation, and Swift's compiler keeps a non-`Sendable` class inside one isolation domain; callers confine each instance (MUST).
- **Offline or disconnected state**: Not applicable — the reader only sees bytes the caller passes; a truncated stream simply yields whatever was read before the cut.
- **Cancellation and timeouts**: Not applicable — every operation is synchronous.

