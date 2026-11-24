
The Reply Counting Transport is a pass-through wrapper around another MCP `Transport`. It forwards `connect`, `disconnect`, `send` and `receive` unchanged, and keeps a set of the JSON-RPC requests that have arrived but have not yet been answered. A server whose input has closed uses that set to wait for the answers it still owes.

The need comes from the pinned swift-sdk (0.12.1), which handles every request in its own unstructured task. `Server.waitUntilCompleted()` waits only for the receive loop, and that loop ends at the input's end of file. Without the wrapper, stopping the server at that point throws away every reply still being worked on. A piped invocation such as `printf '...' | temporal mcp` would then get nothing back.

It is an internal actor of the core framework. It is used by the stdio serving path (`HostMCPServer.serveUntilDrained`), which wraps its transport in it and waits on `waitUntilNothingOwed` with a deadline. The client-side MCP plumbing is the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56).

The source is `packages/apple/AgenticDeveloperHubSDK/Core/MCP/ReplyCountingTransport.swift`.

