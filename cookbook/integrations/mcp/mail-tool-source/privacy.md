
- **Data collected**: Not applicable as collection; the component reads the user's mail (accounts, labels, messages, bodies, threads) through the client and returns it to the tool caller.
- **Storage**: None; the component keeps nothing between calls.
- **Transmission**: Results go to whatever chat engine or MCP host called the tool, so message content leaves the service boundary for that host. Transport to the service is the `MailClient`'s.
- **Retention**: Not applicable; nothing is retained.

