
- **Data collected**: None by this component. It passes the project display name and the pane's node identifier to each shell as environment variables.
- **Storage**: None; the raw value of the terminal view identifier is what persisted layout rows already name.
- **Transmission**: The two environment variables are visible to every process the shell starts, and a process in the shell sends the pane identifier as the MCP caller header.
- **Retention**: Not applicable: nothing is retained by this component.

