
**Decision**: A dedicated `InvalidTimestamp` struct is used as the `Result` failure instead of `String`.
**Rationale**: The source comment states that `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process throwable, which it calls a cure worse than the bare `String` it replaces.
**Approved**: pending

**Decision**: The type carries only a `message` and conforms to `CustomStringConvertible` with `description` equal to `message`.
**Rationale**: `RouteRequest` reports a rejected bound as a 400 with one human-readable reason (its doc comment says this one is a 400, not a silent clamp); printing the value yields the message itself with no wrapper text.
**Approved**: pending

