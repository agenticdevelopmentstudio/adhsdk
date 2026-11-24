
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `daemonName` | `String` | none, required | What failure sentences call the daemon (for example the name of the host's daemon executable). |
| `call` | `@Sendable (Data, TimeInterval?) async throws -> Data` | none, required | One IPC round trip, waiting at most the given time (nil: no deadline). It MUST NOT retry: `signIn` opens a browser and `modifyLabels` writes to Gmail, so a retry after a timeout could do either twice. |
| `classify` | `@Sendable (any Error) -> MailTransportFailure` | none, required | Maps the host's IPC error onto a `MailTransportFailure`. |
| `onFailure` | `@Sendable (any Error) -> Void` | does nothing | Sees the underlying error before it becomes a sentence. |
| `callTimeout` | `TimeInterval` constant | 360 | Deadline for every request except `syncNow`. Not configurable by the caller. |

