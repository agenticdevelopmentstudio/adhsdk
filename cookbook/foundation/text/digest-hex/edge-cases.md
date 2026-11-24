
- **Null / empty input**: Hashing empty data still gives a full-length digest (SHA-256 gives 32 bytes), which renders as 64 characters (MUST). A digest with no bytes would render as the empty string; no CryptoKit digest has zero bytes, so this case is not reachable and no vector covers it.
- **Boundary values**: A byte of 0x00 renders as `00` and 0xFF as `ff` (MUST); a byte below 0x10 keeps its leading zero (MUST).
- **Concurrent access**: The property reads an immutable value digest and keeps no shared state, so calls from any thread are independent.
- **Error states**: Not applicable: the property cannot fail and has no error path.
- **Offline / disconnected state**: Not applicable: the property performs no I/O.
- **Performance**: Each byte goes through `String(format:)` and the pieces are joined, so the cost is per byte; no speed claim is made, and hashes rendered are digest-sized (16 bytes for MD5 to 64 for SHA-512).

