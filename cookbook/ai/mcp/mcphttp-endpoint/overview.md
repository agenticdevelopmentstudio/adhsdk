
The MCP HTTP Endpoint is the listening half of the app's automation surface. It takes a `HostMCPServer` and serves it to local MCP clients (Claude Code, for one) over MCP Streamable HTTP on `127.0.0.1`. FlyingFox owns the socket. The MCP SDK's `StatelessHTTPServerTransport` owns the protocol, including Origin and Host checks, Accept and Content-Type checks, and the protocol-version check. The endpoint adds what the SDK leaves to the host:

- A bearer token on every request.
- One `POST /mcp` route, with 404 and 405 for everything else.
- A unique JSON-RPC id per request. The stateless transport keys its bookkeeping by id alone, so two callers who both send `"id": 1` would otherwise collide.
- Cancellation. Because a request runs under an id its caller did not send, the endpoint translates a caller's `notifications/cancelled` to the id the SDK knows, and turns FlyingFox's request timeout, which on its own cancels only the HTTP handler, into the same cancellation, so the tool call stops when the client is told it failed.
- A start and stop lifecycle that survives a busy port and a stop that races a start.

It is an actor. One instance serves one `HostMCPServer` on one port. The registration side, which writes the command that points Claude Code at this endpoint, is the MCP registration ingredient (ai/mcp/mcp-registration). The client-side MCP plumbing is the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56).

The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPHTTPEndpoint.swift`. It depends on the core `HostMCPServer` (`serve(over:)`, `stop()`, `callerHeader`), FlyingFox, and the MCP SDK.

