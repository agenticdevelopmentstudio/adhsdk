
**Decision**: Components are clamped in the public initializer, and `hexString` clamps again.
**Rationale**: The source comment states a malformed import or NaN from color math must never store an out-of-range or non-finite channel; the second clamp keeps conversion to a byte from trapping.
**Approved**: pending

**Decision**: The type encodes as one `"#RRGGBBAA"` string rather than a keyed object.
**Rationale**: The source comment says this lets settings round-trip cleanly through `UserDefaults`. The cost is 8-bit quantization.
**Approved**: pending

**Decision**: The hex parser requires all eight digits and accepts the leading `#` optionally.
**Rationale**: Alpha is always present, which keeps the stored format unambiguous; the type offers no 6-digit input form. The integer parse also admits a leading sign, which the doc comment does not mention and the source does not reject.
**Approved**: pending

**Decision**: Parse failure is a nil return from the failable initializer; the `Decodable` path converts it to a thrown `DecodingError`.
**Rationale**: Callers parsing user text can branch on nil, while decoders get the standard error type. The decoded error message is English and not localized.
**Approved**: pending

