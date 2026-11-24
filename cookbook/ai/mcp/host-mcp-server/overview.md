
`HostMCPServer` is an actor that turns a set of `ChatToolSource` values into one Model Context Protocol server. Every registered source is advertised under `tools/list`, and `tools/call` is routed to the source that advertises the requested name. The source comment calls it "transport-agnostic": the in-app chat and the HTTP endpoint hand it different transports, and the actor serves whichever it is given.

The actor owns three things: a list of registrations (a source and a name prefix), the current SDK `Server` for the live connection, and the translation between the tool-source contract (name, JSON argument bytes, optional caller, a content string and an error flag) and MCP's result type. It also reads the caller's pane identifier from the `X-ADKitchen-Pane` request header. Starting, stopping and the draining variant used for standard input live here and in `HostMCPServer+Stdio`.

