
- **Data collected**: The host stores each session's user text, assistant text, tool-call arguments and tool results, and the agent definitions (prompts included), all as plaintext JSON.
- **Storage**: In the handed database's `agent_definitions`, `agent_sessions` and `agent_messages` tables; nothing is encrypted by the host. Thinking text and usage are streamed but not stored.
- **Transmission**: Each round sends the session's whole stored history, the system prompt and the tool specs to the provider through the chosen plugin; the host adds no redaction. Events leave the process only through whatever consumes the returned streams.
- **Retention**: A session and its messages are kept until `deleteSession`; the host defines no expiry or size limit.

