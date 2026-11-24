
`HostMCPServer+Stdio` is an extension of `HostMCPServer` that serves the host's MCP tools over this process's standard input and output and shuts down cleanly when input ends. It adds the public `serveStdio()`, a drain deadline constant `stdioDrainDeadline` of 360 seconds, and an internal `serveUntilDrained(over:deadline:)` that works with any transport.

The reason it exists is stated in the source: the pinned MCP Swift SDK (0.12.1) answers each request in its own unstructured task, and `waitUntilServerCompleted()` waits only for the receive loop, which ends at end of input. Stopping at that point drops every reply still in flight, so `printf '...' | temporal mcp` would print nothing. The extension wraps the transport in a `ReplyCountingTransport`, which counts requests that have arrived and are not yet answered, and waits for that count to reach zero or for the deadline before it stops the server.

