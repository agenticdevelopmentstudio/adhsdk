
MCP Registration is how a Claude Code install learns about the host app's local MCP endpoint. It is a stateless namespace with two operations. The first builds the text of a single `claude mcp add` command that the user runs once. The second reads Claude Code's configuration file and reports whether a server named `adkitchen` is already registered against a given port. It performs no process execution, no network access and no writes.

The command writes the endpoint URL, the bearer token and the caller-pane header as shell-style defaults (`${NAME:-default}`) rather than as bare values. A shell running inside the app, where those variables are set, therefore wins over the values baked in at registration time. The endpoint it registers is served by the MCP HTTP endpoint ingredient (ai/mcp/mcphttp-endpoint); the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56) covers the client side of MCP.

The source is one file, `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPRegistration.swift`, a public `enum MCPRegistration` with no cases, one constant and two static functions.

