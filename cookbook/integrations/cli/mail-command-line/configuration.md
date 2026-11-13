
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `args` | `[String]` | required | The arguments after `mail`, such as `["list", "me@example.com", "--limit", "10"]` |
| `program` | `String` | `"mail"` | How the host's users type the command, used in the usage text |
| `client` | `MailClient` | required | The injected client that performs every operation; it owns transport, timeouts and retries |
| `stdout` | `@Sendable (String) -> Void` | required | Receives the result, or the usage text for a help request; one call per successful run |
| `stderr` | `@Sendable (String) -> Void` | required | Receives usage text for a usage error and `Error: ...` lines for failures |
| `--json` | flag | off | Emit the client's value as pretty printed, key-sorted JSON |
| `--limit` | positive integer | filter default 50 | Page size, clamped to 1 through 500 |
| `notFoundStatus` | `Int32` constant | 3 | Exit status when a message id matches nothing |

The component reads no environment variables, settings keys or files.

