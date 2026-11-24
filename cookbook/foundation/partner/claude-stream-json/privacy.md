
- **Data collected**: None by this code. It carries the conversation: the owner's prompt text (`userMessage`), assistant text, thinking text, tool names and tool results, which may contain project content.
- **Storage**: None; the file persists nothing.
- **Transmission**: None directly; the lines it builds are written by the caller to a local claude process's stdin, and claude then talks to its own service.
- **Retention**: None beyond the lifetime of the value the caller holds.

