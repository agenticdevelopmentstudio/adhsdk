
The server name

- **server-name**: `MCPRegistration.serverName` MUST be the string `adkitchen`.

Building the command: `claudeCommand(port:token:)`

- **command-is-text-only**: `claudeCommand` MUST return the command as a string and MUST NOT execute it, read any file, or touch the network.
- **command-prefix**: The command MUST begin with `claude mcp add --transport http --scope user adkitchen ` (the server name followed by one space).
- **command-url-argument**: The command's URL argument MUST be a single-quoted string of the form `${ADKITCHEN_MCP_URL:-http://127.0.0.1:<port>/mcp}`, where `<port>` is the decimal value of the `port` parameter and the path is the endpoint's path constant, `MCPHTTPEndpoint.path` (`/mcp`).
- **command-url-host**: The default URL MUST name the loopback address `127.0.0.1` and the scheme `http`.
- **command-authorization-header**: The command MUST carry the header `--header 'Authorization: Bearer ${ADKITCHEN_MCP_TOKEN:-<token>}'`, where `<token>` is the `token` parameter inserted as given.
- **command-pane-header**: The command MUST carry the header `--header 'X-ADKitchen-Pane: ${ADKITCHEN_PANE_ID:-}'`, whose header name is the endpoint server's caller-header constant (`HostMCPServer.callerHeader`) and whose default value is empty.
- **command-header-order**: The command's two headers MUST appear after the URL argument, the Authorization header first and the pane header last.
- **command-defaults-let-the-environment-win**: Each of the three values (URL, token, pane id) MUST be written as `${VARIABLE:-default}` so that, where Claude Code resolves the variable to a non-empty value, that value takes precedence over the value baked in at registration time. The expansion itself is performed by Claude Code when it reads its configuration, which is outside this source.
- **command-single-quoted**: The URL argument and each header argument MUST be wrapped in single quotes, so a shell run by the user does not expand the `${...}` forms before Claude Code stores them.
- **command-token-not-escaped**: NEEDS REVIEW: Not implemented in source. `claudeCommand` inserts `token` (and the decimal `port`) into a single-quoted shell string with no quoting or validation, so a token containing a single quote would end the quoted string early. The shipped token source, `MCPBearerToken.generate()`, yields 64 hex characters, but `MCPBearerToken.load(from:)` returns whatever non-empty text its file holds, and nothing in `MCPRegistration` or its signature restricts the character set. A decision from the owner of the token contract (reject, escape, or document a hex-only precondition) would settle it.

Checking registration: `isRegistered(claudeConfig:port:)`

- **registered-reads-config-file**: `isRegistered` MUST read the file at `claudeConfig` (normally `~/.claude.json`) and MUST NOT modify it.
- **registered-needs-server-entry**: `isRegistered` MUST return true only when the file's top level is a JSON object whose `mcpServers` value is an object containing a key equal to `serverName` whose value is itself an object.
- **registered-needs-url-string**: `isRegistered` MUST return false when the `adkitchen` entry has no `url` key or its `url` value is not a string.
- **registered-port-match**: `isRegistered` MUST return true when the entry's `url` string contains the substring `127.0.0.1:<port><path>` (for example `127.0.0.1:51477/mcp`), whether the URL is the literal URL or the `${ADKITCHEN_MCP_URL:-...}` default form written by `claudeCommand`.
- **registered-port-mismatch**: `isRegistered` MUST return false when the entry's `url` names a different port.
- **registered-ignores-token-and-headers**: `isRegistered` MUST NOT consider the entry's `type`, headers or token; only its `url` decides the answer.
- **registered-failure-is-false**: `isRegistered` MUST return false, without throwing, when the file is missing, unreadable, not valid JSON, or not a JSON object. It reports all of these as plain "not registered", with no signal that distinguishes them.

Concurrency and side effects

- **stateless**: `MCPRegistration` MUST hold no state; both functions are pure apart from `isRegistered`'s synchronous file read, so they MAY be called from any thread concurrently.

