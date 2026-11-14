
- **Null and empty input**: A nil `llmConfirmation` is valid (MUST encode with the key omitted). Empty strings are accepted by every String field at the DTO level; empty id, name, kind, inject text and act keyword are refused at save by the daemon's script store, not here. An empty group encodes and decodes without error (MUST).
- **Boundary values**: Predicate nesting has no depth limit in the type. `version` is any Int. A condition's `value` is always a String, including for numeric fields; whether it parses as a finite number is checked at save by the daemon.
- **Concurrent access**: The types are `Sendable` values with no shared mutable state, so they MAY be passed across threads and actors freely.
- **Error states**: Decoding failures are the standard `DecodingError` values: data-corrupted for an unknown `type` discriminator, key-not-found for a missing key, and a data-corrupted error for an unknown field or operator raw value. The DTO does not catch them.
- **Offline or disconnected state**: Not applicable: the types perform no I/O.
- **Forward compatibility**: A script containing a future action type or predicate type fails to decode as a whole under this version (MUST, per the unknown-type requirements); an older client cannot read a newer daemon's list of scripts that includes one.
- **Mutable value copies**: Fields are `var`, so an editor copies a script, edits the copy and sends it back; the type does not track dirtiness.

