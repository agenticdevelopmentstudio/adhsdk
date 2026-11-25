
- **Data collected**: none by the handlers. Bodies carry agent definitions, session titles, message text, tool arguments and results, and model entries with optional `secrets`.
- **Storage**: none in the handlers; the host and registry store agents, sessions and entries, and the registry's secret store holds secret field values.
- **Transmission**: replies never carry a secret value (a `ModelEntry` names its secret fields only); request bodies to `POST` and `PUT` model routes MAY carry secrets in the clear on the server's transport, which the example host (roosterd) binds to loopback.
- **Retention**: not decided here; owned by the host and registry.

