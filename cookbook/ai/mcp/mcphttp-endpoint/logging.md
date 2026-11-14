
- **Subsystem and category**: `AgenticDeveloperHubSDK` and `automation` by default, injectable.
- **Levels**: `info` for each request's path and status (including the 401 and cancel lines) and the port-taken fallback; `notice` for the listening port.
- **Privacy**: Port numbers and paths are logged as public. Bodies, headers and the token MUST NOT be logged.
- **Events**: port taken then ephemeral bind; listening on port; each `POST /mcp` status; each 401; each cancellation status.

