
- **Null and empty input**: Every string field MAY be empty (MUST be accepted); `model` and `detail` are empty for a rule finding with no extra context. JSON `null` for any of the twelve keys is not accepted: decoding MUST fail, as for a missing key.
- **Boundary values**: `severity` of 0 and of any Int is accepted with no clamp (MUST); the 0 to 100 range is documentation, not enforcement. `id` is the daemon's autoincrement integer.
- **Concurrent access**: The value is immutable and `Sendable`, so it MAY be shared across threads and actors without synchronization. Concurrent writes to the underlying finding (a double-submit of act, a dismiss racing an act) are resolved by the daemon, which guards the `acted` update on `pending`; the DTO takes no part.
- **Error states**: A body that fails decoding is dropped by the client: the HTTP client reads a list that does not decode as an unreachable daemon (nil), and reads a single act reply that does not decode as no finding, falling back to status `acted` (MUST, per the client). The DTO raises the decoding error; it never swallows it.
- **Offline or disconnected state**: Not applicable: the type performs no I/O. The client that fetches it returns nil when the daemon is unreachable.
- **Unknown values**: An unknown `status` or `source` spelling from a newer daemon decodes without error (MUST); a consumer that switches on `status` needs its own default branch.
- **Stale findings**: A `stale` finding is still returned when no status filter is sent; filtering is the daemon's job, not the type's.

