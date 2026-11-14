
**Decision**: Render lowercase hex, two digits per byte, with no separator or prefix.
**Rationale**: The strings are stored in the daemon's database columns and compared as text; one spelling means equal hashes are equal strings.
**Approved**: pending

**Decision**: Put the rendering on `Digest` as one shared property.
**Rationale**: The source calls it "the one place the daemon turns hash bytes into the hex strings it stores", so a second copy cannot drift.
**Approved**: pending

**Decision**: Build the string byte by byte with `String(format: "%02x", ...)` and `joined()`.
**Rationale**: The source gives none; this is recorded as the implementation, and a port need only match the output, not the mechanism.
**Approved**: pending

