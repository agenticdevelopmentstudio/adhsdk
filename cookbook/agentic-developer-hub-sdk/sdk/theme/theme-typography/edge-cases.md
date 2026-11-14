
- **Empty `styles`**: every role resolves to `defaultStyle(_:)`; the empty `ThemeTypography()` reproduces the system-font look (`system-constant`). MUST.
- **Override for one role**: only that role changes; other roles keep their defaults (`explicitStyleWins`). MUST.
- **Partial override**: an override replaces the whole style, so omitted fields take the `FontStyle` initializer defaults rather than the role default. A `code` override that omits `monospaced` is not monospaced. MUST (to match the source); see `style-lookup-whole-entry`.
- **Boundary scale values**: 0.5 and 4 are inside `sizeScaleRange` and pass the clamp unchanged. MUST.
- **Scale outside the range**: the clamp returns the nearest bound; the stored `sizeScale` inside the type is never clamped on its own, so a value set directly on the property or through `init` stays out of range until a caller clamps it. MUST.
- **Zero or negative scale**: `size(_:)` returns 0 or a negative size for a stored scale of 0 or below; only the callers listed in `clamp-callers` prevent this. MUST (to match the source).
- **Non-finite scale**: NaN and both infinities clamp to 1.0, the unscaled size (`clamp-nan`). MUST.
- **Non-finite or non-positive style size**: `FontStyle.size` is unvalidated, so the model carries it as given. The platform bridge decides what to do with it. MUST (to match the source).
- **Imported theme with a bad scale**: repaired by clamping, not refused (`clamp-repair-not-refuse`). MUST.
- **Malformed JSON**: an unknown `weight` string or a missing required key makes decoding throw the decoder's own error; the type does not fall back to a default. MUST.
- **Unknown `styles` key**: kept in the dictionary, never read by `style(_:)`. MAY.
- **Concurrent access**: not applicable beyond `Sendable`; each copy is an independent value, so concurrent reads cannot race.
- **Offline or disconnected state**: not applicable; the types perform no network or file access.
- **Cancellation and timeouts**: not applicable; every operation is synchronous and bounded.

