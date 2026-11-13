
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `daemonName` | `String` | none, required | What failure sentences call the daemon (the source's example is `temporald`). |
| `call` | `@Sendable (Data, TimeInterval?) async throws -> Data` | none, required | One IPC round trip, waiting at most the given time (nil: no deadline). It must not retry. |
| `classify` | `@Sendable (any Error) -> MailTransportFailure` | none, required | Maps the host's IPC error onto a `MailTransportFailure`. |
| `onFailure` | `@Sendable (any Error) -> Void` | does nothing | Sees the underlying error before it becomes a sentence. |
| `callTimeout` | `TimeInterval` constant | 360 | Deadline for every request except `syncNow`. Not configurable by the caller. |

