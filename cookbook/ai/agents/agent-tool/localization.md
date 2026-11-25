
`AgentToolError.unknownTool`, `AgentToolError.invalidArguments` and the `malformedReply` messages ("Expected a JSON array of tools", "A tool has no name", "Expected JSON, got an event stream") are hardcoded English strings with no localization lookup; a `failed` message is whatever the host sent.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `Unknown tool '<name>'` | `AgentToolError.unknownTool` description |
| none (hardcoded) | `The arguments for '<tool>' are not a JSON object` | `AgentToolError.invalidArguments` description |
| none (hardcoded) | `Expected a JSON array of tools` | `load()` reply not an array |
| none (hardcoded) | `A tool has no name` | `load()` element without a name |
| none (hardcoded) | `Expected JSON, got an event stream` | Reply was an event stream |

