
- **Data collected**: message `content` is the user's prompts and the agent's replies, and `agentId` and `sessionId` identify the source.
- **Storage**: none here; the daemon reads the content from its transcript store.
- **Transmission**: the shapes cross the local boundary between the daemon and `steno conversation fetch`; this code opens no connection.
- **Retention**: none defined by this code.

