
The server returns hardcoded English in two places: `unknown tool <name>` and `server is gone`. They are protocol payload read by an MCP client or model, not interface text, and the source passes them through no localization table. Tool descriptions and results come from the sources and are not altered.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `unknown tool <name>` | Error result when no registration matches |
| (none; literal) | `server is gone` | Error result when the server was deallocated before the call |

