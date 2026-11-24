
**Decision**: The report types mirror DaemonKit's wire format in this file rather than importing DaemonKit.
**Rationale**: A menu bar app or other client reads a daemon's health with Foundation only, the same arrangement [adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6) uses for stenographerd, and the JSON keys alone are the contract between the two.
**Approved**: pending

**Decision**: The Swift names (`DaemonHealthReport`, `DaemonStrategyReport`, `DaemonWorkUnitReport`) differ from DaemonKit's `HealthStatus`, `StrategySnapshot` and `WorkUnitSnapshot`.
**Rationale**: A file importing both modules never meets an ambiguous type name.
**Approved**: pending

**Decision**: `decode` returns `nil` for any undecodable body and discards the error.
**Rationale**: A daemon may answer `/health` in its own shape and still be up, so a mismatch is a normal outcome, not an error to surface. The cost is that a caller cannot tell which key failed.
**Approved**: pending

**Decision**: `status` and `kind` are Strings while the work-unit `State` is a closed enum.
**Rationale**: A daemon may report its own `kind` value, so a consumer treats unknown kinds as opaque. The closed `State` enum has no fallback, so a daemon reporting a fifth state makes the whole report fail to decode; this is the actual behavior and a port must reproduce it.
**Approved**: pending

**Decision**: `DaemonStrategyReport` has a hand-written `init(from:)` that makes `children` optional on the wire, while the other two structs use synthesized decoding.
**Rationale**: A leaf strategy need not send `children`, because it is empty for a leaf. For the work unit, the initializer defaults are not used when decoding, so its non-optional fields are required keys.
**Approved**: pending

**Decision**: The probe collapses every failure (non-200, transport error, timeout, bad URL, cancellation) into `nil`.
**Rationale**: A menu bar app polling for reachability needs a binary answer. The probe returns `nil` for any other status, a transport error or a timeout. It also does not retry, because the caller owns the polling cadence.
**Approved**: pending

**Decision**: The probe takes a 2 second default timeout and uses an ephemeral session created once per probe.
**Rationale**: A poll must not hang a menu bar refresh, and an ephemeral session keeps cookies, caches and credentials off disk. The session is built when the probe is built, not per call, so the closure reuses it.
**Approved**: pending

