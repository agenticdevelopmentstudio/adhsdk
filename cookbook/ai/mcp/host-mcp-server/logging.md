
Subsystem: `AgenticDeveloperHubSDK` | Category: `automation`

| Event | Level | Message |
|-------|-------|---------|
| Call routed and answered without an error flag | info | `tools/call <name> ok` |
| Call routed and answered with an error flag | info | `tools/call <name> error` |
| No registration matched | info | `tools/call <name> unknown` |

The tool name and outcome are logged with public privacy. The stdio drain adds a warning, described in the [host-mcp-server-stdio ingredient](cookbook:2affdc87-3c3b-4f7d-819d-f54ba947f2f1); its `HostMCPServer+Stdio` extension is part of that ingredient.

