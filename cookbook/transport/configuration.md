
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `override` | `TransportResolver.Override` (`.auto` / `.forceDirect` / `.forceDaemon`) | `.auto` | Forces a transport or lets the health probe decide. |
| `port` | `Int` | `DaemonContract.port` (`22850`) | Loopback port the daemon is expected to listen on; feeds `daemonURL(port:)`/`healthURL(port:)` and `APITransport.daemon(port:)`. |
| `probeTimeout` | `TimeInterval` | `2` (seconds) | Bounds the health probe's `timeoutIntervalForRequest`/`timeoutIntervalForResource` before the daemon is treated as down. |
| `probe` | `@Sendable (URL) async -> Bool` (test seam) | The production network probe | Caller-injectable replacement for the real network probe, via `init(override:port:probe:)`. |
| `serverURL` (`APITransport.direct` parameter) | `URL` | `DaemonContract.backendURL` | Overridable backend URL for the Direct path. |
| `transport` (`APITransport.direct`/`daemon` parameter) | `any ClientTransport` / `(any ClientTransport)?` | `URLSessionTransport()` (direct) / `makeDaemonURLSessionTransport()` (daemon) | Overridable client transport, mainly for injecting a mock in tests. |
| `useDirectMode` (`UserDefaults` key, via `fromUserDefaults(_:port:)`) | `Bool` | `false`/absent → `.auto` | User-default escape hatch that forces Direct mode. |

