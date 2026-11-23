
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` | `UInt16?` | `nil` | Port the endpoint is listening on. |
| `token` | `String?` | `nil` | Bearer token for the registration command. |
| `isRegistered` | `Bool` | `false` | Whether `~/.claude.json` lists this server on this port. |
| `failureReason` | `String?` | `nil` | Why the endpoint is not running. |

The component defines no environment variable and no settings key. It reads `MCPHTTPEndpoint.path` (`/mcp`) to build `url`, and is injected into the CLI settings panel and `PartnerCoordinator`.

