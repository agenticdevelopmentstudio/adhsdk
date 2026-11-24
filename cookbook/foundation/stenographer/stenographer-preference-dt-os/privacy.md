
- **Data handled**: Preference values, including the user's summary `prompt` text and the identifier of the selected provider configuration; no credential or secret appears in these types (provider secrets travel in a different type).
- **Storage**: None here; the daemon stores the values.
- **Transmission**: Sent to the local daemon over the loopback HTTP route by the HTTP client.
- **Retention**: Not applicable: the types keep nothing; the daemon owns retention.

