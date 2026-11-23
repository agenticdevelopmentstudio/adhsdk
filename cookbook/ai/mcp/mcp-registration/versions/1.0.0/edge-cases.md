
- **Null and empty input**: An empty `token` MUST produce `${ADKITCHEN_MCP_TOKEN:-}`, a valid but credential-less default (MUST; nothing rejects it). An empty config file or a file with no `mcpServers` key MUST yield false (MUST).
- **Boundary values**: `port` is a `UInt16`, so the command's URL carries any value from 0 to 65535 as a plain decimal; port 0 produces `127.0.0.1:0/mcp` with no validation (MUST, per the type and the unvalidated interpolation). Because the match string begins `127.0.0.1:` and ends with the path, a registered port of 51477 does not match a query for port 1477, and a registered port of 1477 does not match a query for 51477 (MUST).
- **Substring match leniency**: The check is a substring test, so a URL such as `http://127.0.0.1:51477/mcp/extra` or one with a longer host ending in `127.0.0.1` also counts as registered (a consequence of `registered-port-match`; the source documents the match as "names `port`").
- **Concurrent access**: Both functions are free of shared state. `isRegistered` reads the file once, synchronously; if Claude Code rewrites `~/.claude.json` mid-read and the read sees partial JSON, the call reports false (MUST, per `registered-failure-is-false`). Not an ordering concern otherwise: nothing is serialised because nothing is shared.
- **Error states**: A missing, unreadable or malformed config file is reported as false; the source swallows the underlying error (`try?`) and returns no reason, so a caller cannot tell "never registered" from "config unreadable" (MUST, per `registered-failure-is-false`).
- **Offline or disconnected state**: Not applicable — neither function uses the network; the only I/O is one local file read.
- **Cancellation, timeouts**: Not applicable — both functions are synchronous and run to completion.

