
- **Empty or missing data** (MUST): empty strings and an empty `hookData` are accepted; the type never rejects its input.
- **Nil versus empty oauth email** (MUST): the two differ in meaning and MUST NOT be conflated by a port.
- **Boundary values** (not applicable): no field has a range or length limit in this type.
- **Non-JSON values in `hookData`** (SHOULD): a port SHOULD accept them here and leave detection to encoding, where `envelopeJSON()` throws `EnvelopeEncodingError.notSerializable`.
- **Concurrent access** (MUST): safe only while nothing mutates a reference value held inside `hookData` or `context`; the type itself has no mutable state.
- **Error states, offline or disconnected** (not applicable): the type does no I/O and raises no errors.

