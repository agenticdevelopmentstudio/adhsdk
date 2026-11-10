
- **Decision**: The transport chooses between Direct and Daemon by varying
  only `(serverURL, transport)` on an otherwise identical generated
  `Client`, rather than exposing two different client types or APIs.
  **Rationale**: swift-openapi-runtime places the server URL on the `Client`
  itself, not the transport, so `(serverURL, transport)` is already the
  complete seam; keeping `ADHClient.api` a single `Client` type means every
  caller-facing operation works identically regardless of which path was
  chosen.
  **Approved**: pending

- **Decision**: `TransportResolver` only detects whether a daemon is
  already listening; it never starts, installs, or manages the daemon
  process.
  **Rationale**: per the source's own doc comment, Direct is the guaranteed
  fallback, so decoupling detection from process management means the
  client always works even before the daemon (`adhd`) exists or is
  installed — confirmed by `DaemonContract`'s own note that "the real daemon
  does not exist yet."
  **Approved**: pending

- **Decision**: The production probe decides success from the HTTP status
  code alone (`== 200`) and never decodes the response body, even though
  `DaemonContract.HealthStatus` documents the body's wire shape.
  **Rationale**: this keeps the probe's hot path cheap (no JSON parsing) and
  independent of the exact `HealthStatus` payload; `HealthStatus` remains
  the documented contract for the daemon to honor and for any future caller
  that does inspect the body, but `TransportResolver` itself does not need
  to.
  **Approved**: pending

- **Decision**: The Daemon transport builds a dedicated `.ephemeral`
  `URLSession` (no shared cache/cookies, 30s timeout) rather than reusing
  the Direct path's session or `URLSession.shared`.
  **Rationale**: per the factory's doc comment, an ephemeral session "does
  not wait for connectivity since the resolver has already confirmed the
  daemon is up," and avoiding a shared cache/cookie jar keeps loopback
  daemon traffic from interacting with any HTTPS backend session state.
  **Approved**: pending

- **Decision**: Concurrent first-time `resolve()` calls are left able to
  launch duplicate probes (see Edge Cases), and out-of-range `port` values
  are left to crash at a forced URL unwrap rather than being validated.
  **Rationale**: neither is addressed anywhere in
  `TransportResolver.swift`/`DaemonContract.swift`, and neither is exercised
  by `TransportResolverTests.swift`; both are recorded as open questions
  under Edge Cases rather than resolved here, since resolving them would
  mean inventing behavior the source does not define.
  **Approved**: pending

