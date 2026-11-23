
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `channel` (parameter to every function) | `MCPRegistration.Channel` | none — required | Which adhd the entry points at: its server name, port and URL. |
| `adhdPath` (parameter to `entryJSON` and `claudeCommand`) | `String` | none — required | The installed adhd executable the `headersHelper` runs. |
| `claudeConfig` (parameter to `isRegistered`) | `URL` | none — required | The Claude Code configuration file to read; normally `~/.claude.json`. |
| `headersSubcommand` | `String` constant | `mcp headers` | The adhd subcommand the helper runs. |
| `MCPHTTPEndpoint.path` | `String` constant (owned by the endpoint) | `/mcp` | The URL path of the registered endpoint. |
