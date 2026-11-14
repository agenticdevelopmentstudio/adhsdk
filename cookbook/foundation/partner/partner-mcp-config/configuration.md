
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `serverName` | string constant | `adkitchen` | Key of the server under `mcpServers` |
| `callerHeader` | string constant | `X-ADKitchen-Pane` | Name of the caller-id header |
| `port` | `UInt16` | none (required) | Port of the app's MCP endpoint on the loopback address |
| `token` | string | none (required) | Bearer token the endpoint accepts |
| `callerID` | string | none (required) | Identifies the caller to the endpoint |
| `url` (`write`) | file URL | none (required) | Target file; its parent is created and secured |

The directory mode (0700), the file mode (0600), the path `/mcp` and the host `127.0.0.1` are fixed in the source, not configurable.

