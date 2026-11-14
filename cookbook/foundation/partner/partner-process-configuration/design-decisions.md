
**Decision**: Required options come first and optional ones last, in the order model then tools.
**Rationale**: `--allowedTools` takes a variable number of values, so it goes last and nothing after it is read as a tool name; the exact-order test pins the order.
**Approved**: pending

**Decision**: `--strict-mcp-config` is always set together with `--mcp-config`.
**Rationale**: The partner then sees only the MCP server the app configured, not any the user has set up elsewhere.
**Approved**: pending

**Decision**: `--verbose` is always set.
**Rationale**: The source comment states that `-p` with stream-json output requires it.
**Approved**: pending

