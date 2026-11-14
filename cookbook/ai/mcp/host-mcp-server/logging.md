
Subsystem: `AgenticDeveloperHubSDK` | Category: `automation`

| Event | Level | Message |
|-------|-------|---------|
| Call routed and answered without an error flag | info | `tools/call <name> ok` |
| Call routed and answered with an error flag | info | `tools/call <name> error` |
| No registration matched | info | `tools/call <name> unknown` |

The tool name and outcome are logged with public privacy. The stdio drain adds a warning, described in the `host-mcp-server-stdio` recipe.

