
- **Data collected**: Request bodies are tool calls and their arguments from a local MCP client, plus the caller-pane header. The endpoint and its handler read them to route and rewrite ids and does not keep them past the request.
- **Storage**: The endpoint stores nothing durable. The in-flight table holds only caller and id strings for the life of a request. The token is held in memory.
- **Transmission**: The socket binds `127.0.0.1` only, so nothing is reachable from another machine, and traffic is plain HTTP on loopback guarded by the bearer token.
- **Retention**: Nothing is retained after a request completes or the endpoint stops.
- **Token handling**: The token is compared in constant time and is never logged; the 401 log line names only the path and status.

