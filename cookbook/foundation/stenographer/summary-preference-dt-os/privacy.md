
- **Data collected**: none by this code; the source describes `detailChars` as data minimization, capping how much of each event's detail goes into the prompt.
- **Storage**: none here; the daemon persists the values in its settings table under the `SummarySettingsKeys` names.
- **Transmission**: none here; the app pushes the values to the daemon (the HTTP client posts them to the daemon's loopback address; the source's "over XPC" comment is stale), and this code opens no connection.
- **Retention**: none defined by this code.

