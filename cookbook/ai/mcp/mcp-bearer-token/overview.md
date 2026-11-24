
`MCPBearerToken` is a caseless enum holding two static operations and an error type. Its source comment calls the token "the shared secret between the app and the processes it hands the MCP URL to", stored "on disk, mode 0600, created on first load". `generate()` returns 32 random bytes as 64 lowercase hexadecimal characters. `load(from:)` reads the token from a file, or creates the file with a fresh token when there is none.

The token is the credential a caller presents as `Authorization: Bearer <token>` to the local MCP HTTP endpoint (`MCPHTTPEndpoint`), which compares the header to `Bearer <token>` without an early exit on the first differing byte. This recipe covers only the token's creation and file handling; the comparison and the route belong to the endpoint, and the registration command that puts the token in a Claude Code install belongs to `MCPRegistration`.

