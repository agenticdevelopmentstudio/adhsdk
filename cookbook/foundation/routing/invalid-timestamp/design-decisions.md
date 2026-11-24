
**Decision**: A dedicated `InvalidTimestamp` struct is used as the `Result` failure instead of `String`.
**Rationale**: The doc comment on `InvalidTimestamp` in `InvalidTimestamp.swift` states that `Result`'s failure must be an `Error`, and a retroactive `extension String: Error` would make every string in the process throwable, which it calls a cure worse than the bare `String` it replaces.
**Approved**: pending

**Decision**: The type carries only a `message` and conforms to `CustomStringConvertible` with `description` equal to `message`.
**Rationale**: A malformed `since` gets a 400 with a single human-readable reason, instead of being clamped silently; the doc comment on `validatedTimestamp` in `RouteRequest.swift` explains that a malformed bound would otherwise quietly select the wrong rows and return 200. Printing the value yields the message itself with no wrapper text.
**Approved**: pending

