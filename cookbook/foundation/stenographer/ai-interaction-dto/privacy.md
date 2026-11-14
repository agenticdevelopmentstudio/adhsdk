
- **Data handled**: Full system prompts, user prompts and model responses for daemon LLM calls, plus a session id, a configuration display name and error text. These can contain session content.
- **Storage**: None by the type; the daemon stores the rows in its `ai_interactions` table.
- **Transmission**: The DTO crosses XPC and loopback HTTP between daemon and app; the type applies no redaction or encryption.
- **Retention**: Not applicable to the type; retention is the daemon store's concern.

