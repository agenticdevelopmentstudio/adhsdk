
Construction and registration

- **construction-parameters**: The server MUST be constructed from an app name and an app version, and MUST advertise them as its MCP server name and version.
- **register-appends**: `register(_:prefix:)` MUST append the source to the registration list; registration order is the order sources are listed and the order they are searched on a call.
- **prefix-default**: When no prefix is given, the registration MUST use the empty prefix.
- **registrations-survive-stop**: Registrations MUST survive `stop()`, so a later `serve(over:)` serves the same tools; callers MUST NOT re-register.
- **caller-header-name**: The server MUST expose the header name `X-ADHD-Pane` as `callerHeader`, the old name `X-ADKitchen-Pane` as `legacyCallerHeader`, and both, in that order, as `callerHeaders`.

Serving

- **fresh-server-per-serve**: Each `serve(over:)` MUST create a new SDK `Server`, because the SDK marks a server initialized on its first `initialize` and never clears that, so a reused server would answer the next client's `initialize` with "Server is already initialized".
- **serve-stops-previous**: If a server is already serving, `serve(over:)` MUST stop it before starting the new one, so the old connection and receive task are cancelled.
- **tools-capability**: The server MUST declare the tools capability with `listChanged` false.
- **not-strict**: The server MUST be created with the SDK's default configuration, not strict mode, so a stateless HTTP caller can send `tools/call` without a prior `initialize`.
- **serve-throws-start-failure**: `serve(over:)` MUST throw when starting the SDK server on the transport throws, and in that case MUST NOT record the new server as current.
- **stop-clears-server**: `stop()` MUST stop the current SDK server and clear it; calling it with no server MUST do nothing.
- **wait-until-completed**: The server MUST be able to report when the current connection's message loop ends, by waiting on the SDK server; with no server it MUST return at once.

Listing

- **list-concatenates**: `tools/list` MUST return the definitions of every registration, in registration order and in each source's own order.
- **list-prefix**: Each advertised name MUST be the registration's prefix followed by the definition's name.
- **list-description**: Each advertised tool MUST carry the definition's description unchanged.
- **list-schema**: Each advertised tool's input schema MUST be the definition's parameters JSON schema decoded as an MCP value.
- **list-schema-fallback**: When a definition's schema bytes do not decode, the tool MUST still be advertised with the schema `{"type": "object", "properties": {}}`.
- **list-asks-sources-live**: `tools/list` MUST ask each source for its definitions on every request; the server MUST NOT cache them.
- **list-duplicates-kept**: If two registrations advertise the same full name, `tools/list` MUST list both; the server does not deduplicate.
- **list-server-gone**: If the server has been deallocated when a list request arrives, the handler MUST return an empty tool list.

Calling

- **call-routing**: `tools/call` MUST be sent to the first registration, in order, whose prefix the requested name starts with and whose source advertises the name once the prefix is removed.
- **call-prefix-stripped**: The source MUST receive the name with the registration's prefix removed.
- **call-arguments-json**: The source MUST receive the call's arguments encoded as a JSON object; absent arguments MUST be sent as an empty object.
- **call-arguments-fallback**: If the arguments cannot be encoded, the source MUST receive the bytes of `{}`.
- **call-asks-definitions**: Before dispatching, the server MUST ask the candidate source for its current definitions to confirm it advertises the bare name.
- **call-caller**: The source MUST receive the value of the first of `callerHeaders` the request carries (`X-ADHD-Pane`, then `X-ADKitchen-Pane`) as the caller, or nil when there is no HTTP request or neither header.
- **caller-header-case**: The header lookup MUST be case-insensitive, as the request type's header accessor is; the test sets the lowercase `x-adkitchen-pane`.
- **call-result-text**: A result whose content does not start with the PNG data-URL prefix MUST become one text content item carrying the content unchanged.
- **call-result-error-flag**: The MCP result's `isError` MUST equal the source's error flag.
- **call-result-image**: A result whose content starts with `data:image/png;base64,` MUST become one image content item with the text after the prefix as its data and the MIME type `image/png`.
- **call-image-error-flag**: A PNG data-URL result MUST still carry the source's error flag.
- **call-unknown-tool**: When no registration matches, the server MUST return an error result with the text `unknown tool <name>`, as a normal result and not a protocol error.
- **call-server-gone**: If the server has been deallocated when a call arrives, the handler MUST return an error result with the text `server is gone`.
- **call-first-match-only**: Once a registration matches, the server MUST NOT try later registrations, even when the first source's result is an error.

Agent tool bridge (`AgentToolSource`)

- **bridge-definitions**: `AgentToolSource.toolDefinitions()` MUST return one definition per tool in its `tools` list, in list order, with the tool's `name` and `description` and the UTF-8 bytes of its `inputSchemaJSON` as the parameters schema.
- **bridge-caller-default**: `AgentToolSource` MUST take its `caller` from the initializer, and when none is given it MUST use `AgentHandlers.defaultToolCaller`, the string `external`.
- **bridge-caller-fixed**: `callTool` MUST run the tool with a `ToolCallContext` whose `caller` is the source's own `caller`, and MUST NOT pass on the caller the MCP request supplied; the context's `agentId` and `sessionId` MUST be nil.
- **bridge-result**: When the tool returns, `callTool` MUST answer the outcome's `resultJSON` with the error flag false; the outcome's `summary` and `inverse` MUST NOT be part of the answer.
- **bridge-arguments**: `callTool` MUST hand the tool the argument bytes decoded as UTF-8 text, and MUST hand it `{}` when the bytes are empty.
- **bridge-arguments-undecodable**: When non-empty argument bytes are not valid UTF-8, `callTool` MUST hand the tool an empty string.
- **bridge-unknown-tool**: When no tool in the list has the requested name, `callTool` MUST answer the text `Unknown tool '<name>'` with the error flag true and MUST NOT run any tool.
- **bridge-name-first-match**: When two tools share a name, `callTool` MUST run the first in list order.
- **bridge-failure**: When the tool throws, `callTool` MUST answer the error's `localizedDescription` with the error flag true.
- **bridge-ignores-policy**: `callTool` MUST NOT read the tool's `permissionDefault` or `isMutating`, and MUST NOT record an activity entry; it runs every listed tool.

Logging

- **call-log**: Every call MUST write one info log line `tools/call <name> ok`, `tools/call <name> error` or `tools/call <name> unknown`, with the name and outcome logged as public.

