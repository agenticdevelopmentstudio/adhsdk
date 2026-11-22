
- **Data handled**: Session metadata, conversation entries, AI interaction records and provider settings, all read from the local daemon. `setAIPreferences` posts the provider registry, which per its test includes provider `secrets` such as an API key.
- **Storage**: None; the client keeps only the reconnect handlers, the last `uptime` and the poll task in memory.
- **Transmission**: Plain HTTP to the loopback address `127.0.0.1` by default; nothing leaves the machine unless `STENOGRAPHER_URL` points elsewhere, and the client adds no authentication header.
- **Retention**: Not applicable: no data is kept after a call returns.

