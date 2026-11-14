
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` (parameter to `claudeCommand` and `isRegistered`) | `UInt16` | none — required | The port the endpoint is listening on; baked into the URL default, or matched against the registered URL. |
| `token` (parameter to `claudeCommand`) | `String` | none — required | The bearer token baked in as the default of `ADKITCHEN_MCP_TOKEN`. |
| `claudeConfig` (parameter to `isRegistered`) | `URL` | none — required | The Claude Code configuration file to read; the doc comment says "normally `~/.claude.json`". |
| `serverName` | `String` constant | `adkitchen` | The server name used in the command and as the key looked up under `mcpServers`. |
| `MCPHTTPEndpoint.path` | `String` constant (owned by the endpoint) | `/mcp` | The URL path of the registered endpoint. |
| `HostMCPServer.callerHeader` | `String` constant (owned by the endpoint's server) | `X-ADKitchen-Pane` | The name of the caller-pane header. |
| `ADKITCHEN_MCP_URL`, `ADKITCHEN_MCP_TOKEN`, `ADKITCHEN_PANE_ID` | environment variables named in the command | unset — the baked-in defaults apply | Read by Claude Code, not by this component; the source says a shell inside the app is where they are set. |

