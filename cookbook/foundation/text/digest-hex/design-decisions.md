
**Decision**: Render lowercase hex, two digits per byte, with no separator or prefix.
**Rationale**: Stored hashes are compared as text, so one spelling means equal hashes are equal strings.
**Approved**: pending

**Decision**: Put the rendering on `Digest` as one shared property.
**Rationale**: With one rendering, callers that store a digest as text should take it from this property, so a second copy of the spelling cannot drift. That constrains callers, so each consuming recipe states it as its own integration requirement.
**Approved**: pending

**Decision**: Build the string byte by byte with `String(format: "%02x", ...)` and `joined()`.
**Rationale**: It is the simplest correct rendering, and digests are small (16 to 64 bytes), so the per-byte cost does not matter. A port need only match the output, not the mechanism.
**Approved**: pending

