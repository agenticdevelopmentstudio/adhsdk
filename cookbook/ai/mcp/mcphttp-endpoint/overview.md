
The MCP HTTP Endpoint is the listening half of the app's automation surface. It takes a `HostMCPServer` and serves it to local MCP clients (Claude Code, for one) over MCP Streamable HTTP on `127.0.0.1`. FlyingFox owns the socket. The MCP SDK's `StatelessHTTPServerTransport` owns the protocol, including Origin and Host checks, Accept and Content-Type checks, and the protocol-version check. What the SDK leaves to the host is split in two. `MCPStatelessHTTPHandler` (`packages/apple/AgenticDeveloperHubSDK/Core/MCP/MCPStatelessHTTPHandler.swift`, in the core target) depends on no socket and is shared with adhd's `/mcp` route: it owns the id rewriting, cancellation and the collected body. The endpoint owns the socket-side policy, the bearer token, the route and the lifecycle. Together they add:

- A bearer token on every request.
- One `POST /mcp` route, with 404 and 405 for everything else.
- A unique JSON-RPC id per request. The stateless transport keys its bookkeeping by id alone, so two callers who both send `"id": 1` would otherwise collide.
- Cancellation. Because a request runs under an id its caller did not send, the endpoint translates a caller's `notifications/cancelled` to the id the SDK knows, and turns FlyingFox's request timeout, which on its own cancels only the HTTP handler, into the same cancellation, so the tool call stops when the client is told it failed.
- A start and stop lifecycle that survives a busy port and a stop that races a start.

It is an actor. One instance serves one `HostMCPServer` on one port. The registration side, which builds the command that points Claude Code at adhd's endpoint, is [adhsdk.ingredient.ai.mcp.mcp-registration](cookbook:ed460f60-2a13-4a3c-b7eb-53c531bf0741). The client-side MCP plumbing is the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56).

The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPHTTPEndpoint.swift`. It depends on the core `HostMCPServer` (`stop()`) and `MCPStatelessHTTPHandler` (which calls `serve(over:)` and reads `callerHeaders`), FlyingFox, and the MCP SDK.

