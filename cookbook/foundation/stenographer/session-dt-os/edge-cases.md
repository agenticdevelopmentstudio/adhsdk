
- **Null and empty input**: Every String field MAY be empty, and every optional health field MAY be absent or `null`. A missing required session or event key MUST fail the whole decode.
- **Boundary values**: `pid`, `eventCount`, `id` and the health Ints take any Int, including zero and negative values; nothing is clamped. `uptime` is a Double.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY be shared across threads and actors.
- **Error states**: Decoding errors are the standard `DecodingError`s and are thrown, not swallowed. The HTTP client reads a body that does not decode as nil (for example `health()` returns nil and the detail call returns nil).
- **Offline or disconnected state**: Not applicable: the types perform no I/O; the client that fetches them returns nil when the daemon is unreachable.
- **Version skew**: A payload from an older daemon that predates the later-added session keys MUST decode, per session-optional-keys. An old client decoding a newer daemon's payload ignores unknown keys; for an older daemon missing a required key, decoding fails.
- **Casing trap**: A port that spells the two memory properties with an all-caps `MB` suffix reads nil silently from a from-snake-case decoder; health-mb-casing forbids that spelling.
- **Encoding is not lenient**: A client encoding a session always writes every key, so a payload encoded by this type decodes under the strict and the tolerant readers alike.

