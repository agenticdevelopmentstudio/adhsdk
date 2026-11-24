
The source returns hardcoded English: the two tool descriptions, the `Host:`, `Version:` and `Plugins:` labels, `(none)`, `Opened a new chat window.` and `unknown tool <name>`. These strings are read by a model or an MCP client, and the source passes none of them through a localization table. A port MUST reproduce them verbatim, since callers may match on them.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `Returns the host app's name, version and loaded plugins.` | `host_app_info` description |
| (none; literal) | `Opens a new AI chat window in the host app.` | `host_open_chat_window` description |
| (none; literal) | `Host: / Version: / Plugins:` | Labels in the `host_app_info` result |
| (none; literal) | `(none)` | Plugin list when empty |
| (none; literal) | `Opened a new chat window.` | `host_open_chat_window` result |
| (none; literal) | `unknown tool <name>` | Error result for an unrecognised tool |

