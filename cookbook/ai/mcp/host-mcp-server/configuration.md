| Owner | Option | Type | Default | Description |
|-------|--------|------|---------|-------------|
| HostMCPServer | `appName` | String | none (required) | The MCP server name sent in the `initialize` result |
| HostMCPServer | `appVersion` | String | none (required) | The MCP server version sent in the `initialize` result |
| HostMCPServer | `source` | `ChatToolSource` | none | A tool source added with `register(_:prefix:)` |
| HostMCPServer | `prefix` | String, optional | empty | Put before every tool name the source advertises; removed before a call reaches it |
| HostMCPServer | `transport` | `Transport` | none (required) | The MCP transport passed to `serve(over:)` |
| HostMCPServer | `callerHeader` | static String | `X-ADHD-Pane` | Request header naming the calling pane |
| HostMCPServer | `legacyCallerHeader` | static String | `X-ADKitchen-Pane` | The header's name before adhd served the tools; still read |
| HostMCPServer | `callerHeaders` | static [String] | `[callerHeader, legacyCallerHeader]` | Every name the caller is read from, in order |
| AgentToolSource | `tools` | `[any AgentTool]` | none (required) | The agent tools an `AgentToolSource` serves |
| AgentToolSource | `caller` | String | `AgentHandlers.defaultToolCaller` (`external`) | The caller every bridged tool sees in its `ToolCallContext` |
