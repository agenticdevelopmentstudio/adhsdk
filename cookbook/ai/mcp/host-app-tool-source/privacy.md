
- **Data collected**: None. The component holds the app name, app version and plugin names it was given and returns them on request.
- **Storage**: None; the values live in memory for the life of the instance.
- **Transmission**: The values leave the process only when the registering server sends the result of `host_app_info` to a connected MCP client or chat engine; this class itself performs no transmission.
- **Retention**: Not applicable: nothing is persisted.

