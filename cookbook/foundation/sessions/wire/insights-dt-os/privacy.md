
- **Data collected**: The types collect nothing themselves. Their values include tool names, project names (the last path component of a working directory), model names and, in graph session nodes, Claude Code session ids from local sessions.
- **Storage**: None; the types are transient values.
- **Transmission**: They are serialized onto the daemon's local HTTP responses by `UsageRoutes`; the types add no transport of their own.
- **Retention**: Not applicable to the types; retention of the underlying events is the daemon's (the `CacheMissesDTO.coverageStart` doc comment notes retention is opt-in and off by default).

