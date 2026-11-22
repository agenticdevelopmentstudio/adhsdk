
- **Data collected**: The operations carry session identifiers, working directories, conversation entries, AI interaction records, oversight findings and scripts, and LLM provider registry data. `DaemonProviderConfig` carries no secrets and no model by documented design.
- **Storage**: The protocol stores nothing; the daemon owns persistence. `setAIPreferences` replaces the daemon's provider registry with the pushed set.
- **Transmission**: Over HTTP to the base URL the HTTP implementation's caller passes; no authentication header is sent.
- **Retention**: Not set by this protocol.

