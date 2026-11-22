
- **Null and empty input**: A tolerant key present with JSON `null` MUST decode as its default, because the hand-written decoders read present-or-nil and then default. An empty `quotaRows`, `weekRows` or `hoursRows` list MUST decode. `oneSectionPerAccount([])` MUST return `[]`. A header map with no usage headers MUST yield a reading whose `errorText` is set (vector 004).
- **Version skew, newer daemon and older app**: An older app decoding a newer payload ignores unknown keys. A newly added key MUST stay optional on decode, which is why `hudQuota` is a new key rather than a reshaped `hud` and why `isCurrent` is still encoded (see Design Decisions).
- **Version skew, older daemon and newer app**: A payload missing `account_email`, the spend pair, `hours_rows`, `hud_quota`, `account_sections`, `oauth_email`, the per-metric fields, or the quota-row optionals MUST decode with defaults. A payload missing a required key fails the whole decode, including the enclosing `UsageRowsDTO`.
- **Nested strictness**: A key missing inside a nested type's own required set propagates out through the enclosing tolerant decoder. A present `hud_quota` without `account_email`, or an account section without `is_current`, MUST fail the whole `UsageRowsDTO` decode.
- **Boundary values**: Percentages are not clamped anywhere: a reading of `1.05` is 105, `spendPct` MAY exceed 100, and negative utilizations pass through. A reset at exactly 1e12 is not divided; only values above it are. A negative reset is kept as a negative Int.
- **Malformed headers**: A non-numeric utilization or reset MUST yield nil for that field. A non-finite utilization is the open question on `reading-pct-non-finite`.
- **Whitespace in addresses**: `oneSectionPerAccount` trims spaces and tabs only; an address with a trailing newline is a different key from the same address without one.
- **Unknown credential kinds**: A section or reading whose `credentialKind` this build does not know MUST still decode; in `oneSectionPerAccount` it counts as a login.
- **Concurrent access**: The values are immutable and `Sendable`, so they MAY be shared across threads and actors; `oneSectionPerAccount` is a pure function.
- **Error states**: Decoding errors are the standard decoding errors and are thrown, not swallowed. A failed probe is data, not an error: `errorText` is set on the reading or section.
- **Offline or disconnected state**: Not applicable: the types perform no I/O; the clients that fetch them and the daemon that probes Anthropic own connectivity.

