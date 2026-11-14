
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `appName` | String | none (required) | The MCP server name sent in the `initialize` result |
| `appVersion` | String | none (required) | The MCP server version sent in the `initialize` result |
| `source` | `ChatToolSource` | none | A tool source added with `register(_:prefix:)` |
| `prefix` | String, optional | empty | Put before every tool name the source advertises; removed before a call reaches it |
| `transport` | `Transport` | none (required) | The MCP transport passed to `serve(over:)` |
| `callerHeader` | static String | `X-ADKitchen-Pane` | Request header naming the calling pane |

