| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `client` | `MailClient` | none (required) | The mail service client every tool call goes through; supplied to `init(client:)` |

The component reads no environment variables or settings keys. Per-call tool arguments (`limit`, `include_bodies`, `from` and the rest) are not construction options; their defaults are in the requirements above.
