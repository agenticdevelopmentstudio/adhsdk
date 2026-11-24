
The client's errors and the registry's log messages are hardcoded, unlocalized English strings with no string-catalog key:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no catalog key) | "The MCP server was disabled or removed before its connection finished starting; nothing was launched." | The client's "already disconnected" error description |
| (none — literal, no catalog key) | "Failed to connect MCP server %@: %@" (interpolated with the configuration's name and the error's description) | The registry's reconcile failure log line |

