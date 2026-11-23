
Channels

- **channel-cases**: `MCPRegistration.Channel` MUST have exactly two cases, `dev` and `release`, and be `Sendable` and `CaseIterable`.
- **channel-server-name**: `serverName` MUST be `adhd-dev` for `dev` and `adhd` for `release`.
- **channel-port**: `port` MUST be 22871 for `dev` and 22850 for `release`.
- **channel-url**: `url` MUST be `http://127.0.0.1:<port>` followed by the endpoint's path constant, `MCPHTTPEndpoint.path` (`/mcp`).

Building the entry and the command

- **headers-subcommand**: `headersSubcommand` MUST be `mcp headers`, the adhd subcommand that prints `{"Authorization":"Bearer <token>"}`.
- **entry-json**: `entryJSON(channel:adhdPath:)` MUST return a JSON object with exactly the keys `headersHelper`, `type` and `url`, keys sorted and slashes unescaped, where `type` is `http`, `url` is the channel's URL and `headersHelper` is the adhd path as one shell word, a space and `headersSubcommand`.
- **entry-path-quoting**: The adhd path MUST be left bare when it is non-empty and made only of letters, digits and `_-./:@+,`, and otherwise wrapped in single quotes with each single quote written `'\''` (`PartnerStepTemplate.shellQuoted`).
- **entry-no-token**: The entry MUST carry no token and no `Authorization` header.
- **command-is-text-only**: `claudeCommand(channel:adhdPath:)` MUST return the command as a string and MUST NOT execute it, read any file, or touch the network.
- **command-shape**: The command MUST be `claude mcp add-json --scope user <serverName> ` followed by the entry JSON quoted as one shell word by the same rule, so the helper's own single quotes survive.

Checking registration: `isRegistered(claudeConfig:channel:)`

- **registered-reads-config-file**: `isRegistered` MUST read the file at `claudeConfig` (normally `~/.claude.json`) and MUST NOT modify it.
- **registered-needs-server-entry**: `isRegistered` MUST return true only when the file's top level is a JSON object whose `mcpServers` value is an object containing a key equal to the channel's `serverName` whose value is itself an object with a string `url`.
- **registered-url-equal**: `isRegistered` MUST return true exactly when that `url` equals the channel's URL; a different port, another channel's URL or any other text is false.
- **registered-old-entry**: An `adkitchen` entry, the name the Kitchen registered before apps suite Phase 4, MUST NOT count as a registration of either channel.
- **registered-ignores-headers**: `isRegistered` MUST NOT consider the entry's `type`, `headers` or `headersHelper`; only its `url` decides the answer.
- **registered-failure-is-false**: `isRegistered` MUST return false, without throwing, when the file is missing, unreadable, not valid JSON, or not a JSON object, with no signal that distinguishes them.

Concurrency and side effects

- **stateless**: `MCPRegistration` MUST hold no state; its functions are pure apart from `isRegistered`'s synchronous file read, so they MAY be called from any thread concurrently.
