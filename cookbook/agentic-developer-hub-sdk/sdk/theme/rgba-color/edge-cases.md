
- **Empty or missing input**: `init?(hexString:)` returns nil for `""` and for `"#"` (length is not 8). MUST.
- **Boundary values**: components exactly 0 and 1 are stored unchanged; a hex byte `FF` becomes exactly 1 and `00` exactly 0. MUST.
- **Non-finite components**: NaN stores 0, positive infinity stores 1, negative infinity stores 0, because the clamp is `min(1, max(0, x))`. MUST.
- **Malformed hex**: wrong length, non-hex characters, repeated `#`, shorthand forms and surrounding whitespace return nil and never throw from the failable initializer. MUST.
- **Sign characters**: `"+FFFFFFF"` and `"-0000000"` parse because the standard-library integer parse accepts a sign; see `hex-sign-leniency`. MUST (to match the source).
- **Precision loss**: a color that is not a multiple of 1/255 changes after a hex round trip, for example 0.5 encodes as `80` (127.5 rounds to 128) and decodes as 128/255. Equality after a round trip is therefore not guaranteed for arbitrary `Double` components. This is a deliberate 8-bit projection. SHOULD be treated as expected by callers.
- **Decode failure**: an unparseable string throws `DecodingError.dataCorruptedError` and the caller decides whether to fall back; the type does not substitute a default. MUST.
- **Concurrent access**: not applicable beyond `Sendable`; all fields are immutable, so concurrent reads cannot race.
- **Offline or disconnected state**: not applicable; the type performs no network or file access.
- **Cancellation and timeouts**: not applicable; every operation is synchronous and bounded.

