
### TransportKind & APITransport

- **transport-kind-cases**: `TransportKind` MUST be a `String`-backed,
  `Sendable` enum with exactly two cases, `direct` and `daemon`, whose raw
  values equal their case names (`"direct"`/`"daemon"`).
- **api-transport-shape**: `APITransport` MUST be a `Sendable` struct
  exposing exactly three public, immutable fields — `kind: TransportKind`,
  `serverURL: URL`, `transport: any ClientTransport` — constructible via the
  public `init(kind:serverURL:transport:)`.
- **direct-factory**: `APITransport.direct(serverURL:transport:)` MUST tag
  the result `kind: .direct`, MUST default `serverURL` to
  `DaemonContract.backendURL`, and MUST default `transport` to a plain
  `URLSessionTransport()`.
- **daemon-factory**: `APITransport.daemon(port:transport:)` MUST tag the
  result `kind: .daemon`, MUST default `port` to `DaemonContract.port`, MUST
  set `serverURL` to `DaemonContract.daemonURL(port:)`, and MUST default
  `transport` to a fresh value from `makeDaemonURLSessionTransport()`
  whenever the caller passes `transport: nil` (its default).
- **daemon-session-is-ephemeral**: The `URLSessionTransport` that
  `makeDaemonURLSessionTransport()` builds MUST use an `.ephemeral`
  `URLSessionConfiguration` (no shared cache or cookies), MUST set
  `waitsForConnectivity = false`, and MUST set
  `timeoutIntervalForRequest = 30` seconds.
- **transport-injectable-for-tests**: Both `direct(serverURL:transport:)`
  and `daemon(port:transport:)` MAY be called with a caller-supplied
  `ClientTransport` in place of the production one, so a test MAY substitute
  a mock transport without changing which `serverURL`/`kind` the factory
  selects.
- **transport-is-the-sole-variation-point**: For a fixed
  `(serverURL, transport)` pair, the generated `Client` an `APITransport`
  value feeds MUST be identical in shape regardless of `kind` — Direct and
  Daemon MUST differ only in which `(serverURL, transport)` pair is supplied,
  never in the request/response types available through it.

### DaemonContract

- **backend-url-constant**: `DaemonContract.backendURL` MUST be a fixed,
  hardcoded `https` production backend base URL — declared as a
  `static let`, never computed or overridable at runtime — and is the
  `Direct` transport's target.
- **daemon-port-constant**: `DaemonContract.port` MUST be the fixed value
  `22850`.
- **daemon-url-construction**: `DaemonContract.daemonURL(port:)` MUST
  construct `http://127.0.0.1:<port>` for the given `port`, defaulting
  `port` to `DaemonContract.port` when omitted.
- **health-path-constant**: `DaemonContract.healthPath` MUST be the literal
  string `/health`.
- **health-url-construction**: `DaemonContract.healthURL(port:)` MUST equal
  `daemonURL(port:)` with the health path's leading `/` stripped and appended
  as a path component — i.e. `http://127.0.0.1:<port>/health`.
- **health-status-decoding**: `DaemonContract.HealthStatus` MUST decode a
  JSON object whose `status` field is a required `String` and whose
  `version` field is an OPTIONAL `String?`, and MUST ignore any other keys
  present in the decoded object.
- **daemon-request-forwarding-contract**: A conforming daemon MUST accept
  every request other than its own `GET /health` verbatim — same HTTP
  method, headers (including any `Authorization: Bearer` header already
  attached by the caller's middleware), body, and response semantics as
  `DaemonContract.backendURL` — so that a `Client` built against the daemon
  behaves identically to one built against the backend.
- **daemon-health-contract**: A conforming daemon MUST answer `GET /health`
  with HTTP `200` and a JSON body compatible with `HealthStatus` when it is
  healthy.

### TransportResolver — decision and caching

- **resolver-is-an-actor**: `TransportResolver` MUST be declared as an
  `actor`, so its stored `cached` value MUST be read and written only from
  within the actor's isolation domain.
- **resolver-nonisolated-config**: `override` and `port` MUST be exposed as
  `nonisolated let` properties, so a caller MAY read the resolver's
  configuration synchronously, from any isolation domain, without `await`.
- **forced-override-skips-probe**: When constructed with
  `override: .forceDirect`, `resolve()`/`reresolve()` MUST return `.direct`
  without invoking the probe; when constructed with `override: .forceDaemon`,
  they MUST return `.daemon` without invoking the probe.
- **auto-override-probes**: When constructed with `override: .auto`,
  `resolve()`/`reresolve()` MUST return `.daemon` when the probe applied to
  `DaemonContract.healthURL(port: self.port)` returns `true`, and MUST
  return `.direct` when it returns `false`.
- **resolve-serves-from-cache**: `resolve()` MUST return the existing
  `cached` `TransportKind` without invoking the probe (or re-applying the
  override) once a prior `resolve()`/`reresolve()` call has already produced
  one.
- **reresolve-always-recomputes**: `reresolve()` MUST unconditionally re-run
  the override/probe decision — even when a cached value already exists —
  and MUST overwrite `cached` with the new result.
- **cached-kind-reflects-last-decision**: `cachedKind` MUST return `nil`
  before `resolve()`/`reresolve()` has ever completed, and MUST return the
  `TransportKind` from the most recently completed `resolve()`/`reresolve()`
  call afterward.
- **resolver-never-launches-daemon**: `TransportResolver` MUST only detect
  whether a daemon is already listening on `port`; it MUST NOT start,
  install, or otherwise launch a daemon process.

### TransportResolver — health probe

- **probe-issues-single-bounded-get**: The production probe (used whenever
  no test probe is injected) MUST issue exactly one `GET` request to the
  given URL, using an `.ephemeral` `URLSessionConfiguration` with
  `waitsForConnectivity = false` and both `timeoutIntervalForRequest` and
  `timeoutIntervalForResource` set to the resolver's `probeTimeout`.
- **probe-success-is-status-200-only**: The production probe MUST report
  success (`true`) if and only if the response is an `HTTPURLResponse`
  whose `statusCode` is exactly `200`; it MUST NOT inspect or decode the
  response body to reach this decision.
- **probe-failure-collapses-to-false**: The production probe MUST report
  failure (`false`), rather than throwing, when the request throws for any
  reason (refused connection, DNS failure, timeout, or any other error) —
  the specific cause is not distinguished or surfaced.
- **default-probe-timeout**: `TransportResolver.init(override:port:probeTimeout:)`
  MUST default `probeTimeout` to `2` seconds and MUST default `port` to
  `DaemonContract.port`.
- **probe-injectable-for-tests**: `TransportResolver` MUST expose an
  `init(override:port:probe:)` initializer accepting a caller-supplied
  `@Sendable (URL) async -> Bool` closure in place of the production probe,
  for hermetic testing.
- **user-defaults-override**: `TransportResolver.fromUserDefaults(_:port:)`
  MUST read the boolean `UserDefaults` key `"useDirectMode"` and MUST
  construct the resolver with `override: .forceDirect` when that value is
  `true`, or `override: .auto` otherwise (including when the key is absent,
  since `UserDefaults.bool(forKey:)` defaults an absent key to `false`).

