
Hub Client Transport is the seam `ADHClient` (the Agentic Developer Hub API
client) builds its generated `Client` from. It has no visual surface: it is a
value type (`APITransport`), a namespace of constants (`DaemonContract`), and
a decision actor (`TransportResolver`) that together decide, and cache,
whether a request goes straight to the backend over HTTPS ("Direct") or to a
local caching proxy daemon over loopback HTTP ("Daemon").

The three source files, all under the hub client package's
`Sources/Transport/`, are:

- `APITransport.swift` — `TransportKind`, `APITransport`, and the
  `direct(serverURL:transport:)` / `daemon(port:transport:)` factories.
- `DaemonContract.swift` — the constants and wire shape (`HealthStatus`)
  that define what a conforming local daemon must implement.
- `TransportResolver.swift` — the `actor` that probes the daemon's
  `GET /health` and caches the resulting `TransportKind`.

Because swift-openapi-runtime takes the server URL on the generated `Client`
itself (not on the transport), Direct and Daemon are fully captured by the
`(serverURL, transport)` pair `APITransport` carries — the generated `Client`
is identical either way. `TransportResolver` never launches the daemon; it
only detects one that is already running, with Direct as the always-available
fallback. `ADHClient` (`Sources/ADHClient.swift`, outside this component's
file set) is the consumer: `ADHClient.resolved(using:credentials:)` asks a
`TransportResolver` for a `TransportKind` and rebuilds a fresh `APITransport`
(`.daemon(port:)` or `.direct()`) from that decision on every call.

