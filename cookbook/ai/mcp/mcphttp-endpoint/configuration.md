
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `server` | `HostMCPServer` | none — required | The server to serve. |
| `token` | `String` | none — required | The bearer token every request must present. |
| `preferredPort` | `UInt16` | 51477 | The port to try first; 0 asks the system for an ephemeral port. |
| `requestTimeout` | `TimeInterval` | 120 seconds | FlyingFox's whole-handler timeout for each request. |
| `logger` | `Logger?` | subsystem `AgenticDeveloperHubSDK`, category `automation` | Where the endpoint logs. |
| `path` | `String` constant | `/mcp` | The one route. |
| Bind wait | constant inside the source | 5 seconds | How long `start()` waits for the listener to report listening. |
| Stop timeout | constant inside the source | 1 second | How long `stop()` gives the listener to close. |
| Cancel error code | constant inside the source | `-32800` | The JSON-RPC code of the cancelled-request error. |

