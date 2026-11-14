
**Decision**: Components are clamped in the public initializer, and `hexString` clamps again.
**Rationale**: A malformed source, such as an imported `.itermcolors` with an out-of-gamut or rounding-artifact value, or a NaN from color math, must never store an out-of-range or non-finite channel that later corrupts rendering or traps on conversion; the second clamp keeps conversion to a byte from trapping. The source comment on the component initializer gives the same reason.
**Approved**: pending

**Decision**: The type encodes as one `"#RRGGBBAA"` string rather than a keyed object.
**Rationale**: The source comment says this lets settings round-trip cleanly through `UserDefaults`. The cost is 8-bit quantization.
**Approved**: pending

**Decision**: The hex parser requires all eight digits and accepts the leading `#` optionally.
**Rationale**: Alpha is always present, which keeps the stored format unambiguous; the type offers no 6-digit input form. The integer parse also admits a leading sign, which the doc comment does not mention and the source does not reject.
**Approved**: pending

**Decision**: Whether hex parsing should accept a leading sign (`"+FFFFFFF"`, `"-0000000"`) is undecided; the source accepts it only because `UInt32(_:radix:)` does, and ports may accept or reject it.
**Rationale**: Nobody chose this behavior and the doc comment documents `#RRGGBBAA` only. Requiring ports to copy a parsing quirk would lock it into the contract, so `hex-sign-leniency` is a MAY until a person decides whether to reject signs in the source or approve the leniency.
**Approved**: pending

**Decision**: Parse failure is a nil return from the failable initializer; the `Decodable` path converts it to a thrown `DecodingError`.
**Rationale**: Callers parsing user text can branch on nil, while decoders get the standard error type. The decoded error message is English and not localized.
**Approved**: pending

