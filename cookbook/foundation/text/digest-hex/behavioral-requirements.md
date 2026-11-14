
- **extension-scope**: The component MUST be a public computed property `hexString` of type `String` on the `Digest` protocol, available to every conforming digest type.
- **lowercase**: Every hexadecimal letter in the result MUST be lowercase (`a` to `f`).
- **two-digits-per-byte**: Each byte MUST render as exactly two hexadecimal digits, with a leading zero for a byte below 0x10, so the result length is twice the digest's byte count.
- **byte-order**: The digits MUST appear in the digest's iteration order, first byte first, with no separator, prefix or suffix.
- **pure**: The property MUST have no side effect and MUST return the same string each time for the same digest value.
- **no-failure**: The property MUST NOT throw or return an optional; it cannot fail.
- **dependencies**: The component MUST depend only on CryptoKit and Foundation.

