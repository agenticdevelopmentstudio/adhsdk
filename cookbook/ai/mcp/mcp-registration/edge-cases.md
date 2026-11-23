
- **Null and empty input**: An empty `adhdPath` MUST be quoted as `''`, giving the helper `'' mcp headers`, which fails when Claude Code runs it (MUST; nothing rejects it). An empty config file or a file with no `mcpServers` key MUST yield false (MUST).
- **Boundary values**: The ports are fixed per channel; the check is an exact string comparison, so a trailing slash, another host spelling such as `localhost`, or an environment-default form all count as not registered (MUST).
- **Paths with spaces or quotes**: The path is one shell word inside the helper, and the whole entry is one shell word in the command, so a path holding spaces or single quotes survives both levels of quoting (MUST).
- **Concurrent access**: The functions are free of shared state. `isRegistered` reads the file once, synchronously; if Claude Code rewrites `~/.claude.json` mid-read and the read sees partial JSON, the call reports false (MUST, per `registered-failure-is-false`).
- **Error states**: A missing, unreadable or malformed config file is reported as false; the source swallows the underlying error (`try?`) and returns no reason (MUST).
- **Offline or disconnected state**: Not applicable: no function uses the network; the only I/O is one local file read.
- **Cancellation, timeouts**: Not applicable: every function is synchronous and runs to completion.
