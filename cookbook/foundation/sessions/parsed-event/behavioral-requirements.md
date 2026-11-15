
### Fields

- **event-type**: `eventType` MUST hold the event name string exactly as given; the type does not check it against `HookEventType`, so an unmodelled type is carried.
- **timestamp**: `timestamp` MUST hold the timestamp string exactly as given, with no parsing or format check.
- **hook-data**: `hookData` MUST hold the hook payload dictionary as given; it is not copied deeply or inspected.
- **context**: `context` MUST hold the optional context dictionary as given; nil means no context (present in v5+ drops, absent in legacy v4 drops and hand-written fixtures).
- **account-email**: `accountEmail` MUST hold the account email string as given; it is empty when no token could be fingerprinted.
- **oauth-account-email**: `oauthAccountEmail` MUST hold the optional oauth login email as given, and the initializer MUST default it to nil.
- **oauth-nil-versus-empty**: nil MUST mean "this envelope predates the field" (a drop file written by an older build), the only case where resolving the login at write time is still the best answer; the empty string MUST mean "resolved at capture, and there was no oauth login", a real answer and not a missing one.

### Construction

- **initializer**: The public initializer MUST take `eventType`, `timestamp`, `hookData`, `context` and `accountEmail` with no defaults, and `oauthAccountEmail` defaulting to nil.
- **no-validation**: The initializer MUST NOT validate or normalise any argument; an empty `eventType`, an empty `timestamp` or a `hookData` with no `session_id` is accepted, and the later parse step decides what such an event is.
- **immutable-fields**: Every field MUST be a `let`, so an instance cannot be changed after construction.

### Concurrency

- **unchecked-sendable**: The type MUST be `@unchecked Sendable` on the stated invariant that its dictionaries are constructed once and never mutated; the compiler does not enforce that the `Any` values inside are immutable, so a caller MUST NOT put a mutable reference object into `hookData` or `context` and change it later.
- **no-side-effects**: Constructing or reading a `ParsedEvent` MUST NOT perform I/O, logging or notification.

### Related behavior in the same module

- **session-id-accessor**: `ParsedEvent.sessionId` is defined by the envelope-encoding spec (Parsed Event Envelope ([adhsdk.ingredient.foundation.sessions.parsed-event-envelope](cookbook:7dfeb441-3681-45d3-a11b-049294168607))); this type adds no accessor of its own.
- **no-equatable**: The type MUST NOT conform to `Equatable` or `Codable`; tests compare fields one by one, and the serialized form is the envelope.

