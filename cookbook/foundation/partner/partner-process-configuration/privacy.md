
- **Data handled**: Paths, a session ID, a model name and tool names a caller passes in; no credential is held (the MCP token lives in the file at `mcpConfigPath`).
- **Storage**: None; it persists nothing.
- **Transmission**: None leaves the machine; the values are passed on the command line of a local process, so the session ID and file paths are visible to other processes on the machine (for example through `ps`).
- **Retention**: None beyond the lifetime of the value the caller holds.

